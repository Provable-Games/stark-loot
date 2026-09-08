use core::array::SpanTrait;
use core::traits::TryInto;
use snforge_std::fs::{FileTrait, read_json};
use stark_loot::core::{
    LootBagNames, get_foot_item, get_head_item, get_item_name, get_loot_bag, get_loot_bag_names,
    get_neck_item, get_packed_loot_bag, get_ring_item, get_waist_item, get_weapon_item,
    name_prefix_by_id, name_suffix_by_id, suffix_name_by_id,
};
use stark_loot::packed::{LootBagPackingTrait, PackedLootBagTrait};
use crate::loot_reference::loot_reference;

fn assert_bag(id: u64, expected: LootBagNames) {
    let bag = get_loot_bag_names(id);
    assert(bag == expected, 'bag mismatch');
}

#[test]
fn bag_1_matches() {
    assert_bag(
        1,
        LootBagNames {
            chest: "Hard Leather Armor",
            foot: "\"Death Root\" Ornate Greaves of Skill",
            hand: "Studded Leather Gloves",
            head: "Divine Hood",
            neck: "Necklace of Enlightenment",
            ring: "Gold Ring",
            waist: "Hard Leather Belt",
            weapon: "\"Grim Shout\" Grave Wand of Skill +1",
        },
    );
}

#[test]
fn bag_2_matches() {
    assert_bag(
        2,
        LootBagNames {
            chest: "\"Ghoul Sun\" Silk Robe of Fury",
            foot: "\"Pandemonium Shout\" Demonhide Boots of Brilliance +1",
            hand: "Gloves",
            head: "Ancient Helm",
            neck: "Amulet",
            ring: "Titanium Ring",
            waist: "Plated Belt",
            weapon: "Bone Wand",
        },
    );
}

#[test]
fn bag_3_matches() {
    assert_bag(
        3,
        LootBagNames {
            chest: "Ornate Chestplate",
            foot: "Ornate Greaves of Anger",
            hand: "Dragonskin Gloves",
            head: "Great Helm",
            neck: "Necklace",
            ring: "Gold Ring of Titans",
            waist: "Ornate Belt of Detection",
            weapon: "Katana",
        },
    );
}

#[test]
fn bag_4_matches() {
    assert_bag(
        4,
        LootBagNames {
            chest: "Plate Mail",
            foot: "Ornate Greaves",
            hand: "Leather Gloves of Perfection",
            head: "Silk Hood",
            neck: "Amulet",
            ring: "Gold Ring",
            waist: "Heavy Belt",
            weapon: "Scimitar",
        },
    );
}

#[test]
fn bag_5_matches() {
    assert_bag(
        5,
        LootBagNames {
            chest: "Plate Mail",
            foot: "Holy Greaves",
            hand: "Hard Leather Gloves",
            head: "Dragon's Crown of Perfection",
            neck: "Pendant",
            ring: "Titanium Ring",
            waist: "Sash",
            weapon: "Maul of Reflection",
        },
    );
}

#[test]
fn bag_6_matches() {
    assert_bag(
        6,
        LootBagNames {
            chest: "Dragonskin Armor",
            foot: "Dragonskin Boots",
            hand: "Heavy Gloves of Titans",
            head: "Hood",
            neck: "Necklace of Detection",
            ring: "Silver Ring",
            waist: "Leather Belt",
            weapon: "Long Sword",
        },
    );
}

#[test]
fn bag_7_matches() {
    assert_bag(
        7,
        LootBagNames {
            chest: "Ornate Chestplate",
            foot: "\"Tempest Peak\" Greaves of Enlightenment +1",
            hand: "Gauntlets",
            head: "Cap",
            neck: "Necklace",
            ring: "Platinum Ring",
            waist: "Linen Sash",
            weapon: "Katana",
        },
    );
}

