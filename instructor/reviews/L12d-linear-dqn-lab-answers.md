# L12d lab: a linear DQN for adaptive drug dosing — answer sheet

Built 2026-11-11 from the L12c linear DQN example, after the L12c lecture ran late. The lab's
code is complete. Each task stops at a few questions where students inspect a data structure or
rerun a cell with new values. The numbers below are for Julia 1.12 with the pinned Manifest, and
each one is checked in the week-12 suite (`@meeting "L12d"`).

The Double DQN lab that held the L12d slot is retired. It is in git history before this change
(`weeks/week-12/L12d/CHEME-5800-L12d-Lab-DoubleDQN-Fall-2026.ipynb`).

## Task 1: the continuous patient model

- **Which dose gives the largest one-cycle reward?** No dose (action 1), about −0.91 against
  −1.20 for the full dose. It adds no toxicity and no dose charge. Giving it every cycle lets the
  tumor grow and never cures the patient. One cycle's reward ignores the cure reward later on.
- **`Z_new = 0.7`:** only the full dose ends the treatment. The toxicity reaches about 0.955,
  above the lethal level, so the result is a toxic death with reward −60.

## Task 2: the linear DQN

- **The replay buffer:** slots 1, 2, and 3 hold cycles 4, 5, and 3 (actions 1, 2, and 3). Cycles 4
  and 5 overwrote cycles 1 and 2. `oldest` is 3, so the next transition replaces cycle 3, the oldest
  one still stored.
- **Fewer episodes:** with 100 episodes, the policy neither cures nor kills the patient within
  100 cycles (timeout). With 1,000 episodes, it cures the patient in 31 cycles, against 23 after
  3,000 episodes. The run is not monotone in between (500 episodes also times out), so students
  may see either outcome if they try other values.
- **The width σ:** with σ = 0.05, the policy times out. The basis functions are about 0.14 at
  their nearest center and near zero between centers, so most states have almost no features.
  With σ = 0.5, the patient dies of toxicity. Each basis function covers most of the square, so
  the Q-values change slowly with the state. The network cannot represent the sharp drop in
  value next to the lethal level.

## Task 3: the grid policies

- **Inside a grid policy:** rows 1–5 are the tumor burdens 0 to 0.10, where the patient is
  already cured. `solvegrid` gives these ended states action 1. A tumor burden of 0.109 rounds to
  row 5 (0.100), so the 41-level policy gives no dose, and the tumor grows back.
- **Near the lethal toxicity (`Z₀_new = 0.8`, then 0.85):** both policies cure every patient. The
  linear DQN needs 1–4 more cycles than the 201-level policy. Training starts draw the toxicity
  uniformly from 0 to 0.85, so the agent has seen states this toxic.
