#!/usr/bin/env python3
"""Check every cache probe's syscall tree without tracing exhaustive fixture tests."""

import json
import os
from bench_cache import (
    CASES,
    ROOT,
    check_invariants,
    find_probe,
    resource_tree,
    run_logged,
)


def main():
    output = ROOT / "target/cache-resources"
    output.mkdir(parents=True, exist_ok=True)
    for case in CASES:
        (
            ROOT
            / "snfoundry_trace"
            / f"stark_loot_tests_cache_probes_gas_cache_{case}.json"
        ).unlink(missing_ok=True)
    command = [
        "snforge",
        "test",
        "cache_probes::",
        "--release",
        "--tracked-resource",
        "cairo-steps",
        "--save-trace-data",
        "--detailed-resources",
        "--max-n-steps",
        "4294967295",
        "--max-threads",
        "1",
        "--color",
        "never",
    ]
    run_logged(
        command,
        output / "run.log",
        cwd=ROOT,
        env={**os.environ, "SCARB_UI_VERBOSITY": "no-warnings"},
    )
    result = {}
    for case, spec in CASES.items():
        path = (
            ROOT
            / "snfoundry_trace"
            / f"stark_loot_tests_cache_probes_gas_cache_{case}.json"
        )
        probes = find_probe(json.loads(path.read_text()), spec["contract"])
        if len(probes) != 1:
            raise RuntimeError(f"{case}: expected exactly one caller")
        tree = resource_tree(probes[0])
        check_invariants(case, tree)
        result[case] = tree
    (output / "resources.json").write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"All {len(result)} cache caller syscall trees satisfy their read/write/event/Keccak invariants"
    )


if __name__ == "__main__":
    main()
