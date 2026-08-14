module L1dFloatingPoint

# Reference solution for L1d. The student-facing `Compute.jl` in this folder ships as
# a stub; this file is excluded from the student bundle by release.toml.

export float64_report

"""
    float64_report(value::Float64) -> NamedTuple

Decompose a `Float64` into its stored fields and rebuild it from them.
"""
function float64_report(value::Float64)::NamedTuple
    bits = bitstring(value)
    sign_bit = bits[1]
    exponent_bits = bits[2:12]
    fraction_bits = bits[13:64]

    S = (-1.0)^parse(Int, sign_bit)
    E = parse(UInt64, exponent_bits; base = 2)
    significand = 1.0 + sum(parse(Int, fraction_bits[k]) * 2.0^(-k) for k in 1:52)

    return (
        value = value,
        sign_bit = sign_bit,
        exponent_bits = exponent_bits,
        fraction_bits = fraction_bits,
        spacing = eps(value),
        reconstructed = S * significand * 2.0^(Int(E) - 1023),
    )
end

end
