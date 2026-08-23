# CHEME 4800/5800 Week 0 Onboarding and Weeks 1–16 Build Queue

**Status:** Initial chronological build complete  
**Priority:** Preserve the common path while beginning the cross-course cleanup pass

## Working rule

For each week, curate the common instructional path first, then add only the most
useful verified extension. A week is complete when its student-facing notebooks,
supporting code/data, tests, metadata, and clean execution checks all pass.

| Order | Week | Common-core build target | Selected advanced notebook or key dependency | Status |
|---:|---:|---|---|---|
| 0 | 0 | Julia installation, shared-environment setup, notebook kernel, and end-to-end smoke test | Optional first tested calculation | **Onboarding package created; validation pending local environment** |
| 1 | 1 | Primitive types, collection/composite representations, and floating-point behavior | Float32 rounding and precision | **Split into focused L1a lecture and L1b lab; validation pending local environment** |
| 2 | 2 | Functions/interfaces/scope; errors, tests, and debugging; collections; defensive Fibonacci program | Hexadecimal and text representation | **Curated and validated** |
| 3 | 3 | CSV/JSON reading, validation, and provenance; iteration/recursion; sorting as a testable algorithm | Bubble-sort and quicksort comparison | **Curated from 2025 plus new L3b; validation passing** |
| 4 | 4 | Trees and graphs; BFS/DFS; Dijkstra and Bellman–Ford; production-planning shortest path | BFS/DFS implementation detail | **Curated from 2025, corrected, and validated** |
| 5 | 5 | Network flow; maximum-flow validation; linear programming; assignment and minimum-cost flow | Revised-simplex internals | **Curated from 2025, corrected, and validated** |
| 6 | 6 | Duality/sensitivity/FBA; HL-60 urea-cycle model; Jacobi, Gauss–Seidel, and SOR | FBA derivation and iterative-method convergence | **Curated, corrected, and validated** |
| 7 | 7 | SVD/data reduction and ordinary least squares | Confirm and document a reduced S&P 500 dataset | **Curated, corrected, and validated** |
| 8 | 8 | Regularized least squares, cross-validation, and model checking | One compact model-selection extension if warranted | **Curated, corrected, and validated** |
| 9 | 9 | Perceptron, nonlinear optimization, and logistic regression on the shared predictive-maintenance case | XOR and linear separability | **Predictive-maintenance replacement built and validated** |
| 10 | 10 | Multiplicative weights and ordinary multiarm bandits | Thompson sampling | **Rebundled and validated** |
| 11 | 11 | Markov models, Markov decision processes, value iteration, and grid world | Hidden Markov models | **Curated, corrected, and validated** |
| 12 | 12 | Tabular Q-learning and comparison with value iteration | CHEME 5800 learner implementation/analysis | **New integration built and validated** |
| 13 | 13 | HTTP/JSON/REST clients and a local read-only MCP server | BiGG remains an optional extension | **Prototype converted, corrected, and validated** |
| 14 | 14 | Dominant eigenpairs, power iteration, and spectral reasoning | Full eigendecomposition and QR iteration remain in CHEME 5820 | **Substantive lecture rebuilt and validated** |
| 15 | 15 | Explicit Euler, stability, dynamic engineering models, and solver choice | Three-gene and mixed-sugar fermentation cases | **Expanded to a full instructional week and validated** |
| 16 | 16 | Course synthesis and transition to CHEME 5820 | Explicit Fall-to-Spring prerequisite map | **Built and validated** |

## Immediate handoff

The Week 0 onboarding package and chronological Weeks 1–16 build are complete.
Begin the cleanup phase with a
cross-week presentation audit, duplicated-code review, provenance resolution,
notebook-output size review, release-bundle smoke tests, and syllabus/calendar
alignment. Do not expand the topic list during cleanup unless a verified gap blocks
the common instructional path.

Problem sets are intentionally absent from this queue. Each problem set and its
solution are released together through a separate repository workflow.
