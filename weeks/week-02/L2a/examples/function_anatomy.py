#!/usr/bin/env python3
"""Runnable Python companion for L2a's function anatomy comparison."""


def fahrenheit_to_celsius(temperature_f: float) -> float:
    """Convert a temperature from degrees Fahrenheit to degrees Celsius.

    Args:
        temperature_f: Temperature in degrees Fahrenheit.

    Returns:
        The corresponding temperature in degrees Celsius.
    """
    # Shift the Fahrenheit scale so that 32 F maps to 0 C, then rescale
    # each Fahrenheit degree by the ratio 5/9.
    temperature_c = (temperature_f - 32.0) * (5.0 / 9.0)
    return temperature_c


def main() -> None:
    """Run one temperature-conversion example and print the result."""
    # Use an exact reference case so the result is easy to verify: 68 F = 20 C.
    temperature_f = 68.0

    # Reuse the conversion interface instead of duplicating its formula in main.
    temperature_c = fahrenheit_to_celsius(temperature_f)

    # Keep one decimal place and label both physical units in the output.
    print(f"{temperature_f:.1f} F = {temperature_c:.1f} C")


# Run the example only when this file is the command-line entry point. Importing
# the module defines the functions without printing output.
if __name__ == "__main__":
    main()
