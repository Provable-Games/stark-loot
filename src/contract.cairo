use core::byte_array::ByteArray;
use crate::core::{LootBag, LootBagNames, LootItem};
use crate::packed::PackedLootBag;
use crate::types::{Slot, Tier, Type};

#[starknet::interface]
pub trait IStarkLoot<TContractState> {
    fn get_bag(self: @TContractState, bag_id: u64) -> LootBag;
    fn get_bag_names(self: @TContractState, bag_id: u64) -> LootBagNames;
    fn get_packed_bag(self: @TContractState, bag_id: u64) -> PackedLootBag;

    fn get_weapon_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_chest_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_head_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_waist_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_foot_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_hand_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_neck_item(self: @TContractState, bag_id: u64) -> LootItem;
    fn get_ring_item(self: @TContractState, bag_id: u64) -> LootItem;

    fn get_weapon_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_chest_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_head_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_waist_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_foot_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_hand_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_neck_id(self: @TContractState, bag_id: u64) -> u8;
    fn get_ring_id(self: @TContractState, bag_id: u64) -> u8;

    fn get_weapon_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_chest_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_head_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_waist_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_foot_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_hand_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_neck_name(self: @TContractState, bag_id: u64) -> ByteArray;
    fn get_ring_name(self: @TContractState, bag_id: u64) -> ByteArray;

    // Consolidated name lookup (replaces 8 slot-specific _by_id functions)
    fn get_item_name(self: @TContractState, item_id: u8) -> ByteArray;

    fn get_suffix_name_by_id(
        self: @TContractState, suffix_id: u8,
    ) -> ByteArray; // {Of Skill, of Giants, of Titans}
    fn get_name_prefix_by_id(
        self: @TContractState, name_prefix_id: u8,
    ) -> ByteArray; // {Agony, Grim, Viper, Vortex}
    fn get_name_suffix_by_id(
        self: @TContractState, name_suffix_id: u8,
    ) -> ByteArray; // {Bane, Root, Bite, Song, Roar}

    // Individual greatness getters
    fn get_weapon_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_chest_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_head_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_waist_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_foot_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_hand_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_neck_greatness(self: @TContractState, bag_id: u64) -> u8;
    fn get_ring_greatness(self: @TContractState, bag_id: u64) -> u8;

    // Type, Tier, and Slot lookups
    fn get_item_type(self: @TContractState, item_id: u8) -> Type;
    fn get_item_tier(self: @TContractState, item_id: u8) -> Tier;
    fn get_item_slot(self: @TContractState, item_id: u8) -> Slot;

    /// Package release version, shared by the stateless and cache classes.
    /// This does not identify or authenticate a class or its storage context.
    /// Pin the stateless class hash for library calls; use the cache's deployed
    /// address with a contract dispatcher. See README.md, "Shared storage cache".
    fn get_version(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod stark_loot {
    use core::byte_array::ByteArray;
    use crate::core as loot_core;
    use crate::core::{LootBag, LootBagNames, LootItem};
    use crate::packed::PackedLootBag;
    use crate::types::{Slot, Tier, Type};
    use super::IStarkLoot;

    /// Keep in step with `version` in Scarb.toml.
    pub const VERSION: felt252 = '0.3.0';

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl StarkLootImpl of IStarkLoot<ContractState> {
        fn get_bag(self: @ContractState, bag_id: u64) -> LootBag {
            loot_core::get_loot_bag(bag_id)
        }

        fn get_packed_bag(self: @ContractState, bag_id: u64) -> PackedLootBag {
            loot_core::get_packed_loot_bag(bag_id)
        }

        fn get_bag_names(self: @ContractState, bag_id: u64) -> LootBagNames {
            loot_core::get_loot_bag_names(bag_id)
        }

        fn get_weapon_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_weapon_item(bag_id)
        }

        fn get_chest_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_chest_item(bag_id)
        }

        fn get_head_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_head_item(bag_id)
        }

        fn get_waist_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_waist_item(bag_id)
        }

        fn get_foot_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_foot_item(bag_id)
        }

        fn get_hand_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_hand_item(bag_id)
        }

        fn get_neck_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_neck_item(bag_id)
        }

        fn get_ring_item(self: @ContractState, bag_id: u64) -> LootItem {
            loot_core::get_ring_item(bag_id)
        }

        fn get_weapon_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_weapon_item(bag_id).id
        }

        fn get_chest_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_chest_item(bag_id).id
        }

        fn get_head_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_head_item(bag_id).id
        }

        fn get_waist_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_waist_item(bag_id).id
        }

        fn get_foot_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_foot_item(bag_id).id
        }

        fn get_hand_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_hand_item(bag_id).id
        }

        fn get_neck_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_neck_item(bag_id).id
        }

        fn get_ring_id(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_ring_item(bag_id).id
        }

        fn get_weapon_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_weapon_name(bag_id)
        }

        fn get_chest_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_chest_name(bag_id)
        }

        fn get_head_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_head_name(bag_id)
        }

        fn get_waist_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_waist_name(bag_id)
        }

        fn get_foot_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_foot_name(bag_id)
        }

        fn get_hand_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_hand_name(bag_id)
        }

        fn get_neck_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_neck_name(bag_id)
        }

        fn get_ring_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::get_ring_name(bag_id)
        }

        fn get_item_name(self: @ContractState, item_id: u8) -> ByteArray {
            loot_core::get_item_name(item_id)
        }

        fn get_suffix_name_by_id(self: @ContractState, suffix_id: u8) -> ByteArray {
            loot_core::suffix_name_by_id(suffix_id)
        }

        fn get_name_prefix_by_id(self: @ContractState, name_prefix_id: u8) -> ByteArray {
            loot_core::name_prefix_by_id(name_prefix_id)
        }

        fn get_name_suffix_by_id(self: @ContractState, name_suffix_id: u8) -> ByteArray {
            loot_core::name_suffix_by_id(name_suffix_id)
        }

        fn get_weapon_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_weapon_item(bag_id).greatness
        }

        fn get_chest_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_chest_item(bag_id).greatness
        }

        fn get_head_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_head_item(bag_id).greatness
        }

        fn get_waist_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_waist_item(bag_id).greatness
        }

        fn get_foot_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_foot_item(bag_id).greatness
        }

        fn get_hand_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_hand_item(bag_id).greatness
        }

        fn get_neck_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_neck_item(bag_id).greatness
        }

        fn get_ring_greatness(self: @ContractState, bag_id: u64) -> u8 {
            loot_core::get_ring_item(bag_id).greatness
        }
        fn get_item_type(self: @ContractState, item_id: u8) -> Type {
            loot_core::get_type(item_id)
        }

        fn get_item_tier(self: @ContractState, item_id: u8) -> Tier {
            loot_core::get_tier(item_id)
        }

        fn get_item_slot(self: @ContractState, item_id: u8) -> Slot {
            loot_core::get_slot(item_id)
        }

        fn get_version(self: @ContractState) -> felt252 {
            VERSION
        }
    }
}
