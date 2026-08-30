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

    number_of_values = length(values)

    # TODO 1 (solution): each pass is audible when a sound library is supplied.
    for pass in 1:number_of_values
        sounds === nothing || _play_sound(values; sounds = sounds)

        # TODO 2 (solution): sweep the unsorted prefix and swap out-of-order
        # neighbors; TODO 3 (solution): remember whether this pass changed
        # anything so a sorted array exits early.
        swapped_this_pass = false
        for position in 1:(number_of_values - pass)
            if isless(values[position + 1], values[position])
                values[position], values[position + 1] = values[position + 1], values[position]
                swapped_this_pass = true
            end
        end
        swapped_this_pass || break
    end

    return values
end

"""
    bubblesort(values::AbstractVector{<:Number};
        sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing) -> Vector

Return a sorted copy of `values` using the in-place `bubblesort!` above. The
non-mutating wrapper is one line: copy first, then hand the copy to the
mutating implementation.
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

"""Sort a numerical vector using the recursive quicksort reference from Fall 2025."""
quicksort(values::AbstractVector{<:Number}) = quicksort_reference(values)

end
