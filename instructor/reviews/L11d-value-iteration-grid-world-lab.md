# L11d value iteration grid world lab: answer sheet and build notes

Notebook: `weeks/week-11/L11d/CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb`
(replaces the scaffold notebook of the same name, a 230-word 4×3 slip-grid stub).
Built 2026-10-11, revised the same day after the codex review of week 11. All numbers below are
for the notebook's constants (20×20 grid, γ = 0.95, ϵ = 1e-6, k_max = 1000), Julia 1.12.7 with
the pinned Manifest. Value iteration has no random numbers, so no seed is needed. The numbers
are pinned in the week-11 suite (`@meeting "L11d"`, 75 tests).

## Sources

- **The whole lab**: 2025 CHEME 5800 L11d, *Value Iteration for Grid World Navigation*
  (`CHEME-5800-Instances/Fall-2025/CHEME-5800-Labs-Fall-2025/labs/week-11/L11d/...Solution...`).
  Kept: the title, the opening paragraph and the Stanford backstory, the three tasks, the 20×20
  grid, the five lava squares, the charging station at (4,3), the rewards (−1000, +100, −1 per
  step, −50000 off the grid), the absorbing-state rules, the R and T construction code, the
  transition sanity check, the MDP definition box, the Task 3 Bellman equation, the Q and policy
  sections, the start state (20,20), and the student task, refactoring the Stanford value
  iteration into `mysolve` with a convergence check.
- References only: CHEME 145 M2 `...Example-ValueIteration-GridWorld-Ungraded-Codio-Activity`
  (a near-verbatim copy of 2025 that set γ = 0.95 and used the package `solve`/`Q`/`policy`),
  and CHEME 145 M4 `src/Compute.jl` `solve(::MyValueIterationModel, ...)` (a converged loop that
  copies with `copyto!`).

## What changed from 2025, and why

- **γ = 0.95, not 0.05.** The 2025 constants cell set `γ = 0.05`, while the 2025 MDP Definition
  box in the same notebook says "γ = 0.95". At 0.05 the computed policy walks the robot from
  (20,20) into a loop, so the 2025 path figure showed a failed robot. The lab now uses 0.95, and
  the old value became the Task 3 what-if.
- **Absorbing states earn nothing more** (codex review). In 2025, `R` was computed from the
  neighbor square even in an absorbing state, while `T` kept the robot in place, so the station
  and every lava pit kept paying −1 per sweep (value −1/(1−γ) = −20, and 81 next to the
  station), which contradicts "the episode ends". The R cell now sets `R[s, :] = 0` for the
  station and the lava pits, and the reward prose says so in one clause. Now the station and the
  pits are worth 0 and the squares next to the station 100. The 33-move path is unchanged.
- **The 2025 reference `mysolve` was wrong.** It wrote `U = U_new` with a preallocated `U_new`,
  so after the first sweep `U` and `U_new` are the same array. The second sweep then reads
  values it has already overwritten, the change `U_new − U` is zero, and the loop stops after
  2 sweeps whatever the problem. The new reference copies (`U .= U_new`), and the TODO 3
  comment names this trap, because the 2025 solution fell into it.
- **Pseudocode matches the L11c lecture** (codex review). Task 3 now uses the lecture's
  corrected stopping steps: `While not converged`, step 2 "Check whether to stop" (return on
  convergence; return with `converged = false` and a warning at the iteration limit), step 3
  "Increment the iteration counter". The lab keeps its sweep definition, uses $k_{\max}$ for the
  limit, and drops the duplicate `__Extract Policy__` step (the Q and policy subsections follow).
  `mysolve` mirrors the steps, logs the warning at the limit, and returns
  `(U, iterations, converged)` with `iterations = k + 1`, the number of sweeps.
- **Package names.** The 2025 lab carried local copies of the types and `QM`, `mypolicy`,
  `MyValueIterationSolution`. The vendored package has the same grid world `build` (checked:
  the same `states`, `coordinates`, and `moves`), `MyMDPProblemModel`, `MyValueIterationModel`,
  `solve` (the Stanford version, returning `MyValueFunctionPolicy` with field `U`), `Q`,
  `policy`, `lookahead`, and `backup`. The lab uses those; `src/` holds only the student file.
