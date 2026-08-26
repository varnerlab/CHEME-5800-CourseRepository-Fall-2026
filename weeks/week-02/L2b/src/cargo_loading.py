"""Python implementation of the cargo-loading interface used in L2b.

The implementation follows the same unit and input contract as the Julia
function: cargo is supplied in metric tonnes, loading rate is supplied in kilograms
per minute, and both values must be finite and strictly positive.
"""

from __future__ import annotations

import math


def _positive_finite(name: str, value: float) -> float:
    """Validate one numerical argument and return it as a ``float``.

    Args:
        name: Argument name to include in an error message.
        value: Numerical value to validate.

    Returns:
        The validated value converted to a ``float``.

    Raises:
        TypeError: If ``value`` is a Boolean or is not an integer or float.
        ValueError: If ``value`` is not finite or is not strictly positive.
    """
    # Check the input type before converting it. Boolean values are rejected
    # explicitly because bool is a subclass of int in Python.
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise TypeError(f"{name} must be a real number")

    # Normalize accepted integer and floating-point inputs to one return type.
    converted = float(value)

    # Reject values outside the numerical domain supported by the model.
    if not math.isfinite(converted) or converted <= 0.0:
        raise ValueError(f"{name} must be finite and positive")

    return converted


def cargo_loading_time_minutes(
    cargo_tonnes: float, loading_rate_kg_min: float
) -> float:
    """Calculate the time needed to load cargo onto a trailer.

    Args:
        cargo_tonnes: Cargo mass in metric tonnes.
        loading_rate_kg_min: Sustained loading rate in kilograms per minute.

    Returns:
        Loading time in minutes.

    Raises:
        TypeError: If either argument has an unsupported type.
        ValueError: If either argument is not finite and strictly positive.
    """

    # Validate each input at the function boundary and normalize it to float.
    cargo = _positive_finite("cargo_tonnes", cargo_tonnes)
    rate = _positive_finite("loading_rate_kg_min", loading_rate_kg_min)

    # Convert metric tonnes to kilograms so the cargo and loading-rate units agree.
    cargo_kg = 1000.0 * cargo

    # Apply t = m/r using kilograms and kilograms per minute.
    loading_time_minutes = cargo_kg / rate
    return loading_time_minutes
