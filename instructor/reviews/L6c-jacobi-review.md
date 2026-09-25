# Jacobi algorithm review — September 24, 2026

**Follow-up, September 25:** The shared solver stopping issue is now fixed and
covered by package-level regression tests; the example was rerun with both
benchmark histograms preserved. The instructor retired the L6c HTML exports.
See [the completed solver follow-up](L6c-shared-solver-stopping-review.md).
Earlier limitations and numerical outputs below describe the state at that review.

Reviewed and revised [the Jacobi notebook](../../weeks/week-06/L6c/CHEME-5800-L6c-Algorithm-JacobiMethod-Fall-2026.ipynb). The user explicitly authorized changes after the initial assessment. Preserved notebook metadata and the pre-existing removal of an empty code cell. The notebook remains a mathematical algorithm companion; no executable cells or shared-library edits were added.

Initial score: **7.6/10**. Final score: **9.1/10**. These are editorial judgments about the notebook.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 7.0 | 9.3 | Retained the correct iteration matrix; corrected stopping semantics and stated the nonzero-diagonal assumption. |
| Organization | 7.5 | 9.1 | Connected the splitting, diagonal correction, component update, algorithm, and convergence criterion. |
| Narrative and reasoning | 7.4 | 9.0 | Explained why every component must use the previous iterate and how this differs from Gauss–Seidel. |
| Presentation | 7.4 | 9.1 | Six readable displays, three objectives, three conceptual takeaways, and consistent section boundaries. |
| Cognitive density and pacing | 8.5 | 9.0 | Retained a compact algorithm focus, with two development sections and links to the lecture and computational example. |

## Changes

- Specified a nonsingular square system with nonzero diagonal entries and defined the matrix parts before use.
- Explained that the diagonal correction requires componentwise division, not construction of an inverse matrix.
- Derived the component update and explained why the previous iterate must remain unchanged while all new components are calculated. Linked the contrasting Gauss–Seidel update.
- Made both stopping conditions return immediately, with distinct success and failure statuses. Checked the residual before the correction limit so an acceptable initial guess and success on the final allowed correction are handled correctly.
- Preserved the correct signed Jacobi iteration matrix and linked the lecture's strict-diagonal-dominance argument.
- Added aligned objectives, retrospective takeaways, and the final Summary separator.

## Validation

An executable Julia translation of the pseudocode passed **25 checks**. These covered the splitting identity; agreement among residual corrections, stationary updates, and component updates; independence from component visitation order; the distinction from Gauss–Seidel; the infinity-norm bound for a strictly diagonally dominant matrix; convergence to a direct solution; zero allowed corrections; a satisfactory initial guess; success on the final correction; unsuccessful termination at a limit; a divergent system; and a one-variable system.

For the system with matrix rows `[4, 1]` and `[2, 3]`, right-hand side `[1, 2]`, and a zero initial guess, the first Jacobi sweep is `[0.25, 2/3]`. Gauss–Seidel's first sweep on the same problem is `[0.25, 0.5]`. The translated Jacobi algorithm reaches approximately `[0.1, 0.6]` after 27 corrections, with residual norm `6.38045e-11` for tolerance `1e-10`.

Notebook schema, metadata preservation, all four local links, three objectives, three equation-free takeaways, separators, and `git diff --check` passed. All six displayed equations rendered correctly in the VS Code notebook math renderer and markdown-it-texmath. The full revised narrative was visually inspected before saving.

Artifacts are under `build/notebook-previews/L6c-jacobi-review-2026-09-24/`: the original notebook, `final.html`, `final-formulation.png`, `final-algorithm.png`, and `validate.jl`.

## Scope limitation

These checks validate the notebook mathematics and a translation of its pseudocode. The shared course solver still stores an extra correction after detecting a stopping condition; that library behavior was not changed here. The companion example documents it and independently checks the final stored solution and correction count. The revised Jacobi pseudocode states the intended immediate-return behavior.

## Pseudocode format correction — September 25, 2026

The instructor rejected the flattened Repeat list. Compared the actual 2025
L6c algorithm notebooks and restored Initialize, While/do, five numbered steps,
and nested If/then stopping checks. Kept immediate returns and separate success
and failure statuses. Only the pseudocode block changed. Checked rendered previews,
notebook validity, and reran the existing mathematical/stopping checks successfully.
The previous score did not establish that the formatting matched the instructor's
reference; the 2025 layout is now recorded in the shared notebook style guide.
