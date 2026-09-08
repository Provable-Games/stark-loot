use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use stark_loot::contract::IStarkLootDispatcherTrait;
use stark_loot::core::{LootBag, LootItem, get_loot_bag, get_packed_loot_bag};
use stark_loot::packed::{LootBagPackingTrait, PackedLootBag, PackedLootBagTrait};
use stark_loot::types::Slot;
use crate::helpers::library;

// Enforced packed gas budgets on the pinned dev toolchain (whole-test measurements):
// - bench_packed_direct: 2,435,628 measured / 2,500,000 budget; 64,372 spare (2.6%).
// - bench_packed_library: 2,595,618 / 2,700,000; 104,382 spare (4.0%).
// - bench_packed_library_materialize: 2,794,448 / 2,900,000; 105,552 spare (3.8%).
// - bench_packed_library_one_item: 2,632,158 / 2,750,000; 117,842 spare (4.5%).
// - bench_packed_library_materialize_max_id: 2,926,688 / 3,050,000; 123,312 spare (4.2%).
// On an out-of-gas failure, run `snforge test bench_ --no-optimization` to include both
// expanded and packed benchmarks. See README's "Measured cost" table; review changed
// measurements before deliberately recalibrating budgets, including after toolchain changes.

fn reference_bag() -> LootBag {
    LootBag {
        weapon: LootItem {
            id: 10, greatness: 20, suffix_id: 4, name_prefix_id: 33, name_suffix_id: 12,
        },
        chest: LootItem {
            id: 50, greatness: 8, suffix_id: 8, name_prefix_id: 42, name_suffix_id: 12,
        },
        head: LootItem {
            id: 23, greatness: 5, suffix_id: 10, name_prefix_id: 45, name_suffix_id: 6,
        },
        waist: LootItem {
            id: 60, greatness: 11, suffix_id: 3, name_prefix_id: 66, name_suffix_id: 3,
        },
        foot: LootItem {
            id: 93, greatness: 19, suffix_id: 4, name_prefix_id: 17, name_suffix_id: 2,
        },
        hand: LootItem {
            id: 69, greatness: 7, suffix_id: 9, name_prefix_id: 47, name_suffix_id: 11,
        },
        neck: LootItem {
            id: 2, greatness: 15, suffix_id: 7, name_prefix_id: 19, name_suffix_id: 7,
        },
        ring: LootItem {
            id: 8, greatness: 7, suffix_id: 5, name_prefix_id: 11, name_suffix_id: 11,
        },
    }
}

#[test]
fn generation_and_codec_match_reference() {
    let expected = reference_bag();
    let packed = expected.pack();
    assert!(get_packed_loot_bag(1) == packed, "generated bag differs from bag 1 vector");
    assert!(packed.unpack() == expected, "unpacked bag differs from expected fields");
    assert!(
        packed.get_item(Slot::Weapon) == expected.weapon,
        "weapon item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Chest) == expected.chest,
        "chest item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Head) == expected.head,
        "head item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Waist) == expected.waist,
        "waist item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Foot) == expected.foot,
        "foot item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Hand) == expected.hand,
        "hand item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Neck) == expected.neck,
        "neck item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Ring) == expected.ring,
        "ring item mismatch for value {}",
        packed.value,
    );
}

#[test]
fn serialized_bag_is_one_felt() {
    let packed = reference_bag().pack();
    let mut data = array![];
    packed.serialize(ref data);
    assert!(
        data.span() == array![packed.value].span(), "serialization must contain exactly one felt",
    );
    let mut data = data.span();
    let decoded: PackedLootBag = Serde::deserialize(ref data).unwrap();
    assert!(decoded == packed, "serialized value did not round-trip");
    assert!(data.is_empty(), "serialization left unread data");
}

#[test]
#[available_gas(l2_gas: 2_500_000)]
fn bench_packed_direct() {
    get_packed_loot_bag(1);
}

#[test]
#[available_gas(l2_gas: 2_700_000)]
fn bench_packed_library() {
    library().get_packed_bag(1);
}

#[test]
fn bench_expanded_library_materialize() {
    assert!(library().get_bag(1) == reference_bag(), "library bag differs from bag 1 vector");
}

