# L7d housing-price OLS lab

Status (October 7, 2026): rebuilt from the 2025 housing-price example as a
walkthrough lab that applies the three L7c methods. Code was simplified for
students who are new to Julia. `ols_fit` in `src/OLS.jl` now follows the L7c
lecture: it takes the augmented matrix with the ones column last, solves the
normal equations, and returns the estimate, the residuals, σ̂², and the standard
errors. A check cell and a duplicated-feature what-if were added to Task 2, and
a residual plot and a feature-selection what-if to Task 3.

Notebook: [L7d Lab: A Housing-Price Model with Ordinary Least Squares](../../weeks/week-07/L7d/CHEME-5800-L7d-Lab-HousingPriceOLS-Fall-2026.ipynb)

## Predictions and questions

| Where | Prompt | Outcome |
|---|---|---|
| Task 1 | Testing `r2` higher, about the same, or lower than training? | About the same: 0.677 testing, 0.678 training. |
| Task 2 | Is cond(X̂ᵀX̂) about the same as, twice, or the square of cond(X̂)? | The square: about 44 and about 1909. |
| Task 2 what-if | Smallest singular value after adding the area in m²? Do predictions change? | Zero up to rounding (about 10⁻¹⁷ of the largest). X̂ᵀX̂ has rank 13 of 14. Predictions change by about 10⁻¹³. |
| Task 3 residual plot | Same spread at every predicted price, or wider for expensive houses? | Wider: ordered by predicted price, the residual standard deviation is 0.67 million for the cheapest 145 training houses and 1.37 for the most expensive 146. Largest residual +5.04, smallest −2.79. |
| Task 3 | Does every interval exclude zero? | No: `bedrooms` and `guestroom` contain zero for seed 1234. |
| Task 3 feature selection | Testing `rmse` after removing `bedrooms` and `guestroom`? | Up slightly: 1.092 to 1.101 (`r2` 0.677 to 0.671). |
| Task 3 alternatives | `dropped = ["bedrooms"]`; `dropped = ["airconditioning"]` | 1.088 (slightly better than the full model); 1.207 (clearly worse). |

1. **Task 1.** A weighted sum treats each feature's effect as fixed per unit. The
   dataset describes location only coarsely, through the main-road and
   preferred-area flags, and it has nothing on age or condition, which can matter most for expensive houses. A
   testing `r2` well below the training `r2` would signal overfitting.
2. **Task 2.** The new column is 92.90304 times the area column, so one
   combination of columns is zero and X̂ has a zero singular value (only rounding
   keeps it from being exactly zero). X̂ᵀX̂ has eigenvalues σᵢ², so it is singular
   and has no inverse. In floating point, `inv` may throw or return a wrong
   answer depending on rounding, so the cell shows the rank instead. The SVD sum
   skips the zero singular value. The remaining terms span the same column space
   as before, so the fitted values, and therefore the predictions, are unchanged.
   The area effect is split between the two area columns (the smallest-norm
   split): 0.2564 = θ̂₁ + 92.90304·θ̂₁₄.
3. **Task 3.** The correlation among bedrooms, bathrooms, and stories is mild
   (all variance inflation factors are between 1.05 and 1.55), so it widens the
   bedrooms interval only a little. The interval contains zero mainly because the
   estimate, about 0.15 million per bedroom, is small relative to its standard
   error of about 0.08. Holding the other features fixed, the interval runs from
   about −0.01 to 0.32 million per bedroom, so the data allow both no effect and a
   sizable one. The feature-selection what-if answers the rest. Removing both
   features raises the testing `rmse` by 0.009, and removing `bedrooms` alone
   lowers it by 0.004. On ten seeds (1234, 1, 2, 3, 7, 11, 42, 99, 2024, 31415),
   the paired change from removing both ranges from −0.029 (seed 7) to +0.019
   (seed 11), so its sign depends on the split; the full model's testing `rmse`
   itself ranges from 0.99 to 1.20. Removing `airconditioning`, whose interval
   lies well above zero, raises it by 0.115. An interval that contains zero says
   the data cannot rule out a zero weight; it does not say the feature is useless
   for prediction. Using the testing set to choose features also spends it: the
   chosen model needs fresh data for a fair final check. Week 8's
   cross-validation is the tool.
4. **Residual plot.** The widening band suggests unequal error variance
   (heteroskedasticity), against the lecture's equal-variance assumption; a
   misspecified mean can produce a similar pattern. The large residuals are
   positive (moment skewness about +0.94). When the assumption fails, the 95%
   intervals' actual coverage is uncertain. Heteroskedasticity-robust (HC3)
   standard errors, computed by the reviewer, are larger for `area` (+19%),
   `bathrooms` (+34%), and `hotwaterheating` (+20%) and smaller for `mainroad`
   (−23%), so the direction of the error differs by coefficient. With HC3,
   `bedrooms` and `guestroom` are still the only feature intervals that contain
   zero.

## Facts the prose relies on (pinned in the suite)

- 545 houses, 12 features; 436 training and 109 testing houses (seed 1234).
- Training and testing `r2` 0.678 and 0.677; cond(X̂) ≈ 44; the normal-equations
  and SVD estimates agree to below 10⁻¹².
- Only the `bedrooms` and `guestroom` intervals contain zero; 24 of the 436
  training houses have hot-water heating.
- Residuals: the standard deviation in the most expensive third is more than
  1.5 times that in the cheapest third; largest residual between 4.5 and 5.5,
  smallest between −3.0 and −2.5.
- Feature selection: testing `rmse` 1.092 (full), 1.101 (no `bedrooms` or
  `guestroom`), 1.088 (no `bedrooms`), 1.207 (no `airconditioning`); across the
  ten seeds, the paired change from removing both lies between −0.03 and +0.02
  and takes both signs.
- What-if: smallest/largest singular value below 10⁻¹⁴, the next one above 10⁻⁶;
  rank(X̂ᵀX̂) = 13; predictions change by less than 10⁻¹⁰.

Robustness (Julia 1.12.7, macOS ARM): for the row permutations
`randperm(MersenneTwister(s), 436)` with `s = 1, …, 5`, the what-if ratio stayed
between 3×10⁻¹⁸ and 1.7×10⁻¹⁷ and the rank stayed 13. `ols_fit` on the duplicated
matrix threw `DomainError` for the original order and returned predictions off by
0.4 to 7.7 million for those permutations; a reviewer's different permutations
gave two errors and misses of 4.0 to 8.1 million. The outcome depends on rounding,
which is why the notebook does not call it there.
