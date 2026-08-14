module L1dFloatingPoint

export float64_report

"""
    float64_report(value::Float64) -> NamedTuple

Take a `Float64` apart into the three fields IEEE-754 actually stores, then put it
back together from those fields alone.

Returns a named tuple with:

  * `value` — the argument, unchanged
  * `sign_bit` — the single leading bit, as a `Char`
  * `exponent_bits` — the 11 biased-exponent bits, as a `String`
  * `fraction_bits` — the 52 stored fraction bits, as a `String`
  * `spacing` — the gap to the next representable value near `value`
  * `reconstructed` — the value rebuilt from the three fields

For a finite normalized `value`, `reconstructed` must equal `value` exactly.
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

end
