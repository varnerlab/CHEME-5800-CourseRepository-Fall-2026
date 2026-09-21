# `cut_capacity(...)`

```julia
cut_capacity(graph, S)
```

Sum the upper capacities of the edges directed from the node set `S` to the remaining nodes `T`.

## Arguments

- `graph`: Directed graph with a capacity dictionary of edge pairs `(u, v)` and `(lower, upper)` flow bounds.
- `S`: Collection of node identifiers on the source side of the cut. For a source–sink cut, `S` contains the source and not the sink. The function does not check this.

## Returned value

The cut capacity $c(S,T)$, in assignments for this lab: the sum of the upper bounds on edges whose first endpoint is in `S` and whose second endpoint is not. Edges directed from `T` back into `S` do not contribute.

## Interpretation

For a source–sink cut, every unit of flow from the source to the sink must cross from `S` to `T` on one of the counted edges, so every feasible flow value is at most $c(S,T)$. This holds for every `S` that contains the source and not the sink; other sets give no bound. A feasible flow whose value equals some cut's capacity is a maximum flow, and that cut is a minimum cut.

See the docstring in [Compute.jl](../src/Compute.jl) and [Task 1 of the L5b lab](../CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb), which loads this helper through [Include.jl](../Include.jl).
