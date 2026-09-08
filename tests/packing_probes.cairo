//! Single-entrypoint test-only probes. Read the contract/selector gas row, never test totals.
//! Inputs, declarations, oracle calculations, and assertions remain in the test body.
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use stark_loot::core::{LootBag, LootItem};
use stark_loot::packed::PackedLootBag;
use stark_loot::types::Slot;
use starknet::ClassHash;
use super::packing_oracle::{GOLDEN, PAYLOAD_MASK, oracle_unpack};

#[starknet::interface]
pub trait IPackProbe<TState> {
    fn run(self: @TState, bag: LootBag) -> felt252;
}

#[starknet::interface]
pub trait IUnpackProbe<TState> {
    fn run(self: @TState, value: felt252) -> LootBag;
}

#[starknet::interface]
pub trait IItemProbe<TState> {
    fn run(self: @TState, value: felt252, slot: Slot) -> LootItem;
}

#[starknet::interface]
pub trait INativeProbe<TState> {
    fn run(self: @TState, loot_class: ClassHash, bag_id: u64) -> LootBag;
}

#[starknet::interface]
pub trait IPackedProbe<TState> {
    fn run(self: @TState, loot_class: ClassHash, bag_id: u64) -> PackedLootBag;
}

#[starknet::interface]
pub trait ILibraryItemProbe<TState> {
    fn run(self: @TState, loot_class: ClassHash, bag_id: u64, slot: Slot) -> LootItem;
}

fn select_item(bag: LootBag, slot: Slot) -> LootItem {
    match slot {
        Slot::Weapon => bag.weapon,
        Slot::Chest => bag.chest,
        Slot::Head => bag.head,
        Slot::Waist => bag.waist,
        Slot::Foot => bag.foot,
        Slot::Hand => bag.hand,
        Slot::Neck => bag.neck,
        Slot::Ring => bag.ring,
    }
}