- **The "unfinished" guard fires only on the stub** (codex review). The blanks are now `NaN`
  ("not a number"), and the guard throws "Oooops!" when the change Δ is `NaN`, so a valid
  result whose optimal values are all zero (one state, rewards 0 and −1) is accepted.
- **`follow_policy` handles an absorbing start** (codex review): a robot that starts at the
  station or in a lava pit does not move.
- **Dead code dropped from the path figure**: the empty `soft_wall_set`, and the
  `is_reward_shaping_on` branch, which called an undefined `rbf` with an undefined `σ`. The path
  simulation became a `follow_policy(...)` function and the figure a `draw_path(...)` function,
  both in the notebook, so the γ what-if can reuse them. Arrows are `:dodgerblue`, the station
  green, the lava red, on `framestyle = :box`; checked in `theme(:default)` and `theme(:dark)`.
- **2025's five "Future Directions" became one question per task**, the live-lab format: Task 2
  asks about the 0.8/0.1/0.1 slip model (2025 direction 2, and the L11c lecture's grid example),
  and Task 3 runs the γ what-if (2025 direction 1). Directions 3–5 were dropped.
- Removed the 2025 display cells for `𝒮`, `sum(T[24,:,1])`, and `m.𝒮`; the sanity check is now
  one `all(...)` line.

Length: markdown about 2,790 words (2025: 2,328, including the 263-word Future Directions). The
increase is the student-task box, the check-cell explanation, the corrected pseudocode, and the
what-if.

## Predictions and questions

**Task 1 question** (entries of R and T): $R$ has 400 × 4 = 1,600 entries and $T$ has
400 × 400 × 4 = 640,000. Every state-action pair leads to exactly one next state (staying put
counts, at the edge or in an absorbing state), so exactly 1,600 of the transition
probabilities are nonzero, 0.25 percent. This is why the lecture's $O(|\mathcal{S}|^2|\mathcal{A}|)$
cost per sweep is mostly multiplications by zero here.

**Task 2 question** (the 0.8/0.1/0.1 slip model): for a square in the middle of the grid,
`T[s, :, a]` has three nonzero entries: 0.8 at the intended neighbor and 0.1 at each of the two
side neighbors, still summing to 1. A slip that would leave the grid should leave the robot
where it is, so that 0.1 is added to `T[s, s, a]`, the same rule our model uses for an
off-grid move. (The reward would then be an expected reward over where the robot lands.)

**Sweeps prediction**: about 30 (34). The Stanford version runs all 1000, and the two value
functions are identical (largest difference 0.0). The largest change is 100 in sweep 1 (the
squares next to the station learn the +100) and stays above 19 through sweep 33, while news of
the station moves one square per sweep toward the farthest square, 33 moves away. In sweep 34
no value changes at all. Every move is certain and the episode ends at the station, so each value
is exact as soon as the news reaches it. Values: 100 next to the station, 0 at the station and in
the lava pits, 3.245 at (20,20).

**Path** (shown, not asked): 33 moves, the fewest possible (16 in x, 17 in y). First move down to
(20,19), because left is the lava at (19,20); left along y = 19 to x = 5; down the column x = 5
(column x = 4 has the lava at (4,5)); then (4,4) and (4,3). Several shortest paths tie; `policy`
takes the lowest action index among ties (left before down).

**γ prediction** (γ = 0.05): no, the computed greedy policy does not lead the robot to the
station, and value iteration needs fewer sweeps (8). The robot walks down to (20,19), left along
y = 19 to (1,19), and its next move returns to (2,19).

Why (stated in the notebook's "What do we see?", so students can discuss it): the loop is a
numerical effect, not the exact optimum. The exact optimal policy still goes to the station,
because the exact value of a square falls strictly with its distance from the station. But to a
robot at (20,20) the station's +100, 33 moves away, is worth only 100 × 0.05³² ≈ 2 × 10⁻⁴⁰
today. That is far below ϵ, so value iteration stops after 8 sweeps, before the news of the
station reaches the far squares, and it is also far below the spacing of Float64 numbers near
−1.05 (about 2 × 10⁻¹⁶), so more sweeps would not help. Every square more than 10 moves from the
station gets exactly the same computed value, −1.0526; at (20,19) the computed values of left,
down, and up are exactly equal, and `policy` (an argmax) takes the first, left. From 213 of the
394 starting squares the computed policy still reaches the station: all starts within 8 moves
do, the farthest lucky one is 24 moves away, and the nearest looping start is 9 moves away.

**Task 3 question** (γ = 0.5 and 0.99; how the number of sweeps changes, and why):
- `γ_low = 0.5`: 28 sweeps, and the computed policy reaches the station in 33 moves, from every
  starting square. Near (20,20), some moves are still tied numerically (at (20,19) left, down,
  and up are exactly equal), and the tie-break "left" happens to head toward the station until
  the robot is close enough for the values to guide it.
- `γ_low = 0.99`: 34 sweeps, 33 moves, every starting square reaches the station.
- Why: news of the station moves one square per sweep, and the loop stops once the news still
  arriving is worth less than ϵ, about when 100 γᵈ ≤ 10⁻⁶ for the distance d it has reached. That
  happens after about 6 squares at γ = 0.05 (8 sweeps) and 27 at γ = 0.5 (28 sweeps). For γ of
  about 0.7 and above, the news is still worth more than ϵ when it reaches the farthest square,
  33 moves away, so the count levels off at 34, the sweep in which nothing changes. (Before the
  codex fix, when absorbing states kept paying −1, the count kept growing as γ → 1: 271 sweeps
  at 0.95 and 1,376 at 0.99.)

## Check cell (student-facing) and mutation tests

`@testset "My value iteration"` (8 tests at the defaults):
- a one-state test problem whose value falls every sweep (reward −1 forever, γ = 1/2, exact
  value −2): `mysolve` converges in 21 sweeps (the change in sweep k is (1/2)^(k−1)) and lands
  within 10⁻⁶ of −2;
- if the main run converged: every value equals its Bellman backup (`backup(...)`) to within
  ϵ; a run with `k_max = n − 1` stops at the limit with a warning (`@test_logs`), reports n − 1
  sweeps, and matches the package `solve` after n − 1 sweeps (same start, same order); and
  max |U − U_Stanford| ≤ γϵ/(1−γ) + γ^k_max·max|R|/(1−γ);
- if it did not converge: n = k_max, the values match the package `solve` after k_max sweeps,
  and the last sweep changed some value by more than ϵ (compared with a run of k_max − 1
  sweeps, or with the zero starting values when k_max = 1).

Wrong fills caught, at the defaults and with k_max = 10: `U = U_new` (aliasing, the 2025 bug),
no copy (`U .= U`), copying stale values, first action instead of the max, mean over actions,
min instead of max, a signed change (no `abs`), a zero change, a change that never falls below
ϵ, and running to `k_max` while claiming convergence. The one-state test problem is what
catches the signed change, which gives the right answer on this grid because values there only
rise. Any `NaN` blank (the untouched stub, or one TODO left blank) trips the "Oooops!" guard.
Correct alternatives pass: `U = copy(U_new)`, `copyto!(U, U_new)`, `U[:] = U_new`, a for-loop
max, `findmax(...)[1]`. A sum-norm change also passes: it is a stricter stopping rule, so the
values still converge.
Data-independent: passes with γ = 0.05, 0.5, 0.99, a 10 × 10 grid, ϵ = 1e-3, k_max = 1, 2, 10,
33 (one short of converging), 34, and 100, γ = 0.5 with k_max = 10, and re-running the check,
solution, and setup cells out of order.

## Build notes

- `src/Compute.jl` (module `L11dValueIteration`, student stub, 3 TODOs) and
  `src/Compute-solution.jl`; the student file differs only in its header, the TODO comments,
  and the three blank lines (`U_new[s] = NaN;`, `Δ = NaN;`, `U .= NaN;`).
- `Include.jl` loads `Compute.jl` unguarded and has no `using .L11dValueIteration`; the
  notebook calls `L11dValueIteration.mysolve(...)`. The `Week11Core` include was removed.
  IMPORTS: `Test`, `Plots` (the package comes from the root bootstrap).
- The notebook ships without outputs. With the stub, Tasks 1–2 run, and Task 3 stops at the
  solution cell with the "Oooops!" error.
- Run time with the reference: about 3 s for the notebook (the Stanford `solve` is about 1 s).
- Style check (`notebook_style_check.py`, bare and `--strict`): 0 findings.
