module L2dFibonacci

export fibonacci_sequence

"""
    fibonacci_sequence(n::Integer) -> Vector{Int64}

Return the vector `[F_0, F_1, ..., F_n]` of Fibonacci numbers, where `F_0 = 0`,
`F_1 = 1`, and `F_k = F_{k-1} + F_{k-2}`.

The contract:

  * the result is a `Vector{Int64}` of length `n + 1`, so array position `n + 1`
    holds `F_n`;
  * `n` must be an integer with `0 <= n <= 92`. `F_93` does not fit in an `Int64`,
    so 92 is a real boundary of this interface, not an arbitrary limit;
  * `Bool` is a subtype of `Integer` in Julia, but `true` is not a sequence index,
    so it is rejected;
  * anything outside the contract raises an `ArgumentError`.
"""
function fibonacci_sequence(n::Integer)::Vector{Int64}

    # TODO 1: reject input outside the contract.
    #   - a Bool is an Integer in Julia but is not a valid index here
    #   - n must be nonnegative
    #   - n must be at most 92, because F_93 overflows Int64
    #   Throw an ArgumentError with a descriptive message in each case.

    # TODO 2: allocate the result.
    #   You need n + 1 positions: Vector{Int64}(undef, n + 1).

    # TODO 3: store the base cases.
    #   F_0 = 0 goes in position 1. If n == 0 you are already done -- return early,
    #   otherwise position 2 would be read before it is written.
    #   F_1 = 1 goes in position 2.

    # TODO 4: fill the remaining positions from the two before each one, then return.
    #   Use Base.Checked.checked_add so an overflow raises instead of wrapping
    #   silently. (You bounded n at 92 above, so this should never fire -- belt and
    #   braces on an integer boundary is cheap.)

    throw(ErrorException("Oooops! The `fibonacci_sequence(...)` function is not " *
                         "implemented yet - we'd better fix that."))
end

# Anything that is not an Integer never reaches the method above.
fibonacci_sequence(n) = throw(ArgumentError("n must be an integer index"))

end
