#!/usr/bin/env python3
"""Check the bounded coverage fixture, or regenerate it with --write."""

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
# Includes bag 1 and the complete 1000..1009 boundary in lexicographic order.
SAMPLE_BAG_COUNT = 13
CANONICAL_BAG_KEYS = {str(bag_id) for bag_id in range(1, 8001)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=ROOT / "tests/verbose_loot.json")
    parser.add_argument("--output", type=Path, default=ROOT / "tests/verbose_loot_sample.json")
    parser.add_argument("--write", action="store_true", help="Regenerate the sample from the full fixture")
    args = parser.parse_args()

    try:
        full = json.loads(args.input.read_text())
        if not isinstance(full, dict) or set(full) != CANONICAL_BAG_KEYS:
            raise ValueError("Full fixture must contain exactly bag keys 1 through 8000")
        expected = {key: full[key] for key in sorted(full)[:SAMPLE_BAG_COUNT]}
        if args.write:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(expected, indent=2, ensure_ascii=False) + "\n")
            print(f"Wrote {SAMPLE_BAG_COUNT} fixture bags to {args.output}")
        else:
            if json.loads(args.output.read_text()) != expected:
                raise ValueError("Coverage fixture differs from the canonical sample; regenerate with --write")
            print(f"Coverage fixture matches the first {SAMPLE_BAG_COUNT} lexicographic bags")
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
