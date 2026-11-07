# ------------------------------------------------------------------------------------------------ #
# Recursion.jl
#
# Iterative and recursive Fibonacci implementations used by the week-03 recursion material.
# The L3c example notebook (recursive Fibonacci) checks and benchmarks the three public entry
# points; the L3c lecture itself uses only Julia's Base library. The three entry points are
# deliberately near-identical so the notebook can compare them:
#
#   fibonacci(n)                          a single for-loop
#   fibonacci!(n, series)                 the plain recurrence; records but never consults `series`
#   memoization_fibonacci!(n, series)     the same recurrence plus one lookup, so each index is solved once
#
# The two *_report helpers return operation counts and back the week-03 validation suite:
#
#   iterative_fibonacci_report(n)         Fₙ and the number of additions the for-loop makes
#   recursive_fibonacci_report(n)         Fₙ and the number of calls the plain recursion makes
#
# The private helper _fibonacci_index(n; maximum) checks the index the two reports receive.
#
# The Fibonacci numbers are F₀ = 0, F₁ = 1, and Fₙ = Fₙ₋₁ + Fₙ₋₂ for n ≥ 2, so the sequence
# starts 0, 1, 1, 2, 3, 5, 8, 13, ... Every function here stores values as Int64, the 64-bit
# integer type. The largest Fibonacci number that fits in an Int64 is F₉₂ = 7540113804746346429.
# We add with `Base.Checked.checked_add(a, b)`, which returns a + b like `+` does, but throws an
# `OverflowError` when the sum does not fit in an Int64. A plain `+` would wrap around to a
# wrong (negative) number without any warning.
# ------------------------------------------------------------------------------------------------ #

"""
    fibonacci(n::Int64) -> Dict{Int64, Int64}

Compute `F₀` through `Fₙ` iteratively and return an index-to-value dictionary.

We start from the two base cases `F₀ = 0` and `F₁ = 1`, then fill in `F₂, F₃, …, Fₙ` in
order with one for-loop, using `Fₖ = Fₖ₋₁ + Fₖ₋₂`. Each value is computed exactly once, so the
function makes `n − 1` additions for `n ≥ 1`.

### Arguments
- `n::Int64`: the largest index to compute. It must satisfy `0 ≤ n ≤ 92`, because `F₉₃` does
  not fit in an `Int64`.

### Returns
- `Dict{Int64, Int64}`: a dictionary whose key `k` holds `Fₖ`, for every `k = 0, 1, …, n`.

### Throws
- `ArgumentError`: `n` is negative, or `n` is larger than 92.

### Example
```julia
series = fibonacci(5);
series[5]   # 5
series[4]   # 3
```
"""
function fibonacci(n::Int64)::Dict{Int64, Int64}

    # check the index. The form `condition || throw(...)` means: if condition is false, stop with an error -
    n >= 0 || throw(ArgumentError("n must be nonnegative")) # if n >= 0 is false, stop with an error
    n <= 92 || throw(ArgumentError("n must be at most 92 for Int64 output")) # if n <= 92 is false, stop with an error

    # initialize: store the first base case, F₀ = 0 -
    series = Dict{Int64, Int64}(0 => 0) # a dictionary with one entry: key 0 holds the value 0
    n == 0 && return series # if n is 0, we are done: return the dictionary now

    # store the second base case, F₁ = 1 -
    series[1] = 1

    # main loop: fill in F₂, F₃, ..., Fₙ from the two values before each one -
    for index in 2:n
        series[index] = Base.Checked.checked_add(series[index - 1], series[index - 2]) # Fₖ = Fₖ₋₁ + Fₖ₋₂, with an overflow check
    end

    # return the dictionary of F₀ through Fₙ -
    return series
end

