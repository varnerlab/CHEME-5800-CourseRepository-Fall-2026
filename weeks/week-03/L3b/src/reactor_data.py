"""Standard-library Python comparison for the CHEME 5800 L3b data contract."""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path
from typing import Any

REQUIRED_COLUMNS = (
    "run_id",
    "catalyst",
    "temperature_K",
    "residence_time_min",
    "conversion_fraction",
)


def validate_rows(rows: list[dict[str, str]]) -> list[str]:
    """Return validation errors; an empty list means the rows satisfy the contract."""
    errors: list[str] = []
    if not rows:
        return ["dataset must contain at least one row"]

    missing = [name for name in REQUIRED_COLUMNS if name not in rows[0]]
    if missing:
        return [f"missing required columns: {', '.join(missing)}"]

    run_ids: list[str] = []
    for row_index, row in enumerate(rows, start=1):
        run_id = row["run_id"].strip()
        catalyst = row["catalyst"].strip()
        if not run_id:
            errors.append(f"row {row_index}: run_id must be nonempty")
        if not catalyst:
            errors.append(f"row {row_index}: catalyst must be nonempty")
        run_ids.append(run_id)

        for field in ("temperature_K", "residence_time_min", "conversion_fraction"):
            try:
                value = float(row[field])
            except (TypeError, ValueError):
                errors.append(f"row {row_index}: {field} must be numeric")
                continue
            if not math.isfinite(value):
                errors.append(f"row {row_index}: {field} must be finite")
            elif field in ("temperature_K", "residence_time_min") and value <= 0:
                errors.append(f"row {row_index}: {field} must be positive")
            elif field == "conversion_fraction" and not 0 <= value <= 1:
                errors.append(f"row {row_index}: conversion_fraction must be between 0 and 1")

    nonempty_ids = [run_id for run_id in run_ids if run_id]
    if len(set(nonempty_ids)) != len(nonempty_ids):
        errors.append("run_id values must be unique")
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
        lecture_root / "data" / "reactor-runs.csv",
        lecture_root / "data" / "reactor-metadata.json",
    )
    print({"valid": result["valid"], "rows": len(result["rows"]), "errors": result["errors"]})
