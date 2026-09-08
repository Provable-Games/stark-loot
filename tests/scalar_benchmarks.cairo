// Single-operation library caller probes. Assertions stay outside the measured call.
// Bag 1 goldens are in loot_reference.cairo; maximum-ID ring goldens come from
// scripts/loot.py LootGenerator._pluck(2**64 - 1, "RING", RINGS, RING_ID_MAP).
use snforge_std::{DeclareResultTrait, declare};

#[starknet::interface]
trait IIdProbe<TContractState> {
    fn run(self: @TContractState, loot: starknet::ClassHash, bag_id: u64) -> u8;
}
#[starknet::contract]
mod IdProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::IIdProbe;
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Impl of IIdProbe<ContractState> {
        fn run(self: @ContractState, loot: starknet::ClassHash, bag_id: u64) -> u8 {
            IStarkLootLibraryDispatcher { class_hash: loot }.get_weapon_id(bag_id)
        }
    }
}
#[test]
fn gas_probe_id() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let class = declare("IdProbe").unwrap().contract_class();
    let probe = IIdProbeLibraryDispatcher { class_hash: *class.class_hash };
    assert!(probe.run(*loot.class_hash, 1) == 10, "scalar value mismatch");
}

#[starknet::interface]
trait IGreatnessProbe<TContractState> {
    fn run(self: @TContractState, loot: starknet::ClassHash, bag_id: u64) -> u8;
}
#[starknet::contract]
mod GreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::IGreatnessProbe;
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Impl of IGreatnessProbe<ContractState> {
        fn run(self: @ContractState, loot: starknet::ClassHash, bag_id: u64) -> u8 {
            IStarkLootLibraryDispatcher { class_hash: loot }.get_weapon_greatness(bag_id)
        }
    }
}
#[test]
fn gas_probe_greatness() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let class = declare("GreatnessProbe").unwrap().contract_class();
    let probe = IGreatnessProbeLibraryDispatcher { class_hash: *class.class_hash };
    assert!(probe.run(*loot.class_hash, 1) == 20, "scalar value mismatch");
}

#[starknet::interface]
trait IRingIdProbe<TContractState> {
    fn run(self: @TContractState, loot: starknet::ClassHash, bag_id: u64) -> u8;
}
#[starknet::contract]
mod RingIdProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::IRingIdProbe;
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Impl of IRingIdProbe<ContractState> {
        fn run(self: @ContractState, loot: starknet::ClassHash, bag_id: u64) -> u8 {
            IStarkLootLibraryDispatcher { class_hash: loot }.get_ring_id(bag_id)
        }
    }
}
#[test]
fn gas_probe_ring_id_max() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let class = declare("RingIdProbe").unwrap().contract_class();
    let probe = IRingIdProbeLibraryDispatcher { class_hash: *class.class_hash };
    assert!(probe.run(*loot.class_hash, 0xffffffffffffffff) == 8, "scalar value mismatch");
}

#[starknet::interface]
trait IRingGreatnessProbe<TContractState> {
    fn run(self: @TContractState, loot: starknet::ClassHash, bag_id: u64) -> u8;
}
#[starknet::contract]
mod RingGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use super::IRingGreatnessProbe;
    #[storage]
    struct Storage {}
    #[abi(embed_v0)]
    impl Impl of IRingGreatnessProbe<ContractState> {
        fn run(self: @ContractState, loot: starknet::ClassHash, bag_id: u64) -> u8 {
            IStarkLootLibraryDispatcher { class_hash: loot }.get_ring_greatness(bag_id)
        }
    }
}
#[test]
fn gas_probe_ring_greatness_max() {
    let loot = declare("stark_loot").unwrap().contract_class();
    let class = declare("RingGreatnessProbe").unwrap().contract_class();
    let probe = IRingGreatnessProbeLibraryDispatcher { class_hash: *class.class_hash };
    assert!(probe.run(*loot.class_hash, 0xffffffffffffffff) == 12, "scalar value mismatch");
}
