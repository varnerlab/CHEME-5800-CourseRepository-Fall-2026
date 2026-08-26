"""Regression tests for the L2b Python cargo-loading implementation."""

import math
import unittest

from cargo_loading import cargo_loading_time_minutes


class CargoLoadingTests(unittest.TestCase):
    """Check valid calculations and each category of invalid input."""

    def test_reference_case(self) -> None:
        """Confirm the implementation agrees with the known reference case."""
        # A mass of two metric tonnes is 2000 kg and requires 8 min at 250 kg/min.
        self.assertEqual(cargo_loading_time_minutes(2.0, 250.0), 8.0)

    def test_integer_inputs(self) -> None:
        """Confirm integer inputs are accepted and return the correct result."""
        # A mass of one metric tonne is 1000 kg and requires 5 min at 200 kg/min.
        self.assertEqual(cargo_loading_time_minutes(1, 200), 5.0)

    def test_invalid_values(self) -> None:
        """Confirm non-positive and non-finite values raise ``ValueError``."""
        # Each tuple represents one call with an invalid mass or loading rate.
        for arguments in ((0, 100), (1, -2), (1, math.inf)):
            # subTest reports the specific tuple if one case fails.
            with self.subTest(arguments=arguments):
                with self.assertRaises(ValueError):
                    cargo_loading_time_minutes(*arguments)

    def test_invalid_type(self) -> None:
        """Confirm Boolean input is not accepted as numerical cargo mass."""
        # Python treats bool as a subclass of int, so the function must reject
        # Boolean values explicitly.
        with self.assertRaises(TypeError):
            cargo_loading_time_minutes(True, 100)


# Run the test suite when this file is executed directly. Test discovery also
# imports this module and runs the same CargoLoadingTests class.
if __name__ == "__main__":
    unittest.main()
