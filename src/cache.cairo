//! Permissionless canonical cache, storage layout v1: one existing PackedLootBag per u64 ID.
use crate::core::{LootBag, LootBagNames, LootItem};
use crate::packed::PackedLootBag;
use crate::types::Slot;

#[starknet::interface]
pub trait IStarkLootCache<TContractState> {
    /// Canonical, caller-funded insertion. A hit returns unchanged without write or event.
    fn add_to_cache(ref self: TContractState, bag_id: u64) -> PackedLootBag;
    fn is_cached(self: @TContractState, bag_id: u64) -> bool;
    /// Exactly one read; missing entries panic with "bag not cached" and never generate.
    fn get_cached_packed_bag(self: @TContractState, bag_id: u64) -> PackedLootBag;
    fn get_cached_bag(self: @TContractState, bag_id: u64) -> LootBag;
    fn get_cached_item(self: @TContractState, bag_id: u64, slot: Slot) -> LootItem;
    fn get_cached_bag_names(self: @TContractState, bag_id: u64) -> LootBagNames;
}

#[starknet::contract]
pub mod stark_loot_cache {
    use core::byte_array::ByteArray;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use crate::contract::IStarkLoot;
    use crate::contract::stark_loot::VERSION;
    use crate::core as loot_core;
    use crate::core::{LootBag, LootBagNames, LootItem, get_packed_loot_bag};
    use crate::packed::{PackedLootBag, PackedLootBagTrait};
    use crate::types::{Slot, Tier, Type};
    use super::IStarkLootCache;

    #[storage]
    struct Storage {
        // No presence flag or per-entry version. Zero is the miss sentinel.
        bags: Map<u64, PackedLootBag>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        BagCached: BagCached,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BagCached {
        #[key]
        pub bag_id: u64,
    }

    #[abi(embed_v0)]
    impl CacheImpl of IStarkLootCache<ContractState> {
        fn add_to_cache(ref self: ContractState, bag_id: u64) -> PackedLootBag {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                return packed;
            }
            let packed = get_packed_loot_bag(bag_id);
            // For every u64 seed, the low weapon ID is positive. Checked item words are
            // nonnegative and the exact-felt sum is below 2^250 < P, so it cannot be zero.
            // Only this canonical generator writes storage; the public packer's wider
            // domain still permits zero-filled arbitrary bags.
            assert!(packed.value != 0, "zero generated bag");
            self.bags.write(bag_id, packed);
            self.emit(BagCached { bag_id });
            packed
        }

        fn is_cached(self: @ContractState, bag_id: u64) -> bool {
            self.bags.read(bag_id).value != 0
        }

        fn get_cached_packed_bag(self: @ContractState, bag_id: u64) -> PackedLootBag {
            let packed = self.bags.read(bag_id);
            assert!(packed.value != 0, "bag not cached");
            packed
        }
        fn get_cached_bag(self: @ContractState, bag_id: u64) -> LootBag {
            self.get_cached_packed_bag(bag_id).unpack()
        }

        fn get_cached_item(self: @ContractState, bag_id: u64, slot: Slot) -> LootItem {
            self.get_cached_packed_bag(bag_id).get_item(slot)
        }

        fn get_cached_bag_names(self: @ContractState, bag_id: u64) -> LootBagNames {
            cached_names(self.get_cached_packed_bag(bag_id))
        }
    }
    #[abi(embed_v0)]
    impl StarkLootImpl of IStarkLoot<ContractState> {
        fn get_bag(self: @ContractState, bag_id: u64) -> LootBag {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.unpack()
            } else {
                loot_core::get_loot_bag(bag_id)
            }
        }

