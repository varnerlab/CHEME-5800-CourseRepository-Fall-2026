# L4d production-planning functions

These functions support the [production-planning lab](../CHEME-5800-L4d-Lab-ProductionPlanningShortestPath-Fall-2026.ipynb). Route costs use the dataset's arbitrary cost units; vertex identifiers have no physical units. The three route helpers are defined in [`src/Compute.jl`](../src/Compute.jl). The plotting helper is defined in the notebook.

<a id="route_cost"></a>
## `route_cost`

```julia
L4dProductionPlanning.route_cost(edges::AbstractDict, route::AbstractVector{<:Integer}) -> Float64
```

`edges` maps each directed `(source, target)` pair to its cost. `route` lists vertex identifiers in visit order. The function adds the costs of consecutive steps and returns the total in the same cost units. A one-vertex route costs zero. An empty route or a consecutive pair absent from `edges` raises `ArgumentError`.

<a id="reconstruct_route"></a>
## `reconstruct_route`

```julia
L4dProductionPlanning.reconstruct_route(previous::AbstractDict, target::Integer) -> Vector{Int64}
```

`previous` maps each vertex to its predecessor; a missing entry or `nothing` ends the chain. `target` is the final vertex identifier. The function follows predecessors backward, then reverses the collected identifiers to return the route in forward order. A repeated vertex in the predecessor chain raises `ArgumentError`.

If the target has no predecessor, the result is `[target]`. This helper alone does not establish reachability; the solver's distance identifies an unreachable target.

<a id="breakeven_weight"></a>
## `breakeven_weight`

```julia
L4dProductionPlanning.breakeven_weight(edges::AbstractDict,
    candidate_route::AbstractVector{<:Integer},
    reference_route::AbstractVector{<:Integer},
    step::Tuple{<:Integer, <:Integer}) -> Float64
```

`edges` contains baseline step costs. `candidate_route` must contain `step` exactly once as a consecutive vertex pair; `reference_route` must not contain it. `step` identifies the directed edge whose cost changes. Holding other costs fixed, the function returns the step cost at which the routes tie. The candidate route is strictly cheaper below that value. A negative threshold means no nonnegative step cost makes it cheaper.

Invalid step membership or a route rejected by `route_cost` must raise `ArgumentError`. Students complete the two TODOs in Task 3; the supplied stub raises an unfinished-exercise error until completed.

<a id="plotroute"></a>
## `plotroute`

```julia
plotroute(graphmodel::MySimpleDirectedGraphModel, route::Vector{Int64},
    coordinates::Matrix{Float64};
    start::Int64 = start_vertex, finish::Int64 = finish_vertex)
```

`graphmodel` supplies directed edges and costs. `route` lists the vertices of the route to highlight. Row `v` of `coordinates` holds the display position `(x, y)` for vertex `v`; these coordinates have no physical units and do not determine edge costs. `start` and `finish` select highlighted endpoints, defaulting to the notebook's endpoint variables.

The function returns the plot with the full graph, edge costs, and the chosen route in red. It assumes valid vertex-indexed coordinates and a route whose steps exist in the graph. See [Shared plotting setup](../CHEME-5800-L4d-Lab-ProductionPlanningShortestPath-Fall-2026.ipynb#Shared-plotting-setup) for its definition.
