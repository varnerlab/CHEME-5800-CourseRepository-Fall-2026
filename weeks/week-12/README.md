# Week 12 — Q-learning and model-free reinforcement learning

In week 12, we learn a policy from experience instead of computing it from a model.

- The L12a lecture builds the Q-learning update from the Bellman equation for the action
  values. It also states when Q-learning converges.
- The L12a example trains a roomba with Q-learning to return to its charging station in the
  lava grid world. It compares the learned policy with the optimal policy from value iteration.
- In the L12b lab, students write their own Q-learning update. They use it to learn a
  chemotherapy dosing policy and compare it with the optimal policy from value iteration.
- The L12c lecture replaces the Q-table with a Q-network and builds deep Q-learning (DQN),
  starting from a linear network. It covers the DQN loss, the replay buffer, and the target
  network.
- The L12c example trains a linear DQN to dose the L12b patient without rounding the patient
  state to a grid. It compares the learned doses with policies from value iteration.
- The L12d lab shows how Q-learning and DQN overestimate action values. It tests Double
  Q-learning and Double DQN on a problem with two states.

| Meeting | Topic | Notebook |
|---|---|---|
| L12a | Model-free reinforcement learning and Q-learning | [Lecture](L12a/CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb) and [example](L12a/CHEME-5800-L12a-Example-QLearningGridWorld-Fall-2026.ipynb) |
| L12b | Adaptive drug dosing with Q-learning | [Lab](L12b/CHEME-5800-L12b-Lab-AdaptiveDosing-QLearning-Fall-2026.ipynb) |
| L12c | Deep Q-learning | [Lecture](L12c/CHEME-5800-L12c-Lecture-DeepQLearning-Fall-2026.ipynb) and [example](L12c/CHEME-5800-L12c-Example-LinearDQN-AdaptiveDosing-Fall-2026.ipynb) |
| L12d | Overestimation and Double DQN | [Lab](L12d/CHEME-5800-L12d-Lab-DoubleDQN-Fall-2026.ipynb) |

The L12a lecture and its figures are ported from the Fall 2025 CHEME 5800 Q-learning lecture.
The L12b lab is adapted from the CHEME 153 adaptive dosing activity, and the L12a example extends
the week 11 grid world lab. The L12c lecture draws on the CHEME 5820 deep Q-learning lecture. The L12d two-state problem is Example 6.7 of Sutton and
Barto (2018). The slide deck for L12a is in the lecture's `slides` folder.

```bash
julia --startup-file=no --project=. instructor/validation/week-12/runtests.jl
```
