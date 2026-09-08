//! Single-operation address/class callers. Setup and expectations are outside run.
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use stark_loot::cache::IStarkLootCacheDispatcherTrait;
use stark_loot::core::{
    LootBag, LootBagNames, LootItem, get_loot_bag, get_loot_bag_names, get_packed_loot_bag,
};
use stark_loot::packed::PackedLootBag;
use crate::cache::cache;

#[starknet::interface]
pub trait ICacheProbe0<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> PackedLootBag;
}

#[starknet::contract]
mod CacheGetCachedPackedBagProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe0;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe0<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> PackedLootBag {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_packed_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_packed_bag_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheGetCachedPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_packed_bag_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheGetCachedPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe1<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> LootBag;
}

#[starknet::contract]
mod CacheGetCachedBagProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootBag;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe1;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe1<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootBag {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheGetCachedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheGetCachedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe2<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> LootBagNames;
}

#[starknet::contract]
mod CacheGetCachedBagNamesProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootBagNames;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe2;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe2<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootBagNames {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_bag_names(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_names_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheGetCachedBagNamesProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe2Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_names_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheGetCachedBagNamesProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe2Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe3<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> bool;
}

#[starknet::contract]
mod CacheIsCachedProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe3;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe3<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> bool {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .is_cached(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_is_cached_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheIsCachedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe3Dispatcher { contract_address: address };
    let expected = true;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_is_cached_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheIsCachedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe3Dispatcher { contract_address: address };
    let expected = true;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_is_cached_miss() {
    let cache = cache();

    let (address, _) = declare("CacheIsCachedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe3Dispatcher { contract_address: address };
    let expected = false;
    assert!(probe.run(cache.contract_address.into(), 0) == expected);
    assert!(crate::cache::storage_word(address, 0) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheAddToCacheProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe0;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe0<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> PackedLootBag {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .add_to_cache(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_add_to_cache_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheAddToCacheProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_add_to_cache_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheAddToCacheProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_insert_1() {
    let cache = cache();

    let (address, _) = declare("CacheAddToCacheProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_insert_8000() {
    let cache = cache();

    let (address, _) = declare("CacheAddToCacheProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe4<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> LootItem;
}

#[starknet::contract]
mod CacheSelectedWeaponProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_item(bag_id, Slot::Weapon)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_weapon_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheSelectedWeaponProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_weapon_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheSelectedWeaponProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).weapon;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheSelectedFootProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_item(bag_id, Slot::Foot)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_foot_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheSelectedFootProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_foot_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheSelectedFootProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).foot;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheSelectedRingProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_item(bag_id, Slot::Ring)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_ring_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheSelectedRingProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_selected_ring_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheSelectedRingProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).ring;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetBagProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootBag;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe1;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe1<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootBag {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }.get_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod UnchangedLibraryGetBagProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use stark_loot::core::LootBag;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe1;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe1<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootBag {
            IStarkLootLibraryDispatcher { class_hash: target.try_into().unwrap() }.get_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_library_1() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(1);
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_deployed_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(1);
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_library_8000() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000);
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_deployed_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe1Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000);
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetPackedBagProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe0;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe0<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> PackedLootBag {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_packed_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod UnchangedLibraryGetPackedBagProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe0;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe0<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> PackedLootBag {
            IStarkLootLibraryDispatcher { class_hash: target.try_into().unwrap() }
                .get_packed_bag(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_library_1() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_deployed_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(1);
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_library_8000() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_packed_bag_deployed_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe0Dispatcher { contract_address: address };
    let expected = get_packed_loot_bag(8000);
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetBagNamesProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootBagNames;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe2;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe2<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootBagNames {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_bag_names(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_bag_names_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetBagNamesProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe2Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1);
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWeaponItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_weapon_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).weapon;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod UnchangedLibraryGetWeaponItemProbe {
    use stark_loot::contract::{IStarkLootDispatcherTrait, IStarkLootLibraryDispatcher};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootLibraryDispatcher { class_hash: target.try_into().unwrap() }
                .get_weapon_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_library_1() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon;
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_deployed_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon;
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                1,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_library_8000() {
    let cache = cache();

    let (address, _) = declare("UnchangedLibraryGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).weapon;
    assert!(
        probe
            .run(
                (*declare("stark_loot").unwrap().contract_class().class_hash).into(), 8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_item_deployed_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).weapon;
    assert!(
        probe
            .run(
                Into::<
                    starknet::ContractAddress, felt252,
                >::into(
                    declare("stark_loot").unwrap().contract_class().deploy(@array![]).unwrap().0,
                ),
                8000,
            ) == expected,
    );
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe5<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> u8;
}

#[starknet::contract]
mod CacheCompatGetWeaponIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_weapon_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWeaponIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_id_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_id_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).weapon.id;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWeaponGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_weapon_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWeaponGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe6<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> ByteArray;
}

#[starknet::contract]
mod CacheCompatGetWeaponNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_weapon_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_name_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_weapon_name_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(8000).weapon;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetChestItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_chest_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_chest_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetChestItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).chest;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetChestIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_chest_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_chest_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetChestIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).chest.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetChestGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_chest_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_chest_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetChestGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).chest.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetChestNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_chest_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_chest_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetChestNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).chest;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHeadItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_head_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_head_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHeadItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).head;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHeadIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_head_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_head_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHeadIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).head.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHeadGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_head_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_head_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHeadGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).head.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHeadNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_head_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_head_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHeadNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).head;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWaistItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_waist_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_waist_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWaistItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).waist;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWaistIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_waist_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_waist_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWaistIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).waist.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWaistGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_waist_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_waist_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWaistGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).waist.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetWaistNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_waist_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_waist_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWaistNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).waist;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetFootItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_foot_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_foot_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetFootItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetFootIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_foot_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_foot_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetFootIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetFootGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_foot_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_foot_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetFootGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetFootNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_foot_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_foot_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetFootNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).foot;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHandItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_hand_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_hand_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHandItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).hand;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHandIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_hand_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_hand_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHandIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).hand.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHandGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_hand_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_hand_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHandGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).hand.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetHandNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_hand_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_hand_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetHandNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).hand;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetNeckItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_neck_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_neck_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetNeckItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).neck;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetNeckIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_neck_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_neck_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetNeckIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).neck.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetNeckGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_neck_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_neck_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetNeckGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).neck.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetNeckNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_neck_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_neck_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetNeckNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).neck;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetRingItemProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe4;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe4<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> LootItem {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_ring_item(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_item_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetRingItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe4Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetRingIdProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_ring_id(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_id_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetRingIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.id;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetRingGreatnessProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_ring_greatness(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_greatness_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetRingGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_greatness_miss_1() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetRingGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.greatness;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_greatness_miss_8000() {
    let cache = cache();

    let (address, _) = declare("CacheCompatGetRingGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(8000).ring.greatness;
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheCompatGetRingNameProbe {
    use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe6;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe6<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> ByteArray {
            IStarkLootDispatcher { contract_address: target.try_into().unwrap() }
                .get_ring_name(bag_id)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_ring_name_hit() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetRingNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).ring;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe7<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> (LootItem, LootItem, LootItem);
}

#[starknet::contract]
mod CacheReusePackedProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe7;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe7<ContractState> {
        fn run(
            self: @ContractState, target: felt252, bag_id: u64,
        ) -> (LootItem, LootItem, LootItem) {
            let packed = IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_packed_bag(bag_id);
            (
                packed.get_item(Slot::Weapon),
                packed.get_item(Slot::Foot),
                packed.get_item(Slot::Ring),
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_packed_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheReusePackedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(1);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_packed_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheReusePackedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(8000);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheReuseSelectedProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe7;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe7<ContractState> {
        fn run(
            self: @ContractState, target: felt252, bag_id: u64,
        ) -> (LootItem, LootItem, LootItem) {
            let cache = IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() };
            (
                cache.get_cached_item(bag_id, Slot::Weapon),
                cache.get_cached_item(bag_id, Slot::Foot),
                cache.get_cached_item(bag_id, Slot::Ring),
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_selected_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheReuseSelectedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(1);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_selected_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheReuseSelectedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(8000);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheReuseExpandedProbe {
    use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
    use stark_loot::core::LootItem;
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe7;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe7<ContractState> {
        fn run(
            self: @ContractState, target: felt252, bag_id: u64,
        ) -> (LootItem, LootItem, LootItem) {
            let bag = IStarkLootCacheDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_bag(bag_id);
            (bag.weapon, bag.foot, bag.ring)
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_expanded_1() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheReuseExpandedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(1);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_reuse_expanded_8000() {
    let cache = cache();
    cache.add_to_cache(8000);
    let (address, _) = declare("CacheReuseExpandedProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe7Dispatcher { contract_address: address };
    let expected = {
        let bag = get_loot_bag(8000);
        (bag.weapon, bag.foot, bag.ring)
    };
    assert!(probe.run(cache.contract_address.into(), 8000) == expected);
    assert!(crate::cache::storage_word(address, 8000) == 0, "consumer storage changed");
}

#[starknet::interface]
pub trait ICacheProbe8<TState> {
    fn run(self: @TState, target: felt252, bag_id: u64) -> Array<felt252>;
}

#[starknet::contract]
mod CacheMissGetCachedPackedBagProbe {
    use stark_loot::cache::{IStarkLootCacheSafeDispatcher, IStarkLootCacheSafeDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe8;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[feature("safe_dispatcher")]
    #[abi(embed_v0)]
    impl Probe of ICacheProbe8<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> Array<felt252> {
            IStarkLootCacheSafeDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_packed_bag(bag_id)
                .unwrap_err()
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_packed_bag_strict_miss() {
    let cache = cache();

    let (address, _) = declare("CacheMissGetCachedPackedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe8Dispatcher { contract_address: address };
    let expected = {
        let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC];
        let message: ByteArray = "bag not cached";
        message.serialize(ref error);
        error.append('ENTRYPOINT_FAILED');
        error
    };
    assert!(probe.run(cache.contract_address.into(), 0) == expected);
    assert!(crate::cache::storage_word(address, 0) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheMissGetCachedBagProbe {
    use stark_loot::cache::{IStarkLootCacheSafeDispatcher, IStarkLootCacheSafeDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe8;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[feature("safe_dispatcher")]
    #[abi(embed_v0)]
    impl Probe of ICacheProbe8<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> Array<felt252> {
            IStarkLootCacheSafeDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_bag(bag_id)
                .unwrap_err()
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_strict_miss() {
    let cache = cache();

    let (address, _) = declare("CacheMissGetCachedBagProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe8Dispatcher { contract_address: address };
    let expected = {
        let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC];
        let message: ByteArray = "bag not cached";
        message.serialize(ref error);
        error.append('ENTRYPOINT_FAILED');
        error
    };
    assert!(probe.run(cache.contract_address.into(), 0) == expected);
    assert!(crate::cache::storage_word(address, 0) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheMissGetCachedItemProbe {
    use stark_loot::cache::{IStarkLootCacheSafeDispatcher, IStarkLootCacheSafeDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe8;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[feature("safe_dispatcher")]
    #[abi(embed_v0)]
    impl Probe of ICacheProbe8<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> Array<felt252> {
            IStarkLootCacheSafeDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_item(bag_id, Slot::Ring)
                .unwrap_err()
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_item_strict_miss() {
    let cache = cache();

    let (address, _) = declare("CacheMissGetCachedItemProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe8Dispatcher { contract_address: address };
    let expected = {
        let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC];
        let message: ByteArray = "bag not cached";
        message.serialize(ref error);
        error.append('ENTRYPOINT_FAILED');
        error
    };
    assert!(probe.run(cache.contract_address.into(), 0) == expected);
    assert!(crate::cache::storage_word(address, 0) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheMissGetCachedBagNamesProbe {
    use stark_loot::cache::{IStarkLootCacheSafeDispatcher, IStarkLootCacheSafeDispatcherTrait};
    use stark_loot::packed::PackedLootBag;
    use super::ICacheProbe8;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[feature("safe_dispatcher")]
    #[abi(embed_v0)]
    impl Probe of ICacheProbe8<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> Array<felt252> {
            IStarkLootCacheSafeDispatcher { contract_address: target.try_into().unwrap() }
                .get_cached_bag_names(bag_id)
                .unwrap_err()
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_get_cached_bag_names_strict_miss() {
    let cache = cache();

    let (address, _) = declare("CacheMissGetCachedBagNamesProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe8Dispatcher { contract_address: address };
    let expected = {
        let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC];
        let message: ByteArray = "bag not cached";
        message.serialize(ref error);
        error.append('ENTRYPOINT_FAILED');
        error
    };
    assert!(probe.run(cache.contract_address.into(), 0) == expected);
    assert!(crate::cache::storage_word(address, 0) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_name_threshold_14() {
    let cache = cache();
    cache.add_to_cache(3);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(3).weapon;
    assert!(probe.run(cache.contract_address.into(), 3) == expected);
    assert!(crate::cache::storage_word(address, 3) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_name_threshold_15() {
    let cache = cache();
    cache.add_to_cache(98);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(98).weapon;
    assert!(probe.run(cache.contract_address.into(), 98) == expected);
    assert!(crate::cache::storage_word(address, 98) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_name_threshold_18() {
    let cache = cache();
    cache.add_to_cache(29);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(29).weapon;
    assert!(probe.run(cache.contract_address.into(), 29) == expected);
    assert!(crate::cache::storage_word(address, 29) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_name_threshold_19() {
    let cache = cache();
    cache.add_to_cache(60);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(60).weapon;
    assert!(probe.run(cache.contract_address.into(), 60) == expected);
    assert!(crate::cache::storage_word(address, 60) == 0, "consumer storage changed");
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_name_threshold_20() {
    let cache = cache();
    cache.add_to_cache(1);
    let (address, _) = declare("CacheCompatGetWeaponNameProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe6Dispatcher { contract_address: address };
    let expected = get_loot_bag_names(1).weapon;
    assert!(probe.run(cache.contract_address.into(), 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemWeaponIdProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Weapon).id
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_weapon_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemWeaponIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectWeaponIdProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Weapon, false,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_weapon_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectWeaponIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemWeaponGreatnessProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Weapon).greatness
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_weapon_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemWeaponGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectWeaponGreatnessProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Weapon, true,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_weapon_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectWeaponGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).weapon.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemFootIdProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Foot).id
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_foot_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemFootIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectFootIdProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Foot, false,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_foot_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectFootIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemFootGreatnessProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Foot).greatness
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_foot_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemFootGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectFootGreatnessProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Foot, true,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_foot_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectFootGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).foot.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemRingIdProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Ring).id
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_ring_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemRingIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectRingIdProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Ring, false,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_ring_id() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectRingIdProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.id;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarItemRingGreatnessProbe {
    use stark_loot::packed::{PackedLootBag, PackedLootBagTrait};
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            (PackedLootBag { value: target }).get_item(Slot::Ring).greatness
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_item_ring_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarItemRingGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}

#[starknet::contract]
mod CacheScalarDirectRingGreatnessProbe {
    use stark_loot::packed::PackedLootBag;
    use stark_loot::types::Slot;
    use super::ICacheProbe5;
    #[storage]
    struct Storage {
        bags: starknet::storage::Map<u64, PackedLootBag>,
    }
    #[abi(embed_v0)]
    impl Probe of ICacheProbe5<ContractState> {
        fn run(self: @ContractState, target: felt252, bag_id: u64) -> u8 {
            super::super::cache_scalar_candidate::scalar(
                (PackedLootBag { value: target }), Slot::Ring, true,
            )
        }
    }
}

#[test]
#[feature("safe_dispatcher")]
fn gas_cache_scalar_direct_ring_greatness() {
    let cache = cache();

    let (address, _) = declare("CacheScalarDirectRingGreatnessProbe")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    let probe = ICacheProbe5Dispatcher { contract_address: address };
    let expected = get_loot_bag(1).ring.greatness;
    assert!(probe.run(get_packed_loot_bag(1).value, 1) == expected);
    assert!(crate::cache::storage_word(address, 1) == 0, "consumer storage changed");
}
