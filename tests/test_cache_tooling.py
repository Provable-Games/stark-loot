import contextlib
import copy
import io
import json
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

from scripts.bench_cache import run_logged
from scripts.check_cache_benchmarks import check_results, check_sizes
from scripts.make_cache_probes import check_files, generated_files
from scripts.test_all import main as test_all_main, run_nonempty

ROOT = Path(__file__).resolve().parents[1]


class CacheToolingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cases = json.loads((ROOT / "scripts/cache_probe_cases.json").read_text())
        evidence = ROOT / "benchmarks/cache"
        cls.results = json.loads((evidence / "results.json").read_text())
        cls.sizes = json.loads((evidence / "sizes.json").read_text())
        cls.stateless_baseline = json.loads((evidence / "baseline.json").read_text())

    def test_baselines_and_provenance(self):
        actual = copy.deepcopy(self.results)
        actual["source_sha256"] = {}
        check_results(actual, self.results, self.cases)
        actual = copy.deepcopy(self.sizes)
        actual["compiler_sha256"] = "different-host"
        check_sizes(actual, self.sizes, self.cases, self.stateless_baseline)

    def test_gas_nested_resources_configuration_and_case_drift(self):
        case = next(iter(self.cases))
        for kind in ("gas", "nested", "config", "missing", "mode"):
            actual = copy.deepcopy(self.results)
            measurement = actual["cases"][case]["measurements"]["sierra-gas"]
            if kind == "gas":
                measurement["entrypoint_l2_gas"] += 1
            elif kind == "nested":
                measurement["trace"]["nested_calls"].append({"unexpected": 1})
            elif kind == "config":
                actual["snforge"] += "changed"
            elif kind == "missing":
                del actual["cases"][case]
            else:
                del actual["cases"][case]["measurements"]["cairo-steps"]
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                check_results(actual, self.results, self.cases)

    def test_size_and_equivalence_drift(self):
        for key in (
            "casm_words",
            "sierra_words",
            "largest_segment",
            "entrypoints",
            "test_artifact_matches_production",
            "missing",
            "compiler",
        ):
            actual = copy.deepcopy(self.sizes)
            entry = actual["classes"]["stark_loot_cache"]
            if key == "missing":
                del actual["classes"]["stark_loot_cache"]
            elif key == "compiler":
                actual["compiler"] += "changed"
            elif key == "entrypoints":
                entry[key]["EXTERNAL"] += 1
            elif key == "test_artifact_matches_production":
                entry[key] = False
            else:
                entry[key] += 1
            with self.subTest(key=key), self.assertRaises(ValueError):
                check_sizes(actual, self.sizes, self.cases, self.stateless_baseline)

    def test_stateless_bytecode_drift_at_equal_size_is_rejected(self):
        actual = copy.deepcopy(self.sizes)
        actual["classes"]["stark_loot"]["casm_sha256"] = "0" * 64
        # Changing bytes must fail even when every size/resource metric matches.
        with self.assertRaisesRegex(ValueError, "reproduced stateless CASM differs"):
            check_sizes(actual, self.sizes, self.cases, self.stateless_baseline)
        # Refreshing sizes.json alone cannot silently drop the pre-cache identity.
        with self.assertRaisesRegex(ValueError, "stateless CASM differs"):
            check_sizes(actual, actual, self.cases, self.stateless_baseline)
        with self.assertRaisesRegex(ValueError, "baseline stateless CASM differs"):
            check_sizes(self.sizes, actual, self.cases, self.stateless_baseline)

    @unittest.skipUnless(
        shutil.which("scarb"), "formatter integration requires pinned Scarb"
    )
    def test_generated_files_and_independent_drift(self):
        files = generated_files()
        check_files(files)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, content in files.items():
                (root / name).parent.mkdir(parents=True, exist_ok=True)
                (root / name).write_text(content)
            for name, content in files.items():
                (root / name).write_text(content + "drift")
                with self.subTest(name=name), self.assertRaisesRegex(ValueError, name):
                    check_files(files, root)
                self.assertEqual((root / name).read_text(), content + "drift")
                (root / name).write_text(content)

    def test_failed_command_persists_and_prints_both_streams(self):
        completed = subprocess.CompletedProcess(
            ["probe"], 9, "test case failed\n", "assertion detail\n"
        )
        with (
            tempfile.TemporaryDirectory() as directory,
            patch("scripts.bench_cache.subprocess.run", return_value=completed) as run,
        ):
            output = io.StringIO()
            path = Path(directory) / "run.log"
            with (
                contextlib.redirect_stdout(output),
                self.assertRaises(subprocess.CalledProcessError),
            ):
                run_logged(["probe"], path)
            self.assertEqual(path.read_text(), completed.stdout + completed.stderr)
            self.assertEqual(output.getvalue(), path.read_text())
            self.assertEqual(
                run.call_args.kwargs,
                {"capture_output": True, "text": True, "check": False},
            )


class TestDriverTests(unittest.TestCase):
    def test_guarded_mode_runs_only_the_explicit_selection(self):
        args = [
            "cache_exhaustive::",
            "--release",
            "--max-threads",
            "1",
            "--max-n-steps=999",
        ]
        with (
            patch("scripts.test_all.subprocess.run") as run,
            patch("scripts.test_all.run_nonempty") as guarded,
        ):
            test_all_main(["--require-tests"] + args)
        self.assertEqual(run.call_count, 1)  # Fixture preparation only.
        guarded.assert_called_once_with(["snforge", "test"] + args)

    def test_guarded_mode_requires_a_selection_before_options(self):
        for args in (["--require-tests"], ["--require-tests", "--release"]):
            with (
                self.subTest(args=args),
                patch("scripts.test_all.subprocess.run") as run,
                self.assertRaisesRegex(ValueError, "needs a test filter"),
            ):
                test_all_main(args)
            run.assert_not_called()

    def test_explicit_options_and_filter_are_forwarded_once(self):
        args = [
            "cache::",
            "--fuzzer-seed",
            "123",
            "--max-threads",
            "2",
            "--max-n-steps",
            "999",
        ]
        with patch("scripts.test_all.subprocess.run") as run:
            test_all_main(args)
        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args.args[0], ["snforge", "test"] + args)

    def test_empty_or_failed_fixture_selection_is_rejected(self):
        for code, summary, error in [
            (0, "Tests: 0 passed", RuntimeError),
            (1, "Tests: 1 passed", subprocess.CalledProcessError),
        ]:
            with (
                self.subTest(code=code),
                contextlib.redirect_stdout(io.StringIO()),
                self.assertRaises(error),
            ):
                run_nonempty(
                    [
                        sys.executable,
                        "-c",
                        f"print({summary!r}); raise SystemExit({code})",
                    ]
                )
        with contextlib.redirect_stdout(io.StringIO()):
            run_nonempty([sys.executable, "-c", "print('Tests: 32 passed, 0 failed')"])
            run_nonempty(
                [
                    sys.executable,
                    "-c",
                    "print('Tests: \\x1b[32m1\\x1b[0m passed, 0 failed')",
                ]
            )

    @unittest.skipUnless(
        shutil.which("scarb"), "formatter integration requires pinned Scarb"
    )
    def test_generator_check_from_another_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            completed = subprocess.run(
                [sys.executable, str(ROOT / "scripts/make_cache_probes.py"), "--check"],
                cwd=directory,
                capture_output=True,
                text=True,
            )
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
