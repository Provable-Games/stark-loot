import json
import unittest
from pathlib import Path

from scripts.loot import LootGenerator, VERBOSE_FIELDS


FIXTURE_PATH = Path(__file__).with_name("loot.json")
VERBOSE_FIXTURE_PATH = Path(__file__).with_name("verbose_loot.json")


def load_fixture():
    with FIXTURE_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    flat = {}
    for entry in data:
        for bag_id_str, items in entry.items():
            flat[int(bag_id_str)] = items
    return flat


class LootScriptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generator = LootGenerator()
        cls.fixture = load_fixture()
        cls.verbose_fixture = json.loads(VERBOSE_FIXTURE_PATH.read_text(encoding="utf-8"))

    def test_all_bag_names_match_fixture(self):
        for bag_id, expected_names in self.fixture.items():
            with self.subTest(bag_id=bag_id):
                actual = self.generator.get_bag_strings(bag_id)
                self.assertEqual(expected_names, actual)

    def test_metadata_fields_align_with_names(self):
        # Original Loot includes bag 8000; validate its metadata as well as its names.
        self.assertEqual(set(self.verbose_fixture), {str(i) for i in range(1, 8001)})
        for bag_id in range(1, 8001):
            bag = self.generator.get_bag_metadata(bag_id)
            expected_bag = self.verbose_fixture[str(bag_id)]
            self.assertEqual(set(expected_bag), set(bag), f"bag {bag_id} slot keys")
            for slot, meta in bag.items():
                with self.subTest(bag_id=bag_id, slot=slot):
                    # Reuse this loop's generation to validate every committed metadata field,
                    # including hidden modifiers and preview strings outside the CI sample.
                    self.assertEqual(
                        expected_bag[slot], {field: meta[field] for field in VERBOSE_FIELDS},
                        "committed verbose metadata mismatch",
                    )
                    current = meta["current_name"]
                    expected_current = self.fixture[bag_id][slot]
                    self.assertEqual(current, expected_current)

                    expected_final = f"\"{meta['name_prefix']} {meta['name_suffix']}\" {meta['item_name']} {meta['suffix']} +1"
                    self.assertEqual(meta["final_name"], expected_final)
                    self.assertTrue(meta["final_name"].endswith(" +1"))

                    has_suffix = meta["greatness"] > 14
                    suffix_phrase = f" {meta['suffix']}"
                    self.assertEqual(has_suffix, suffix_phrase in current)

                    has_name = meta["greatness"] >= 19
                    legendary_name = f"\"{meta['name_prefix']} {meta['name_suffix']}\""
                    self.assertEqual(has_name, legendary_name in current)

                    is_plus_one = meta["greatness"] == 20
                    self.assertEqual(is_plus_one, current.endswith(" +1"))

                    if meta["greatness"] <= 14:
                        self.assertEqual(current, meta["item_name"])
                    elif 15 <= meta["greatness"] <= 18:
                        self.assertTrue(current.startswith(meta["item_name"]))
                        self.assertTrue(current.endswith(meta["suffix"]))
                    elif meta["greatness"] == 19:
                        self.assertTrue(current.startswith(legendary_name))
                        self.assertFalse(current.endswith(" +1"))


if __name__ == "__main__":
    unittest.main()
