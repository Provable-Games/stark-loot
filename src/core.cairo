use core::byte_array::{ByteArray, ByteArrayTrait};
use core::integer::{u128_byte_reverse, u256};
use core::panic_with_felt252;
use core::traits::{DivRem, TryInto};
use core::zeroable::NonZero;
use starknet::SyscallResultTrait;
use crate::packed::{PackedLootBag, from_item_words};
use crate::types::{Slot, Tier, Type};

const GREATNESS_MOD: usize = 21;
// LOOT_MODULUS must remain divisible by these and every slot-list length.
const SUFFIX_MOD: usize = 16;
const NAME_PREFIX_MOD: usize = 69;
const NAME_SUFFIX_MOD: usize = 18;
// Least common multiple of every index modulus used to derive a Loot item:
// 16, 69, 18, 21, and the base-list lengths 18, 15, 5, and 3.
const LOOT_MODULUS: NonZero<u256> = 115_920;

// Construct through packed_decimal_seed(bag_id): decimal ASCII plus the 0x01 padding byte.
// This type prevents accidental raw-felt arguments; it does not validate hand-built values.
#[derive(Copy, Drop)]
struct PackedSeed {
    digits: felt252,
}

#[derive(Copy, Drop)]
struct SeedPrefix {
    word: u64,
    next_shift: u64,
}

// Prefix bytes packed in the little-endian u64 format expected by the Keccak syscall.
const WEAPON_PREFIX: SeedPrefix = SeedPrefix { word: 0x4e4f50414557, next_shift: 0x1000000000000 };
const CHEST_PREFIX: SeedPrefix = SeedPrefix { word: 0x5453454843, next_shift: 0x10000000000 };
const HEAD_PREFIX: SeedPrefix = SeedPrefix { word: 0x44414548, next_shift: 0x100000000 };
const WAIST_PREFIX: SeedPrefix = SeedPrefix { word: 0x5453494157, next_shift: 0x10000000000 };
const FOOT_PREFIX: SeedPrefix = SeedPrefix { word: 0x544f4f46, next_shift: 0x100000000 };
const HAND_PREFIX: SeedPrefix = SeedPrefix { word: 0x444e4148, next_shift: 0x100000000 };
const NECK_PREFIX: SeedPrefix = SeedPrefix { word: 0x4b43454e, next_shift: 0x100000000 };
const RING_PREFIX: SeedPrefix = SeedPrefix { word: 0x474e4952, next_shift: 0x100000000 };

#[derive(Copy, Debug, Drop, PartialEq, Serde)]
pub struct LootItem {
    pub id: u8,
    pub greatness: u8,
    pub suffix_id: u8,
    pub name_prefix_id: u8,
    pub name_suffix_id: u8,
}

#[derive(Clone, Copy, Debug, Drop, PartialEq, Serde)]
pub struct LootBag {
    pub weapon: LootItem,
    pub chest: LootItem,
    pub head: LootItem,
    pub waist: LootItem,
    pub foot: LootItem,
    pub hand: LootItem,
    pub neck: LootItem,
    pub ring: LootItem,
}

/// Familiar LootBag fields in memory, one felt in Starknet storage.
pub impl LootBagStorePacking of starknet::storage_access::StorePacking<LootBag, felt252> {
    fn pack(value: LootBag) -> felt252 {
        crate::packed::LootBagPackingTrait::pack(value).value
    }

    fn unpack(value: felt252) -> LootBag {
        crate::packed::PackedLootBagTrait::unpack(PackedLootBag { value })
    }
}

#[derive(Clone, Debug, Drop, PartialEq, Serde)]
pub struct LootBagNames {
    pub weapon: ByteArray,
    pub chest: ByteArray,
    pub head: ByteArray,
    pub waist: ByteArray,
    pub foot: ByteArray,
    pub hand: ByteArray,
    pub neck: ByteArray,
    pub ring: ByteArray,
}

pub fn get_loot_bag(bag_id: u64) -> LootBag {
    let seed = packed_decimal_seed(bag_id);
    LootBag {
        weapon: pluck_packed_item(seed, Slot::Weapon),
        chest: pluck_packed_item(seed, Slot::Chest),
        head: pluck_packed_item(seed, Slot::Head),
        waist: pluck_packed_item(seed, Slot::Waist),
        foot: pluck_packed_item(seed, Slot::Foot),
        hand: pluck_packed_item(seed, Slot::Hand),
        neck: pluck_packed_item(seed, Slot::Neck),
        ring: pluck_packed_item(seed, Slot::Ring),
    }
}

/// Generate one felt directly, avoiding the intermediate 40-field bag and its ABI serialization.
pub fn get_packed_loot_bag(bag_id: u64) -> PackedLootBag {
    let seed = packed_decimal_seed(bag_id);
    from_item_words(
        pluck_item_word(seed, Slot::Weapon),
        pluck_item_word(seed, Slot::Chest),
        pluck_item_word(seed, Slot::Head),
        pluck_item_word(seed, Slot::Waist),
        pluck_item_word(seed, Slot::Foot),
        pluck_item_word(seed, Slot::Hand),
        pluck_item_word(seed, Slot::Neck),
        pluck_item_word(seed, Slot::Ring),
    )
}

