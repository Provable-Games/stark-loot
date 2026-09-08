use stark_loot::core::{
    get_chest_item, get_chest_name, get_foot_item, get_foot_name, get_hand_item, get_hand_name,
    get_head_item, get_head_name, get_loot_bag, get_loot_bag_names, get_neck_item, get_neck_name,
    get_ring_item, get_ring_name, get_waist_item, get_waist_name, get_weapon_item, get_weapon_name,
};

// Gas benchmarks. Budgets guard the optimized paths on the pinned dev toolchain.
// README lists CI measurements and reproduction commands. An out-of-gas failure here signals
// a budget regression; review measurements when changing toolchain pins.
// Tight margins deliberately require remeasurement for compiler/toolchain changes:
// - full bag: 2,257,428 measured / 2,300,000 budget; 42,572 spare gas (1.9%).
// - bag names: 2,854,008 measured / 2,900,000 budget; 45,992 spare gas (1.6%).
// Scalar library getters share full-item generation: 481,721 measured / 500,000 budget.
// See README's "Measured cost" table for the other budgets. On failure, reproduce
// with `snforge test bench_ --no-optimization` on the pinned dev toolchain;
// review the changed measurements before deliberately recalibrating a budget.

#[test]
fn bench_get_weapon_item() {
    get_weapon_item(1);
}

#[test]
fn bench_get_chest_item() {
    get_chest_item(1);
}

#[test]
fn bench_get_head_item() {
    get_head_item(1);
}

#[test]
fn bench_get_waist_item() {
    get_waist_item(1);
}

#[test]
fn bench_get_foot_item() {
    get_foot_item(1);
}

#[test]
fn bench_get_hand_item() {
    get_hand_item(1);
}

#[test]
fn bench_get_neck_item() {
    get_neck_item(1);
}

#[test]
fn bench_get_ring_item() {
    get_ring_item(1);
}

#[test]
#[available_gas(l2_gas: 2_300_000)]
fn bench_get_loot_bag() {
    get_loot_bag(1);
}

#[test]
fn bench_multiple_single_items() {
    get_weapon_item(1);
    get_chest_item(1);
    get_head_item(1);
}

#[test]
fn test_single_item_matches_full_bag() {
    // Verify optimization doesn't affect correctness
    let full_bag = get_loot_bag(1);
    let weapon = get_weapon_item(1);
    let chest = get_chest_item(1);
    let head = get_head_item(1);
    let waist = get_waist_item(1);
    let foot = get_foot_item(1);
    let hand = get_hand_item(1);
    let neck = get_neck_item(1);
    let ring = get_ring_item(1);

    assert(weapon == full_bag.weapon, 'weapon mismatch');
    assert(chest == full_bag.chest, 'chest mismatch');
    assert(head == full_bag.head, 'head mismatch');
    assert(waist == full_bag.waist, 'waist mismatch');
    assert(foot == full_bag.foot, 'foot mismatch');
    assert(hand == full_bag.hand, 'hand mismatch');
    assert(neck == full_bag.neck, 'neck mismatch');
    assert(ring == full_bag.ring, 'ring mismatch');
}

// ==================================================================================
// Bag Names Optimization Benchmarks
// ==================================================================================

#[test]
#[available_gas(l2_gas: 2_900_000)]
fn bench_get_loot_bag_names() {
    get_loot_bag_names(1);
}

#[test]
#[available_gas(l2_gas: 580_000)]
fn bench_get_single_item_name() {
    get_weapon_name(1);
}

#[test]
fn bench_get_three_item_names() {
    get_weapon_name(1);
    get_chest_name(1);
    get_head_name(1);
}

#[test]
fn test_bag_names_matches_individual_names() {
    // Verify optimization doesn't affect correctness
    let bag_names = get_loot_bag_names(1);

    assert(bag_names.weapon == get_weapon_name(1), 'weapon name mismatch');
    assert(bag_names.chest == get_chest_name(1), 'chest name mismatch');
    assert(bag_names.head == get_head_name(1), 'head name mismatch');
    assert(bag_names.waist == get_waist_name(1), 'waist name mismatch');
    assert(bag_names.foot == get_foot_name(1), 'foot name mismatch');
    assert(bag_names.hand == get_hand_name(1), 'hand name mismatch');
    assert(bag_names.neck == get_neck_name(1), 'neck name mismatch');
    assert(bag_names.ring == get_ring_name(1), 'ring name mismatch');
}

#[test]
#[available_gas(l2_gas: 480_000)]
fn bench_get_weapon_item_max_id() {
    get_weapon_item(0xffffffffffffffff);
}

#[test]
#[available_gas(l2_gas: 2_500_000)]
fn bench_get_loot_bag_max_id() {
    get_loot_bag(0xffffffffffffffff);
}

#[test]
#[available_gas(l2_gas: 2_750_000)]
fn bench_get_loot_bag_names_max_id() {
    get_loot_bag_names(0xffffffffffffffff);
}

// Exercise the same library-call boundary used by consuming contracts.
use stark_loot::contract::IStarkLootDispatcherTrait;
use super::helpers::library;

#[test]
#[available_gas(l2_gas: 540_000)]
fn bench_library_weapon_item() {
    library().get_weapon_item(1);
}

#[test]
#[available_gas(l2_gas: 500_000)]
fn bench_library_weapon_id() {
    library().get_weapon_id(1);
}

#[test]
#[available_gas(l2_gas: 500_000)]
fn bench_library_weapon_greatness() {
    library().get_weapon_greatness(1);
}

#[test]
#[available_gas(l2_gas: 2_850_000)]
fn bench_library_bag() {
    library().get_bag(1);
}

#[test]
#[available_gas(l2_gas: 3_500_000)]
fn bench_library_bag_names() {
    library().get_bag_names(1);
}
