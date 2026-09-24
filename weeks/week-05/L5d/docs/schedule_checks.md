# schedule_checks(...)

```julia
schedule_checks(department::NamedTuple, schedule::AbstractDataFrame; atol::Real = 1e-8)
```

Count each faculty member's assignments and each course's staffing in a schedule from [the `teaching_schedule(...)` function](teaching_schedule.md), and compare the counts with the department's rules.

Returns a named tuple with two `DataFrame`s and a summary flag:

| Field | Columns | Check |
|---|---|---|
| `loads` | `name`, `required`, `assigned`, `ok` | Each faculty member teaches exactly their load. |
| `staffing` | `course`, `min_faculty`, `assigned`, `max_faculty`, `ok` | Each course's staffing lies within its bounds. |
| `all_ok` | | Every row of both tables passes. |

Counts add the schedule's flow values, so they are whole numbers only for a whole-number schedule; `atol` is an absolute tolerance in assignments. This check works from the schedule, while [the `validate_flow_solution(...)` function](validate_flow.md) works from the flow model.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 2 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
