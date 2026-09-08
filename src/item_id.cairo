// Item ID constants
// IDs are grouped by combat type for efficient type/tier lookups
// Source: Compatible with Ethereum Loot contract and death-mountain

pub mod ItemId {
    // Necklaces (1-3)
    pub const Pendant: u8 = 1;
    pub const Necklace: u8 = 2;
    pub const Amulet: u8 = 3;

    // Rings (4-8)
    pub const SilverRing: u8 = 4;
    pub const BronzeRing: u8 = 5;
    pub const PlatinumRing: u8 = 6;
    pub const TitaniumRing: u8 = 7;
    pub const GoldRing: u8 = 8;

    // Magic Weapons (9-16)
    pub const GhostWand: u8 = 9;
    pub const GraveWand: u8 = 10;
    pub const BoneWand: u8 = 11;
    pub const Wand: u8 = 12;
    pub const Grimoire: u8 = 13;
    pub const Chronicle: u8 = 14;
    pub const Tome: u8 = 15;
    pub const Book: u8 = 16;

    // Cloth Chest (17-21)
    pub const DivineRobe: u8 = 17;
    pub const SilkRobe: u8 = 18;
    pub const LinenRobe: u8 = 19;
    pub const Robe: u8 = 20;
    pub const Shirt: u8 = 21;

    // Cloth Head (22-26)
    pub const Crown: u8 = 22;
    pub const DivineHood: u8 = 23;
    pub const SilkHood: u8 = 24;
    pub const LinenHood: u8 = 25;
    pub const Hood: u8 = 26;

    // Cloth Waist (27-31)
    pub const BrightsilkSash: u8 = 27;
    pub const SilkSash: u8 = 28;
    pub const WoolSash: u8 = 29;
    pub const LinenSash: u8 = 30;
    pub const Sash: u8 = 31;

    // Cloth Foot (32-36)
    pub const DivineSlippers: u8 = 32;
    pub const SilkSlippers: u8 = 33;
    pub const WoolShoes: u8 = 34;
    pub const LinenShoes: u8 = 35;
    pub const Shoes: u8 = 36;

    // Cloth Hand (37-41)
    pub const DivineGloves: u8 = 37;
    pub const SilkGloves: u8 = 38;
    pub const WoolGloves: u8 = 39;
    pub const LinenGloves: u8 = 40;
    pub const Gloves: u8 = 41;

    // Blade Weapons (42-46)
    pub const Katana: u8 = 42;
    pub const Falchion: u8 = 43;
    pub const Scimitar: u8 = 44;
    pub const LongSword: u8 = 45;
    pub const ShortSword: u8 = 46;

    // Hide Chest (47-51)
    pub const DemonHusk: u8 = 47;
    pub const DragonskinArmor: u8 = 48;
    pub const StuddedLeatherArmor: u8 = 49;
    pub const HardLeatherArmor: u8 = 50;
    pub const LeatherArmor: u8 = 51;

    // Hide Head (52-56)
    pub const DemonCrown: u8 = 52;
    pub const DragonsCrown: u8 = 53;
    pub const WarCap: u8 = 54;
    pub const LeatherCap: u8 = 55;
    pub const Cap: u8 = 56;

    // Hide Waist (57-61)
    pub const DemonhideBelt: u8 = 57;
    pub const DragonskinBelt: u8 = 58;
    pub const StuddedLeatherBelt: u8 = 59;
    pub const HardLeatherBelt: u8 = 60;
    pub const LeatherBelt: u8 = 61;

    // Hide Foot (62-66)
    pub const DemonhideBoots: u8 = 62;
    pub const DragonskinBoots: u8 = 63;
    pub const StuddedLeatherBoots: u8 = 64;
    pub const HardLeatherBoots: u8 = 65;
    pub const LeatherBoots: u8 = 66;

    // Hide Hand (67-71)
    pub const DemonsHands: u8 = 67;
    pub const DragonskinGloves: u8 = 68;
    pub const StuddedLeatherGloves: u8 = 69;
    pub const HardLeatherGloves: u8 = 70;
    pub const LeatherGloves: u8 = 71;

    // Bludgeon Weapons (72-76)
    pub const Warhammer: u8 = 72;
    pub const Quarterstaff: u8 = 73;
    pub const Maul: u8 = 74;
    pub const Mace: u8 = 75;
    pub const Club: u8 = 76;

    // Metal Chest (77-81)
    pub const HolyChestplate: u8 = 77;
    pub const OrnateChestplate: u8 = 78;
    pub const PlateMail: u8 = 79;
    pub const ChainMail: u8 = 80;
    pub const RingMail: u8 = 81;

    // Metal Head (82-86)
    pub const AncientHelm: u8 = 82;
    pub const OrnateHelm: u8 = 83;
    pub const GreatHelm: u8 = 84;
    pub const FullHelm: u8 = 85;
    pub const Helm: u8 = 86;

    // Metal Waist (87-91)
    pub const OrnateBelt: u8 = 87;
    pub const WarBelt: u8 = 88;
    pub const PlatedBelt: u8 = 89;
    pub const MeshBelt: u8 = 90;
    pub const HeavyBelt: u8 = 91;

