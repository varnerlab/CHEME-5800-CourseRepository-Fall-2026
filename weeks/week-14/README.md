# Week 14 — Linear state space models and practicum launch

Week 14 has one instructional meeting before Thanksgiving break. Students solve linear
time-invariant state space models, read the stability of a steady state from the eigenvalues of
the state matrix, and solve a model with an input using the discretization of the S4 sequence
model. An example linearizes a self-activating gene about a steady state and compares the linear
and nonlinear responses to a pulse of an inducer.

## Session sequence

| Session | Topic | Language | Notebook |
|---|---|---|---|
| L14a | Linear state space models: the open-loop solution, stability from the eigenvalues, the S4 discretization, and linearization | Julia | [Lecture](L14a/CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb), [example](L14a/CHEME-5800-L14a-Example-GeneSwitch-Fall-2026.ipynb), and [advanced notebook](L14a/CHEME-5800-L14a-Advanced-ComputingEigenvalues-Fall-2026.ipynb) |
| L14b | Practicum release and QA session | | Assessment is managed outside this course-content repository |
| L14c | Thanksgiving break | | No class |
| L14d | Thanksgiving break | | No class |

## Data and execution contracts

- The L14a example builds three gene networks from TOML files in the course package, in `code/src/data/motifs`. The network builder and the discretization are in `code/src/GeneNetworks.jl`. The example ships with outputs.
- The advanced notebook computes eigenvalues with the power iteration and QR iteration functions of the course package, in `code/src/Eigen.jl`, and compares each result with the `eigen` function of the `LinearAlgebra` package.

The advanced notebook is refactored from the CHEME 5820 Spring 2026 eigenvalue lectures. Gram–Schmidt
and principal component analysis remain in CHEME 5820. The gene expression model follows a chapter by
J. D. Varner, in preparation for _Comprehensive Biotechnology_ (4th edition), and the network motifs
follow Shoval and Alon, _Cell_ 143 (2010).

The practicum problem and solution follow the separate assessment-repository workflow. They are
not duplicated or linked prematurely from this weekly package.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl
```