#[test]
#[available_gas(l2_gas: 2_900_000)]
fn bench_packed_library_materialize() {
    assert!(
        library().get_packed_bag(1).unpack() == reference_bag(),
        "packed library bag differs from bag 1 vector",
    );
}

#[test]
fn bench_expanded_library_one_item() {
    assert!(
        library().get_bag(1).weapon == reference_bag().weapon,
        "library weapon differs from bag 1 vector",
    );
}

#[test]
#[available_gas(l2_gas: 2_750_000)]
fn bench_packed_library_one_item() {
    assert!(
        library().get_packed_bag(1).get_item(Slot::Weapon) == reference_bag().weapon,
        "selected library weapon differs from bag 1 vector",
    );
}

#[test]
fn bench_expanded_direct_materialize() {
    assert!(get_loot_bag(1) == reference_bag(), "direct bag differs from bag 1 vector");
}

#[test]
fn bench_packed_direct_materialize() {
    assert!(
        get_packed_loot_bag(1).unpack() == reference_bag(),
        "direct packed bag differs from bag 1 vector",
    );
}

#[test]
fn bench_generate_then_pack() {
    get_loot_bag(1).pack();
}


#[test]
fn bag_one_matches_independent_bit_layout_vector() {
    // Calculated with Python integers from tests/final_loot_concise.json, using the documented
    // slot/field bit offsets. Pins wire format independently of this codec's round-trip.
    assert!(
        reference_bag()
            .pack()
            .value == 0x162ca7107267782016bd278a22249dd007086b7865aa297018a90864c424a0a,
        "bag 1 wire vector mismatch",
    );
}

fn uniform_bag(item: LootItem) -> LootBag {
    LootBag {
        weapon: item,
        chest: item,
        head: item,
        waist: item,
        foot: item,
        hand: item,
        neck: item,
        ring: item,
    }
}

fn zero_item() -> LootItem {
    LootItem { id: 0, greatness: 0, suffix_id: 0, name_prefix_id: 0, name_suffix_id: 0 }
}

#[test]
fn zero_and_maximum_width_bags_roundtrip() {
    let empty = uniform_bag(zero_item());
    assert!(empty.pack().value == 0, "zero bag must pack to zero");
    assert!((PackedLootBag { value: 0 }).unpack() == empty, "zero must unpack to empty fields");
    let max = uniform_bag(
        LootItem { id: 127, greatness: 31, suffix_id: 31, name_prefix_id: 127, name_suffix_id: 31 },
    );
    let packed = max.pack();
    assert!(packed.unpack() == max, "maximum-width fields did not round-trip");
    assert!(
        packed.value == 0x3ffffffffffffff03ffffffffffffff03ffffffffffffff03ffffffffffffff,
        "maximum-width payload differs from wire mask",
    );
}

#[test]
#[fuzzer(runs: 128)]
fn arbitrary_field_values_roundtrip(low: u128, high: u128) {
    // Allow all representable values, including non-canonical Loot IDs, to ensure that packing
    // is a lossless numeric codec rather than secretly depending on hash/modifier correlations.
    let mask: u128 = 0x3ffffffffffffff03ffffffffffffff;
    let low: felt252 = (low & mask).into();
    let high: felt252 = (high & mask).into();
    let packed = PackedLootBag { value: low + high * 0x100000000000000000000000000000000 };
    let bag = packed.unpack();
    assert!(bag.pack() == packed, "arbitrary packed fields did not round-trip");
    assert!(
        packed.get_item(Slot::Weapon) == bag.weapon,
        "weapon item mismatch for value {}",
        packed.value,
    );
    assert!(
        packed.get_item(Slot::Chest) == bag.chest, "chest item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Head) == bag.head, "head item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Waist) == bag.waist, "waist item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Foot) == bag.foot, "foot item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Hand) == bag.hand, "hand item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Neck) == bag.neck, "neck item mismatch for value {}", packed.value,
    );
    assert!(
        packed.get_item(Slot::Ring) == bag.ring, "ring item mismatch for value {}", packed.value,
    );
}

