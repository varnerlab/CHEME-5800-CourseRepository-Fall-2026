# Week 11 — Markov models, MDPs, and value iteration

Week 11 starts with Markov chains: states, the Markov property, the transition matrix,
and the stationary distribution, which the L11a example computes by power iteration and
checks by simulation. The L11b lab builds a character-level Markov model from about
370,000 English words and generates new words one character at a time. An optional L11b
example builds a position-aware Markov generator from a small Kunitz protein-family
alignment, evaluates its candidate sequences, and conditions the generator toward a
selected amino-acid marker. The second half
adds actions and rewards to the chain to form a Markov decision process, solved by value
iteration and estimated by random rollouts; the L11c example compares the two on the lecture's
slippery grid world and shows that rollouts estimate the value of random actions, not the optimal
value. In the L11d lab, students write their own
value iteration with a convergence check and use it to guide a robot through a grid world
to a charging station while avoiding lava pits.

| Meeting | Topic | Notebook |
|---|---|---|
| L11a | Markov models and the stationary distribution | [Lecture](L11a/CHEME-5800-L11a-Lecture-MarkovModels-Fall-2026.ipynb), [Example](L11a/CHEME-5800-L11a-Example-MarkovModels-Fall-2026.ipynb) |
| L11b | Markov sequence generators | [Word-generator lab](L11b/CHEME-5800-L11b-Lab-MarkovWordGenerator-Fall-2026.ipynb), [protein-generator example](L11b/CHEME-5800-L11b-Example-MarkovProteinGenerator-Fall-2026.ipynb) |
| L11c | Markov decision processes, value iteration, and random rollout | [Lecture](L11c/CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb), [Example](L11c/CHEME-5800-L11c-Example-RandomRollout-Fall-2026.ipynb) |
| L11d | Value iteration in a grid world | [Lab](L11d/CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb) |

The notebooks are ported from the Fall 2025 CHEME 5800 week 11 lectures, example, and labs; the
L11c example is new for Fall 2026. Slide decks for L11a and L11c are in each lecture's `slides`
folder.

```bash
julia --startup-file=no --project=. instructor/validation/week-11/runtests.jl
```