// Reuse the existing generation body, then enforce the packed field widths.
#[inline(never)]
fn pluck_item_word(seed: PackedSeed, slot: Slot) -> felt252 {
    crate::packed::pack_item(pluck_packed_item(seed, slot))
}

pub fn get_loot_bag_names(bag_id: u64) -> LootBagNames {
    render_bag_names(get_loot_bag(bag_id))
}

/// Render already-decoded fields without invoking generation.
#[inline(always)]
pub fn render_bag_names(bag: LootBag) -> LootBagNames {
    LootBagNames {
        weapon: render_item_name(bag.weapon),
        chest: render_chest_name(bag.chest),
        head: render_head_name(bag.head),
        waist: render_waist_name(bag.waist),
        foot: render_foot_name(bag.foot),
        hand: render_hand_name(bag.hand),
        neck: render_neck_name(bag.neck),
        ring: render_ring_name(bag.ring),
    }
}

pub fn get_weapon_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Weapon)
}

pub fn get_chest_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Chest)
}

pub fn get_head_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Head)
}

pub fn get_waist_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Waist)
}

pub fn get_foot_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Foot)
}

pub fn get_hand_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Hand)
}

pub fn get_neck_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Neck)
}

pub fn get_ring_item(bag_id: u64) -> LootItem {
    pluck_item(bag_id, Slot::Ring)
}

pub fn get_weapon_name(bag_id: u64) -> ByteArray {
    render_item_name(get_weapon_item(bag_id))
}

pub fn get_chest_name(bag_id: u64) -> ByteArray {
    render_chest_name(get_chest_item(bag_id))
}

pub fn get_head_name(bag_id: u64) -> ByteArray {
    render_head_name(get_head_item(bag_id))
}

pub fn get_waist_name(bag_id: u64) -> ByteArray {
    render_waist_name(get_waist_item(bag_id))
}

pub fn get_foot_name(bag_id: u64) -> ByteArray {
    render_foot_name(get_foot_item(bag_id))
}

pub fn get_hand_name(bag_id: u64) -> ByteArray {
    render_hand_name(get_hand_item(bag_id))
}

pub fn get_neck_name(bag_id: u64) -> ByteArray {
    render_neck_name(get_neck_item(bag_id))
}

pub fn get_ring_name(bag_id: u64) -> ByteArray {
    render_ring_name(get_ring_item(bag_id))
}

/// Gets the suffix name by ID
/// @param id The suffix ID (must be 1-16)
/// @return ByteArray The suffix name (e.g., "of Power")
pub fn suffix_name_by_id(id: u8) -> ByteArray {
    match id {
        0 => panic_with_felt252('invalid suffix id'),
        1 => "of Power",
        2 => "of Giants",
        3 => "of Titans",
        4 => "of Skill",
        5 => "of Perfection",
        6 => "of Brilliance",
        7 => "of Enlightenment",
        8 => "of Protection",
        9 => "of Anger",
        10 => "of Rage",
        11 => "of Fury",
        12 => "of Vitriol",
        13 => "of the Fox",
        14 => "of Detection",
        15 => "of Reflection",
        16 => "of the Twins",
        _ => panic_with_felt252('invalid suffix id'),
    }
}

/// Gets the name prefix by ID
/// @param id The name prefix ID (must be 1-69)
/// @return ByteArray The name prefix (e.g., "Grim")
pub fn name_prefix_by_id(id: u8) -> ByteArray {
    match id {
        0 => panic_with_felt252('invalid name prefix id'),
        1 => "Agony",
        2 => "Apocalypse",
        3 => "Armageddon",
        4 => "Beast",
        5 => "Behemoth",
        6 => "Blight",
        7 => "Blood",
        8 => "Bramble",
        9 => "Brimstone",
        10 => "Brood",
        11 => "Carrion",
        12 => "Cataclysm",
        13 => "Chimeric",
        14 => "Corpse",
        15 => "Corruption",
        16 => "Damnation",
        17 => "Death",
        18 => "Demon",
        19 => "Dire",
        20 => "Dragon",
        21 => "Dread",
        22 => "Doom",
        23 => "Dusk",
        24 => "Eagle",
        25 => "Empyrean",
        26 => "Fate",
        27 => "Foe",
        28 => "Gale",
        29 => "Ghoul",
        30 => "Gloom",
        31 => "Glyph",
        32 => "Golem",
        33 => "Grim",
        34 => "Hate",
        35 => "Havoc",
        36 => "Honour",
        37 => "Horror",
        38 => "Hypnotic",
        39 => "Kraken",
        40 => "Loath",
        41 => "Maelstrom",
        42 => "Mind",
        43 => "Miracle",
        44 => "Morbid",
        45 => "Oblivion",
        46 => "Onslaught",
        47 => "Pain",
        48 => "Pandemonium",
        49 => "Phoenix",
        50 => "Plague",
        51 => "Rage",
        52 => "Rapture",
        53 => "Rune",
        54 => "Skull",
        55 => "Sol",
        56 => "Soul",
        57 => "Sorrow",
        58 => "Spirit",
        59 => "Storm",
        60 => "Tempest",
        61 => "Torment",
        62 => "Vengeance",
        63 => "Victory",
        64 => "Viper",
        65 => "Vortex",
        66 => "Woe",
        67 => "Wrath",
        68 => "Light's",
        69 => "Shimmering",
        _ => panic_with_felt252('invalid name prefix id'),
    }
}

