"""Tests for the optional Python Fibonacci implementation."""

import unittest

from fibonacci import fibonacci_sequence


class FibonacciSequenceTests(unittest.TestCase):
    """Verify ordinary cases, boundaries, and invalid inputs."""

    def test_base_cases(self) -> None:
        """The two smallest supported indices return complete sequences."""
        self.assertEqual(fibonacci_sequence(0), [0])
        self.assertEqual(fibonacci_sequence(1), [0, 1])

    def test_ordinary_case(self) -> None:
        """An ordinary input returns every value from F_0 through F_n."""
        self.assertEqual(
            fibonacci_sequence(10),
            [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55],
        )

    def test_largest_supported_index(self) -> None:
        """The final value at the documented upper boundary is correct."""
        self.assertEqual(fibonacci_sequence(92)[-1], 7_540_113_804_746_346_429)

    def test_out_of_range_values(self) -> None:
        """Indices outside the shared Julia/Python contract are rejected."""
        for index in (-1, 93):
            with self.subTest(index=index):
                with self.assertRaises(ValueError):
                    fibonacci_sequence(index)

    def test_invalid_types(self) -> None:
        """Non-integers and Boolean values are not sequence indices."""
        for value in (2.5, "10", True):
            with self.subTest(value=value):
                with self.assertRaises(TypeError):
                    fibonacci_sequence(value)  # type: ignore[arg-type]


if __name__ == "__main__":
    unittest.main()
