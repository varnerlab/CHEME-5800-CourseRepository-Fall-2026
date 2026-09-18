# `build_sensitivity_graph(...)`

```julia
build_sensitivity_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)
```

Read the worker–task edge list and return a `MyDirectedBipartiteGraphModel` containing node models, directed edges, and a capacity dictionary.

## Arguments

- `path`: Path to a comma-separated file with source node, target node, cost, lower capacity, and upper capacity in each edge record. Lines beginning with `#` are comments.
- `source`, `sink`: Distinct node identifiers present in the data. The course solver uses contiguous integer node identifiers starting at one.

## Returned values and units

The returned graph stores capacity bounds as `graph.capacity[(u, v)] = (lower, upper)`. Each bound is measured in assignments in this lab. The solver uses the upper capacity; cost is not part of the maximum-flow objective.

## Assumptions

The input file must exist. Use a directed flow network with zero lower flow bounds and finite, nonnegative upper capacities. The supplied dataset meets these requirements; the builder does not validate every solver assumption.

See the docstring in [Compute.jl](../src/Compute.jl) and [Task 1 of the L5b lab](../CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb), which loads this helper through [Include.jl](../Include.jl).
