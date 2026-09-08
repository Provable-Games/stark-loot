// Combat-related enums for Loot items
// Adapted from death-mountain loot package

#[derive(Copy, Drop, PartialEq, Serde)]
pub enum Type {
    Magic_or_Cloth,
    Blade_or_Hide,
    Bludgeon_or_Metal,
}

#[derive(Copy, Drop, PartialEq, Serde)]
pub enum Tier {
    T1,
    T2,
    T3,
    T4,
    T5,
}

#[derive(Copy, Drop, PartialEq, Serde)]
pub enum Slot {
    Weapon,
    Chest,
    Head,
    Waist,
    Foot,
    Hand,
    Neck,
    Ring,
}
