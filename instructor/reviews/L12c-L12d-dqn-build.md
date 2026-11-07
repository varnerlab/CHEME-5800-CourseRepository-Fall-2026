# L12c deep Q-learning and L12d Double DQN: build notes and answer sheet

Built 2026-11-06, replacing the value-iteration-versus-Q-learning lecture (L12c) and the
bioreactor exploration lab (L12d). All numbers are for Julia 1.12.7 with the pinned Manifest.
Unless a bullet says otherwise, they are pinned in the week-12 suite (`@meeting "L12c"` and
`@meeting "L12d"`).

## Sources

- **L12c lecture:** the DQN section of the eCornell AI in finance session 3 lecture (May 2026):
  the four parts, the DQN Bellman loss box, and the algorithm. Also the curse-of-dimensionality
  framing of CHEME 5820 L16a (Spring 2026) and the DQN half of the 2025 CHEME 5800 L13c. The
  REINFORCE material in those lectures was left out on purpose. The linear Q-network, the
  one-hot check against the table, and the Double DQN target are new.
- **L12c figure:** the bottom panel is the eCornell DQN schematic, recolored for the dark theme;
  the top (linear) panel is new.
- **L12c example and L12d lab:** nothing earlier covers a linear DQN or Double DQN, so the code
  is new. The patient is the L12b model without the grid; the two-state problem is Sutton and
  Barto (2018), Example 6.7.

## Decisions and facts that are easy to get wrong

- **The network is linear, with a hand-written gradient step**, not a Flux layer. Flux was added
  to the environment on 2026-11-06 for the neural-network weeks; L12c does not use it.
- **No reward scaling is needed.** With W starting at zero, dividing every reward by a positive
  constant c divides the weights by c at every step, in exact arithmetic, because the max in the
  target is positively homogeneous. Multiplying the rewards by c multiplies the weights by c. The
  greedy policy is the same either way.
- **The L12b 41-level policy fails on the patient without a grid** (timeout at 100 cycles,
  G = -18.21). It snaps B = 0.109 to the grid level 0.100, which the grid counts as cured, and a
  cured grid state stores action 1 (no dose). `solvegrid(...; nlevels = 41)` reproduces the
  L12b policy state for state (the suite checks this), because `snap` uses the L12b rounding
  `round(x/step)`; rounding `x*(n - 1)` instead changed 25 states.
- **Double DQN changed little on the dosing problem in one scratch experiment** (mean
  overestimate of the start-state return 1.92 for DQN, 1.81 for Double DQN, over 10 seeds and 12
  starts, with no uncertainty estimate). The suite does not reproduce this, and `mydqn` has no
  Double DQN option. L12d uses the two-state problem instead, where the effect is large.
- **In the L12d experiment, Double DQN is weaker than Double Q-learning.** The target network is
  a recent copy of the Q-network. With C = 1 the two targets are identical.

## L12d answers

- **Task 1 question.** One action: the single estimate is -0.098, no bias, because there is no
  maximum to take. 10 actions with 100 rewards each: 0.053, a small bias, because each average
  is less noisy. Few actions and many samples per action keep overestimation small.
- **Task 2 question.** With one action in B, Q-learning never rises above the coin flip of the
  first episodes (largest share 51 percent, in episode 2), and its curve falls like the Double
  Q-learning curve. The bias needs a maximum over several noisy estimates; one estimate has none.
  (The what-if cell's default, 100 actions in B, keeps about 95 percent of the Q-learning agents
  on "left" in episode 300, against 7 percent for Double Q-learning.)
- **Task 3 question.** With C = 100, the gap in episode 300 grows to 68 versus 44 percent (from
  69 versus 54 at C = 25). For the first 60 or so episodes both curves sit near 50 percent: the
  target network is still all zeros, so "left" and "right" have the same target and the agents
  learn nothing about A. Copying less often makes the second estimate more independent, at the
  price of slower learning.
