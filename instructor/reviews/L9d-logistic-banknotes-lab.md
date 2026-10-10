# L9d logistic regression banknote lab: rebuild notes and answer sheet

Rebuilt 2026-10-09 from the instructor's 2025 materials, after the predictive-maintenance
scaffold (`CHEME-5800-L9d-Lab-PredictiveMaintenance-Fall-2026.ipynb`, `Week09Core`, and
`L9d/data/ai4i2020.csv`) was dropped in favor of the banknotes:

- CHEME 5800 Fall 2025 L9d, `CHEME-5800-L9d-Solution-LogisticRegression-Banknotes-Fall-2025.ipynb`
  (title, opening sentences, banknote data, 80/20 split, gradient descent on the cross-entropy
  loss, test confusion matrix).

The notebook is git-mv'd to `CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb`.

## Why it is not a straight port

The 2025 lab would now repeat two week-9 notebooks. The L9c example already writes the
gradient descent loop with the analytic gradient, sets α = 1/L, draws probability contours,
and compares thresholds; the L9a example already loads, splits, and scores the banknotes.
The 2025 lab also ran the package `learn(...)` for logistic regression, which uses a
finite-difference gradient (20,000 iterations in 2025) and names the parameters `β` and the
inverse temperature `T`, the reverse of the lecture. Its `classify(...)` ignores `T`.

Jeff chose (2026-10-09) to keep what only L9d can do:

1. **Student work: `my_logistic_regression(...)`** in `src/Compute.jl` (module `L9dLogistic`),
   scaffolded like L9b: loops, counters, loss history, and return are written; students fill
   three blanks, one per step of the L9c algorithm: term i of the gradient (TODO 1), the update
   (TODO 2), and the stopping test (TODO 3). The penalty gradient δθ is pre-written as the
   starting value of `∇J`, so the ridge term from the L9c lecture (which the L9c example skips)
   is in every run. An unfinished stopping test runs all `maxiter` steps and reaches the
   "Oooops!" throw.
2. **Perceptron vs. logistic regression on the same banknotes**, with the L9a example's split
   (`MersenneTwister(1234)`, 80/20).
3. **An inspector band**: decide automatically outside `(t_low, t_high)`, send the rest to a
   person. This is what the probability adds over the Perceptron's sign.

Jeff chose standardized features for both models (L9c lecture: scale before penalizing), so
the Perceptron count (5) differs from the L9a example's raw-feature count (12); the notebook
says so in one parenthetical.

## Other changes from 2025

- **Notation** follows the 2026 L9c lecture: θ parameters, β inverse temperature (fixed at 1),
  δ penalty, α = 1/(L + δ) with L = β²‖X̂‖₂². 2025 used a hand-picked α = 0.005.
- **Analytic gradient** (lecture box) instead of finite differences.
- **Parameters start at zero** (2025: 0.01 ones), so the first loss is n log 2.
- **Probabilities plotted, not printed.** 2025 printed the 274×2 `P` matrix. The lab draws a
  strip plot (`src/Visualize.jl`, module `L9dVisualize`, `plot_probabilities`) with the light /
  dark theme keyword; L9b colors (orange forged, teal genuine, gray missed).
- **Dropped:** the Boltzmann derivation (now in the L9c lecture), the general barrier/penalty
  gradient descent algorithm (L9c lecture and advanced notebook), and the `log10` note.
- **Ships without outputs**, like L6d, L8d, and L9b.

## Check cell (what it catches)

Four tests: the loss never increases; δ = 0 uses all `maxiter` steps unconverged; δ = 10
converges before `maxiter`; at the δ = 10 answer, a central finite-difference gradient of the
notebook's own `J` is below 1e-2 (it is 2.3e-3; the stopping rule allows up to ϵ(L + δ) ≈
2.4e-3). Checked against broken versions: a flipped sign, a missing 2β, σ(u) in place of
1 − σ(u), a `+` update, and a stopping test that ignores ϵ all fail; the reference passes.

## Verified numbers (seed 1234, 1,097 training / 275 testing banknotes, β = 1, ϵ = 1e-6)

