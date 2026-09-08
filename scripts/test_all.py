#!/usr/bin/env python3
"""Run every Cairo test, serializing only the memory-heavy fixture walks.

Prefix an explicit Foundry selection with --require-tests to reject empty runs:
    python3 scripts/test_all.py --require-tests cache_exhaustive:: --release
The guarded mode runs only the supplied selection, not the default heavy set.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEAVY = (
    "cache_exhaustive::",
    "all_loot_items_match_verbose_fixture",
    "u64_boundaries_and_fixed_seed_random",
)


def run_nonempty(command):
    """Stream diagnostics and reject renamed/missing fixture-test filters."""
    passed = 0
    with subprocess.Popen(
        command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
    ) as process:
        for line in process.stdout:
            print(line, end="", flush=True)
            plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", line)
            match = re.search(r"Tests: (\d+) passed", plain)
            if match:
                passed += int(match.group(1))
        code = process.wait()
    if code:
        raise subprocess.CalledProcessError(code, command)
    if not passed:
        raise RuntimeError(f"Expected nonempty fixture test selection: {command}")


def main(args=None):
    args = sys.argv[1:] if args is None else args
    require_tests = args[:1] == ["--require-tests"]
    if require_tests:
        args = args[1:]
        if not args or args[0].startswith("-"):
            raise ValueError(
                "--require-tests needs a test filter before Foundry options"
            )
    subprocess.run(
        [sys.executable, "scripts/prepare_cache_fixtures.py"], cwd=ROOT, check=True
    )
    base = ["snforge", "test"]
    if not any(
        arg == "--max-n-steps" or arg.startswith("--max-n-steps=") for arg in args
    ):
        base += ["--max-n-steps", "4294967295"]
    if args:
        # Explicit selections/options retain Foundry's normal CLI semantics.
        if require_tests:
            run_nonempty(base + args)
        else:
            subprocess.run(base + args, cwd=ROOT, check=True)
        return
    subprocess.run(
        base + [part for case in HEAVY for part in ("--skip", case)],
        cwd=ROOT,
        check=True,
    )
    for case in HEAVY:
        run_nonempty(base + [case, "--max-threads", "1", "--color", "never"])


if __name__ == "__main__":
    main()
