# Week 9 — Binary classification and numerical optimization

Week 9 covers linear classifiers and the numerical optimization used to train them. The
L9a example and the L9d lab use the UCI banknote authentication dataset with the same
training/testing split, so the L9d lab can compare the Perceptron and logistic regression on
the same banknotes. The L9b lab trains the Perceptron on a half circle, a wedge, and an XOR pattern to show where a linear classifier breaks down.

| Meeting | Topic | Notebook |
|---|---|---|
| L9a | Linear models for classification and the Perceptron | [Lecture](L9a/CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb) · [Banknote Perceptron example](L9a/CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb) |
| L9b | The Perceptron on data that are not linearly separable (XOR) | [Lab](L9b/CHEME-5800-L9b-Lab-XOR-Fall-2026.ipynb) |
| L9c | Logistic regression and optimization | [Lecture](L9c/CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb) |
| L9d | Logistic regression with gradient descent on the banknotes | [Lab](L9d/CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb) |

```bash
julia --startup-file=no --project=. instructor/validation/week-09/runtests.jl
```