/// Gets the name suffix by ID
/// @param id The name suffix ID (must be 1-18)
/// @return ByteArray The name suffix (e.g., "Shout")
pub fn name_suffix_by_id(id: u8) -> ByteArray {
    match id {
        0 => panic_with_felt252('invalid name suffix id'),
        1 => "Bane",
        2 => "Root",
        3 => "Bite",
        4 => "Song",
        5 => "Roar",
        6 => "Grasp",
        7 => "Instrument",
        8 => "Glow",
        9 => "Bender",
        10 => "Shadow",
        11 => "Whisper",
        12 => "Shout",
        13 => "Growl",
        14 => "Tear",
        15 => "Peak",
        16 => "Form",
        17 => "Sun",
        18 => "Moon",
        _ => panic_with_felt252('invalid name suffix id'),
    }
}

/// Gets the base name of any item by its ID
/// @param id The item ID (must be 1-101)
/// @return ByteArray The base item name (e.g., "Katana", "Divine Robe")
/// Direct O(1) lookup - more efficient than array search
pub fn get_item_name(id: u8) -> ByteArray {
    // Including every contiguous u8 value from 0 lets Cairo lower this match to a jump table.
    match id {
        0 => panic_with_felt252('invalid item id'),
        1 => "Pendant",
        2 => "Necklace",
        3 => "Amulet",
        4 => "Silver Ring",
        5 => "Bronze Ring",
        6 => "Platinum Ring",
        7 => "Titanium Ring",
        8 => "Gold Ring",
        9 => "Ghost Wand",
        10 => "Grave Wand",
        11 => "Bone Wand",
        12 => "Wand",
        13 => "Grimoire",
        14 => "Chronicle",
        15 => "Tome",
        16 => "Book",
        17 => "Divine Robe",
        18 => "Silk Robe",
        19 => "Linen Robe",
        20 => "Robe",
        21 => "Shirt",
        22 => "Crown",
        23 => "Divine Hood",
        24 => "Silk Hood",
        25 => "Linen Hood",
        26 => "Hood",
        27 => "Brightsilk Sash",
        28 => "Silk Sash",
        29 => "Wool Sash",
        30 => "Linen Sash",
        31 => "Sash",
        32 => "Divine Slippers",
        33 => "Silk Slippers",
        34 => "Wool Shoes",
        35 => "Linen Shoes",
        36 => "Shoes",
        37 => "Divine Gloves",
        38 => "Silk Gloves",
        39 => "Wool Gloves",
        40 => "Linen Gloves",
        41 => "Gloves",
        42 => "Katana",
        43 => "Falchion",
        44 => "Scimitar",
        45 => "Long Sword",
        46 => "Short Sword",
        47 => "Demon Husk",
        48 => "Dragonskin Armor",
        49 => "Studded Leather Armor",
        50 => "Hard Leather Armor",
        51 => "Leather Armor",
        52 => "Demon Crown",
        53 => "Dragon's Crown",
        54 => "War Cap",
        55 => "Leather Cap",
        56 => "Cap",
        57 => "Demonhide Belt",
        58 => "Dragonskin Belt",
        59 => "Studded Leather Belt",
        60 => "Hard Leather Belt",
        61 => "Leather Belt",
        62 => "Demonhide Boots",
        63 => "Dragonskin Boots",
        64 => "Studded Leather Boots",
        65 => "Hard Leather Boots",
        66 => "Leather Boots",
        67 => "Demon's Hands",
        68 => "Dragonskin Gloves",
        69 => "Studded Leather Gloves",
        70 => "Hard Leather Gloves",
        71 => "Leather Gloves",
        72 => "Warhammer",
        73 => "Quarterstaff",
        74 => "Maul",
        75 => "Mace",
        76 => "Club",
        77 => "Holy Chestplate",
        78 => "Ornate Chestplate",
        79 => "Plate Mail",
        80 => "Chain Mail",
        81 => "Ring Mail",
        82 => "Ancient Helm",
        83 => "Ornate Helm",
        84 => "Great Helm",
        85 => "Full Helm",
        86 => "Helm",
        87 => "Ornate Belt",
        88 => "War Belt",
        89 => "Plated Belt",
        90 => "Mesh Belt",
        91 => "Heavy Belt",
        92 => "Holy Greaves",
        93 => "Ornate Greaves",
        94 => "Greaves",
        95 => "Chain Boots",
        96 => "Heavy Boots",
        97 => "Holy Gauntlets",
        98 => "Ornate Gauntlets",
        99 => "Gauntlets",
        100 => "Chain Gloves",
        101 => "Heavy Gloves",
        _ => panic_with_felt252('invalid item id'),
    }
}