#[test]
#[fuzzer(runs: 64)]
fn generated_packed_bags_match_expanded_for_u64_ids(bag_id: u64) {
    let expected = get_loot_bag(bag_id);
    let packed = get_packed_loot_bag(bag_id);
    assert!(packed == expected.pack(), "packed generation mismatch for bag {bag_id}");
    assert!(packed.unpack() == expected, "unpacked bag differs from expected fields");
}

#[test]
fn generated_packed_bags_match_at_decimal_boundaries() {
    assert!(get_packed_loot_bag(0).unpack() == get_loot_bag(0), "generation mismatch at bag zero");
    assert!(
        get_packed_loot_bag(0xffffffffffffffff).unpack() == get_loot_bag(0xffffffffffffffff),
        "generation mismatch at maximum u64 bag ID",
    );
    let mut power = 10_u64;
    loop {
        assert!(
            get_packed_loot_bag(power - 1).unpack() == get_loot_bag(power - 1),
            "generation mismatch below decimal boundary {power}",
        );
        assert!(
            get_packed_loot_bag(power).unpack() == get_loot_bag(power),
            "generation mismatch at decimal boundary {power}",
        );
        assert!(
            get_packed_loot_bag(power + 1).unpack() == get_loot_bag(power + 1),
            "generation mismatch above decimal boundary {power}",
        );
        if power == 10_000_000_000_000_000_000 {
            break;
        }
        power *= 10;
    };
}

#[test]
fn both_bag_types_occupy_one_storage_felt() {
    assert!(
        starknet::storage_access::Store::<PackedLootBag>::size() == 1,
        "PackedLootBag must occupy one storage felt",
    );
    assert!(
        starknet::storage_access::Store::<LootBag>::size() == 1,
        "LootBag must occupy one storage felt",
    );
}

#[test]
#[should_panic(expected: "item id packing overflow")]
fn rejects_overflowing_id() {
    let mut item = zero_item();
    item.id = 128;
    uniform_bag(item).pack();
}

#[test]
#[should_panic(expected: "greatness packing overflow")]
fn rejects_overflowing_greatness() {
    let mut item = zero_item();
    item.greatness = 32;
    uniform_bag(item).pack();
}

#[test]
#[should_panic(expected: "suffix packing overflow")]
fn rejects_overflowing_suffix_id() {
    let mut item = zero_item();
    item.suffix_id = 32;
    uniform_bag(item).pack();
}

#[test]
#[should_panic(expected: "prefix packing overflow")]
fn rejects_overflowing_name_prefix_id() {
    let mut item = zero_item();
    item.name_prefix_id = 128;
    uniform_bag(item).pack();
}

