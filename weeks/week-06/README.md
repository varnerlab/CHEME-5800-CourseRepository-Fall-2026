# Week 6 — Duality, flux balance, and iterative linear solvers

Week 6 connects three uses of linear algebra: dual variables quantify local resource
value, stoichiometric matrices enforce metabolic steady state, and stationary
iterations solve linear systems through repeated local updates.

| Meeting | Topic | Notebook |
|---|---|---|
| L6a | LP duality and sensitivity | [Lecture](L6a/CHEME-5800-L6a-Lecture-DualityAndSensitivity-Fall-2026.ipynb) |
| L6b | HL-60 urea-cycle flux balance | [Lab](L6b/CHEME-5800-L6b-Lab-UreaCycleFluxBalance-Fall-2026.ipynb) |
| L6c | Jacobi, Gauss–Seidel, SOR, and convergence | [Lecture](L6c/CHEME-5800-L6c-Lecture-StationaryIterativeMethods-Fall-2026.ipynb) |
| L6d | Residual-based solver comparison | [Lab](L6d/CHEME-5800-L6d-Lab-IterativeLinearSolvers-Fall-2026.ipynb) |

The notebooks retain the strong Fall 2025 duality, FBA, and stationary-method
explanations while replacing local environments, student/solution splits, and
unchecked solver calls with the shared course environment and tested local code.

Validate from the repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-06/runtests.jl
```
