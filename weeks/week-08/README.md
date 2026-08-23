# Week 8 — Regularization, cross-validation, and model checking

Fall Break occupies the first two meeting slots. When instruction resumes,
Week 8 moves from fitting to generalization: students inspect coefficient
stability, select a ridge penalty using training-only scaling inside reproducible
cross-validation folds, and use residuals to justify a model revision.

| Meeting | Topic | Notebook |
|---|---|---|
| L8a | Fall Break — no class | [Session note](L8a/README.md) |
| L8b | Fall Break — no class | [Session note](L8b/README.md) |
| L8c | Regularization, generalization, and ridge coefficient shrinkage | [Lecture](L8c/CHEME-5800-L8c-Lecture-RegularizationAndGeneralization-Fall-2026.ipynb) · [Example](L8c/CHEME-5800-L8c-Example-RidgeCoefficientShrinkage-Fall-2026.ipynb) |
| L8d | Cross-validation and residual model checking | [Lab](L8d/CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb) |

The lecture and coefficient-path example retain the useful regularization
material. The integrated lab makes intercept handling, fold membership,
training-only standardization, residual diagnosis, and fold-level validation
errors explicit and testable.

```bash
julia --startup-file=no --project=. instructor/validation/week-08/runtests.jl
```
