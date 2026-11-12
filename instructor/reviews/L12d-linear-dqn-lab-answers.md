# L12d lab: a linear DQN for adaptive drug dosing — answer sheet

Built 2026-11-11 from the L12c linear DQN example, after the L12c lecture ran late. The lab's
code is complete. Each task ends with one question for the class, under "Things to think about",
where students rerun a cell with new values. The numbers below are for Julia 1.12 with the pinned Manifest, and
each one is checked in the week-12 suite (`@meeting "L12d"`).

The Double DQN lab that held the L12d slot is retired. It is in git history before this change
(`weeks/week-12/L12d/CHEME-5800-L12d-Lab-DoubleDQN-Fall-2026.ipynb`).

## Task 1: the continuous patient model

- **Which dose gives the largest one-cycle reward?** No dose (action 1), about −0.91 against
  −1.20 for the full dose. It adds no toxicity and no dose charge. Giving it every cycle lets the
  tumor grow and never cures the patient. One cycle's reward ignores the cure reward later on.

## Task 2: the grid policies

- **Which grids cure the patient?** In the table, 81 and 201 levels cure the patient. 41 levels
  time out, and 49 levels kill the patient in cycle 7.
- **If students ask why 49 levels kill the patient:** before that dose, the toxicity is 0.883,
  which rounds down to the grid level 0.875. From 0.875, the grid model predicts that the next
  dose keeps the toxicity just below 0.90. The real patient crosses 0.90.
- **Why did this policy cure the patient in the dosing lab?** There, the world rounded the state
  after every cycle. In cycle 13, the equations gave a tumor burden of 0.112, and rounding made
  it 0.100, a cure. Here the patient reaches 0.109 and stays there, but the policy looks up
  0.100 and gives no dose.
- **Does a finer grid always do better?** No. From the same start, 41 levels time out, 42–47
  cure, 48–50 kill the patient, and 51 cures again. Even fine grids fail sometimes: 87, 89, 109,
  117, and 119 levels also kill the patient. A grid policy is optimal for the rounded problem,
  and near the lethal level a small rounding error can be fatal. The linear DQN learned on the
  patient without a grid, so it never rounds the state.

## Task 3: the linear DQN

- **Which widths cure the patient?** The table trains one network per width in `σ_values`. With
  σ = 0.05, the policy times out. The basis functions are about 0.14 at their nearest center and
  near zero between centers, so most states have almost no features. With σ = 0.15, the policy
  cures the patient. With σ = 0.5, the patient dies of toxicity. Each basis function covers most
  of the square, so the Q-values change slowly with the state. The network cannot represent the
  sharp drop in value next to the lethal level. In the basis function figure, the narrow bumps
  leave gaps between their centers, and the wide bumps reach across most of the axis.

- **The comparison figure:** the 201-level policy cures in 19 cycles, and its toxicity peaks at
  0.89. The linear DQN takes 23 cycles, and its toxicity peaks at 0.85.

- **If students ask whether to train longer:** the loss levels off, and the treatment barely
  changes. With seeds 1234, 42, and 7, the last 500 steps average about 2.5 after 3000 episodes
  and about 1.6 after 12000; 24000 episodes do no better. Every run cures the patient from
  (0.90, 0) in 21–23 cycles, and from every starting tumor burden 0.2–1.0 with no toxicity.
