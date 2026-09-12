# ------------------------------------------------------------------------------------------------ #
# ShortestPathAlgorithms.jl
#
# Dijkstra and Bellman-Ford implementations used by the week-04 L4c lecture.
# ------------------------------------------------------------------------------------------------ #

import DataStructures: PriorityQueue, dequeue! # min-priority queue and removal by smallest priority


"""
    WeightedEdge(source::Integer, target::Integer, weight::Real)

A directed edge from vertex `source` to vertex `target` with traversal cost `weight`.
Vertex identifiers need not be consecutive. Identifiers are stored as `Int64` and
the weight as `Float64`; negative weights are allowed by this representation.
"""
struct WeightedEdge
    source::Int64   # vertex at the start of the directed edge
    target::Int64   # vertex at the end of the directed edge
    weight::Float64 # cost of traversing this edge; use consistent units across the graph

    function WeightedEdge(source::Integer, target::Integer, weight::Real)
        # Check the input values before converting their storage types -
        # Bool is an Integer in Julia, but true/false are not vertex identifiers here.
        source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
        target isa Bool && throw(ArgumentError("target must be a vertex identifier"))
        isfinite(weight) || throw(ArgumentError("edge weight must be finite"))
        return new(Int64(source), Int64(target), Float64(weight))
    end
end

"""
    weighted_edges(records)

Convert `(source, target, weight)` records to a vector of `WeightedEdge` objects.
Each record supplies the three arguments checked by the edge constructor.
"""
weighted_edges(records) = [WeightedEdge(record...) for record in records]

# Infer the vertex set from edge endpoints; an isolated vertex has no record in this representation.
function _vertices(edges::AbstractVector{WeightedEdge})::Vector{Int64}
    isempty(edges) && throw(ArgumentError("edges may not be empty"))
    vertices = Set{Int64}() # collect each endpoint identifier once
    for edge in edges
        push!(vertices, edge.source, edge.target)
    end
    return sort!(collect(vertices)) # give both algorithms the same vertex ordering
end

# Initialize the source, distance estimates, and predecessor map shared by both algorithms.
function _initialize(edges::AbstractVector{WeightedEdge}, source::Integer)
    # Check that the requested source is an endpoint in the supplied graph -
    source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
    source_id = Int64(source)
    vertices = _vertices(edges)
    source_id in vertices || throw(ArgumentError("source vertex is not in the graph"))

    # Initialize the lecture's dist and prev maps -
    distances = Dict(vertex => Inf for vertex in vertices) # no route has been discovered yet
    # Each predecessor is a vertex identifier or nothing when no predecessor is recorded.
    previous = Dict{Int64, Union{Nothing, Int64}}(vertex => nothing for vertex in vertices)
    distances[source_id] = 0.0 # the route from the source to itself contains no edges
    return source_id, vertices, distances, previous
end

