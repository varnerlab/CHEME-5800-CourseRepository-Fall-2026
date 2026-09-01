module L3dSorting

export bubble_sort_report, bubblesort, bubblesort!, quicksort, quicksort_reference,
    load_sound_library

include(joinpath(@__DIR__, "Sounds.jl"))

"""Sort a copy with bubble sort and report comparisons and swaps."""
function bubble_sort_report(values::AbstractVector; lt = isless)::NamedTuple
    result = collect(values)
    comparisons = 0
    swaps = 0

    for last_index in length(result):-1:2
        changed = false
        for index in 1:(last_index - 1)
            comparisons += 1
            if lt(result[index + 1], result[index])
                result[index], result[index + 1] = result[index + 1], result[index]
                swaps += 1
                changed = true
            end
        end
        changed || break
    end

    return (values = result, comparisons = comparisons, swaps = swaps)
end

"""
    bubblesort!(values::AbstractVector{<:Number};
        sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing)

Sort `values` into ascending order in place using bubble sort, and return the
sorted vector. When a `sounds` dictionary from `load_sound_library` is supplied
and `values` holds integers drawn from `1:128`, each pass plays the array as a
sequence of tones, so you can hear the disorder drain out.

### Arguments
- `values::AbstractVector{<:Number}`: The vector to sort. It is mutated.
- `sounds`: `nothing` for silent operation (the default), or a tone dictionary
  mapping each integer value to its waveform and sampling frequency.

### Returns
- The input vector, now sorted into ascending order.
"""
function bubblesort!(values::AbstractVector{<:Number};
    sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing)

    # TODO 1: Loop over passes 1 through length(values). At the top of each
    # pass, call _play_sound(values; sounds = sounds) when sounds !== nothing,
    # so the pass is audible whenever a sound library is supplied.

    # TODO 2: Inside each pass, sweep positions 1 through length(values) - pass.
    # Compare each neighboring pair with isless and swap the two elements
    # whenever the pair is out of order, the same ordering Julia's sort uses.

    # TODO 3: Track whether the pass performed any swap, stop early when a full
    # pass changes nothing, and return the (now sorted) values vector.

    throw(ErrorException("Oooops! The `bubblesort!(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 through TODO 3."))
end

"""
    bubblesort(values::AbstractVector{<:Number};
        sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing) -> Vector

Return a sorted copy of `values` using the in-place `bubblesort!` above. The
non-mutating wrapper is one line: copy first, then hand the copy to the
mutating implementation. Complete `bubblesort!` and this function works too.
"""
bubblesort(values::AbstractVector{<:Number};
    sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing) =
    bubblesort!(collect(values); sounds = sounds)

"""Recursive quicksort reference used by the L3d lab and algorithm notebook."""
function quicksort_reference(values::AbstractVector; lt = isless)
    length(values) <= 1 && return collect(values)
    pivot = last(values)
    lower = [value for value in values[begin:(end - 1)] if lt(value, pivot)]
    equal = [value for value in values if !lt(value, pivot) && !lt(pivot, value)]
    upper = [value for value in values[begin:(end - 1)] if lt(pivot, value)]
    return vcat(
        quicksort_reference(lower; lt = lt),
        equal,
        quicksort_reference(upper; lt = lt),
    )
end

"""Sort a numerical vector with the recursive quicksort reference above."""
quicksort(values::AbstractVector{<:Number}) = quicksort_reference(values)

end
