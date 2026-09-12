module L4bTraversal

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

    # TODO 1: Validate start, then allocate an empty visited set and traversal-
    # order vector. The set prevents a cycle from revisiting a vertex.

    # TODO 2: Define a recursive visit(vertex) helper. Return immediately for a
    # visited vertex. Otherwise, record it in both state collections and visit
    # each neighbor returned by _ordered_neighbors(adjacency, vertex).

    # TODO 3: Visit the validated starting vertex and return the completed
    # first-visit order.

    throw(ErrorException("Oooops! The `depth_first_order(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 through TODO 3."))
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

    # TODO 4: Validate start; allocate the visited set, traversal-order vector,
    # and FIFO queue; then mark and enqueue the start vertex. Marking on enqueue
    # prevents different vertices from adding the same neighbor twice.

    # TODO 5: Process the queue with a head index. For each dequeued vertex,
    # append it to the traversal order and inspect its ordered neighbors.

    # TODO 6: Mark and enqueue every neighbor that has not been discovered.
    # Continue until the head passes the end of the queue, then return the order.

    throw(ErrorException("Oooops! The `breadth_first_order(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 4 through TODO 6."))
end

end
