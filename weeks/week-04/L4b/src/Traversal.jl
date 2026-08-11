module L4bTraversal

export adjacency_from_edges, breadth_first_order, depth_first_order

"""Build a deterministic adjacency list from directed `(source, target)` edges."""
function adjacency_from_edges(edges)::Dict{Int64, Vector{Int64}}
    result = Dict{Int64, Vector{Int64}}()
    for edge in edges
        source, target = Int64(edge[1]), Int64(edge[2])
        get!(result, source, Int64[])
        get!(result, target, Int64[])
        push!(result[source], target)
    end
    for neighbors in values(result)
        sort!(unique!(neighbors))
    end
    return result
end

function _validate_start(adjacency::AbstractDict, start::Integer)::Int64
    start isa Bool && throw(ArgumentError("start must be a vertex identifier"))
    start_id = Int64(start)
    haskey(adjacency, start_id) || throw(ArgumentError("start vertex $(start_id) is not in the graph"))
    return start_id
end

"""Return reachable vertices in recursive depth-first order."""
function depth_first_order(adjacency::AbstractDict, start::Integer)::Vector{Int64}
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}()
    order = Int64[]

    function visit(vertex::Int64)
        vertex in visited && return
        push!(visited, vertex)
        push!(order, vertex)
        for neighbor in sort!(Int64.(collect(get(adjacency, vertex, Int64[]))))
            visit(neighbor)
        end
    end

    visit(start_id)
    return order
end

"""Return reachable vertices in breadth-first layer order."""
function breadth_first_order(adjacency::AbstractDict, start::Integer)::Vector{Int64}
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}([start_id])
    order = Int64[]
    queue = Int64[start_id]
    head = 1

    while head <= length(queue)
        vertex = queue[head]
        head += 1
        push!(order, vertex)
        for neighbor in sort!(Int64.(collect(get(adjacency, vertex, Int64[]))))
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(queue, neighbor)
            end
        end
    end
    return order
end

end

