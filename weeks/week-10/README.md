# Week 10 — Online learning and multi-armed bandits

Week 10 starts with online learning from expert advice: the weighted majority and
multiplicative weights algorithms, judged by their regret against the best expert. The
L10b lab combines five expert tickers into a daily call on SPY and tests the mistake bound.
The second half removes the experts' full feedback and studies stochastic multi-armed
bandits, where the agent sees only the reward of the arm it pulls. The L10d lab compares
explore-first, epsilon-greedy, and UCB1 on the same arms, and students implement Thompson
sampling for a binary Bernoulli bandit.

The lectures work small examples by hand: four rounds of weighted voting, one UCB1
choice, and one Bernoulli posterior update. The L10c example plays the opening rounds of
UCB1 by hand on three sets of reaction conditions, then checks the full game against the
course package. The bandit lab compares the algorithms in one seeded game and then
averaged over 30 games at four horizons; its helper functions are described in
[L10d/docs/compare_bandits.md](L10d/docs/compare_bandits.md).

| Meeting | Topic | Notebook |
|---|---|---|
| L10a | Online learning: weighted majority and multiplicative weights | [Lecture](L10a/CHEME-5800-L10a-Lecture-OnlineLearningAndRegret-Fall-2026.ipynb) |
| L10b | The weighted majority algorithm on SPY | [Lab](L10b/CHEME-5800-L10b-Lab-WeightedMajorityAlgorithm-Fall-2026.ipynb) |
| L10c | Stochastic multi-armed bandits and Thompson sampling | [Lecture](L10c/CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb) and [example](L10c/CHEME-5800-L10c-Example-UCB1StepByStep-Fall-2026.ipynb) |
| L10d | Bandit algorithms and Thompson sampling | [Lab](L10d/CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb) |

The notebooks are ported from Fall 2025 CHEME 5800 (L10a, the L10b lab, L12a, the L12b lab,
and the Bernoulli bandit section of L12c) and the Fall 2024 Thompson sampling lab.

```bash
julia --startup-file=no --project=. instructor/validation/week-10/runtests.jl
```
