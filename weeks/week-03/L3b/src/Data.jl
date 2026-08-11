module L3bData

import CSV
import DataFrames
import JSON
import SHA

export file_sha256, load_shift_bundle, validate_shift_records

const REQUIRED_SHIFT_COLUMNS = [
    :shift_id,
    :zone,
    :orders_completed,
    :labor_hours,
    :picking_error_fraction,
]

const ALLOWED_ZONES = Set(["East", "West"])

"""Return a lowercase SHA-256 digest for a file without modifying it."""
file_sha256(path::AbstractString)::String = bytes2hex(open(SHA.sha256, path))

function _valid_number(value; positive::Bool = false, nonnegative::Bool = false,
                       fraction::Bool = false, integral::Bool = false)
    value isa Real || return false
    value isa Bool && return false
    isfinite(value) || return false
    positive && value <= 0 && return false
    nonnegative && value < 0 && return false
    fraction && !(0 <= value <= 1) && return false
    integral && value != round(value) && return false
    return true
end

"""Validate the schema and operational constraints of the L3b shift table."""
function validate_shift_records(table::DataFrames.AbstractDataFrame)::NamedTuple
    errors = String[]
    available = Set(Symbol.(names(table)))
    missing_columns = [column for column in REQUIRED_SHIFT_COLUMNS if column ∉ available]

    if !isempty(missing_columns)
        push!(errors, "missing required columns: $(join(string.(missing_columns), ", "))")
        return (valid = false, errors = errors)
    end

    isempty(table) && push!(errors, "dataset must contain at least one row")
    shift_ids = String[]

    for (row_index, row) in enumerate(eachrow(table))
        shift_id = ismissing(row.shift_id) ? "" : strip(string(row.shift_id))
        zone = ismissing(row.zone) ? "" : strip(string(row.zone))
        isempty(shift_id) && push!(errors, "row $(row_index): shift_id must be nonempty")
        push!(shift_ids, shift_id)

        if isempty(zone)
            push!(errors, "row $(row_index): zone must be nonempty")
        elseif zone ∉ ALLOWED_ZONES
            push!(errors,
                  "row $(row_index): zone must be one of $(join(sort(collect(ALLOWED_ZONES)), ", "))")
        end

        _valid_number(row.orders_completed; nonnegative = true, integral = true) ||
            push!(errors, "row $(row_index): orders_completed must be a finite nonnegative whole number")
        _valid_number(row.labor_hours; positive = true) ||
            push!(errors, "row $(row_index): labor_hours must be finite and positive")
        _valid_number(row.picking_error_fraction; fraction = true) ||
            push!(errors, "row $(row_index): picking_error_fraction must be finite and between 0 and 1")
    end

    nonempty_ids = filter(!isempty, shift_ids)
    length(unique(nonempty_ids)) == length(nonempty_ids) ||
        push!(errors, "shift_id values must be unique")

    return (valid = isempty(errors), errors = errors)
end

"""Load the committed CSV/JSON pair and validate both its rows and metadata."""
function load_shift_bundle(csv_path::AbstractString, metadata_path::AbstractString)::NamedTuple
    shifts = CSV.read(csv_path, DataFrames.DataFrame)
    metadata = JSON.parsefile(metadata_path)
    errors = copy(validate_shift_records(shifts).errors)

    if !haskey(metadata, "expected_rows")
        push!(errors, "metadata must declare expected_rows")
    elseif metadata["expected_rows"] != DataFrames.nrow(shifts)
        push!(errors, "metadata expected_rows does not match the CSV row count")
    end

    return (
        shifts = shifts,
        metadata = metadata,
        validation = (valid = isempty(errors), errors = errors),
    )
end

end
