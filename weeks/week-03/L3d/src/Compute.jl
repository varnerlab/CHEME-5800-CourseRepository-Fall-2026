module L3dSorting

export bubble_sort_report, bubblesort, quicksort, quicksort_reference

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

"""Sort a numerical vector using the bubble-sort implementation from Fall 2025."""
bubblesort(values::AbstractVector{<:Number}) = bubble_sort_report(values).values

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