#[starknet::contract]
mod PackProbe {
    use stark_loot::packed::LootBagPackingTrait;
    use super::{IPackProbe, LootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IPackProbe<ContractState> {
        fn run(self: @ContractState, bag: LootBag) -> felt252 {
            bag.pack().value
        }
    }
}

#[starknet::contract]
mod U256PackProbe {
    use super::{IPackProbe, LootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IPackProbe<ContractState> {
        fn run(self: @ContractState, bag: LootBag) -> felt252 {
            super::super::packing_oracle::oracle_pack(bag)
        }
    }
}

#[starknet::contract]
mod UnpackProbe {
    use stark_loot::packed::PackedLootBagTrait;
    use super::{IUnpackProbe, LootBag, PackedLootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IUnpackProbe<ContractState> {
        fn run(self: @ContractState, value: felt252) -> LootBag {
            (PackedLootBag { value }).unpack()
        }
    }
}

#[starknet::contract]
mod U256UnpackProbe {
    use super::{IUnpackProbe, LootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IUnpackProbe<ContractState> {
        fn run(self: @ContractState, value: felt252) -> LootBag {
            super::super::packing_oracle::oracle_unpack(value).unwrap()
        }
    }
}

#[starknet::contract]
mod ItemProbe {
    use stark_loot::packed::PackedLootBagTrait;
    use super::{IItemProbe, LootItem, PackedLootBag, Slot};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IItemProbe<ContractState> {
        fn run(self: @ContractState, value: felt252, slot: Slot) -> LootItem {
            (PackedLootBag { value }).get_item(slot)
        }
    }
}

#[starknet::contract]
mod FullItemProbe {
    use stark_loot::packed::PackedLootBagTrait;
    use super::{IItemProbe, LootItem, PackedLootBag, Slot};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IItemProbe<ContractState> {
        fn run(self: @ContractState, value: felt252, slot: Slot) -> LootItem {
            super::select_item((PackedLootBag { value }).unpack(), slot)
        }
    }
}

#[starknet::contract]
mod NativeLibraryProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::{ClassHash, INativeProbe, LootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of INativeProbe<ContractState> {
        fn run(self: @ContractState, loot_class: ClassHash, bag_id: u64) -> LootBag {
            IStarkLootLibraryDispatcher { class_hash: loot_class }.get_bag(bag_id)
        }
    }
}

#[starknet::contract]
mod PackedLibraryProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::{ClassHash, IPackedProbe, PackedLootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of IPackedProbe<ContractState> {
        fn run(self: @ContractState, loot_class: ClassHash, bag_id: u64) -> PackedLootBag {
            IStarkLootLibraryDispatcher { class_hash: loot_class }.get_packed_bag(bag_id)
        }
    }
}

#[starknet::contract]
mod MaterializedLibraryProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use stark_loot::packed::PackedLootBagTrait;
    use super::{ClassHash, INativeProbe, LootBag};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of INativeProbe<ContractState> {
        fn run(self: @ContractState, loot_class: ClassHash, bag_id: u64) -> LootBag {
            IStarkLootLibraryDispatcher { class_hash: loot_class }.get_packed_bag(bag_id).unpack()
        }
    }
}

#[starknet::contract]
mod NativeItemLibraryProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::{ClassHash, ILibraryItemProbe, LootItem, Slot};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of ILibraryItemProbe<ContractState> {
        fn run(self: @ContractState, loot_class: ClassHash, bag_id: u64, slot: Slot) -> LootItem {
            super::select_item(
                IStarkLootLibraryDispatcher { class_hash: loot_class }.get_bag(bag_id), slot,
            )
        }
    }
}

#[starknet::contract]
mod PackedItemLibraryProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use stark_loot::packed::PackedLootBagTrait;
    use super::{ClassHash, ILibraryItemProbe, LootItem, Slot};
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Probe of ILibraryItemProbe<ContractState> {
        fn run(self: @ContractState, loot_class: ClassHash, bag_id: u64, slot: Slot) -> LootItem {
            IStarkLootLibraryDispatcher { class_hash: loot_class }
                .get_packed_bag(bag_id)
                .get_item(slot)
        }
    }
}

#[test]
fn gas_probe_pack_golden() {
    let value: felt252 = GOLDEN;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_pack_u256_golden() {
    let value: felt252 = GOLDEN;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_unpack_golden() {
    let value: felt252 = GOLDEN;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_unpack_u256_golden() {
    let value: felt252 = GOLDEN;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_pack_zero() {
    let value: felt252 = 0;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_pack_u256_zero() {
    let value: felt252 = 0;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_unpack_zero() {
    let value: felt252 = 0;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_unpack_u256_zero() {
    let value: felt252 = 0;
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_pack_maximum() {
    let value: felt252 = PAYLOAD_MASK.try_into().unwrap();
    let bag = oracle_unpack(value).unwrap();
    let class = declare("PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_pack_u256_maximum() {
    let value: felt252 = PAYLOAD_MASK.try_into().unwrap();
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256PackProbe").unwrap().contract_class();
    let probe = IPackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(bag);
    assert!(actual == value);
}

#[test]
fn gas_probe_unpack_maximum() {
    let value: felt252 = PAYLOAD_MASK.try_into().unwrap();
    let bag = oracle_unpack(value).unwrap();
    let class = declare("UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_unpack_u256_maximum() {
    let value: felt252 = PAYLOAD_MASK.try_into().unwrap();
    let bag = oracle_unpack(value).unwrap();
    let class = declare("U256UnpackProbe").unwrap().contract_class();
    let probe = IUnpackProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(value);
    assert!(actual == bag);
}

#[test]
fn gas_probe_item_weapon() {
    let bag = oracle_unpack(GOLDEN).unwrap();
    let class = declare("ItemProbe").unwrap().contract_class();
    let probe = IItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(GOLDEN, Slot::Weapon);
    assert!(actual == bag.weapon);
}

#[test]
fn gas_probe_full_item_weapon() {
    let bag = oracle_unpack(GOLDEN).unwrap();
    let class = declare("FullItemProbe").unwrap().contract_class();
    let probe = IItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(GOLDEN, Slot::Weapon);
    assert!(actual == bag.weapon);
}

#[test]
fn gas_probe_item_ring() {
    let bag = oracle_unpack(GOLDEN).unwrap();
    let class = declare("ItemProbe").unwrap().contract_class();
    let probe = IItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(GOLDEN, Slot::Ring);
    assert!(actual == bag.ring);
}

#[test]
fn gas_probe_full_item_ring() {
    let bag = oracle_unpack(GOLDEN).unwrap();
    let class = declare("FullItemProbe").unwrap().contract_class();
    let probe = IItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(GOLDEN, Slot::Ring);
    assert!(actual == bag.ring);
}

#[test]
fn gas_probe_native_library_one() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 1;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("NativeLibraryProbe").unwrap().contract_class();
    let probe = INativeProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == expected);
}

#[test]
fn gas_probe_packed_library_one() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 1;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("PackedLibraryProbe").unwrap().contract_class();
    let probe = IPackedProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == PackedLootBag { value: super::packing_oracle::oracle_pack(expected) });
}

#[test]
fn gas_probe_materialized_library_one() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 1;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("MaterializedLibraryProbe").unwrap().contract_class();
    let probe = INativeProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == expected);
}

#[test]
fn gas_probe_native_library_max_id() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 0xffffffffffffffff;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("NativeLibraryProbe").unwrap().contract_class();
    let probe = INativeProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == expected);
}

#[test]
fn gas_probe_packed_library_max_id() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 0xffffffffffffffff;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("PackedLibraryProbe").unwrap().contract_class();
    let probe = IPackedProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == PackedLootBag { value: super::packing_oracle::oracle_pack(expected) });
}

#[test]
fn gas_probe_materialized_library_max_id() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let bag_id: u64 = 0xffffffffffffffff;
    let expected = stark_loot::core::get_loot_bag(bag_id);
    let class = declare("MaterializedLibraryProbe").unwrap().contract_class();
    let probe = INativeProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, bag_id);
    assert!(actual == expected);
}

#[test]
fn gas_probe_native_library_item_weapon() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let expected = stark_loot::core::get_loot_bag(1);
    let class = declare("NativeItemLibraryProbe").unwrap().contract_class();
    let probe = ILibraryItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, 1, Slot::Weapon);
    assert!(actual == expected.weapon);
}

#[test]
fn gas_probe_packed_library_item_weapon() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let expected = stark_loot::core::get_loot_bag(1);
    let class = declare("PackedItemLibraryProbe").unwrap().contract_class();
    let probe = ILibraryItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, 1, Slot::Weapon);
    assert!(actual == expected.weapon);
}

#[test]
fn gas_probe_native_library_item_ring() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let expected = stark_loot::core::get_loot_bag(1);
    let class = declare("NativeItemLibraryProbe").unwrap().contract_class();
    let probe = ILibraryItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, 1, Slot::Ring);
    assert!(actual == expected.ring);
}

#[test]
fn gas_probe_packed_library_item_ring() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let expected = stark_loot::core::get_loot_bag(1);
    let class = declare("PackedItemLibraryProbe").unwrap().contract_class();
    let probe = ILibraryItemProbeLibraryDispatcher { class_hash: *class.class_hash };
    let actual = probe.run(*loot.class_hash, 1, Slot::Ring);
    assert!(actual == expected.ring);
}
