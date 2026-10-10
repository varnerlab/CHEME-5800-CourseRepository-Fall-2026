# Week 8 — Regularization, cross-validation, and model checking

Fall Break occupies the first two meeting slots. When instruction resumes,
Week 8 moves from fitting to generalization: students inspect coefficient
stability, select a ridge penalty using training-only scaling inside reproducible
cross-validation folds, and check the residuals of the selected model.

| Meeting | Topic | Notebook |
|---|---|---|
| L8a | Fall Break — no class | [Session note](L8a/README.md) |
| L8b | Fall Break — no class | [Session note](L8b/README.md) |
| L8c | Regularization and cross-validation | [Lecture](L8c/CHEME-5800-L8c-Lecture-RegularizationAndGeneralization-Fall-2026.ipynb) · [Housing-price ridge example](L8c/CHEME-5800-L8c-Example-RLS-SVD-HousingPriceModel-Fall-2026.ipynb) · [Condition number](L8c/CHEME-5800-L8c-Theory-ConditionNumber-Fall-2026.ipynb) |
| L8d | Cross-validation for ridge regression | [Lab](L8d/CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb) |

The L8c example estimates a linear model of housing prices with ordinary least
squares, with ridge regression, and with the SVD form of the ridge estimate. In
the L8d lab, students implement k-fold cross-validation in `L8d/src/Compute.jl`,
use it to choose the ridge penalty for a housing-price model with 84 features
(the twelve originals plus 72 pairwise products), and use the SVD filter factors
to see why the penalty helps.

```bash
julia --startup-file=no --project=. instructor/validation/week-08/runtests.jl
```
