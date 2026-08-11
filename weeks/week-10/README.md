# Week 10 — Online learning and ordinary multiarm bandits

Week 10 starts with full-information multiplicative weights, then removes that
feedback advantage and studies stochastic bandits. The common bandit lab compares
UCB1 and Thompson sampling on identical seeded Bernoulli arms.

| Meeting | Topic | Notebook |
|---|---|---|
| L10a | Online learning and regret | [Lecture](L10a/CHEME-5800-L10a-Lecture-OnlineLearningAndRegret-Fall-2026.ipynb) |
| L10b | Multiplicative weights | [Lab](L10b/CHEME-5800-L10b-Lab-MultiplicativeWeights-Fall-2026.ipynb) |
| L10c | Stochastic multiarm bandits | [Lecture](L10c/CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb) |
| L10d | UCB1 and Thompson sampling | [Lab](L10d/CHEME-5800-L10d-Lab-UCBAndThompsonSampling-Fall-2026.ipynb) |

The online-learning lecture and multiplicative-weights motivation retain strong
Fall 2025 material. Ordinary bandit material is moved here from the old Week 12
calendar so Week 12 can focus on Q-learning as approved.

```bash
julia --startup-file=no --project=. instructor/validation/week-10/runtests.jl
```
