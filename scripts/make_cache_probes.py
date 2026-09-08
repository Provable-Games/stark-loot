#!/usr/bin/env python3
"""Generate canonical single-operation cache callers and their case manifest.

Use --write to regenerate (including Scarb formatting), or --check to detect drift.

All data setup and assertions live outside each measured entrypoint. Generated
contracts stay in tests/ and never enter the two production artifacts.
"""

from pathlib import Path
import json
import argparse
import subprocess
import tempfile
import re

ROOT = Path(__file__).resolve().parents[1]
slots = "weapon chest head waist foot hand neck ring".split()
source = """//! Single-operation address/class callers. Setup and expectations are outside run.
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use stark_loot::cache::IStarkLootCacheDispatcherTrait;
use stark_loot::core::{LootBag, LootBagNames, LootItem, get_loot_bag, get_loot_bag_names, get_packed_loot_bag};
use stark_loot::packed::PackedLootBag;
use crate::cache::cache;
"""
cases = {}
interfaces = {}


def probe(name, ret, expr, extra=""):
    global source
    interface = interfaces.get(ret)
    if not interface:
        interface = "ICacheProbe" + str(len(interfaces))
        interfaces[ret] = interface
        source += f"""\n#[starknet::interface]
pub trait {interface}<TState> {{
    fn run(self: @TState, target: felt252, bag_id: u64) -> {ret};
}}
"""
    source += f"""\n#[starknet::contract]
mod {name} {{
    use stark_loot::cache::{{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait, IStarkLootCacheSafeDispatcher, IStarkLootCacheSafeDispatcherTrait}};
    use stark_loot::contract::{{IStarkLootDispatcher, IStarkLootLibraryDispatcher, IStarkLootDispatcherTrait}};
    use stark_loot::packed::{{PackedLootBag, PackedLootBagTrait}};
    use stark_loot::core::{{LootBag, LootBagNames, LootItem}};
    use stark_loot::types::Slot;
    use super::{interface};
    #[storage]
    struct Storage {{ bags: starknet::storage::Map<u64, PackedLootBag> }}
    #[abi(embed_v0)]
    impl Probe of {interface}<ContractState> {{
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> {ret} {{
            {extra}
            {expr}
        }}
    }}
}}
"""
    return interface


def case(
    label,
    name,
    interface,
    id,
    expected,
    setup=True,
    target="cache.contract_address.into()",
    reads=1,
    writes=0,
    keccak=0,
    events=0,
):
    global source
    source += f'''\n#[test]
#[feature("safe_dispatcher")]
fn gas_cache_{label}() {{
    let cache = cache();
    {"cache.add_to_cache(" + str(id) + ");" if setup else ""}
    let (address, _) = declare("{name}").unwrap().contract_class().deploy(@array![]).unwrap();
    let probe = {interface}Dispatcher {{ contract_address: address }};
    let expected = {expected};
    assert!(probe.run({target}, {id}) == expected);
    assert!(crate::cache::storage_word(address, {id}) == 0, "consumer storage changed");
}}
'''
    cases[label] = {
        "contract": name,
        "reads": reads,
        "writes": writes,
        "keccak": keccak,
        "events": events,
    }


strict = "IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }"
view = "IStarkLootDispatcher { contract_address: target.try_into().unwrap() }"
library = "IStarkLootLibraryDispatcher { class_hash: target.try_into().unwrap() }"
for method, ret, expected in [
    ("get_cached_packed_bag", "PackedLootBag", "get_packed_loot_bag(ID)"),
    ("get_cached_bag", "LootBag", "get_loot_bag(ID)"),
    ("get_cached_bag_names", "LootBagNames", "get_loot_bag_names(ID)"),
    ("is_cached", "bool", "true"),
    ("add_to_cache", "PackedLootBag", "get_packed_loot_bag(ID)"),
]:
    name = "Cache" + "".join(w.title() for w in method.split("_")) + "Probe"
    interface = probe(name, ret, f"{strict}.{method}(bag_id)")
    for id in [1, 8000]:
        case(f"{method}_{id}", name, interface, id, expected.replace("ID", str(id)))
    if method == "add_to_cache":
        for id in [1, 8000]:
            case(
                f"insert_{id}",
                name,
                interface,
                id,
                expected.replace("ID", str(id)),
                setup=False,
                writes=1,
                keccak=8,
                events=1,
            )
    if method == "is_cached":
        case("is_cached_miss", name, interface, 0, "false", setup=False)
