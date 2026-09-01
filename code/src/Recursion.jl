# ------------------------------------------------------------------------------------------------ #
# Recursion.jl
#
# Iterative and recursive Fibonacci implementations used by the week-03 recursion material
# (the L3c lecture and its companion example). The three public entry points are deliberately
# near-identical so the notebooks can compare them:
#
#   fibonacci(n)                          a single for-loop
#   fibonacci!(n, series)                 the plain recurrence; records but never consults `series`
#   memoization_fibonacci!(n, series)     the same recurrence plus one lookup, so each index is solved once
#
# The two *_report helpers return operation counts and back the week-03 validation suite.
# ------------------------------------------------------------------------------------------------ #

"""Compute `F₀` through `Fₙ` iteratively and return an index-to-value dictionary."""
function fibonacci(n::Int64)::Dict{Int64, Int64}
    n >= 0 || throw(ArgumentError("n must be nonnegative"))
    n <= 92 || throw(ArgumentError("n must be at most 92 for Int64 output"))

    series = Dict{Int64, Int64}(0 => 0)
    n == 0 && return series
    series[1] = 1
    for index in 2:n
        series[index] = Base.Checked.checked_add(series[index - 1], series[index - 2])
    end
    return series
end

"""Recursively compute `Fₙ`, storing every visited index in `series`."""
function fibonacci!(n::Int64, series::Dict{Int64, Int64})::Int64
    n >= 0 || throw(ArgumentError("n must be nonnegative"))
    if n == 0
        return series[0] = 0
    elseif n == 1
        return series[1] = 1
    end
    return series[n] = Base.Checked.checked_add(fibonacci!(n - 1, series), fibonacci!(n - 2, series))
end

"""Recursively compute `Fₙ` while caching each completed subproblem."""
function memoization_fibonacci!(n::Int64, series::Dict{Int64, Int64})::Int64
    n >= 0 || throw(ArgumentError("n must be nonnegative"))
    haskey(series, n) && return series[n]
    if n == 0
        return series[0] = 0
    elseif n == 1
        return series[1] = 1
    end
    return series[n] = Base.Checked.checked_add(
        memoization_fibonacci!(n - 1, series),
        memoization_fibonacci!(n - 2, series),
    )
end

function _fibonacci_index(n; maximum::Int)
    n isa Integer && !(n isa Bool) || throw(ArgumentError("n must be an integer index"))
    0 <= n <= maximum || throw(ArgumentError("n must be between 0 and $(maximum)"))
    return Int(n)
end

"""Compute `Fₙ` iteratively and report the number of addition operations."""
function iterative_fibonacci_report(n)::NamedTuple
    index = _fibonacci_index(n; maximum = 92)
    index == 0 && return (value = Int64(0), additions = 0)

    previous, current = Int64(0), Int64(1)
    additions = 0
    for _ in 2:index
        previous, current = current, Base.Checked.checked_add(previous, current)
        additions += 1
    end
    return (value = current, additions = additions)
end

"""Compute `Fₙ` from its recurrence and report every recursive function call."""
function recursive_fibonacci_report(n)::NamedTuple
    index = _fibonacci_index(n; maximum = 40)
    calls = Ref(0)

    function visit(k::Int)::Int64
        calls[] += 1
        k < 2 && return Int64(k)
        return Base.Checked.checked_add(visit(k - 1), visit(k - 2))
    end

    return (value = visit(index), calls = calls[])
end
