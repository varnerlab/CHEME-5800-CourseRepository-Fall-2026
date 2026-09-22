# block_assignments(...)

```julia
block_assignments(edges::AbstractVector{FlowEdge}, pairs)
```

Return a copy of `edges` in which every `(source, target)` pair in `pairs` has both flow bounds set to zero. The blocked edges keep their endpoints and cost, so they remain in the model and in `result.flow`, but they can carry no flow. The input vector is not modified, which keeps the original network available for comparison.

## Arguments

- `edges`: Directed edge records in the order used by the flow variables.
- `pairs`: A collection of `(source, target)` node-identifier pairs to block. Each pair must name an edge in `edges`; otherwise an `ArgumentError` is thrown.

## Scope

Blocking does not check whether the required flow remains feasible. If the blocked edges leave too little capacity, the solver reports an infeasible model and [the `solve_min_cost_flow(...)` function](solve_min_cost_flow.md) stops with an error.

See [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and [Task 3 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
