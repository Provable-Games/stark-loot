use snforge_std::cheatcodes::storage::store;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, load, map_entry_address,
    spy_events, start_cheat_caller_address,
};
use stark_loot::cache::{
    IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait, IStarkLootCacheSafeDispatcher,
    IStarkLootCacheSafeDispatcherTrait,
};
use stark_loot::contract::{
    IStarkLootDispatcher, IStarkLootDispatcherTrait, IStarkLootSafeDispatcherTrait,
};
use stark_loot::core::{LootBag, LootBagNames, get_loot_bag, get_packed_loot_bag};
use stark_loot::packed::PackedLootBagTrait;
use stark_loot::types::Slot;
use starknet::ContractAddress;

pub fn cache() -> IStarkLootCacheDispatcher {
    let (contract_address, _) = declare("stark_loot_cache")
        .unwrap()
        .contract_class()
        .deploy(@array![])
        .unwrap();
    IStarkLootCacheDispatcher { contract_address }
}

#[test]
fn insertion_and_duplicate() {
    let cache = cache();
    assert!(!cache.is_cached(1));
    let expected = get_packed_loot_bag(1);
    assert!(cache.add_to_cache(1) == expected);
    assert!(cache.is_cached(1));
    assert!(cache.get_cached_packed_bag(1) == expected);
    assert!(cache.add_to_cache(1) == expected);
}

pub fn storage_word(address: ContractAddress, id: u64) -> felt252 {
    let key = map_entry_address(selector!("bags"), array![id.into()].span());
    *load(address, key, 1).at(0)
}

pub fn check_bag(
    cache: IStarkLootCacheDispatcher, id: u64, word: felt252, bag: LootBag, names: LootBagNames,
) {
    assert!(word != 0);
    assert!(storage_word(cache.contract_address, id) == word, "stored word mismatch");
    assert!(cache.get_cached_packed_bag(id).value == word);
    assert!(cache.get_cached_bag(id) == bag, "cached metadata mismatch");
    assert!(cache.get_cached_bag_names(id) == names);
    let view = IStarkLootDispatcher { contract_address: cache.contract_address };
    assert!(view.get_packed_bag(id).value == word);
    assert!(view.get_bag(id) == bag);
    assert!(view.get_bag_names(id) == names);
    assert!(cache.get_cached_item(id, Slot::Weapon) == bag.weapon);
    assert!(view.get_weapon_item(id) == bag.weapon);
    assert!(view.get_weapon_id(id) == bag.weapon.id);
    assert!(view.get_weapon_greatness(id) == bag.weapon.greatness);
    assert!(view.get_weapon_name(id) == names.weapon);
    assert!(cache.get_cached_item(id, Slot::Chest) == bag.chest);
    assert!(view.get_chest_item(id) == bag.chest);
    assert!(view.get_chest_id(id) == bag.chest.id);
    assert!(view.get_chest_greatness(id) == bag.chest.greatness);
    assert!(view.get_chest_name(id) == names.chest);
    assert!(cache.get_cached_item(id, Slot::Head) == bag.head);
    assert!(view.get_head_item(id) == bag.head);
    assert!(view.get_head_id(id) == bag.head.id);
    assert!(view.get_head_greatness(id) == bag.head.greatness);
    assert!(view.get_head_name(id) == names.head);
    assert!(cache.get_cached_item(id, Slot::Waist) == bag.waist);
    assert!(view.get_waist_item(id) == bag.waist);
    assert!(view.get_waist_id(id) == bag.waist.id);
    assert!(view.get_waist_greatness(id) == bag.waist.greatness);
    assert!(view.get_waist_name(id) == names.waist);
    assert!(cache.get_cached_item(id, Slot::Foot) == bag.foot);
    assert!(view.get_foot_item(id) == bag.foot);
    assert!(view.get_foot_id(id) == bag.foot.id);
    assert!(view.get_foot_greatness(id) == bag.foot.greatness);
    assert!(view.get_foot_name(id) == names.foot);
    assert!(cache.get_cached_item(id, Slot::Hand) == bag.hand);
    assert!(view.get_hand_item(id) == bag.hand);
    assert!(view.get_hand_id(id) == bag.hand.id);
    assert!(view.get_hand_greatness(id) == bag.hand.greatness);
    assert!(view.get_hand_name(id) == names.hand);
    assert!(cache.get_cached_item(id, Slot::Neck) == bag.neck);
    assert!(view.get_neck_item(id) == bag.neck);
    assert!(view.get_neck_id(id) == bag.neck.id);
    assert!(view.get_neck_greatness(id) == bag.neck.greatness);
    assert!(view.get_neck_name(id) == names.neck);
    assert!(cache.get_cached_item(id, Slot::Ring) == bag.ring);
    assert!(view.get_ring_item(id) == bag.ring);
    assert!(view.get_ring_id(id) == bag.ring.id);
    assert!(view.get_ring_greatness(id) == bag.ring.greatness);
    assert!(view.get_ring_name(id) == names.ring);
    assert!(storage_word(cache.contract_address, id) == word);
}

