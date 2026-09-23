# Week 6 redesign: flux balance analysis replaces duality

Approved by Jeff on 2026-09-23. L6a meets Mon. Sep. 28 and L6b Tue. Sep. 29.
Students need to see linear programming applied, so the week-6 duality lecture is
dropped (L5c already introduces duality) and replaced by flux balance analysis.
L6c and L6d (stationary iterative methods) are unchanged.

## L6a: flux balance analysis lecture and HL-60 example

Adapted from the CHEME 5430 Spring 2026 lecture
([Lecture-5430-FluxBalanceAnalysis](https://github.com/varnerlab/Lecture-5430-FluxBalanceAnalysis)),
in 2026 CHEME 5800 notation and style.

- Lecture `CHEME-5800-L6a-Lecture-FluxBalanceAnalysis-Fall-2026.ipynb` (conceptual,
  no code): metabolic networks and the stoichiometric matrix S, with the link to
  L5c's incidence matrix; steady state S v = 0 from species mole balances, with
  exchange reactions in the role of L5c's source and sink; the FBA linear program;
  the general and simplified flux-bounds models; an example callout.
- Example `CHEME-5800-L6a-Example-UreaCycle-FluxBalance-Fall-2026.ipynb`: the HL-60
  urea cycle from `Network.net` (moved from the old L6b). Three tasks: build S;
  set bounds from the documented eQuilibrator reversibility and BRENDA kcat values
  (simplified model, e° = 0.01); maximize urea export, check S v = 0 and the
  bounds, and find the rate-limiting step.
- Code in the course package, `code/src/FluxBalance.jl` (lecture folders carry no
  `src/`): read a reaction file, build S, solve an FBA linear program, and check a
  flux vector.

Optional later: the 5430 steady-state derivation and SVD examples.

## L6b: overflow metabolism in E. coli (live lab)

The core cancer model was tried first. With the HL-60 biomass it cannot grow
(glycogen and nine lipids have no production route), and with those removed it
shows no lactate overflow under plain FBA; a reliable Warburg demo needs a
curation pass. Jeff chose the BiGG E. coli core model instead.

- Lab `CHEME-5800-L6b-Lab-OverflowMetabolism-Fall-2026.ipynb`, live walkthrough in
  the L5d format (lean text; predict, run, discuss; flow diagrams; parameter
  changes in the questions). Code complete in `src/Compute.jl`, with
  `src/Compute-solution.jl` identical apart from its header.
- Data: `e_coli_core.json` from BiGG Models (Orth et al. 2010; King et al. 2016),
  committed with a README.
- Task 1: load the model and build S. Task 2: maximize growth on glucose with
  oxygen available (growth 0.874 1/h, no overflow) and check the solution.
  Task 3: live changes (cap oxygen uptake: acetate appears; anaerobic: acetate,
  ethanol, formate), with questions that raise glucose under an oxygen cap, block
  acetate secretion, and change ATP maintenance.
- Figure: a cell-boundary flow diagram: nutrients on the left, products on the
  right, biomass leaving at the bottom; arrows point the way material moves, width
  scaled to flux, values labeled.

## Other files

`weeks/week-06/README.md`, `weeks/week-06/release.toml`,
`instructor/validation/week-06/runtests.jl`; `weeks/week-06/src/Week06Core.jl`
keeps only the L6c/L6d functions. The old duality notebook and urea-cycle lab
are removed. L5d's closing sentence already points to flux balance analysis.

## Verification

Week-6 suite, notebook execution, rendering in light and dark themes,
`notebook_style_check.py --strict`, and one codex read-only pass.

## Discussion answers (instructor only)

Numbers from GLPK through the notebook code; rates in µmol/gDW/s for the urea
cycle and mmol/gDW/h (growth 1/h) for *E. coli*.

### L6a example: urea cycle

**Task 1.**
- *Which columns of S have one −1 and one +1?* None. The enzyme reactions touch
  3 to 8 species (v2 has 3 entries, v5 has 8, with coefficients up to 4), and each
  exchange has a single entry. The lecture's toy r₁ and r₃ are the flow-network case;
  real metabolism is not.
- *Why does an exchange column have one entry?* It moves one species across the
  boundary. The other side is the surroundings, which is not balanced, so it has
  no row in S.

**Task 2.**
- *v5 bounds, and why free energy wins:* δ = 0, so 0 ≤ v5 ≤ 0.1. A reaction with
  ΔG ≈ −1220 kJ/mol cannot run backward at any physiological concentrations; the
  file's `true` is an annotation, not a measurement.
- *A wrong default kcat:* the defaults are v1 and v5. v5 carries no flux, so its
  value does not matter (kcat 1000 still gives 0.0328). If v1's true kcat were
  below 3.28, v1 would limit instead: kcat = 2 gives export 0.02. Above 3.28,
  nothing changes. Export is the smallest Vmax among v1–v4.

**Task 3.**
- *Lyase kcat doubled:* Vmax₂ = 0.0656, still below v1's 0.1, so export doubles
  to 0.0656 and v2 still limits.
- *Nonzero oxygen consumption:* only v5 uses oxygen, so v5 = O₂/4 must carry flux.
  The arginine balance gives urea = v2 − 2 v5, so export falls by half the oxygen
  rate: O₂ = 0.02 gives urea 0.0228; above about 0.066 the problem is infeasible
  (v5 would need more arginine than v2 can supply).
- Not asked, if it comes up: e° × 10 multiplies export by ten (0.328) and leaves
  v2 as the limit.

### L6b lab: overflow metabolism

Baseline: growth 0.874, glucose 10, O₂ 21.8, secretes CO₂ 22.81 (plus water and
protons), no acetate.

**Task 1.**
- *Glucose lower bound negative, acetate zero:* uptake is a negative flux. Glucose
  is in the medium (up to 10); acetate is not, so it can only leave.
- *Sealed flask:* set the oxygen exchange lower bound to 0,
  `with_uptake_limit(model, "EX_o2_e", 0.0)`.

**Task 2.**
- *No acetate with plenty of oxygen:* glucose is the only limit, and respiration
  makes far more ATP per glucose than making acetate, so the best solution burns
  every glucose. Plain FBA charges nothing for respiratory capacity, so it never
  overflows while oxygen is free.
- *Cap oxygen below 21.8:* growth falls and acetate appears (next cell: O₂ ≤ 15
  gives growth 0.718, acetate 6.81).

**Task 3 questions.**
- *O₂ ≤ 15, glucose 20:* growth 1.047 (up from 0.718); acetate 24.09 and formate
  22.13; CO₂ drops to 5.14. The extra glucose is mostly overflow. For contrast,
  glucose 20 with free oxygen grows at 1.791 with no overflow. Threshold: at
  O₂ ≤ 15, acetate appears above glucose ≈ 6.59 (6.5 gives none; 7.0 gives 0.82).
- *O₂ ≤ 15, acetate blocked:* the cell switches to ethanol (5.33) and growth falls
  to 0.663 from 0.718. Blocking one overflow route reroutes carbon, at a cost.
- *ATPM 20:* with free oxygen, growth 0.815 (from 0.874), O₂ 24.38, still no
  acetate. With O₂ ≤ 15, growth 0.596 and acetate 9.48 (from 6.81). Yes, it
  overflows sooner: the glucose threshold drops from 6.59 to 5.29, because more
  ATP must come from the same capped respiration.
- Not asked: ATPM 500 is infeasible, which draws the gray cell with the status.

### Codex review, 2026-09-23

One read-only pass; ten findings applied (r₃ incidence claim, "fixed at 8.39",
net-coefficient definition, active-bound wording, urea-model scope, ΔG rule of
thumb, figure title for non-optimal status, infinite-bound checks, EC typo, JSON
link). Declined: guarding every urea-example cell against an infeasible solve; no
question asks students to run an infeasible case.

