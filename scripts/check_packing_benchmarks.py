#!/usr/bin/env python3
"""Compare a complete reproduced run with the reviewed benchmark baseline.

Exact metric and compiler equality is deliberate with the pinned toolchain.
The Scarb host architecture is recorded as provenance, not a performance gate.
Improvements also require refreshing the checked-in evidence. Source hashes
document provenance but are not performance metrics: a harmless source edit need
not change the baseline.
"""

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG_KEYS = (
    "scarb", "snforge", "profile", "repetitions", "fuzzer_seed",
    "measurement_boundary", "artifact_build",
)


def compiler_identity(version):
    # Keep every non-architecture line, including the Scarb build and Cairo/Sierra versions.
    # Do not whitelist known compiler versions or ignore an unfamiliar future compiler line.
    return "\n".join(line for line in version.splitlines() if not line.startswith("arch: "))


def check_results(actual, baseline, cases):
    if not cases:
        raise ValueError("Expected a nonempty probe case manifest")
    for label, result in (("reproduced", actual), ("baseline", baseline)):
        if set(result["cases"]) != set(cases):
            raise ValueError(f"{label} case set differs from packing_probe_cases.json")
        for case, contract in cases.items():
            entry = result["cases"][case]
            if entry["contract"] != contract:
                raise ValueError(f"{label} probe contract differs for {case}")
            if set(entry["measurements"]) != {"sierra-gas", "cairo-steps"}:
                raise ValueError(f"{label} accounting modes differ for {case}")
    for key in CONFIG_KEYS:
        reproduced, reviewed = actual[key], baseline[key]
        if key == "scarb":
            reproduced, reviewed = compiler_identity(reproduced), compiler_identity(reviewed)
        if reproduced != reviewed:
            raise ValueError(f"Benchmark configuration changed: {key}")
    changed = [case for case in cases if actual["cases"][case] != baseline["cases"][case]]
    if changed:
        raise ValueError("Gas or resources changed for: " + ", ".join(changed))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--actual", type=Path, default=ROOT / "target/packing-benchmarks/results.json")
    parser.add_argument("--baseline", type=Path, default=ROOT / "benchmarks/packing/results.json")
    args = parser.parse_args()
    try:
        cases = json.loads((ROOT / "scripts/packing_probe_cases.json").read_text())
        check_results(json.loads(args.actual.read_text()), json.loads(args.baseline.read_text()), cases)
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit(f"Packing benchmark check failed: {error}. Reproduce the full run, "
                         "review the changes, then deliberately update the baseline and tables.") from error
    print(f"All {len(cases)} probe cases match the committed gas and resource baseline")


if __name__ == "__main__":
    main()
