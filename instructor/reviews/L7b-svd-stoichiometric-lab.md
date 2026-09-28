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
| Task 3 | Does column 10 of $\mathbf{V}_0$ satisfy the bounds? | No: 270 irreversible reactions run backward, 1 reverse-only reaction runs forward (271 total). |

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
   reaction direction, capacity, and any objective. A column of $\mathbf{V}_0$ is
   an orthonormal direction with mixed signs (506 of its 1008 entries are
   negative), so it runs many irreversible reactions backward. None of the 289
   columns satisfies every bound. Flux balance analysis adds the bounds as
   constraints and an objective, and solves a linear program to select a
   feasible, optimal flux from the right nullspace.

## Facts the prose relies on (pinned in the suite)

- 738 × 1008, 4006 nonzero entries; rank 719; 19 and 289 nullity.
- 4, 223, and 534 modes for 50, 90, and 99 percent of the squared norm;
  96.47% and relative error 0.1879 at `k = 400`.
- 559 reactions with lower bound 0 (bounds are only 0 or ±1000).
- Relation 3 (column 3 of $\mathbf{U}_0$, from `QRIteration()`): its 15 largest
  weights are exactly five families, each an exactly conserved unit-weight pool:
  {`nad_c`, `nadh_c`, `nmn_c`, `rnam_c`, `ncam_c`}, {`nadp_m`, `nadph_m`},
  {`nad_m`, `nadh_m`}, {`estrone_c`, `estrones_c`},
  {`nadp_c`, `nadph_c`, `nadp_r`, `nadph_r`}. The relation has nonzero weights on
  99 metabolites. `nad_c` + `nadh_c` alone is not conserved.
- `QRIteration()` is kept because the displayed nullspace columns depend on the
  algorithm; the default divide-and-conquer SVD gives the same singular values to
  $4\times10^{-14}$ and the same rank, about four times faster.
- Densest rows: `h_c` (388 reactions), `h2o_c` (217), `atp_c` (133).
