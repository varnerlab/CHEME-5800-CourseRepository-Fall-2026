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
    # Choose a sample temperature with a known Celsius equivalent.
    temperature_f = 68.0

    # Call the conversion function and store its return value.
    temperature_c = fahrenheit_to_celsius(temperature_f)

    # Display the input and output values with their units.
    print(f"{temperature_f:.1f} F = {temperature_c:.1f} C")


# Run main only when this file is executed from the command line. Importing the
# file in the Python REPL defines the functions without running the example.
if __name__ == "__main__":
    main()
