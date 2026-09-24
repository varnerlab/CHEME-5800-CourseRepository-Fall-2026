# Scenario helpers

```julia
with_preference(department::NamedTuple, name::AbstractString,
    course::AbstractString, score::Union{Real,Missing})
with_cost(department::NamedTuple, name::AbstractString, course::AbstractString, cost::Real)
with_load(department::NamedTuple, name::AbstractString, load::Integer)
with_staffing(department::NamedTuple, course::AbstractString,
    min_faculty::Integer, max_faculty::Integer)
```

Each helper returns a changed copy of `department` and leaves the input unchanged, so the original data stay available. The copy is checked with the same rules as [the `read_department(...)` function](read_department.md), and a violation raises an `ArgumentError`. Helpers can be chained, for example `with_preference(with_load(department, "B", 0), "G", "CHEME-2880", 2)`.

| Helper | Changes | Kind of change |
|---|---|---|
| `with_preference` | The score for `name` and `course`: 0–3, or `missing` to restore the default 3. Clears any `with_cost` change for the pairing; the edge remains available. | Cost |
| `with_cost` | The cost of the edge `name` → `course`, to any finite value in score points; a value below zero is a bonus. The pairing must be an option. | Cost |
| `with_load` | Faculty member `name`'s teaching load; zero models a sabbatical. | Bound |
| `with_staffing` | The minimum and maximum number of instructors for `course`. | Bound |

A cost change preserves the feasible schedules and changes only which one is cheapest. A bound change can remove schedules or leave none. The sabbatical can be covered using a default-score pairing. Increasing course staffing beyond the available teaching load would instead make the model infeasible. Build a new network from the returned copy with [the `build_teaching_network(...)` function](build_teaching_network.md) before solving.

See the docstrings in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 3 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
