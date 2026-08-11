import unittest
from pathlib import Path

from reactor_data import load_bundle, validate_rows


LECTURE_ROOT = Path(__file__).resolve().parent.parent


class ReactorDataTests(unittest.TestCase):
    def test_committed_bundle_is_valid(self):
        result = load_bundle(
            LECTURE_ROOT / "data" / "reactor-runs.csv",
            LECTURE_ROOT / "data" / "reactor-metadata.json",
        )
        self.assertTrue(result["valid"])
        self.assertEqual(len(result["rows"]), 8)
        self.assertIn("synthetic", result["metadata"]["provenance"].lower())

    def test_invalid_data_example_reports_both_physical_errors(self):
        result = load_bundle(
            LECTURE_ROOT / "data" / "reactor-runs-invalid-example.csv",
            LECTURE_ROOT / "data" / "reactor-metadata.json",
        )
        self.assertFalse(result["valid"])
        self.assertTrue(any("residence_time_min" in error for error in result["errors"]))
        self.assertTrue(any("conversion_fraction" in error for error in result["errors"]))

    def test_duplicate_run_ids_are_rejected(self):
        rows = [
            {
                "run_id": "R01",
                "catalyst": "A",
                "temperature_K": "330",
                "residence_time_min": "4",
                "conversion_fraction": "0.62",
            }
        ] * 2
        self.assertIn("run_id values must be unique", validate_rows(rows))


if __name__ == "__main__":
    unittest.main()
