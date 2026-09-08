#!/usr/bin/env python3
"""Enforce independent production budgets after a fresh `scarb --release build`.

This script inspects artifacts on disk and cannot establish their freshness.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = ROOT / "target/release/stark_loot_stark_loot.compiled_contract_class.json"
CACHE_ARTIFACT = (
    ROOT / "target/release/stark_loot_stark_loot_cache.compiled_contract_class.json"
)
MAX_CASM_WORDS = 21_000
BASELINE_CASM_WORDS = 20_830  # Merged implementation base bdf9656, freshly rebuilt.
# Complete cache: 30,340 words, including generator, names, decoders and all wrappers.
# Fixed 32,000-word ceiling leaves 1,660 words (5.5%) for deliberate maintenance.
MAX_CACHE_CASM_WORDS = 32_000
BASELINE_CACHE_CASM_WORDS = 30_340


def check_artifact(name, path, budget, baseline):
    try:
        bytecode = json.loads(path.read_text())["bytecode"]
        if not isinstance(bytecode, list) or not bytecode:
            raise ValueError("bytecode must be a nonempty list")
        words = len(bytecode)
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit(
            f"Cannot read {name} release CASM artifact: {error}. "
            "Run `scarb --release build` first."
        ) from error
    print(
        f"{name} release CASM: {words:,} words (limit: {budget:,}; "
        f"{words - baseline:+,} vs applicable baseline)"
    )
    if words > budget:
        raise SystemExit(f"{name} release CASM exceeds its size budget")


def main():
    check_artifact("stark_loot", ARTIFACT, MAX_CASM_WORDS, BASELINE_CASM_WORDS)
    check_artifact(
        "stark_loot_cache",
        CACHE_ARTIFACT,
        MAX_CACHE_CASM_WORDS,
        BASELINE_CACHE_CASM_WORDS,
    )


if __name__ == "__main__":
    main()
