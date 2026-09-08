//! One-felt Loot bag codec. Two 29-bit items occupy the low 58 bits of each u64 quarter.
//! Slots start at bits 0, 29, 64, 93, 128, 157, 192, and 221; the payload ends at bit 249.
//! No field or item crosses a u64/u128 boundary. The six unused bits in each quarter are zero.
use core::traits::DivRem;
use crate::core::{LootBag, LootItem};
use crate::types::Slot;

const TWO_POW_7: NonZero<u64> = 0x80;
const TWO_POW_5: NonZero<u64> = 0x20;
const TWO_POW_29: NonZero<u64> = 0x20000000;
const TWO_POW_64: NonZero<u128> = 0x10000000000000000;
const ITEM_SHIFT: felt252 = 0x20000000;
const QUARTER_SHIFT: felt252 = 0x10000000000000000;
const LIMB_SHIFT: felt252 = 0x100000000000000000000000000000000;
// 2^58 = ITEM_SHIFT * ITEM_SHIFT: two 29-bit item words per quarter.
const QUARTER_PAYLOAD_BOUND: u64 = 0x400000000000000;

/// A bag's complete numeric metadata, serialized and stored as exactly one felt.
/// Use `unpack()` for the familiar LootBag fields, or `get_item(slot)` to decode one slot.
#[derive(Clone, Copy, Debug, Drop, PartialEq, Serde, starknet::Store)]
pub struct PackedLootBag {
    pub value: felt252,
}

#[generate_trait]
pub impl LootBagPackingImpl of LootBagPackingTrait {
    /// Pack all five fields, including modifiers that are not yet visible in the item name.
    /// Reject values that exceed the layout's field widths; do not silently truncate.
    fn pack(self: LootBag) -> PackedLootBag {
        from_item_words(
            pack_item(self.weapon),
            pack_item(self.chest),
            pack_item(self.head),
            pack_item(self.waist),
            pack_item(self.foot),
            pack_item(self.hand),
            pack_item(self.neck),
            pack_item(self.ring),
        )
    }
}

#[generate_trait]
pub impl PackedLootBagImpl of PackedLootBagTrait {
    fn unpack(self: PackedLootBag) -> LootBag {
        let packed: u256 = self.value.into();
        let (q1, q0) = DivRem::div_rem(packed.low, TWO_POW_64);
        let (q3, q2) = DivRem::div_rem(packed.high, TWO_POW_64);
        let (weapon, chest) = unpack_pair(q0.try_into().unwrap());
        let (head, waist) = unpack_pair(q1.try_into().unwrap());
        let (foot, hand) = unpack_pair(q2.try_into().unwrap());
        let (neck, ring) = unpack_pair(q3.try_into().unwrap());
        LootBag { weapon, chest, head, waist, foot, hand, neck, ring }
    }

    /// Decode just the requested slot. Only the selected quarter's padding is checked.
    fn get_item(self: PackedLootBag, slot: Slot) -> LootItem {
        let packed: u256 = self.value.into();
        let (quarter, second) = match slot {
            Slot::Weapon => (lower_quarter(packed.low), false),
            Slot::Chest => (lower_quarter(packed.low), true),
            Slot::Head => (upper_quarter(packed.low), false),
            Slot::Waist => (upper_quarter(packed.low), true),
            Slot::Foot => (lower_quarter(packed.high), false),
            Slot::Hand => (lower_quarter(packed.high), true),
            Slot::Neck => (upper_quarter(packed.high), false),
            Slot::Ring => (upper_quarter(packed.high), true),
        };
        assert!(quarter < QUARTER_PAYLOAD_BOUND, "nonzero bag padding");
        let (high, low) = DivRem::div_rem(quarter, TWO_POW_29);
        unpack_item(if second {
            high
        } else {
            low
        })
    }
}

#[inline(always)]
fn lower_quarter(limb: u128) -> u64 {
    let (_, low) = DivRem::div_rem(limb, TWO_POW_64);
    low.try_into().unwrap()
}

#[inline(always)]
fn upper_quarter(limb: u128) -> u64 {
    let (high, _) = DivRem::div_rem(limb, TWO_POW_64);
    high.try_into().unwrap()
}

#[inline(always)]
pub(crate) fn pack_item(item: LootItem) -> felt252 {
    assert!(item.id < 128, "item id packing overflow");
    assert!(item.greatness < 32, "greatness packing overflow");
    assert!(item.suffix_id < 32, "suffix packing overflow");
    assert!(item.name_prefix_id < 128, "prefix packing overflow");
    assert!(item.name_suffix_id < 32, "name suffix packing overflow");
    item_word(
        item.id.into(),
        item.greatness.into(),
        item.suffix_id.into(),
        item.name_prefix_id.into(),
        item.name_suffix_id.into(),
    )
}

/// Internal callers must bound fields to 7/5/5/7/5 bits before entering this helper.
/// All summands are disjoint and the sum is below 2^29, so felt arithmetic is exact.
#[inline(always)]
fn item_word(
    id: felt252, greatness: felt252, suffix: felt252, name_prefix: felt252, name_suffix: felt252,
) -> felt252 {
    id + greatness * 0x80 + suffix * 0x1000 + name_prefix * 0x20000 + name_suffix * 0x1000000
}

/// Internal callers must supply eight item words below 2^29. The final sum is below 2^250.
#[inline(always)]
pub(crate) fn from_item_words(
    weapon: felt252,
    chest: felt252,
    head: felt252,
    waist: felt252,
    foot: felt252,
    hand: felt252,
    neck: felt252,
    ring: felt252,
) -> PackedLootBag {
    let low = weapon + chest * ITEM_SHIFT + (head + waist * ITEM_SHIFT) * QUARTER_SHIFT;
    let high = foot + hand * ITEM_SHIFT + (neck + ring * ITEM_SHIFT) * QUARTER_SHIFT;
    PackedLootBag { value: low + high * LIMB_SHIFT }
}

#[inline(always)]
fn unpack_pair(quarter: u64) -> (LootItem, LootItem) {
    assert!(quarter < QUARTER_PAYLOAD_BOUND, "nonzero bag padding");
    let (high, low) = DivRem::div_rem(quarter, TWO_POW_29);
    (unpack_item(low), unpack_item(high))
}

#[inline(always)]
fn unpack_item(word: u64) -> LootItem {
    let (rest, id) = DivRem::div_rem(word, TWO_POW_7);
    let (rest, greatness) = DivRem::div_rem(rest, TWO_POW_5);
    let (rest, suffix_id) = DivRem::div_rem(rest, TWO_POW_5);
    let (name_suffix_id, name_prefix_id) = DivRem::div_rem(rest, TWO_POW_7);
    LootItem {
        id: id.try_into().unwrap(),
        greatness: greatness.try_into().unwrap(),
        suffix_id: suffix_id.try_into().unwrap(),
        name_prefix_id: name_prefix_id.try_into().unwrap(),
        name_suffix_id: name_suffix_id.try_into().unwrap(),
    }
}
