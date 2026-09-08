use core::array::Array;
use core::byte_array::ByteArray;
use stark_loot::constants;
use stark_loot::contract::IStarkLootDispatcherTrait;
use stark_loot::core::{
    get_chest_item, get_foot_item, get_hand_item, get_head_item, get_item_name, get_loot_bag,
    get_neck_item, get_ring_item, get_waist_item, get_weapon_item, name_prefix_by_id,
    name_suffix_by_id, suffix_name_by_id,
};
use super::helpers::library;

fn assert_item_names_match(ids: Array<u8>, names: Array<ByteArray>) {
    assert(ids.len() == names.len(), 'item/id count mismatch');

    let mut index = 0;
    while index < ids.len() {
        assert(get_item_name(*ids.at(index)) == names.at(index).clone(), 'item name mismatch');
        index += 1;
    }
}

#[test]
fn test_greatness_getters() {
    // Bag 1 weapon has greatness 20
    let weapon = get_weapon_item(1);
    assert(weapon.greatness == 20_u8, 'weapon greatness mismatch');
}

#[test]
fn test_weapon_count() {
    let weapons = constants::weapons();
    assert(weapons.len() == 18, 'weapon count mismatch');
}

#[test]
fn test_chest_armor_count() {
    let chest_armors = constants::chest_armors();
    assert(chest_armors.len() == 15, 'chest armor count mismatch');
}

#[test]
fn test_head_armor_count() {
    let head_armors = constants::head_armors();
    assert(head_armors.len() == 15, 'head armor count mismatch');
}

#[test]
fn test_suffix_count() {
    let suffixes = constants::suffixes();
    assert(suffixes.len() == 16, 'suffix count mismatch');
}

#[test]
fn test_name_prefix_count() {
    let name_prefixes = constants::name_prefixes();
    assert(name_prefixes.len() == 69, 'name prefix count mismatch');
}

#[test]
fn test_name_suffix_count() {
    let name_suffixes = constants::name_suffixes();
    assert(name_suffixes.len() == 18, 'name suffix count mismatch');
}

#[test]
fn test_weapon_ids_match_weapons() {
    let weapons = constants::weapons();
    let weapon_ids = constants::weapon_ids();
    assert(weapons.len() == weapon_ids.len(), 'weapon/id count mismatch');
}

#[test]
fn test_all_weapons_accessible() {
    let weapons = constants::weapons();
    assert(weapons.at(0).clone() == "Warhammer", 'first weapon mismatch');
    assert(weapons.at(17).clone() == "Book", 'last weapon mismatch');
}

#[test]
fn test_all_suffixes_accessible() {
    let suffixes = constants::suffixes();
    assert(suffixes.at(0).clone() == "of Power", 'first suffix mismatch');
    assert(suffixes.at(15).clone() == "of the Twins", 'last suffix mismatch');
}

#[test]
fn test_all_affix_lookups_match_canonical_lists() {
    let suffixes = constants::suffixes();
    let suffix_ids = constants::suffix_ids();
    let mut index = 0;
    while index < suffix_ids.len() {
        assert(
            suffix_name_by_id(*suffix_ids.at(index)) == suffixes.at(index).clone(),
            'suffix lookup mismatch',
        );
        index += 1;
    }

    let name_prefixes = constants::name_prefixes();
    let name_prefix_ids = constants::name_prefix_ids();
    index = 0;
    while index < name_prefix_ids.len() {
        assert(
            name_prefix_by_id(*name_prefix_ids.at(index)) == name_prefixes.at(index).clone(),
            'name prefix mismatch',
        );
        index += 1;
    }

    let name_suffixes = constants::name_suffixes();
    let name_suffix_ids = constants::name_suffix_ids();
    index = 0;
    while index < name_suffix_ids.len() {
        assert(
            name_suffix_by_id(*name_suffix_ids.at(index)) == name_suffixes.at(index).clone(),
            'name suffix mismatch',
        );
        index += 1;
    }
}

#[test]
fn test_necklace_count() {
    let necklaces = constants::necklaces();
    assert(necklaces.len() == 3, 'necklace count mismatch');
}

#[test]
fn test_ring_count() {
    let rings = constants::rings();
    assert(rings.len() == 5, 'ring count mismatch');
}

#[test]
fn test_bag_1_all_greatness_values() {
    let bag = get_loot_bag(1);
    assert(bag.weapon.greatness == 20_u8, 'weapon greatness');
    assert(bag.chest.greatness == 8_u8, 'chest greatness');
    assert(bag.head.greatness == 5_u8, 'head greatness');
    assert(bag.waist.greatness == 11_u8, 'waist greatness');
    assert(bag.foot.greatness == 19_u8, 'foot greatness');
    assert(bag.hand.greatness == 7_u8, 'hand greatness');
    assert(bag.neck.greatness == 15_u8, 'neck greatness');
    assert(bag.ring.greatness == 7_u8, 'ring greatness');
}

