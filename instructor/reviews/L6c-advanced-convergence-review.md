# Advanced convergence review — September 25, 2026

**Follow-up, September 25:** The shared solver stopping issue is now fixed and
covered by package-level regression tests; the example was rerun with both
benchmark histograms preserved. The instructor retired the L6c HTML exports.
See [the completed solver follow-up](L6c-shared-solver-stopping-review.md).
Earlier limitations and numerical outputs below describe the state at that review.

Completed review and polish of the L6c Advanced Convergence notebook. The user
explicitly authorized polishing if its score was at most 9/10; the initial score
was **7.2/10**, so the pass proceeded under that authorization. Final rating:
**9.0/10**. These are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 7.0 | 9.4 | Added invertibility assumptions and the every-initial-guess qualifier; established necessity and sufficiency, including defective matrices. |
| Organization | 8.0 | 9.0 | Kept the splitting-to-error sequence, then completed the spectral argument and interpreted a small example. |
| Narrative and reasoning | 6.0 | 8.9 | The original asserted the theorem promised by its title; the revision explains the eigenvector and Jordan-block arguments. |
| Presentation | 8.0 | 9.1 | Retained aligned algebra, reduced redundant algebraic lines, and checked nine mathematical displays and the full layout. |
| Cognitive density and pacing | 7.0 | 8.6 | Added the necessary proof in a dedicated section. The Jordan extension remains the most demanding passage and presumes familiarity with matrix similarity. |

## Findings and changes

The original 2026 narrative matched the 2025 notebook. Its error recurrence was
correct, but its last paragraph asserted the spectral-radius criterion without
explaining the matrix-power theorem. It did not distinguish a particular initial
error from every possible initial error, or state the nonsingularity needed for
the fixed-point inverse. Initial visual inspection found readable equation-led
presentation, but incomplete mathematical justification. The alternate math
renderer also retained raw display delimiters because of equation spacing.

Preserved the title and equation-led development. Defined the splitting assumptions,
showed uniqueness through I-G=M⁻¹A, and derived e(k)=G^k e(0). Explained both
implications between all initial errors decaying and matrix powers tending to zero.
Proved necessity using an eigenvector/norm inequality; proved sufficiency first
for diagonalizable matrices, then through the finite binomial expansion of each
Jordan block, treating the zero-eigenvalue nilpotent case separately.

The matrix-power theorem was checked against Nick Higham's primary exposition:
https://nhigham.com/2024/01/12/what-is-the-spectral-radius-of-a-matrix/ .
The notebook links to that reference. The proof is developed within the notebook,
rather than delegated to the link.

Added two small illustrations: diag(1/2,2) admits special decaying errors without
convergence from every guess; the triangular matrix with rows [1/2,2] and [0,1/2]
initially amplifies the error [0,1] but its powers still tend to zero. Clarified
contraction versus eventual convergence and residual versus solution error.
Added three learning objectives, three conceptual takeaways, and the required
major-section/final separators. This is a proof companion, not a computational
example requiring artificial setup or three implementation tasks.

## Verification

An independent Julia validation script passed **74/74 checks**. These cover the
splitting/fixed-point identities, recurrence over repeated updates, residual/error
relation, exceptional initial errors, complex unit-modulus eigenvalues, transient
growth and its exact power formula, and Jordan blocks of sizes 1–3 with positive,
negative, complex, and zero eigenvalues. These are checks of algebra and examples;
the finite computations do not substitute for the written general proof.

For the transient example, the initial norm is 1, the next is approximately
2.06155, and the norm at iteration 40 is approximately 1.45522e-10.

All nine displayed equations passed the VS Code notebook math renderer and
markdown-it-texmath. Visually inspected the whole draft and the proof section
at readable resolution before saving. Notebook schema, links, preserved notebook
and original-cell metadata, three objectives/takeaways, separators, saved-draft
equality, and git diff --check passed. Preserved the existing deletion of the
empty Markdown cell. No code cells or shared solver files were changed.

Artifacts: build/notebook-previews/L6c-convergence-review-2026-09-25/ contains
initial.ipynb, draft.ipynb, final.html, final.png, draft-cell-2.png,
render-report.json, and validate.jl.

The proof concerns finite matrices in exact arithmetic. It does not provide a
roundoff analysis or a quantitative finite-iteration bound for general nonnormal
matrices. The existing L6c HTML release exports were not regenerated, and the
shared solver's extra-update stopping limitation remains a separate library issue.