        fn get_packed_bag(self: @ContractState, bag_id: u64) -> PackedLootBag {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed
            } else {
                loot_core::get_packed_loot_bag(bag_id)
            }
        }

        fn get_bag_names(self: @ContractState, bag_id: u64) -> LootBagNames {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                cached_names(packed)
            } else {
                loot_core::get_loot_bag_names(bag_id)
            }
        }

        fn get_weapon_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.weapon_or_generate(bag_id)
        }

        fn get_chest_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.chest_or_generate(bag_id)
        }

        fn get_head_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.head_or_generate(bag_id)
        }

        fn get_waist_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.waist_or_generate(bag_id)
        }

        fn get_foot_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.foot_or_generate(bag_id)
        }

        fn get_hand_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.hand_or_generate(bag_id)
        }

        fn get_neck_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.neck_or_generate(bag_id)
        }

        fn get_ring_item(self: @ContractState, bag_id: u64) -> LootItem {
            self.ring_or_generate(bag_id)
        }

        fn get_weapon_id(self: @ContractState, bag_id: u64) -> u8 {
            self.weapon_or_generate(bag_id).id
        }

        fn get_chest_id(self: @ContractState, bag_id: u64) -> u8 {
            self.chest_or_generate(bag_id).id
        }

        fn get_head_id(self: @ContractState, bag_id: u64) -> u8 {
            self.head_or_generate(bag_id).id
        }

        fn get_waist_id(self: @ContractState, bag_id: u64) -> u8 {
            self.waist_or_generate(bag_id).id
        }

        fn get_foot_id(self: @ContractState, bag_id: u64) -> u8 {
            self.foot_or_generate(bag_id).id
        }

        fn get_hand_id(self: @ContractState, bag_id: u64) -> u8 {
            self.hand_or_generate(bag_id).id
        }

        fn get_neck_id(self: @ContractState, bag_id: u64) -> u8 {
            self.neck_or_generate(bag_id).id
        }

        fn get_ring_id(self: @ContractState, bag_id: u64) -> u8 {
            self.ring_or_generate(bag_id).id
        }

        fn get_weapon_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.weapon_or_generate(bag_id))
        }

        fn get_chest_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.chest_or_generate(bag_id))
        }

        fn get_head_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.head_or_generate(bag_id))
        }

        fn get_waist_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.waist_or_generate(bag_id))
        }

        fn get_foot_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.foot_or_generate(bag_id))
        }

        fn get_hand_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.hand_or_generate(bag_id))
        }

        fn get_neck_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.neck_or_generate(bag_id))
        }

        fn get_ring_name(self: @ContractState, bag_id: u64) -> ByteArray {
            loot_core::render_item_name(self.ring_or_generate(bag_id))
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
            self.weapon_or_generate(bag_id).greatness
        }

        fn get_chest_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.chest_or_generate(bag_id).greatness
        }

        fn get_head_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.head_or_generate(bag_id).greatness
        }

        fn get_waist_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.waist_or_generate(bag_id).greatness
        }

        fn get_foot_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.foot_or_generate(bag_id).greatness
        }

        fn get_hand_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.hand_or_generate(bag_id).greatness
        }

        fn get_neck_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.neck_or_generate(bag_id).greatness
        }

        fn get_ring_greatness(self: @ContractState, bag_id: u64) -> u8 {
            self.ring_or_generate(bag_id).greatness
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn weapon_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Weapon)
            } else {
                loot_core::get_weapon_item(bag_id)
            }
        }
        fn chest_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Chest)
            } else {
                loot_core::get_chest_item(bag_id)
            }
        }
        fn head_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Head)
            } else {
                loot_core::get_head_item(bag_id)
            }
        }
        fn waist_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Waist)
            } else {
                loot_core::get_waist_item(bag_id)
            }
        }
        fn foot_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Foot)
            } else {
                loot_core::get_foot_item(bag_id)
            }
        }
        fn hand_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Hand)
            } else {
                loot_core::get_hand_item(bag_id)
            }
        }
        fn neck_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Neck)
            } else {
                loot_core::get_neck_item(bag_id)
            }
        }
        fn ring_or_generate(self: @ContractState, bag_id: u64) -> LootItem {
            let packed = self.bags.read(bag_id);
            if packed.value != 0 {
                packed.get_item(Slot::Ring)
            } else {
                loot_core::get_ring_item(bag_id)
            }
        }
    }
    // Share the large name renderer between strict and compatibility entrypoints.
    #[inline(never)]
    fn cached_names(packed: PackedLootBag) -> LootBagNames {
        loot_core::render_bag_names(packed.unpack())
    }
}
