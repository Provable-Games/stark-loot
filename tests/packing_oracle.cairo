//! Deliberately slow, independent whole-u256 oracle. Never linked into production.
//! Division/multiplication by 2^offset implements shifts; masks are applied independently
//! to every field. No production layout constants, lane helpers, or codec calls are reused.
use core::num::traits::Pow;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use stark_loot::core::{LootBag, LootItem};
use stark_loot::packed::{LootBagPackingTrait, PackedLootBag, PackedLootBagTrait};
use stark_loot::types::Slot;
use super::packing_probes::{
    IItemProbeSafeDispatcherTrait, IItemProbeSafeLibraryDispatcher, IUnpackProbeSafeDispatcherTrait,
    IUnpackProbeSafeLibraryDispatcher,
};

pub const PAYLOAD_MASK: u256 = 0x3ffffffffffffff03ffffffffffffff03ffffffffffffff03ffffffffffffff;
pub const GOLDEN: felt252 = 0x162ca7107267782016bd278a22249dd007086b7865aa297018a90864c424a0a;

fn extract(value: u256, offset: u32, width: u32) -> u8 {
    ((value / 2_u256.pow(offset)) & (2_u256.pow(width) - 1)).try_into().unwrap()
}

fn read_item(value: u256, offset: u32) -> LootItem {
    LootItem {
        id: extract(value, offset, 7),
        greatness: extract(value, offset + 7, 5),
        suffix_id: extract(value, offset + 12, 5),
        name_prefix_id: extract(value, offset + 17, 7),
        name_suffix_id: extract(value, offset + 24, 5),
    }
}

pub fn oracle_unpack(value: felt252) -> Option<LootBag> {
    let word: u256 = value.into();
    if (word & PAYLOAD_MASK) != word {
        return Option::None;
    }
    Option::Some(
        LootBag {
            weapon: read_item(word, 0),
            chest: read_item(word, 29),
            head: read_item(word, 64),
            waist: read_item(word, 93),
            foot: read_item(word, 128),
            hand: read_item(word, 157),
            neck: read_item(word, 192),
            ring: read_item(word, 221),
        },
    )
}

// Straight-line u256 packing also serves as the layout-preserving comparison arm.
// It is a test-only alternative, NOT the previous production implementation.
#[inline(always)]
fn write_item(item: LootItem) -> u256 {
    assert!(item.id < 128, "item id packing overflow");
    assert!(item.greatness < 32, "greatness packing overflow");
    assert!(item.suffix_id < 32, "suffix packing overflow");
    assert!(item.name_prefix_id < 128, "prefix packing overflow");
    assert!(item.name_suffix_id < 32, "name suffix packing overflow");
    let id: u256 = item.id.into();
    let greatness: u256 = item.greatness.into();
    let suffix: u256 = item.suffix_id.into();
    let prefix: u256 = item.name_prefix_id.into();
    let name_suffix: u256 = item.name_suffix_id.into();
    id | greatness * 128 | suffix * 4096 | prefix * 131072 | name_suffix * 16777216
}

pub fn oracle_pack(bag: LootBag) -> felt252 {
    let word = write_item(bag.weapon) | write_item(bag.chest)
        * 2_u256.pow(29) | write_item(bag.head)
        * 2_u256.pow(64) | write_item(bag.waist)
        * 2_u256.pow(93) | write_item(bag.foot)
        * 2_u256.pow(128) | write_item(bag.hand)
        * 2_u256.pow(157) | write_item(bag.neck)
        * 2_u256.pow(192) | write_item(bag.ring)
        * 2_u256.pow(221);
    word.try_into().unwrap()
}

fn check(value: felt252) {
    let expected = oracle_unpack(value).unwrap();
    let packed = PackedLootBag { value };
    assert!(packed.unpack() == expected, "unpack mismatch for value {value}");
    assert!(expected.pack().value == value, "pack mismatch for value {value}");
    assert!(oracle_pack(expected) == value, "oracle pack mismatch for value {value}");
    assert!(packed.get_item(Slot::Weapon) == expected.weapon, "weapon mismatch for value {value}");
    assert!(packed.get_item(Slot::Chest) == expected.chest, "chest mismatch for value {value}");
    assert!(packed.get_item(Slot::Head) == expected.head, "head mismatch for value {value}");
    assert!(packed.get_item(Slot::Waist) == expected.waist, "waist mismatch for value {value}");
    assert!(packed.get_item(Slot::Foot) == expected.foot, "foot mismatch for value {value}");
    assert!(packed.get_item(Slot::Hand) == expected.hand, "hand mismatch for value {value}");
    assert!(packed.get_item(Slot::Neck) == expected.neck, "neck mismatch for value {value}");
    assert!(packed.get_item(Slot::Ring) == expected.ring, "ring mismatch for value {value}");
}

#[test]
fn oracle_zero_maximum_and_golden() {
    check(0);
    check(PAYLOAD_MASK.try_into().unwrap());
    check(GOLDEN);
}

