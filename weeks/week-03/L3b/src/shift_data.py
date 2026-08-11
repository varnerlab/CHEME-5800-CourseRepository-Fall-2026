"""Standard-library Python comparison for the CHEME 5800 L3b data contract."""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path
from typing import Any

REQUIRED_COLUMNS = (
    "shift_id",
    "zone",
    "orders_completed",
    "labor_hours",
    "picking_error_fraction",
)

ALLOWED_ZONES = ("East", "West")


def validate_rows(rows: list[dict[str, str]]) -> list[str]:
    """Return validation errors; an empty list means the rows satisfy the contract."""
    errors: list[str] = []
    if not rows:
        return ["dataset must contain at least one row"]

    missing = [name for name in REQUIRED_COLUMNS if name not in rows[0]]
    if missing:
        return [f"missing required columns: {', '.join(missing)}"]

    shift_ids: list[str] = []
    for row_index, row in enumerate(rows, start=1):
        shift_id = row["shift_id"].strip()
        zone = row["zone"].strip()
        if not shift_id:
            errors.append(f"row {row_index}: shift_id must be nonempty")
        shift_ids.append(shift_id)

        if not zone:
            errors.append(f"row {row_index}: zone must be nonempty")
        elif zone not in ALLOWED_ZONES:
            errors.append(f"row {row_index}: zone must be one of {', '.join(ALLOWED_ZONES)}")

        for field in ("orders_completed", "labor_hours", "picking_error_fraction"):
            try:
                value = float(row[field])
            except (TypeError, ValueError):
                errors.append(f"row {row_index}: {field} must be numeric")
                continue
            if not math.isfinite(value):
                errors.append(f"row {row_index}: {field} must be finite")
            elif field == "orders_completed" and (value < 0 or value != round(value)):
                errors.append(
                    f"row {row_index}: orders_completed must be a finite nonnegative whole number"
                )
            elif field == "labor_hours" and value <= 0:
                errors.append(f"row {row_index}: labor_hours must be finite and positive")
            elif field == "picking_error_fraction" and not 0 <= value <= 1:
                errors.append(
                    f"row {row_index}: picking_error_fraction must be finite and between 0 and 1"
                )

    nonempty_ids = [shift_id for shift_id in shift_ids if shift_id]
    if len(set(nonempty_ids)) != len(nonempty_ids):
        errors.append("shift_id values must be unique")
    return errors


def load_bundle(csv_path: str | Path, metadata_path: str | Path) -> dict[str, Any]:
    """Load and validate the same committed bundle used by the Julia notebook."""
    with Path(csv_path).open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    with Path(metadata_path).open(encoding="utf-8") as stream:
        metadata = json.load(stream)

    errors = validate_rows(rows)
    if metadata.get("expected_rows") != len(rows):
        errors.append("metadata expected_rows does not match the CSV row count")
    return {"rows": rows, "metadata": metadata, "valid": not errors, "errors": errors}


if __name__ == "__main__":
    lecture_root = Path(__file__).resolve().parent.parent
    result = load_bundle(
        lecture_root / "data" / "fulfillment-shifts.csv",
        lecture_root / "data" / "fulfillment-metadata.json",
    )
    print({"valid": result["valid"], "rows": len(result["rows"]), "errors": result["errors"]})
