# flow_formulation(...)

```julia
flow_formulation(edges::AbstractVector{FlowEdge}, source::Integer,
    sink::Integer, required_flow::Real)
```

Assemble the objective coefficients, node conservation equations, and bounds for a minimum-cost flow model. This helper returns model data; it does not solve the model.

## Arguments and units

- `edges`: Directed edge records in the desired column order. Each record supplies the source and target node identifiers, cost per assignment, and lower and upper flow bounds.
- `source`, `sink`: Distinct node identifiers present in the edge records.
- `required_flow`: Finite, nonnegative net source-to-sink flow, measured in assignments in this lab. Use the same flow units as the edge bounds.

## Returned fields

| Field | Meaning |
|---|---|
| `vertices` | Node identifiers in ascending order; these define the row order. |
| `A` | Node–edge incidence matrix: −1 at an edge's source and +1 at its target. Columns follow the supplied edge order. |
| `b` | Required net inflows: negative at the source, positive at the sink, and zero at intermediate nodes. |
| `c` | Costs in synthetic cost units per assignment; denoted by **w** in the notebook. |
| `lower`, `upper` | Edge flow bounds, measured in assignments. |

## Assumptions and scope

Each `FlowEdge` has distinct endpoints, finite costs and bounds, and `0 ≤ lower ≤ upper`. Node identifiers need not be consecutive; use `vertices` to interpret matrix rows. The routine validates the source, sink, and required-flow argument, but does not establish that the requested flow is feasible. In particular, assembling the arrays with a required flow of four does not prove this lab's three-worker network can deliver it.

See the source docstring in [Compute.jl](../src/Compute.jl), loaded through [Include.jl](../Include.jl), and [Task 1 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