#[test]
fn permissionless_idempotent_one_felt_and_event() {
    let cache = cache();
    let id = 1;
    let key = map_entry_address(selector!("bags"), array![id.into()].span());
    let mut spy = spy_events();
    start_cheat_caller_address(cache.contract_address, 0x111.try_into().unwrap());
    let packed = cache.add_to_cache(id);
    assert!(load(cache.contract_address, key, 2).span() == array![packed.value, 0].span());
    assert!(*load(cache.contract_address, key - 1, 1).at(0) == 0);
    start_cheat_caller_address(cache.contract_address, 0x222.try_into().unwrap());
    assert!(cache.add_to_cache(id) == packed);
    let events = spy.get_events().events;
    assert!(events.len() == 1);
    let (address, event) = events.at(0);
    assert!(*address == cache.contract_address);
    assert!(event.keys.span() == array![selector!("BagCached"), 1].span());
    assert!(event.data.is_empty());
}

#[test]
#[feature("safe_dispatcher")]
fn every_strict_miss_has_exact_error_and_no_state_or_events() {
    let cache = cache();
    let safe = IStarkLootCacheSafeDispatcher { contract_address: cache.contract_address };
    let mut error = array![core::byte_array::BYTE_ARRAY_MAGIC];
    let message: ByteArray = "bag not cached";
    message.serialize(ref error);
    error.append('ENTRYPOINT_FAILED');
    let mut spy = spy_events();
    assert!(safe.get_cached_packed_bag(0).unwrap_err() == error);
    assert!(safe.get_cached_bag(0).unwrap_err() == error);
    assert!(safe.get_cached_item(0, Slot::Ring).unwrap_err() == error);
    assert!(safe.get_cached_bag_names(0).unwrap_err() == error);
    assert!(!cache.is_cached(0));
    assert!(storage_word(cache.contract_address, 0) == 0);
    assert!(spy.get_events().events.is_empty());
}

#[test]
fn compatibility_misses_leave_storage_empty() {
    let cache = cache();
    let view = IStarkLootDispatcher { contract_address: cache.contract_address };
    let mut spy = spy_events();
    for id in array![0_u64, 1, 8001, 18446744073709551615] {
        let bag = get_loot_bag(id);
        let names = stark_loot::core::get_loot_bag_names(id);
        assert!(view.get_packed_bag(id) == get_packed_loot_bag(id));
        assert!(view.get_bag(id) == bag);
        assert!(view.get_bag_names(id) == names);
        assert!(view.get_weapon_item(id) == bag.weapon);
        assert!(view.get_weapon_id(id) == bag.weapon.id);
        assert!(view.get_weapon_greatness(id) == bag.weapon.greatness);
        assert!(view.get_weapon_name(id) == names.weapon);
        assert!(view.get_chest_item(id) == bag.chest);
        assert!(view.get_chest_id(id) == bag.chest.id);
        assert!(view.get_chest_greatness(id) == bag.chest.greatness);
        assert!(view.get_chest_name(id) == names.chest);
        assert!(view.get_head_item(id) == bag.head);
        assert!(view.get_head_id(id) == bag.head.id);
        assert!(view.get_head_greatness(id) == bag.head.greatness);
        assert!(view.get_head_name(id) == names.head);
        assert!(view.get_waist_item(id) == bag.waist);
        assert!(view.get_waist_id(id) == bag.waist.id);
        assert!(view.get_waist_greatness(id) == bag.waist.greatness);
        assert!(view.get_waist_name(id) == names.waist);
        assert!(view.get_foot_item(id) == bag.foot);
        assert!(view.get_foot_id(id) == bag.foot.id);
        assert!(view.get_foot_greatness(id) == bag.foot.greatness);
        assert!(view.get_foot_name(id) == names.foot);
        assert!(view.get_hand_item(id) == bag.hand);
        assert!(view.get_hand_id(id) == bag.hand.id);
        assert!(view.get_hand_greatness(id) == bag.hand.greatness);
        assert!(view.get_hand_name(id) == names.hand);
        assert!(view.get_neck_item(id) == bag.neck);
        assert!(view.get_neck_id(id) == bag.neck.id);
        assert!(view.get_neck_greatness(id) == bag.neck.greatness);
        assert!(view.get_neck_name(id) == names.neck);
        assert!(view.get_ring_item(id) == bag.ring);
        assert!(view.get_ring_id(id) == bag.ring.id);
        assert!(view.get_ring_greatness(id) == bag.ring.greatness);
        assert!(view.get_ring_name(id) == names.ring);
        assert!(!cache.is_cached(id));
        assert!(storage_word(cache.contract_address, id) == 0);
    }
    assert!(spy.get_events().events.is_empty());
}

