use core::array::Array;
use core::byte_array::ByteArray;

pub fn weapons() -> Array<ByteArray> {
    array![
        "Warhammer", "Quarterstaff", "Maul", "Mace", "Club", "Katana", "Falchion", "Scimitar",
        "Long Sword", "Short Sword", "Ghost Wand", "Grave Wand", "Bone Wand", "Wand", "Grimoire",
        "Chronicle", "Tome", "Book",
    ]
}

pub fn weapon_ids() -> Array<u8> {
    array![72, 73, 74, 75, 76, 42, 43, 44, 45, 46, 9, 10, 11, 12, 13, 14, 15, 16]
}

pub fn chest_armors() -> Array<ByteArray> {
    array![
        "Divine Robe", "Silk Robe", "Linen Robe", "Robe", "Shirt", "Demon Husk", "Dragonskin Armor",
        "Studded Leather Armor", "Hard Leather Armor", "Leather Armor", "Holy Chestplate",
        "Ornate Chestplate", "Plate Mail", "Chain Mail", "Ring Mail",
    ]
}

pub fn chest_ids() -> Array<u8> {
    array![17, 18, 19, 20, 21, 47, 48, 49, 50, 51, 77, 78, 79, 80, 81]
}

pub fn head_armors() -> Array<ByteArray> {
    array![
        "Ancient Helm", "Ornate Helm", "Great Helm", "Full Helm", "Helm", "Demon Crown",
        "Dragon's Crown", "War Cap", "Leather Cap", "Cap", "Crown", "Divine Hood", "Silk Hood",
        "Linen Hood", "Hood",
    ]
}

pub fn head_ids() -> Array<u8> {
    array![82, 83, 84, 85, 86, 52, 53, 54, 55, 56, 22, 23, 24, 25, 26]
}

pub fn waist_armors() -> Array<ByteArray> {
    array![
        "Ornate Belt", "War Belt", "Plated Belt", "Mesh Belt", "Heavy Belt", "Demonhide Belt",
        "Dragonskin Belt", "Studded Leather Belt", "Hard Leather Belt", "Leather Belt",
        "Brightsilk Sash", "Silk Sash", "Wool Sash", "Linen Sash", "Sash",
    ]
}

pub fn waist_ids() -> Array<u8> {
    array![87, 88, 89, 90, 91, 57, 58, 59, 60, 61, 27, 28, 29, 30, 31]
}

pub fn foot_armors() -> Array<ByteArray> {
    array![
        "Holy Greaves", "Ornate Greaves", "Greaves", "Chain Boots", "Heavy Boots",
        "Demonhide Boots", "Dragonskin Boots", "Studded Leather Boots", "Hard Leather Boots",
        "Leather Boots", "Divine Slippers", "Silk Slippers", "Wool Shoes", "Linen Shoes", "Shoes",
    ]
}

pub fn foot_ids() -> Array<u8> {
    array![92, 93, 94, 95, 96, 62, 63, 64, 65, 66, 32, 33, 34, 35, 36]
}

pub fn hand_armors() -> Array<ByteArray> {
    array![
        "Holy Gauntlets", "Ornate Gauntlets", "Gauntlets", "Chain Gloves", "Heavy Gloves",
        "Demon's Hands", "Dragonskin Gloves", "Studded Leather Gloves", "Hard Leather Gloves",
        "Leather Gloves", "Divine Gloves", "Silk Gloves", "Wool Gloves", "Linen Gloves", "Gloves",
    ]
}

pub fn hand_ids() -> Array<u8> {
    array![97, 98, 99, 100, 101, 67, 68, 69, 70, 71, 37, 38, 39, 40, 41]
}

pub fn necklaces() -> Array<ByteArray> {
    array!["Necklace", "Amulet", "Pendant"]
}

pub fn neck_ids() -> Array<u8> {
    array![2, 3, 1]
}

pub fn rings() -> Array<ByteArray> {
    array!["Gold Ring", "Silver Ring", "Bronze Ring", "Platinum Ring", "Titanium Ring"]
}

pub fn ring_ids() -> Array<u8> {
    array![8, 4, 5, 6, 7]
}

