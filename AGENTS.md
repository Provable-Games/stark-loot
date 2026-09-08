# Repository Guidelines

## Project Structure & Module Organization

Stark Loot implements Ethereum-compatible Loot generation in Cairo for Starknet.

- `src/`: generation in `core.cairo`, stateless entrypoints in `contract.cairo`, storage cache in `cache.cairo`, and the single-felt codec in `packed.cairo`. Types and lookup tables occupy separate modules.
- `tests/`: Cairo integration, fuzz, and benchmark tests; canonical JSON fixtures; and Python tooling tests. Register new Cairo test modules in `tests/lib.cairo`.
- `scripts/`: Python reference generation, fixture preparation, regression checks, and deployment tooling.
- `benchmarks/{cache,packing,scalars}/`: committed measurements and reproduction instructions.
- `.github/workflows/test.yml`: formatting, correctness, coverage, and performance checks.

## Build, Test, and Development Commands

Use `.tool-versions`: Scarb 2.20.1, Starknet Foundry 0.63.0, and Python 3.12.14.

- `scarb build`: compile development artifacts into `target/`.
- `scarb --release build`: build production Sierra/CASM artifacts.
- `scarb test`: run all Cairo tests; the wrapper prepares cache fixtures and serializes memory-heavy fixture walks.
- `python3 scripts/test_all.py --require-tests cache::`: run a focused Cairo selection, rejecting empty matches.
- `python3 -m unittest discover -s tests -p 'test_*.py'`: run Python parity and tooling tests.
- `scarb fmt --check`: verify Cairo formatting; use `scarb fmt` to apply it.
- `python3 scripts/check_casm_size.py`: enforce artifact budgets after a release build.
- `python3 scripts/check_fixture_sample.py`: validate the coverage sample against canonical fixtures.

## Coding Style & Naming Conventions

Use four-space indentation. Follow existing `snake_case` module, function, and variable names, `PascalCase` types, and `UPPER_SNAKE_CASE` constants. Keep reusable generation logic in `core.cairo`. Use Scarb formatting for Cairo and follow surrounding Python style; no separate Python formatter is configured.

## Testing Guidelines

Use Starknet Foundry `#[test]` functions with descriptive behavior names and Python `unittest` in `test_*.py`. Preserve exact parity across all 8,000 canonical bags. Run the full Cairo suite without coverage for generation changes; follow CI's exclusions when collecting coverage. Codecov targets 80% patch coverage for `src/**`. Reproduce affected benchmarks using their READMEs before updating baselines.

## Commit & Pull Request Guidelines

History favors short imperative subjects such as `Add permissionless one-felt Loot cache`; occasional prefixes such as `docs:` are also used. Keep commits focused. PRs should explain behavior changes, link relevant issues, list validation commands/results, and include benchmark evidence for performance changes. Update documentation for interface or deployment changes.
