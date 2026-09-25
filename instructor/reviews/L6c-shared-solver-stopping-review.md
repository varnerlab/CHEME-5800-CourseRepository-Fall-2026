# L6c shared solver stopping fix — September 25, 2026

Fixed the course package's Jacobi, Gauss–Seidel, and successive over-relaxation
loops in code/src/Solvers.jl. Each loop now counts completed corrections, checks
the current residual before the correction limit, and returns immediately when
converged, capped, or stopped by the existing large-residual safeguard. No extra
correction is calculated or archived after termination. The initial guess remains
at key zero; keys thereafter count actual corrections. A zero budget is supported,
and negative budgets now raise ArgumentError. The dictionary return API, inverse-based
corrections, warning thresholds, and linear-programming solver remain intact.

Updated the public docstring to explain stopping and archive semantics, corrected
its displayed defaults/return type, and removed unused loop bookkeeping. The example's
obsolete extra-correction paragraph now explains the corrected behavior.

## Regression and execution evidence

The new package-level regression suite reproduced **24 failures out of 78 checks**
on the original implementation. After the fix, all **78/78 passed**, along with the
existing **7/7 L6c/L6d checks**, using:

```sh
RELEASE_MEETINGS='L6c L6d' julia --startup-file=no --project=. instructor/validation/week-06/runtests.jl
```

Cases cover all three algorithms: initially solved systems, zero and one-correction
budgets, success on the last allowed correction, immediate termination at the first
satisfactory residual, contiguous archive keys, preservation of the initial guess,
independent stored vectors, the large-residual safeguard, and negative budgets.
The tests are in instructor/validation/week-06/course_solver_stopping.jl and are
included by the existing week-06 validation entry point. Existing unrelated edits
to that entry point were preserved.

Executed all **13 code cells** of Fun with Iterative Solvers in a fresh Julia kernel.
The saved code is unchanged; only the stopping explanation and execution outputs
changed. The default Gauss–Seidel result has residual **7.22805e-12**, below **1e-10**,
and difference from the direct solution **1.40829e-13**. Both benchmark histograms
are saved and visually verified, along with the new result and performance tables.
Timing values are machine/run dependent and are not general solver rankings.

Notebook schema, exact saved/executed equality, cell count, unchanged code sources,
and git diff --check passed. Validation artifacts and a before-copy are under
build/notebook-previews/L6c-solver-fix-2026-09-25/.

## HTML retirement

At the instructor's request, removed the six tracked L6c HTML exports and their
week-06 README link. The README records that HTML exports are not maintained for
2026 and that the L6c notebooks have been reviewed. No other meetings' HTML files
were removed. Temporary files in the ignored preview directory serve visual QA;
no replacement course HTML exports were created.