"""
    fibonacci!(n::Int64, series::Dict{Int64, Int64}) -> Int64

Recursively compute `Fₙ`, storing every visited index in `series`.

This is the plain recursion from the L3c lecture. A call on `n ≥ 2` calls itself on `n − 1`
and on `n − 2`, then adds the two results. The calls on `0` and `1` are the base cases that
stop the recursion. The function writes each value it computes into `series`, but it never
reads `series` back, so it solves the same smaller problems many times. The number of calls
grows roughly like `1.6ⁿ`.

The `!` at the end of the name is the Julia convention for a function that changes one of
its arguments; here, the function changes `series`.

### Arguments
- `n::Int64`: the index of the Fibonacci number to compute; `n ≥ 0`.
- `series::Dict{Int64, Int64}`: a dictionary that the function fills in. After a call with
  `n ≥ 2`, key `k` holds `Fₖ` for every `k = 0, 1, …, n`; a call with `n = 0` or `n = 1` writes
  only key `n`. The function overwrites the keys it visits and never reads the dictionary.

### Returns
- `Int64`: the Fibonacci number `Fₙ`.

### Throws
- `ArgumentError`: `n` is negative.
- `OverflowError`: `Fₙ` does not fit in an `Int64`, i.e., `n > 92`.

### Example
```julia
series = Dict{Int64, Int64}();   # an empty dictionary for the function to fill
fibonacci!(5, series)            # 5
series[3]                        # 2
```
"""
function fibonacci!(n::Int64, series::Dict{Int64, Int64})::Int64

    # check the index -
    n >= 0 || throw(ArgumentError("n must be nonnegative")) # if n >= 0 is false, stop with an error

    # base cases: F₀ = 0 and F₁ = 1. The line `return series[0] = 0` stores 0 under key 0
    # and returns that same value, because an assignment in Julia gives the assigned value -
    if n == 0
        return series[0] = 0
    elseif n == 1
        return series[1] = 1
    end

    # recursive case: Fₙ = Fₙ₋₁ + Fₙ₋₂. We call fibonacci! twice, add the two results with an
    # overflow check, store the sum under key n, and return it -
    return series[n] = Base.Checked.checked_add(fibonacci!(n - 1, series), fibonacci!(n - 2, series))
end

"""
    memoization_fibonacci!(n::Int64, series::Dict{Int64, Int64}) -> Int64

Recursively compute `Fₙ` while caching each completed subproblem.

This is the same recursion as `fibonacci!`, with one extra step at the start of each call:
if `series` already holds `Fₙ`, we return the stored value and make no further calls. This is
called memoization: we store (memoize) each answer the first time we compute it, and look it
up every later time. Each index is then solved once, so the number of additions grows like
`n` instead of like `1.6ⁿ`.

### Arguments
- `n::Int64`: the index of the Fibonacci number to compute; `n ≥ 0`.
- `series::Dict{Int64, Int64}`: the cache. The function reads it, and adds key `k` with value
  `Fₖ` for every index it computes. Pass an empty dictionary to start fresh. The function
  trusts every value already in the dictionary, so a wrong stored value gives a wrong result.

### Returns
- `Int64`: the Fibonacci number `Fₙ`.

### Throws
- `ArgumentError`: `n` is negative.
- `OverflowError`: `Fₙ` does not fit in an `Int64`, i.e., `n > 92`.

### Example
```julia
series = Dict{Int64, Int64}();         # an empty cache
memoization_fibonacci!(5, series)      # 5
```
"""
function memoization_fibonacci!(n::Int64, series::Dict{Int64, Int64})::Int64

    # check the index -
    n >= 0 || throw(ArgumentError("n must be nonnegative")) # if n >= 0 is false, stop with an error

    # memoization: if we already stored Fₙ, return the stored value and skip the recursion -
    haskey(series, n) && return series[n] # if the key n is in the cache, return its value now

    # base cases: F₀ = 0 and F₁ = 1, stored and returned -
    if n == 0
        return series[0] = 0
    elseif n == 1
        return series[1] = 1
    end

    # recursive case: Fₙ = Fₙ₋₁ + Fₙ₋₂, stored under key n and returned. For n ≥ 3, the first
    # call stores every index below n, so the second call finds Fₙ₋₂ already stored -
    return series[n] = Base.Checked.checked_add(
        memoization_fibonacci!(n - 1, series),
        memoization_fibonacci!(n - 2, series),
    )
end

"""
    _fibonacci_index(n; maximum::Int) -> Int

Check that `n` is a valid Fibonacci index for the two report functions, and return it as an
`Int`. This helper is private to `iterative_fibonacci_report` and `recursive_fibonacci_report`.

The two report functions take `n` without a declared type, so this helper checks the type.
Julia counts `true` and `false` as integers (`Bool` is a subtype of `Integer`), so we reject
them by name.

### Arguments
- `n`: the index to check. It must be an integer that is not a `Bool`.
- `maximum::Int`: the largest index allowed (keyword argument, no default). Inside this
  function, the name `maximum` means this number, not Julia's `maximum(...)` function.

### Returns
- `Int`: the index `n`, converted to `Int`.

### Throws
- `ArgumentError`: `n` is not an integer, `n` is a `Bool`, or `n` is outside `0, 1, …, maximum`.
"""
function _fibonacci_index(n; maximum::Int)

    # check the type: && is evaluated before ||, so this line reads
    # "(n is an integer and n is not a Bool) or else stop with an error" -
    n isa Integer && !(n isa Bool) || throw(ArgumentError("n must be an integer index"))

    # check the range: 0 <= n <= maximum is a chained comparison, true when 0 ≤ n and n ≤ maximum -
    0 <= n <= maximum || throw(ArgumentError("n must be between 0 and $(maximum)")) # if n is out of range, stop with an error

    # return the checked index as an Int -
    return Int(n)
