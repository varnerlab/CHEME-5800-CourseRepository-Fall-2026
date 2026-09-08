module L4bTraversal

# Reference solution for L4b. The student-facing Compute.jl file contains the
# same public interface with TODO comments in place of the two traversals.

export adjacency_from_edges, breadth_first_order, depth_first_order

"""
    adjacency_from_edges(edges) -> Dict{Int64, Vector{Int64}}

Build a directed adjacency list from `(source, target)` edge pairs. Every vertex
appearing in an edge becomes a key, including vertices with no outgoing edges.
Duplicate edges are removed, and each outgoing-neighbor vector is sorted so
subsequent traversals have a reproducible order.
"""
function adjacency_from_edges(edges)::Dict{Int64, Vector{Int64}}
    adjacency = Dict{Int64, Vector{Int64}}()

    # Populate one outgoing-neighbor vector for every vertex in the edge list.
    for edge in edges
        source, target = Int64(edge[1]), Int64(edge[2])
        get!(adjacency, source, Int64[])
        get!(adjacency, target, Int64[])
        push!(adjacency[source], target)
    end

    # Normalize each vector once so duplicate records and input order do not
    # affect the traversal order.
    for neighbors in values(adjacency)
        sort!(unique!(neighbors))
    end
    return adjacency
end

# Validate the starting vertex before either traversal allocates its state.
function _validate_start(adjacency::AbstractDict, start::Integer)::Int64
    start isa Bool && throw(ArgumentError("start must be a vertex identifier, not Bool"))
    start_id = Int64(start)
    haskey(adjacency, start_id) ||
        throw(ArgumentError("start vertex $(start_id) is not in the graph"))
    return start_id
end

# Return a sorted copy rather than sorting the caller's adjacency list in place.
function _ordered_neighbors(adjacency::AbstractDict, vertex::Int64)::Vector{Int64}
    return sort!(unique!(Int64.(collect(get(adjacency, vertex, Int64[])))))
end

"""
    depth_first_order(adjacency::AbstractDict, start::Integer) -> Vector{Int64}

Return every vertex reachable from `start` in deterministic recursive
depth-first order.

### Arguments
- `adjacency::AbstractDict`: Mapping from each vertex identifier to its outgoing
  neighbors. The function does not mutate this mapping or its neighbor lists.
- `start::Integer`: Vertex at which the traversal begins. Boolean values are not
  valid vertex identifiers.

### Returns
- `Vector{Int64}`: Reachable vertices in first-visit order. Outgoing neighbors
  are considered in ascending identifier order.

### Errors
- `ArgumentError`: `start` is a Boolean or is not a key in `adjacency`.
"""
function depth_first_order(adjacency::AbstractDict, start::Integer)::Vector{Int64}

    # TODO 1 (solution): validate the start and allocate the traversal state.
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}()
    order = Int64[]

    # TODO 2 (solution): record a vertex on its first visit, then recursively
    # explore its outgoing neighbors in deterministic identifier order.
    function visit(vertex::Int64)
        vertex in visited && return
        push!(visited, vertex)
        push!(order, vertex)

        for neighbor in _ordered_neighbors(adjacency, vertex)
            visit(neighbor)
        end
        return nothing
    end

    # TODO 3 (solution): start the recursion and return first-visit order.
    visit(start_id)
    return order
end

"""
    breadth_first_order(adjacency::AbstractDict, start::Integer) -> Vector{Int64}

Return every vertex reachable from `start` in deterministic breadth-first layer
order.

### Arguments
- `adjacency::AbstractDict`: Mapping from each vertex identifier to its outgoing
  neighbors. The function does not mutate this mapping or its neighbor lists.
- `start::Integer`: Vertex at which the traversal begins. Boolean values are not
  valid vertex identifiers.

### Returns
- `Vector{Int64}`: Reachable vertices in first-visit order. Outgoing neighbors
  are considered in ascending identifier order.

### Errors
- `ArgumentError`: `start` is a Boolean or is not a key in `adjacency`.
"""
function breadth_first_order(adjacency::AbstractDict, start::Integer)::Vector{Int64}

    # TODO 4 (solution): seed the FIFO queue and mark the starting vertex when
    # it enters the queue, so it cannot be enqueued again through a cycle.
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}([start_id])
    order = Int64[]
    queue = Int64[start_id]
    head = 1

    # TODO 5 (solution): advance a head index instead of removing the first
    # vector element, then record the vertex when it leaves the queue.
    while head <= length(queue)
        vertex = queue[head]
        head += 1
        push!(order, vertex)

        # TODO 6 (solution): discover each ordered neighbor once. Marking here,
        # at enqueue time, prevents duplicate queue entries.
        for neighbor in _ordered_neighbors(adjacency, vertex)
            if neighbor ∉ visited
                push!(visited, neighbor)
                push!(queue, neighbor)
            end
        end
    end
    return order
end

end
