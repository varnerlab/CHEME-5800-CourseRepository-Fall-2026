module L3bData

import CSV
import DataFrames
import JSON
import SHA

export file_sha256, load_reactor_bundle, validate_reactor_runs

const REQUIRED_REACTOR_COLUMNS = [
    :run_id,
    :catalyst,
    :temperature_K,
    :residence_time_min,
    :conversion_fraction,
]

"""Return a lowercase SHA-256 digest for a file without modifying it."""
file_sha256(path::AbstractString)::String = bytes2hex(open(SHA.sha256, path))

function _valid_number(value; positive::Bool = false, fraction::Bool = false)
    value isa Real || return false
    value isa Bool && return false
    isfinite(value) || return false
    positive && value <= 0 && return false
    fraction && !(0 <= value <= 1) && return false
    return true
end

"""Validate the schema and physical constraints of the L3b reactor table."""
function validate_reactor_runs(table::DataFrames.AbstractDataFrame)::NamedTuple
    errors = String[]
    available = Set(Symbol.(names(table)))
    missing_columns = [column for column in REQUIRED_REACTOR_COLUMNS if column ∉ available]

    if !isempty(missing_columns)
        push!(errors, "missing required columns: $(join(string.(missing_columns), ", "))")
        return (valid = false, errors = errors)
    end

    isempty(table) && push!(errors, "dataset must contain at least one row")
    run_ids = String[]

    for (row_index, row) in enumerate(eachrow(table))
        run_id = ismissing(row.run_id) ? "" : strip(string(row.run_id))
        catalyst = ismissing(row.catalyst) ? "" : strip(string(row.catalyst))
        isempty(run_id) && push!(errors, "row $(row_index): run_id must be nonempty")
        isempty(catalyst) && push!(errors, "row $(row_index): catalyst must be nonempty")
        push!(run_ids, run_id)

        _valid_number(row.temperature_K; positive = true) ||
            push!(errors, "row $(row_index): temperature_K must be finite and positive")
        _valid_number(row.residence_time_min; positive = true) ||
            push!(errors, "row $(row_index): residence_time_min must be finite and positive")
        _valid_number(row.conversion_fraction; fraction = true) ||
            push!(errors, "row $(row_index): conversion_fraction must be finite and between 0 and 1")
    end

    nonempty_ids = filter(!isempty, run_ids)
    length(unique(nonempty_ids)) == length(nonempty_ids) ||
        push!(errors, "run_id values must be unique")

    return (valid = isempty(errors), errors = errors)
end

"""Load the committed CSV/JSON pair and validate both its rows and metadata."""
function load_reactor_bundle(csv_path::AbstractString, metadata_path::AbstractString)::NamedTuple
    runs = CSV.read(csv_path, DataFrames.DataFrame)
    metadata = JSON.parsefile(metadata_path)
    errors = copy(validate_reactor_runs(runs).errors)

    if !haskey(metadata, "expected_rows")
        push!(errors, "metadata must declare expected_rows")
    elseif metadata["expected_rows"] != DataFrames.nrow(runs)
        push!(errors, "metadata expected_rows does not match the CSV row count")
    end

    return (
        runs = runs,
        metadata = metadata,
        validation = (valid = isempty(errors), errors = errors),
    )
end

end
