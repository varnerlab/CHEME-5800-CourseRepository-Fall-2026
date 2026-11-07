# ------------------------------------------------------------------------------------------------ #
# ShortestPathAlgorithms.jl
#
# Dijkstra and Bellman-Ford implementations used by the week-04 L4c lecture.
#
# Both algorithms solve the single-source shortest-path problem: starting from one source
# vertex s, find the least total edge weight (the distance) of a route to every other vertex,
# and the route itself. They share the lecture's two maps:
#
# - dist[v]: the best distance from s to v found so far; Inf until a route to v is found.
# - prev[v]: the vertex just before v on that best route; `nothing` when no route is recorded.
#
# Both improve dist by edge relaxation: for an edge u → v with weight w(u,v), the route to v
# through u costs alt = dist[u] + w(u,v); if alt < dist[v], we set dist[v] = alt and prev[v] = u.
#
# Public type and functions (the L4c lecture uses all of them):
#
#   WeightedEdge(source, target, weight)   one directed edge with a weight
#   weighted_edges(records)                turns (source, target, weight) tuples into WeightedEdge objects
#   dijkstra(edges, source)                shortest paths when every weight is ≥ 0, using a priority queue
#   bellman_ford(edges, source)            shortest paths that allow negative weights; rejects negative cycles
#   reconstruct_path(previous, s, t)       follows the prev map back from t to s, and returns the route
#   path_cost(edges, path)                 adds the edge weights along a route
#
# Private helpers (a leading underscore marks a name that callers should not use):
#
#   _vertices(edges)                       the sorted ids of every vertex that appears in an edge
#   _initialize(edges, source)             checks the source and builds the starting dist and prev maps
#
# The functions here work on a plain vector of WeightedEdge objects. The graph-model versions
# used in the L4d lab, findshortestpath(...) with DijkstraAlgorithm() or BellmanFordAlgorithm(),
# are in Graphs.jl.
# ------------------------------------------------------------------------------------------------ #

import DataStructures: PriorityQueue, dequeue! # min-priority queue and removal by smallest priority


"""
    WeightedEdge(source::Integer, target::Integer, weight::Real)

A directed edge from vertex `source` to vertex `target` with traversal cost `weight`.
Vertex identifiers need not be consecutive. Identifiers are stored as `Int64` and
the weight as `Float64`; negative weights are allowed by this representation.

The constructor checks its inputs before it stores them. Julia counts `true` and `false` as
integers (`Bool` is a subtype of `Integer`), so the constructor rejects a `Bool` id by name.

### Fields
- `source::Int64`: the vertex at the start of the edge.
- `target::Int64`: the vertex at the end of the edge.
- `weight::Float64`: the cost of traversing the edge, in units that are the same for every
  edge of the graph.

### Throws
- `ArgumentError`: `source` or `target` is a `Bool`, or `weight` is `Inf` or `NaN`.

### Example
```julia
edge = WeightedEdge(1, 2, 4);   # the integer weight 4 is stored as 4.0
edge.weight                     # 4.0
```
"""
struct WeightedEdge
    source::Int64   # vertex at the start of the directed edge
    target::Int64   # vertex at the end of the directed edge
    weight::Float64 # cost of traversing this edge; use consistent units across the graph

    # inner constructor: Julia calls this function to build every WeightedEdge -
    function WeightedEdge(source::Integer, target::Integer, weight::Real)
        # Check the input values before converting their storage types -
        # Bool is an Integer in Julia, but true/false are not vertex identifiers here.
        source isa Bool && throw(ArgumentError("source must be a vertex identifier")) # if source is true or false, stop with an error
        target isa Bool && throw(ArgumentError("target must be a vertex identifier")) # if target is true or false, stop with an error
        isfinite(weight) || throw(ArgumentError("edge weight must be finite")) # if the weight is Inf or NaN, stop with an error

        # new(...) stores the three converted values in a new WeightedEdge -
        return new(Int64(source), Int64(target), Float64(weight))
    end
end

