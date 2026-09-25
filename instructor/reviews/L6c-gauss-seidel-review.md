# Gauss–Seidel algorithm review — September 24, 2026

**Follow-up, September 25:** The shared solver stopping issue is now fixed and
covered by package-level regression tests; the example was rerun with both
benchmark histograms preserved. The instructor retired the L6c HTML exports.
See [the completed solver follow-up](L6c-shared-solver-stopping-review.md).
Earlier limitations and numerical outputs below describe the state at that review.

Reviewed and revised [the algorithm notebook](../../weeks/week-06/L6c/CHEME-5800-L6c-Algorithm-GaussSeidel-Fall-2026.ipynb). Preserved its metadata and the pre-existing removal of an empty code cell. The notebook remains a mathematical algorithm companion with no executable cells. No shared solver implementation was changed.

Initial score: **7.2/10**. Final score: **9.1/10**. These are editorial judgments about the notebook.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 6.0 | 9.4 | Corrected the iteration-matrix sign and immediate-return semantics; specified nonzero diagonal entries and distinguished residual tolerance from solution error. |
| Organization | 7.5 | 9.1 | Connected the splitting, correction, sequential sweep, stopping algorithm, and convergence condition. |
| Narrative and reasoning | 7.4 | 9.0 | Explained how new component values enter the update and why the iteration matrix has a minus sign. |
| Presentation | 7.4 | 9.1 | Six readable displays, annotated terms, three objectives, and three conceptual takeaways. |
| Cognitive density and pacing | 7.7 | 8.9 | Kept the derivation and pseudocode together in two main development sections; broader theory and computation remain in companions. |

## Corrections

- The splitting has `M = D + L` and `N = -U`, so the iteration matrix is `G = -(D + L)⁻¹ U`.
- The correction is computed by a lower triangular solve using forward substitution, without requiring an explicit inverse.
- The component update distinguishes newly computed values for earlier rows from previous-iteration values for later rows. The ordering discussion is consistent with [Netlib's Gauss–Seidel description](https://netlib.org/linalg/html_templates/node14.html).
- The pseudocode returns immediately with success when the residual meets tolerance, or with failure when the correction limit is reached. It checks the residual first, allowing both an acceptable initial guess and success on the final allowed correction.
- The introduction qualifies the comparison with Jacobi rather than presenting Gauss–Seidel as a universal improvement.
- Added three concise objectives, three retrospective takeaways, appropriate section separators, and links to the lecture and executed example.

## Verification

A Julia translation of the notebook pseudocode passed **20 checks** covering:

- Agreement among the residual correction, signed stationary update, and sequential component sweep.
- Rejection of the original unsigned iteration matrix. Its spectral radius equals that of the correct matrix, so a spectral-radius check alone would not detect this sign error.
- Agreement with a direct solution and satisfaction of the residual tolerance.
- An already solved initial guess, zero allowed corrections, unsuccessful termination after one correction, success exactly at the correction limit, and a divergent system stopped at its limit.

For the system with matrix rows `[4, 1]` and `[2, 3]`, right-hand side `[1, 2]`, and a zero initial guess, the first sweep is `[0.25, 0.5]`. The translation reaches approximately `[0.1, 0.6]` after 14 corrections, with residual norm `3.82829e-11` for tolerance `1e-10`.

Notebook schema validation, metadata preservation, all three local links, objective/takeaway counts, separators, and `git diff --check` passed. All six displays rendered without errors or raw display delimiters in both the VS Code notebook math renderer and markdown-it-texmath. The complete revised narrative was visually inspected before saving.

The preview and validation artifacts are under `build/notebook-previews/L6c-gauss-seidel-review-2026-09-24/`, including `initial.ipynb`, `final.html`, `final-formulation.png`, `final-algorithm.png`, and `validate.jl`.

## Scope limitation

The checks validate the mathematics and an executable translation of this notebook's pseudocode. They do not certify the shared course solver's stopping loop, which still stores an extra correction after detecting a stopping condition. That implementation behavior is documented and checked independently in the companion example. The algorithm notebook now states the intended immediate-return behavior.

## Pseudocode format correction — September 25, 2026

The instructor rejected the flattened Repeat list. Compared the actual 2025
L6c algorithm notebooks and restored Initialize, While/do, five numbered steps,
and nested If/then stopping checks. Kept immediate returns and separate success
and failure statuses. Only the pseudocode block changed. Checked rendered previews,
notebook validity, and reran the existing mathematical/stopping checks successfully.
The previous score did not establish that the formatting matched the instructor's
reference; the 2025 layout is now recorded in the shared notebook style guide.
