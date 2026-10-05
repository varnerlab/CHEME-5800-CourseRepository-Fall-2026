# L7c ordinary least squares lecture review — October 5, 2026

**Status:** Reviewed and approved by the instructor on October 5, 2026 ("mark this
as reviewed"), after round 2 and the TikZ figure. Approval covers the lecture at
SHA-256 `09e50ee4559166ac18bbea2ac7f42b28742b624a958ce612f73cb7d9eaac5000`, released in week-07.2. The review is closed.

Target: [Ordinary Least Squares lecture](../../weeks/week-07/L7c/CHEME-5800-L7c-Lecture-OrdinaryLeastSquares-Fall-2026.ipynb).

## Source and decisions

The 2026 notebook was the instructor's Fall 2025 lecture body inside the 2026
scaffold, the same shape L7a had before its port: four one-line objectives in
y = Xβ + ε notation promising RMSE, R², and column-space projection that the body
never developed, a Setup cell and include cell in a lecture with no code, a
"Numerical contract" cell and a second Summary after the real one, and three dead
references (the regression figure, the dot-product PNG, and a 2026 housing example
that does not exist).

The instructor chose on October 5 to drop the example stop (housing prices now
live in the L7d lab) and to copy the 2025 dot-product PNG over and keep its link.
The regression schematic was first restored from 2025. At the instructor's request
the same day, it was redrawn in TikZ with the lecture's notation (x̂ᵢ, θ̂, rᵢ) in
`figs/Fig-LinearRegressionModel-Schematic/`, replacing the 2025 file, which labeled
the residual yᵢ − xᵢᵀβ; see [the L7c figure README](../../weeks/week-07/L7c/figs/README.md).

## Scores

| Dimension | Before | After |
|---|---|---|
| Correctness | 6 | 9 |
| Organization | 5 | 9 |
| Narrative | 7 | 8 |
| Presentation | 5 | 8 |
| Density | 6 | 8 |
| **Overall** | **5.5** | **8.5** |

## Changes

- Title cell: three house-form objectives without math, a lab sentence, and
  "Let's get started!"; Setup, include, Numerical contract, and second Summary cells
  deleted, with the condition-number point folded into the SVD comparison.
- Organization: figure inside the first H2 with a caption; Overdetermined and
  Underdetermined as H3s under "Ordinary least squares"; the SVD comparison as an H3;
  the 962-word error-model cell split one cell per H3; "Key Insights" H3s became
  labeled panels.
- New mathematics: the normal equations from the gradient, with fitted values as the
  projection of y onto the column space; the full-row-rank condition for the
  least-norm solution.
- Corrections: rank r(X̂) ≤ min(n, p), not min(n, p); Σ to S to match L7a; "previous
  notebook" reference; normality does not enable the OLS solution (BLUE needs only
  zero-mean, uncorrelated, constant-variance errors); "No parameter correlation"
  label; correlated errors break the standard errors, not unbiasedness; normal
  equation cost O(np² + p³); prediction intervals need the full covariance plus the
  new observation's noise; P is the projection onto the row space.

## Verification

Strict notebook style check 0 findings; legacy audit flags only the two adjacent
assumption panels (2025 layout, advisory). nbformat validates. Rendered HTML preview
in `build/notebook-previews/L7c-ols/`. Week 7 bundle builds with the new datasets.
Codex (read-only): 22/24 FIXED, 0 overcorrected. Its two NOT FIXED items (product
order in takeaway 2; full-column-rank scope of κ(X̂ᵀX̂) = κ(X̂)²) and three new
findings (backslash-link anchor, β/θ mapping in the caption, bare r in σ_r) were
fixed. The anchor it proposed (`%5C`) was checked against the live docs page, whose
id carries two backslashes, so the link uses `%5C%5C`. Declined: defining σ̂ as the
square root of σ̂² (standard).

## Open

- The Lab sentence describes the current L7d scaffold (synthetic housing prices, OLS
  through `ols_fit`). Revisit it if L7d is rebuilt.
- The L6c example and L6d lab carry the same broken backslash anchor (`\-`).

## Independent rescore — October 5, 2026 (after the TikZ figure)

Claude and codex each scored the lecture 8.5, not 9, scoring independently.
Codex by dimension: correctness 8.5, organization 9, narrative 8.5,
presentation 8.5, density 7.5. Its path to 9: scope the error-variance and
standard-error results to the overdetermined, full-column-rank case; remove the
repeated least-norm/regularization point and give the null-space reason instead;
consolidate the overlapping SVD panels; tighten the standard-error applications
and drop "Advanced:" from the confidence-interval heading (objective 3 covers it).
Its fifth item was a blank line before the final `___`. The trailing `___` shows
as literal underscores only in nbconvert's HTML preview, and the instructor's own
L6a edit set the no-blank-line form.

## Round 2 — October 5, 2026

The instructor approved all five ("Fix 1 - 5"), including the blank line before the
closing `___` in the title and Summary cells. Applied: scope sentence before the
variance estimate and the n > p reason in its key insight; n > p and n < p
definitions; full row rank before the exact-fit constraint; null-space reason for
the least-norm choice; "Non-unique solutions" and "High-dimensional relevance" cut;
SVD stability, data-structure, and regularization bullets and the repeated displays
removed; squared condition number and thin-SVD cost stated; standard error
introduced as an estimated standard deviation; applications panel shortened; the
expanded SE formula no longer repeated; "Advanced:" dropped. Prose went from about
3,070 to 3,000 words.

Codex verification: 4/5 FIXED and 8.9/10. The miss was the new null-space sentence,
which claimed that adding any null-space vector lengthens any exact solution (false;
it holds from the least-norm solution, by orthogonality) and said "a single
prediction" without restricting it to the observed data. After the correction, a
narrow codex check returned FIXED and **9.0/10**. Numerical check: on a random 3×6
X̂, X̂z = 0, the least-norm solution lies in the row space, and the Pythagorean
identity holds. Strict style check 0 findings; nbformat valid.
