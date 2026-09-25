# L6c general iterative method review — September 24, 2026

**Follow-up, September 25:** The shared solver stopping issue is now fixed and
covered by package-level regression tests; the example was rerun with both
benchmark histograms preserved. The instructor retired the L6c HTML exports.
See [the completed solver follow-up](L6c-shared-solver-stopping-review.md).
Earlier limitations and numerical outputs below describe the state at that review.

Reviewed and polished [the lecture notebook](../../weeks/week-06/L6c/CHEME-5800-L6c-Lecture-GeneralIterativeMethod-Fall-2026.ipynb). The user authorized polishing when the initial score was below 9/10. Initial score: **7.9/10**. Final score: **9.1/10**.

These are editorial judgments about this lecture, not measured learning outcomes or certification of the linked teaching bundle.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 6.5 | 9.4 | Corrected the iteration-count sign, contraction assumptions, Jacobi splitting signs, and scope of the SOR guarantee. |
| Organization | 8.5 | 9.3 | Preserved the general algorithm and derivation, then connected error propagation, convergence, bounds, and specific splittings. |
| Narrative and reasoning | 8.3 | 9.0 | Retained the approved opening and derivation; clarified what each convergence result establishes and how to interpret the bound. |
| Presentation | 8.0 | 9.2 | Checked all displays in two Markdown math renderers, repaired the missing section boundary, and supplied three retrospective conceptual takeaways. |
| Cognitive density and pacing | 8.2 | 8.8 | Added a short numerical anchor and explicit assumptions. Convergence remains the most demanding section, especially the distinction between spectral radius and a chosen induced norm. |

## Changes

The first four cells, including the previously approved opening, examples, general algorithm, and update-direction derivation, are unchanged. All notebook and cell metadata are preserved. Only the convergence, specific-methods, lab separator, and summary cells changed.

- Derived the error recurrence before stating the spectral-radius condition, including the distinction between eventual convergence and monotone error reduction.
- Defined strict row diagonal dominance directly from the entries of the system matrix. Identified the infinity-norm calculation as a Jacobi proof and distinguished the triangular Gauss–Seidel splitting.
- Replaced the negative iteration threshold with a positive sufficient integer bound, stated the contraction and initial-error assumptions, and separated solution-error tolerance from residual tolerance.
- Connected Jacobi, Gauss–Seidel, and relaxation to their choices of the correction matrix. Distinguished under-relaxation, Gauss–Seidel, and over-relaxation, and qualified speed comparisons.
- Restricted the full relaxation-interval convergence guarantee to symmetric positive definite matrices, consistent with [Netlib's discussion](https://netlib.org/linalg/html_templates/node16.html).
- Added concise per-sweep cost context, three retrospective takeaways without equations, a closing sentence, and the missing separator before Summary.

## Verification

- Parsed the saved notebook and verified its cell structure, metadata, and equality to the reviewed draft.
- Confirmed exactly three learning objectives and three conceptual takeaways, all major-section separators, and the final Summary separator.
- Checked all seven local link occurrences. Read the linked algorithm, convergence, example, and lab material to assess the lecture's descriptions.
- Rendered all 16 displayed equations with the VS Code notebook math renderer and markdown-it-texmath, with no errors or unconsumed display delimiters in the final output. Visually inspected the complete initial narrative and the revised convergence and closing sections.
- Numerically checked the sufficient count: contraction factor 0.5, initial error bound 1, and tolerance 0.001 require 10 corrections; the bound after 10 corrections is 0.0009765625.
- Confirmed a strictly row diagonally dominant counterexample to the original SOR claim: for the matrix with rows `[1, 0.9]` and `[-0.9, 1]`, relaxation factor 1.9 produces spectral radius approximately 4.545918. Jacobi and Gauss–Seidel spectral radii are 0.9 and 0.81.
- Checked agreement between residual corrections, stationary splitting updates, and component relaxation sweeps for four relaxation factors on the lab's three-by-three matrix.
- `git diff --check` passed. The lecture contains no code cells. The companion Julia benchmarks were not rerun; numerical checks used NumPy and do not certify the package implementations.

Readable artifacts are under the ignored directory `build/notebook-previews/L6c-lecture-review-2026-09-24/`: `final.html`, `final-convergence.png`, `final-closing.png`, `initial.ipynb`, and `numerical-checks.json`.

## Findings in linked notebooks for a separate pass

These files were inspected but not edited, including companions with pre-existing working-tree changes.

- **Fun with Iterative Solvers example:** the random construction does not ensure strict diagonal dominance. The `any(ddcondition)` assertion checks only one qualifying row, whereas the theorem requires every row. The discussion also overstates SOR convergence, labels solution differences as residuals, and uses different relaxation factors in the solution and benchmark cells.
- **Gauss–Seidel algorithm:** the final iteration-matrix expression lacks the minus sign required by its stated splitting. Its stopping pseudocode also falls through to a correction after setting the termination flag.
- **Jacobi and SOR algorithms:** stopping pseudocode similarly conflates successful convergence with reaching an iteration limit and does not immediately return before the correction step.
- **SOR algorithm:** the relaxation-parameter formula needs its matrix-structure assumptions; it is not a general optimal-parameter formula.

These limitations prevent treating the linked bundle as fully validated. The final score applies to the requested lecture only.
