# read_department(...)

```julia
read_department(folder::AbstractString)
```

Read the four department tables in `folder` and check that they agree. The lab passes `CHEME5800_L5D_DATA`, the local [data folder](../data/README.md).

## Files

| File | Columns | Meaning |
|---|---|---|
| `Faculty.csv` | `name`, `load` | Each faculty member teaches exactly `load` courses this semester. |
| `Courses.csv` | `course`, `min_faculty`, `max_faculty`, `title` | Staffing bounds, counted in instructors. |
| `Preferences.csv` | `name`, then one column per course | Survey scores 0–3; a blank cell means the pairing is not an option. |
| `Assignments.csv` | `name`, `course` | Fixed assignments that every schedule must include. |

## Returns

A named tuple with `faculty`, `courses`, and `preferences` (`DataFrame`s in file order, with blank scores stored as `missing`), `fixed` (a vector of `(name, course)` pairs), and `costs` (empty; [the `with_cost(...)` function](scenario_helpers.md) adds costs that replace survey scores).

## Checks

Names and course codes must be unique. Preference rows and columns must follow the order of `Faculty.csv` and `Courses.csv`. Loads and staffing bounds must be nonnegative integers, with `min_faculty ≤ max_faculty`. Scores must be 0, 1, 2, 3, or blank, and a fixed assignment must name a pairing that has a score. The first problem found raises an `ArgumentError`. These checks concern the tables themselves; whether a schedule exists is decided by the solver.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 1 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
