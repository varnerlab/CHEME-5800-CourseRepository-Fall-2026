import unittest
from pathlib import Path

from shift_data import load_bundle, validate_rows


LECTURE_ROOT = Path(__file__).resolve().parent.parent


class ShiftDataTests(unittest.TestCase):
    def test_committed_bundle_is_valid(self):
        result = load_bundle(
            LECTURE_ROOT / "data" / "fulfillment-shifts.csv",
            LECTURE_ROOT / "data" / "fulfillment-metadata.json",
        )
        self.assertTrue(result["valid"])
        self.assertEqual(len(result["rows"]), 8)
        self.assertIn("synthetic", result["metadata"]["provenance"].lower())

    def test_invalid_example_reports_every_failure_class(self):
        result = load_bundle(
            LECTURE_ROOT / "data" / "fulfillment-shifts-invalid-example.csv",
            LECTURE_ROOT / "data" / "fulfillment-metadata.json",
        )
        self.assertFalse(result["valid"])
        joined = " | ".join(result["errors"])
        self.assertIn("shift_id values must be unique", joined)
        self.assertIn("zone must be nonempty", joined)
        self.assertIn("zone must be one of", joined)
        self.assertIn("orders_completed", joined)
        self.assertIn("labor_hours", joined)
        self.assertIn("picking_error_fraction", joined)

    def test_duplicate_shift_ids_are_rejected(self):
        rows = [
            {
                "shift_id": "S01",
                "zone": "East",
                "orders_completed": "92",
                "labor_hours": "8.0",
                "picking_error_fraction": "0.021",
            }
        ] * 2
        self.assertIn("shift_id values must be unique", validate_rows(rows))


if __name__ == "__main__":
    unittest.main()
