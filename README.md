# Stark Loot

A Cairo implementation of [Loot](https://etherscan.io/token/0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7#code) for Starknet.

Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.

Loot was originally launched on Ethereum, in Solidity. This repo implements a Loot generator on Starknet, which produces bags identical to the originals. This includes not only the same contents but also the same greatness for all the items and the same prefixes and suffixes, regardless of whether or not those names have been revealed yet.

This repo does not implement ERC721 or provide ownership for the bags; it provides stateless generation and an optional permissionless storage cache for 1:1 replication of Loot bags on Starknet.

## Deployment

| | |
| --- | --- |
| Network | Starknet mainnet |
| Version | `0.3.0` |
| Class hash | `0x016750a09837c17969b68a976624ec1f11dbe11f33a3824a1391132a86a3c305` |
| Contract address | `0x05817c9625ad12198ebe04cc28e827e3b4d09465ddce16a6d7fc628afa3243ab` |
| Explorer | [Class and source](https://voyager.online/class/0x016750a09837c17969b68a976624ec1f11dbe11f33a3824a1391132a86a3c305) · [Contract instance](https://voyager.online/contract/0x05817c9625ad12198ebe04cc28e827e3b4d09465ddce16a6d7fc628afa3243ab) |

Use the class hash for library calls to the stateless `stark_loot` generator, including `get_packed_bag`. Use the contract address for JSON-RPC `starknet_call` or contract-dispatcher calls. The deployed contract's `get_version` returns `'0.3.0'`.

The shared `stark_loot_cache` is also deployed on Starknet mainnet:

| | |
| --- | --- |
| Class hash | `0x041dce5cfda4ab8d37f89e67947d24b445c3fab0a3b2d6420838c4cf598f28fe` |
| Contract address | `0x012a0617d7b4229e4317da2c40db734f30178b1c6717a20843a6fb16a0f7728f` |
| Explorer | [Cache class and source](https://voyager.online/class/0x041dce5cfda4ab8d37f89e67947d24b445c3fab0a3b2d6420838c4cf598f28fe) · [Cache instance](https://voyager.online/contract/0x012a0617d7b4229e4317da2c40db734f30178b1c6717a20843a6fb16a0f7728f) |

Use the cache's contract address with a contract dispatcher for shared storage. Bags 1, 2, and 3 are populated; anyone can populate additional bags with `add_to_cache`. Both contracts report version `'0.3.0'`.

## Using it

Add the dependency:

```toml
[dependencies]
stark_loot = { git = "https://github.com/Provable-Games/stark-loot" }
```

Then call the declared class. Because the contract has no storage, executing it in your contract's context is safe — a library call cannot touch your storage if the library never reads or writes any.

```cairo
use stark_loot::contract::{IStarkLootLibraryDispatcher, IStarkLootDispatcherTrait};

const STARK_LOOT: felt252 =
    0x016750a09837c17969b68a976624ec1f11dbe11f33a3824a1391132a86a3c305;

fn equip(bag_id: u64) {
    let loot = IStarkLootLibraryDispatcher {
        class_hash: STARK_LOOT.try_into().unwrap(),
    };

    let bag = loot.get_bag(bag_id);          // all eight items
    let weapon = loot.get_weapon_item(bag_id); // one item, without deriving the rest
    let name = loot.get_weapon_name(bag_id);   // "\"Grim Shout\" Grave Wand of Skill +1"
}
```

The logic is also importable directly, skipping the contract layer entirely:

```cairo
use stark_loot::core::{get_loot_bag, get_weapon_item, get_item_name};

let bag = get_loot_bag(1);
let name = get_item_name(bag.weapon.id); // "Grave Wand"
```

## Shared storage cache

The sibling `stark_loot_cache` contract caches each canonical bag in one felt.
Anyone can fund insertion with `add_to_cache`; duplicate insertion is a read-only
no-op. Its four strict `get_cached_*` getters read once and never execute Keccak,
including on a miss (`"bag not cached"`). It also embeds `IStarkLoot` with
non-writing generation fallback. All u64 IDs are supported.

Use a deployed cache address with `IStarkLootCacheDispatcher`. Library calls execute in the caller's storage context: keep them pointed at the stateless `stark_loot` class. `get_version` reports the package version and does not identify a class or validate its storage context.

```cairo
use starknet::ContractAddress;
use stark_loot::cache::{IStarkLootCacheDispatcher, IStarkLootCacheDispatcherTrait};
use stark_loot::contract::{IStarkLootDispatcher, IStarkLootDispatcherTrait};
use stark_loot::PackedLootBagTrait;
use stark_loot::types::Slot;

fn equipment(cache_address: ContractAddress, bag_id: u64) {
    let cache = IStarkLootCacheDispatcher { contract_address: cache_address };
    cache.add_to_cache(bag_id); // caller-funded insertion; existing entries are unchanged
    let packed = cache.get_cached_packed_bag(bag_id);
    let weapon = packed.get_item(Slot::Weapon);

    let loot = IStarkLootDispatcher { contract_address: cache_address };
    let bag = loot.get_bag(bag_id); // reads cached data or generates without writing
}
```

The cache exposes `add_to_cache`, `is_cached`, `get_cached_packed_bag`, `get_cached_bag`, `get_cached_item`, and `get_cached_bag_names`, plus all 43 `IStarkLoot` getters. Strict getters panic with `"bag not cached"` on a miss. Only `add_to_cache` writes: the contract computes canonical data itself, and its API cannot overwrite or delete an entry. Zero is the absence sentinel; canonical packed bags are always nonzero.

To create another cache instance, declare and deploy it with no constructor arguments, then populate the required bags:

```bash
sncast --account <name> --wait declare --contract-name stark_loot_cache --network mainnet
sncast --account <name> --wait deploy --class-hash <cache-class-hash> --network mainnet
sncast --account <name> --wait invoke --contract-address <cache-address> \
  --function add_to_cache --calldata 1 --network mainnet
```

Cache deployment starts empty. For reads at a historical block, population must be accepted before that block. Local tests establish Keccak-free strict reads and cache hits; Virtual OS execution and proof verification of the complete artifacts remain unverified. See [cache benchmarks](benchmarks/cache/README.md) for regression checks and measurement scope.

## Single-felt bags

`get_packed_bag` returns `PackedLootBag { value: felt252 }`: all eight items and all five numeric fields per item in **one serialized felt**. Hidden modifier IDs are preserved, so full names remain reconstructible. The `get_bag` interface returns an eight-field `LootBag` (40 serialized felts).

```cairo
use stark_loot::{LootBagPackingTrait, PackedLootBag, PackedLootBagTrait};
use stark_loot::core::get_packed_loot_bag;
use stark_loot::types::Slot;

let packed = get_packed_loot_bag(1);  // generate directly into one felt
let raw: felt252 = packed.value;
let weapon = packed.get_item(Slot::Weapon); // decode only this item
let bag = packed.unpack();          // existing LootBag fields and LootItem types
let greatness = bag.weapon.greatness;
let repacked = bag.pack();
let restored = PackedLootBag { value: raw }.unpack();
```

Through a library dispatcher, use `loot.get_packed_bag(bag_id)` and the same methods with the mainnet class hash above.

Both `PackedLootBag` and `LootBag` occupy **one storage felt**. `PackedLootBag` stores its value directly; `LootBag` implements `StorePacking<LootBag, felt252>`, so ordinary storage `.write(bag)` / `.read()` automatically pack/unpack while preserving field access in memory. The codec permits zero-filled bags, including unwritten storage. Consumers with their own `Store<LootBag>` or `StorePacking` implementation should review impl selection and existing storage layout when upgrading. Writing a hand-built `LootBag` calls `pack()` and rejects fields exceeding the documented widths.

### Wire layout

Each item uses 29 bits with its existing one-based IDs; no offset adjustments are needed:

| Field | Offset within item | Width | Representable range |
| --- | ---: | ---: | ---: |
| `id` | 0 | 7 | 0–127 |
| `greatness` | 7 | 5 | 0–31 |
| `suffix_id` | 12 | 5 | 0–31 |
| `name_prefix_id` | 17 | 7 | 0–127 |
| `name_suffix_id` | 24 | 5 | 0–31 |

Two items occupy the low 58 bits of each `u64` quarter:

| Quarter | First item/start bit | Second item/start bit |
| --- | --- | --- |
| 0 | Weapon / 0 | Chest / 29 |
| 1 | Head / 64 | Waist / 93 |
| 2 | Foot / 128 | Hand / 157 |
| 3 | Neck / 192 | Ring / 221 |

No field or item crosses bit 64, 128, or 192. The highest payload bit is 249, so the complete value is below `2^250`, safely inside `felt252`. Packing uses felt multiplication/addition with constant powers of two. Unpacking converts felt → `u256`, splits `.low` and `.high` into `u64` quarters with `DivRem`, and extracts item fields with `u64` operations. It performs no `u256` division or shifting.

`pack()` checks field widths and rejects overflow. It is a numeric codec, not validation of canonical Loot IDs or slot membership: representable values outside the game's ranges round-trip unchanged. Full `unpack()` rejects nonzero padding; `get_item(slot)` checks only the selected quarter's padding and does not validate the rest of an externally supplied felt. Serde and the raw wrapper accept any felt; decoding performs those padding checks.

## What a bag contains

Eight slots, each an item drawn from that slot's list:

| Slot | Choices | Examples |
| --- | --- | --- |
| Weapon | 18 | Warhammer, Katana, Ghost Wand |
| Chest | 15 | Divine Robe, Demon Husk, Plate Mail |
| Head | 15 | Ancient Helm, Dragon's Crown, Silk Hood |
| Waist | 15 | Ornate Belt, Demonhide Belt, Brightsilk Sash |
| Foot | 15 | Holy Greaves, Dragonskin Boots, Divine Slippers |
| Hand | 15 | Holy Gauntlets, Demon's Hands, Linen Gloves |
| Neck | 3 | Necklace, Amulet, Pendant |
| Ring | 5 | Gold Ring, Silver Ring, Titanium Ring |

Each item also carries a **greatness** score from 0 to 20, which unlocks decorations on its rendered name:

| Greatness | Name becomes |
| --- | --- |
| 0–14 | `Grave Wand` |
| 15–18 | `Grave Wand of Skill` |
| 19 | `"Grim Shout" Grave Wand of Skill` |
| 20 | `"Grim Shout" Grave Wand of Skill +1` |

A `LootItem` exposes these as data rather than only as a string, so callers can branch on them:

```cairo
struct LootItem {
    id: u8,             // 1-101, which item
    greatness: u8,      // 0-20
    suffix_id: u8,      // "of Skill"      — applies above 14
    name_prefix_id: u8, // "Grim"          — applies at 19 and 20
    name_suffix_id: u8, // "Shout"         — applies at 19 and 20
}
```

## How generation works

For each slot, the contract hashes the slot name concatenated with the decimal bag ID:

```
rand = keccak256("WEAPON" + "1")
```

That single number decides everything about the item, by taking it modulo each list length: `rand % 18` picks the weapon, `rand % 21` gives greatness, `rand % 16` picks the suffix, and so on.

Matching Ethereum exactly requires these details:

- **Keccak, not Poseidon.** Cairo's `keccak_syscall` returns a little-endian `u256` while Solidity treats the digest as big-endian, so the result is byte-reversed before use.
- **One reduction, not many.** Rather than reducing the full `u256` once per modulus, the value is reduced once by `LOOT_MODULUS = 115,920` — the least common multiple of every modulus involved (3, 5, 15, 16, 18, 21, 69). Every later division then operates on a small integer. This is only equivalent to Solidity's arithmetic while every modulus divides 115,920, which is asserted in the tests.

Decimal digits are packed once per bag into a `felt252`, including the initial Keccak padding byte. Each slot adds its prefix and splits the result into four `u64` words, then pads to the syscall's 17-word block. A `u64` ID has at most 20 digits, so the packed prefix, digits, and padding stay below 2^216. See the [Keccak syscall format](https://docs.starknet.io/build/corelib/core-starknet-syscalls-keccak_syscall).

Name rendering appends the quoted name before the base and suffix, avoiding an intermediate suffixed string. Scalar ID and greatness getters select their field from the shared full-item generator. Sharing this code reduces the class size; the measured gas tradeoff is below.

## Contract interface

43 view functions in four groups:

- **Whole bag** (3) — `get_bag(bag_id)`, `get_bag_names(bag_id)`, `get_packed_bag(bag_id)`
- **Per slot** (32) — for each of the eight slots: `get_{slot}_item`, `get_{slot}_name`, `get_{slot}_id`, `get_{slot}_greatness`
- **By item ID** (7) — `get_item_name`, `get_suffix_name_by_id`, `get_name_prefix_by_id`, `get_name_suffix_by_id`, `get_item_type`, `get_item_tier`, `get_item_slot`
- **Metadata** (1) — `get_version`, a short string identifying this implementation

The `core` module names the last three `get_type` / `get_tier` / `get_slot`; the contract prefixes them with `item_` so `get_slot` does not collide with the per-slot accessors.

`get_{slot}_item` derives only the slot you asked for, so reading one item does not cost what reading a whole bag costs.

Items 9–101 also carry combat metadata for games built on top: a `Type` (Magic/Cloth, Blade/Hide, Bludgeon/Metal), a `Tier` (T1–T5), and a `Slot`. Necklaces and rings (IDs 1–8) have no combat type, so `get_item_type` panics for them; `get_item_tier` and `get_item_slot` cover all 101.

```cairo
use stark_loot::item_id::ItemId;
use stark_loot::types::{Tier, Type};

loot.get_item_type(ItemId::Katana); // Type::Blade_or_Hide
loot.get_item_tier(ItemId::Katana); // Tier::T1
```

## Measured cost

The primary measurements use isolated, single-entrypoint probes in `tests/packing_probes.cairo`, compiled together in the release profile with Scarb 2.20.1 / Cairo 2.20.0 / Sierra 1.9.3 and Starknet Foundry 0.63.0. Each figure is the **probe's entrypoint row**, including ABI handling and any nested library call, excluding test setup and assertions. Every case is reproduced twice. These are execution measurements, not total transaction fees or storage/settlement savings.

Bag ID is 1 unless specified.

| Operation | Expanded bag | Packed bag | Reduction |
| --- | ---: | ---: | ---: |
| Library call, return representation | 1,946,908 | 1,916,978 | 1.5% |
| Library call, return all 40 decoded fields | 1,946,908 | 1,991,668 | -2.3% |
| Library call, return weapon from full bag | 1,947,808 | 1,933,508 | 0.7% |
| Library call, return representation, maximum `u64` ID | 2,003,578 | 1,973,648 | 1.5% |
| Library call, return all fields, maximum `u64` ID | 2,003,578 | 2,048,338 | -2.2% |

Codec-only probes measure `pack()` at **104,230**, `unpack()` at **71,560**, and `get_item(Weapon)` at **18,400** Sierra gas. These include their own entrypoint ABI costs: packing accepts 40 fields, unpacking returns 40, and selective access returns five. Do not subtract these figures from the library-call rows or compare them as if they had identical ABIs.

The single-item comparison starts from a **full bag in both cases**. If only one item is needed from a bag ID, the per-slot generator is much cheaper: it computes one Keccak hash instead of eight. Use the expanded `LootBag` API when all fields are immediately needed: the shared packed generator followed by full unpacking costs more gas, as shown above. Negative reductions indicate increased gas. Both representations still support one-felt storage; the packed API primarily benefits callers that keep or selectively decode the packed value.

Run the reproducible harness:

```bash
python3 scripts/bench_packing.py
python3 scripts/check_packing_benchmarks.py
# Or select cases; each still runs twice in each accounting mode:
python3 scripts/bench_packing.py pack_golden unpack_golden item_weapon
```

[The benchmark report](benchmarks/packing/README.md) includes resource counts, all comparison boundaries, limitations, and the checked-in machine-readable results. Compiler versions/builds remain exact comparison gates; the recorded host architecture is provenance so matching measurements can be checked across hosts. Sierra-gas runs supply the primary figures; separate Cairo-step runs supply VM steps and builtin counts. The harness uses snforge's default test-contract artifact build so its test-only probes are available. Both sides use the same build. The production CASM size below is measured separately.

Whole-test costs can also be measured with `snforge test bench_ --release --no-optimization`; their boundary and artifact build differ, so their values should not be mixed with the probe results. Run the complete suite without `--no-optimization`, since its storage and probe contracts are defined in test modules.

Both bag APIs reuse the same item generation, with checked packing for the one-felt result. Release CASM is **20,830 words** for `stark_loot` and **30,340 words** for `stark_loot_cache`. CI enforces separate ceilings of 21,000 and 32,000 words:

```bash
scarb --release build
python3 scripts/check_casm_size.py
```

Shared full-item generation reduces class size at a gas cost for scalar and packed callers. The [packing benchmark report](benchmarks/packing/README.md) and [scalar benchmark report](benchmarks/scalars/README.md) document the measured tradeoffs and reproduction instructions.

Build immediately before running the size checker: it reads the artifact on disk and cannot detect a stale build. These are full-class CASM word counts, not measurements of SNIP-36 Virtual OS proof capacity or proving time. The generator still uses eight Keccak hashes per bag and preserves the original Loot algorithm.

Dev-profile measurements and enforced budgets are below. With the pinned toolchain, the exact CI coverage command and the dev benchmark command below produce the same gas costs, including library calls.

| Budgeted benchmark | Dev L2 gas | Budget | Headroom |
| --- | ---: | ---: | ---: |
| Full bag | 2,257,428 | 2,300,000 | 1.9% |
| Full bag names | 2,854,008 | 2,900,000 | 1.6% |
| One rendered name | 558,281 | 580,000 | 3.9% |
| One item, maximum `u64` ID | 450,961 | 480,000 | 6.4% |
| Full bag, maximum `u64` ID | 2,389,668 | 2,500,000 | 4.6% |
| Full bag names, maximum `u64` ID | 2,613,468 | 2,750,000 | 5.2% |
| Weapon ID, library call | 481,721 | 500,000 | 3.8% |
| Weapon greatness, library call | 481,721 | 500,000 | 3.8% |
| Weapon item, library call | 510,861 | 540,000 | 5.7% |
| Full bag, library call | 2,723,218 | 2,850,000 | 4.7% |
| Full bag names, library call | 3,342,808 | 3,500,000 | 4.7% |
| Packed bag, direct | 2,435,628 | 2,500,000 | 2.6% |
| Packed bag, library call | 2,595,618 | 2,700,000 | 4.0% |
| Packed library call, unpack all fields | 2,794,448 | 2,900,000 | 3.8% |
| Packed library call, select weapon | 2,632,158 | 2,750,000 | 4.5% |
| Packed library call, unpack all fields, maximum u64 ID | 2,926,688 | 3,050,000 | 4.2% |

Gas accounting is deterministic for this pinned configuration. The tight whole-bag budgets preserve the measured improvements: 10% headroom would allow full bag and bag names to return to their pre-optimization dev costs. Scalar budgets reflect the deliberate choice to share full-item generation and reduce CASM. A benchmark reporting `Ran out of gas` indicates its regression budget was exceeded. Review measurements and budgets deliberately when updating the toolchain. An unbudgeted direct single-item call costs 318,721 L2 gas.

```bash
snforge test bench_ --no-optimization
SCARB_PROFILE=release snforge test bench_ --no-optimization
```

`--no-optimization` builds the contract separately so library-call benchmarks use normal contract artifacts. It does not disable the selected profile's Cairo compiler optimizations.

Keep `#[inline(never)]` on the shared `pluck_packed_item` and `pluck_item_word` helpers; review budgets deliberately when changing compiler pins.

## Development

Requires [Scarb](https://docs.swmansion.com/scarb/) and [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/); exact versions are pinned in `.tool-versions`. Python fixture/version tests require Python 3.11+ for the standard-library TOML parser; CI uses Python 3.12.14, pinned in `.tool-versions`.

```bash
scarb build
scarb --release build
python3 scripts/check_casm_size.py
python3 scripts/check_fixture_sample.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/prepare_cache_fixtures.py
scarb test # isolates large fixture walks to bound concurrent VM memory
scarb fmt --check
```

The step budget is raised because the suite verifies all 8,000 bags in one test. To reproduce the CI coverage run:

```bash
scarb fmt --check
scarb --release build
python3 scripts/check_casm_size.py
python3 scripts/check_fixture_sample.py
python3 -m unittest discover -s tests -p 'test_*.py'
snforge test packing_oracle --max-n-steps 4294967295
python3 scripts/bench_packing.py
python3 scripts/check_packing_benchmarks.py
python3 scripts/prepare_cache_fixtures.py
snforge test --coverage --max-n-steps 4294967295 --skip all_loot_items_match_verbose_fixture --skip packing_oracle --skip packing_probes --skip cache_exhaustive --skip cache_probes --skip u64_boundaries_and_fixed_seed_random
```

### Test suite

Cache tests add production-entrypoint parity for all 8,000 bags (32 batches of
250, without coverage), 124 boundary/fixed-seed random u64 IDs, exact misses,
canonical insertion provenance, actual mapping words, event/idempotence checks,
and independent deployments. Run `python3 scripts/check_cache_resources.py` for
all caller syscall-tree invariants. The separate production size budgets are
21,000 CASM words for `stark_loot` and 32,000 for `stark_loot_cache`.

323 Cairo tests (176 generator/codec tests plus 147 cache tests/probes). Correctness checks include:

- `tests/loot_bags.cairo` — rendered names for known bags, every decoration threshold, and a 13-bag JSON sample that exercises the shared exhaustive-fixture validator in CI
- `tests/loot_reference.cairo` — 500 reference bags as `LootItem` structs, checked by `first_500_loot_items_match_cairo_fixture`
- `tests/view_functions.cairo` — library scalar getters against whole bags, and every ID lookup against the canonical lists
- `tests/gas_benchmarks.cairo` and `tests/packed_bags.cairo` — gas benchmarks, wire-layout vectors, arbitrary-field fuzzing, overflow/padding checks, and one-felt storage/ABI integration
- `tests/packing_oracle.cairo` — independent whole-`u256` codec, fixed-seed differential fuzzing, every field and payload bit in isolation, and exact malformed-input errors
- `tests/scalar_benchmarks.cairo` — isolated scalar library-call probes; reproduce twice in both accounting modes with `python3 scripts/bench_scalars.py`
- `tests/packing_probes.cairo` — isolated codec and library-caller measurements; CI repeats all 26 cases twice in both accounting modes
- `all_loot_items_match_verbose_fixture` — all 8,000 bags read directly from `tests/verbose_loot.json`, checking rendered names, greatness, every modifier including hidden ones, each stored greatness-20 `final_name` preview, and packed-generation/codec parity. Preview validation reuses already-checked components without extra Keccak calls. Its coverage trace is too large for CI; run the full suite without `--coverage` locally before changing generation. CI traces both `first_500_loot_items_match_cairo_fixture` (500 bags / 4,000 Keccak calls) and the 13-bag `tests/verbose_loot_sample.json` through the JSON validator, including packed-codec parity. The exhaustive generator JSON walk, cache batches and larger u64 cache sample run without coverage; the slow oracle and all benchmark probes also run separately without coverage. The sample is checked against the full fixture.

A corrupt-preview regression test checks the exact error, and a small synthetic JSON fixture pins lexicographic bag/slot/field ordering without changing the canonical fixture schema.

Foundry does not emit coverage traces for randomized fuzz runs. The deterministic hash test replays the same property for 64 full-range `u64` IDs and all eight slot prefixes; the general fuzzers explore a varying seed on each run. Differential oracle tests and benchmark invocations retain explicit fixed seeds for reproducibility.

The Python discovery command runs exhaustive parity checks for all 8,000 bags plus fixture, CLI, CASM, and version guards. It also tests the packing-benchmark checker.

Reference data lives in `tests/loot.json` (rendered names for all 8,000 bags) and `tests/verbose_loot.json` (full metadata). `scripts/loot.py` is a Python implementation of the same algorithm, useful for regenerating fixtures. After regenerating the full verbose fixture, update and validate the bounded coverage sample:

```bash
python3 scripts/loot.py --all --fixture-schema --output tests/verbose_loot.json
python3 scripts/check_fixture_sample.py --write
python3 scripts/check_fixture_sample.py
```

The checker requires exactly bag keys 1–8,000 and selects sample entries in lexicographic order, matching Cairo `read_json`. If changing its sample count, also update the Cairo sample test’s expected terminal bag ID. Ordinary CLI output retains all eleven metadata fields, including numeric IDs, for stdout and arbitrary `--output` paths. Use `--fixture-schema` when regenerating the seven-field verbose fixture: it preserves committed field order and bytes. The flag is mutually exclusive with `--names-only`; `--concise-output` independently writes the numeric LootItem schema. CI runs the checker and Python regression tests before Cairo tests.

### Deploying

`scripts/deploy.sh` uses `sncast` to declare the class and optionally deploy an instance, then the `voyager` CLI to submit the source for verification. Signing keys come from your Starknet Foundry accounts file. Install the tool versions in `.tool-versions` and a compatible `universal-sierra-compiler` (this deployment used 2.10.0); the script also requires `curl`, `jq`, and `xxd`.

```bash
sncast account list                                        # find your account name
RPC_URL='https://...' ./scripts/deploy.sh \
  --account <name> --estimate-only                         # fee estimate, sends nothing
RPC_URL='https://...' ./scripts/deploy.sh \
  --account <name> --deploy-instance                      # declare + deploy + verify
```

Set `RPC_URL` to your intended network’s RPC endpoint; it can also be stored in `.env`. The script defaults to declaration and verification without an instance; use `--deploy-instance` as above to deploy one, or `--no-verify` to skip Voyager.

The script prints the chain name and class hash before spending anything, and derives the class hash with `sncast` so it always matches the profile being declared — `dev` and `release` compile to different Sierra and therefore different class hashes.

## Compatibility

Verified against the original Loot contract at [`0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7`](https://etherscan.io/token/0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7#code) on Ethereum mainnet, across all 8,000 bags.

Bag IDs are `u64` here, while Ethereum's `tokenId` is `uint256`. Every ID this contract can represent produces identical output; IDs at or above 2^64 cannot be passed. The packed seed builder also relies on this bound: at most 20 decimal digits, with the prefixed and padded seed fitting below 2^216. Widening the ID type requires redesigning that encoding to avoid field overflow.

`tokenURI` is not implemented. This repository generates items and names, not the SVG and base64 JSON envelope the Ethereum contract returns.

## License

The original Loot contract is in the public domain. This implementation is MIT licensed.
