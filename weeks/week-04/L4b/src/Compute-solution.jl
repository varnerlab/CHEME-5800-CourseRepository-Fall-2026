module L4bTraversal

using VLDataScienceMachineLearningPackage: MyQueue # FIFO queue introduced in L3b

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
    # Initialize -
    adjacency = Dict{Int64, Vector{Int64}}() # one outgoing-neighbor vector per vertex

    # Populate directed neighbor lists -
    for edge in edges
        source, target = Int64(edge[1]), Int64(edge[2])
        get!(adjacency, source, Int64[]) # create a list only for a new source; retain earlier neighbors
        get!(adjacency, target, Int64[]) # include targets with no outgoing edges
        push!(adjacency[source], target) # source → target does not imply target → source
    end

    # Remove repeated edges, then sort so input order cannot change neighbor choices -
    for neighbors in values(adjacency)
        sort!(unique!(neighbors))
    end
    return adjacency
end

# Reject missing start vertices and Boolean identifiers (Bool <: Integer in Julia).
function _validate_start(adjacency::AbstractDict, start::Integer)::Int64
    start isa Bool && throw(ArgumentError("start must be a vertex identifier, not Bool"))
    start_id = Int64(start)
    haskey(adjacency, start_id) ||
        throw(ArgumentError("start vertex $(start_id) is not in the graph"))
    return start_id
end

# Work on a fresh vector: unique! and sort! must not change the caller's lists.
# An absent key gives an empty vector, so a vertex with no recorded edges ends a branch.
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

    # TODO 1 (solution): Initialize the state shared by every recursive call -
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}() # vertices already discovered by this search
    order = Int64[]       # first-visit order

    # TODO 2 (solution): Explore a branch before continuing to the next neighbor -
    function visit(vertex::Int64)
        vertex in visited && return # stop repeated exploration through cycles or converging edges
        push!(visited, vertex) # mark before descending so a cycle cannot re-enter this vertex
        push!(order, vertex)   # record discovery, not the later return from recursion

        for neighbor in _ordered_neighbors(adjacency, vertex)
            visit(neighbor) # finish this branch before the loop considers the next neighbor
        end
        return nothing # return after all outgoing neighbors have been considered
    end

    # TODO 3 (solution): Start the recursion and return first-visit order -
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

    # TODO 4 (solution): Initialize discovered vertices and the FIFO queue -
    start_id = _validate_start(adjacency, start)
    visited = Set{Int64}([start_id]) # includes queued vertices not yet processed
    order = Int64[]                 # vertices in dequeue order
    queue = MyQueue{Int64}()        # discovered vertices waiting to be processed
    push!(queue, start_id)

    # TODO 5 (solution): Process the oldest queued vertex -
    # Every queued vertex is already in visited, but enters order only when
    # removed from the front. New discoveries go behind all vertices still waiting.
    while !isempty(queue)
        vertex = popfirst!(queue)
        push!(order, vertex)

        # TODO 6 (solution): Discover each ordered neighbor at most once -
        # Mark on discovery, not removal: two incoming edges could otherwise
        # enqueue the same vertex before either copy is processed.
        for neighbor in _ordered_neighbors(adjacency, vertex)
            if neighbor ∉ visited
                push!(visited, neighbor) # later incoming edges will skip this vertex
                push!(queue, neighbor)
            end
        end
    end
    return order
end

end
