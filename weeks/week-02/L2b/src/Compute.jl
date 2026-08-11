module L2bDebugging

export cargo_loading_time_minutes

"""
    cargo_loading_time_minutes(cargo_tonnes, loading_rate_kg_min) -> Float64

Return the time in min needed to load `cargo_tonnes` tonnes of freight at a
sustained rate of `loading_rate_kg_min` kilograms per minute.

The contract: both arguments must be finite and strictly positive; anything else
raises an `ArgumentError` naming the offending argument. Note the unit mismatch —
cargo arrives in tonnes and the rate in kg/min, so a conversion is required before
dividing.
"""
function cargo_loading_time_minutes(cargo_tonnes::Real, loading_rate_kg_min::Real)::Float64

    # TODO 1: validate the inputs.
    #   Throw an ArgumentError naming the argument if either cargo_tonnes or
    #   loading_rate_kg_min is not finite, or is not strictly positive.
    #   See `isfinite` and `throw`.

    # TODO 2: return the loading time in minutes.
    #   t = m/r, but the units do not line up as given: 1 tonne = 1000 kg.
    #   Convert, divide, and return a Float64.

    throw(ErrorException("Oooops! The `cargo_loading_time_minutes(...)` function is " *
                         "not implemented yet - we'd better fix that."))
end

end
