"""Pure computation layer for the urea-cycle teaching network.

This module intentionally has no MCP imports. Numerical behavior can therefore be
tested without a protocol client, subprocess, network connection, or model account.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
import math
from numbers import Real
from pathlib import Path
from typing import Any

NETWORK_ID = "urea-cycle"
NETWORK_URI = "cheme://metabolic-network/urea-cycle"
DATA_PATH = Path(__file__).resolve().parents[3] / "data" / "urea-cycle-network.json"


@dataclass(frozen=True)
class MetabolicNetwork:
    network_id: str
    name: str
    description: str
    species: tuple[str, ...]
    reactions: tuple[dict[str, Any], ...]
    stoichiometric_matrix: tuple[tuple[float, ...], ...]
    raw: dict[str, Any]

    @property
    def reaction_ids(self) -> tuple[str, ...]:
        return tuple(str(reaction["id"]) for reaction in self.reactions)


def _require_unique_strings(values: Any, field: str) -> tuple[str, ...]:
    if not isinstance(values, list) or not values:
        raise ValueError(f"{field} must be a non-empty array")
    if not all(isinstance(value, str) and value for value in values):
        raise ValueError(f"{field} must contain non-empty strings")
    if len(set(values)) != len(values):
        raise ValueError(f"{field} must not contain duplicates")
    return tuple(values)


def _as_finite_number(value: Any, location: str) -> float:
    if isinstance(value, bool) or not isinstance(value, Real):
        raise ValueError(f"{location} must be numeric")
    number = float(value)
    if not math.isfinite(number):
        raise ValueError(f"{location} must be finite")
    return number


def _validate_payload(payload: Any) -> MetabolicNetwork:
    if not isinstance(payload, dict):
        raise ValueError("network fixture must be a JSON object")
    if payload.get("network_id") != NETWORK_ID:
        raise ValueError(f"network fixture must identify {NETWORK_ID!r}")

    species = _require_unique_strings(payload.get("species"), "species")
    reactions_value = payload.get("reactions")
    if not isinstance(reactions_value, list) or not reactions_value:
        raise ValueError("reactions must be a non-empty array")
    if not all(isinstance(reaction, dict) for reaction in reactions_value):
        raise ValueError("each reaction must be an object")
    reaction_ids = _require_unique_strings(
        [reaction.get("id") for reaction in reactions_value], "reaction ids"
    )

    rows = payload.get("stoichiometric_matrix")
    if not isinstance(rows, list) or len(rows) != len(species):
        raise ValueError("stoichiometric_matrix must have one row per species")
    matrix: list[tuple[float, ...]] = []
    for row_index, row in enumerate(rows):
        if not isinstance(row, list) or len(row) != len(reaction_ids):
            raise ValueError(
                "each stoichiometric_matrix row must have one value per reaction"
            )
        matrix.append(
            tuple(
                _as_finite_number(value, f"stoichiometric_matrix[{row_index}][{column_index}]")
                for column_index, value in enumerate(row)
            )
        )

    return MetabolicNetwork(
        network_id=NETWORK_ID,
        name=str(payload.get("name", NETWORK_ID)),
        description=str(payload.get("description", "")),
        species=species,
        reactions=tuple(reactions_value),
        stoichiometric_matrix=tuple(matrix),
        raw=payload,
    )


def load_network(network_id: str = NETWORK_ID) -> MetabolicNetwork:
    """Load and validate the one read-only network shipped with this server."""
    if network_id != NETWORK_ID:
        raise ValueError(
            f"unknown network_id {network_id!r}; supported network_id is {NETWORK_ID!r}"
        )
    with DATA_PATH.open(encoding="utf-8") as stream:
        return _validate_payload(json.load(stream))


def summarize_network(network_id: str = NETWORK_ID) -> dict[str, Any]:
    """Return dimensions and named species/reactions for a network."""
    network = load_network(network_id)
    return {
        "network_id": network.network_id,
        "name": network.name,
        "number_of_species": len(network.species),
        "number_of_reactions": len(network.reactions),
        "species": list(network.species),
        "reactions": list(network.reaction_ids),
    }


def check_flux_balance(
    flux: list[float],
    tolerance: float = 1.0e-9,
    network_id: str = NETWORK_ID,
) -> dict[str, Any]:
    """Compute ``S*v`` and report whether every residual meets the tolerance."""
    network = load_network(network_id)
    tolerance_value = _as_finite_number(tolerance, "tolerance")
    if tolerance_value < 0:
        raise ValueError("tolerance must be non-negative")
    if not isinstance(flux, list):
        raise ValueError("flux must be an array")
    if len(flux) != len(network.reactions):
        raise ValueError(
            f"flux must contain {len(network.reactions)} values; received {len(flux)}"
        )
    values = [
        _as_finite_number(value, f"flux[{index}]") for index, value in enumerate(flux)
    ]

    residual = [
        sum(coefficient * value for coefficient, value in zip(row, values, strict=True))
        for row in network.stoichiometric_matrix
    ]
    max_abs_residual = max(abs(value) for value in residual)
    return {
        "network_id": network.network_id,
        "reaction_order": list(network.reaction_ids),
        "species_order": list(network.species),
        "residual": residual,
        "max_abs_residual": max_abs_residual,
        "tolerance": tolerance_value,
        "is_balanced": max_abs_residual <= tolerance_value,
    }