#[test]
fn deployments_are_independent_and_library_remains_stateless() {
    let first = cache();
    let second = cache();
    let packed = first.add_to_cache(1);
    assert!(!second.is_cached(1));
    assert!(crate::helpers::library().get_packed_bag(1) == packed);
    assert!(second.add_to_cache(1) == packed);
}

#[test]
#[should_panic(expected: ("cached metadata mismatch",))]
fn oracle_rejects_corrupt_hidden_metadata() {
    let cache = cache();
    let packed = cache.add_to_cache(1);
    // Flip a hidden suffix bit in bag 1 chest (greatness 8); rendered name stays the same.
    let corrupt: felt252 = (Into::<felt252, u256>::into(packed.value) ^ (1_u256 * 0x20000000000))
        .try_into()
        .unwrap();
    let key = map_entry_address(selector!("bags"), array![1].span());
    store(cache.contract_address, key, array![corrupt].span());
    check_bag(cache, 1, corrupt, get_loot_bag(1), stark_loot::core::get_loot_bag_names(1));
}

#[test]
fn fixture_sample() {
    crate::cache_exhaustive::check_fixture("target/cache-fixtures/sample.json");
}

#[test]
fn u64_boundaries_and_fixed_seed_random() {
    crate::cache_exhaustive::check_fixture("target/cache-fixtures/boundaries.json");
}

#[test]
#[feature("safe_dispatcher")]
fn by_id_metadata_and_errors_match_old_library() {
    let cache = cache();
    let view = stark_loot::contract::IStarkLootSafeDispatcher {
        contract_address: cache.contract_address,
    };
    let library = stark_loot::contract::IStarkLootSafeLibraryDispatcher {
        class_hash: *declare("stark_loot").unwrap().contract_class().class_hash,
    };
    assert!(view.get_version() == library.get_version());
    for id in 0_u16..256 {
        let id: u8 = id.try_into().unwrap();
        assert!(view.get_item_name(id) == library.get_item_name(id));
        assert!(view.get_suffix_name_by_id(id) == library.get_suffix_name_by_id(id));
        assert!(view.get_name_prefix_by_id(id) == library.get_name_prefix_by_id(id));
        assert!(view.get_name_suffix_by_id(id) == library.get_name_suffix_by_id(id));
        assert!(view.get_item_type(id) == library.get_item_type(id));
        assert!(view.get_item_tier(id) == library.get_item_tier(id));
        assert!(view.get_item_slot(id) == library.get_item_slot(id));
    }
}

#[test]
fn abi_rejects_ids_outside_u64_without_populating() {
    let cache = cache();
    let mut spy = spy_events();
    assert!(
        starknet::syscalls::call_contract_syscall(
            cache.contract_address, selector!("add_to_cache"), array![0x10000000000000000].span(),
        )
            .is_err(),
    );
    assert!(!cache.is_cached(0));
    assert!(spy.get_events().events.is_empty());
}
