#!/usr/bin/env python3
"""Generate tests/loot_reference.cairo from tests/concise_loot.json."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("tests/concise_loot.json"),
        help="Path to concise_loot.json (default: tests/concise_loot.json)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("tests/loot_reference.cairo"),
        help="Output Cairo file (default: tests/loot_reference.cairo)",
    )
    return parser.parse_args()


def format_item(item: Dict[str, Any], indent: str) -> str:
    return (
        f"{indent}LootItem {{ "
        f"id: {item['id']}_u8, "
        f"greatness: {item['greatness']}_u8, "
        f"suffix_id: {item['suffix_id']}_u8, "
        f"name_prefix_id: {item['name_prefix_id']}_u8, "
        f"name_suffix_id: {item['name_suffix_id']}_u8 }}"
    )


def main() -> None:
    args = parse_args()
    data = json.loads(args.input.read_text())
    bag_ids = sorted(int(key) for key in data.keys())
    lines = [
        "// AUTO-GENERATED from tests/concise_loot.json. Do not edit manually.",
        "use core::array::ArrayTrait;",
        "use stark_loot::core::{LootBag, LootItem};",
        "",
        f"pub const LOOT_BAG_COUNT: usize = {len(bag_ids)};",
        "",
        "pub fn loot_reference() -> Array<LootBag> {",
        "    array![",
    ]

    for idx, bag_id in enumerate(bag_ids):
        bag = data[str(bag_id)]
        lines.append("        LootBag {")
        lines.append(format_item(bag["weapon"], "            weapon: ") + ",")
        lines.append(format_item(bag["chest"], "            chest: ") + ",")
        lines.append(format_item(bag["head"], "            head: ") + ",")
        lines.append(format_item(bag["waist"], "            waist: ") + ",")
        lines.append(format_item(bag["foot"], "            foot: ") + ",")
        lines.append(format_item(bag["hand"], "            hand: ") + ",")
        lines.append(format_item(bag["neck"], "            neck: ") + ",")
        lines.append(format_item(bag["ring"], "            ring: ") )
        lines.append("        }" + ("," if idx + 1 < len(bag_ids) else ""))

    lines += [
        "    ]",
        "}",
        "",
    ]

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines))
    print(f"Wrote {args.output} with {len(bag_ids)} LootBag entries")


if __name__ == "__main__":
    main()
