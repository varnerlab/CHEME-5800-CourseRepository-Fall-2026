# Week 15 — Numerical solution of initial value problems

Week 15 opens with initial value problems and explicit methods. The lecture
derives Euler and Runge–Kutta updates. The worked example compares both methods
with a library solver on gene circuits and tests the Euler step limit.

| Session | Schedule | Repository disposition |
|---|---|---|
| L15a | Initial value problems and explicit methods | [Lecture](L15a/CHEME-5800-L15a-Lecture-InitialValueProblems-Fall-2026.ipynb) · [Example](L15a/CHEME-5800-L15a-Example-ExplicitMethods-Fall-2026.ipynb) |
| L15b | Solve a gene circuit with a library solver, and implement explicit Euler and RK4 | [Lab](L15b/CHEME-5800-L15b-Lab-ExplicitMethods-Fall-2026.ipynb) |
| L15c | Integration and CHEME 5820 bridge | [Notebook](L15c/CHEME-5800-L15c-Lecture-StateUpdatesAnd5820Bridge-Fall-2026.ipynb) |
| L15d | Mixed-sugar fermentation with a maintained ODE solver | [Lab](L15d/CHEME-5800-L15d-Lab-MixedSugarFermentation-Fall-2026.ipynb) |

The three-gene model is adapted from the 2024 Lab 9b source. The fermentation case
is adapted from 2024 Lab 9d. The maintained-solver comparisons use
`OrdinaryDiffEq.Tsit5` through the shared root environment.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl
```