for slot in ["weapon", "foot", "ring"]:
    name = "CacheSelected" + slot.title() + "Probe"
    interface = probe(
        name, "LootItem", f"{strict}.get_cached_item(bag_id, Slot::{slot.title()})"
    )
    for id in [1, 8000]:
        case(f"selected_{slot}_{id}", name, interface, id, f"get_loot_bag({id}).{slot}")
for method, ret, expected in [
    ("get_bag", "LootBag", "get_loot_bag(ID)"),
    ("get_packed_bag", "PackedLootBag", "get_packed_loot_bag(ID)"),
    ("get_bag_names", "LootBagNames", "get_loot_bag_names(ID)"),
] + [
    (
        f"get_{slot}_{kind}",
        ret,
        f"get_loot_bag_names(ID).{slot}"
        if kind == "name"
        else f"get_loot_bag(ID).{slot}" + ("" if kind == "item" else f".{kind}"),
    )
    for slot in slots
    for kind, ret in [
        ("item", "LootItem"),
        ("id", "u8"),
        ("greatness", "u8"),
        ("name", "ByteArray"),
    ]
]:
    name = "CacheCompat" + "".join(w.title() for w in method.split("_")) + "Probe"
    interface = probe(name, ret, f"{view}.{method}(bag_id)")
    case(method + "_hit", name, interface, 1, expected.replace("ID", "1"))
    if method in [
        "get_bag",
        "get_packed_bag",
        "get_weapon_item",
        "get_weapon_id",
        "get_ring_greatness",
        "get_weapon_name",
    ]:
        for id in [1, 8000]:
            case(
                method + f"_miss_{id}",
                name,
                interface,
                id,
                expected.replace("ID", str(id)),
                setup=False,
                keccak=8 if method in ["get_bag", "get_packed_bag"] else 1,
            )
    if method in ["get_bag", "get_packed_bag", "get_weapon_item"]:
        libname = name.replace("CacheCompat", "UnchangedLibrary")
        li = probe(libname, ret, f"{library}.{method}(bag_id)")
        for id in [1, 8000]:
            case(
                method + f"_library_{id}",
                libname,
                li,
                id,
                expected.replace("ID", str(id)),
                setup=False,
                target='*declare("stark_loot").unwrap().contract_class().class_hash',
                reads=0,
                keccak=8 if method != "get_weapon_item" else 1,
            )
            case(
                method + f"_deployed_{id}",
                name,
                interface,
                id,
                expected.replace("ID", str(id)),
                setup=False,
                target='Into::<starknet::ContractAddress, felt252>::into(declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0)',
                reads=0,
                keccak=8 if method != "get_weapon_item" else 1,
            )
# Same consumer ABI, selecting all 15 fields of the same three items.
for strategy, body in {
    "Packed": f"let packed = {strict}.get_cached_packed_bag(bag_id);\n            (packed.get_item(Slot::Weapon), packed.get_item(Slot::Foot), packed.get_item(Slot::Ring))",
    "Selected": f"let cache = {strict};\n            (cache.get_cached_item(bag_id, Slot::Weapon), cache.get_cached_item(bag_id, Slot::Foot), cache.get_cached_item(bag_id, Slot::Ring))",
    "Expanded": f"let bag = {strict}.get_cached_bag(bag_id);\n            (bag.weapon, bag.foot, bag.ring)",
}.items():
    name = "CacheReuse" + strategy + "Probe"
    interface = probe(name, "(LootItem, LootItem, LootItem)", body)
    for id in [1, 8000]:
        case(
            f"reuse_{strategy.lower()}_{id}",
            name,
            interface,
            id,
            f"{{ let bag = get_loot_bag({id}); (bag.weapon, bag.foot, bag.ring) }}",
            reads=3 if strategy == "Selected" else 1,
        )
for method, args in [
    ("get_cached_packed_bag", "bag_id"),
    ("get_cached_bag", "bag_id"),
    ("get_cached_item", "bag_id, Slot::Ring"),
    ("get_cached_bag_names", "bag_id"),
]:
    name = "CacheMiss" + "".join(w.title() for w in method.split("_")) + "Probe"
    interface = probe(
        name,
        "Array<felt252>",
        f"IStarkLootCacheSafeDispatcher {{ contract_address: target.try_into().unwrap() }}.{method}({args}).unwrap_err()",
    )
    case(
        method + "_strict_miss",
        name,
        interface,
        0,
        "{ let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC]; let message: ByteArray = \"bag not cached\"; message.serialize(ref error); error.append('ENTRYPOINT_FAILED'); error }",
        setup=False,
    )
