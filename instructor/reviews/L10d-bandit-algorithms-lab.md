# L10d bandit algorithms lab: answer sheet and build notes

Notebook: `weeks/week-10/L10d/CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb`
(replaces the scaffold `CHEME-5800-L10d-Lab-UCBAndThompsonSampling-Fall-2026.ipynb`).
Built 2026-10-10; revised 2026-10-12 after the codex audit changed the package bandit solvers
(zero rewards now count in sample means, `return_history = true` returns the selected arms,
ε-greedy uses the lecture schedule) and added the repeated-game comparison in Task 2. All
numbers below are for `seed = 5800`, `T = 5000`, Julia 1.12.7 with the pinned Manifest. They
are pinned in the week-10 suite (`@meeting "L10d"`, 119 tests).

## Sources

- **Tasks 1 and 2**: 2025 CHEME 5800 L12b, *Evaluation of Bandit Problem Algorithms*
  (`CHEME-5800-Instances/Fall-2025/CHEME-5800-Labs-Fall-2025/labs/week-12/L12b/...Solution...`).
  Kept: the title, the opening paragraph, the seven Beta arms, `K = 7`, `T = 5000`, the
  `world(...)` function, the arm table, the build/solve/results-array explanation, the regret
  definition, and the three theoretical bounds.
- **Task 3**: 2024 CHEME 5800 D12d, *Thompson and ε-greedy Thompson sampling and the Binary
  Bandit Problem* (`CHEME-4800-5800-Examples-Labs-Fall-2024/discussion/week-12/D12d/`). Kept:
  the success/failure scenario, the Oracle framing, `θ = [0.90, 0.60, 0.80]`, the uniform
  Beta(1, 1) priors, `T = 5000`, the true-vs-estimated table, and the Beta density plot of each
  arm. The student function follows the 2025 CHEME 5800 L12c Thompson pseudo-code and its
  notation (α(a), β(a), S(a), F(a)).

## What changed from the sources, and why

- **Student work added.** The 2025 lab was read-and-run. Students now complete three TODOs in
  `L10dThompson.my_thompson_sampling(...)` (`src/Compute.jl`): sample each posterior, take the
  argmax, update S and F. The package has no Thompson implementation, so the reference is
  `src/Compute-solution.jl`.
- **Regret uses the true best mean.** The package `regret(...)` uses the best *empirical* arm
  mean. The lecture defines regret with the true μ⋆, and we know it (10/12), so the notebook
  computes R(t) = tμ⋆ − (r₁ + … + rₜ) in an explicit loop. The package `regret` is not used.
- **Explore-first length fixed.** The 2025 cell computed `Nₐ = 3*(T/K)^(2/3)*(log T)^(1/3)` =
  490, but the package uses no factor 3. The notebook now computes the package's value, 163
  pulls per arm (1,141 exploring rounds), and says the package takes the hidden O constant as 1.
- **ε-greedy schedule matches the lecture.** Since 2026-10-12 the package pulls each arm once,
  then uses ε_t = min(1, (K log t / t)^(1/3)), the L10c schedule with a cap. For K = 7,
  ε_t = 1 through round 21. This made ε-greedy explore more than the old package schedule
  (t^(-1/3)(log(K t))^(1/3)), so it now has the largest regret of the three.
- **Seeded games.** The package solvers and the world use Julia's global RNG unseeded in 2025.
  Each game cell now calls `Random.seed!(seed)` first, so every run and every quoted number is
  reproducible. Task 3 uses one `MersenneTwister(seed)` for the agent and the world.
- **Three repeated "which arm was chosen at t = 4000 / best arm after exploration" cells**
  became one pull-count table (rows = arms, columns = algorithms), plus a look at the first ten
  rows of the UCB1 results array.
- **Arm plot.** 2025 plotted arm 2 against arm 6 ("other arm") with `plot!(d::Beta)`, which
  fails in the 2026 environment (no StatsPlots recipe). The lab keeps arm 2 against arm 6 and
  draws them with `pdf.(d, x)`; the Task 3 posterior plot uses `pdf.(d, x)` too. Open for Jeff:
  arm 5 (mean 0.769) is the closest competitor to arm 2 (0.833) and the arm UCB1 explores most,
  so plotting it would set up the Task 1 question; the build briefly used it and was reverted.
