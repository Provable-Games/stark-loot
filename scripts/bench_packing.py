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


ROOT = Path(__file__).resolve().parents[1]
CASES = json.loads((ROOT / "scripts/packing_probe_cases.json").read_text())


def capture(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def gas_row(log, contract):
    # Every test contains exactly one invocation of its single-entrypoint probe.
    table = log.split(f"| {contract} Contract", 1)[1]
    row = re.search(r"\| run\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)"
                    r"\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|", table)
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
        "nested_calls": [resource_tree(child["EntryPointCall"])
                         for child in trace["nested_calls"] if "EntryPointCall" in child],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cases", nargs="*", help="Case names from packing_probe_cases.json (default: all)")
    parser.add_argument("--output", type=Path, default=ROOT / "target/packing-benchmarks")
    args = parser.parse_args()
    cases = args.cases or list(CASES)
    unknown = set(cases) - CASES.keys()
    if unknown:
        parser.error(f"Unknown cases: {sorted(unknown)}")
    help_text = capture("snforge", "test", "--help")
    for flag in ["--gas-report", "--tracked-resource", "--detailed-resources", "--save-trace-data"]:
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
            for path in sorted([*ROOT.glob("src/*.cairo"), *ROOT.glob("tests/packing_*.cairo"),
                                ROOT / "Scarb.toml", ROOT / "Scarb.lock", ROOT / ".tool-versions"])
        },
        "cases": {},
    }
    for case in cases:
        contract = CASES[case]
        measurements = {}
        for mode in ["sierra-gas", "cairo-steps"]:
            attempts = []
            for repetition in [1, 2]:
                test = f"stark_loot_tests::packing_probes::gas_probe_{case}"
                command = ["snforge", "test", test, "--exact", "--release", "--gas-report",
                           "--tracked-resource", mode, "--detailed-resources", "--save-trace-data",
                           "--color", "never", "--fuzzer-seed", "360029", "--max-n-steps", "4294967295"]
                print(f"{case}: {mode}, run {repetition}/2", flush=True)
                log_path = output / f"{case}.{mode}.{repetition}.log"
                trace_path = ROOT / "snfoundry_trace" / (test.replace("::", "_") + ".json")
                trace_path.unlink(missing_ok=True)
                with log_path.open("w") as log:
                    subprocess.run(command, cwd=ROOT, env={**os.environ, "SCARB_UI_VERBOSITY": "no-warnings"},
                                   stdout=log, stderr=subprocess.STDOUT, check=True)
                log = log_path.read_text()
                if "Tests: 1 passed, 0 failed" not in log:
                    raise RuntimeError(f"Expected one successful test: {log_path}")
                probes = find_probe(json.loads(trace_path.read_text()), contract)
                if len(probes) != 1:
                    raise RuntimeError(f"Expected one {contract} trace, found {len(probes)}")
                attempts.append({"entrypoint_l2_gas": gas_row(log, contract),
                                 "trace": resource_tree(probes[0])})
            if attempts[0] != attempts[1]:
                raise RuntimeError(f"Non-reproducible measurement for {case}/{mode}")
            measurements[mode] = attempts[0]
        result["cases"][case] = {"contract": contract, "measurements": measurements}
        print(f"  {contract}.run: {measurements['sierra-gas']['entrypoint_l2_gas']:,} Sierra gas "
              "(identical in both runs)", flush=True)
        (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"Verified identical gas and resources in both runs: {output / 'results.json'}")


if __name__ == "__main__":
    main()
