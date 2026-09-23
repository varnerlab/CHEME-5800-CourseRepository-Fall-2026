# Scenario helpers

```julia
with_preference(department, name, course, score)
with_cost(department, name, course, cost)
with_load(department, name, load)
with_staffing(department, course, min_faculty, max_faculty)
with_fixed(department, name, course)
```

Each helper returns a changed copy of `department` and leaves the input unchanged, so the original data stay available. The copy is checked with the same rules as [the `read_department(...)` function](read_department.md), and a violation raises an `ArgumentError`. Helpers can be chained, for example `with_preference(with_load(department, "B", 0), "G", "CHEME-2880", 2)`.

| Helper | Changes | Kind of change |
|---|---|---|
| `with_preference` | The survey score for `name` and `course`: 0–3, or `missing` for a blank, which removes the option. Clears any `with_cost` change for the pairing. | Cost, or an option |
| `with_cost` | The cost of the edge `name` → `course`, to any finite value in score points; a value below zero is a bonus. The pairing must be an option. | Cost |
| `with_load` | Faculty member `name`'s teaching load; zero models a sabbatical. | Bound |
| `with_staffing` | The minimum and maximum number of instructors for `course`. | Bound |
| `with_fixed` | Adds the fixed assignment `name` → `course`, such as a department mandate; the pairing must be an option. | Bound |

A cost change keeps every schedule feasible and changes only which one is cheapest. A bound change can remove schedules, and can leave none, as the lab's sabbatical does. Build a new network from the returned copy with [the `build_teaching_network(...)` function](build_teaching_network.md) before solving.

See the docstrings in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 3 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
