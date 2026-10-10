# L9b XOR lab: rebuild notes and answer sheet

Rebuilt 2026-10-09 from the instructor's 2025 materials:

- CHEME 5800 Fall 2025 L9b, `CHEME-5800-L9b-Solution-XOR-Fall-2025.ipynb` (title, intro,
  backstory, objectives, constants, labeling functions, data generation, training,
  inference, confusion matrix, misses plot, summary, "Where do we go from here?").
- CHEME 5820 Spring 2026 L3d, `CHEME-5820-L3d-Lab-Solution-XOR-Spring-2026.ipynb`
  (the "should work / will not work" framing, the Rosenblatt link in the backstory).

The 2026 scaffold it replaces (`CHEME-5800-L9b-Example-XORLinearSeparability-Fall-2026.ipynb`,
four hand-coded XOR points and `Week09Core.fit_perceptron`) is gone.

## What changed from 2025, and why

- **Three tasks instead of one.** 2025 had the data in Setup and a single Task 1. The 2026
  lab follows the three 2025 learning objectives: Task 1 generates and plots the data,
  Task 2 trains and classifies, Task 3 evaluates and plots the misses.
- **Student work: `my_perceptron(...)`.** The 2025 lab was read-and-run (students uncommented
  three lines), which the Fall 2026 plan (section 5.2) says every lab must correct. Jeff then
  asked for "a healthy amount of scaffolding", because students had been spending lab time
  on the implementation. The stub in `src/Compute.jl` has the initialization, both loops, the
  counters, and the return written; students fill three blanks, each a line of the L9a
  pseudocode: the mistake test (TODO 1, replace `false`), the update (TODO 2, replace the
  right-hand side of `θ = θ`), and the stopping test (TODO 3, replace `false`). The function
  renames its `maxiter` and `mistakes` arguments `T` and `M`, so TODO 3 reads like L9a step 4
  (`number_of_mistakes ≤ M || t ≥ T`) instead of the confusing `number_of_mistakes ≤ mistakes`.
  Each TODO comment gives the L9a math, the code names for its symbols, and a syntax hint,
  but not the line itself. An unfilled
  stopping test runs every pass and reaches the final "Oooops!" throw. `src/Compute-solution.jl`
  is the reference, in the same `L9bXOR` module. The check cell does not pin any count, so a
  correct implementation still passes after the split cell is re-run alone or a constant is
  changed (checked: split re-run, ϕ = 0 and 30°, `maxiter = 10000`, 1000 training examples,
  500 points). It compares θ with the package on all three datasets, requires the half circle
  to stop early with no mistakes and the wedge and XOR to use every pass, then runs one pass
  on the wedge data to get its mistakes m₁ (228 by default) and requires thresholds m₁ and
  m₁ + 1 to stop after that pass. These catch `== 0`, `< M`, `== M`, a strict `<` mistake
  test, a wrong-sign update, and a hard-coded `t ≥ 1000` (the `maxiter = 1` call never
  returns).
  Task 2 still trains with the package `learn(...)` exactly as 2025 did,
  and the check cell requires the student's parameters to match it for all three datasets.
  The notebook check compares the parameters with `≈`, and the suite with `==`: `dot`,
  `sum(θ .* x̂)`, and `transpose(x̂)*θ` all reproduce the package bit for bit. Like L6d and L8d, the notebook ships without outputs.
- **sign(0).** The package `classify(...)` returns `sign(score)`, which is `0` at a zero score,
  and `confusion(...)` silently skips those. The classify cell now sets them to `1`, as L9a
  defines; no test point lands exactly on a learned boundary in this run.
- **All three labelings at once.** 2025 toggled one labeling function by uncommenting a
  line, so the shipped notebook showed only one case. The lab now labels the same cloud
  three ways and shows the half circle, the wedge, and XOR side by side.
- **One cloud, not two.** 2025 drew two 1,000-point clouds from the same distribution, both
  with `label = 0`, shuffled their combined rows, and then relabeled every point. One
  2,000-point draw gives the same sampling distribution, and the split shuffles the rows
  anyway. `number_of_features = 3` (really the column count of `D`) is gone.
