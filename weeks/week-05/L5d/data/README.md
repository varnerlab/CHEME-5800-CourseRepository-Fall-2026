# L5d department data

Synthetic Fall teaching data for a small chemical engineering department. The
course codes and titles are public CHEME Fall courses; the faculty (A–J), their
loads, the staffing bounds, and every survey score are invented for this lab.
The structure follows a real faculty–course matching model, reduced to one
semester.

| File | Contents |
|---|---|
| `Faculty.csv` | `name`, `load`: each faculty member teaches exactly `load` courses. |
| `Courses.csv` | `course`, `min_faculty`, `max_faculty`, `title`: staffing bounds per course. |
| `Preferences.csv` | Survey scores, one row per faculty member and one column per course. |
| `Assignments.csv` | `name`, `course`: fixed assignments the solution must include. |

Survey scores: `0` prepared to teach, `1` comfortable teaching, `2` interested
in developing expertise, `3` needs significant support or lead time. A blank
cell means the pairing is not an option; it is different from a `3`, which is
an option with a high cost.

Preference rows and columns follow the order of `Faculty.csv` and
`Courses.csv`; [the `read_department(...)` function](../docs/read_department.md) checks this.
