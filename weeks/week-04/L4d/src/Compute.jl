# Student implementation for the L4d production-planning lab. Complete the
# two TODOs in `breakeven_weight(...)`, save the file, and re-run the notebook's
# setup cell to reload this module. The Task 3 test cell is the definition of done.
module L4dProductionPlanning

export breakeven_weight, reconstruct_route, route_cost

"""
    reconstruct_route(previous::AbstractDict, target::Integer) -> Vector{Int64}

Follow predecessors backward from `target` and return the route from the start
vertex to `target`, in visiting order.

### Arguments
- `previous::AbstractDict`: Maps each vertex id to its predecessor on the
  shortest path, as returned by `findshortestpath(...)`. The start vertex has no
  predecessor: it is either absent from the map or maps to `nothing`.
- `target::Integer`: The vertex the route ends at.

### Returns
- `Vector{Int64}`: The vertex ids from the start vertex to `target`. A target the
  search never reached has no predecessor, so its route is `[target]`.

### Errors
- `ArgumentError`: The predecessor chain revisits a vertex, which a valid
  shortest-path tree never does.
"""
function reconstruct_route(previous::AbstractDict, target::Integer)::Vector{Int64}
    route = Int64[]
    seen = Set{Int64}()
    current = Int64(target)

    # Walk backward until a vertex has no predecessor; the guard rejects a map
    # that loops, which would otherwise never terminate.
    while !isnothing(current)
        current in seen && throw(ArgumentError("predecessor map revisits vertex $(current)"))
        push!(seen, current)
        push!(route, current)
        current = get(previous, current, nothing)
    end
    return reverse!(route)
end

"""
    route_cost(edges::AbstractDict, route::AbstractVector{<:Integer}) -> Float64

Sum the costs of the consecutive steps on `route`.

### Arguments
- `edges::AbstractDict`: Maps each `(source, target)` pair to its cost, which is
  the `edges` field of a graph model.
- `route::AbstractVector{<:Integer}`: The vertex ids of the route, in order.

### Returns
- `Float64`: The total cost of the route. A route with one vertex costs zero.

### Errors
- `ArgumentError`: `route` is empty, or a consecutive pair of vertices on
  `route` is not a key in `edges`.
"""
function route_cost(edges::AbstractDict, route::AbstractVector{<:Integer})::Float64

    # An empty route has no first vertex, so it is rejected.
    isempty(route) && throw(ArgumentError("route must contain at least one vertex"))

    # Add the cost of each consecutive step, rejecting a pair that is not an
    # edge of the graph.
    cost = 0.0
    for i in 1:(length(route) - 1)
        step = (Int64(route[i]), Int64(route[i + 1]))
        haskey(edges, step) || throw(ArgumentError("route step $(step) is not an edge in the graph"))
        cost += edges[step]
    end
    return cost
end

"""
    breakeven_weight(edges::AbstractDict, candidate_route, reference_route,
                     step::Tuple{<:Integer, <:Integer}) -> Float64

Return the cost of `step` at which `candidate_route` costs the same as
`reference_route`, holding every other cost fixed. The candidate route is
strictly cheaper for any cost of `step` below the returned value.

### Arguments
- `edges::AbstractDict`: The baseline `(source, target) => cost` dictionary.
- `candidate_route::AbstractVector{<:Integer}`: The route that contains `step`
  exactly once.
- `reference_route::AbstractVector{<:Integer}`: The route it competes against.
  It must not contain `step`, otherwise the discount would move both costs.
- `step::Tuple{<:Integer, <:Integer}`: The `(source, target)` pair whose cost
  is being discounted.

### Returns
- `Float64`: The break-even cost of `step`. A negative value means no
  nonnegative cost makes the candidate route cheaper.

### Errors
- `ArgumentError`: `step` does not appear exactly once as a consecutive pair on
  `candidate_route`, `step` appears on `reference_route`, or either route fails
  the checks in `route_cost(...)`.
"""
function breakeven_weight(edges::AbstractDict, candidate_route::AbstractVector{<:Integer},
    reference_route::AbstractVector{<:Integer}, step::Tuple{<:Integer, <:Integer})::Float64

    # TODO 1: Check that `step` appears exactly once as a consecutive pair on
    # `candidate_route` and never on `reference_route`; throw an ArgumentError
    # otherwise.

    # TODO 2: Compute the cost of both routes with route_cost(...) and return the
    # break-even cost from the formula in Task 3 of the notebook.

    throw(ErrorException("Oooops! The `breakeven_weight(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 and TODO 2."))
end

end # module
