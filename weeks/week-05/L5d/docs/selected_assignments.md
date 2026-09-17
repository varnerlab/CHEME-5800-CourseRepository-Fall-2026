# selected_assignments(...)

```julia
selected_assignments(result; workers = 2:4, tasks = 5:8, atol::Real = 1e-8)
```

Read `result.flow` and return the worker-to-task edges with flow greater than `atol`. The defaults select worker nodes 2–4 and task nodes 5–8 in this lab. The threshold uses flow units (assignments).

The return value is a vector of named tuples with fields `worker`, `task`, and `flow`, sorted by worker and task identifiers. Flow values are retained without rounding. Extraction does not establish feasibility, integrality, or optimality.

See [MinCostFlow.jl](../src/MinCostFlow.jl), loaded by [Include.jl](../Include.jl), and [Task 2 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
