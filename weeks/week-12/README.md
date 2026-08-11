# Week 12 — Tabular Q-learning and sequential-decision integration

Week 12 closes the sequential-decision spine by learning a policy from sampled experience.
The same stochastic grid-world contract supports a direct comparison between
model-based value iteration and model-free tabular Q-learning.

| Meeting | Topic | Notebook |
|---|---|---|
| L12a | Q-learning and temporal-difference updates | [Lecture](L12a/CHEME-5800-L12a-Lecture-TabularQLearning-Fall-2026.ipynb) |
| L12b | Learn a grid-world policy | [Lab](L12b/CHEME-5800-L12b-Lab-QLearningGridWorld-Fall-2026.ipynb) |
| L12c | Value iteration versus Q-learning | [Lab](L12c/CHEME-5800-L12c-Lab-ValueIterationVsQLearning-Fall-2026.ipynb) |
| L12d | Exploration and reproducibility | [Lab](L12d/CHEME-5800-L12d-Lab-ExplorationAndReproducibility-Fall-2026.ipynb) |

The Fall 2025 calendar used Week 12 for additional bandit material; that content is
now correctly placed in Week 10. This Q-learning unit is a new tabular integration
built from the course package's existing Q-learning/MDP lineage and the earlier
grid-world sources. Deep Q-learning remains Spring-owned material.

```bash
julia --startup-file=no --project=. instructor/validation/week-12/runtests.jl
```
