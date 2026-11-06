# Week 12 — Q-learning and model-free reinforcement learning

Week 12 learns a policy from experience instead of computing it from a model. The L12a
lecture builds the Q-learning update from the Bellman equation for the action values and
states when it converges; the L12a example treats a course of chemotherapy as a Markov
decision process and compares the dosing policy Q-learning learns with the optimal policy
from value iteration. In the L12b lab, students write their own Q-learning and use it to
guide a robot through the lava grid world to its charging station. The L12c lecture
compares value iteration and Q-learning: what each needs, what each costs, and where
tabular Q-learning runs out of room. The L12d lab feeds a bioreactor with Q-learning and
shows how the random seed and the amount of exploration change what the agent learns.

| Meeting | Topic | Notebook |
|---|---|---|
| L12a | Model-free reinforcement learning and Q-learning | [Lecture](L12a/CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb) and [example](L12a/CHEME-5800-L12a-Example-AdaptiveDosing-QLearning-Fall-2026.ipynb) |
| L12b | Q-learning in the lava grid world | [Lab](L12b/CHEME-5800-L12b-Lab-QLearningGridWorld-Fall-2026.ipynb) |
| L12c | Value iteration versus Q-learning | [Lecture](L12c/CHEME-5800-L12c-Lecture-ValueIterationVsQLearning-Fall-2026.ipynb) |
| L12d | Exploration and reproducibility in Q-learning | [Lab](L12d/CHEME-5800-L12d-Lab-ExplorationAndReproducibility-Fall-2026.ipynb) |

The L12a lecture and its figures are ported from the Fall 2025 CHEME 5800 Q-learning lecture.
The L12a example and the L12d lab are adapted from the CHEME 153 adaptive dosing and fed-batch
bioreactor activities, the L12b lab extends the week 11 grid world lab, and the limitations in
L12c come from the CHEME 5820 Q-learning lecture.

```bash
julia --startup-file=no --project=. instructor/validation/week-12/runtests.jl
```
