use core::panic_with_felt252;
use stark_loot::constants::{
    chest_ids, foot_ids, hand_ids, head_ids, item_tiers, item_types, neck_ids, ring_ids, waist_ids,
    weapon_ids,
};
use stark_loot::core::{get_slot, get_tier, get_type};
use stark_loot::types::{Slot, Tier, Type};

// ==================================================================================
// Type Lookup Tests
// ==================================================================================

#[test]
fn test_every_item_type_matches_canonical_list() {
    // Checked against constants::item_types, transcribed from the upstream death-mountain loot
    // package. Asserting a handful of boundary IDs against the ranges get_type itself defines
    // cannot catch a wrong grouping - that is how get_tier shipped wrong for 76 of 101 items.
    let types = item_types();
    assert!(types.len() == 101, "canonical type list must cover all 101 items");

    let mut id: u8 = 9;
    while id <= 101 {
        let expected = type_from_u8(*types.at((id - 1).into()));
        assert!(get_type(id) == expected, "wrong type for item {}", id);
        id += 1;
    }
}

#[test]
fn test_canonical_type_list_marks_exactly_the_neck_and_ring_ids() {
    // The loop above starts at 9 because get_type panics for necklaces and rings. That bound is
    // asserted against the canonical data rather than assumed, so a re-transcription of that
    // list cannot silently shrink what the loop covers.
    let types = item_types();

    let mut id: u8 = 1;
    while id <= 101 {
        let has_combat_type = *types.at((id - 1).into()) != 0;
        assert!(has_combat_type == (id > 8), "combat type presence wrong for item {}", id);
        id += 1;
    }
}

fn type_from_u8(value: u8) -> Type {
    match value {
        1 => Type::Magic_or_Cloth,
        2 => Type::Blade_or_Hide,
        3 => Type::Bludgeon_or_Metal,
        _ => panic_with_felt252('invalid type'),
    }
}

// ==================================================================================
// Tier Lookup Tests
// ==================================================================================

#[test]
fn test_every_item_tier_matches_canonical_list() {
    // Checked against constants::item_tiers, transcribed from the upstream death-mountain loot
    // package. Asserting range boundaries against ranges get_tier itself defines cannot catch a
    // wrong grouping, so the expected values have to come from outside this crate.
    let tiers = item_tiers();
    assert!(tiers.len() == 101, "canonical tier list must cover all 101 items");

    let mut id: u8 = 1;
    while id <= 101 {
        let expected = tier_from_u8(*tiers.at((id - 1).into()));
        assert!(get_tier(id) == expected, "wrong tier for item {}", id);
        id += 1;
    }
}

fn tier_from_u8(value: u8) -> Tier {
    match value {
        1 => Tier::T1,
        2 => Tier::T2,
        3 => Tier::T3,
        4 => Tier::T4,
        5 => Tier::T5,
        _ => panic_with_felt252('invalid tier'),
    }
}

// ==================================================================================
// Slot Lookup Tests
// ==================================================================================

#[test]
fn test_every_item_slot_matches_canonical_id_lists() {
    // Checked against the eight per-slot ID lists rather than a fresh transcription: those are
    // the Ethereum arrays, and they are already pinned by
    // direct_base_item_selectors_match_canonical_id_lists in core.cairo's test module and by the
    // name checks in tests/view_functions.cairo, so they are anchored to the parity fixtures.
    //
    // The lists hold 101 entries between them and every ID below is found in one of them, so no
    // ID can appear in two: the eight are an exact partition of 1-101.
    let total = weapon_ids().len()
        + chest_ids().len()
        + head_ids().len()
        + waist_ids().len()
        + foot_ids().len()
        + hand_ids().len()
        + neck_ids().len()
        + ring_ids().len();
    assert!(total == 101, "the canonical ID lists must hold 101 entries between them");

    let mut id: u8 = 1;
    while id <= 101 {
        assert!(get_slot(id) == slot_from_canonical_id_lists(id), "wrong slot for item {}", id);
        id += 1;
    }
}

fn slot_from_canonical_id_lists(id: u8) -> Slot {
    if id_list_contains(weapon_ids(), id) {
        Slot::Weapon
    } else if id_list_contains(chest_ids(), id) {
        Slot::Chest
    } else if id_list_contains(head_ids(), id) {
        Slot::Head
    } else if id_list_contains(waist_ids(), id) {
        Slot::Waist
    } else if id_list_contains(foot_ids(), id) {
        Slot::Foot
    } else if id_list_contains(hand_ids(), id) {
        Slot::Hand
    } else if id_list_contains(neck_ids(), id) {
        Slot::Neck
    } else if id_list_contains(ring_ids(), id) {
        Slot::Ring
    } else {
        panic_with_felt252('id in no canonical list')
    }
}

fn id_list_contains(list: Array<u8>, value: u8) -> bool {
    let mut i: usize = 0;
    let mut found = false;
    while i < list.len() {
        if *list.at(i) == value {
            found = true;
            break;
        }
        i += 1;
    }
    found
}

// ==================================================================================
// Panic Paths
// ==================================================================================

// get_type panics for necklaces and rings, which have no combat type. Each ID needs its own
// test: a loop would stop at the first panic and prove nothing about the IDs after it.

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_pendant() {
    get_type(1);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_necklace() {
    get_type(2);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_amulet() {
    get_type(3);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_silver_ring() {
    get_type(4);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_bronze_ring() {
    get_type(5);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_platinum_ring() {
    get_type(6);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_titanium_ring() {
    get_type(7);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_gold_ring() {
    get_type(8);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_on_zero() {
    get_type(0);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_type_panics_above_range() {
    get_type(102);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_tier_panics_on_zero() {
    get_tier(0);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_tier_panics_above_range() {
    get_tier(102);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_slot_panics_on_zero() {
    get_slot(0);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_slot_panics_above_range() {
    get_slot(102);
}
