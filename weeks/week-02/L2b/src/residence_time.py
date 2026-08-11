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


def residence_time_minutes(volume_l: float, flow_ml_min: float) -> float:
    """Return residence time in min for volume in L and flow in mL/min."""

    volume = _positive_finite("volume_l", volume_l)
    flow = _positive_finite("flow_ml_min", flow_ml_min)
    return 1000.0 * volume / flow

