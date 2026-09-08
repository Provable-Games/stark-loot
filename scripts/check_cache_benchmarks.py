#!/usr/bin/env python3
"""Compare all cache gas/resource trees and artifact sizes with reviewed evidence.

Source hashes and git revisions are historical provenance, not metric gates.
The stateless CASM digest is gated against the pre-cache artifact to enforce its
byte-identical compatibility claim. Compiler versions are gated; host architecture
and compiler binary hashes are not portable.
"""

import argparse
import json
from pathlib import Path

try:
    from .check_packing_benchmarks import check_results as check_probe_results
except ImportError:
    from check_packing_benchmarks import check_results as check_probe_results

ROOT = Path(__file__).resolve().parents[1]
SIZE_KEYS = ("casm_words", "sierra_words", "largest_segment", "entrypoints")
STATELESS_CASM_PATH = (
    "target/release/stark_loot_stark_loot.compiled_contract_class.json"
)


def check_results(actual, baseline, cases):
    check_probe_results(actual, baseline, {k: v["contract"] for k, v in cases.items()})


def check_sizes(actual, baseline, cases, stateless_baseline):
    if actual["compiler"] != baseline["compiler"]:
        raise ValueError("Artifact compiler changed")
    expected = {v["contract"] for v in cases.values()} | {
        "stark_loot",
        "stark_loot_cache",
    }
    for label, result in (("reproduced", actual), ("baseline", baseline)):
        if set(result["classes"]) != expected:
            raise ValueError(
                f"{label} artifact class set differs from cache probe manifest"
            )
        for name in ("stark_loot", "stark_loot_cache"):
            if (
                result["classes"][name].get("test_artifact_matches_production")
                is not True
            ):
                raise ValueError(
                    f"{label} {name} test artifact does not match production"
                )
    for name in sorted(expected):
        for key in SIZE_KEYS:
            if actual["classes"][name][key] != baseline["classes"][name][key]:
                raise ValueError(f"Artifact measurement changed: {name}.{key}")
    expected_digest = stateless_baseline["sha256"][STATELESS_CASM_PATH]
    for label, result in (("reproduced", actual), ("baseline", baseline)):
        if result["classes"]["stark_loot"]["casm_sha256"] != expected_digest:
            raise ValueError(
                f"{label} stateless CASM differs from the pre-cache artifact; "
                "review the byte-identical compatibility claim and its evidence"
            )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--actual", type=Path, default=ROOT / "target/cache-benchmarks/results.json"
    )
    parser.add_argument(
        "--sizes", type=Path, default=ROOT / "target/cache-artifacts/sizes.json"
    )
    parser.add_argument(
        "--baseline-dir",
        type=Path,
        default=ROOT / "benchmarks/cache",
    )
    args = parser.parse_args()
    try:
        cases = json.loads((ROOT / "scripts/cache_probe_cases.json").read_text())
        check_results(
            json.loads(args.actual.read_text()),
            json.loads((args.baseline_dir / "results.json").read_text()),
            cases,
        )
        check_sizes(
            json.loads(args.sizes.read_text()),
            json.loads((args.baseline_dir / "sizes.json").read_text()),
            cases,
            json.loads((args.baseline_dir / "baseline.json").read_text()),
        )
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit(
            f"Cache benchmark check failed: {error}. Reproduce the full run, review changes, then deliberately update the baseline and tables."
        ) from error
    print(
        f"All {len(cases)} cache probes and artifact sizes match the committed baseline"
    )


if __name__ == "__main__":
    main()
