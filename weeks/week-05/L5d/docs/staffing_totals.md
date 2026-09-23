# staffing_totals(...)

```julia
staffing_totals(department)
```

Compare the total teaching load with the total staffing the courses require and allow. Returns a named tuple with `total_load`, `total_min`, `total_max`, and `totals_ok`, all counted in assignments.

Every assignment uses one unit of some faculty member's load and fills one staffing position in some course, so a schedule can exist only when `total_min ≤ total_load ≤ total_max`. The check is necessary but not sufficient: it ignores which faculty can teach which courses. The lab's sabbatical scenario passes it and is still infeasible.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 1 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