# Render thresholds on a selected cached item.
bags = json.loads((ROOT / "tests/final_loot_concise.json").read_text())
for greatness in [14, 15, 18, 19, 20]:
    id = next(
        int(id) for id, b in bags.items() if b["weapon"]["greatness"] == greatness
    )
    name = "CacheCompatGetWeaponNameProbe"
    case(
        f"name_threshold_{greatness}",
        name,
        interfaces["ByteArray"],
        id,
        f"get_loot_bag_names({id}).weapon",
    )
# Compare a direct local scalar extraction with the unchanged public item decoder.
for slot in ["weapon", "foot", "ring"]:
    for field in ["id", "greatness"]:
        for strategy in ["Item", "Direct"]:
            name = "CacheScalar" + strategy + slot.title() + field.title() + "Probe"
            packed = "(PackedLootBag { value: target })"
            expr = (
                f"{packed}.get_item(Slot::{slot.title()}).{field}"
                if strategy == "Item"
                else f"super::super::cache_scalar_candidate::scalar({packed}, Slot::{slot.title()}, {str(field == 'greatness').lower()})"
            )
            interface = probe(name, "u8", expr)
            case(
                f"scalar_{strategy.lower()}_{slot}_{field}",
                name,
                interface,
                1,
                f"get_loot_bag(1).{slot}.{field}",
                setup=False,
                target="get_packed_loot_bag(1).value",
                reads=0,
            )

# Drop unused imports from each generated module; keep dispatcher traits when used.
source = source.replace(
    'probe.run(*declare("stark_loot").unwrap().contract_class().class_hash,',
    'probe.run((*declare("stark_loot").unwrap().contract_class().class_hash).into(),',
)


def clean_module(match):
    module = match.group()
    body = module[module.index("    #[storage]") :]

    def imports(m):
        path, names = m.groups()
        used = [
            n.strip()
            for n in names.split(",")
            if n.strip()
            and (
                re.search(r"\b" + n.strip() + r"\b", body)
                or (
                    n.strip().endswith("DispatcherTrait")
                    and n.strip().removesuffix("Trait")
                    in module.split("    #[storage]")[1]
                )
            )
        ]
        # DispatcherTrait also services a library dispatcher.
        if (
            path == "stark_loot::contract"
            and "IStarkLootLibraryDispatcher" in used
            and "IStarkLootDispatcherTrait" not in used
        ):
            used.append("IStarkLootDispatcherTrait")
        if path == "stark_loot::packed" and ".get_item(" in body:
            used.append("PackedLootBagTrait")
        return f"    use {path}::{{{', '.join(dict.fromkeys(used))}}};" if used else ""

    module = re.sub(r"    use ([\w:]+)::\{([^}]+)\};", imports, module)
    if "Slot::" not in body:
        module = module.replace("    use stark_loot::types::Slot;", "")
    if "IStarkLootCacheSafeDispatcher" in body:
        module = module.replace(
            "    #[abi(embed_v0)]",
            '    #[feature("safe_dispatcher")]\n    #[abi(embed_v0)]',
        )
    return module


source = re.sub(
    r"#\[starknet::contract\]\nmod .*?\n}\n", clean_module, source, flags=re.S
)


def generated_files():
    # Format a temporary file: --check never mutates either committed output.
    with tempfile.TemporaryDirectory() as directory:
        workspace = Path(directory)
        (workspace / "Scarb.toml").write_text(
            ' [package]\nname = "cache_probe_format"\nversion = "0.1.0"\nedition = "2024_07"\n'
        )
        (workspace / ".tool-versions").write_text((ROOT / ".tool-versions").read_text())
        (workspace / "src").mkdir()
        path = workspace / "src/lib.cairo"
        path.write_text(source)
        subprocess.run(["scarb", "fmt", str(path)], cwd=workspace, check=True)
        formatted = path.read_text()
    return {
        "tests/cache_probes.cairo": formatted,
        "scripts/cache_probe_cases.json": json.dumps(cases, indent=2) + "\n",
    }


def check_files(files, root=ROOT):
    changed = [
        name
        for name, content in files.items()
        if not (root / name).exists() or (root / name).read_text() != content
    ]
    if changed:
        raise ValueError(
            "Generated cache probes differ: "
            + ", ".join(changed)
            + "; run python3 scripts/make_cache_probes.py --write"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    args = parser.parse_args()
    files = generated_files()
    if args.check:
        try:
            check_files(files)
        except ValueError as error:
            raise SystemExit(str(error)) from error
    else:
        for name, content in files.items():
            (ROOT / name).write_text(content)
    print(
        f"{len(cases)} canonical cache probe cases {'checked' if args.check else 'written'}"
    )


if __name__ == "__main__":
    main()