pub fn render_item_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_chest_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_head_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_waist_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_foot_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_hand_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_neck_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn render_ring_name(item: LootItem) -> ByteArray {
    decorate_item_name(get_item_name(item.id), item)
}

fn decorate_item_name(mut base: ByteArray, item: LootItem) -> ByteArray {
    if item.greatness >= 19_u8 {
        let mut named: ByteArray = "\"";
        named.append(@name_prefix_by_id(item.name_prefix_id));
        named.append_byte(' ');
        named.append(@name_suffix_by_id(item.name_suffix_id));
        named.append_word('" ', 2);
        named.append(@base);
        base = named;
    }
    if item.greatness > 14_u8 {
        base.append_byte(' ');
        base.append(@suffix_name_by_id(item.suffix_id));
    }
    if item.greatness == 20_u8 {
        base.append_word(' +1', 3);
    }
    base
}

fn slot_seed_prefix(slot: Slot) -> SeedPrefix {
    match slot {
        Slot::Weapon => WEAPON_PREFIX,
        Slot::Chest => CHEST_PREFIX,
        Slot::Head => HEAD_PREFIX,
        Slot::Waist => WAIST_PREFIX,
        Slot::Foot => FOOT_PREFIX,
        Slot::Hand => HAND_PREFIX,
        Slot::Neck => NECK_PREFIX,
        Slot::Ring => RING_PREFIX,
    }
}

fn pluck_item(bag_id: u64, slot: Slot) -> LootItem {
    pluck_packed_item(packed_decimal_seed(bag_id), slot)
}

// Share the generation body while retaining the inlined base-item selector inside it.
#[inline(never)]
fn pluck_packed_item(seed: PackedSeed, slot: Slot) -> LootItem {
    let rand = packed_random(seed, slot_seed_prefix(slot));
    // One u256 reduction is enough for every downstream modulus because `LOOT_MODULUS` is their
    // least common multiple. The remaining divisions operate on a small `usize`.
    let random_index = loot_random_index(rand);
    let id = base_item_id(slot, random_index);
    // Modifier IDs are canonical one-based sequences, so allocating arrays just to index them is
    // unnecessary. Their lengths are fixed by the original Loot contract.
    let suffix_id = (random_index % SUFFIX_MOD + 1).try_into().unwrap();
    let name_prefix_id = (random_index % NAME_PREFIX_MOD + 1).try_into().unwrap();
    let name_suffix_id = (random_index % NAME_SUFFIX_MOD + 1).try_into().unwrap();
    let greatness_usize = random_index % GREATNESS_MOD;
    LootItem {
        id,
        greatness: greatness_usize.try_into().unwrap(),
        suffix_id,
        name_prefix_id,
        name_suffix_id,
    }
}

#[inline(always)]
fn base_item_id(slot: Slot, random_index: usize) -> u8 {
    // These matches preserve the canonical, non-monotonic list order without allocating an Array
    // on every lookup. Every index is reduced to the corresponding list length before selection.
    match slot {
        Slot::Weapon => {
            match random_index % 18 {
                0 => 72,
                1 => 73,
                2 => 74,
                3 => 75,
                4 => 76,
                5 => 42,
                6 => 43,
                7 => 44,
                8 => 45,
                9 => 46,
                10 => 9,
                11 => 10,
                12 => 11,
                13 => 12,
                14 => 13,
                15 => 14,
                16 => 15,
                17 => 16,
                _ => panic_with_felt252('invalid weapon index'),
            }
        },
        Slot::Chest => {
            match random_index % 15 {
                0 => 17,
                1 => 18,
                2 => 19,
                3 => 20,
                4 => 21,
                5 => 47,
                6 => 48,
                7 => 49,
                8 => 50,
                9 => 51,
                10 => 77,
                11 => 78,
                12 => 79,
                13 => 80,
                14 => 81,
                _ => panic_with_felt252('invalid chest index'),
            }
        },
        Slot::Head => {
            match random_index % 15 {
                0 => 82,
                1 => 83,
                2 => 84,
                3 => 85,
                4 => 86,
                5 => 52,
                6 => 53,
                7 => 54,
                8 => 55,
                9 => 56,
                10 => 22,
                11 => 23,
                12 => 24,
                13 => 25,
                14 => 26,
                _ => panic_with_felt252('invalid head index'),
            }
        },
        Slot::Waist => {
            match random_index % 15 {
                0 => 87,
                1 => 88,
                2 => 89,
                3 => 90,
                4 => 91,
                5 => 57,
                6 => 58,
                7 => 59,
                8 => 60,
                9 => 61,
                10 => 27,
                11 => 28,
                12 => 29,
                13 => 30,
                14 => 31,
                _ => panic_with_felt252('invalid waist index'),
            }
        },
        Slot::Foot => {
            match random_index % 15 {
                0 => 92,
                1 => 93,
                2 => 94,
                3 => 95,
                4 => 96,
                5 => 62,
                6 => 63,
                7 => 64,
                8 => 65,
                9 => 66,
                10 => 32,
                11 => 33,
                12 => 34,
                13 => 35,
                14 => 36,
                _ => panic_with_felt252('invalid foot index'),
            }
        },
        Slot::Hand => {
            match random_index % 15 {
                0 => 97,
                1 => 98,
                2 => 99,
                3 => 100,
                4 => 101,
                5 => 67,
                6 => 68,
                7 => 69,
                8 => 70,
                9 => 71,
                10 => 37,
                11 => 38,
                12 => 39,
                13 => 40,
                14 => 41,
                _ => panic_with_felt252('invalid hand index'),
            }
        },
        Slot::Neck => {
            match random_index % 3 {
                0 => 2,
                1 => 3,
                2 => 1,
                _ => panic_with_felt252('invalid neck index'),
            }
        },
        Slot::Ring => {
            match random_index % 5 {
                0 => 8,
                1 => 4,
                2 => 5,
                3 => 6,
                4 => 7,
                _ => panic_with_felt252('invalid ring index'),
            }
        },
    }
}

