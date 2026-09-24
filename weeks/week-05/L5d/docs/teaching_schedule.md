# teaching_schedule(...)

```julia
teaching_schedule(department::NamedTuple, network::NamedTuple,
    result::NamedTuple; atol::Real = 1e-8)
```

List the faculty–course assignments in an optimal result. `network` must come from [the `build_teaching_network(...)` function](build_teaching_network.md) for the same `department`, and `result` from [the `solve_flow_lp(...)` function](solve_flow_lp.md) or [the `solve_min_cost_flow(...)` function](solve_min_cost_flow.md). An infeasible result has no schedule and raises an `ArgumentError`.

Returns a `DataFrame` with one row per faculty → course edge whose flow exceeds `atol` (in assignments), in course order. The columns are `course`, `title`, `name`, `score`, and `flow`. Flows are reported as returned, without rounding; checking that they are whole assignments is a separate step.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 2 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
