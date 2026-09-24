# build_teaching_network(...)

```julia
build_teaching_network(department::NamedTuple)
```

Translate the department's rules into a flow network with lower and upper bounds. `department` comes from [the `read_department(...)` function](read_department.md) or a [scenario helper](scenario_helpers.md). One unit of flow is one faculty–course assignment, and cost is measured in survey-score points.

## Nodes

Node 1 is the source. The faculty follow in `Faculty.csv` order, then the courses in `Courses.csv` order, then one completion node per course in the same order, and the last node is the sink. Use the returned name-to-node dictionaries to identify nodes after changing the data. As in the L5a and L5b networks, a course's completion node passes its flow on to the sink.

## Edges

| Rule | Edge | Lower bound ℓ | Capacity c | Cost w |
|---|---|---|---|---|
| Exact teaching load | source → faculty | load | load | 0 |
| Survey score 0–3 | faculty → course | 0 | 1 | score, or a `with_cost` value |
| Blank input preference | faculty → course | 0 | 1 | default score 3 |
| Course staffing | course → completion | `min_faculty` | `max_faculty` | 0 |
| Course completion | completion → sink | 0 | `max_faculty` | 0 |

## Returns

A named tuple with `edges` (a `Vector{FlowEdge}`), `source`, `sink`, `required_flow` (the total teaching load), `labels` (one name per node), and the dictionaries `faculty_node`, `course_node`, and `completion_node`, which map names and course codes to node numbers.

This is the function suggested for the optional after-class exercise. See the docstring in [Compute.jl](../src/Compute.jl) and the reference in [Compute-solution.jl](../src/Compute-solution.jl), and Task 1 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
