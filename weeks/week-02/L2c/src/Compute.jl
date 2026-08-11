module L2cCollections

import Statistics: mean

export codepoint_hex, measurement_summary

"""Summarize a nonempty finite numerical vector without changing it."""
function measurement_summary(values::AbstractVector{<:Real})::NamedTuple
    isempty(values) && throw(ArgumentError("values may not be empty"))
    all(isfinite, values) || throw(ArgumentError("values must be finite"))
    return (
        count = length(values),
        minimum = Float64(minimum(values)),
        maximum = Float64(maximum(values)),
        mean = Float64(mean(values)),
    )
end

"""Format a character's Unicode code point as uppercase U+XXXX."""
function codepoint_hex(character::Char)::String
    hexadecimal = uppercase(string(UInt32(character); base = 16, pad = 4))
    return "U+$(hexadecimal)"
end

end