    // Metal Foot (92-96)
    pub const HolyGreaves: u8 = 92;
    pub const OrnateGreaves: u8 = 93;
    pub const Greaves: u8 = 94;
    pub const ChainBoots: u8 = 95;
    pub const HeavyBoots: u8 = 96;

    // Metal Hand (97-101)
    pub const HolyGauntlets: u8 = 97;
    pub const OrnateGauntlets: u8 = 98;
    pub const Gauntlets: u8 = 99;
    pub const ChainGloves: u8 = 100;
    pub const HeavyGloves: u8 = 101;
}

// Item Suffix IDs (1-16)
pub mod ItemSuffix {
    pub const of_Power: u8 = 1;
    pub const of_Giants: u8 = 2;
    pub const of_Titans: u8 = 3;
    pub const of_Skill: u8 = 4;
    pub const of_Perfection: u8 = 5;
    pub const of_Brilliance: u8 = 6;
    pub const of_Enlightenment: u8 = 7;
    pub const of_Protection: u8 = 8;
    pub const of_Anger: u8 = 9;
    pub const of_Rage: u8 = 10;
    pub const of_Fury: u8 = 11;
    pub const of_Vitriol: u8 = 12;
    pub const of_the_Fox: u8 = 13;
    pub const of_Detection: u8 = 14;
    pub const of_Reflection: u8 = 15;
    pub const of_the_Twins: u8 = 16;
}

// Name Prefix IDs (1-69)
pub mod ItemNamePrefix {
    pub const Agony: u8 = 1;
    pub const Apocalypse: u8 = 2;
    pub const Armageddon: u8 = 3;
    pub const Beast: u8 = 4;
    pub const Behemoth: u8 = 5;
    pub const Blight: u8 = 6;
    pub const Blood: u8 = 7;
    pub const Bramble: u8 = 8;
    pub const Brimstone: u8 = 9;
    pub const Brood: u8 = 10;
    pub const Carrion: u8 = 11;
    pub const Cataclysm: u8 = 12;
    pub const Chimeric: u8 = 13;
    pub const Corpse: u8 = 14;
    pub const Corruption: u8 = 15;
    pub const Damnation: u8 = 16;
    pub const Death: u8 = 17;
    pub const Demon: u8 = 18;
    pub const Dire: u8 = 19;
    pub const Dragon: u8 = 20;
    pub const Dread: u8 = 21;
    pub const Doom: u8 = 22;
    pub const Dusk: u8 = 23;
    pub const Eagle: u8 = 24;
    pub const Empyrean: u8 = 25;
    pub const Fate: u8 = 26;
    pub const Foe: u8 = 27;
    pub const Gale: u8 = 28;
    pub const Ghoul: u8 = 29;
    pub const Gloom: u8 = 30;
    pub const Glyph: u8 = 31;
    pub const Golem: u8 = 32;
    pub const Grim: u8 = 33;
    pub const Hate: u8 = 34;
    pub const Havoc: u8 = 35;
    pub const Honour: u8 = 36;
    pub const Horror: u8 = 37;
    pub const Hypnotic: u8 = 38;
    pub const Kraken: u8 = 39;
    pub const Loath: u8 = 40;
    pub const Maelstrom: u8 = 41;
    pub const Mind: u8 = 42;
    pub const Miracle: u8 = 43;
    pub const Morbid: u8 = 44;
    pub const Oblivion: u8 = 45;
    pub const Onslaught: u8 = 46;
    pub const Pain: u8 = 47;
    pub const Pandemonium: u8 = 48;
    pub const Phoenix: u8 = 49;
    pub const Plague: u8 = 50;
    pub const Rage: u8 = 51;
    pub const Rapture: u8 = 52;
    pub const Rune: u8 = 53;
    pub const Skull: u8 = 54;
    pub const Sol: u8 = 55;
    pub const Soul: u8 = 56;
    pub const Sorrow: u8 = 57;
    pub const Spirit: u8 = 58;
    pub const Storm: u8 = 59;
    pub const Tempest: u8 = 60;
    pub const Torment: u8 = 61;
    pub const Vengeance: u8 = 62;
    pub const Victory: u8 = 63;
    pub const Viper: u8 = 64;
    pub const Vortex: u8 = 65;
    pub const Woe: u8 = 66;
    pub const Wrath: u8 = 67;
    pub const Lights: u8 = 68;
    pub const Shimmering: u8 = 69;
}

// Name Suffix IDs (1-18)
pub mod ItemNameSuffix {
    pub const Bane: u8 = 1;
    pub const Root: u8 = 2;
    pub const Bite: u8 = 3;
    pub const Song: u8 = 4;
    pub const Roar: u8 = 5;
    pub const Grasp: u8 = 6;
    pub const Instrument: u8 = 7;
    pub const Glow: u8 = 8;
    pub const Bender: u8 = 9;
    pub const Shadow: u8 = 10;
    pub const Whisper: u8 = 11;
    pub const Shout: u8 = 12;
    pub const Growl: u8 = 13;
    pub const Tear: u8 = 14;
    pub const Peak: u8 = 15;
    pub const Form: u8 = 16;
    pub const Sun: u8 = 17;
    pub const Moon: u8 = 18;
}
