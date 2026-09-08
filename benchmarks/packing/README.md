# Loot packing benchmarks

Release measurements for the expanded and packed APIs, with regression data in [results.json](results.json).

## Reproduce

```bash
python3 scripts/bench_packing.py
python3 scripts/check_packing_benchmarks.py
# One selected case, still repeated twice in both modes:
python3 scripts/bench_packing.py unpack_golden
```

The script reads `scripts/packing_probe_cases.json` and runs **one test at a time**, using:

```bash
SCARB_UI_VERBOSITY=no-warnings snforge test \
  stark_loot_tests::packing_probes::gas_probe_unpack_golden --exact --release \
  --gas-report --tracked-resource sierra-gas --detailed-resources --save-trace-data \
  --color never --fuzzer-seed 360029 --max-n-steps 4294967295
```

It repeats that invocation independently and then repeats the same case twice with `--tracked-resource cairo-steps`. All **26 cases / 104 invocations** must pass, with exactly one probe call per test. The script rejects missing or aggregated gas rows and mismatched gas/resource results between repetitions. Raw logs and machine-readable results are written to `target/packing-benchmarks/`; [results.json](results.json) preserves the measured results, nested resource trees, tool versions, and source hashes.

Toolchain: **Scarb 2.20.1, Cairo 2.20.0, Sierra 1.9.3, snforge 0.63.0**, release profile. Both alternatives compile in the same crate. No counterfactual historical baseline is inferred. The script verifies flag availability before running. It uses snforge's default test-contract artifact build, without `--no-optimization`, because the single-entrypoint probe contracts exist only in the test crate. This is distinct from separately built production artifacts used in the old whole-test benchmarks.

## Measurement boundary

The primary number is the selected **probe contract's `run` row** in `--gas-report`. It includes entrypoint ABI handling, return serialization, and nested library calls, and excludes declarations, test-side input construction, the independent oracle, and assertions. The caller probes take a Loot class hash and bag ID; both alternatives perform one library call to the same compiled Loot class. Full-materialization probes return all 40 fields, preventing unused-field elimination.

These are isolated execution measurements, **not total transaction costs**, and establish no net calldata, storage, settlement, SNIP-36 proving-capacity, or proving-time savings. Codec probes have different input/output ABIs, so their absolute gas figures cannot be subtracted to explain the caller probes.

Sierra accounting reports zero VM counters in saved traces. Consequently, the VM steps and builtin counts below come from separate **Cairo-step-mode** executions of the same cases. They are diagnostic counts, not a decomposition of Sierra gas. `results.json` also preserves the Cairo-step-mode L2 estimate separately; it must not be mixed with the Sierra gas figures. Probe trace resource totals include nested calls: do not add their child totals again. Keccak appears as eight syscall calls for each full-bag generation, while its VM builtin counter is zero.

## Codec results

Golden input is the independent bag-1 wire vector. Zero and maximum-width bags give the same production pack/unpack Sierra gas; their full measurements are in JSON.

| Probe operation | Sierra gas | VM steps | Range checks | Bitwise |
| --- | ---: | ---: | ---: | ---: |
| Pack 40 fields into one felt | 104,230 | 904 | 121 | 0 |
| Unpack one felt into 40 fields | 71,560 | 585 | 168 | 0 |
| Read weapon directly | 18,400 | 149 | 30 | 0 |
| Full unpack, then select weapon | 71,360 | 570 | 168 | 0 |
| Read ring directly | 18,300 | 161 | 30 | 0 |
| Full unpack, then select ring | 71,360 | 583 | 168 | 0 |

The matched weapon accessors have identical ABIs and return the same item: selective decoding saves **74.2%** of entrypoint Sierra gas. The ring comparison saves **74.4%**. The full-decode comparison validates all padding; the selective accessor intentionally validates only its own lane. Differential tests pin that documented distinction for malformed inputs.

The slow whole-u256 oracle is also measured for reproducibility (golden pack: 1,627,624; golden unpack: 8,302,126 Sierra gas). It uses independent masks, full-width arithmetic, and explicit powers/offsets. It is **not a previously shipped codec or a tuned u256 implementation**, and includes overhead beyond integer width alone. Those large ratios must not be presented as historical production savings or as the isolated benefit of felt accumulation.

## Library caller results

Each row includes the outer probe's ABI and nested library call. Bag ID is 1 unless specified.

| Caller operation | Sierra gas | VM steps | Range checks | Bitwise |
| --- | ---: | ---: | ---: | ---: |
| Existing: return 40-field bag | 1,946,908 | 3,249 | 481 | 64 |
| Packed: return one-felt bag | 1,916,978 | 3,033 | 441 | 64 |
| Packed: unpack and return 40 fields | 1,991,668 | 3,649 | 608 | 64 |
| Existing: return weapon from full bag | 1,947,808 | 3,245 | 481 | 64 |
| Packed: return weapon from full bag | 1,933,508 | 3,163 | 470 | 64 |
| Existing: return ring from full bag | 1,947,908 | 3,259 | 481 | 64 |
| Packed: return ring from full bag | 1,933,408 | 3,175 | 470 | 64 |
| Existing: return bag, maximum u64 ID | 2,003,578 | 3,734 | 592 | 64 |
| Packed: return bag, maximum u64 ID | 1,973,648 | 3,518 | 552 | 64 |
| Packed: return 40 fields, maximum u64 ID | 2,048,338 | 4,134 | 719 | 64 |

For bag 1, the representation-transfer comparison saves **1.5%**, full materialization costs **2.3% more**, and selecting either measured item from a full bag saves about **0.7%**. Full materialization increases VM steps from 3,249 to 3,649 and range checks from 481 to 608. These results include the accepted cost of sharing generation and checking packed field widths. If only one slot is needed from a bag ID, use the existing single-slot generator (one Keccak instead of eight), not either full-bag caller in this table.
