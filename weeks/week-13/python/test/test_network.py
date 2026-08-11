from __future__ import annotations

import json
import math
from pathlib import Path
import unittest

from cheme5800_mcp.network import (
    DATA_PATH,
    NETWORK_ID,
    check_flux_balance,
    load_network,
    summarize_network,
)


class NetworkCoreTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = json.loads(Path(DATA_PATH).read_text(encoding="utf-8"))

    def test_summary_preserves_order_and_dimensions(self) -> None:
        summary = summarize_network()
        self.assertEqual(summary["network_id"], NETWORK_ID)
        self.assertEqual(summary["number_of_species"], 18)
        self.assertEqual(summary["number_of_reactions"], 19)
        self.assertEqual(summary["reactions"][:5], ["v1", "v2", "v3", "v4", "v5"])

    def test_reference_balanced_flux_has_zero_residual(self) -> None:
        result = check_flux_balance(self.payload["reference_fluxes"]["balanced"])
        self.assertTrue(result["is_balanced"])
        self.assertEqual(result["max_abs_residual"], 0.0)
        self.assertEqual(result["residual"], [0.0] * 18)

    def test_reference_imbalanced_flux_identifies_urea_residual(self) -> None:
        result = check_flux_balance(self.payload["reference_fluxes"]["imbalanced"])
        self.assertFalse(result["is_balanced"])
        self.assertEqual(result["max_abs_residual"], 1.0)
        urea_index = result["species_order"].index("M_Urea_c")
        self.assertEqual(result["residual"][urea_index], 1.0)

    def test_bad_flux_length_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "19 values"):
            check_flux_balance([0.0] * 18)

    def test_nonfinite_flux_is_rejected(self) -> None:
        flux = [0.0] * 19
        flux[4] = math.inf
        with self.assertRaisesRegex(ValueError, r"flux\[4\] must be finite"):
            check_flux_balance(flux)

    def test_unknown_network_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "unknown network_id"):
            load_network("genome-scale-model")

    def test_negative_tolerance_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "non-negative"):
            check_flux_balance([0.0] * 19, tolerance=-1.0)


if __name__ == "__main__":
    unittest.main()