// Packs decimal ASCII in little-endian order, followed by Keccak's 0x01 padding byte.
// A u64 has at most 20 digits, so the result is below 2^168 and never wraps felt252.
fn packed_decimal_seed(mut value: u64) -> PackedSeed {
    let mut digits = 1;
    let ten: NonZero<u64> = 10;
    while value >= 10 {
        let (quotient, remainder) = DivRem::div_rem(value, ten);
        digits = digits * 0x100 + remainder.into() + 48;
        value = quotient;
    }
    PackedSeed { digits: digits * 0x100 + value.into() + 48 }
}

#[cfg(test)]
fn random(bag_id: u64, prefix: SeedPrefix) -> u256 {
    packed_random(packed_decimal_seed(bag_id), prefix)
}

fn packed_random(seed: PackedSeed, prefix: SeedPrefix) -> u256 {
    // At most six prefix bytes plus 20 digits and the padding byte: below 2^216,
    // safely within felt252. All bytes above the padding byte are already zero.
    let seed: u256 = (prefix.word.into() + seed.digits * prefix.next_shift.into()).into();
    let word_base: NonZero<u128> = 0x10000000000000000;
    let (word1, word0) = DivRem::div_rem(seed.low, word_base);
    let (word3, word2) = DivRem::div_rem(seed.high, word_base);
    // Exactly one 17-word Keccak rate block, including its final padding bit.
    let words = array![
        word0.try_into().unwrap(), word1.try_into().unwrap(), word2.try_into().unwrap(),
        word3.try_into().unwrap(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x8000000000000000,
    ];
    to_solidity_uint(starknet::syscalls::keccak_syscall(words.span()).unwrap_syscall())
}

fn to_solidity_uint(hash_le: u256) -> u256 {
    let low = u128_byte_reverse(hash_le.high);
    let high = u128_byte_reverse(hash_le.low);
    u256 { low, high }
}

fn loot_random_index(value: u256) -> usize {
    let (_, remainder) = DivRem::div_rem(value, LOOT_MODULUS);
    // The remainder is strictly below 115,920, so its high limb is necessarily zero.
    remainder.low.try_into().unwrap()
}

// ==================================================================================
// Type, Tier, and Slot Lookups
// ==================================================================================

// Helper functions to determine item categories
fn is_necklace(id: u8) -> bool {
    id == 1_u8 || id == 2_u8 || id == 3_u8
}

fn is_ring(id: u8) -> bool {
    id == 4_u8 || id == 5_u8 || id == 6_u8 || id == 7_u8 || id == 8_u8
}

fn is_magic_or_cloth(id: u8) -> bool {
    // Ghost Wand (9) to Gloves (41)
    id >= 9_u8 && id <= 41_u8
}

fn is_blade_or_hide(id: u8) -> bool {
    // Katana (42) to Leather Gloves (71)
    id >= 42_u8 && id <= 71_u8
}

fn is_bludgeon_or_metal(id: u8) -> bool {
    // Warhammer (72) to Heavy Gloves (101)
    id >= 72_u8 && id <= 101_u8
}

/// Gets the type of a Loot item
/// @param id The item ID (must be 1-101)
/// @return Type The type classification of the item
pub fn get_type(id: u8) -> Type {
    if is_magic_or_cloth(id) {
        Type::Magic_or_Cloth
    } else if is_blade_or_hide(id) {
        Type::Blade_or_Hide
    } else if is_bludgeon_or_metal(id) {
        Type::Bludgeon_or_Metal
    } else {
        panic_with_felt252('invalid item id')
    }
}

/// Gets the tier (rarity/power level) of an item
/// @param id The item ID (must be 1-101)
/// @return Tier The tier classification (T1-T5)
/// Tier is per item, not per ID range: each five-item ladder runs T1 (best) to T5, the
/// four-item wand and book ladders skip T4, and rings (4-8) are not a ladder at all -
/// Silver T2, Bronze T3, Platinum/Titanium/Gold T1. Checked against `constants::item_tiers`.
pub fn get_tier(id: u8) -> Tier {
    // Including every contiguous u8 value from 0 lets Cairo lower this match to a jump table.
    match id {
        0 => panic_with_felt252('invalid item id'),
        1 => Tier::T1, // Pendant
        2 => Tier::T1, // Necklace
        3 => Tier::T1, // Amulet
        4 => Tier::T2, // Silver Ring
        5 => Tier::T3, // Bronze Ring
        6 => Tier::T1, // Platinum Ring
        7 => Tier::T1, // Titanium Ring
        8 => Tier::T1, // Gold Ring
        9 => Tier::T1, // Ghost Wand
        10 => Tier::T2, // Grave Wand
        11 => Tier::T3, // Bone Wand
        12 => Tier::T5, // Wand
        13 => Tier::T1, // Grimoire
        14 => Tier::T2, // Chronicle
        15 => Tier::T3, // Tome
        16 => Tier::T5, // Book
        17 => Tier::T1, // Divine Robe
        18 => Tier::T2, // Silk Robe
        19 => Tier::T3, // Linen Robe
        20 => Tier::T4, // Robe
        21 => Tier::T5, // Shirt
        22 => Tier::T1, // Crown
        23 => Tier::T2, // Divine Hood
        24 => Tier::T3, // Silk Hood
        25 => Tier::T4, // Linen Hood
        26 => Tier::T5, // Hood
        27 => Tier::T1, // Brightsilk Sash
        28 => Tier::T2, // Silk Sash
        29 => Tier::T3, // Wool Sash
        30 => Tier::T4, // Linen Sash
        31 => Tier::T5, // Sash
        32 => Tier::T1, // Divine Slippers
        33 => Tier::T2, // Silk Slippers
        34 => Tier::T3, // Wool Shoes
        35 => Tier::T4, // Linen Shoes
        36 => Tier::T5, // Shoes
        37 => Tier::T1, // Divine Gloves
        38 => Tier::T2, // Silk Gloves
        39 => Tier::T3, // Wool Gloves
        40 => Tier::T4, // Linen Gloves
        41 => Tier::T5, // Gloves
        42 => Tier::T1, // Katana
        43 => Tier::T2, // Falchion
        44 => Tier::T3, // Scimitar
        45 => Tier::T4, // Long Sword
        46 => Tier::T5, // Short Sword
        47 => Tier::T1, // Demon Husk
        48 => Tier::T2, // Dragonskin Armor
        49 => Tier::T3, // Studded Leather Armor
        50 => Tier::T4, // Hard Leather Armor
        51 => Tier::T5, // Leather Armor
        52 => Tier::T1, // Demon Crown
        53 => Tier::T2, // Dragon's Crown
        54 => Tier::T3, // War Cap
        55 => Tier::T4, // Leather Cap
        56 => Tier::T5, // Cap
        57 => Tier::T1, // Demonhide Belt
        58 => Tier::T2, // Dragonskin Belt
        59 => Tier::T3, // Studded Leather Belt
        60 => Tier::T4, // Hard Leather Belt
        61 => Tier::T5, // Leather Belt
        62 => Tier::T1, // Demonhide Boots
        63 => Tier::T2, // Dragonskin Boots
        64 => Tier::T3, // Studded Leather Boots
        65 => Tier::T4, // Hard Leather Boots
        66 => Tier::T5, // Leather Boots
        67 => Tier::T1, // Demon's Hands
        68 => Tier::T2, // Dragonskin Gloves
        69 => Tier::T3, // Studded Leather Gloves
        70 => Tier::T4, // Hard Leather Gloves
        71 => Tier::T5, // Leather Gloves
        72 => Tier::T1, // Warhammer
        73 => Tier::T2, // Quarterstaff
        74 => Tier::T3, // Maul
        75 => Tier::T4, // Mace
        76 => Tier::T5, // Club
        77 => Tier::T1, // Holy Chestplate
        78 => Tier::T2, // Ornate Chestplate
        79 => Tier::T3, // Plate Mail
        80 => Tier::T4, // Chain Mail
        81 => Tier::T5, // Ring Mail
        82 => Tier::T1, // Ancient Helm
        83 => Tier::T2, // Ornate Helm
        84 => Tier::T3, // Great Helm
        85 => Tier::T4, // Full Helm
        86 => Tier::T5, // Helm
        87 => Tier::T1, // Ornate Belt
        88 => Tier::T2, // War Belt
        89 => Tier::T3, // Plated Belt
        90 => Tier::T4, // Mesh Belt
        91 => Tier::T5, // Heavy Belt
        92 => Tier::T1, // Holy Greaves
        93 => Tier::T2, // Ornate Greaves
        94 => Tier::T3, // Greaves
        95 => Tier::T4, // Chain Boots
        96 => Tier::T5, // Heavy Boots
        97 => Tier::T1, // Holy Gauntlets
        98 => Tier::T2, // Ornate Gauntlets
        99 => Tier::T3, // Gauntlets
        100 => Tier::T4, // Chain Gloves
        101 => Tier::T5, // Heavy Gloves
        _ => panic_with_felt252('invalid item id'),
    }
}

/// Gets the equipment slot for an item
/// @param id The item ID (must be 1-101)
/// @return Slot The equipment slot
pub fn get_slot(id: u8) -> Slot {
    // Necklaces (1-3)
    if id >= 1_u8 && id <= 3_u8 {
        Slot::Neck
    } // Rings (4-8)
    else if id >= 4_u8 && id <= 8_u8 {
        Slot::Ring
    } // Weapons (9-16, 42-46, 72-76)
    else if (id >= 9_u8 && id <= 16_u8)
        || (id >= 42_u8 && id <= 46_u8)
        || (id >= 72_u8 && id <= 76_u8) {
        Slot::Weapon
    } // Chest (17-21, 47-51, 77-81)
    else if (id >= 17_u8 && id <= 21_u8)
        || (id >= 47_u8 && id <= 51_u8)
        || (id >= 77_u8 && id <= 81_u8) {
        Slot::Chest
    } // Head (22-26, 52-56, 82-86)
    else if (id >= 22_u8 && id <= 26_u8)
        || (id >= 52_u8 && id <= 56_u8)
        || (id >= 82_u8 && id <= 86_u8) {
        Slot::Head
    } // Waist (27-31, 57-61, 87-91)
    else if (id >= 27_u8 && id <= 31_u8)
        || (id >= 57_u8 && id <= 61_u8)
        || (id >= 87_u8 && id <= 91_u8) {
        Slot::Waist
    } // Foot (32-36, 62-66, 92-96)
    else if (id >= 32_u8 && id <= 36_u8)
        || (id >= 62_u8 && id <= 66_u8)
        || (id >= 92_u8 && id <= 96_u8) {
        Slot::Foot
    } // Hand (37-41, 67-71, 97-101)
    else if (id >= 37_u8 && id <= 41_u8)
        || (id >= 67_u8 && id <= 71_u8)
        || (id >= 97_u8 && id <= 101_u8) {
        Slot::Hand
    } else {
        panic_with_felt252('invalid item id')
    }
}

#[cfg(test)]
mod tests {
    use core::array::Array;
    use core::byte_array::{ByteArray, ByteArrayTrait};
    use core::keccak::compute_keccak_byte_array;
    use core::traits::TryInto;
    use crate::constants::{
        chest_ids, foot_ids, hand_ids, head_ids, neck_ids, ring_ids, waist_ids, weapon_ids,
    };
    use super::{
        CHEST_PREFIX, FOOT_PREFIX, GREATNESS_MOD, HAND_PREFIX, HEAD_PREFIX, LOOT_MODULUS,
        NAME_PREFIX_MOD, NAME_SUFFIX_MOD, NECK_PREFIX, RING_PREFIX, SUFFIX_MOD, SeedPrefix, Slot,
        WAIST_PREFIX, WEAPON_PREFIX, base_item_id, random, to_solidity_uint,
    };

    fn legacy_random(bag_id: u64, key_prefix: @ByteArray) -> u256 {
        let mut seed = key_prefix.clone();
        let id_string = legacy_decimal_string(bag_id);
        seed.append(@id_string);
        to_solidity_uint(compute_keccak_byte_array(@seed))
    }

    fn legacy_decimal_string(bag_id: u64) -> ByteArray {
        if bag_id == 0 {
            return "0";
        }
        let mut result: ByteArray = "";
        legacy_decimal_string_inner(bag_id, ref result);
        result
    }

    fn legacy_decimal_string_inner(value: u64, ref buffer: ByteArray) {
        if value >= 10 {
            legacy_decimal_string_inner(value / 10, ref buffer);
        }
        let digit: u8 = (value % 10).try_into().unwrap();
        buffer.append_byte(48 + digit);
    }

    fn assert_random_matches(bag_id: u64, prefix: SeedPrefix, key_prefix: @ByteArray) {
        assert!(random(bag_id, prefix) == legacy_random(bag_id, key_prefix));
    }

    fn loot_modulus_usize() -> usize {
        let modulus: u256 = LOOT_MODULUS.into();
        modulus.try_into().unwrap()
    }

    fn assert_base_item_ids(slot: Slot, slot_label: ByteArray, expected: Array<u8>) {
        let len = expected.len();
        let modulus = loot_modulus_usize();
        let mut index = 0;
        loop {
            if index == len {
                break;
            }
            let expected_id = *expected.at(index);
            let actual_id = base_item_id(slot, index);
            // Cache absence uses zero. Every possible canonical base selector is positive,
            // including every weapon (the low summand in exact-felt bag assembly).
            assert!(actual_id > 0, "canonical base ID must be nonzero");
            assert!(
                actual_id < 128,
                "base item exceeds packed ID width for {slot_label} at index {index}",
            );
            assert!(
                actual_id == expected_id, "base item mismatch for {slot_label} at index {index}",
            );
            // Every base-list length divides the shared random-index modulus.
            assert!(
                base_item_id(slot, index + modulus) == expected_id,
                "post-modulus item mismatch for {slot_label} at index {index}",
            );
            index += 1;
        };
    }

    #[test]
    fn direct_base_item_selectors_match_canonical_id_lists() {
        // Pin the generated maxima to the wire widths without hashing sampled bags.
        // Greatness is zero-based; the three modifier IDs are one-based.
        assert!(GREATNESS_MOD <= 32, "generated greatness exceeds packed width");
        assert!(SUFFIX_MOD < 32, "generated suffix exceeds packed width");
        assert!(NAME_PREFIX_MOD < 128, "generated name prefix exceeds packed width");
        assert!(NAME_SUFFIX_MOD < 32, "generated name suffix exceeds packed width");
        // Reduction before field selection is valid only when each modulus divides it.
        let modulus = loot_modulus_usize();
        assert!(modulus % GREATNESS_MOD == 0, "GREATNESS_MOD must divide LOOT_MODULUS");
        assert!(modulus % SUFFIX_MOD == 0, "SUFFIX_MOD must divide LOOT_MODULUS");
        assert!(modulus % NAME_PREFIX_MOD == 0, "NAME_PREFIX_MOD must divide LOOT_MODULUS");
        assert!(modulus % NAME_SUFFIX_MOD == 0, "NAME_SUFFIX_MOD must divide LOOT_MODULUS");
        assert_base_item_ids(Slot::Weapon, "weapon", weapon_ids());
        assert_base_item_ids(Slot::Chest, "chest", chest_ids());
        assert_base_item_ids(Slot::Head, "head", head_ids());
        assert_base_item_ids(Slot::Waist, "waist", waist_ids());
        assert_base_item_ids(Slot::Foot, "foot", foot_ids());
        assert_base_item_ids(Slot::Hand, "hand", hand_ids());
        assert_base_item_ids(Slot::Neck, "neck", neck_ids());
        assert_base_item_ids(Slot::Ring, "ring", ring_ids());
    }

    #[test]
    fn packed_seed_matches_legacy_hash_for_deterministic_bag_ids() {
        // Replay the same property in a traced test: Foundry fuzz runs do not emit coverage
        // traces. A full-period u64 LCG also exercises long IDs for every slot prefix.
        let mut bag_id = 0x535441524b_u64;
        let mut run = 0_u32;
        while run < 64 {
            packed_seed_matches_legacy_hash_for_u64_ids(bag_id);
            let next: u128 = bag_id.into() * 6_364_136_223_846_793_005 + 1;
            bag_id = (next % 0x10000000000000000).try_into().unwrap();
            run += 1;
        }
    }

    #[test]
    fn packed_seed_matches_legacy_hash_for_powers_of_ten() {
        let mut bag_id = 1_u64;
        loop {
            assert_random_matches(bag_id, WEAPON_PREFIX, @"WEAPON");
            if bag_id == 10_000_000_000_000_000_000 {
                break;
            }
            bag_id *= 10;
        };
    }

    #[test]
    fn packed_seed_matches_legacy_hash_across_word_boundaries() {
        // Six-byte prefix: exercise zero, decimal digit, and 8/16/24-byte boundaries.
        assert_random_matches(0, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(9, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(10, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(1_000_000_000, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(100_000_000_000_000_000, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(0xffffffffffffffff, WEAPON_PREFIX, @"WEAPON");

        // Four-byte prefix reaches exact 8/16/24-byte lengths at 4, 12, and 20 digits.
        assert_random_matches(1_000, HEAD_PREFIX, @"HEAD");
        assert_random_matches(100_000_000_000, HEAD_PREFIX, @"HEAD");
        assert_random_matches(0xffffffffffffffff, HEAD_PREFIX, @"HEAD");

        // Cover every packed prefix constant at the maximum decimal length.
        assert_random_matches(0xffffffffffffffff, CHEST_PREFIX, @"CHEST");
        assert_random_matches(0xffffffffffffffff, WAIST_PREFIX, @"WAIST");
        assert_random_matches(0xffffffffffffffff, FOOT_PREFIX, @"FOOT");
        assert_random_matches(0xffffffffffffffff, HAND_PREFIX, @"HAND");
        assert_random_matches(0xffffffffffffffff, NECK_PREFIX, @"NECK");
        assert_random_matches(0xffffffffffffffff, RING_PREFIX, @"RING");
    }

    #[test]
    #[fuzzer(runs: 64)]
    fn packed_seed_matches_legacy_hash_for_u64_ids(bag_id: u64) {
        assert_random_matches(bag_id, WEAPON_PREFIX, @"WEAPON");
        assert_random_matches(bag_id, CHEST_PREFIX, @"CHEST");
        assert_random_matches(bag_id, HEAD_PREFIX, @"HEAD");
        assert_random_matches(bag_id, WAIST_PREFIX, @"WAIST");
        assert_random_matches(bag_id, FOOT_PREFIX, @"FOOT");
        assert_random_matches(bag_id, HAND_PREFIX, @"HAND");
        assert_random_matches(bag_id, NECK_PREFIX, @"NECK");
        assert_random_matches(bag_id, RING_PREFIX, @"RING");
    }
}
