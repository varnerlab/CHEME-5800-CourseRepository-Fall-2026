# validate_flow_solution(...)

```julia
validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)
```

Check `result.vector` against the supplied edge bounds, recompute every node's inflow minus outflow from the edge endpoints, and recompute total cost. Supply edges in the same order as the candidate vector. The expected node identifiers and net inflows are taken from `result.formulation.vertices` and `result.formulation.b`; preserve these model inputs when editing a candidate.

`atol` is a finite nonnegative absolute tolerance, applied to flow values (assignments) and cost differences (synthetic cost units). Relative tolerance is zero. The default suits this lab's small values; choose tolerances consistent with the scale and units of other problems.

The returned flags are `valid`, `bounds_ok`, `balance_ok`, and `objective_ok`. The result also includes the freshly computed `residual`, `maximum_balance_residual`, and `recomputed_cost`. The helper does not trust the saved incidence matrix or residual. It checks the vector representation, not `result.flow`, and does not establish integrality or optimality.

See the full docstring in [MinCostFlow.jl](../src/MinCostFlow.jl), loaded by [Include.jl](../Include.jl), and [Task 2 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
