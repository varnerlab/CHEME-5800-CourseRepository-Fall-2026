# Week 14 — Dominant eigenpairs and practicum launch

Week 14 has one substantive instructional meeting before Thanksgiving break.
Students compute a dominant eigenpair with power iteration and use the result to
connect three earlier and later ideas: convergence of stationary iterations,
long-run behavior of Markov models, and explicit-Euler stability. The full
eigendecomposition, QR iteration, Gram–Schmidt, and PCA treatment remains in
CHEME 5820.

| Session | Schedule | Repository disposition |
|---|---|---|
| L14a | Dominant eigenpairs, power iteration, and spectral reasoning | [Notebook](L14a/CHEME-5800-L14a-Lecture-DominantEigenpairs-PowerIteration-Fall-2026.ipynb) |
| L14b | Practicum release and QA session | Assessment is managed outside this course-content repository |
| L14c | Thanksgiving break | No class |
| L14d | Thanksgiving break | No class |

L14a adapts the power-iteration prerequisite from CHEME 5820 Spring 2026 Week 2
without importing its full two-lecture eigendecomposition unit. The practicum
problem and solution follow the separate assessment-repository workflow. They are
not duplicated or linked prematurely from this weekly package.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl
```
