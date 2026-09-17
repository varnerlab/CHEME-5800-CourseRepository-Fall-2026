# `validate_sensitivity_flow(...)`

```julia
validate_sensitivity_flow(graph, flow::AbstractDict, source::Integer, sink::Integer; atol::Real = 1e-8)
```

Check a candidate flow independently and recompute its net source outflow.

## Arguments

- `graph`: Directed graph with node models and a capacity dictionary of edge pairs and `(lower, upper)` flow bounds.
- `flow`: Dictionary mapping directed edge pairs to numeric flows. Missing graph edges carry zero flow. A key absent from the graph invalidates the capacity check.
- `source`, `sink`: Distinct source and sink node identifiers present in the graph.
- `atol`: Nonnegative absolute tolerance, in assignments for this lab. The default is `1e-8`.

## Returned values

| Field | Meaning |
|:---|:---|
| `capacity_ok` | All flows respect zero lower bounds and edge upper capacities within the tolerance, and all supplied keys identify graph edges. |
| `conservation_ok` | Incoming and outgoing flows balance at intermediate nodes within the tolerance. |
| `balance_ok` | Net source outflow and net sink inflow agree within the tolerance. |
| `valid` | All three preceding checks pass. |
| `value` | Net source outflow calculated from the edge-flow dictionary, in assignments. |
| `residuals` | Dictionary of incoming minus outgoing flow at each node, in assignments. |

## Assumptions and interpretation

Use zero lower flow bounds and finite numeric capacities and flows. The helper does not enforce nonzero lower bounds. It checks feasibility; the caller must compare `value` with the algorithm's reported total and use a cut-capacity bound to establish optimality.

See the docstring in [FlowValidation.jl](../src/FlowValidation.jl) and [Task 1 of the L5b lab](../CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb), which loads this helper through [Include.jl](../Include.jl).