| Quantity | Value |
|---|---|
| L = ‖X̂‖₂² (scaled training data) | 2384.0 |
| δ = 0, `maxiter` = 50,000 | not converged; loss 760.38 → 497 (step 1) → 32.9 (step 1,000) → 20.40 |
| training mistakes at δ = 0 | 9 of 1,097 |
| logistic test confusion [TP FN; FP TN] | [128 2; 0 145]; misses are forged, P = 0.291, 0.333 |
| Perceptron test confusion, T = 1000 | [126 4; 1 144] (5 mistakes) |
| Perceptron test mistakes, T = 998 / 999 / 1001 / 1002 | 4 / 6 / 7 / 3 |
| one more GD step (50,001) | θ moves 5.7e-5; labels unchanged (2 mistakes) |
| P below 0.01 or above 0.99 | 254 of 275 |
| band (0.25, 0.75) | 5 to inspector, 0 automatic mistakes |
| band (0.4, 0.6) | 2 to inspector (both genuine, P = 0.463), 2 automatic mistakes |
| band (0.1, 0.9) | 9 to inspector, 0 automatic mistakes |
| δ = 10 | converged in 672 steps; 6 test mistakes (1 FN, 5 FP); band (0.25, 0.75): 12 inspected, 0 automatic mistakes |
| δ = 1 | 5,148 steps; 4 test mistakes; band (0.25, 0.75): 8 inspected |

The δ = 10 step count is quoted as "under 700" because a student's summation order can move
it by a step. Test mistakes are not monotone in δ (δ = 0.1 gives 4, δ = 0.5 gives 3), so the
prose compares only δ = 0 with δ = 10. The suite checks every number the notebook prose quotes
(672 as "under 700", the last step as "less than 1e-4"); the extra answer-sheet runs (δ = 1,
T = 998/999/1002, the other bands, the curvature values below) were verified separately.

Codex review (2026-10-09, read-only, 8.5/10) confirmed every number and the suite (17/17,
39/39, 60/60). Its two accuracy corrections are applied: the notebook no longer explains the
slow convergence by the 9 misclassified banknotes (it now leaves the "why" to the Task 1
question), and it no longer says the penalty pulls every probability toward 1/2.

Jeff reviewed the lab on 2026-10-09 and approved it, along with the sentence added to the L9c
lecture's Lab cell.

## Answers to "Things to think about"

**Task 1.** The learning rate α = 1/L is set by how sharply the loss curves at its most
curved, and for this loss that is at θ = 0, where every probability is 1/2: the largest
eigenvalue of the Hessian (the matrix of second derivatives) there equals L = 2384. Near the
answer, most training banknotes have probabilities near 0 or 1, so they barely change the
gradient, and the loss is much flatter: at the 50,000-step answer the Hessian eigenvalues are
0.067, 4.35, 19.2, 26.0, and 99.9. In the flattest direction, a step of 1/L removes only about
0.067/2384 ≈ 3e-5 of the remaining error, so tens of thousands of steps make slow progress
(‖θ‖ is still growing: 17.1 at 50,000 steps, about 19.5 at 200,000). We have not measured
the L9c example's curvature; its clusters overlap, which keeps more points away from
probabilities 0 and 1, and it converged in a few hundred steps. A penalty δ > 0 adds δ to every
curvature (strongly convex, as the L9c lecture says), so gradient descent converges much
faster: 5,148 steps at δ = 1 and 672 at δ = 10. The price is a worse fit: 17 and 20 training
mistakes, 4 and 6 test mistakes.

**Task 2.** On data that no line separates, every Perceptron pass makes at least one mistake,
and each mistake changes θ by a full yᵢx̂ᵢ, so θ keeps jumping from pass to pass; the test
count goes 4, 6, 5, 7, 3 for T = 998 to 1002. Gradient descent with α ≤ 1/L lowers a convex
loss at every step and approaches its single minimizer, so late steps are tiny (5.7e-5 here)
and the labels settle. Stopping much earlier does matter, because θ has not settled yet:
10,000 or 20,000 steps give 4 test mistakes, 50,000 and 100,000 give 2.

**Task 3.** If inspection is cheap, use a wide band: (0.1, 0.9) sends 9 banknotes and
(0.01, 0.99) 21, and both leave no automatic mistakes on this test set. If a forgery that gets
through is very costly, the band (or the threshold) should lean toward calling banknotes
forged: lower t_low so fewer banknotes are accepted automatically; both test misses were
forgeries at P ≈ 0.3. A larger penalty shrinks θ (‖θ‖ goes from 17.1 to 3.1 at δ = 10) and
also changes its direction. Scaling θ down alone would move every probability toward 1/2,
like raising the temperature in the L9c lecture, since β and θ enter only as the product βθ.
Because the direction changes too, not every probability moves toward 1/2: the two genuine
banknotes at P = 0.463 move to 0.66 (and become false positives). Most do, though: the number
of test probabilities below 0.01 or above 0.99 falls from 254 to 76, and the band
(0.25, 0.75) holds 12 banknotes instead of 5.
