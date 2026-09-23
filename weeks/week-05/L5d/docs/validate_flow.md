# validate_flow_solution(...)

```julia
validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)
```

Check an optimal result's flow vector against the supplied edge bounds, recompute every node's inflow minus outflow from the edge endpoints, and recompute the total cost. Supply the edges in the same order as `result.vector`. The expected node identifiers and net inflows are taken from `result.formulation`. A result whose status is not `OPTIMAL` has no flows, and passing one raises an `ArgumentError`.

`atol` is a finite nonnegative absolute tolerance, applied to flow values (assignments) and cost differences (survey-score points). Relative tolerance is zero. The default suits this lab's small whole-number data.

The returned flags are `valid`, `bounds_ok`, `balance_ok`, and `objective_ok`, together with `maximum_balance_residual` and `recomputed_cost`. The helper does not reuse the solver's incidence matrix. It does not establish integrality or optimality, and it does not know about faculty or courses; [the `schedule_checks(...)` function](schedule_checks.md) checks the department's rules.

See the full docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 2 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