- **Dropped**: the 2024 ε-greedy Thompson variant (not in the L10c lecture), the
  `ThompsonSamplingModel`/`sample(...)` types (replaced by the student function), and the 2024
  claim that θ = (0.9, 0.6, 0.8) is "taken from Russo et al. Fig. 3.1". That figure uses
  θ = (0.9, 0.8, 0.7) (checked against arXiv:1707.02038, Section 3). The lab keeps Jeff's values
  without an attribution; switching to Russo's values is an option for Jeff.
- Colors: default Plots palette and `framestyle = :box`, no `bg = "gray95"`, so the figures read
  in both `theme(:default)` and `theme(:dark)` (both checked).

## Predictions and questions

**Task 1 prediction** (which algorithm pulls arm 2 most often): explore-first, 4,022 times.
ε-greedy 3,655; UCB1 only 3,518. Pull counts (arms 1–7):

| arm | mean | explore-first | ε-greedy | UCB1 |
|---|---|---|---|---|
| 1 | 0.500 | 163 | 236 | 111 |
| 2 | 0.833 | 4022 | 3655 | 3518 |
| 3 | 0.167 | 163 | 234 | 32 |
| 4 | 0.231 | 163 | 230 | 37 |
| 5 | 0.769 | 163 | 212 | 946 |
| 6 | 0.667 | 163 | 221 | 302 |
| 7 | 0.333 | 163 | 212 | 54 |

**Task 1 question** (why UCB1 explores arm 5): UCB1 pulls the arm with the largest
μ̄(a) + √(2 log t / Nₐ). Arm 5's mean, 0.769, is close to arm 2's 0.833, so a modest bonus keeps
its bound above arm 2's estimate, and it must be pulled many times before the two can be told
apart. Arm 3's mean is 0.167, so after a few pulls its bound falls far below arm 2's and stays
there. Explore-first and ε-greedy choose exploration pulls in turn or uniformly at random,
ignoring the rewards, so every arm gets about the same share. No: a pull of arm a gives up
μ⋆ − μ(a) in expectation, 0.064 for arm 5 but 0.667 for arm 3.

**Task 2 prediction** (smallest regret at T = 5000): UCB1. R(5000): explore-first 400.5,
ε-greedy 525.7, UCB1 232.0. Bounds (constants = 1): 1142.3, 1142.3, 546.0. Curves: explore-first
rises during its 1,141 exploring rounds (R(1141) = 386.4) and then stays between 385 and 403.
ε-greedy and UCB1 separate early: ε-greedy is 25 above UCB1 by round 487 and 50 above by round
880. ε-greedy crosses above explore-first at round 3,335 and stays above.

**Repeated-game prediction** (is UCB1 lowest at every horizon?): yes. Average gap loss over
seeds 5800–5829:

| T | explore-first | ε-greedy | UCB1 |
|---|---:|---:|---:|
| 1000 | 121.3 | 165.5 | 99.5 |
| 2500 | 233.3 | 323.5 | 161.1 |
| 5000 | 380.3 | 532.8 | 219.6 |
| 10,000 | 620.7 | 872.7 | 285.8 |

UCB1 beats both other algorithms in every one of the 30 games at every horizon, and
explore-first beats ε-greedy in every game. Explore-first commits to arm 2 in every game at every
horizon, so its gap loss is exactly N times the sum of the gaps (N = 52, 100, 163, 266) and its
standard deviation is 0; its realized regret still varies (SD 9.2 at T = 10,000). Average gap
loss and average realized regret differ by at most 3 at every entry. From T = 5000 to 10,000
the average gap loss grows by 1.63, 1.64, and 1.30; the bounds grow by 1.63 and 1.47.

