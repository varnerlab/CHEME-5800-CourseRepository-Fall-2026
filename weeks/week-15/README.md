# Week 15 — Dynamics as algorithms and the CHEME 5820 bridge

Week 15 is a full instructional week on numerical dynamics. Students build
explicit Euler to expose state updates, step-size error, and stability; test it on
a three-gene dynamic model; connect discretization to state-space and learned
updates; and then use a maintained solver for a mixed-sugar fermentation model.

| Session | Schedule | Repository disposition |
|---|---|---|
| L15a | Explicit Euler, stability, and build-versus-buy ODE solvers | [Notebook](L15a/CHEME-5800-L15a-Lecture-DynamicsAsAlgorithms-Fall-2026.ipynb) |
| L15b | Implement and test Euler on a three-gene dynamic model | [Lab](L15b/CHEME-5800-L15b-Lab-ThreeGeneDynamics-Fall-2026.ipynb) |
| L15c | Integration and CHEME 5820 bridge | [Notebook](L15c/CHEME-5800-L15c-Lecture-StateUpdatesAnd5820Bridge-Fall-2026.ipynb) |
| L15d | Mixed-sugar fermentation with a maintained ODE solver | [Lab](L15d/CHEME-5800-L15d-Lab-MixedSugarFermentation-Fall-2026.ipynb) |

The three-gene model is adapted from the 2024 Lab 9b source. The fermentation case
is adapted from 2024 Lab 9d. The maintained-solver comparisons use
`OrdinaryDiffEq.Tsit5` through the shared root environment.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl
```
