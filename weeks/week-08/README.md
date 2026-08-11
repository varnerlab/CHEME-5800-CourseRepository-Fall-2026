# Week 8 — Regularization, cross-validation, and model checking

Week 8 moves from fitting to generalization. Students inspect coefficient stability,
use residuals to identify a missing feature, and select a ridge penalty using
training-only scaling inside reproducible cross-validation folds.

| Meeting | Topic | Notebook |
|---|---|---|
| L8a | Regularization and generalization | [Lecture](L8a/CHEME-5800-L8a-Lecture-RegularizationAndGeneralization-Fall-2026.ipynb) |
| L8b | Ridge coefficient shrinkage | [Example](L8b/CHEME-5800-L8b-Example-RidgeCoefficientShrinkage-Fall-2026.ipynb) |
| L8c | Residual model checking | [Lab](L8c/CHEME-5800-L8c-Lab-ResidualModelChecking-Fall-2026.ipynb) |
| L8d | Reproducible ridge cross-validation | [Lab](L8d/CHEME-5800-L8d-Lab-RidgeCrossValidation-Fall-2026.ipynb) |

The regularization and cross-validation concepts retain Fall 2025 material. New
local implementations make intercept handling, fold membership, training-only
standardization, and fold-level validation errors explicit and testable.

```bash
julia --startup-file=no --project=. instructor/validation/week-08/runtests.jl
```
