# solve_min_cost_flow(...)

```julia
solve_min_cost_flow(edges::AbstractVector{FlowEdge}, source::Integer,
    sink::Integer, required_flow::Real)
```

Construct and solve a continuous minimum-cost flow model using JuMP and GLPK. Supply directed edge records, distinct source and sink identifiers, and a finite nonnegative required flow. Bounds and the required flow are measured in assignments in this lab; edge costs are measured in synthetic cost units per assignment. Directed edge pairs must be unique.

The returned named tuple contains `flow` (edge-pair dictionary), `vector` (input edge order), `cost` (solver-reported objective), `residual` (matrix balance residual), `status`, and `formulation` (the assembled model inputs). An `OPTIMAL` termination status is required; other statuses raise an error. The returned data still require independent checks of feasibility and cost.

See [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and [Task 2 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
