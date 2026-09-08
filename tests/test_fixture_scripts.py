import contextlib
import io
import json
import re
import tomllib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts import check_casm_size


ROOT = Path(__file__).resolve().parents[1]


class FixtureScriptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.full = Path(self.temp.name) / "full.json"
        self.sample = Path(self.temp.name) / "sample.json"

    def check_sample(self, *args):
        return subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts/check_fixture_sample.py"),
                "--input",
                str(self.full),
                "--output",
                str(self.sample),
                *args,
            ],
            capture_output=True,
            text=True,
        )

    def test_rejects_incomplete_or_wrong_canonical_keys_before_writing(self):
        canonical = {str(i): {} for i in range(1, 8001)}
        for invalid in (
            json.loads((ROOT / "tests/verbose_loot_sample.json").read_text()),
            {k: v for k, v in canonical.items() if k != "8000"},
            {**canonical, "8001": {}},
            {**{k: v for k, v in canonical.items() if k != "8000"}, "0": {}},
        ):
            with self.subTest(keys=len(invalid)):
                self.full.write_text(json.dumps(invalid))
                self.sample.write_text("unchanged")
                result = self.check_sample("--write")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("exactly bag keys 1 through 8000", result.stderr)
                self.assertEqual(self.sample.read_text(), "unchanged")

    def test_sample_round_trip_and_drift_detection(self):
        self.full.write_bytes((ROOT / "tests/verbose_loot.json").read_bytes())
        result = self.check_sample("--write")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(self.sample.read_text()),
            json.loads((ROOT / "tests/verbose_loot_sample.json").read_text()),
        )
        self.assertEqual(self.check_sample().returncode, 0)
        sample = json.loads(self.sample.read_text())
        sample["1"]["weapon"]["current_name"] = "wrong name"
        self.sample.write_text(json.dumps(sample))
        result = self.check_sample()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("regenerate with --write", result.stderr)

    def test_regenerated_verbose_schema_matches_fixture_and_keeps_concise_ids(self):
        concise = Path(self.temp.name) / "concise.json"
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts/loot.py"),
                "--range",
                "1",
                "13",
                "--fixture-schema",
                "--output",
                str(self.full),
                "--concise-output",
                str(concise),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        canonical = json.loads((ROOT / "tests/verbose_loot.json").read_text())
        expected = {str(i): canonical[str(i)] for i in range(1, 14)}
        self.assertEqual(json.loads(self.full.read_text()), expected)
        # Dict equality misses key-order changes that rewrite the entire fixture.
        self.assertEqual(
            self.full.read_text(),
            json.dumps(expected, indent=2, ensure_ascii=False),
        )
        # Bag 1 weapon from the independent Cairo fixture in loot_reference.cairo.
        self.assertEqual(
            json.loads(concise.read_text())["1"]["weapon"],
            {
                "id": 10,
                "greatness": 20,
                "suffix_id": 4,
                "name_prefix_id": 33,
                "name_suffix_id": 12,
            },
        )

    def test_cli_inspection_preserves_numeric_ids_on_stdout_and_in_files(self):
        canonical = json.loads((ROOT / "tests/verbose_loot.json").read_text())["1"]
        ids = {
            "item_id": 10,
            "suffix_id": 4,
            "name_prefix_id": 33,
            "name_suffix_id": 12,
        }
        for selection in (("--bag", "1"), ("--range", "1", "1")):
            for to_file in (False, True):
                with self.subTest(selection=selection, to_file=to_file):
                    args = [sys.executable, str(ROOT / "scripts/loot.py"), *selection]
                    if to_file:
                        args += ["--output", str(self.full)]
                    result = subprocess.run(args, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    data = json.loads(
                        self.full.read_text() if to_file else result.stdout
                    )
                    self.assertEqual(
                        data["1"]["weapon"], {**canonical["weapon"], **ids}
                    )
                    for item in data["1"].values():
                        self.assertEqual(set(item), set(canonical["weapon"]) | set(ids))

    def test_cli_fixture_schema_on_stdout_and_conflicting_formats(self):
        args = [
            sys.executable,
            str(ROOT / "scripts/loot.py"),
            "--bag",
            "1",
            "--fixture-schema",
        ]
        result = subprocess.run(args, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        canonical = json.loads((ROOT / "tests/verbose_loot.json").read_text())
        self.assertEqual(
            result.stdout, json.dumps({"1": canonical["1"]}, indent=2) + "\n"
        )
        result = subprocess.run([*args, "--names-only"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not allowed with argument", result.stderr)

    def test_contract_version_matches_package_and_lockfile(self):
        package = tomllib.loads((ROOT / "Scarb.toml").read_text())["package"]
        versions = re.findall(
            r"^\s*pub\s+const\s+VERSION\s*:\s*felt252\s*=\s*'([^']+)'\s*;",
            (ROOT / "src/contract.cairo").read_text(),
            re.MULTILINE,
        )
        self.assertEqual(
            len(versions), 1, "Expected exactly one contract VERSION literal"
        )
        self.assertEqual(
            versions[0],
            package["version"],
            "Bump Scarb.toml and contract.cairo VERSION together",
        )
        # Cairo's by_id_metadata_and_errors_match_old_library test checks that
        # the cache dispatcher returns the same release version as the library.
        locked = [
            entry["version"]
            for entry in tomllib.loads((ROOT / "Scarb.lock").read_text())["package"]
            if entry["name"] == package["name"]
        ]
        self.assertEqual(
            locked, [package["version"]], "Refresh Scarb.lock with scarb build"
        )

    def test_casm_budget_boundary_and_missing_artifact_message(self):
        artifact = Path(self.temp.name) / "casm.json"
        cache = Path(self.temp.name) / "cache.json"
        with (
            patch.object(check_casm_size, "ARTIFACT", artifact),
            patch.object(check_casm_size, "CACHE_ARTIFACT", cache),
        ):
            with self.assertRaisesRegex(SystemExit, "scarb --release build"):
                check_casm_size.main()
            with contextlib.redirect_stdout(io.StringIO()):
                artifact.write_text(
                    json.dumps({"bytecode": [0] * check_casm_size.MAX_CASM_WORDS})
                )
                with self.assertRaisesRegex(SystemExit, "stark_loot_cache"):
                    check_casm_size.main()
                cache.write_text(
                    json.dumps({"bytecode": [0] * check_casm_size.MAX_CACHE_CASM_WORDS})
                )
                check_casm_size.main()
                for path, budget in [
                    (artifact, check_casm_size.MAX_CASM_WORDS),
                    (cache, check_casm_size.MAX_CACHE_CASM_WORDS),
                ]:
                    original = path.read_text()
                    path.write_text(json.dumps({"bytecode": [0] * (budget + 1)}))
                    with self.assertRaisesRegex(SystemExit, "exceeds"):
                        check_casm_size.main()
                    for broken in ["{", "{}", '{"bytecode": null}', '{"bytecode": []}']:
                        path.write_text(broken)
                        with self.assertRaisesRegex(
                            SystemExit, "scarb --release build"
                        ):
                            check_casm_size.main()
                    path.write_text(original)


if __name__ == "__main__":
    unittest.main()