pub fn suffixes() -> Array<ByteArray> {
    array![
        "of Power", "of Giants", "of Titans", "of Skill", "of Perfection", "of Brilliance",
        "of Enlightenment", "of Protection", "of Anger", "of Rage", "of Fury", "of Vitriol",
        "of the Fox", "of Detection", "of Reflection", "of the Twins",
    ]
}

pub fn suffix_ids() -> Array<u8> {
    array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
}

pub fn name_prefixes() -> Array<ByteArray> {
    array![
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble",
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption",
        "Damnation", "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle",
        "Empyrean", "Fate", "Foe", "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate",
        "Havoc", "Honour", "Horror", "Hypnotic", "Kraken", "Loath", "Maelstrom", "Mind", "Miracle",
        "Morbid", "Oblivion", "Onslaught", "Pain", "Pandemonium", "Phoenix", "Plague", "Rage",
        "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", "Spirit", "Storm", "Tempest",
        "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath", "Light's",
        "Shimmering",
    ]
}

pub fn name_prefix_ids() -> Array<u8> {
    array![
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
        26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
        49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
    ]
}

pub fn name_suffixes() -> Array<ByteArray> {
    array![
        "Bane", "Root", "Bite", "Song", "Roar", "Grasp", "Instrument", "Glow", "Bender", "Shadow",
        "Whisper", "Shout", "Growl", "Tear", "Peak", "Form", "Sun", "Moon",
    ]
}

pub fn name_suffix_ids() -> Array<u8> {
    array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]
}

/// Canonical item tiers, indexed by item ID - 1 (IDs 1-101 in order).
/// Transcribed from the death-mountain loot package, the upstream source for this metadata:
/// Provable-Games/death-mountain, contracts/src/utils/loot.cairo, as of commit
/// 4e8f0e439e9e5104fa6081063ca58859a51d069a.
/// Tiers are per item, not per ID range: each five-item ladder runs T1 (best) to T5, the
/// four-item wand and book ladders skip T4, and rings (4-8) are not a ladder at all.
/// One ID per line, so an entry can be read against upstream without counting commas.
pub fn item_tiers() -> Array<u8> {
    array![
        1, // 1 Pendant
        1, // 2 Necklace
        1, // 3 Amulet
        2, // 4 Silver Ring
        3, // 5 Bronze Ring
        1, // 6 Platinum Ring
        1, // 7 Titanium Ring
        1, // 8 Gold Ring
        1, // 9 Ghost Wand
        2, // 10 Grave Wand
        3, // 11 Bone Wand
        5, // 12 Wand
        1, // 13 Grimoire
        2, // 14 Chronicle
        3, // 15 Tome
        5, // 16 Book
        1, // 17 Divine Robe
        2, // 18 Silk Robe
        3, // 19 Linen Robe
        4, // 20 Robe
        5, // 21 Shirt
        1, // 22 Crown
        2, // 23 Divine Hood
        3, // 24 Silk Hood
        4, // 25 Linen Hood
        5, // 26 Hood
        1, // 27 Brightsilk Sash
        2, // 28 Silk Sash
        3, // 29 Wool Sash
        4, // 30 Linen Sash
        5, // 31 Sash
        1, // 32 Divine Slippers
        2, // 33 Silk Slippers
        3, // 34 Wool Shoes
        4, // 35 Linen Shoes
        5, // 36 Shoes
        1, // 37 Divine Gloves
        2, // 38 Silk Gloves
        3, // 39 Wool Gloves
        4, // 40 Linen Gloves
        5, // 41 Gloves
        1, // 42 Katana
        2, // 43 Falchion
        3, // 44 Scimitar
        4, // 45 Long Sword
        5, // 46 Short Sword
        1, // 47 Demon Husk
        2, // 48 Dragonskin Armor
        3, // 49 Studded Leather Armor
        4, // 50 Hard Leather Armor
        5, // 51 Leather Armor
        1, // 52 Demon Crown
        2, // 53 Dragon's Crown
        3, // 54 War Cap
        4, // 55 Leather Cap
        5, // 56 Cap
        1, // 57 Demonhide Belt
        2, // 58 Dragonskin Belt
        3, // 59 Studded Leather Belt
        4, // 60 Hard Leather Belt
        5, // 61 Leather Belt
        1, // 62 Demonhide Boots
        2, // 63 Dragonskin Boots
        3, // 64 Studded Leather Boots
        4, // 65 Hard Leather Boots
        5, // 66 Leather Boots
        1, // 67 Demon's Hands
        2, // 68 Dragonskin Gloves
        3, // 69 Studded Leather Gloves
        4, // 70 Hard Leather Gloves
        5, // 71 Leather Gloves
        1, // 72 Warhammer
        2, // 73 Quarterstaff
        3, // 74 Maul
        4, // 75 Mace
        5, // 76 Club
        1, // 77 Holy Chestplate
        2, // 78 Ornate Chestplate
        3, // 79 Plate Mail
        4, // 80 Chain Mail
        5, // 81 Ring Mail
        1, // 82 Ancient Helm
        2, // 83 Ornate Helm
        3, // 84 Great Helm
        4, // 85 Full Helm
        5, // 86 Helm
        1, // 87 Ornate Belt
        2, // 88 War Belt
        3, // 89 Plated Belt
        4, // 90 Mesh Belt
        5, // 91 Heavy Belt
        1, // 92 Holy Greaves
        2, // 93 Ornate Greaves
        3, // 94 Greaves
        4, // 95 Chain Boots
        5, // 96 Heavy Boots
        1, // 97 Holy Gauntlets
        2, // 98 Ornate Gauntlets
        3, // 99 Gauntlets
        4, // 100 Chain Gloves
        5 // 101 Heavy Gloves
    ]
}

