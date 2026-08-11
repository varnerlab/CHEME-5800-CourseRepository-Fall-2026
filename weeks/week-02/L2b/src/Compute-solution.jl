module L2bDebugging

# Reference solution for L2b. The student-facing `Compute.jl` in this folder ships as
# a stub; this file is excluded from the student bundle by release.toml.
#
# Validation is written inline rather than factored into a helper: the whole student
# contribution is meant to be this one function body.

export cargo_loading_time_minutes

"""
    cargo_loading_time_minutes(cargo_tonnes, loading_rate_kg_min) -> Float64

Return the time in min needed to load `cargo_tonnes` tonnes of freight at a
sustained rate of `loading_rate_kg_min` kilograms per minute.
"""
function cargo_loading_time_minutes(cargo_tonnes::Real, loading_rate_kg_min::Real)::Float64
    isfinite(cargo_tonnes) || throw(ArgumentError("cargo_tonnes must be finite"))
    cargo_tonnes > 0 || throw(ArgumentError("cargo_tonnes must be positive"))
    isfinite(loading_rate_kg_min) || throw(ArgumentError("loading_rate_kg_min must be finite"))
    loading_rate_kg_min > 0 || throw(ArgumentError("loading_rate_kg_min must be positive"))

    cargo_kg = 1000.0 * cargo_tonnes # 1 tonne = 1000 kg
    return Float64(cargo_kg / loading_rate_kg_min)
end

end
