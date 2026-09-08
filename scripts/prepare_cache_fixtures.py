#!/usr/bin/env python3
"""Prepare bounded cache fixtures from committed independent numeric fields and rendered names.

Never derive expectations from the production Cairo codec. Run before cache tests.
"""

import hashlib
import json
from pathlib import Path
from random import Random
from loot import LootGenerator, SLOTS

ROOT = Path(__file__).resolve().parents[1]
SLOT_NAMES = "weapon chest head waist foot hand neck ring".split()
FIELDS = "id greatness suffix_id name_prefix_id name_suffix_id".split()


def record(bag_id, bag, names):
    # Naive independent shifts/OR, including all hidden modifiers.
    word = 0
    for slot, offset in zip(SLOT_NAMES, [0, 29, 64, 93, 128, 157, 192, 221]):
        for field, shift, width in zip(FIELDS, [0, 7, 12, 17, 24], [7, 5, 5, 7, 5]):
            value = bag[slot][field]
            assert 0 <= value < 2**width
            word |= value << (offset + shift)
    # Flat, zero-padded object keys preserve field order in Foundry's JSON reader.
    values = [
        bag_id,
        word,
        *[bag[s][f] for s in SLOT_NAMES for f in FIELDS],
        *[names[s] for s in SLOT_NAMES],
    ]
    return {f"{i:02}": value for i, value in enumerate(values)}


def main():
    output = ROOT / "target/cache-fixtures"
    output.mkdir(parents=True, exist_ok=True)
    numeric = json.loads((ROOT / "tests/final_loot_concise.json").read_text())
    names = {
        k: v
        for b in json.loads((ROOT / "tests/loot.json").read_text())
        for k, v in b.items()
    }
    assert set(numeric) == set(names) == {str(i) for i in range(1, 8001)}
    assert {
        item["greatness"] for bag in numeric.values() for item in bag.values()
    } == set(range(21))
    records = [record(i, numeric[str(i)], names[str(i)]) for i in range(1, 8001)]
    for start in range(0, 8000, 250):
        (output / f"{start // 250:02}.json").write_text(
            json.dumps(
                {f"{i:04}": r for i, r in enumerate(records[start : start + 250])}
            )
        )
    sample_ids = [1, 2, 3, 4, 5, 7, 8, 9, 10, 99, 100, 999, 8000]
    (output / "sample.json").write_text(
        json.dumps({f"{i:04}": records[id - 1] for i, id in enumerate(sample_ids)})
    )
    rng = Random(360029)
    ids = sorted(
        {
            0,
            8001,
            2**64 - 1,
            *[10**i + d for i in range(1, 20) for d in (-1, 0, 1)],
            *[rng.getrandbits(64) for _ in range(64)],
        }
    )
    generator = LootGenerator()
    boundaries = []
    for bag_id in ids:
        # The public Python convenience method enforces original mint bounds; the
        # underlying independent Solidity transcription accepts these u64 seeds.
        items = {
            slot: generator._pluck(bag_id, prefix, source, lookup)
            for slot, prefix, source, lookup in SLOTS
        }
        bag = {
            s: {f: items[s]["item_id" if f == "id" else f] for f in FIELDS}
            for s in SLOT_NAMES
        }
        boundaries.append(
            record(bag_id, bag, {s: items[s]["current_name"] for s in SLOT_NAMES})
        )
    (output / "boundaries.json").write_text(
        json.dumps({f"{i:04}": r for i, r in enumerate(boundaries)})
    )
    digest = hashlib.sha256(
        "".join(f"{hex(r['01'])}\n" for r in records).encode()
    ).hexdigest()
    assert digest == "7a205e4308aa4301213e9cb8e4aef82a2dc6a2fae8f7147e1442516ecd305e74"
    (output / "sha256.txt").write_text(digest + "\n")
    print(
        f"Prepared 32 batches, sample and {len(ids)} boundary/random bags; packed SHA256: {digest}"
    )


if __name__ == "__main__":
    main()