"""
    dijkstra(edges::AbstractVector{WeightedEdge}, source::Integer) -> NamedTuple

Compute shortest-path distances from `source` when every edge weight is nonnegative.
The result contains `distances` (minimum costs) and `previous` (chosen predecessors),
both keyed by vertex identifier. Unreachable vertices retain `Inf` and `nothing`.
The source has distance zero and no predecessor. The edge vector must be nonempty
and contain the source among its endpoints.
"""
function dijkstra(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple
    # Check the weight assumption needed to declare a selected distance final -
    any(edge -> edge.weight < 0, edges) && throw(ArgumentError("Dijkstra requires nonnegative edge weights"))
    source_id, vertices, distances, previous = _initialize(edges, source)

    # Group outgoing edges so processing a vertex visits only its neighbors -
    adjacency = Dict(vertex => WeightedEdge[] for vertex in vertices) # one edge list per vertex
    for edge in edges
        push!(adjacency[edge.source], edge)
    end

    # Initialize the lecture's queue Q and processed set S -
    queue = PriorityQueue{Int64, Float64}() # vertex identifiers are keys; distance estimates are priorities
    queue[source_id] = 0.0                 # only the source is discovered initially
    visited = Set{Int64}()                 # vertices whose shortest-path distances are final

    # Select the smallest tentative distance, then relax its outgoing edges -
    while !isempty(queue)
        vertex = dequeue!(queue) # remove and return the vertex with the lowest distance estimate
        vertex in visited && continue # do not process a vertex twice
        push!(visited, vertex)
        for edge in adjacency[vertex]
            alternative = distances[vertex] + edge.weight # alternative route cost; alt(u,v) in the lecture
            if alternative < distances[edge.target] # tied costs leave the existing predecessor unchanged
                distances[edge.target] = alternative
                previous[edge.target] = vertex # record the last edge of the improved route
                queue[edge.target] = alternative # insert a new key or decrease its existing priority
            end
        end
    end
    return (distances = distances, previous = previous)
end

"""
    bellman_ford(edges::AbstractVector{WeightedEdge}, source::Integer) -> NamedTuple

Compute shortest-path distances from `source`, allowing negative edge weights.
Return `distances` and `previous`, keyed by vertex identifier; unreachable vertices
retain `Inf` and `nothing`. The edge vector must be nonempty and contain the source.
A reachable negative-weight cycle raises `ArgumentError` instead of returning a result.
"""
function bellman_ford(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple
    _, vertices, distances, previous = _initialize(edges, source)

    # Relax every edge for at most |V|-1 passes -
    # Updates are available immediately to later edges in the same input-order scan.
    for _ in 1:(length(vertices) - 1)
        changed = false # records whether any distance improves during this complete pass
        for edge in edges
            isfinite(distances[edge.source]) || continue # skip edges without a finite route to their start
            alternative = distances[edge.source] + edge.weight # alternative route cost; alt(u,v) in the lecture
            if alternative < distances[edge.target]
                distances[edge.target] = alternative
                previous[edge.target] = edge.source # record the last edge of the improved route
                changed = true
            end
        end
        changed || break # a complete pass without improvement establishes convergence
    end

    # Check whether a reachable edge can still improve a distance -
    # After |V|-1 passes, a further improvement contradicts the finite shortest-path bound.
    for edge in edges
        if isfinite(distances[edge.source]) && distances[edge.source] + edge.weight < distances[edge.target]
            throw(ArgumentError("graph contains a reachable negative-weight cycle"))
        end
    end
    return (distances = distances, previous = previous)
end

"""
    reconstruct_path(previous::AbstractDict, source::Integer, target::Integer) -> Vector{Int64}

Recover a route using the predecessor map from a successful shortest-path calculation
with the same source. Return an empty vector when the target is unreachable, or
`[source]` when source and target coincide. Both identifiers must appear in the map.
"""
function reconstruct_path(previous::AbstractDict, source::Integer, target::Integer)::Vector{Int64}
    # Check that both requested endpoints belong to the predecessor map -
    source_id, target_id = Int64(source), Int64(target)
    haskey(previous, source_id) || throw(ArgumentError("source vertex is not in the predecessor map"))
    haskey(previous, target_id) || throw(ArgumentError("target vertex is not in the predecessor map"))
    source_id == target_id && return Int64[source_id] # the zero-edge route contains just the source

    # Follow predecessors backward from the target -
    path = Int64[]      # vertex identifiers accumulate in target-to-source order
    current = target_id
    while current != source_id
        push!(path, current)
        parent = previous[current] # vertex immediately before current on the selected route
        isnothing(parent) && return Int64[] # no predecessor before reaching the source means no route
        current = parent
    end
    push!(path, source_id)
    reverse!(path) # return the route in source-to-target order
    return path
end

"""
    path_cost(edges::AbstractVector{WeightedEdge}, path::AbstractVector{<:Integer}) -> Float64

Sum the edge weights along consecutive vertices in `path`. An empty or single-vertex
sequence returns zero; the zero from an empty sequence does not establish reachability.
A missing edge in a longer sequence raises `ArgumentError`. For repeated endpoint
pairs in `edges`, the last supplied weight is used.
"""
function path_cost(edges::AbstractVector{WeightedEdge}, path::AbstractVector{<:Integer})::Float64
    length(path) <= 1 && return 0.0 # no consecutive vertex pairs contribute to the sum

    # Index edge costs by their ordered endpoints -
    weights = Dict((edge.source, edge.target) => edge.weight for edge in edges)
    total = 0.0 # accumulated route cost, in the same units as the edge weights

    # Validate and sum each directed step along the route -
    for index in 1:(length(path) - 1)
        key = (Int64(path[index]), Int64(path[index + 1])) # adjacent positions in the route vector
        haskey(weights, key) || throw(ArgumentError("path contains missing edge $(key)"))
        total += weights[key]
    end
    return total
end
