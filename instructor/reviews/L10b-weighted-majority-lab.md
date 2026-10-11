# L10b weighted majority lab: rebuild notes and answer sheet

Rebuilt 2026-10-10 from the instructor's 2025 lab, after Jeff asked that week 10 copy as much
of the 2025 material as possible. The scaffold it replaces
(`CHEME-5800-L10b-Lab-MultiplicativeWeights-Fall-2026.ipynb`: three made-up "operating
policies" and an exponential update in `Week10Core.weighted_majority`) is deleted. The source
is:

- CHEME 5800 Fall 2025 L10b, `CHEME-5800-L10b-Solution-WeightedMajorityAlgorithm-Fall-25.ipynb`
  (the SPY game, the five ticker experts, the adversary, the package `build`/`play` run, the
  weight plot, the mistake-bound test, and most of the wording). CHEME 5820 Spring 2025 L6b is
  an earlier copy of the same lab.

New notebook: `weeks/week-10/L10b/CHEME-5800-L10b-Lab-WeightedMajorityAlgorithm-Fall-2026.ipynb`
(44 cells, no outputs, about 2,700 words of markdown, against 1,959 in the 2025 lab; the
addition is the house lab material: the TODO list, check, predictions, questions, and the
forecasting what-if).

## What was kept from 2025

The 2025 Background section (Game, Goal, Algorithm, Theorem) is kept, moved to where each part
is used: Game and Goal open Task 1, the algorithm opens Task 2 (the student implements it),
and the theorem opens Task 3. Kept as written: the CCGR blockquote, the `log_growth_matrix`
call, `list_of_tickers`, `tickerindexmap`, the `expert(...)` and `adversary(...)` functions
(same five experts, QQQ, NVDA, AMD, AAPL, MSFT, and "These are my choices for experts: you
pick yours"), the model build with T = 252 and ϵ = 10/T, the description of `sims` and
`weights`, the weight plot, `m_experts`, and the `L`/`R` bound computation and plot.

## What changed and why

- **Data cache.** `MyTrainingMarketDataSet()` needs an 88 MB JLD2 file that is not in the
  vendored package, so the 2025 cell cannot run here. `L10b/data/` holds a 9.7 MB CSV of the
  daily volume-weighted average price for the 424 tickers with all 2,767 trading days, the set
  the 2025 notebook kept after filtering. The notebook builds the same
  `dataset::Dict{String,DataFrame}`, so the 2025 flow after that point is unchanged, and
  students can still pick any of the 424 tickers as experts. The 2025 filter cells
  (`maximum_number_trading_days`) are gone because the cache is already filtered.
  Provenance and SHA-256 are in `L10b/data/README.md`.
- **Honest framing.** In 2025, each expert "predicts" SPY from its own ticker's growth on the
  same day, while the prose said "Each morning, we forecast the daily price direction." The
  experts and numbers are unchanged, but the notebook now says the advice uses same-day
  information, so the game measures how well a weighted vote combines correlated signals, not
  forecasting. Task 3 adds a forecasting version (below).
- **Student work.** `src/Compute.jl` (module `L10bWMA`) holds a scaffolded
  `my_weighted_majority(model, data)` with the same inputs and outputs as the package
  `play(model, data)`. Students fill three blanks: the vote (TODO 1), each expert's mistake
  (TODO 2), and the weight update (TODO 3). Until TODO 1 is done, a pre-written guard throws
  the "Oooops!" error. `Compute-solution.jl` is the reference.
- **Vote rule.** The package compares the weight of the experts predicting up with the weight
  predicting down and predicts 1 only if up is strictly larger (a tie goes to −1; an expert
  that predicts 0 counts toward neither side and is wrong). The 2025 lecture and lab said
  "predict 1 if the weight on 1 is at least half the total weight". The two rules differ only
  on an exact tie or when an abstaining expert holds the deciding weight. Neither happens in
  either game here (NVDA abstains in rounds 17, 46, 108, and 160; no tie occurs), but the
  notebook, the TODO, and the L10a lecture now state the package rule. The 2025 "we select n as
  odd to avoid ties" was dropped from both: weights like 1, 0.5, 0.5 can tie whatever n is.
- **Notation.** Expert predictions are $\hat{y}_{i}^{(t)}$ (as in the L10a MWA section), our
  prediction is $\hat{y}_t$ (as in the L10a WMA section), and the actual outcome is $y_t$. The 2025 lab used $y_t$ for
  both our prediction and the outcome.
- **"Which expert was best?"** 2025 called the largest final weight a heuristic. The final
  weight is exactly $(1-\epsilon)^{m_i}$, so it picks the expert with the fewest mistakes, and
  the notebook now says so.
- **Plots** use the default palette and `framestyle = :box` (no `bg = "gray95"`), so they
  read in the light and dark themes; the theme cell is the L9d one.
- **Dropped:** "Unhide the code block" phrasing and the 2025 sentence that pre-answered the
  bound plot ("This confirms the validity ...").

## Check cell (what it catches)

Your function must reproduce the package `play(...)` in every round for the notebook's model
and for ϵ = 1/2, so the check works for any choice of experts. Mutation tests (2026-10-10):
the reference, `Int(predictions[i] != y)`, `(1 - ϵ)^mistake`, a tie-to-up vote, and the
lecture's "at least half the total" vote all pass (the last two because no tie or deciding
abstention occurs). These fail: only TODO 1 done, no weight update, an abstaining expert
counted as correct, a weight that shrinks every round, an additive update, and a reversed
vote. The stub throws at the student call and nowhere else.

## Numbers (default experts, ϵ = 10/252, T = 252)

Rounds 1 to 252 are trading days 2014-01-06 to 2015-01-05.

| | mistakes | correct |
|---|---:|---:|
| expert 1, QQQ | 40 | 84.1% |
| expert 2, NVDA | 76 | 69.8% |
| expert 3, AMD | 83 | 67.1% |
| expert 4, AAPL | 79 | 68.7% |
| expert 5, MSFT | 91 | 63.9% |
| aggregator (us) | 44 | 82.5% |

QQQ has the largest weight in every round from 22 on (strictly largest in 232 of the 253
weight rows) and ends at 0.198, more than four times any other expert (0.046 or less). The
bound starts at 2 ln 5/ϵ = 81.1 and ends at 164.3; our 44 mistakes stay below it in every
round. With ϵ = 1/2, our mistakes drop to 42.

Forecasting game (`next_day_adversary`: experts report day t, the adversary reveals SPY on day
t + 1): we make 104 mistakes (58.7%), the best expert in hindsight is AAPL with 101 (59.9%),
the experts range from 52.0% to 59.9%, and always predicting up makes 106 mistakes (57.9%).
The bound holds in every round (it ends at 291.1). With ϵ = 1/2, we make 107 mistakes.

## Things to think about: answers

**Task 1.** No. Each expert's growth rate is computed from that day's volume-weighted average
price, which is only known once the market closes, the same time SPY's direction is known. To
help a decision that morning, an expert would have to use information available before the
open, such as the previous day's move. Task 3 tries exactly that.

**Task 2.** The vote is not the same as following the best expert. Until round 175, QQQ's
weight is smaller than the combined weight of the other four, so the experts that disagree
with QQQ can outvote it. That happened in 12 rounds, all between rounds 11 and 139: in 8 of
them we were wrong and QQQ was right (rounds 12, 31, 36, 51, 53, 69, 114, 139), and in 4 we
were right and QQQ was wrong (rounds 11, 37, 70, 94), hence 44 mistakes versus 40. From round
175 on, QQQ outweighs the other four together, so the vote follows QQQ. A larger learning rate shrinks the weights of experts
that make mistakes faster, so the vote follows the best expert sooner; with ϵ = 1/2 we make
42 mistakes. The theorem trades this off: a larger ϵ makes the constant 2 ln n/ϵ smaller but
the factor 2(1 + ϵ) larger.

**Task 3.** About the same as always predicting up (58.7% versus 57.9%), and SPY went up on
more than half of these days, so neither the experts nor the vote shows much forecasting
skill. The bound still holds because it only promises that we do not do much worse than the
best expert; when every expert is close to a coin flip, the guarantee is met while our
accuracy stays near what a constant guess gets. The bound is a guarantee relative to the
experts, not a guarantee of good predictions.

## Validation

- Executed from `weeks/week-10/L10b/` with `--project=@.`: with `Compute-solution.jl` swapped
  in after the setup cell, every cell runs and the check passes (6/6); with the stub, the
  first error is the "Oooops!" throw at the `my_weighted_majority` call (code cell 10).
- `python3 instructor/validation/notebook_style_check.py` on the notebook: 0 findings.
- Suite block (`@meeting "L10b"`, 46 tests) run in a scratch copy of the week-10 harness:
  46/46. It covers a hand-checked three-expert game and a tie, the stub's shape, the data
  cache hash, and every number quoted in the notebook and in this sheet.