- **Rotation angle is `ϕ`, not `θ`.** L9a uses θ for the classifier parameters.
- **Seeded.** `Random.seed!(5800)` so the prose numbers are reproducible; 2025 was unseeded.
- **Parameters start at zero** (2025: ones), matching the L9a pseudocode and Novikoff.
- **Split with `randperm`** (Jeff's own 2025 L9d-extra idiom) instead of the `Set`/`while` loop.
  The seeded data cell draws the row order (`shuffled_rows`) right after the points, and the
  split cell only slices it, so re-running the split cell alone gives the same split and the
  same numbers. Drawing it in the split cell instead (the first version) took whatever the
  global stream held at that moment. Reseeding there with 5800 would tie the split to the
  cloud's coordinates, and reseeding with any other seed would have changed every quoted number.
- **Parameter count from `size(X,2)`.** 2025 used `size(D,2)`, which was 3 only because the
  label column and the bias column happen to coincide.
- **Metrics table.** 2025 printed only "Fraction correct". The lab now computes the four L9a
  metrics, because the wedge result is the L9a rare-class trap (accuracy 0.831, recall 0.321).
- **Plot code moved to `src/Visualize.jl`** (`plot_dataset`, `plot_misses`, module
  `L9bVisualize`) and the 2025 `generatedatacloud` to `src/Utility.jl` (module `L9bUtility`),
  with docstrings and the light/dark theme keyword. `src/Compute.jl` holds only the student's
  `my_perceptron(...)` (module `L9bXOR`). Include.jl loads the two helpers once and brings them
  in with `using`, so the notebook calls them unqualified; only `L9bXOR.my_perceptron(...)`
  is qualified, so that re-running the setup cell reloads the student's edits. 2025 kept the
  plotting cells hidden ("Unhide the code block"). The boundary helper solves for whichever
  coordinate keeps the line finite, and the axes are fixed to the disk. Colors follow the L9a
  figure (orange label 1, teal label -1); 2025's navy did not read on the dark theme.
- **Dropped:** the training/test scatter plots (2025 said they "should look like the original
  dataset `D`"), the PDF confusion-matrix link into the 5820 Spring 2025 repository (L9a has
  the table), and the hypothesis link to the 5820 notes PDF (L9a has the pseudocode).
- **Kept as Jeff wrote them:** the `# features, what??` prompt, the `flag`/`if` labeling loop,
  the rotation-matrix layout, the inference paragraph, "Visualize the misses", the 2025
  summary opener, and "Where do we go from here?" ("arbitrary" boundaries softened to "curved").

## Verified numbers (seed 5800, 1200 training / 800 test points, `maxiter = 1000`)

| Pattern | Passes | Last-pass mistakes | Confusion [TP FN; FP TN] | Accuracy | Precision | Recall | Specificity |
|---|---|---|---|---|---|---|---|
| half circle | 5 | 0 | [399 1; 0 400] | 0.999 | 1.0 | 0.998 | 1.0 |
| wedge | 1000 | 234 | [62 131; 4 603] | 0.831 | 0.939 | 0.321 | 0.993 |
| XOR | 1000 | 610 | [203 207; 207 183] | 0.482 | 0.495 | 0.495 | 0.469 |

The half-circle miss is test row 492, at radius 0.29, 0.0003 from the true boundary and
0.0006 on the wrong side of the learned line; the learned line is 0.18 degrees from the true
boundary. The wedge test set is 24.1% label 1, so predicting -1 everywhere scores 0.759. The
best straight line on the wedge training data (brute force over angle and offset) reaches
about 0.87 accuracy; on XOR about 0.62. The suite pins the three confusion matrices.

## Answers to "Things to think about"

**Task 1.** The best line for the wedge cuts across the orange quarter. It must either leave
out the orange points nearest the center or take in some teal points beside the quarter. A
brute-force search finds about 87% training accuracy for the best line. Rotation
does not change separability: a rotation maps lines to lines, so a separating line before
the rotation becomes a separating line after it. The rotation only keeps the boundaries off
the axes.

**Task 2.** The half-circle data are linearly separable, so the convergence theorem
guarantees zero mistakes after finitely many updates; here it took 5 passes. The wedge and
XOR data are not separable, so every pass makes at least one mistake and only `maxiter`
stops the loop. More passes cannot remove all the training mistakes on the wedge data. The
parameters keep changing from pass to pass, so the test accuracy of the returned classifier
can improve or worsen as we change the number of passes: 0.831 after 1000 passes, 0.800
(recall 0.171) after 1001, and 0.833 (recall 0.326) after 10,000. The half circle stops after
5 passes either way.

**Task 3.** The wedge classifier makes mostly false negatives (131 FN against 4 FP): it calls
few points label 1, and those are almost all right (precision 0.939), but it misses two thirds
of the label-1 points. Accuracy is misleading because only about a quarter of the points are
label 1, so predicting -1 everywhere already scores 0.759. For XOR, the new feature is the
product `u v` of the two coordinates before the rotation, `(u, v)`. The label is 1 exactly
when `u v < 0` (ignoring points on the axes). That product is a quadratic function
of the rotated features (a combination of `x₁²`, `x₂²`, and `x₁x₂`), so adding it as a third
feature makes the labels separable by a plane in three dimensions. With `ϕ = 0`, the feature
is simply `x₁x₂`. Adding computed features like this is the idea behind feature maps, which
CHEME 5820 develops together with kernel methods.
