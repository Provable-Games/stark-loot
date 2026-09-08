//! Bounded production-entrypoint parity. Prepare JSON with scripts/prepare_cache_fixtures.py.
//! Run without coverage, with --max-threads 1; each test has at most 250 bags.
//! Serialization bounds concurrent VM memory across the large fixture walks.
use snforge_std::fs::{FileTrait, read_json};
use stark_loot::cache::IStarkLootCacheDispatcherTrait;
use stark_loot::core::{LootBag, LootBagNames};
use crate::cache::{cache, check_bag};

pub fn check_fixture(path: ByteArray) {
    let file = FileTrait::new(path);
    let mut data = read_json(@file).span();
    let cache = cache();
    while !data.is_empty() {
        let id: u64 = Serde::deserialize(ref data).unwrap();
        let word: felt252 = Serde::deserialize(ref data).unwrap();
        let bag: LootBag = Serde::deserialize(ref data).unwrap();
        let names: LootBagNames = Serde::deserialize(ref data).unwrap();
        assert!(cache.add_to_cache(id).value == word, "canonical packed fixture mismatch");
        check_bag(cache, id, word, bag, names);
    }
}

#[test]
fn batch_00() {
    check_fixture("target/cache-fixtures/00.json");
}

#[test]
fn batch_01() {
    check_fixture("target/cache-fixtures/01.json");
}

#[test]
fn batch_02() {
    check_fixture("target/cache-fixtures/02.json");
}

#[test]
fn batch_03() {
    check_fixture("target/cache-fixtures/03.json");
}

#[test]
fn batch_04() {
    check_fixture("target/cache-fixtures/04.json");
}

#[test]
fn batch_05() {
    check_fixture("target/cache-fixtures/05.json");
}

#[test]
fn batch_06() {
    check_fixture("target/cache-fixtures/06.json");
}

#[test]
fn batch_07() {
    check_fixture("target/cache-fixtures/07.json");
}

#[test]
fn batch_08() {
    check_fixture("target/cache-fixtures/08.json");
}

#[test]
fn batch_09() {
    check_fixture("target/cache-fixtures/09.json");
}

#[test]
fn batch_10() {
    check_fixture("target/cache-fixtures/10.json");
}

#[test]
fn batch_11() {
    check_fixture("target/cache-fixtures/11.json");
}

#[test]
fn batch_12() {
    check_fixture("target/cache-fixtures/12.json");
}

#[test]
fn batch_13() {
    check_fixture("target/cache-fixtures/13.json");
}

#[test]
fn batch_14() {
    check_fixture("target/cache-fixtures/14.json");
}

#[test]
fn batch_15() {
    check_fixture("target/cache-fixtures/15.json");
}

#[test]
fn batch_16() {
    check_fixture("target/cache-fixtures/16.json");
}

#[test]
fn batch_17() {
    check_fixture("target/cache-fixtures/17.json");
}

#[test]
fn batch_18() {
    check_fixture("target/cache-fixtures/18.json");
}

#[test]
fn batch_19() {
    check_fixture("target/cache-fixtures/19.json");
}

#[test]
fn batch_20() {
    check_fixture("target/cache-fixtures/20.json");
}

#[test]
fn batch_21() {
    check_fixture("target/cache-fixtures/21.json");
}

#[test]
fn batch_22() {
    check_fixture("target/cache-fixtures/22.json");
}

#[test]
fn batch_23() {
    check_fixture("target/cache-fixtures/23.json");
}

#[test]
fn batch_24() {
    check_fixture("target/cache-fixtures/24.json");
}

#[test]
fn batch_25() {
    check_fixture("target/cache-fixtures/25.json");
}

#[test]
fn batch_26() {
    check_fixture("target/cache-fixtures/26.json");
}

#[test]
fn batch_27() {
    check_fixture("target/cache-fixtures/27.json");
}

#[test]
fn batch_28() {
    check_fixture("target/cache-fixtures/28.json");
}

#[test]
fn batch_29() {
    check_fixture("target/cache-fixtures/29.json");
}

#[test]
fn batch_30() {
    check_fixture("target/cache-fixtures/30.json");
}

#[test]
fn batch_31() {
    check_fixture("target/cache-fixtures/31.json");
}
