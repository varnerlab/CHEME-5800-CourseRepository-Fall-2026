# L6d oxygen-delivery lab and derivation

Status (September 27, 2026): draft validated and saved for the instructor's manual
review later this week.

The lab replaces the three-by-three solver demonstration with steady oxygen
diffusion and first-order consumption in a square tissue slice. The derivation
starts from a local material balance, nondimensionalizes the PDE, sets accumulation
to zero, and derives the five-point linear system, including boundary terms and
an explicit four-unknown example.

## Model and conventions

- The square extends from `-L` to `L` in both directions. Its broad faces are
  sealed; concentration is uniform through the thickness. All lateral edges
  have the same prescribed oxygen concentration.
- `phi = L*sqrt(k_r/D)` uses the half-width. Its square is the diffusion time
  divided by the first-order reaction time.
- `theta = c/c_ref` uses a fixed reference across scenarios; `beta = c_s/c_ref`
  controls the boundary concentration independently of the Thiele modulus.
- The equations are multiplied by `h^2`. Diagonal entries are `4+(phi*h)^2`,
  interior-neighbor entries are `-1`, and each boundary neighbor contributes
  `beta` to the right-hand side.
- This is an illustrative first-order model, with no fitted biological parameters.
  The derivation explains the low-concentration connection to saturating uptake.
- Numerical correction counts in the concentration snapshots are solver
  iterations. The lab solves a steady boundary-value problem.

## Student work and discussion answers

Update (September 30, 2026): the one-step Jacobi update in the notebook was
replaced by a full implementation task, following the L3d and L4d pattern.
Students complete `my_jacobi(...)` in the `L6dOxygen` module in
`L6d/src/Compute.jl`: the docstring, argument checks, and archive setup ship
complete, and three TODO comments follow the five-step pseudocode of the L6c
Jacobi notebook (residual, stopping test with the strict tolerance checked
before the correction limit, diagonal correction). Until they are done, the
function throws the house "Oooops! ... not implemented yet" error.
`L6d/src/Compute-solution.jl` is the completed reference. The notebook checks
the student archive against the course package Jacobi archive key by key, then
uses the student archive for the Jacobi row of the comparison table and the
snapshot plots; Gauss–Seidel and SOR remain course-package calls.

Because students edit the module file, `Include.jl` includes `Compute.jl`
unguarded and has no `using .L6dOxygen`; the notebook calls
`L6dOxygen.build_tissue_system(...)` and friends by qualified name, so
re-running the setup cell reloads the edits without a kernel restart.

The one remaining notebook assignment is:

```julia
reduced_boundary = β / 2;
```

The validation runner executes a sibling copy of the L6d folder with the
reference source swapped in, fills the boundary answer in memory, and removes
the copy at exit, so the distributed files stay unanswered.

1. (Task 1, revised September 30) Each row has diagonal `4 + (phi*h)^2` and at
   most four off-diagonal entries of magnitude one, so the off-diagonal sum is at
   most 4. For `phi > 0` the diagonal exceeds it in every row (default grid:
   4.0625 versus 4.0), so the matrix is strictly diagonally dominant, and the
   L6c lecture says this is sufficient for Jacobi and Gauss–Seidel to converge
   from any initial guess. For `phi = 0` interior rows tie at 4 and strict
   dominance fails, although the methods still converge on this problem.
   The former Task 1 question (doubling `L` doubles `phi`, lowering center
   oxygen) duplicated the Task 3 prediction and was replaced.
2. (Task 2, revised September 30) Gauss–Seidel uses each new concentration as
   soon as it is computed, so each sweep does more work toward the solution;
   with the defaults it needs 266 corrections versus 528 for Jacobi, and SOR
   with relaxation 1.5 needs 78. All three methods agree with the same direct
   steady solution within the specified tolerance.
3. (Task 3, revised September 30) Yes: for fixed `phi` the field is linear in
   the edge concentration, so raising `beta` from 1 to about 5.68 (the ratio
   0.390557/0.068769) restores the original center value in the larger slice.
   Only the right-hand side changes; the matrix depends on `phi`, not `beta`.
   The former question (is center oxygen halved; which of A or b changed)
   repeated the cell's own prediction and was answered by the paragraph above it.

Default grid: 15 interior points per direction, 225 unknowns, spacing 0.125.
Default modulus: 2; boundary concentration: 1; absolute residual tolerance:
`1e-8`; correction limit: 2000; relaxation factor: 1.5.

| Scenario | Thiele modulus | Edge concentration | Center concentration |
|---|---:|---:|---:|
| Original tissue | 2 | 1 | 0.390557 |
| Double half-width | 4 | 1 | 0.068769 |
| Half edge supply | 2 | 0.5 | 0.195278 |

Default correction counts: Jacobi 528, Gauss–Seidel 266, SOR 78.

## Validation

From the repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-06/runtests.jl
python instructor/validation/week-06/execute_l6d_notebook.py
```

The Julia suite includes independent one-node and four-node balances, the
zero-consumption limit, zero supply, symmetry, positivity, linear supply scaling,
discrete integrated supply versus consumption, the analytical Jacobi spectral
radius, and agreement of all three course solvers with the direct solution.

Spatial accuracy is checked against the independently prescribed exact field
`cosh(ξ)*cosh(η)` with Thiele modulus `sqrt(2)` and its nonuniform boundary
values. Maximum errors on 7, 15, and 31 interior points per direction are
approximately `0.00237426`, `0.000603863`, and `0.000151628`. Halving the spacing
reduces the error by factors of approximately 3.93 and 3.98.

The Python runner requires nbformat, nbclient, nbconvert, and the Julia 1.12
Jupyter kernel. It executes the completed lab in light and dark themes and
writes executed notebooks and HTML previews to a temporary directory. It needs
local loopback sockets for the kernel. These exports are validation artifacts;
the course notebooks remain the maintained materials.

Both notebook layouts and the SVG/plot figures were inspected in rendered form.
The full Week 6 Julia suite passed 189 checks, and the completed lab ran in both
plot themes. All new local notebook links resolve.

## Code readability pass — September 27, 2026

Reviewed all L6d source functions, the local setup file, and all 14 lab code
cells. The derivation notebook has no code cells. Expanded compact input and
placeholder checks into conditional blocks, made theme selection explicit, and
named intermediate residual and comparison quantities. The replaced compact
forms remain as commented alternatives. Added comments explaining grid ordering,
boundary contributions, solver settings, archive keys, heatmap orientation, and
the center index. Each source function now documents its arguments, returned
values, dimensionless conventions, error conditions, and a usage example.

The reference module still matches the student module, and all three notebook
exercises remain unanswered. Markdown cells, outputs, execution counts, and
metadata were preserved. The full Week 6 suite again passed 189 checks. An
additional comparison against the saved pre-refactor implementation passed 108
checks across 36 parameter combinations, plus 31 input-validation and plot-theme
checks. All 14 completed lab code cells executed in both plot themes, and the
expanded code cells were inspected in the HTML export.
All four docstring examples were extracted from Julia's rendered help text and
executed successfully.
