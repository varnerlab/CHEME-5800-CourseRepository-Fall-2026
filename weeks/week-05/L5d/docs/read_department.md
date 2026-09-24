# read_department(...)

```julia
read_department(folder::AbstractString)
```

Read the department tables in `folder` and check that they agree. The lab passes `CHEME5800_L5D_DATA`, the local [data folder](../data/README.md).

## Files

| File | Columns | Meaning |
|---|---|---|
| `Faculty.csv` | `name`, `load` | Each faculty member teaches exactly `load` courses this semester. |
| `Courses.csv` | `course`, `min_faculty`, `max_faculty`, `title` | Staffing bounds, counted in instructors. |
| `Preferences.csv` | `name`, then one column per course | Survey scores 0–3; a blank cell receives the default score 3, keeping the pairing available. |

## Returns

A named tuple with `faculty`, `courses`, and `preferences` (`DataFrame`s in file order, with blank preferences replaced by 3), and `costs` (empty; [the `with_cost(...)` function](scenario_helpers.md) adds costs that replace survey scores). The input CSV is not modified; its blanks distinguish unspecified preferences from supplied responses.

## Checks

Names and course codes must be unique. Preference rows and columns must follow the order of `Faculty.csv` and `Courses.csv`. Loads and staffing bounds must be nonnegative integers, with `min_faculty ≤ max_faculty`. Input scores must be 0, 1, 2, 3, or blank; loaded scores are 0–3. The first problem found raises an `ArgumentError`. These checks concern the tables themselves; whether a schedule exists is decided by the solver.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 1 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