#[test]
fn test_get_item_name_works_for_all_slots() {
    // Test one item from each slot across all three types
    assert(get_item_name(1) == "Pendant", 'neck item');
    assert(get_item_name(8) == "Gold Ring", 'ring item');
    assert(get_item_name(10) == "Grave Wand", 'magic weapon');
    assert(get_item_name(17) == "Divine Robe", 'cloth chest');
    assert(get_item_name(23) == "Divine Hood", 'cloth head');
    assert(get_item_name(27) == "Brightsilk Sash", 'cloth waist');
    assert(get_item_name(32) == "Divine Slippers", 'cloth foot');
    assert(get_item_name(37) == "Divine Gloves", 'cloth hand');
    assert(get_item_name(42) == "Katana", 'blade weapon');
    assert(get_item_name(47) == "Demon Husk", 'hide chest');
    assert(get_item_name(72) == "Warhammer", 'bludgeon weapon');
    assert(get_item_name(77) == "Holy Chestplate", 'metal chest');
}

#[test]
fn test_all_item_name_lookups_match_canonical_lists() {
    assert_item_names_match(constants::weapon_ids(), constants::weapons());
    assert_item_names_match(constants::chest_ids(), constants::chest_armors());
    assert_item_names_match(constants::head_ids(), constants::head_armors());
    assert_item_names_match(constants::waist_ids(), constants::waist_armors());
    assert_item_names_match(constants::foot_ids(), constants::foot_armors());
    assert_item_names_match(constants::hand_ids(), constants::hand_armors());
    assert_item_names_match(constants::neck_ids(), constants::necklaces());
    assert_item_names_match(constants::ring_ids(), constants::rings());
}