#[test]
fn bag_8_matches() {
    assert_bag(
        8,
        LootBagNames {
            chest: "Shirt",
            foot: "\"Skull Bite\" Hard Leather Boots of Reflection +1",
            hand: "Wool Gloves of Skill",
            head: "Full Helm of Anger",
            neck: "Amulet",
            ring: "Titanium Ring",
            waist: "War Belt of Perfection",
            weapon: "Ghost Wand",
        },
    );
}

#[test]
fn bag_9_matches() {
    assert_bag(
        9,
        LootBagNames {
            chest: "\"Soul Glow\" Studded Leather Armor of Rage",
            foot: "Wool Shoes of the Twins",
            hand: "Silk Gloves",
            head: "Linen Hood of Fury",
            neck: "Necklace",
            ring: "Gold Ring of Anger",
            waist: "Mesh Belt",
            weapon: "Short Sword",
        },
    );
}

#[test]
fn bag_10_matches() {
    assert_bag(
        10,
        LootBagNames {
            chest: "Robe",
            foot: "Holy Greaves",
            hand: "Wool Gloves",
            head: "Divine Hood",
            neck: "\"Havoc Sun\" Amulet of Reflection",
            ring: "Platinum Ring",
            waist: "Studded Leather Belt",
            weapon: "Maul",
        },
    );
}

#[test]
fn plus_one_items_have_max_greatness() {
    let weapon = get_weapon_item(1);
    assert(weapon.greatness == 20_u8, 'expect greatness 20');
}

#[test]
fn named_items_without_plus_one_have_greatness_19() {
    let foot = get_foot_item(1);
    assert(foot.greatness == 19_u8, 'expect greatness 19');
}

#[test]
fn suffixed_items_without_names_are_between_15_and_18() {
    let waist = get_waist_item(3);
    assert(waist.greatness >= 15_u8 && waist.greatness <= 18_u8, 'suffix range check');
}

#[test]
fn plain_items_have_base_greatness() {
    let head = get_head_item(3);
    assert(head.greatness <= 14_u8, 'base greatness range');
}

#[test]
fn first_500_loot_items_match_cairo_fixture() {
    let mut reference_bags = loot_reference();
    let mut index = 0;
    loop {
        match reference_bags.pop_front() {
            Option::Some(expected) => {
                let bag_id: u64 = (index + 1).try_into().unwrap();
                let actual = get_loot_bag(bag_id);
                assert(*expected == actual, 'loot bag mismatch');
                index += 1;
            },
            Option::None(_) => { break; },
        };
    }
}

#[test]
fn bag_1_weapon_metadata_matches_verbose_fixture() {
    let item = get_weapon_item(1);
    assert(item.greatness == 20_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Grave Wand", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Skill", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Grim", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Shout", 'meta mismatch');
}

#[test]
fn bag_1_foot_metadata_matches_verbose_fixture() {
    let item = get_foot_item(1);
    assert(item.greatness == 19_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Ornate Greaves", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Skill", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Death", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Root", 'meta mismatch');
}

#[test]
fn bag_1_waist_metadata_matches_verbose_fixture() {
    let item = get_waist_item(1);
    assert(item.greatness == 11_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Hard Leather Belt", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Titans", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Woe", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Bite", 'meta mismatch');
}

#[test]
fn bag_1_ring_metadata_matches_verbose_fixture() {
    let item = get_ring_item(1);
    assert(item.greatness == 7_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Gold Ring", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Perfection", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Carrion", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Whisper", 'meta mismatch');
}

#[test]
fn bag_2_weapon_metadata_matches_verbose_fixture() {
    let item = get_weapon_item(2);
    assert(item.greatness == 12_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Bone Wand", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Anger", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Agony", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Growl", 'meta mismatch');
}

#[test]
fn bag_3_waist_metadata_matches_verbose_fixture() {
    let item = get_waist_item(3);
    assert(item.greatness == 18_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Ornate Belt", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Detection", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Doom", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Shadow", 'meta mismatch');
}

#[test]
fn bag_5_weapon_metadata_matches_verbose_fixture() {
    let item = get_weapon_item(5);
    assert(item.greatness == 17_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Maul", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Reflection", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Grim", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Bite", 'meta mismatch');
}