/// Canonical item combat types, indexed by item ID - 1 (IDs 1-101 in order).
/// Same upstream source and commit as `item_tiers`.
/// Encoded as 0 = no combat type, 1 = Magic_or_Cloth, 2 = Blade_or_Hide, 3 = Bludgeon_or_Metal.
/// Upstream gives necklaces and rings their own Type variants; this crate's `Type` enum has only
/// the three combat types, so `get_type` panics for those IDs and they are recorded as 0 here.
/// One ID per line, so an entry can be read against upstream without counting commas.
pub fn item_types() -> Array<u8> {
    array![
        0, // 1 Pendant (Necklace - no combat type)
        0, // 2 Necklace (Necklace - no combat type)
        0, // 3 Amulet (Necklace - no combat type)
        0, // 4 Silver Ring (Ring - no combat type)
        0, // 5 Bronze Ring (Ring - no combat type)
        0, // 6 Platinum Ring (Ring - no combat type)
        0, // 7 Titanium Ring (Ring - no combat type)
        0, // 8 Gold Ring (Ring - no combat type)
        1, // 9 Ghost Wand (Magic_or_Cloth)
        1, // 10 Grave Wand (Magic_or_Cloth)
        1, // 11 Bone Wand (Magic_or_Cloth)
        1, // 12 Wand (Magic_or_Cloth)
        1, // 13 Grimoire (Magic_or_Cloth)
        1, // 14 Chronicle (Magic_or_Cloth)
        1, // 15 Tome (Magic_or_Cloth)
        1, // 16 Book (Magic_or_Cloth)
        1, // 17 Divine Robe (Magic_or_Cloth)
        1, // 18 Silk Robe (Magic_or_Cloth)
        1, // 19 Linen Robe (Magic_or_Cloth)
        1, // 20 Robe (Magic_or_Cloth)
        1, // 21 Shirt (Magic_or_Cloth)
        1, // 22 Crown (Magic_or_Cloth)
        1, // 23 Divine Hood (Magic_or_Cloth)
        1, // 24 Silk Hood (Magic_or_Cloth)
        1, // 25 Linen Hood (Magic_or_Cloth)
        1, // 26 Hood (Magic_or_Cloth)
        1, // 27 Brightsilk Sash (Magic_or_Cloth)
        1, // 28 Silk Sash (Magic_or_Cloth)
        1, // 29 Wool Sash (Magic_or_Cloth)
        1, // 30 Linen Sash (Magic_or_Cloth)
        1, // 31 Sash (Magic_or_Cloth)
        1, // 32 Divine Slippers (Magic_or_Cloth)
        1, // 33 Silk Slippers (Magic_or_Cloth)
        1, // 34 Wool Shoes (Magic_or_Cloth)
        1, // 35 Linen Shoes (Magic_or_Cloth)
        1, // 36 Shoes (Magic_or_Cloth)
        1, // 37 Divine Gloves (Magic_or_Cloth)
        1, // 38 Silk Gloves (Magic_or_Cloth)
        1, // 39 Wool Gloves (Magic_or_Cloth)
        1, // 40 Linen Gloves (Magic_or_Cloth)
        1, // 41 Gloves (Magic_or_Cloth)
        2, // 42 Katana (Blade_or_Hide)
        2, // 43 Falchion (Blade_or_Hide)
        2, // 44 Scimitar (Blade_or_Hide)
        2, // 45 Long Sword (Blade_or_Hide)
        2, // 46 Short Sword (Blade_or_Hide)
        2, // 47 Demon Husk (Blade_or_Hide)
        2, // 48 Dragonskin Armor (Blade_or_Hide)
        2, // 49 Studded Leather Armor (Blade_or_Hide)
        2, // 50 Hard Leather Armor (Blade_or_Hide)
        2, // 51 Leather Armor (Blade_or_Hide)
        2, // 52 Demon Crown (Blade_or_Hide)
        2, // 53 Dragon's Crown (Blade_or_Hide)
        2, // 54 War Cap (Blade_or_Hide)
        2, // 55 Leather Cap (Blade_or_Hide)
        2, // 56 Cap (Blade_or_Hide)
        2, // 57 Demonhide Belt (Blade_or_Hide)
        2, // 58 Dragonskin Belt (Blade_or_Hide)
        2, // 59 Studded Leather Belt (Blade_or_Hide)
        2, // 60 Hard Leather Belt (Blade_or_Hide)
        2, // 61 Leather Belt (Blade_or_Hide)
        2, // 62 Demonhide Boots (Blade_or_Hide)
        2, // 63 Dragonskin Boots (Blade_or_Hide)
        2, // 64 Studded Leather Boots (Blade_or_Hide)
        2, // 65 Hard Leather Boots (Blade_or_Hide)
        2, // 66 Leather Boots (Blade_or_Hide)
        2, // 67 Demon's Hands (Blade_or_Hide)
        2, // 68 Dragonskin Gloves (Blade_or_Hide)
        2, // 69 Studded Leather Gloves (Blade_or_Hide)
        2, // 70 Hard Leather Gloves (Blade_or_Hide)
        2, // 71 Leather Gloves (Blade_or_Hide)
        3, // 72 Warhammer (Bludgeon_or_Metal)
        3, // 73 Quarterstaff (Bludgeon_or_Metal)
        3, // 74 Maul (Bludgeon_or_Metal)
        3, // 75 Mace (Bludgeon_or_Metal)
        3, // 76 Club (Bludgeon_or_Metal)
        3, // 77 Holy Chestplate (Bludgeon_or_Metal)
        3, // 78 Ornate Chestplate (Bludgeon_or_Metal)
        3, // 79 Plate Mail (Bludgeon_or_Metal)
        3, // 80 Chain Mail (Bludgeon_or_Metal)
        3, // 81 Ring Mail (Bludgeon_or_Metal)
        3, // 82 Ancient Helm (Bludgeon_or_Metal)
        3, // 83 Ornate Helm (Bludgeon_or_Metal)
        3, // 84 Great Helm (Bludgeon_or_Metal)
        3, // 85 Full Helm (Bludgeon_or_Metal)
        3, // 86 Helm (Bludgeon_or_Metal)
        3, // 87 Ornate Belt (Bludgeon_or_Metal)
        3, // 88 War Belt (Bludgeon_or_Metal)
        3, // 89 Plated Belt (Bludgeon_or_Metal)
        3, // 90 Mesh Belt (Bludgeon_or_Metal)
        3, // 91 Heavy Belt (Bludgeon_or_Metal)
        3, // 92 Holy Greaves (Bludgeon_or_Metal)
        3, // 93 Ornate Greaves (Bludgeon_or_Metal)
        3, // 94 Greaves (Bludgeon_or_Metal)
        3, // 95 Chain Boots (Bludgeon_or_Metal)
        3, // 96 Heavy Boots (Bludgeon_or_Metal)
        3, // 97 Holy Gauntlets (Bludgeon_or_Metal)
        3, // 98 Ornate Gauntlets (Bludgeon_or_Metal)
        3, // 99 Gauntlets (Bludgeon_or_Metal)
        3, // 100 Chain Gloves (Bludgeon_or_Metal)
        3 // 101 Heavy Gloves (Bludgeon_or_Metal)
    ]
}
