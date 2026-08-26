module L2bFibonacci

# Reference solution for L2b. The student-facing Compute.jl file contains the
# same interface with TODO comments in place of the implementation.

export fibonacci_sequence

"""
    fibonacci_sequence(n::Integer) -> Vector{Int64}

Return the vector `[F_0, F_1, ..., F_n]`, where `F_0 = 0`, `F_1 = 1`, and
`F_k = F_{k-1} + F_{k-2}`.

### Arguments
- `n::Integer`: Largest Fibonacci index to compute. The supported range is
  `0 <= n <= 92`. Boolean values are not valid indices.

### Returns
- `Vector{Int64}`: Fibonacci values from `F_0` through `F_n`. Julia arrays use
  one-based indexing, so `F_n` is stored at position `n + 1`.

### Errors
- `ArgumentError`: The input is a Boolean, is negative, or is greater than 92.
  The upper bound prevents `Int64` overflow.
"""
function fibonacci_sequence(n::Integer)::Vector{Int64}

    # Validate the complete input contract before allocating the output vector.
    n isa Bool && throw(ArgumentError("n must be an integer index, not Bool"))
    n >= 0 || throw(ArgumentError("n must be nonnegative"))
    n <= 92 || throw(ArgumentError("n must be at most 92 for Int64 output"))

    # Convert the validated index to Int and allocate one position for each
    # value from F_0 through F_n.
    last_index = Int(n)
    sequence = Vector{Int64}(undef, last_index + 1)

    # Store the first supported value. For n == 0, the result is complete and
    # returning here avoids writing beyond the one-position vector.
    sequence[1] = 0
    last_index == 0 && return sequence

    # Store F_1, then build each remaining value from its two predecessors.
    sequence[2] = 1
    for position in 3:length(sequence)
        sequence[position] = Base.Checked.checked_add(
            sequence[position - 1],
            sequence[position - 2],
        )
    end

    return sequence
end

# Reject values that do not match the public Integer method with one clear error.
fibonacci_sequence(n) = throw(ArgumentError("n must be an integer index"))

end