#[test]
fn bag_7_ring_metadata_matches_verbose_fixture() {
    let item = get_ring_item(7);
    assert(item.greatness == 0_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Platinum Ring", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Giants", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Doom", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Song", 'meta mismatch');
}

#[test]
fn bag_8_weapon_metadata_matches_verbose_fixture() {
    let item = get_weapon_item(8);
    assert(item.greatness == 4_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Ghost Wand", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Anger", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Storm", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Whisper", 'meta mismatch');
}

#[test]
fn bag_9_ring_metadata_matches_verbose_fixture() {
    let item = get_ring_item(9);
    assert(item.greatness == 18_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Gold Ring", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Anger", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Miracle", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Instrument", 'meta mismatch');
}

#[test]
fn bag_10_neck_metadata_matches_verbose_fixture() {
    let item = get_neck_item(10);
    assert(item.greatness == 19_u8, 'meta mismatch');
    assert(get_item_name(item.id) == "Amulet", 'meta mismatch');
    assert(suffix_name_by_id(item.suffix_id) == "of Reflection", 'meta mismatch');
    assert(name_prefix_by_id(item.name_prefix_id) == "Havoc", 'meta mismatch');
    assert(name_suffix_by_id(item.name_suffix_id) == "Sun", 'meta mismatch');
}

fn assert_verbose_item(ref data: Span<felt252>, item: stark_loot::core::LootItem, name: ByteArray) {
    // Alphabetically, greatness precedes item_name.
    let current_name: ByteArray = Serde::deserialize(ref data).unwrap();
    // final_name is a hypothetical greatness-20 preview, not the name this bag returns.
    // Validate it below using the same already-checked components, without rehashing.
    let final_name: ByteArray = Serde::deserialize(ref data).unwrap();
    let greatness: u8 = Serde::deserialize(ref data).unwrap();
    let item_name: ByteArray = Serde::deserialize(ref data).unwrap();
    let name_prefix: ByteArray = Serde::deserialize(ref data).unwrap();
    let name_suffix: ByteArray = Serde::deserialize(ref data).unwrap();
    let suffix: ByteArray = Serde::deserialize(ref data).unwrap();
    assert!(name == current_name, "rendered name mismatch");
    assert!(item.greatness == greatness, "greatness mismatch");
    assert!(get_item_name(item.id) == item_name, "base name mismatch");
    assert!(name_prefix_by_id(item.name_prefix_id) == name_prefix, "prefix mismatch");
    assert!(name_suffix_by_id(item.name_suffix_id) == name_suffix, "name suffix mismatch");
    assert!(suffix_name_by_id(item.suffix_id) == suffix, "suffix mismatch");

    let mut expected_final: ByteArray = "\"";
    expected_final.append(@name_prefix);
    expected_final.append_byte(' ');
    expected_final.append(@name_suffix);
    expected_final.append_word('" ', 2);
    expected_final.append(@item_name);
    expected_final.append_byte(' ');
    expected_final.append(@suffix);
    expected_final.append_word(' +1', 3);
    assert!(final_name == expected_final, "final name mismatch");
}

#[test]
#[should_panic(expected: ("final name mismatch",))]
fn verbose_fixture_rejects_corrupt_preview() {
    // Bag 1 chest has hidden modifiers. Keep its actual name and all metadata correct,
    // but omit the preview's +1 so this must fail specifically at preview validation.
    let mut encoded = array![];
    let current_name: ByteArray = "Hard Leather Armor";
    current_name.serialize(ref encoded);
    let corrupt_preview: ByteArray = "\"Mind Shout\" Hard Leather Armor of Protection";
    corrupt_preview.serialize(ref encoded);
    8_u8.serialize(ref encoded);
    current_name.serialize(ref encoded);
    let prefix: ByteArray = "Mind";
    prefix.serialize(ref encoded);
    let name_suffix: ByteArray = "Shout";
    name_suffix.serialize(ref encoded);
    let suffix: ByteArray = "of Protection";
    suffix.serialize(ref encoded);
    let mut data = encoded.span();
    let item = stark_loot::core::LootItem {
        id: 50, greatness: 8, suffix_id: 8, name_prefix_id: 42, name_suffix_id: 12,
    };
    assert_verbose_item(ref data, item, current_name);
}

