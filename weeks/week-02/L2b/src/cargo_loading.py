"""Reference Python implementation for the Week 2 interface comparison."""

from __future__ import annotations

import math


def _positive_finite(name: str, value: float) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise TypeError(f"{name} must be a real number")
    converted = float(value)
    if not math.isfinite(converted) or converted <= 0.0:
        raise ValueError(f"{name} must be finite and positive")
    return converted


def cargo_loading_time_minutes(cargo_tonnes: float, loading_rate_kg_min: float) -> float:
    """Return loading time in min for cargo in tonnes and rate in kg/min."""

    cargo = _positive_finite("cargo_tonnes", cargo_tonnes)
    rate = _positive_finite("loading_rate_kg_min", loading_rate_kg_min)
    return 1000.0 * cargo / rate