#[test]
#[should_panic(expected: "name suffix packing overflow")]
fn rejects_overflowing_name_suffix_id() {
    let mut item = zero_item();
    item.name_suffix_id = 32;
    uniform_bag(item).pack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_58() {
    (PackedLootBag { value: 0x400000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_63() {
    (PackedLootBag { value: 0x8000000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_122() {
    (PackedLootBag { value: 0x4000000000000000000000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_127() {
    (PackedLootBag { value: 0x80000000000000000000000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_186() {
    (PackedLootBag { value: 0x40000000000000000000000000000000000000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_191() {
    (PackedLootBag { value: 0x800000000000000000000000000000000000000000000000 }).unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_250() {
    (PackedLootBag { value: 0x400000000000000000000000000000000000000000000000000000000000000 })
        .unpack();
}

#[test]
#[should_panic(expected: "nonzero bag padding")]
fn rejects_padding_bit_251() {
    (PackedLootBag { value: 0x800000000000000000000000000000000000000000000000000000000000000 })
        .unpack();
}

// Independent Python LootGenerator._pluck vector for the largest accepted bag ID.
fn reference_max_bag() -> LootBag {
    LootBag {
        weapon: LootItem {
            id: 14, greatness: 9, suffix_id: 2, name_prefix_id: 4, name_suffix_id: 16,
        },
        chest: LootItem {
            id: 51, greatness: 0, suffix_id: 2, name_prefix_id: 1, name_suffix_id: 16,
        },
        head: LootItem {
            id: 53, greatness: 3, suffix_id: 5, name_prefix_id: 37, name_suffix_id: 1,
        },
        waist: LootItem {
            id: 29, greatness: 0, suffix_id: 10, name_prefix_id: 49, name_suffix_id: 10,
        },
        foot: LootItem {
            id: 62, greatness: 11, suffix_id: 7, name_prefix_id: 15, name_suffix_id: 9,
        },
        hand: LootItem {
            id: 71, greatness: 18, suffix_id: 9, name_prefix_id: 40, name_suffix_id: 1,
        },
        neck: LootItem {
            id: 2, greatness: 18, suffix_id: 10, name_prefix_id: 25, name_suffix_id: 16,
        },
        ring: LootItem {
            id: 8, greatness: 12, suffix_id: 13, name_prefix_id: 37, name_suffix_id: 13,
        },
    }
}


#[test]
fn bench_packed_direct_max_id() {
    get_packed_loot_bag(0xffffffffffffffff);
}

#[test]
fn bench_packed_library_max_id() {
    library().get_packed_bag(0xffffffffffffffff);
}

#[test]
fn bench_expanded_library_max_id() {
    library().get_bag(0xffffffffffffffff);
}

#[test]
#[available_gas(l2_gas: 3_050_000)]
fn bench_packed_library_materialize_max_id() {
    assert!(
        library().get_packed_bag(0xffffffffffffffff).unpack() == reference_max_bag(),
        "packed library bag differs from maximum-ID vector",
    );
}

#[test]
fn bench_expanded_library_materialize_max_id() {
    assert!(
        library().get_bag(0xffffffffffffffff) == reference_max_bag(),
        "library bag differs from maximum-ID vector",
    );
}

#[test]
fn packed_entrypoint_returns_exactly_one_felt() {
    let loot = library();
    let result = starknet::syscalls::library_call_syscall(
        loot.class_hash, selector!("get_packed_bag"), array![1].span(),
    )
        .unwrap();
    assert!(
        result == array![reference_bag().pack().value].span(),
        "packed entrypoint must return the single golden felt",
    );
}

#[starknet::interface]
trait IPackedBagStore<TState> {
    fn write_bag(ref self: TState, bag: LootBag);
    fn read_bag(self: @TState) -> LootBag;
    fn write_packed(ref self: TState, bag: PackedLootBag);
    fn read_packed(self: @TState) -> PackedLootBag;
}

#[starknet::contract]
mod PackedBagStore {
    use stark_loot::core::LootBag;
    use stark_loot::packed::PackedLootBag;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::IPackedBagStore;

    #[storage]
    struct Storage {
        bag: LootBag,
        packed: PackedLootBag,
    }

    #[abi(embed_v0)]
    impl StoreImpl of IPackedBagStore<ContractState> {
        fn write_bag(ref self: ContractState, bag: LootBag) {
            self.bag.write(bag);
        }
        fn read_bag(self: @ContractState) -> LootBag {
            self.bag.read()
        }
        fn write_packed(ref self: ContractState, bag: PackedLootBag) {
            self.packed.write(bag);
        }
        fn read_packed(self: @ContractState) -> PackedLootBag {
            self.packed.read()
        }
    }
}

#[test]
fn storage_preserves_field_access_and_packed_values() {
    let contract = declare("PackedBagStore").unwrap().contract_class();
    let (address, _) = contract.deploy(@array![]).unwrap();
    let store = IPackedBagStoreDispatcher { contract_address: address };
    let bag = reference_bag();
    store.write_bag(bag);
    store.write_packed(bag.pack());
    assert!(store.read_bag() == bag, "stored LootBag fields did not round-trip");
    assert!(store.read_packed().unpack() == bag, "stored PackedLootBag fields did not round-trip");
    // Verify the actual storage word, not merely Store::size() or a codec round-trip.
    assert!(
        snforge_std::load(address, selector!("bag"), 1).span() == array![bag.pack().value].span(),
        "LootBag storage word differs from packed payload",
    );
    assert!(
        snforge_std::load(address, selector!("packed"), 1)
            .span() == array![bag.pack().value]
            .span(),
        "PackedLootBag storage word differs from packed payload",
    );
}