**Task 2 question** (UCB1 pulls arm 2 less but has less regret): in expectation, regret charges
each pull by the gap μ⋆ − μ(a), not by whether it missed arm 2. Most of UCB1's non-arm-2 pulls go
to arm 5 (gap 0.064) and arm 6 (gap 0.167), which cost little; its gap loss in the seeded game is
218.6 against R(5000) = 232.0. ε-greedy's random pulls land equally on arm 3 (gap 0.667), arm 4
(0.603), and arm 7 (0.5). Doubling T: UCB1 has already identified the poor arms, and its remaining
exploration grows only logarithmically; ε-greedy keeps exploring at rate ε_t ~ t^(-1/3), so its
regret keeps growing like t^(2/3), and explore-first's exploration count grows like T^(2/3).

**Task 3 prediction** (most accurate estimate): arm 1. Pulls [4908, 11, 81]; S [4444, 6, 67];
F [464, 5, 14]; posterior means [0.905, 0.538, 0.819] against θ = [0.90, 0.60, 0.80].

**Closer-arm prediction** (θ₃ = 0.88): arm 3 is pulled more, 551 times instead of 81 (arm 1:
4,432). The direction held for seeds 1, 2, 3 (180, 1,202, 603 pulls of arm 3).

**Task 3 question** (rough estimate of θ₂): not a problem for the agent, whose goal is reward,
not estimates. Thompson sampling pulls an arm only when a sample from its posterior beats every
other arm's sample. Once arm 1's posterior is concentrated near 0.9, arm 2's posterior
(Beta(7, 6), mean 0.54) almost never produces a sample above 0.9, so arm 2 is pulled only rarely
during this run, even though its own posterior is still wide. UCB1 did the same with arm 3 in Task 1: once its
upper bound fell below arm 2's estimate, it pulled arm 3 only 32 times in the run (its bonus
still grows slowly, so UCB1 would return to it eventually).

## Check cell (student-facing) and mutation tests

`@testset "My Thompson sampling"` (7 tests): S + F = T; pulls and successes per arm agree with
`actions` and `rewards`; two fresh `MersenneTwister(seed)` replays reproduce `result.actions`;
on a test bandit θ = (0.70, 0.50, 0.90), `MersenneTwister(1234)`, 2000 rounds, arm 3 is pulled in
more than 1000 rounds and its posterior mean is within 0.05 of 0.9.

- Wrong fills caught: always arm 1, argmin, posterior mean instead of a sample (greedy), samples
  from the global RNG (`rand(Beta(...))` without `rng`), swapped Beta parameters, prior only (no
  learning), swapped S/F update. Updating only S trips the stub's "Oooops!" guard.
- Correct alternatives pass: `findmax(p)[2]`, `+=` updates, an if/else update.
- Data-independent: passes with seeds 1, 2, 42, 7 and T = 200, 1000, 5000, 20000. The test
  bandit thresholds held for all of 2000 seeds (minimum 1,346 pulls of arm 3; largest
  posterior-mean error 0.026).
- The two replays are needed because `@testset` reseeds the global RNG on entry. A single replay
  inside the testset could match a global-RNG implementation when the notebook is run from a
  fresh kernel without Tasks 1–2.

## Build notes

- `src/Compute.jl` (module `L10dThompson`, student stub), `src/Compute-solution.jl`, and
  `src/Utility.jl` (module `L10dUtility`: `compare_bandits` for the Task 2 repeated games and
  `bernoulli_world` for Task 3, documented in `docs/compare_bandits.md`). Codex first added the
  helpers as `src/Experiments.jl`; they were renamed on 2026-10-12 to follow the Utility.jl
  convention, loaded once behind an `isdefined` guard and brought in with `using .L10dUtility`.
  No Visualize.jl: all plots are short notebook cells, as in 2025.
- `Include.jl` loads `Compute.jl` unguarded and has no `using .L10dThompson`; the notebook calls
  `L10dThompson.my_thompson_sampling(...)`. The `Week10Core` include was removed.
- The notebook ships without outputs. With the stub, Tasks 1–2 run; Task 3 stops at the result
  cell with the "Oooops!" error.
- Style check (`notebook_style_check.py`, bare): 0 findings.
- Suite block: `@meeting "L10d"` with `import JSON`, `import REPL`, `using Test` at the top of
  the file (`using Test` so `@testset` parses when L10d is not in a release).
