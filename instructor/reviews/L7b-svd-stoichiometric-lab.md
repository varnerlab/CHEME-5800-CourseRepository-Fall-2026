# L7b platelet stoichiometric-matrix SVD lab

Status (September 27, 2026): converted from the September 24 example into a live
lab in the week-6 lab format, at the instructor's request ("Lab with one TODO",
full draft first). The draft is backed up for voice-calibration round 4 in
`instructor/voice-calibration/L7b-Lab-SVD-StoichiometricMatrix/`. The earlier
example review is [L6a-svd-stoichiometric-matrix-review.md](L6a-svd-stoichiometric-matrix-review.md).

Notebook: [L7b Lab: Singular Value Decomposition of a Platelet Metabolic Network](../../weeks/week-07/L7b/CHEME-5800-L7b-Lab-SVD-StoichiometricMatrix-Fall-2026.ipynb)
(renamed from `CHEME-5800-L7b-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb`).

## What changed from the example

- Plain-language opener (platelet, metabolism, metabolites), objectives in the
  "what it is" + "We'll ..." form, lecture link, "Let's get started!".
- Task 1 shows glucose (`glc__D_c`) and hexokinase (`HEX1`) instead of `h2o_c`
  ("H2O H2O") and `PIPLC_18_0_20_4`; the original-matrix image moved here.
- Task 2 flags the notation clash with L7a (L7a writes the SVD as
  $\mathbf{A}=\mathbf{U}\mathbf{S}\mathbf{V}^{\top}$; here $\mathbf{S}$ is the
  stoichiometric matrix). The retained-spectrum condition number subsection was
  cut: nothing later used it.
- Task 3 defines both nullspaces before using them; the relation table shows 15
  rows so it ends on whole families; the flux table shows each reaction's bounds.
- Five denials of unproposed misreadings removed; the "failed trial does not
  establish infeasibility" clause became a positive link to L6a's FBA problem.
- `@assert` checks became `@testset`; tables use plain `pretty_table` text
  (`PrettyTables` added to `L7b/Include.jl`).

## Student work

One notebook assignment, in Task 2:

```julia
S_k = U[:, 1:k] * Diagonal(Σ[1:k]) * transpose(V[:, 1:k]);
```

The distributed notebook ships `S_k = nothing;` with its cell unexecuted, as in
L6b. The validation suite fills only an in-memory copy.

## Predictions and questions

| Where | Prompt | Outcome |
|---|---|---|
| Task 2 | Is the rank 738 or less? | 719. $\sigma_{719}\approx0.032$, $\sigma_{720}\approx2.9\times10^{-15}$, $\tau\approx9.45\times10^{-12}$. |
| Task 2 Your turn | `k = 10` | 62.0% retained, relative error 0.617 |
| Task 2 Your turn | `k = 360` | 95.3% retained, relative error 0.216 |
| Task 2 Your turn | `k = r` (719) | 100%, relative error $7.5\times10^{-15}$; image identical to $\mathbf{S}$ |
| Task 3 | Does $\hat{\mathbf{v}}$ (HEX1 projected onto the right nullspace) satisfy the bounds? | No: 416 irreversible reactions run backward, none exceeds an upper bound. Three already show in the 9-row table (`HEX7`, `SBTD_D2`, `SBTR`). |

1. **Task 1.** Each reaction converts a few reactants into a few products, so a
   column has only a few nonzero entries (4006 nonzeros over 1008 columns, about
   four per column). A reaction with a single metabolite moves that metabolite
   into or out of the model. The 121 single-entry columns are exchange (`EX_`),
   sink (`SK_`), and demand (`DM_`) reactions, like the exchange reactions in the
   L6a urea-cycle example and the L6b *E. coli* model (`EX_glc__D_e`).
2. **Task 2.** The image looks like $\mathbf{S}$ well before the error reaches
   zero, because the gray band hides small values (error 0.059 at `k = 600`). At
   `k = r` every nonzero singular value is included, so $\mathbf{S}_r=\mathbf{S}$
   up to rounding. Modes beyond $r$ have singular values below $\tau$ (about
   $10^{-15}$), so adding them changes the approximation only at rounding level:
   `k = 738` differs from `k = r` by $1.3\times10^{-14}$ in Frobenius norm. `k`
   cannot exceed 738, the number of singular values.
3. **Task 3.** The SVD uses only the stoichiometric coefficients; it ignores
   reaction direction, capacity, and any objective. The trial flux
   $\hat{\mathbf{v}}$ spreads over 1005 of the 1008 reactions with mixed signs,
   so it runs many irreversible reactions backward. Flux balance analysis adds the bounds as
   constraints and an objective, and solves a linear program to select a
   feasible, optimal flux from the right nullspace.

## Facts the prose relies on (pinned in the suite)

- 738 × 1008, 4006 nonzero entries; rank 719; 19 and 289 nullity.
- 4, 223, and 534 modes for 50, 90, and 99 percent of the squared norm;
  96.47% and relative error 0.1879 at `k = 400`.
- 559 reactions with lower bound 0 (bounds are only 0 or ±1000).
- The NAD⁺ relation $\mathbf{w}_i=\mathbf{U}_0\mathbf{U}_0^{\top}\mathbf{e}_i$ for
  `nad_c` has exactly five nonzero weights, each 0.2: {`nad_c`, `nadh_c`, `nmn_c`,
  `rnam_c`, `ncam_c`}, an exactly conserved unit-weight pool. `nad_c` + `nadh_c`
  alone is not conserved.
- The trial flux $\hat{\mathbf{v}}=\mathbf{V}_0\mathbf{V}_0^{\top}\mathbf{e}_j$ for
  `HEX1`: $\hat{v}_j\approx0.4964$, 416 lower-bound violations (all on
  irreversible reactions), none above an upper bound. Rows 9 and 10 of its
  sorted entries differ (0.0676 vs 0.0663), so the 9-row table has no tie at its
  edge; rows 10-13 are a four-way tie, which is why it is not 12 rows.
- **Why projections (October 5, 2026).** The week-07.1 and week-07.2 Actions
  failed because the suite pinned column 3 of $\mathbf{U}_0$ and column 10 of
  $\mathbf{V}_0$. Any rotation of a nullspace basis is another valid basis, and
  rounding-level changes (Linux BLAS, or just scaling $\mathbf{S}$ by
  $1+10^{-15}$) changed both columns: column 10 went from 271 to 273
  violations, and the relation table lost every named family. The projections
  matched across row and column permutations and rescaling. Roundoff numbers in
  the prose are worded loosely for the same reason ($\sigma_{720}$ ranged
  2.9e-15 to 5.5e-15, the largest entry of $\mathbf{S}\mathbf{V}_0$ 3e-15 to 6e-14).
- `QRIteration()` is kept (slower but more accurate); the default
  divide-and-conquer SVD gives the same singular values to $4\times10^{-14}$ and
  the same rank, about four times faster.
- Densest rows: `h_c` (388 reactions), `h2o_c` (217), `atp_c` (133).
