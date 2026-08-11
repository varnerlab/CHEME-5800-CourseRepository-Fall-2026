# Week 11 — Markov models, MDPs, and value iteration

Week 11 progresses from uncontrolled stochastic transitions to controlled decisions.
Students propagate distributions, sample a categorical sequence, formulate an MDP,
and solve a stochastic grid world by Bellman value iteration.

| Meeting | Topic | Notebook |
|---|---|---|
| L11a | Markov models and distributions | [Lecture](L11a/CHEME-5800-L11a-Lecture-MarkovModels-Fall-2026.ipynb) |
| L11b | Markov sequence generation | [Lab](L11b/CHEME-5800-L11b-Lab-MarkovSequenceGenerator-Fall-2026.ipynb) |
| L11c | MDPs and Bellman backups | [Lecture](L11c/CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb) |
| L11d | Stochastic grid-world value iteration | [Lab](L11d/CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb) |

This directly retains and corrects the strongest Fall 2025 Markov, MDP, word-
generator, and grid-world material. Transition orientation, terminal semantics,
seeds, and Bellman convergence are now explicit contracts.

```bash
julia --startup-file=no --project=. instructor/validation/week-11/runtests.jl
```
