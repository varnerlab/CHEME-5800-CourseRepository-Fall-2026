"""Tests for the Week 2 Python interface comparison."""

import math
import unittest

from cargo_loading import cargo_loading_time_minutes


class CargoLoadingTests(unittest.TestCase):
    def test_reference_case(self) -> None:
        self.assertEqual(cargo_loading_time_minutes(2.0, 250.0), 8.0)

    def test_integer_inputs(self) -> None:
        self.assertEqual(cargo_loading_time_minutes(1, 200), 5.0)

    def test_invalid_values(self) -> None:
        for arguments in ((0, 100), (1, -2), (1, math.inf)):
            with self.subTest(arguments=arguments):
                with self.assertRaises(ValueError):
                    cargo_loading_time_minutes(*arguments)

    def test_invalid_type(self) -> None:
        with self.assertRaises(TypeError):
            cargo_loading_time_minutes(True, 100)


if __name__ == "__main__":
    unittest.main()

