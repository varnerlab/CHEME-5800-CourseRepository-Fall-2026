module L1dFloatingPoint

export float64_report

"""Return the sign, exponent, fraction, and local spacing for a Float64 value."""
function float64_report(value::Float64)::NamedTuple
    bits = bitstring(value)
    return (
        value = value,
        sign_bit = bits[1],
        exponent_bits = bits[2:12],
        fraction_bits = bits[13:64],
        spacing = eps(value),
    )
end

end