"""
    weighted_edges(records) -> Vector{WeightedEdge}

Convert `(source, target, weight)` records to a vector of `WeightedEdge` objects.
Each record supplies the three arguments checked by the edge constructor.

### Arguments
- `records`: a collection of three-entry records, e.g., a vector of tuples
  `(source, target, weight)`. Each record is passed to `WeightedEdge` in that order.

### Returns
- `Vector{WeightedEdge}`: one edge per record, in the same order.

### Throws
- `ArgumentError`: a record fails the checks of the `WeightedEdge` constructor.

### Example
```julia
edges = weighted_edges([(1, 2, 4.0), (1, 3, 1.0), (3, 2, 2.0), (2, 4, 1.0), (3, 4, 5.0)]);
length(edges)   # 5
```
"""
weighted_edges(records) = [WeightedEdge(record...) for record in records] # one-line function: a comprehension that builds one WeightedEdge per record; record... (splatting) passes the three entries of the record as three separate arguments

"""
    _vertices(edges::AbstractVector{WeightedEdge}) -> Vector{Int64}

Infer the vertex set from edge endpoints; an isolated vertex has no record in this
representation. Return each vertex id once, in increasing order. Both shortest-path
algorithms call this helper, so they see the same vertex ordering.

### Arguments
- `edges::AbstractVector{WeightedEdge}`: the edges of the graph; at least one edge.

### Returns
- `Vector{Int64}`: the id of every vertex that is the source or target of an edge, sorted.

### Throws
- `ArgumentError`: `edges` is empty.
"""
function _vertices(edges::AbstractVector{WeightedEdge})::Vector{Int64}

    # check that we have at least one edge -
    isempty(edges) && throw(ArgumentError("edges may not be empty")) # if there are no edges, stop with an error

    # collect both endpoints of every edge into a set -
    vertices = Set{Int64}() # collect each endpoint identifier once
    for edge in edges
        push!(vertices, edge.source, edge.target) # push!(set, a, b) adds a and then b
    end

    # convert the set to a vector and sort it in place -
    return sort!(collect(vertices)) # give both algorithms the same vertex ordering
end

"""
    _initialize(edges::AbstractVector{WeightedEdge}, source::Integer) -> Tuple

Initialize the source, distance estimates, and predecessor map shared by both algorithms.

This is the "Initialize" step of both L4c algorithms: `dist[v] ← ∞` and `prev[v] ← nothing`
for every vertex `v`, then `dist[s] ← 0` for the source `s`.

### Arguments
- `edges::AbstractVector{WeightedEdge}`: the edges of the graph; at least one edge.
- `source::Integer`: the source vertex `s`. It must be an endpoint of some edge.

### Returns
A tuple of four values, in this order:
- `source_id::Int64`: the source, converted to `Int64`.
- `vertices::Vector{Int64}`: the sorted vertex ids, from `_vertices`.
- `distances::Dict{Int64, Float64}`: `dist`; `0.0` for the source and `Inf` for every other vertex.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: `prev`; `nothing` for every vertex.

### Throws
- `ArgumentError`: `source` is a `Bool`, `edges` is empty, or `source` is not a vertex of the graph.
"""
function _initialize(edges::AbstractVector{WeightedEdge}, source::Integer)

    # Check that the requested source is an endpoint in the supplied graph -
    source isa Bool && throw(ArgumentError("source must be a vertex identifier")) # if source is true or false, stop with an error
    source_id = Int64(source)
    vertices = _vertices(edges)
    source_id in vertices || throw(ArgumentError("source vertex is not in the graph")) # if source is not a vertex, stop with an error

    # Initialize the lecture's dist and prev maps. Dict(key => value for x in xs) builds a
    # dictionary with one entry per vertex -
    distances = Dict(vertex => Inf for vertex in vertices) # no route has been discovered yet
    # Each predecessor is a vertex identifier or nothing when no predecessor is recorded.
    # Union{Nothing, Int64} is the type "either nothing or an Int64" -
    previous = Dict{Int64, Union{Nothing, Int64}}(vertex => nothing for vertex in vertices)
    distances[source_id] = 0.0 # the route from the source to itself contains no edges

    # return four values at once, as a tuple; the caller unpacks them into four variables -
    return source_id, vertices, distances, previous
end

