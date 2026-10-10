# L9a banknote Perceptron example review — October 9, 2026

**Status:** Reviewed and approved by the instructor on October 9, 2026 ("Let's mark
this example as reviewed"). Approval covers the executed notebook at SHA-256
`3831a93cd12ae9f043a8e1a8bedfb04a3bff43aeabe03c9ff4d0808dee557c9a` (uncommitted at
approval). The review is closed.

Target: [Banknote Perceptron example](../../weeks/week-09/L9a/CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb).

Companion record: [L9a lecture](L9a-linear-classification-lecture-review.md).

## Source and decisions

The example was ported on October 9 from the instructor's
`CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2025.ipynb`, in
the 2026 house form: setup, three tasks, a check block, and the Summary. It keeps
the 2025 order, the UCI banknote data, M = 0, T = 1000, the error-analysis framing,
and "This is good performance for a simple linear classifier!".

Instructor decisions, October 9:

- **Banknotes, 2025 as is.** This was decided in the lecture round.
- **Compute the four metrics.** Task 3 computes accuracy, precision, recall, and
  specificity. 2025 deferred them.
- **Copy the lecture's pseudocode verbatim.** He rejected a short recap. A
  pseudocode edit in the lecture must be repeated here, as it was for the bold
  **w** fix.
- **Re-rating follow-ups.** Fixes 1–4 below were approved. The optional trim of the
  check-block paragraph was declined.

## Corrections to 2025

- θ starts at 0. 2025 used ones, which is neither zero nor the pseudocode's "small
  random values".
- Entropy is computed from the image itself, not from the wavelet-transformed image,
  per the UCI attribute list. Wavelet transform, variance, skewness, curtosis, and
  entropy are glossed.
- The `model.mistakes # ???` cell was dropped. That field holds the threshold M, not
  a count.
- 2025 implied that the printed "number of errors" (12) was the training error. The
  package's `learn(...)` prints the last-pass count while θ is still changing. The
  notebook counts the training mistakes of the returned θ itself (40 of 1097).
- The package's `classify(...)` uses Julia's `sign`, which returns 0 at a score of
  exactly zero, where the lecture uses 1. The notebook says so at inference, and the
  check block confirms that every label is ±1. `confusion(...)` would silently drop
  a 0.

## Results with the default split

Seed 1234 gives a split of 1097 training and 275 testing banknotes. The training
data are not linearly separable, so the Perceptron uses all 1000 passes. The returned
θ misclassifies 40 training banknotes (3.6%) and 12 testing banknotes (4.4%). The
confusion matrix is [121 9; 3 142], with accuracy 0.956, precision 0.976, recall
0.931, and specificity 0.979.

Seed 1234 is the worst of seeds 1–30 (8–22 training and 1–10 testing mistakes). It
was kept rather than cherry-picked, so the prose avoids seed-specific numbers.
Weight signs and whether FN exceeds FP vary by seed, so neither is interpreted.

## Scores

| Round | Claude | Codex |
|---|---|---|
| Port as built | — | 8.8 |
| Re-rating, after its five fixes | 8.5 | 8.9 |
| After fixes 1–4 | — | 9.3 |

Codex's first-round fixes:
- explain Julia's `sign` at inference;
- describe recall and specificity as rates within each class;
- soften the "no residuals" line;
- replace a takeaway that claimed an untried seed experiment;
- add a lead-in before the metrics table.

Re-rating fixes approved by the instructor:
1. Non-separability is stated as a fact checked separately by a small linear
   program, not as an inference from reaching T. Takeaway 1 now runs from the fact to
   the behavior.
2. The learned-parameter table was cut. Codex had endorsed adding it in the first
   round, then called it an uninterpreted output on the re-rating.
3. One repeated seed sentence was cut. Takeaway 2's second sentence now states the
   concept (the boundary carries over to held-out banknotes), not reproducibility.
4. Takeaway 1's procedural sentence became the idea: the last pass's printed count
   is not the training error of the returned parameters.

## Supporting changes

- `code/src/data/data-banknote-authentication.csv` was restored from the upstream
  package copy (identical file; SHA-256 `410c43ef…`).
- `using Random` was added to `L9a/Include.jl`.
- One line each was added to `release.toml` (entry notebook) and the week README.
- `instructor/validation/week-09/runtests.jl` gained the "L9a banknote Perceptron
  example" testset (17 tests), with a `JuMP`/`GLPK` import. It checks:
  - the data size and class counts (762/610), the split, and the augmented column of
    ones;
  - that `learn(...)` matches the lecture pseudocode bit for bit;
  - that the separability LP is infeasible on the training set;
  - that every label is ±1, the confusion-matrix identities hold, and the testing and
    training mistake fractions are within 0.02.

## Verification

Strict notebook style check: 0 findings. KaTeX: 47/47 expressions. nbformat
validates. The notebook executes cleanly with kernel julia-1.12, and its own check
block passes 4/4. `RELEASE_MEETINGS=L9a` passes 17/17. After fixes 1–4, re-execution
left every retained output identical. Codex, read-only, confirmed the fixes and that
nothing else changed. Prose: 1,808 words (2025: 1,030). Most of the increase is the
metrics step, the training-mistake count and its explanation, and the feature glosses.

## Open

None.
