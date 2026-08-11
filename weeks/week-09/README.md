# Week 9 — Binary classification and numerical optimization

Week 9 uses one shared engineering case for the common path: predictive maintenance
on the UCI AI4I data. The perceptron and weighted logistic regression use the same
leakage-free features, stratified split, training-only scaling, and evaluation
metrics. XOR remains a compact optional separability diagnostic.

| Meeting | Topic | Notebook |
|---|---|---|
| L9a | Linear classification and perceptron updates | [Lecture](L9a/CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb) |
| L9b | XOR and feature representation | [Supporting example](L9b/CHEME-5800-L9b-Example-XORLinearSeparability-Fall-2026.ipynb) |
| L9c | Logistic regression and optimization | [Lecture](L9c/CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb) |
| L9d | AI4I model comparison | [Lab](L9d/CHEME-5800-L9d-Lab-AI4IPredictiveMaintenance-Fall-2026.ipynb) |

This implements the approved replacement of the Fall 2025 banknote case. The old
classification and nonlinear-optimization explanations are retained where useful;
the data loader, narrative, split, metrics, and models are now AI4I-specific and
tested for target leakage and class imbalance.

```bash
julia --startup-file=no --project=. instructor/validation/week-09/runtests.jl
```
