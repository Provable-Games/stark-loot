//! Measured test-only accessor candidate. Does not alter the public codec.
use core::traits::DivRem;
use stark_loot::packed::PackedLootBag;
use stark_loot::types::Slot;

#[inline(always)]
pub fn scalar(packed: PackedLootBag, slot: Slot, greatness: bool) -> u8 {
    let packed: u256 = packed.value.into();
    let (limb, upper, second) = match slot {
        Slot::Weapon => (packed.low, false, false),
        Slot::Chest => (packed.low, false, true),
        Slot::Head => (packed.low, true, false),
        Slot::Waist => (packed.low, true, true),
        Slot::Foot => (packed.high, false, false),
        Slot::Hand => (packed.high, false, true),
        Slot::Neck => (packed.high, true, false),
        Slot::Ring => (packed.high, true, true),
    };
    let (high, low) = DivRem::div_rem(limb, 0x10000000000000000);
    let quarter: u64 = if upper {
        high
    } else {
        low
    }.try_into().unwrap();
    assert!(quarter < 0x400000000000000, "nonzero bag padding");
    let (high, low) = DivRem::div_rem(quarter, 0x20000000);
    let word = if second {
        high
    } else {
        low
    };
    if greatness {
        let (rest, _) = DivRem::div_rem(word, 0x80);
        let (_, field) = DivRem::div_rem(rest, 0x20);
        field.try_into().unwrap()
    } else {
        let (_, field) = DivRem::div_rem(word, 0x80);
        field.try_into().unwrap()
    }
}
