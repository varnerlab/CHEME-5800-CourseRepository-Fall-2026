# Week 5 — Maximum flow and linear programming

Week 5 turns graph structure into optimization models. Students first compute and
independently validate maximum flow, then study how capacity changes alter network
throughput. The second half expresses resource allocation and flow conservation as
linear programs and closes with a minimum-cost worker–task assignment.

## Learning objectives

By the end of the week, students should be able to:

1. formulate a capacitated source-to-sink flow problem;
2. explain augmenting paths and residual capacity in Ford–Fulkerson;
3. compare Ford–Fulkerson and Edmonds–Karp results;
4. validate capacity, conservation, and source/sink balance independently;
5. identify decision variables, objectives, constraints, and bounds in an LP;
6. interpret primal and dual resource-allocation viewpoints;
7. formulate minimum-cost flow as an incidence-matrix LP; and
8. extract and validate assignment decisions from edge-flow variables.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L5a | Mon. Sep. 21 | Maximum-flow formulation and augmenting paths | [Lecture](L5a/CHEME-5800-L5a-Lecture-MaximumFlowProblems-Fall-2026.ipynb) · [Worked example](L5a/CHEME-5800-L5a-WorkedExample-MaximumFlow-Fall-2026.ipynb) |
| L5b | Tue. Sep. 22 | Capacity sensitivity, bottlenecks, and outages | [Lab](L5b/CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb) |
| L5c | Wed. Sep. 23 | Linear-program formulation and resource allocation | [Lecture](L5c/CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb) · [Fruit allocation](L5c/CHEME-5800-L5c-Example-FruitAllocation-Fall-2026.ipynb) · [Revised simplex](L5c/CHEME-5800-L5c-Algorithm-RevisedSimplex-Fall-2026.ipynb) |
| L5d | Thu. Sep. 24 | Minimum-cost assignment as a network-flow LP | [Lab](L5d/CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb) |

The revised-simplex notebook is the week's selected supporting algorithm notebook.
Interior-point derivations and extended duality proofs remain deeper-study topics;
they are not parallel required notebooks.

## Environment and validation

Each meeting-local `Include.jl` delegates to the single root `Project.toml` and
`Manifest.toml`. All package imports are centralized in those include files, and
the LP examples use meeting-local JuMP/GLPK models with explicit validation.

From the authoring-repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-05/runtests.jl
```

Problem sets and their simultaneously released solutions are managed in separate
repositories and are not part of this weekly instructional package.

## Source adaptation

- L5a retains the detailed Fall 2025 maximum-flow formulation, residual-graph
  explanation, worker–task example, and capacity scenarios. Fall 2026 adds a
  deterministic Edmonds–Karp comparison and independent flow contracts.
- L5b retains the strongest completed Fall 2025 lab path without publishing a
  student/solution pair. The capacity expansion and worker outage are now explicit,
  executable scenarios with assertions.
- L5c retains the Fall 2025 primal/dual lecture, fruit-allocation geometry, SVG
  schematic, and revised-simplex narrative. The example now uses the current JuMP
  API directly and handles alternate optima deliberately.
- L5d retains the Fall 2025 assignment-network formulation while replacing the
  degenerate equal assignment costs with documented synthetic costs. The new local
  model exposes `A`, `b`, bounds, residuals, and selected assignments for testing.
