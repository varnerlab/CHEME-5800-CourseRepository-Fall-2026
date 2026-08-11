module L2dFibonacci

# Reference solution for L2d. The student-facing `Compute.jl` in this folder ships as
# a stub; this file is excluded from the student bundle by release.toml.

export fibonacci_sequence

"""
    fibonacci_sequence(n::Integer) -> Vector{Int64}

Return `[F_0, F_1, ..., F_n]` using checked `Int64` arithmetic. Array position
`n + 1` holds `F_n`.
"""
function fibonacci_sequence(n::Integer)::Vector{Int64}
    n isa Bool && throw(ArgumentError("n must be an integer index, not Bool"))
    n >= 0 || throw(ArgumentError("n must be nonnegative"))
    n <= 92 || throw(ArgumentError("n must be at most 92 for Int64 output"))

    last_index = Int(n)
    sequence = Vector{Int64}(undef, last_index + 1)
    sequence[1] = 0
    last_index == 0 && return sequence

    sequence[2] = 1
    for index in 3:length(sequence)
        sequence[index] = Base.Checked.checked_add(sequence[index - 1], sequence[index - 2])
    end
    return sequence
end

fibonacci_sequence(n) = throw(ArgumentError("n must be an integer index"))

end