end

"""
    iterative_fibonacci_report(n) -> NamedTuple

Compute `Fₙ` iteratively and report the number of addition operations.

We keep only the last two Fibonacci numbers, `previous = Fₖ₋₁` and `current = Fₖ`, and move
them one step forward per loop pass with one addition. Starting from `F₀ = 0` and `F₁ = 1`,
the loop makes `n − 1` additions for `n ≥ 1`, and none for `n = 0`. The week-03 validation
suite compares this count with the call count of `recursive_fibonacci_report`.

### Arguments
- `n`: the index of the Fibonacci number; an integer (not a `Bool`) with `0 ≤ n ≤ 92`.

### Returns
A `NamedTuple` with the fields:
- `value::Int64`: the Fibonacci number `Fₙ`.
- `additions::Int`: the number of additions the loop made.

### Throws
- `ArgumentError`: `n` is not an integer, is a `Bool`, or is outside `0, 1, …, 92`.

### Example
```julia
iterative_fibonacci_report(10)   # (value = 55, additions = 9)
```
"""
function iterative_fibonacci_report(n)::NamedTuple

    # check the index -
    index = _fibonacci_index(n; maximum = 92)
    index == 0 && return (value = Int64(0), additions = 0) # if the index is 0, return F₀ = 0 with no additions

    # initialize: previous holds F₀ and current holds F₁. The line assigns two variables at
    # once: previous gets Int64(0) and current gets Int64(1) -
    previous, current = Int64(0), Int64(1)
    additions = 0 # the number of additions so far

    # main loop: each pass moves (previous, current) from (Fₖ₋₁, Fₖ) to (Fₖ, Fₖ₊₁).
    # The loop variable is `_` because we do not need the pass number -
    for _ in 2:index

        # Julia computes both values on the right first, then assigns them, so the new
        # previous is the old current, and the new current is old previous + old current -
        previous, current = current, Base.Checked.checked_add(previous, current)
        additions += 1 # additions += 1 is short for additions = additions + 1
    end

    # return Fₙ and the number of additions, as a NamedTuple with the fields value and additions -
    return (value = current, additions = additions)
end

"""
    recursive_fibonacci_report(n) -> NamedTuple

Compute `Fₙ` from its recurrence and report every recursive function call.

We run the plain recursion `Fₖ = Fₖ₋₁ + Fₖ₋₂`, with base cases `F₀ = 0` and `F₁ = 1`, and count
every call, including the first one. The count for index `n` is `2⋅Fₙ₊₁ − 1`, e.g., 177 calls
for `n = 10`. It grows roughly like `1.6ⁿ`. The function accepts `n` up to 40, where the
recursion already makes 331,160,281 calls.

### Arguments
- `n`: the index of the Fibonacci number; an integer (not a `Bool`) with `0 ≤ n ≤ 40`.

### Returns
A `NamedTuple` with the fields:
- `value::Int64`: the Fibonacci number `Fₙ`.
- `calls::Int`: the number of calls made to the recursive inner function `visit`.

### Throws
- `ArgumentError`: `n` is not an integer, is a `Bool`, or is outside `0, 1, …, 40`.

### Example
```julia
recursive_fibonacci_report(10)   # (value = 55, calls = 177)
```
"""
function recursive_fibonacci_report(n)::NamedTuple

    # check the index -
    index = _fibonacci_index(n; maximum = 40)

    # initialize the call counter. Ref(0) makes a small container that holds one number,
    # starting at 0; calls[] reads that number, and calls[] += 1 adds one to it -
    calls = Ref(0)

    # visit(k) is an inner function: it is defined inside recursive_fibonacci_report, so it
    # can use the calls counter. It returns Fₖ by the plain recursion, and adds one to the
    # counter each time it runs -
    function visit(k::Int)::Int64
        calls[] += 1 # count this call
        k < 2 && return Int64(k) # base cases: if k is 0 or 1, Fₖ = k, so return k
        return Base.Checked.checked_add(visit(k - 1), visit(k - 2)) # recursive case: Fₖ = Fₖ₋₁ + Fₖ₋₂
    end

    # run the recursion, then return Fₙ and the call count. Julia evaluates visit(index)
    # before it reads calls[], so the count includes every call -
    return (value = visit(index), calls = calls[])
end
