module L1dFloatingPoint

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

      # TODO 1: get the 64-character bit pattern.
      #   See `bitstring`. Position 1 is the sign, 2:12 the exponent, 13:64 the fraction.

      # TODO 2: slice the three fields out of that string.

      # TODO 3: rebuild the value from the fields alone, using the L1c formula
      #   x = S * significand * 2^(E - 1023)
      #   where S = (-1)^sign_bit, E is the exponent bits read as a base-2 integer
      #   (see `parse` with the `base` keyword), and
      #   significand = 1 + sum over k of fraction_bits[k] * 2^(-k).

      # TODO 4: return the named tuple described in the docstring, using `eps(value)`
      #   for the local spacing.

      throw(ErrorException("Oooops! The `float64_report(...)` function is not " *
                          "implemented yet - we'd better fix that."))
  end
end # end module
