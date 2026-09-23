# solve_min_cost_flow(...)

```julia
solve_min_cost_flow(network)
```

Assemble the linear program for `network` with [the `flow_formulation(...)` function](flow_formulation.md) and solve it with [the `solve_flow_lp(...)` function](solve_flow_lp.md). `network` comes from [the `build_teaching_network(...)` function](build_teaching_network.md), whose nodes are numbered 1, 2, ..., n. The lab uses this shortcut for the live changes in Task 3, where rebuilding the arrays by hand would repeat Task 2.

Returns the same named tuple as [the `solve_flow_lp(...)` function](solve_flow_lp.md): `status`, `optimal`, `flow`, `vector`, `cost`, and `formulation`. When the status is not `OPTIMAL`, for example `INFEASIBLE`, the flow fields and the cost are `nothing`.

See [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 3 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