#[test]
fn test_public_generation_reaches_every_canonical_base_item() {
    // Each independently calculated witness reaches one selector arm through its public API.
    for (bag_id, expected_id) in array![
        (11_u64, 72_u8), (25_u64, 73_u8), (5_u64, 74_u8), (51_u64, 75_u8), (64_u64, 76_u8),
        (3_u64, 42_u8), (47_u64, 43_u8), (4_u64, 44_u8), (6_u64, 45_u8), (9_u64, 46_u8),
        (8_u64, 9_u8), (1_u64, 10_u8), (2_u64, 11_u8), (87_u64, 12_u8), (31_u64, 13_u8),
        (0_u64, 14_u8), (24_u64, 15_u8), (22_u64, 16_u8),
    ] {
        assert(get_weapon_item(bag_id).id == expected_id, 'weapon selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (26_u64, 17_u8), (0_u64, 18_u8), (15_u64, 19_u8), (10_u64, 20_u8), (8_u64, 21_u8),
        (13_u64, 47_u8), (6_u64, 48_u8), (9_u64, 49_u8), (1_u64, 50_u8), (18_u64, 51_u8),
        (33_u64, 77_u8), (3_u64, 78_u8), (4_u64, 79_u8), (12_u64, 80_u8), (16_u64, 81_u8),
    ] {
        assert(get_chest_item(bag_id).id == expected_id, 'chest selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (0_u64, 82_u8), (19_u64, 83_u8), (3_u64, 84_u8), (8_u64, 85_u8), (13_u64, 86_u8),
        (11_u64, 52_u8), (5_u64, 53_u8), (46_u64, 54_u8), (12_u64, 55_u8), (7_u64, 56_u8),
        (41_u64, 22_u8), (1_u64, 23_u8), (4_u64, 24_u8), (9_u64, 25_u8), (6_u64, 26_u8),
    ] {
        assert(get_head_item(bag_id).id == expected_id, 'head selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (3_u64, 87_u8), (8_u64, 88_u8), (2_u64, 89_u8), (9_u64, 90_u8), (4_u64, 91_u8),
        (58_u64, 57_u8), (29_u64, 58_u8), (10_u64, 59_u8), (1_u64, 60_u8), (0_u64, 61_u8),
        (19_u64, 27_u8), (11_u64, 28_u8), (31_u64, 29_u8), (7_u64, 30_u8), (5_u64, 31_u8),
    ] {
        assert(get_waist_item(bag_id).id == expected_id, 'waist selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (0_u64, 92_u8), (1_u64, 93_u8), (7_u64, 94_u8), (16_u64, 95_u8), (14_u64, 96_u8),
        (2_u64, 62_u8), (6_u64, 63_u8), (11_u64, 64_u8), (8_u64, 65_u8), (26_u64, 66_u8),
        (25_u64, 32_u8), (22_u64, 33_u8), (9_u64, 34_u8), (27_u64, 35_u8), (56_u64, 36_u8),
    ] {
        assert(get_foot_item(bag_id).id == expected_id, 'foot selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (42_u64, 97_u8), (11_u64, 98_u8), (7_u64, 99_u8), (63_u64, 100_u8), (6_u64, 101_u8),
        (15_u64, 67_u8), (3_u64, 68_u8), (1_u64, 69_u8), (5_u64, 70_u8), (0_u64, 71_u8),
        (19_u64, 37_u8), (9_u64, 38_u8), (8_u64, 39_u8), (21_u64, 40_u8), (2_u64, 41_u8),
    ] {
        assert(get_hand_item(bag_id).id == expected_id, 'hand selector mismatch');
    }

    for (bag_id, expected_id) in array![(1_u64, 2_u8), (0_u64, 3_u8), (5_u64, 1_u8)] {
        assert(get_neck_item(bag_id).id == expected_id, 'neck selector mismatch');
    }

    for (bag_id, expected_id) in array![
        (1_u64, 8_u8), (0_u64, 4_u8), (11_u64, 5_u8), (7_u64, 6_u8), (2_u64, 7_u8),
    ] {
        assert(get_ring_item(bag_id).id == expected_id, 'ring selector mismatch');
    }
}

#[test]
fn test_get_item_name_boundary_cases() {
    // Test boundaries of ID ranges
    assert(get_item_name(1) == "Pendant", 'min necklace');
    assert(get_item_name(3) == "Amulet", 'max necklace');
    assert(get_item_name(9) == "Ghost Wand", 'min magic weapon');
    assert(get_item_name(41) == "Gloves", 'max cloth hand');
    assert(get_item_name(42) == "Katana", 'min blade');
    assert(get_item_name(71) == "Leather Gloves", 'max hide hand');
    assert(get_item_name(72) == "Warhammer", 'min bludgeon');
    assert(get_item_name(101) == "Heavy Gloves", 'max metal hand');
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_get_item_name_panics_on_zero() {
    get_item_name(0);
}

#[test]
#[should_panic(expected: 'invalid item id')]
fn test_get_item_name_panics_on_too_high() {
    get_item_name(102);
}

#[test]
#[should_panic(expected: 'invalid suffix id')]
fn test_suffix_name_panics_on_zero() {
    suffix_name_by_id(0);
}

#[test]
#[should_panic(expected: 'invalid suffix id')]
fn test_suffix_name_panics_above_range() {
    suffix_name_by_id(17);
}

#[test]
#[should_panic(expected: 'invalid name prefix id')]
fn test_name_prefix_panics_on_zero() {
    name_prefix_by_id(0);
}

#[test]
#[should_panic(expected: 'invalid name prefix id')]
fn test_name_prefix_panics_above_range() {
    name_prefix_by_id(70);
}

#[test]
#[should_panic(expected: 'invalid name suffix id')]
fn test_name_suffix_panics_on_zero() {
    name_suffix_by_id(0);
}

#[test]
#[should_panic(expected: 'invalid name suffix id')]
fn test_name_suffix_panics_above_range() {
    name_suffix_by_id(19);
}

#[test]
fn library_scalar_getters_match_full_bags() {
    let loot = library();
    for bag_id in array![0_u64, 1, 9, 10, 9999, 10000, 0xffffffffffffffff] {
        let bag = get_loot_bag(bag_id);
        assert!(loot.get_weapon_id(bag_id) == bag.weapon.id, "weapon id mismatch");
        assert!(
            loot.get_weapon_greatness(bag_id) == bag.weapon.greatness, "weapon greatness mismatch",
        );
        assert!(loot.get_chest_id(bag_id) == bag.chest.id, "chest id mismatch");
        assert!(
            loot.get_chest_greatness(bag_id) == bag.chest.greatness, "chest greatness mismatch",
        );
        assert!(loot.get_head_id(bag_id) == bag.head.id, "head id mismatch");
        assert!(loot.get_head_greatness(bag_id) == bag.head.greatness, "head greatness mismatch");
        assert!(loot.get_waist_id(bag_id) == bag.waist.id, "waist id mismatch");
        assert!(
            loot.get_waist_greatness(bag_id) == bag.waist.greatness, "waist greatness mismatch",
        );
        assert!(loot.get_foot_id(bag_id) == bag.foot.id, "foot id mismatch");
        assert!(loot.get_foot_greatness(bag_id) == bag.foot.greatness, "foot greatness mismatch");
        assert!(loot.get_hand_id(bag_id) == bag.hand.id, "hand id mismatch");
        assert!(loot.get_hand_greatness(bag_id) == bag.hand.greatness, "hand greatness mismatch");
        assert!(loot.get_neck_id(bag_id) == bag.neck.id, "neck id mismatch");
        assert!(loot.get_neck_greatness(bag_id) == bag.neck.greatness, "neck greatness mismatch");
        assert!(loot.get_ring_id(bag_id) == bag.ring.id, "ring id mismatch");
        assert!(loot.get_ring_greatness(bag_id) == bag.ring.greatness, "ring greatness mismatch");
    }
}
