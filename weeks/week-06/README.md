# Week 6 — Flux balance analysis and iterative linear solvers

Week 6 applies the linear programs of week 5 to metabolism and then turns to
iterative methods for linear systems. Flux balance analysis encodes a metabolic
network as a stoichiometric matrix, requires every metabolite to balance at steady
state, and maximizes a biological objective subject to flux bounds. Stationary
iterations then solve linear systems through repeated local updates.

| Meeting | Topic | Notebooks |
|---|---|---|
| L6a | Flux balance analysis | [Lecture](L6a/CHEME-5800-L6a-Lecture-FluxBalanceAnalysis-Fall-2026.ipynb) · [Advanced derivation](L6a/CHEME-5800-L6a-Advanced-Derivation-FluxBalanceAnalysis-Fall-2026.ipynb) · [SVD of a stoichiometric matrix](L6a/CHEME-5800-L6a-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb) · [HL-60 urea-cycle example](L6a/CHEME-5800-L6a-Example-UreaCycle-FluxBalance-Fall-2026.ipynb) |
| L6b | Overflow metabolism in *E. coli* | [Lab](L6b/CHEME-5800-L6b-Lab-OverflowMetabolism-Fall-2026.ipynb) |
| L6c | Jacobi, Gauss–Seidel, SOR, and convergence | [Lecture](L6c/CHEME-5800-L6c-Lecture-GeneralIterativeMethod-Fall-2026.ipynb) · [Iterative-solvers example](L6c/CHEME-5800-L6c-Example-FunWithIterativeSolvers-Fall-2026.ipynb) |
| L6d | Residual-based solver comparison | [Lab](L6d/CHEME-5800-L6d-Lab-IterativeLinearSolvers-Fall-2026.ipynb) |

The flux balance material is adapted from the CHEME 5430/5450 Spring 2026 lecture
([varnerlab/Lecture-5430-FluxBalanceAnalysis](https://github.com/varnerlab/Lecture-5430-FluxBalanceAnalysis)).
L6a's code is in `L6a/src/`, loaded by `L6a/Include.jl`.

## L6c supporting material

The complete 2025 L6c notebook set has been imported for review, with 2026
filenames and links. The lecture and example are linked above; companion notes
develop each algorithm and the convergence condition:

- [Jacobi method](L6c/CHEME-5800-L6c-Algorithm-JacobiMethod-Fall-2026.ipynb)
- [Gauss–Seidel method](L6c/CHEME-5800-L6c-Algorithm-GaussSeidel-Fall-2026.ipynb)
- [Successive over-relaxation](L6c/CHEME-5800-L6c-Algorithm-SOR-Fall-2026.ipynb)
- [Spectral-radius convergence derivation](L6c/CHEME-5800-L6c-Advanced-Convergence-IterativeMethods-Fall-2026.ipynb)

The [HTML exports](L6c/html/CHEME-5800-L6c-Lecture-GeneralIterativeMethod-Fall-2026.html)
are also available. The existing
[2026 stationary-methods draft](L6c/CHEME-5800-L6c-Lecture-StationaryIterativeMethods-Fall-2026.ipynb)
is retained for comparison. The imported example retains its saved 2025 outputs
and uses the shared 2026 environment through [Include.jl](L6c/Include.jl).
Content and execution review of the imported material is pending.

## Lab implementations and reference solutions

L6b is walked through in class, so its [Compute.jl](L6b/src/Compute.jl) ships
complete and matches [Compute-solution.jl](L6b/src/Compute-solution.jl) apart from
its header. Rebuilding `solve_growth(...)` from its docstring is an optional
exercise. The lab's model, `L6b/data/e_coli_core.json`, is the BiGG *E. coli* core
model (Orth et al. 2010).

Validate from the repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-06/runtests.jl
```
