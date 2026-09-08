# Cache benchmark regression data

These files support the cache benchmark checks in CI:

- `results.json`: all 105 caller probes, repeated twice in Sierra-gas and Cairo-step modes.
- `sizes.json`: production and probe artifact sizes, including test-to-production equivalence.
- `baseline.json`: the stateless generator artifact identity used by the compatibility guard.

Reproduce with the pinned toolchain:

```bash
scarb --release build
snforge test cache_probes:: --release --max-n-steps 4294967295 --max-threads 1
python3 scripts/cache_artifacts.py
python3 scripts/bench_cache.py --jobs 2
python3 scripts/check_cache_benchmarks.py
python3 scripts/check_cache_resources.py
```

Measurements include each caller entrypoint and its nested calls, excluding test setup and assertions. They are execution and artifact-size measurements, not total transaction fees, storage-proof sizes, or proving costs. Source hashes and revisions identify the measured inputs; compiler versions and metric equality are regression gates. Update baselines only after reproducing and reviewing a deliberate change.