#[test]
fn oracle_every_field_and_payload_bit_in_isolation() {
    let slot_offsets = array![0_u32, 29, 64, 93, 128, 157, 192, 221];
    let field_offsets = array![0_u32, 7, 12, 17, 24];
    let widths = array![7_u32, 5, 5, 7, 5];
    for slot in 0..8_u32 {
        for field in 0..5_u32 {
            let offset = *slot_offsets.at(slot) + *field_offsets.at(field);
            let width = *widths.at(field);
            // Independently construct the expanded bag through its documented 40-field ABI.
            // This catches permutations even if pack and unpack share the same offset bug.
            for bit in 0..width + 1 {
                let field_value = if bit == width {
                    2_u256.pow(width) - 1
                } else {
                    2_u256.pow(bit)
                };
                let mut fields = array![];
                for index in 0..40_u32 {
                    fields
                        .append(
                            if index == slot * 5 + field {
                                field_value.try_into().unwrap()
                            } else {
                                0
                            },
                        );
                }
                let mut fields = fields.span();
                let bag: LootBag = Serde::deserialize(ref fields).unwrap();
                let expected: felt252 = (field_value * 2_u256.pow(offset)).try_into().unwrap();
                assert!(
                    oracle_pack(bag) == expected,
                    "oracle pack mismatch: slot {slot}, field {field}, bit/max {bit}",
                );
                assert!(
                    bag.pack().value == expected,
                    "production pack mismatch: slot {slot}, field {field}, bit/max {bit}",
                );
                assert!(
                    (PackedLootBag { value: expected }).unpack() == bag,
                    "production unpack mismatch: slot {slot}, field {field}, bit/max {bit}",
                );
                check(expected);
            };
        };
    };
}

#[test]
#[fuzzer(runs: 128, seed: 360029)]
fn oracle_random_valid_fields(low: u128, high: u128) {
    let word = u256 { low, high } & PAYLOAD_MASK;
    check(word.try_into().unwrap());
}

fn unpack_probe() -> IUnpackProbeSafeLibraryDispatcher {
    let class = declare("UnpackProbe").unwrap().contract_class();
    IUnpackProbeSafeLibraryDispatcher { class_hash: *class.class_hash }
}

fn expected_padding_error() -> Array<felt252> {
    let mut data = array![core::byte_array::BYTE_ARRAY_MAGIC];
    let message: ByteArray = "nonzero bag padding";
    message.serialize(ref data);
    // Starknet appends this marker when a library entrypoint panics.
    data.append('ENTRYPOINT_FAILED');
    data
}

#[test]
#[feature("safe_dispatcher")]
#[fuzzer(runs: 128, seed: 360030)]
fn oracle_arbitrary_felts_including_rejections(value: felt252) {
    let actual = unpack_probe().run(value);
    match oracle_unpack(value) {
        Option::Some(bag) => assert!(
            actual.unwrap() == bag, "accepted bag mismatch for value {value}",
        ),
        Option::None => assert_padding_error(actual.unwrap_err()),
    }
}

#[test]
#[feature("safe_dispatcher")]
fn oracle_every_padding_bit_and_field_prime_boundary() {
    let probe = unpack_probe();
    // Every representable non-payload bit, not just the endpoints of each gap.
    for bit in 0..252_u32 {
        let word = 2_u256.pow(bit);
        if (word & PAYLOAD_MASK) == 0 {
            let value: felt252 = word.try_into().unwrap();
            assert!(oracle_unpack(value).is_none(), "oracle accepted padding bit {bit}");
            assert!(
                probe.run(value).unwrap_err() == expected_padding_error(),
                "wrong error for padding bit {bit}",
            );
        }
    }
    assert!(oracle_unpack(-1).is_none(), "oracle accepted field-prime boundary");
    assert_padding_error(probe.run(-1).unwrap_err());
}

fn assert_padding_error(actual: Array<felt252>) {
    assert!(actual == expected_padding_error(), "actual error: {:?}", actual);
}

#[test]
#[feature("safe_dispatcher")]
fn oracle_selective_access_validates_only_its_own_lane() {
    let class = declare("ItemProbe").unwrap().contract_class();
    let probe = IItemProbeSafeLibraryDispatcher { class_hash: *class.class_hash };
    let slots = array![
        Slot::Weapon, Slot::Chest, Slot::Head, Slot::Waist, Slot::Foot, Slot::Hand, Slot::Neck,
        Slot::Ring,
    ];
    let empty = LootItem {
        id: 0, greatness: 0, suffix_id: 0, name_prefix_id: 0, name_suffix_id: 0,
    };
    for bit in 0..252_u32 {
        let word = 2_u256.pow(bit);
        if (word & PAYLOAD_MASK) == 0 {
            let value: felt252 = word.try_into().unwrap();
            for slot_index in 0..8_u32 {
                let actual = probe.run(value, *slots.at(slot_index));
                if slot_index / 2 == bit / 64 {
                    assert!(
                        actual.unwrap_err() == expected_padding_error(),
                        "wrong error for slot {slot_index}, padding bit {bit}",
                    );
                } else {
                    assert!(
                        actual.unwrap() == empty,
                        "slot {slot_index} changed by unrelated padding bit {bit}",
                    );
                }
            };
        }
    };
}
