# Week 9 review — October 12, 2026

**Status:** Reviewed and approved by the instructor on October 12, 2026
("ok - mark week-9 as reviewed"). The review covers all seven current Week 9
notebooks and their supporting Julia code and figures. All seven notebooks meet
the 9/10 review threshold. The review is closed.

## Final assessment

| Notebook | Score |
|---|---:|
| [L9a linear classification lecture](../../weeks/week-09/L9a/CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb) | 9.3/10 |
| [L9a banknote Perceptron example](../../weeks/week-09/L9a/CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb) | 9.4/10 |
| [L9b XOR lab](../../weeks/week-09/L9b/CHEME-5800-L9b-Lab-XOR-Fall-2026.ipynb) | 9.4/10 |
| [L9c logistic regression lecture](../../weeks/week-09/L9c/CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb) | 9.1/10 |
| [L9c gradient descent and simulated annealing example](../../weeks/week-09/L9c/CHEME-5800-L9c-Example-LogisticRegression-GD-SA-Fall-2026.ipynb) | 9.2/10 |
| [L9c advanced nonlinear optimization](../../weeks/week-09/L9c/CHEME-5800-L9c-Advanced-NonlinearOptimization-Fall-2026.ipynb) | 9.2/10 |
| [L9d banknote logistic regression lab](../../weeks/week-09/L9d/CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb) | 9.4/10 |

## Correction completed during review

The advanced optimization notebook initially scored 8.8/10 because its numerical
example omitted the high precision used by its validation. A Float64 reproduction
stalled near the active-constraint solution with the original inner tolerance of
1e-8. At the instructor's request, the example now uses Float64 arithmetic and an
inner tolerance of 1e-5, while keeping the outer KKT tolerance at 1e-3. Both tables
were regenerated from the numerical iterates, and the explanation and residual
claims were updated. The validation uses Float64 throughout and checks the types
of the iterates, weights, and multipliers.

## Verification

- The Week 9 Julia suite passed all **210 checks** after the Float64 correction:
  L9a 17, L9b 39, L9c 93, and L9d 61. The lab notebooks were executed with their
  reference solutions replacing the intentional student stubs.
- The L9c gradient descent and simulated annealing example was executed separately;
  its four checks passed and its saved numerical results were reproduced.
- The active-constraint, inactive-constraint, and equality-penalty cases converge
  in Float64 and agree with independent analytical solutions within the stated
  tolerances. The validation also checks bounded termination and line-search failure.
- All seven notebooks have three learning objectives and three equation-free key
  takeaways, and their local links resolve. Lecture diagrams and computed plots
  were inspected in light and dark appearances.
- The corrected advanced notebook passed notebook-schema validation and HTML
  export; both numerical tables contain the five expected data rows.

Validation command, from the repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-09/runtests.jl
```

## Reviewed notebook snapshots

SHA-256 values, with paths relative to `weeks/week-09/`:

```text
9aea979f91f8c887f30394da5e9fea632a686630642671a8ecd7792ec95072d6  L9a/CHEME-5800-L9a-Lecture-LinearClassificationAndPerceptron-Fall-2026.ipynb
3831a93cd12ae9f043a8e1a8bedfb04a3bff43aeabe03c9ff4d0808dee557c9a  L9a/CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb
41341d5757a4de6f062dd52d009bcf3014368ba144179f55491a197b29afb04f  L9b/CHEME-5800-L9b-Lab-XOR-Fall-2026.ipynb
e93c0eedfec2506406fcbff9905404fb2694506b49a783f224738fb0690da61e  L9c/CHEME-5800-L9c-Lecture-LogisticRegressionAndOptimization-Fall-2026.ipynb
b0ead334a1df332711b158699cfa1001a4618159198aaefe79c46b6f388df782  L9c/CHEME-5800-L9c-Example-LogisticRegression-GD-SA-Fall-2026.ipynb
fa0c697db76a7199d6640526edc357aae09deb6863a3d34c543980c42521c9c8  L9c/CHEME-5800-L9c-Advanced-NonlinearOptimization-Fall-2026.ipynb
5587242ba94d57ba0304562e48cea8b3d3876a5e7a7f59f02ad0f8d68c322f83  L9d/CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb
```
