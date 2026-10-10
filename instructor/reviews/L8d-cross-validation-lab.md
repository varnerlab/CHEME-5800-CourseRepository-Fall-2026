# L8d cross-validation lab

Status (October 9, 2026): rebuilt from the 2025 L8d cross-validation lab
(`CHEME-5800-L8d-Solution-CrossValidation-Fall-2025.ipynb`) as an implementation
lab on the L7d housing data. The August scaffold (synthetic data with a planted
quadratic term, helpers in the week-level `Week08Core` module) was replaced.

Kept from 2025: the title, the k-fold algorithm blockquote with the averaged-error
formula and the formula for the selected δ, the log-scale δ grid, the
cross-validation curve with a ± one standard deviation ribbon and a marker at the
selected δ, "Train the final model with the optimal δ", the "Why examine
residuals?" blockquote, and the "Where do we go from here?" closing. Dropped: the
synthetic factorial data, the comparison with true parameters, and the parity
plot (lab time).

Notebook: [L8d Lab: Let's Implement Cross-Validation for Ridge Regression](../../weeks/week-08/L8d/CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb)

Student code: `my_cross_validation(...)` in `weeks/week-08/L8d/src/Compute.jl`, three
TODOs (training rows, scale and fit, fold MSE). Reference:
`src/Compute-solution.jl`. Supplied helpers: `scale_features`, `ridge_fit` (ones
column last, intercept not penalized), `ridge_predict`.

## Predictions and questions

All numbers are for the default split (`Random.seed!(1234)`, the L7d split, 436
training and 109 testing houses), k = 10 folds with fold seed 5800, and the grid
`10.0 .^ range(-3, 4, length = 71)`. Prices are in millions.

| Where | Prompt | Outcome |
|---|---|---|
| Task 1 | 84-feature training error {lower, similar, higher}? Testing error? | Training lower (0.871 vs 1.053 RMSE); testing higher (1.304 vs 1.092). |
| Task 2 | Where is the smallest average validation error? | In between: δ* = 100, CV error 1.1201, against 1.4315 at δ = 0.001 and 2.12 at δ = 10⁴. |
| Task 2 final model | 84 features with δ*: better than, as well as, or worse than 12 features on the test set? | Better on this split: 1.062 vs 1.092 (training 0.964). On 3 of 10 other splits (`Random.seed!(1:10)`), the twelve-feature model wins. |
| Task 3 | Twelve-feature curve: U-shaped or flat until the penalty is large? | Flat: between 1.177 and 1.191 for every δ ≤ 100, then up to 3.06 at δ = 10⁴. δ*₁₂ = 31.6. |
| Task 3 SVD | How many of the 84 filter factors stay above 0.9 at δ*? | Only a few: 11 above 0.9, 52 below 0.5, 21 below 0.1. Twelve-feature filter factors are all above 0.84 at δ*₁₂. |

1. **Task 1.** The 84 columns include the original twelve, so with δ = 0 the
   larger model can reproduce the twelve-feature fit by setting every product
   weight to zero. Least squares minimizes the training error, so the larger
   model can only match or beat it on the training houses; δ = 0.001 changes
   this negligibly. The `testing_rmse` column measures performance on houses the
   fit never saw.
2. **Task 2.** Choosing δ by its testing error makes the testing set part of the
   fit: the best of 71 values on the testing houses is δ = 50.1 with testing RMSE
   1.058, an optimistic number for new houses, because we picked it for this
   particular set of 109 houses. Scaling inside a fold with all of the rows lets
   the validation houses shape the mean and standard deviation the model is
   trained with, so the fold is no longer unseen. Here the effect is small (the
   average validation errors change by at most 0.006, and δ* stays at 100), but
   the procedure should not depend on the effect being small.
3. **Task 3.** δ* moves: 158.5 for `seed = 1`, 199.5 for `seed = 2`. The bottom of
   the 84-feature curve is flat (CV error 1.124 at δ = 31.6, 1.120 at 100, 1.129
   at 316), while the fold-to-fold standard deviation there is about 0.16, so a
   different shuffle easily moves the minimum. The testing error barely changes:
   1.066 and 1.069, against 1.062 at δ = 100.

## Notes

- Fold seed 5800 was chosen because its δ* sits in the typical range. Across fold
  seeds the selected value runs from about 16 (seed 1234) to 251 (seeds 3, 42).
- The log-price revision was tried and rejected as the Task 3 content. In an
  earlier exploration (six `MersenneTwister` splits, δ chosen by the mean of fold
  RMSEs, not the lab's conventions), the 84-feature log-price model had a higher
  testing RMSE than the price model for 6 of 6 splits without a back-transform
  correction and 5 of 6 with a smearing correction (seed 3: 1.054 against 1.061).
- With centered (scaled) features and an unpenalized intercept, the intercept
  equals the average training price for every δ, and the feature weights are
  the L8c SVD sum over the singular values of the scaled feature matrix. The
  notebook's filter factors rely on this.
- Validation: `instructor/validation/week-08/runtests.jl` (the L8d testset runs the
  notebook with the reference solution and pins the numbers above) and
  `instructor/validation/week-08/execute_l8d_notebook.py` (light and dark
  execution with HTML export). The lab ships without outputs, like L6d.