#[test]
fn all_loot_items_match_verbose_fixture() {
    let mut data = verbose_fixture_data("tests/verbose_loot.json");
    let next_bag_id = assert_verbose_bags(ref data, 1, 8_000);
    assert!(next_bag_id == 1, "fixture traversal did not wrap");
    assert!(data.is_empty(), "unread fixture data");
}

fn verbose_fixture_data(path: ByteArray) -> Span<felt252> {
    let file = FileTrait::new(path);
    read_json(@file).span()
}

fn assert_verbose_bags(ref data: Span<felt252>, mut bag_id: u64, n_bags: u32) -> u64 {
    let mut count = 0_u32;
    while count < n_bags {
        // Exercise expanded, packed, and names APIs for every fixture bag: 24 Keccaks.
        let bag = get_loot_bag(bag_id);
        let packed = get_packed_loot_bag(bag_id);
        assert!(packed.unpack() == bag, "packed bag mismatch");
        assert!(bag.pack() == packed, "packed generation mismatch");
        let names = get_loot_bag_names(bag_id);
        assert_verbose_item(ref data, bag.chest, names.chest);
        assert_verbose_item(ref data, bag.foot, names.foot);
        assert_verbose_item(ref data, bag.hand, names.hand);
        assert_verbose_item(ref data, bag.head, names.head);
        assert_verbose_item(ref data, bag.neck, names.neck);
        assert_verbose_item(ref data, bag.ring, names.ring);
        assert_verbose_item(ref data, bag.waist, names.waist);
        assert_verbose_item(ref data, bag.weapon, names.weapon);
        count += 1;
        bag_id = next_fixture_bag_id(bag_id);
    }
    bag_id
}

fn next_fixture_bag_id(mut bag_id: u64) -> u64 {
    // Visit 1, 10, 100, 1000, ..., 1001, ... in the JSON reader's key order.
    if bag_id * 10 <= 8_000 {
        bag_id * 10
    } else {
        while bag_id % 10 == 9 || bag_id >= 8_000 {
            bag_id /= 10;
        }
        bag_id + 1
    }
}

#[test]
fn verbose_fixture_sample_matches() {
    // Exercise the same validator in CI without tracing all 8,000 bags. The first 13
    // lexicographic entries include bag 1 and the complete 1000..1009 digit boundary.
    let mut data = verbose_fixture_data("tests/verbose_loot_sample.json");
    // Consume every entry produced by the checker. The terminal ID below pins the
    // expected traversal and must be updated together with SAMPLE_BAG_COUNT.
    let mut bag_id = 1;
    while !data.is_empty() {
        bag_id = assert_verbose_bags(ref data, bag_id, 1);
    }
    assert!(bag_id == 101, "sample traversal mismatch");
    // Cover the fixture's upper limit and multi-digit carry without hashing extra bags.
    assert!(next_fixture_bag_id(7999) == 8, "7999 traversal mismatch");
    assert!(next_fixture_bag_id(800) == 8000, "800 traversal mismatch");
    assert!(next_fixture_bag_id(8000) == 801, "8000 traversal mismatch");
    assert!(next_fixture_bag_id(999) == 1, "traversal wrap mismatch");
}

#[test]
fn verbose_fixture_reader_uses_lexicographic_keys() {
    // Numeric-looking bag IDs, slots, and fields must all sort lexicographically.
    // Synthetic marker values isolate the reader contract from Loot generation.
    let data = verbose_fixture_data("tests/fixtures/reader_key_order.json");
    assert!(
        data == array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].span(),
        "read_json key ordering changed",
    );
}