"""
    dijkstra(edges::AbstractVector{WeightedEdge}, source::Integer) -> NamedTuple

Compute shortest-path distances from `source` when every edge weight is nonnegative.
The result contains `distances` (minimum costs) and `previous` (chosen predecessors),
both keyed by vertex identifier. Unreachable vertices retain `Inf` and `nothing`.
The source has distance zero and no predecessor. The edge vector must be nonempty
and contain the source among its endpoints.

The method follows the L4c pseudocode. A min-priority queue `Q` holds the discovered vertices
that wait to be processed, each with its distance estimate as its priority. Each pass of the
main loop does three steps:

1. Select a vertex: remove the vertex `u` with the smallest estimate from `Q`.
2. Mark it as processed: skip `u` if it is already in the processed set `S`; otherwise add it.
3. Relax its outgoing edges: for each edge `u → v`, compute `alt = dist[u] + w(u,v)`. If
   `alt < dist[v]`, set `dist[v] = alt` and `prev[v] = u`, and give `v` priority `alt` in `Q`.

When every weight is nonnegative, no later route can be cheaper than the estimate of the
vertex we select, so that estimate is final.

### Arguments
- `edges::AbstractVector{WeightedEdge}`: the edges of the graph; at least one edge, and every
  weight ≥ 0.
- `source::Integer`: the source vertex `s`. It must be an endpoint of some edge.

### Returns
A `NamedTuple` with the fields:
- `distances::Dict{Int64, Float64}`: key `v` holds the shortest distance from `s` to `v`;
  `Inf` when `v` is unreachable.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: key `v` holds the vertex before `v` on the
  selected shortest route; `nothing` for the source and for unreachable vertices.

### Throws
- `ArgumentError`: an edge weight is negative, `edges` is empty, `source` is a `Bool`, or
  `source` is not a vertex of the graph.

### Example
```julia
edges = weighted_edges([(1, 2, 4.0), (1, 3, 1.0), (3, 2, 2.0), (2, 4, 1.0), (3, 4, 5.0)]);
result = dijkstra(edges, 1);
result.distances[4]   # 4.0, along the route 1 → 3 → 2 → 4
result.previous[4]    # 2
```
"""
function dijkstra(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple

    # Check the weight assumption needed to declare a selected distance final.
    # any(f, edges) is true when f(edge) is true for at least one edge; here f is the anonymous
    # function edge -> edge.weight < 0, which tests one edge for a negative weight -
    any(edge -> edge.weight < 0, edges) && throw(ArgumentError("Dijkstra requires nonnegative edge weights")) # if any weight is negative, stop with an error

    # Initialize: dist and prev for every vertex. The left side unpacks the four returned values -
    source_id, vertices, distances, previous = _initialize(edges, source)

    # Group outgoing edges so processing a vertex visits only its neighbors -
    adjacency = Dict(vertex => WeightedEdge[] for vertex in vertices) # one edge list per vertex
    for edge in edges
        push!(adjacency[edge.source], edge) # file the edge under its start vertex
    end

    # Initialize the lecture's queue Q and processed set S -
    queue = PriorityQueue{Int64, Float64}() # vertex identifiers are keys; distance estimates are priorities
    queue[source_id] = 0.0                 # only the source is discovered initially
    visited = Set{Int64}()                 # vertices whose shortest-path distances are final

    # Select the smallest tentative distance, then relax its outgoing edges -
    while !isempty(queue) # !isempty(queue) is true while the queue still holds a vertex

        # step 1, select a vertex: remove the vertex u with the smallest estimate -
        vertex = dequeue!(queue) # remove and return the vertex with the lowest distance estimate

        # step 2, mark it as processed -
        vertex in visited && continue # do not process a vertex twice: if it is already in S, skip to the next pass
        push!(visited, vertex)

        # step 3, relax its outgoing edges -
        for edge in adjacency[vertex]
            alternative = distances[vertex] + edge.weight # alternative route cost; alt(u,v) in the lecture
            if alternative < distances[edge.target] # tied costs leave the existing predecessor unchanged
                distances[edge.target] = alternative
                previous[edge.target] = vertex # record the last edge of the improved route
                queue[edge.target] = alternative # insert a new key or decrease its existing priority
            end
        end
    end

    # Return: the dist and prev maps, as a NamedTuple -
    return (distances = distances, previous = previous)
end

"""
    bellman_ford(edges::AbstractVector{WeightedEdge}, source::Integer) -> NamedTuple

Compute shortest-path distances from `source`, allowing negative edge weights.
Return `distances` and `previous`, keyed by vertex identifier; unreachable vertices
retain `Inf` and `nothing`. The edge vector must be nonempty and contain the source.
A reachable negative-weight cycle raises `ArgumentError` instead of returning a result.

The method follows the L4c pseudocode. We make at most `|V| − 1` passes over the edges, where
`|V|` is the number of vertices. Each pass does three steps:

1. Reset the change flag: `changed ← false`.
2. Relax every edge: for each edge `u → v` with `dist[u] < ∞`, compute `alt = dist[u] + w(u,v)`.
   If `alt < dist[v]`, set `dist[v] = alt`, `prev[v] = u`, and `changed ← true`.
3. Check for convergence: if no distance changed in the pass, stop the passes.

A shortest route without a cycle uses at most `|V| − 1` edges, so `|V| − 1` passes are enough.
We then check for a negative-weight cycle: we visit every edge once more, and if an edge can
still lower a distance, a cycle with negative total weight is reachable from the source, and no
shortest path exists.

### Arguments
- `edges::AbstractVector{WeightedEdge}`: the edges of the graph, in the order we relax them;
  at least one edge. Weights may be negative.
- `source::Integer`: the source vertex `s`. It must be an endpoint of some edge.

### Returns
A `NamedTuple` with the fields:
- `distances::Dict{Int64, Float64}`: key `v` holds the shortest distance from `s` to `v`;
  `Inf` when `v` is unreachable.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: key `v` holds the vertex before `v` on the
  selected shortest route; `nothing` for the source and for unreachable vertices.

### Throws
- `ArgumentError`: a negative-weight cycle is reachable from the source, `edges` is empty,
  `source` is a `Bool`, or `source` is not a vertex of the graph.

### Example
```julia
edges = weighted_edges([(1, 2, 4.0), (1, 3, 5.0), (2, 3, -2.0), (3, 4, 3.0)]);
result = bellman_ford(edges, 1);
result.distances[4]   # 5.0, along the route 1 → 2 → 3 → 4
```
"""
function bellman_ford(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple

    # Initialize: dist and prev for every vertex. The `_` discards the first returned value
    # (the source id), which we do not need here -
    _, vertices, distances, previous = _initialize(edges, source)

    # Relax every edge for at most |V|-1 passes -
    # Updates are available immediately to later edges in the same input-order scan.
    # The loop variable is `_` because we do not need the pass number.
    for _ in 1:(length(vertices) - 1)

        # step 1, reset the change flag -
        changed = false # records whether any distance improves during this complete pass

        # step 2, relax every edge -
        for edge in edges
            isfinite(distances[edge.source]) || continue # skip edges without a finite route to their start: if dist[u] is Inf, go to the next edge
            alternative = distances[edge.source] + edge.weight # alternative route cost; alt(u,v) in the lecture
            if alternative < distances[edge.target]
                distances[edge.target] = alternative
                previous[edge.target] = edge.source # record the last edge of the improved route
                changed = true
            end
        end

        # step 3, check for convergence -
        changed || break # a complete pass without improvement establishes convergence: if nothing changed, leave the loop
    end

    # Check whether a reachable edge can still improve a distance -
    # After |V|-1 passes, a further improvement contradicts the finite shortest-path bound.
    for edge in edges
        if isfinite(distances[edge.source]) && distances[edge.source] + edge.weight < distances[edge.target]
            throw(ArgumentError("graph contains a reachable negative-weight cycle"))
        end
    end

    # Return: the dist and prev maps, as a NamedTuple -
    return (distances = distances, previous = previous)
end

"""
    reconstruct_path(previous::AbstractDict, source::Integer, target::Integer) -> Vector{Int64}

Recover a route using the predecessor map from a successful shortest-path calculation
with the same source. Return an empty vector when the target is unreachable, or
`[source]` when source and target coincide. Both identifiers must appear in the map.

We start at the target and follow `prev` backward, `t → prev[t] → prev[prev[t]] → …`, until we
reach the source. That gives the route in reverse, so we reverse it at the end.

### Arguments
- `previous::AbstractDict`: the predecessor map `prev`, e.g., the `previous` field returned by
  `dijkstra` or `bellman_ford`.
- `source::Integer`: the source vertex used in that calculation.
- `target::Integer`: the vertex where the route ends.

### Returns
- `Vector{Int64}`: the route as a list of vertices, from `source` to `target`; empty when the
  target is unreachable.

### Throws
- `ArgumentError`: `source` or `target` is not a key of `previous`.

### Example
```julia
edges = weighted_edges([(1, 2, 4.0), (1, 3, 1.0), (3, 2, 2.0), (2, 4, 1.0), (3, 4, 5.0)]);
result = dijkstra(edges, 1);
reconstruct_path(result.previous, 1, 4)   # [1, 3, 2, 4]
```
"""
function reconstruct_path(previous::AbstractDict, source::Integer, target::Integer)::Vector{Int64}

    # Check that both requested endpoints belong to the predecessor map -
    source_id, target_id = Int64(source), Int64(target) # assign two variables at once
    haskey(previous, source_id) || throw(ArgumentError("source vertex is not in the predecessor map")) # if the source is not a key, stop with an error
    haskey(previous, target_id) || throw(ArgumentError("target vertex is not in the predecessor map")) # if the target is not a key, stop with an error
    source_id == target_id && return Int64[source_id] # the zero-edge route contains just the source: if source equals target, return [source] now

    # Follow predecessors backward from the target -
    path = Int64[]      # vertex identifiers accumulate in target-to-source order
    current = target_id
    while current != source_id
        push!(path, current)
        parent = previous[current] # vertex immediately before current on the selected route
        isnothing(parent) && return Int64[] # no predecessor before reaching the source means no route: if parent is nothing, return an empty route
        current = parent
    end
    push!(path, source_id)

    # put the route in source-to-target order and return it -
    reverse!(path) # return the route in source-to-target order
    return path
end

"""
    path_cost(edges::AbstractVector{WeightedEdge}, path::AbstractVector{<:Integer}) -> Float64

Sum the edge weights along consecutive vertices in `path`. An empty or single-vertex
sequence returns zero; the zero from an empty sequence does not establish reachability.
A missing edge in a longer sequence raises `ArgumentError`. For repeated endpoint
pairs in `edges`, the last supplied weight is used.

For a route `⟨v₀, v₁, …, vₖ⟩`, the cost is `w(v₀,v₁) + w(v₁,v₂) + … + w(vₖ₋₁,vₖ)`.

### Arguments
- `edges::AbstractVector{WeightedEdge}`: the edges of the graph.
- `path::AbstractVector{<:Integer}`: the route as a list of vertex ids, in travel order.
  `<:Integer` means any integer type, e.g., a `Vector{Int64}`.

### Returns
- `Float64`: the total weight of the route, in the units of the edge weights.

### Throws
- `ArgumentError`: two consecutive vertices of `path` are not joined by an edge.

### Example
```julia
edges = weighted_edges([(1, 2, 4.0), (1, 3, 1.0), (3, 2, 2.0), (2, 4, 1.0), (3, 4, 5.0)]);
path_cost(edges, [1, 3, 2, 4])   # 4.0 = 1 + 2 + 1
```
"""
function path_cost(edges::AbstractVector{WeightedEdge}, path::AbstractVector{<:Integer})::Float64

    # a route with 0 or 1 vertex has no edges, so its cost is 0 -
    length(path) <= 1 && return 0.0 # no consecutive vertex pairs contribute to the sum

    # Index edge costs by their ordered endpoints. The dictionary maps the pair
    # (source, target) to the edge weight, one entry per edge -
    weights = Dict((edge.source, edge.target) => edge.weight for edge in edges)
    total = 0.0 # accumulated route cost, in the same units as the edge weights

    # Validate and sum each directed step along the route -
    for index in 1:(length(path) - 1)
        key = (Int64(path[index]), Int64(path[index + 1])) # adjacent positions in the route vector
        haskey(weights, key) || throw(ArgumentError("path contains missing edge $(key)")) # if this step is not an edge, stop with an error
        total += weights[key] # total += x is short for total = total + x
    end

    # return the total cost of the route -
    return total
end
