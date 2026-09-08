import copy
import unittest

from scripts.check_packing_benchmarks import CONFIG_KEYS, check_results


class PackingBenchmarkTests(unittest.TestCase):
    def setUp(self):
        self.manifest = {"probe": "Probe"}
        self.baseline = {key: "pinned" for key in CONFIG_KEYS}
        self.baseline["source_sha256"] = {"src/core.cairo": "old"}
        self.baseline["cases"] = {"probe": {
            "contract": "Probe",
            "measurements": {
                mode: {"entrypoint_l2_gas": 100, "trace": {"steps": 10}}
                for mode in ("sierra-gas", "cairo-steps")
            },
        }}

    def test_identical_metrics_allow_provenance_changes(self):
        actual = copy.deepcopy(self.baseline)
        actual["source_sha256"]["src/core.cairo"] = "new"
        check_results(actual, self.baseline, self.manifest)

    def test_deterministic_gas_or_resource_changes_fail(self):
        for mode in ("sierra-gas", "cairo-steps"):
            for field in ("gas", "resources"):
                with self.subTest(mode=mode, field=field):
                    actual = copy.deepcopy(self.baseline)
                    measurement = actual["cases"]["probe"]["measurements"][mode]
                    if field == "gas":
                        measurement["entrypoint_l2_gas"] += 1
                    else:
                        measurement["trace"]["steps"] += 1
                    with self.assertRaisesRegex(ValueError, "Gas or resources changed for: probe"):
                        check_results(actual, self.baseline, self.manifest)

    def test_incomplete_or_extra_cases_fail_on_either_side(self):
        for label in ("actual", "baseline"):
            for extra in (False, True):
                actual, baseline = copy.deepcopy(self.baseline), copy.deepcopy(self.baseline)
                result = actual if label == "actual" else baseline
                if extra:
                    result["cases"]["extra"] = result["cases"]["probe"]
                else:
                    del result["cases"]["probe"]
                with self.assertRaisesRegex(ValueError, "case set differs"):
                    check_results(actual, baseline, self.manifest)

    def test_configuration_and_probe_identity_changes_fail(self):
        for key in CONFIG_KEYS:
            actual = copy.deepcopy(self.baseline)
            actual[key] = "changed"
            with self.assertRaisesRegex(ValueError, "configuration changed"):
                check_results(actual, self.baseline, self.manifest)
        actual = copy.deepcopy(self.baseline)
        actual["cases"]["probe"]["contract"] = "OtherProbe"
        with self.assertRaisesRegex(ValueError, "probe contract differs"):
            check_results(actual, self.baseline, self.manifest)
        actual = copy.deepcopy(self.baseline)
        del actual["cases"]["probe"]["measurements"]["cairo-steps"]
        with self.assertRaisesRegex(ValueError, "accounting modes differ"):
            check_results(actual, self.baseline, self.manifest)

    def test_host_architecture_is_provenance_but_compiler_changes_fail(self):
        baseline = copy.deepcopy(self.baseline)
        baseline["scarb"] = (
            "scarb 2.20.1 (dd18779a1)\ncairo: 2.20.0\nsierra: 1.9.3\n"
            "arch: x86_64-unknown-linux-gnu"
        )
        actual = copy.deepcopy(baseline)
        actual["scarb"] = actual["scarb"].replace(
            "x86_64-unknown-linux-gnu", "aarch64-apple-darwin",
        )
        check_results(actual, baseline, self.manifest)
        for before, after in (
            ("2.20.1", "2.20.2"), ("dd18779a1", "different-build"),
            ("cairo: 2.20.0", "cairo: 2.20.1"), ("sierra: 1.9.3", "sierra: 1.9.4"),
        ):
            with self.subTest(compiler_change=before):
                changed = copy.deepcopy(actual)
                changed["scarb"] = changed["scarb"].replace(before, after)
                with self.assertRaisesRegex(ValueError, "configuration changed: scarb"):
                    check_results(changed, baseline, self.manifest)
        actual["scarb"] += "\nnew compiler option: enabled"
        with self.assertRaisesRegex(ValueError, "configuration changed: scarb"):
            check_results(actual, baseline, self.manifest)
