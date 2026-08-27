module L1dFloatingPoint

# Reference solution for L1d. The student-facing `Compute.jl` in this folder ships as
# a stub; this file is excluded from the student bundle by release.toml.

export float64_report

    """
        float64_report(value::Float64) -> NamedTuple

    Decompose a binary64 value into its IEEE 754 sign, biased-exponent, and fraction
    fields, then reconstruct the value from those fields.

    # Arguments

    - `value::Float64`: finite normalized value whose 64-bit representation will be
      inspected.

    # Returns

    A `NamedTuple` containing:

    - `value::Float64`: the input value, returned unchanged.
    - `sign_bit::Char`: the sign bit at position 1 of the bit pattern.
    - `exponent_bits::String`: the 11 biased-exponent bits at positions 2 through 12.
    - `fraction_bits::String`: the 52 stored fraction bits at positions 13 through 64.
    - `spacing::Float64`: the local unit in the last place (ULP), computed as
      `eps(value)`.
    - `reconstructed::Float64`: the value rebuilt from the sign, exponent, and
      fraction fields.

    The reconstruction formula used here assumes a finite normalized input. Under
    that assumption, `reconstructed` must equal `value` exactly.
    """
    function float64_report(value::Float64)::NamedTuple

        # Represent the Float64 as a 64-character, most-significant-bit-first string.
        bits = bitstring(value)

        # Extract the three fixed-width fields. A single index returns a Char, while
        # a range returns a String.
        sign_bit = bits[1]
        exponent_bits = bits[2:12]
        fraction_bits = bits[13:64]

        # Convert the stored fields to the sign, biased exponent, and normalized
        # significand used by the IEEE 754 reconstruction formula.
        S = (-1.0)^parse(Int, sign_bit)
        E = parse(UInt64, exponent_bits; base = 2)
        significand = 1.0 + sum(parse(Int, fraction_bits[k]) * 2.0^(-k) for k in 1:52)

        # Return the extracted fields together with the local ULP and the exact
        # reconstruction check.
        return (
            value = value,
            sign_bit = sign_bit,
            exponent_bits = exponent_bits,
            fraction_bits = fraction_bits,
            spacing = eps(value),
            reconstructed = S * significand * 2.0^(Int(E) - 1023),
        )
    end

end # end module
