# assignments_by_faculty(...)

```julia
assignments_by_faculty(department::NamedTuple, schedule::AbstractDataFrame)
```

Summarize a schedule from [the `teaching_schedule(...)` function](teaching_schedule.md) by faculty member: the teaching-assignment table a department would publish.

Returns a `DataFrame` with one row per faculty member, in `Faculty.csv` order: `name`, `load`, `courses` (the assigned course codes joined with commas, or `"none"`), and `scores` (the matching survey scores, in the same order as the courses).

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 2 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
