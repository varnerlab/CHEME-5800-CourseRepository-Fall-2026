# CHEME 4800/5800 — Fall 2026

Principles of Computational Thinking for Engineers, Cornell University.

This site documents the course code library. All logic used by the lectures, labs,
and problem sets lives in this repository under `code/` — there is no external
package to install and no registry to add.

## Using the library

Every course notebook activates the repository root environment and loads the
library the same way:

```julia
using VLDataScienceMachineLearningPackage
```

## Where things live

| Path | Contents |
|---|---|
| `code/` | The course library: types, factory methods, and computational routines |
| `weeks/` | Lecture notebooks, labs, and deeper-dive notebooks, organized by week |
| `docs/` | The source for this site |

## Deeper dives

Lecture notebooks link to optional deeper-dive notebooks for students who want
the underlying theory — the simplex method behind linear programming, the duality
proof, the convergence analysis behind the iterative solvers. None of that
material is required, and nothing later in the course assumes it.
