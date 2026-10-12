# Week 8 review

Date: October 12, 2026.

Status: Codex review complete; Claude confirmation and repairs complete (see below). These are
reviewer assessments, not instructor approval. The scores table below is the morning
Codex review of the original notebooks; the repairs that followed are listed under
"Claude confirmation and repairs".

The review covers all four notebooks and their linked setup, data, and lab source
files. L8a and L8b are Fall Break session notes, with no required notebooks.
The shared course notebook style guide governs this review; the condition-number
companion is a conceptual derivation and does not need computational tasks.

## Scores

Scale: 0 = really bad; 10 = really great. No notebook scores below 9.

| Material | Score | Assessment |
|---|---:|---|
| [L8c lecture: regularization and cross-validation](../../weeks/week-08/L8c/CHEME-5800-L8c-Lecture-RegularizationAndGeneralization-Fall-2026.ipynb) | 9.3/10 | Connects ridge shrinkage, sampling variability, SVD filter factors, and cross-validation. Correctly distinguishes variability at a fixed penalty from confidence intervals for the original coefficients. |
| [L8c housing-price example](../../weeks/week-08/L8c/CHEME-5800-L8c-Example-RLS-SVD-HousingPriceModel-Fall-2026.ipynb) | 9.2/10 | Three coherent tasks compare OLS, direct ridge, and SVD estimates. Numerical interpretations match the default execution, including the small prediction change and concentration of coefficient changes along the last singular direction. |
| [L8c condition-number companion](../../weeks/week-08/L8c/CHEME-5800-L8c-Theory-ConditionNumber-Fall-2026.ipynb) | 9.2/10 | Develops sensitivity bounds with assumptions, a concrete two-by-two example, and connections to normal equations, scaling, and ridge. Includes the residual-dependent qualification for least-squares sensitivity. |
| [L8d cross-validation lab](../../weeks/week-08/L8d/CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb) | 9.4/10 | Students implement a focused algorithm, observe overfitting, select the penalty with training-only fold scaling, examine residuals, and explain the result with filter factors. The small test-set improvement is appropriately qualified. |

## Possible refinements

None is required to reach 9/10. These proposals have not been implemented or
confirmed by Claude.

1. **Use a linear solve in the lab helper.** In `L8d/src/Compute.jl` and its
   reference solution, `ridge_fit` could solve the regularized normal equations
   with backslash instead of explicitly forming the inverse. Keep the analytical
   formula and the example's direct-versus-SVD comparison. The current implementation
   gives correct results on this dataset, so this is a practical improvement rather
   than a numerical failure found in the review.
2. **Tighten the significant-digit rule if desired.** In cell 5 of the condition-
   number companion, emphasize that the digit estimate is an approximate worst-
   case guide. It is already labeled a rule of thumb, and cell 6 supplies the
   least-squares residual qualification; a broader rewrite is unwarranted.
3. **Optionally connect the fitting conventions.** A short sentence could identify
   the change from the L8c example's penalized intercept and simple unit rescaling
   to the lab's unpenalized intercept and training-based standardization. The lab
   already explains both decisions, so add this only if the instructor finds the
   cross-notebook transition unclear. Do not force the two artifacts to use the
   same convention merely for uniformity.

## Verification

- `GKSwstype=100 julia --startup-file=no --project=. instructor/validation/week-08/runtests.jl`:
  **76/76 passed**, including actual lab-cell execution with the reference solution,
  fold coverage and reproducibility, independent CV recomputation, training-only
  scaling, student-stub behavior, and the reported default results.
- Executed all housing-example code cells: **4/4 notebook checks passed**. The
  direct ridge and SVD estimates differed in norm by approximately `3.2e-14`.
- Independently checked the condition-number companion's numerical examples:
  **7/7 supplemental checks passed**. Housing values were approximately 42.16 for
  the design matrix, 1777.46 for its Gram matrix, 1634.83 after adding the unit
  ridge penalty, and 34094.65 with area left in square feet.
- Reproduced the example's suggested penalties 0, 10, and 100; the training-error
  and parameter-norm comparisons held.
- Executed all six plotting cells in light and dark themes and visually inspected
  the twelve resulting plots. Labels, legends, curves, points, and interpretation
  were readable and consistent.
- Validated all four notebook schemas, exported HTML, and checked exported heading
  structure and local link targets. This was structural HTML inspection, not a
  browser inspection of every rendered equation.
- Each notebook has three learning objectives and three key takeaways without
  equations. The computational example and lab each have three tasks with explicit
  task openers. Final summaries have the required closing separator.
- The local housing CSV matches the SHA-256 recorded in its data README.

## Claude confirmation and repairs (October 12, 2026)

Claude scored the unchanged notebooks lecture 8.0, example 8.5, companion 9.0, and lab
8.5. Codex checked those findings and re-scored 8.8, 8.9, 9.2, and 8.5. The instructor
approved the repair plan, and Claude applied it the same day (uncommitted):

- **Lecture:** cross-validation section gained a hyperparameter definition, the
  CV_k(δ), MSE_j(δ), and δ* displays, and a theme-aware five-fold diagram
  (`L8c/figs/Fig-KFold-CrossValidation-Schematic.svg`, listed in `release.toml`).
  LO 3, KT 3, and the Summary opener now claim only what the lecture develops. The
  SVD section says when the matrix form applies and that the sum gives the
  minimum-norm solution at δ = 0 for a rank-deficient matrix. The in-section example
  stop is one sentence.
- **Example:** L7d/L8d `Dict` recoding with an explicit feature list (tables list area
  first, no `t_` prefixes); a sentence that its split differs from L7d's; a paragraph
  tying the intercept-dominated last singular direction to uncentered features and the
  penalized intercept; Task 2 opener trimmed; long paragraph split. Every quoted number
  is unchanged.
- **Lab:** helpers moved to a guarded `L8d/src/Utility.jl` (`L8dUtility`), so
  `Compute.jl` holds only `my_cross_validation`. One `fold_seed` is shared by the
  cross-validation cell, the check, and Task 3. The student check recomputes the
  average error from the student's own folds instead of pinning default numbers.
  The residual paragraph names the L7d confidence intervals.
- **Validation:** new `instructor/validation/week-08/l8c_housing_example.jl` runs the
  example and pins its numbers and the companion's (36 tests). The L8d suite tests the
  module split and re-runs the notebook check at `fold_seed = 1` (86 tests). Suite
  122/122. Linter 0 findings on all four notebooks. The example and the lab (reference
  solution) executed without errors in light and dark themes.

Codex verified the repairs (12 of 13 fixed on the first pass; the missing δ* line and a
dropped section separator were then fixed) and re-scored the lecture 9.2, the example
9.4, the companion 9.2, and the lab 9.4.

## Notebook snapshots

SHA-256 values at the morning review, before the repairs:

| Notebook | SHA-256 |
|---|---|
| L8c lecture | `58796d151485b472bade2b4d1f2ab652bb1d328b869f4517d06f6a914651306d` |
| L8c housing-price example | `a50fe8ce4a1fa557139cd543428c2f32a165bc27dfc1742f8660dd64001c4711` |
| L8c condition-number companion | `926f59b51d17279d48d8adfea101d657a40ea7ff76dd180d9accac1046de0e81` |
| L8d cross-validation lab | `66a6ec2fad1bec95eb8a5cef6e2d845d1633bd25bff345ae3386735610d1a775` |
