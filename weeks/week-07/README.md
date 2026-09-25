# Week 7 — SVD, data reduction, and ordinary least squares

Week 7 develops one geometric thread: SVD exposes dominant matrix directions,
low-rank reconstruction compresses multivariate data, and OLS projects observations
onto a model's column space.

| Meeting | Topic | Notebook |
|---|---|---|
| L7a | SVD and low-rank approximation | [Lecture](L7a/CHEME-5800-L7a-Lecture-SVDAndDataReduction-Fall-2026.ipynb) |
| L7b | Stoichiometric structure and singular value decomposition | [Example](L7b/CHEME-5800-L7b-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb) |
| L7c | OLS as projection | [Lecture](L7c/CHEME-5800-L7c-Lecture-OrdinaryLeastSquares-Fall-2026.ipynb) |
| L7d | Housing-price regression contracts | [Lab](L7d/CHEME-5800-L7d-Lab-HousingPriceOLS-Fall-2026.ipynb) |

The L7b example uses a cached human platelet metabolic model to examine numerical
rank, cumulative matrix reconstruction, conservation relations, and balanced-flux
directions. Its supplied model supports offline execution.

```bash
julia --startup-file=no --project=. instructor/validation/week-07/runtests.jl
```
