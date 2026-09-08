# Scalar getter benchmarks

[shared.json](shared.json) records release measurements for the shared full-item generator used by scalar ID and greatness getters. Each isolated probe runs twice in Sierra-gas mode and twice in Cairo-step mode with the toolchain recorded in the results. Costs include the probe entrypoint ABI and nested library call, excluding test setup and assertions; they are not transaction fees.

```bash
python3 scripts/bench_scalars.py
```

Compare results only with matching compiler versions, profiles, and measurement boundaries. Whole-test gas budgets are enforced separately by the Cairo tests.
