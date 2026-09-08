#!/usr/bin/env python3
"""
Utility script that mirrors the original Loot contract logic.

It can produce deterministic Loot bag metadata (names, greatness, suffix/name unlocks)
for any bag id between 1 and 8000 and compare the rendered names against the
tests/loot.json fixture to guarantee parity with Ethereum Loot.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Dict, Iterable, List, Tuple


# --------------------------------------------------------------------------------------
# Loot constants (verbatim from the Solidity contract)
# --------------------------------------------------------------------------------------
WEAPONS = [
    "Warhammer",
    "Quarterstaff",
    "Maul",
    "Mace",
    "Club",
    "Katana",
    "Falchion",
    "Scimitar",
    "Long Sword",
    "Short Sword",
    "Ghost Wand",
    "Grave Wand",
    "Bone Wand",
    "Wand",
    "Grimoire",
    "Chronicle",
    "Tome",
    "Book",
]

CHEST_ARMOR = [
    "Divine Robe",
    "Silk Robe",
    "Linen Robe",
    "Robe",
    "Shirt",
    "Demon Husk",
    "Dragonskin Armor",
    "Studded Leather Armor",
    "Hard Leather Armor",
    "Leather Armor",
    "Holy Chestplate",
    "Ornate Chestplate",
    "Plate Mail",
    "Chain Mail",
    "Ring Mail",
]

HEAD_ARMOR = [
    "Ancient Helm",
    "Ornate Helm",
    "Great Helm",
    "Full Helm",
    "Helm",
    "Demon Crown",
    "Dragon's Crown",
    "War Cap",
    "Leather Cap",
    "Cap",
    "Crown",
    "Divine Hood",
    "Silk Hood",
    "Linen Hood",
    "Hood",
]

WAIST_ARMOR = [
    "Ornate Belt",
    "War Belt",
    "Plated Belt",
    "Mesh Belt",
    "Heavy Belt",
    "Demonhide Belt",
    "Dragonskin Belt",
    "Studded Leather Belt",
    "Hard Leather Belt",
    "Leather Belt",
    "Brightsilk Sash",
    "Silk Sash",
    "Wool Sash",
    "Linen Sash",
    "Sash",
]

FOOT_ARMOR = [
    "Holy Greaves",
    "Ornate Greaves",
    "Greaves",
    "Chain Boots",
    "Heavy Boots",
    "Demonhide Boots",
    "Dragonskin Boots",
    "Studded Leather Boots",
    "Hard Leather Boots",
    "Leather Boots",
    "Divine Slippers",
    "Silk Slippers",
    "Wool Shoes",
    "Linen Shoes",
    "Shoes",
]

HAND_ARMOR = [
    "Holy Gauntlets",
    "Ornate Gauntlets",
    "Gauntlets",
    "Chain Gloves",
    "Heavy Gloves",
    "Demon's Hands",
    "Dragonskin Gloves",
    "Studded Leather Gloves",
    "Hard Leather Gloves",
    "Leather Gloves",
    "Divine Gloves",
    "Silk Gloves",
    "Wool Gloves",
    "Linen Gloves",
    "Gloves",
]

NECKLACES = [
    "Necklace",
    "Amulet",
    "Pendant",
]

RINGS = [
    "Gold Ring",
    "Silver Ring",
    "Bronze Ring",
    "Platinum Ring",
    "Titanium Ring",
]

SUFFIXES = [
    "of Power",
    "of Giants",
    "of Titans",
    "of Skill",
    "of Perfection",
    "of Brilliance",
    "of Enlightenment",
    "of Protection",
    "of Anger",
    "of Rage",
    "of Fury",
    "of Vitriol",
    "of the Fox",
    "of Detection",
    "of Reflection",
    "of the Twins",
]

NAME_PREFIXES = [
    "Agony",
    "Apocalypse",
    "Armageddon",
    "Beast",
    "Behemoth",
    "Blight",
    "Blood",
    "Bramble",
    "Brimstone",
    "Brood",
    "Carrion",
    "Cataclysm",
    "Chimeric",
    "Corpse",
    "Corruption",
    "Damnation",
    "Death",
    "Demon",
    "Dire",
    "Dragon",
    "Dread",
    "Doom",
    "Dusk",
    "Eagle",
    "Empyrean",
    "Fate",
    "Foe",
    "Gale",
    "Ghoul",
    "Gloom",
    "Glyph",
    "Golem",
    "Grim",
    "Hate",
    "Havoc",
    "Honour",
    "Horror",
    "Hypnotic",
    "Kraken",
    "Loath",
    "Maelstrom",
    "Mind",
    "Miracle",
    "Morbid",
    "Oblivion",
    "Onslaught",
    "Pain",
    "Pandemonium",
    "Phoenix",
    "Plague",
    "Rage",
    "Rapture",
    "Rune",
    "Skull",
    "Sol",
    "Soul",
    "Sorrow",
    "Spirit",
    "Storm",
    "Tempest",
    "Torment",
    "Vengeance",
    "Victory",
    "Viper",
    "Vortex",
    "Woe",
    "Wrath",
    "Light's",
    "Shimmering",
]

NAME_SUFFIXES = [
    "Bane",
    "Root",
    "Bite",
    "Song",
    "Roar",
    "Grasp",
    "Instrument",
    "Glow",
    "Bender",
    "Shadow",
    "Whisper",
    "Shout",
    "Growl",
    "Tear",
    "Peak",
    "Form",
    "Sun",
    "Moon",
]

WEAPON_IDS = [72, 73, 74, 75, 76, 42, 43, 44, 45, 46, 9, 10, 11, 12, 13, 14, 15, 16]
CHEST_IDS = [17, 18, 19, 20, 21, 47, 48, 49, 50, 51, 77, 78, 79, 80, 81]
HEAD_IDS = [82, 83, 84, 85, 86, 52, 53, 54, 55, 56, 22, 23, 24, 25, 26]
WAIST_IDS = [87, 88, 89, 90, 91, 57, 58, 59, 60, 61, 27, 28, 29, 30, 31]
FOOT_IDS = [92, 93, 94, 95, 96, 62, 63, 64, 65, 66, 32, 33, 34, 35, 36]
HAND_IDS = [97, 98, 99, 100, 101, 67, 68, 69, 70, 71, 37, 38, 39, 40, 41]
NECK_IDS = [2, 3, 1]
RING_IDS = [8, 4, 5, 6, 7]

SUFFIX_IDS = list(range(1, 17))
NAME_PREFIX_IDS = list(range(1, len(NAME_PREFIXES) + 1))
NAME_SUFFIX_IDS = list(range(1, len(NAME_SUFFIXES) + 1))

def build_id_map(names: List[str], ids: List[int]) -> Dict[str, int]:
    return {name: id_ for name, id_ in zip(names, ids)}

WEAPON_ID_MAP = build_id_map(WEAPONS, WEAPON_IDS)
CHEST_ID_MAP = build_id_map(CHEST_ARMOR, CHEST_IDS)
HEAD_ID_MAP = build_id_map(HEAD_ARMOR, HEAD_IDS)
WAIST_ID_MAP = build_id_map(WAIST_ARMOR, WAIST_IDS)
FOOT_ID_MAP = build_id_map(FOOT_ARMOR, FOOT_IDS)
HAND_ID_MAP = build_id_map(HAND_ARMOR, HAND_IDS)
NECK_ID_MAP = build_id_map(NECKLACES, NECK_IDS)
RING_ID_MAP = build_id_map(RINGS, RING_IDS)
SUFFIX_ID_MAP = build_id_map(SUFFIXES, SUFFIX_IDS)
NAME_PREFIX_ID_MAP = build_id_map(NAME_PREFIXES, NAME_PREFIX_IDS)
NAME_SUFFIX_ID_MAP = build_id_map(NAME_SUFFIXES, NAME_SUFFIX_IDS)

SLOTS: Tuple[Tuple[str, str, List[str], Dict[str, int]], ...] = (
    ("weapon", "WEAPON", WEAPONS, WEAPON_ID_MAP),
    ("chest", "CHEST", CHEST_ARMOR, CHEST_ID_MAP),
    ("head", "HEAD", HEAD_ARMOR, HEAD_ID_MAP),
    ("waist", "WAIST", WAIST_ARMOR, WAIST_ID_MAP),
    ("foot", "FOOT", FOOT_ARMOR, FOOT_ID_MAP),
    ("hand", "HAND", HAND_ARMOR, HAND_ID_MAP),
    ("neck", "NECK", NECKLACES, NECK_ID_MAP),
    ("ring", "RING", RINGS, RING_ID_MAP),
)

MAX_BAG_ID = 8000
GREATNESS_MOD = 21
# Pin the committed fixture's field set and emission order, filtering numeric IDs.
# Cairo read_json sorts object keys on read; it does not require sorted JSON output.
VERBOSE_FIELDS = (
    "current_name", "final_name", "item_name", "greatness",
    "suffix", "name_prefix", "name_suffix",
)


# --------------------------------------------------------------------------------------
# Minimal Keccak-256 implementation (to avoid external dependencies)
# --------------------------------------------------------------------------------------
ROTATION_OFFSETS = [
    [0, 36, 3, 41, 18],
    [1, 44, 10, 45, 2],
    [62, 6, 43, 15, 61],
    [28, 55, 25, 21, 56],
    [27, 20, 39, 8, 14],
]

ROUND_CONSTANTS = [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000A,
    0x000000008000808B,
    0x800000000000008B,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800A,
    0x800000008000000A,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008,
]


def _rotl(value: int, shift: int) -> int:
    return ((value << shift) & ((1 << 64) - 1)) | (value >> (64 - shift))


def _keccak_f1600(state: List[int]) -> None:
    for rc in ROUND_CONSTANTS:
        c = [state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20] for x in range(5)]
        d = [c[(x - 1) % 5] ^ _rotl(c[(x + 1) % 5], 1) for x in range(5)]
        for x in range(5):
            for y in range(5):
                state[x + 5 * y] ^= d[x]

        b = [0] * 25
        for x in range(5):
            for y in range(5):
                new_x = y
                new_y = (2 * x + 3 * y) % 5
                idx = x + 5 * y
                b[new_x + 5 * new_y] = _rotl(state[idx], ROTATION_OFFSETS[x][y])

        for x in range(5):
            for y in range(5):
                idx = x + 5 * y
                state[idx] = b[idx] ^ ((~b[((x + 1) % 5) + 5 * y]) & b[((x + 2) % 5) + 5 * y])

        state[0] ^= rc


def keccak256(data: bytes) -> bytes:
    rate_bytes = 136  # 1088 bits
    state = [0] * 25
    padded = bytearray(data)
    padded.append(0x01)
    while len(padded) % rate_bytes != rate_bytes - 1:
        padded.append(0x00)
    padded.append(0x80)

    for offset in range(0, len(padded), rate_bytes):
        block = padded[offset : offset + rate_bytes]
        for i in range(rate_bytes // 8):
            chunk = block[i * 8 : (i + 1) * 8]
            state[i] ^= int.from_bytes(chunk, "little")
        _keccak_f1600(state)

    output = bytearray()
    while len(output) < 32:
        for value in state[: rate_bytes // 8]:
            output.extend(value.to_bytes(8, "little"))
            if len(output) >= 32:
                return bytes(output[:32])
        _keccak_f1600(state)

    return bytes(output[:32])


# --------------------------------------------------------------------------------------
# Loot logic (mirrors the Solidity contract)
# --------------------------------------------------------------------------------------
class LootGenerator:
    def __init__(self) -> None:
        pass

    @staticmethod
    def _random(token_id: int, key_prefix: str) -> int:
        seed = f"{key_prefix}{token_id}".encode("utf-8")
        return int.from_bytes(keccak256(seed), "big")

    def _pluck(self, token_id: int, key_prefix: str, source: List[str], id_lookup: Dict[str, int]) -> Dict[str, object]:
        rand = self._random(token_id, key_prefix)
        base = source[rand % len(source)]
        greatness = rand % GREATNESS_MOD

        suffix = SUFFIXES[rand % len(SUFFIXES)]
        name_prefix = NAME_PREFIXES[rand % len(NAME_PREFIXES)]
        name_suffix = NAME_SUFFIXES[rand % len(NAME_SUFFIXES)]
        item_id = id_lookup[base]
        suffix_id = SUFFIX_ID_MAP[suffix]
        name_prefix_id = NAME_PREFIX_ID_MAP[name_prefix]
        name_suffix_id = NAME_SUFFIX_ID_MAP[name_suffix]

        current_name = base
        suffix_unlocked = greatness > 14
        name_unlocked = greatness >= 19

        if suffix_unlocked:
            current_name = f"{current_name} {suffix}"
        if name_unlocked:
            current_name = f"\"{name_prefix} {name_suffix}\" {current_name}"
            if greatness == 20:
                current_name = f"{current_name} +1"

        final_name = f"\"{name_prefix} {name_suffix}\" {base} {suffix} +1"

        return {
            "current_name": current_name,
            "final_name": final_name,
            "item_name": base,
            "greatness": greatness,
            "suffix": suffix,
            "name_prefix": name_prefix,
            "name_suffix": name_suffix,
            "item_id": item_id,
            "suffix_id": suffix_id,
            "name_prefix_id": name_prefix_id,
            "name_suffix_id": name_suffix_id,
        }

    def get_bag_metadata(self, bag_id: int) -> Dict[str, Dict[str, object]]:
        if not 1 <= bag_id <= MAX_BAG_ID:
            raise ValueError(f"bag_id must be between 1 and {MAX_BAG_ID}")
        bag = {}
        for slot, prefix, source, id_lookup in SLOTS:
            bag[slot] = self._pluck(bag_id, prefix, source, id_lookup)
        return bag

    def get_bag_strings(self, bag_id: int) -> Dict[str, str]:
        return {slot: data["current_name"] for slot, data in self.get_bag_metadata(bag_id).items()}

    def get_bag_loot_items(self, bag_id: int) -> Dict[str, Dict[str, int]]:
        bag = self.get_bag_metadata(bag_id)
        concise: Dict[str, Dict[str, int]] = {}
        for slot, data in bag.items():
            concise[slot] = {
                "id": int(data["item_id"]),
                "greatness": int(data["greatness"]),
                "suffix_id": int(data["suffix_id"]),
                "name_prefix_id": int(data["name_prefix_id"]),
                "name_suffix_id": int(data["name_suffix_id"]),
            }
        return concise


# --------------------------------------------------------------------------------------
# CLI helpers
# --------------------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate deterministic Loot bags identical to the Ethereum contract.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--bag", type=int, help="Generate metadata for a single bag id.")
    group.add_argument("--range", nargs=2, type=int, metavar=("START", "END"), help="Generate metadata for a bag id range (inclusive).")
    group.add_argument("--all", action="store_true", help="Generate metadata for all 8000 bags.")
    format_group = parser.add_mutually_exclusive_group()
    format_group.add_argument("--names-only", action="store_true", help="Emit only the rendered item names (matching tests/loot.json).")
    format_group.add_argument("--fixture-schema", action="store_true", help="Emit the seven-field verbose fixture schema in its committed field order, omitting numeric IDs.")
    parser.add_argument("--output", type=Path, help="Optional path to write JSON output. Defaults to stdout.")
    parser.add_argument("--concise-output", type=Path, help="Optional path to write LootItem-style JSON output.")
    parser.add_argument("--check-fixture", type=Path, help="Optional path to tests/loot.json for parity verification.")
    parser.add_argument("--fixture-sample", type=int, default=10, help="Number of fixture bags to verify (default: 10).")
    return parser.parse_args()


def build_bag_id_list(args: argparse.Namespace) -> List[int]:
    if args.bag:
        return [args.bag]
    if args.range:
        start, end = args.range
        if start > end:
            raise ValueError("START must be <= END")
        return list(range(start, end + 1))
    if args.all or args.output or args.concise_output:
        return list(range(1, MAX_BAG_ID + 1))
    return [1]


def format_output(generator: LootGenerator, bag_ids: Iterable[int], names_only: bool,
                  fixture_schema: bool = False) -> Dict[str, object]:
    result: Dict[str, object] = {}
    for bag_id in bag_ids:
        if names_only:
            result[str(bag_id)] = generator.get_bag_strings(bag_id)
        elif fixture_schema:
            result[str(bag_id)] = {
                slot: {field: metadata[field] for field in VERBOSE_FIELDS}
                for slot, metadata in generator.get_bag_metadata(bag_id).items()
            }
        else:
            result[str(bag_id)] = generator.get_bag_metadata(bag_id)
    return result


def format_concise_output(generator: LootGenerator, bag_ids: Iterable[int]) -> Dict[str, Dict[str, Dict[str, int]]]:
    result: Dict[str, Dict[str, Dict[str, int]]] = {}
    for bag_id in bag_ids:
        result[str(bag_id)] = generator.get_bag_loot_items(bag_id)
    return result


def load_fixture(path: Path) -> Dict[int, Dict[str, str]]:
    with path.open("r", encoding="utf-8") as handle:
        raw = json.load(handle)
    fixture: Dict[int, Dict[str, str]] = {}
    for entry in raw:
        for bag_id_str, payload in entry.items():
            fixture[int(bag_id_str)] = payload
    return fixture


def compare_fixture(generator: LootGenerator, path: Path, sample: int) -> None:
    fixture = load_fixture(path)
    bag_ids = sorted(fixture.keys())[:sample]
    for bag_id in bag_ids:
        expected = fixture[bag_id]
        actual = generator.get_bag_strings(bag_id)
        if expected != actual:
            raise SystemExit(f"Mismatch detected for bag {bag_id}: expected {expected}, got {actual}")
    print(f"Fixture comparison succeeded for {len(bag_ids)} bag(s) using {path}")


def main() -> None:
    args = parse_args()
    generator = LootGenerator()

    if args.check_fixture:
        compare_fixture(generator, args.check_fixture, args.fixture_sample)

    bag_ids = build_bag_id_list(args)
    payload = format_output(generator, bag_ids, args.names_only, args.fixture_schema)

    json_kwargs = {"indent": 2, "ensure_ascii": False}
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, **json_kwargs)
        print(f"Wrote {len(payload)} bag(s) to {args.output}")
    elif not args.concise_output:
        json.dump(payload, sys.stdout, **json_kwargs)
        sys.stdout.write("\n")

    if args.concise_output:
        concise_payload = format_concise_output(generator, bag_ids)
        args.concise_output.parent.mkdir(parents=True, exist_ok=True)
        with args.concise_output.open("w", encoding="utf-8") as handle:
            json.dump(concise_payload, handle, **json_kwargs)
        print(f"Wrote {len(concise_payload)} bag(s) to {args.concise_output}")


if __name__ == "__main__":
    main()
