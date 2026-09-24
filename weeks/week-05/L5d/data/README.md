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
| `Preferences.csv` | Supplied survey scores, one row per faculty member and one column per course; blanks receive the default score when loaded. |

Survey scores: `0` prepared to teach, `1` comfortable teaching, `2` interested
in developing expertise, `3` needs significant support or lead time. A blank
cell receives the default score `3` when the data are loaded. The pairing is
available at the highest survey cost. This default is a modeling assumption,
not a supplied survey response; the CSV retains blanks to preserve that distinction.

A course with staffing bounds `0–1` is optional: it is not taught if no faculty
member is assigned, and runs with one instructor otherwise. Bounds `1–1`
require it to run with one instructor. Every faculty member assigned to a
team-taught course uses one teaching assignment.

Preference rows and columns follow the order of `Faculty.csv` and
`Courses.csv`; [the `read_department(...)` function](../docs/read_department.md) checks this.
