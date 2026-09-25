# Fun with Iterative Solvers — September 24, 2026

**Follow-up, September 25:** The shared solver stopping issue is now fixed and
covered by package-level regression tests; the example was rerun with both
benchmark histograms preserved. The instructor retired the L6c HTML exports.
See [the completed solver follow-up](L6c-shared-solver-stopping-review.md).
Earlier limitations and numerical outputs below describe the state at that review.

Fixed and executed [the example notebook](../../weeks/week-06/L6c/CHEME-5800-L6c-Example-FunWithIterativeSolvers-Fall-2026.ipynb). Added the standard-library `Random` import to its local setup. No solver-library implementation or other notebook was changed in this pass.

## Assessment

Initial score: **6.8/10**. Final score: **9.1/10**. These are editorial judgments about the example, not measured teaching outcomes.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 5.5 | 9.3 | The matrix now satisfies the stated assumptions; every row is checked; residual and solution difference are distinct; solve and benchmark use identical parameters. |
| Organization | 7.5 | 9.2 | Retained three tasks and the standard setup, replaced duplicate matrix displays with a small preview, and added a closing Summary. |
| Narrative and reasoning | 7.0 | 9.1 | Explained the matrix construction, actual solver behavior, and what each check establishes. Removed unsupported performance conclusions. |
| Presentation | 7.0 | 9.1 | Four displayed equations render correctly; refreshed outputs use compact numerical summaries and comparison tables. |
| Cognitive density and pacing | 7.0 | 9.0 | Focused the norm discussion on the Euclidean norm used by the computation, removed the full archive dump, and placed interpretation beside each result. |

## Corrections

- Replaced the random diagonal increment with an explicit construction: symmetric off-diagonal entries and positive diagonal entries equal to the absolute off-diagonal row sum plus a positive margin. A local seeded generator makes the experiment reproducible in the same Julia environment.
- Required all rows to pass strict diagonal dominance and separately checked symmetry and positive definiteness. These properties support the stated convergence guarantees, including relaxation factors between zero and two.
- Replaced the swallowed `any(ddcondition)` assertion with checks that halt execution if an assumption fails.
- Defined the actual equation residual and the difference from the direct solution separately. Checked finite output, the residual tolerance, the requested correction limit, and agreement with the direct solution before benchmarking.
- Defined the selected method and parameters once and reused them in the benchmark. Both calls use the same matrix and right-hand side, and each benchmark uses one evaluation per sample.
- Replaced fixed runtime and memory claims with measured median-time and allocation tables. Explained that allocation traffic is not peak memory and that the iterative implementation forms explicit inverse matrices and retains a solution history.
- Added three conceptual, retrospective takeaways and the final separator. Updated all stored outputs by executing the revised notebook.

The package documentation site was unavailable through the browser tool. Function references therefore link to the bundled solver source, which includes the existing public docstring. Benchmark usage was checked against the [official BenchmarkTools manual](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/).

## Validation

Executed all **13 code cells** with the Julia 1.12.7 Jupyter kernel and the pinned course environment. The final saved code and outputs exactly match that execution; subsequent edits only clarified prose and preview styling.

For the default 100-variable system, all 100 rows passed. The minimum diagonal margin was approximately 1.0, and symmetry and positive definiteness both passed. The default Gauss–Seidel result had residual **4.91565e-13**, below the **1e-10** tolerance, and difference from the direct solution **9.50177e-15**.

An additional **32 numerical checks passed**, covering reproducibility, matrix assumptions, a matrix with only one dominant row, all three algorithms, four relaxation factors, unchanged inputs, and an unfinished solve with a one-correction limit.

| Method | Relaxation factor | Stored corrections | Final residual norm |
| --- | ---: | ---: | ---: |
| Jacobi | ignored | 19 | 5.89037e-12 |
| Gauss–Seidel | ignored | 12 | 4.91565e-13 |
| Relaxation | 0.6 | 37 | 3.78338e-11 |
| Relaxation | 1.0 | 12 | 4.91565e-13 |
| Relaxation | 1.1 | 15 | 5.14557e-12 |
| Relaxation | 1.9 | 260 | 8.17605e-11 |

Ran the existing course checks with `RELEASE_MEETINGS='L6c L6d' julia --startup-file=no --project=. instructor/validation/week-06/runtests.jl`: **7/7 passed**. Other meetings were deliberately excluded from this scoped check.

Notebook schema, local links, three tasks, three objectives, three equation-free takeaways, section separators, and `git diff --check` passed. All four displayed equations passed both the VS Code notebook math renderer and markdown-it-texmath; the complete rendered narrative and outputs were visually reviewed.

Preview and validation artifacts are in the ignored directory `build/notebook-previews/L6c-iterative-example-review-2026-09-24/`, including `final.html`, `final-system.png`, `final-solving.png`, `final-benchmarks.png`, the original notebook, and the execution and numerical-validation scripts.

## Remaining implementation limitation

The existing course solver performs and stores one extra correction after detecting convergence or an iteration limit. The notebook now documents this behavior, checks the final stored residual, and rejects a stored correction count beyond the requested limit. The count above is therefore the number of stored corrections, not the first iteration satisfying the tolerance. Repairing the shared solver's stopping loop remains a separate library change.

The benchmark measures the current dense implementations, including inverse construction and history storage. It does not establish a general ranking of iterative algorithms or their optimized sparse implementations.

## Benchmark histogram restoration

At the instructor's request, removed the output-suppressing semicolons from both benchmark cells. Reran all 13 code cells successfully, confirmed both saved outputs contain the BenchmarkTools timing histogram, and visually verified the direct and iterative distributions above the comparison table. The refreshed benchmark preview replaces the earlier table-only preview.

## Focused formatting follow-up — September 25, 2026

The instructor identified formatting drift after a follow-up assessment had recommended no further polish. That assessment relied too heavily on the prior review and legible rendering; it did not adequately compare the opening and closing with the approved setup examples and takeaway guidance. The earlier score should not be treated as evidence that this comparison had passed.

With the instructor's approval, restored the standard compact `Include:` callout and setup introduction, restored the course-library documentation reference, added the quoted blank line before the learning-objective list, and replaced instructional takeaway labels with descriptive topic labels. The BenchmarkTools manual remains linked, and the solver source link remains in Task 2. Only Markdown cells 0, 1, 3, and 30 changed.

Compared the setup with the shared guide's CHEME 5660 L4a cumulative-probability and L4b parameter-estimation examples. Verified the restored course-library URL returned HTTP 200. Notebook schema, local links, three objectives, three tasks, three takeaways, and section separators passed. All four displayed equations passed the VS Code notebook math renderer and markdown-it-texmath. Visually inspected the revised opening and summary in Chrome. Every code cell, output, execution count, cell ID, and metadata field was preserved; numerical execution was not repeated for these Markdown-only changes.

Before/draft notebooks, rendered HTML, rendering checks, and opening/summary PNGs are in `build/notebook-previews/L6c-formatting-2026-09-25/`.
