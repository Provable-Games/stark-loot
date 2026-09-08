#!/usr/bin/env python3
"""Reproduce isolated codec/caller measurements twice, with raw logs and per-call resources.

No third-party Python dependencies. Run from any directory. Results go under ignored target/.
Sierra gas is the primary metric; VM resources come from separate cairo-steps executions.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed


ROOT = Path(__file__).resolve().parents[1]
CASES = json.loads((ROOT / "scripts/cache_probe_cases.json").read_text())


def run_logged(command, log_path, **kwargs):
    """Retain every command log and expose diagnostics in CI on failure."""
    completed = subprocess.run(
        command, capture_output=True, text=True, check=False, **kwargs
    )
    log = completed.stdout + completed.stderr
    log_path.write_text(log)
    if completed.returncode:
        print(log, end="", flush=True)
        raise subprocess.CalledProcessError(completed.returncode, command)
    return log


def capture(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def gas_row(log, contract):
    # Every test contains exactly one invocation of its single-entrypoint probe.
    table = log.split(f"| {contract} Contract", 1)[1]
    row = re.search(
        r"\| run\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)"
        r"\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|",
        table,
    )
    if row is None:
        raise RuntimeError(f"Missing gas row for {contract}")
    minimum, maximum, average, deviation, calls = map(int, row.groups())
    if not (minimum == maximum == average and deviation == 0 and calls == 1):
        raise RuntimeError(f"Expected exactly one measured call: {row.group()}")
    return average


def find_probe(trace, contract):
    found = []
    if trace["entry_point"]["contract_name"] == contract:
        found.append(trace)
    for child in trace["nested_calls"]:
        if "EntryPointCall" in child:
            found.extend(find_probe(child["EntryPointCall"], contract))
    return found


def resource_tree(trace):
    # Retain the per-call boundaries: do not attribute the whole test's oracle resources
    # to the probe, or silently conflate the caller with its nested library call.
    return {
        "contract": trace["entry_point"]["contract_name"],
        "function": trace["entry_point"]["function_name"],
        "resources": trace["used_execution_resources"],
        "events": trace["entry_point"]["events_summary"],
        "nested_calls": [
            resource_tree(child["EntryPointCall"])
            for child in trace["nested_calls"]
            if "EntryPointCall" in child
        ],
    }


def syscall_counts(tree):
    # Foundry reports inclusive syscall counters at each node. Inspect every nested
    # node, but do not add inclusive counters (that would count nested calls twice).
    return {
        key: value["call_count"]
        for key, value in tree["resources"].get("syscall_counter", {}).items()
    }


def check_invariants(case, tree):
    expected = CASES[case]
    counts = syscall_counts(tree)
    for key, field in [
        ("StorageRead", "reads"),
        ("StorageWrite", "writes"),
        ("Keccak", "keccak"),
        ("EmitEvent", "events"),
    ]:
        if counts.get(key, 0) != expected[field]:
            raise RuntimeError(
                f"{case}: {key}={counts.get(key, 0)}, expected {expected[field]}"
            )
    if expected["keccak"] == 0:

        def walk(node):
            if syscall_counts(node).get("Keccak", 0):
                raise RuntimeError(f"{case}: nested Keccak syscall")
            for child in node["nested_calls"]:
                walk(child)

        walk(tree)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "cases", nargs="*", help="Case names from cache_probe_cases.json (default: all)"
    )
    parser.add_argument("--output", type=Path, default=ROOT / "target/cache-benchmarks")
    parser.add_argument(
        "--jobs",
        type=int,
        default=1,
        help="Independent cases in parallel; repetitions remain sequential per case",
    )
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    cases = args.cases or list(CASES)
    unknown = set(cases) - CASES.keys()
    if unknown:
        parser.error(f"Unknown cases: {sorted(unknown)}")
    help_text = capture("snforge", "test", "--help")
    for flag in [
        "--gas-report",
        "--tracked-resource",
        "--detailed-resources",
        "--save-trace-data",
    ]:
        if flag not in help_text:
            raise RuntimeError(f"Pinned snforge must support {flag}")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    result = {
        "scarb": capture("scarb", "--version"),
        "snforge": capture("snforge", "--version"),
        "profile": "release",
        "repetitions": 2,
        "fuzzer_seed": 360029,
        "measurement_boundary": "Single probe entrypoint, including ABI handling and nested calls; "
        "excludes test setup/assertions. Not total transaction fees.",
        "artifact_build": "snforge test contract artifacts (default optimization), not --no-optimization",
        "source_sha256": {
            str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(
                [
                    *ROOT.glob("src/*.cairo"),
                    *ROOT.glob("tests/cache*.cairo"),
                    *ROOT.glob("scripts/*cache*.py"),
                    ROOT / "scripts/cache_probe_cases.json",
                    ROOT / "Scarb.toml",
                    ROOT / "Scarb.lock",
                    ROOT / ".tool-versions",
                ]
            )
        },
        "cases": {},
    }
    if args.jobs > 1:

        def run_case(case):
            destination = output / case
            destination.mkdir(exist_ok=True)
            command = [
                sys.executable,
                str(Path(__file__).resolve()),
                case,
                "--output",
                str(destination),
                "--jobs",
                "1",
            ]
            run_logged(command, destination / "runner.log", cwd=ROOT)
            record = json.loads((destination / "results.json").read_text())
            for key in result.keys() - {"cases"}:
                if record[key] != result[key]:
                    raise RuntimeError(f"{case}: benchmark provenance changed: {key}")
            return case, record["cases"][case]

        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [pool.submit(run_case, case) for case in cases]
            for future in as_completed(futures):
                case, measured = future.result()
                result["cases"][case] = measured
                gas = measured["measurements"]["sierra-gas"]["entrypoint_l2_gas"]
                print(
                    f"{case}: {gas:,} Sierra gas; both repetitions/modes verified",
                    flush=True,
                )
                (output / "results.json").write_text(
                    json.dumps(result, indent=2) + "\n"
                )
        print(f"Verified all {len(cases)} cases: {output / 'results.json'}")
        return
    for case in cases:
        contract = CASES[case]["contract"]
        measurements = {}
        for mode in ["sierra-gas", "cairo-steps"]:
            attempts = []
            for repetition in [1, 2]:
                test = f"stark_loot_tests::cache_probes::gas_cache_{case}"
                command = [
                    "snforge",
                    "test",
                    test,
                    "--exact",
                    "--release",
                    "--gas-report",
                    "--tracked-resource",
                    mode,
                    "--detailed-resources",
                    "--save-trace-data",
                    "--color",
                    "never",
                    "--fuzzer-seed",
                    "360029",
                    "--max-n-steps",
                    "4294967295",
                ]
                print(f"{case}: {mode}, run {repetition}/2", flush=True)
                log_path = output / f"{case}.{mode}.{repetition}.log"
                trace_path = (
                    ROOT / "snfoundry_trace" / (test.replace("::", "_") + ".json")
                )
                trace_path.unlink(missing_ok=True)
                log = run_logged(
                    command,
                    log_path,
                    cwd=ROOT,
                    env={**os.environ, "SCARB_UI_VERBOSITY": "no-warnings"},
                )
                if "Tests: 1 passed, 0 failed" not in log:
                    raise RuntimeError(f"Expected one successful test: {log_path}")
                probes = find_probe(json.loads(trace_path.read_text()), contract)
                if len(probes) != 1:
                    raise RuntimeError(
                        f"Expected one {contract} trace, found {len(probes)}"
                    )
                tree = resource_tree(probes[0])
                check_invariants(case, tree)
                attempts.append(
                    {"entrypoint_l2_gas": gas_row(log, contract), "trace": tree}
                )
            if attempts[0] != attempts[1]:
                raise RuntimeError(f"Non-reproducible measurement for {case}/{mode}")
            measurements[mode] = attempts[0]
        result["cases"][case] = {"contract": contract, "measurements": measurements}
        print(
            f"  {contract}.run: {measurements['sierra-gas']['entrypoint_l2_gas']:,} Sierra gas "
            "(identical in both runs)",
            flush=True,
        )
        (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"Verified identical gas and resources in both runs: {output / 'results.json'}"
    )


if __name__ == "__main__":
    main()
