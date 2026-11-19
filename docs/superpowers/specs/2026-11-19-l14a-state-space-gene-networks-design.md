# L14a: Linear State Space Models, Stability, and a Gene Network Builder

Date: 2026-11-19. Status: draft for Jeff's approval.

## Intent

L14a is the only instructional meeting in week 14 of CHEME 5800 (Fall 2026). Jeff wants it to
teach the solution of time-invariant linear state space models, ẋ = Ax + Bu, and stability
analysis by eigendecomposition. The meeting replaces the assistant-written power iteration
prototype (`CHEME-5800-L14a-Lecture-DominantEigenpairs-PowerIteration-Fall-2026.ipynb`).

The lecture has two parts:

1. **Open loop (u = 0).** Solve ẋ = Ax with the eigendecomposition and read stability from the
   eigenvalues. A 2-D figure shows why each eigenvalue case behaves as it does.
2. **Forced (u ≠ 0).** Write the exact solution, then approximate it with the discretization
   that S4 uses (the bilinear, or trapezoid, transform). We'll linearize a nonlinear model with
   the Taylor series to obtain A and B.

The example applies both parts to Jeff's research system: mRNA and protein balances with
Boltzmann (active-state) transcription control. Jeff chose the self-activating gene (positive
autoregulation) driven by an inducer pulse. The gene networks come from TOML config files that a
course-package builder reads at run time. The same builder will later serve a problem set in
which students estimate the control structure (the policy) from data.

## Goals

- A lecture notebook on LTI state space models: open-loop solution, eigenvalue stability, the
  forced solution, the S4 bilinear recursion, and linearization by Taylor series.
- An advanced notebook on how eigenvalues are computed (power iteration and QR iteration),
  refactored from earlier material. The lecture calls `eigen` and links to the advanced notebook.
- An example notebook that builds gene network motifs from config files, classifies their steady
  states by eigenvalue, and solves the linearized self-activating gene with the S4 recursion.
- A gene network builder in the course package (`code/src`) that reads a TOML config and returns a
  model, with one generic balance function and an `equations(model)` printer.
- Motif config files for three of Alon's motifs.

## Non-goals

- The reinforcement learning problem set. It is a separate project designed after L14a ships.
  The builder must support it (see Constraints), but no problem set files are written now.
- Code generation from the config (Jeff's past approach, option C). The `equations` printer can
  later write a `.jl` file if Jeff wants files on disk.
- BSTModelKit. It is not used and not added to the course environment.
- A slide deck for L14a. It can be added later through the separate slide workflow.
- Changes to week 15. Its scaffold plans explicit Euler and stability (L15a), a three-gene lab
  (L15b), and a state-space bridge (L15c). Those overlap with this lecture and are decided at the
  week 15 rebuild.
- Release, tagging, or pushing. Those need Jeff's explicit go-ahead.

## Anti-goals

- A lecture that reads like the 5820 deep-learning lecture. The 5800 lecture is about the
  solution and stability of LTI systems. HiPPO, LegS matrices, and readout training stay in 5820.
- Biology jargon that students without a biology background can't follow. Every term (mRNA,
  protein, transcription, translation, promoter, RNA polymerase, inducer, motif) is introduced in
  plain words before it is used.
- Package code that students can't read: no closures, `do` blocks, ternary chains, or
  `x || throw` one-liners.

## Sources to borrow from

Copy and edit these, keeping Jeff's wording where it fits:

| Source | What to take |
|---|---|
| `~/Desktop/julia_work/CHEME-5820-Instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/week-14/L14a/CHEME-5820-L14a-Lecture-StateSpaceModels-Spring-2026.ipynb` | The continuous-time LTI block, the stability paragraph, and the bilinear discretization box. Drop HiPPO, LegS, ridge readout, the RNN/Transformer table, and C and D. |
| `.../week-14/L14a/src/Compute.jl` (same 5820 folder) | `discretize(A, B; Δt, method = :bilinear)` as the starting point for the package function. |
| `.../CHEME-5820-Lectures-Spring-2026/lectures/week-2/L2a/CHEME-5820-L2a-Lecture-Eigendecomposition-Power-Spring-2026.ipynb` | The eigendecomposition section and power iteration, for the advanced notebook. |
| `.../week-2/L2c/CHEME-5820-L2c-Lecture-Eigendecomposition-QR-Spring-2026.ipynb` | QR iteration, for the advanced notebook. |
| `.../week-2/L2a/src/Eigendecomposition.jl` | `poweriteration`, to sit next to the package's existing `qriteration` in `code/src/Eigen.jl`. |
| Current 2026 L14a prototype and `weeks/week-14/src/Week14Core.jl` | The eigenpair residual check and the spectral gap demonstration, if they fit the advanced notebook. |
| `~/Desktop/papers/MRW-BTC4-Chapter-Varner/chapter/sections/gateways.tex` | The mRNA and protein balances, the active-state control (partition function), the control split, and the Lux promoter example. |
| `~/Desktop/julia_work/CHEME-5450-Lectures-Spring-2025/lectures/week-6/L6c/CHEME-5450-L6c-BoltzmannRegulationModels-S2025.ipynb` | Jeff's teaching version of the balances and the discrete-state promoter model. |
| `~/Desktop/papers/Gluconate-Sensor-Model-Paper/code/src/Model.jl` | The lab's implementation of `transcription_control`, including how an inducer changes the regulator's bound fraction. |
| Shoval and Alon, "SnapShot: Network Motifs", Cell 143 (2010), DOI 10.1016/j.cell.2010.09.050 | The motif names and their functions. Cite by DOI. Do not ship or link the PDF. |

Citations in the example: Moon et al. (2012) and Adhikari et al. (2020) for the promoter-state
control. The chapter is not published yet, so cite it as in preparation for *Comprehensive
Biotechnology*, 4th edition.

Tell Jeff which pieces were kept and why anything was dropped.

## The model (decided with Jeff)

For each gene j in a network:

```
dm_j/dt = r_X,j ū_j − (θ_m,j + μ) m_j
dp_j/dt = r_L,j w_j − (θ_p,j + μ) p_j

r_X,j = Vmax_X,j G_j / (K_X,j + G_j)     constant, set by the gene concentration G_j
r_L,j = Vmax_L,j m_j / (K_L,j + m_j)     saturates in the mRNA m_j
```

- m_j is the mRNA concentration and p_j is the protein concentration of gene j.
- θ_m,j and θ_p,j are first-order degradation constants. The builder computes each from a
  half-life, θ = ln 2 / t½. μ is the specific growth rate, computed from the doubling time.
- ū_j is the transcriptional control and w_j is the translational control. Both lie in [0, 1].

**Boltzmann (active-state) control.** Each promoter has a list of states. The empty promoter is
the reference state with weight 1. Each other state s has weight W_s · ∏_b f_b, where:

- W_s = exp(−ΔG_s) is the state's relative weight. The config gives W_s directly.
- The product runs over the regulators bound in state s. A state can bind zero, one, or several
  regulators. A state with none (for example, RNA polymerase bound alone) has weight W_s.
- f_b = x_b^n / (K_b^n + x_b^n) is the bound fraction of regulator b, with concentration x_b.
- An inducer acts through its regulator. If a bound regulator names an inducer I, its available
  concentration is x_b = p_reg · f_I, with f_I = I^n_I / (K_I^n_I + I^n_I), when the inducer
  activates the regulator (the chapter's Lux case). It is x_b = p_reg · (1 − f_I) when the inducer
  inactivates the regulator (the gluconate sensor's GntR case).

Then

```
ū_j = (sum of weights of active states) / (1 + sum of weights of all states)
```

Active states (RNA polymerase bound, alone or with an activator) count in the numerator and the
denominator. Inactive states (for example, a repressor-bound promoter) count only in the
denominator. This one rule gives activation, repression, and combinations of several regulators,
so no separate gate field is needed:

- **OR logic:** two active states, each binding one activator.
- **AND logic:** one active state that binds both activators, with weight W · f_A · f_B. This
  logic is needed for Alon's AND-gated feedforward loop in the problem set.

The leak comes from the RNA polymerase-only state, as in the chapter's control split
(λ_j = r_X,j u†_j). The balances therefore carry no separate leak constant. The example should
say this in one sentence and point to the chapter's split.

The translational control w_j uses the same rule, with the gene's translation states. When the
config lists no translation states, w_j = 1.

## The builder (option A, chosen by Jeff)

**Where it lives.** A new file in the vendored course package, `code/src/GeneNetworks.jl`,
included from `VLDataScienceMachineLearningPackage.jl`. Types go in `code/src/Types.jl` with the
package's `My*` naming (for example, `MyGeneNetworkModel` and `MyPromoterStateModel`). The factory
goes in `code/src/Factory.jl` as `build(MyGeneNetworkModel, path::String)`, the same pattern as the
other `build` methods. Lecture folders carry no `src/`, so nothing goes in `weeks/week-14/L14a`.

Motif configs live in `code/src/data/motifs/`. Any other path also works, so students and the
problem set can write their own configs.

**Functions the package provides.** Names may change. Each function is documented and written in
plain course style, with explicit loops and if-blocks:

| Function | What it does |
|---|---|
| `build(MyGeneNetworkModel, path)` | Reads the TOML file and returns the model. It checks that every regulator and inducer named in a state exists, and throws an `ArgumentError` with the config field named otherwise. |
| `transcription_control(model, j, x, t)` | Computes ū_j from gene j's promoter states. |
| `translation_control(model, j, x, t)` | Computes w_j, or returns 1 when gene j has no translation states. |
| `balances!(dx, x, model, t)` | The right-hand side above, in the signature `OrdinaryDiffEq` expects. The state vector is all mRNA, then all protein, in the order the genes appear in the config's `[[genes]]` array. |
| `equations(model)` | Prints each gene's balances and its control, with the config's numbers substituted. |
| `input_value(model, name, t)` | Looks up an inducer's value from a piecewise-constant schedule stored in the model. |
| `steady_state(model; guess)` | Newton's method from a starting guess, using `jacobian`. |
| `jacobian(model, x, t)` | The state Jacobian (the A matrix). |
| `input_jacobian(model, x, t, name)` | The derivative of the balances with respect to one inducer (the B column). |
| `discretize(A, B; Δt)` | The bilinear Ā and B̄. |
| `poweriteration(...)` | Ported from 5820 next to the existing `qriteration`, for the advanced notebook. |

Inducer schedules are data, not functions: a list of (start time, value) pairs held in the model.
This keeps the package free of closures, and it matches the piecewise-constant input that the
discretization assumes. The notebook sets a schedule with a plain function call (for example,
`set_input!(model, "I", times, values)`).

The ODE solve stays in the notebooks. They call `OrdinaryDiffEq` directly from the root
environment, the way the week 15 scaffold does. The package does not depend on `OrdinaryDiffEq`.
The course package and `OrdinaryDiffEq` both export `solve`, so notebooks write the qualified call
`OrdinaryDiffEq.solve(...)`, as the week 15 code does.

**`qriteration`.** The package's `qriteration` can return wrong or NaN eigenvectors. Its own
docstring shows this for a symmetric 3×3 matrix. The 5820 L2a/L2c copy fixes this with a
null-space step. Replace the package copy with the 5820 version when porting `poweriteration`.
Nothing else in the course calls the package copy.

**Dependencies.** `TOML` is a standard library and must be added to `code/Project.toml`, because
package imports must be declared there, not in the root project. If `jacobian` uses ForwardDiff,
ForwardDiff must also be added there. It is already in the root Manifest. See "Left to the
builder".

## Config format

TOML, one file per network. Genes are an array of tables (`[[genes]]`), because Julia's TOML
parser returns a `Dict` for named tables and loses their order. The array order sets the state
order. Each promoter state lists the regulators it binds as `[[genes.promoter.bound]]` entries. The
self-activating gene, in the form agreed with Jeff:

```toml
[metadata]
description = "Positive autoregulation: protein X activates transcription of its own gene"
reference = "Shoval and Alon, Cell 143 (2010), doi:10.1016/j.cell.2010.09.050"

[parameters]
mRNA_half_life = 2.5      # min
protein_half_life = 35.0  # min
doubling_time = 60.0      # min

[[genes]]
name = "X"
G = 0.005          # gene concentration (µM)
Vmax_X = 1.0       # transcription kinetic limit (µM/min)
K_X = 0.001        # transcription saturation constant (µM)
Vmax_L = 1.0       # translation kinetic limit (µM/min)
K_L = 0.1          # translation saturation constant (µM)

  [[genes.promoter]]          # RNA polymerase bound alone: the leak
  W = 0.01
  active = true

  [[genes.promoter]]          # RNA polymerase with protein X bound: self-activation
  W = 50.0
  active = true

    [[genes.promoter.bound]]
    regulator = "X"
    K = 1.0
    n = 2
    inducer = "I"             # inducer I sets the fraction of X that can bind
    inducer_effect = "activates"
    K_I = 1.0
    n_I = 1

[inputs.I]
initial = 1.0                 # baseline inducer concentration (µM)
```

The numbers above are placeholders. The builder sets values (see Constraints). Half-lives may be
given per gene, overriding `[parameters]`. Translation states use `[[genes.translation]]` with the
same fields.

## Lecture notebook

File: `weeks/week-14/L14a/CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb`. The
builder may change the name, but it must follow the course pattern. It replaces the prototype
lecture. Planned sections:

1. **Title block.** Three learning objectives, each exactly two plain sentences, covering: the
   open-loop solution and stability from eigenvalues; the forced solution and the S4 recursion;
   linearization about a steady state. The block ends with a link to the example.
2. **Setup.**
3. **Linear time-invariant state space models.** ẋ = Ax + Bu, what x, u, A, and B are, and what
   time-invariant means. Taken from the 5820 lecture, without C and D.
4. **The open-loop solution.** x(t) = e^{At} x₀. With A = VΛV⁻¹, x(t) = V e^{Λt} V⁻¹ x₀, which is a
   sum of modes c_i v_i e^{λ_i t}. Eigenvalues come from the `eigen` function, with a link to the
   advanced notebook for how they are computed.
5. **Stability from the eigenvalues.** A 2×2 phase portrait figure for 2-D systems:
   - both eigenvalues negative (stable node),
   - one positive eigenvalue (saddle),
   - purely imaginary eigenvalues (center),
   - complex eigenvalues with negative real part (stable spiral).

   Jeff asked for the negative, positive, and imaginary cases. The fourth panel separates purely
   imaginary from complex with a negative real part, and the builder may drop it. The text
   explains each case from the modes. A complex pair α ± iβ gives e^{αt}(cos βt + i sin βt), so α
   sets growth or decay and β sets the oscillation.
6. **The forced solution.** x(t) = e^{At} x₀ + ∫₀ᵗ e^{A(t−s)} B u(s) ds. The integral is the hard
   part.
7. **The S4 discretization.** The input is held over each step of length Δt, and the integral is
   approximated with the trapezoid rule. This gives the bilinear Ā and B̄ and the recursion
   x_k = Ā x_{k−1} + B̄ u_k. Each discrete eigenvalue is (1 + Δt λ/2)/(1 − Δt λ/2), which lies
   inside the unit circle exactly when Re λ < 0. So stability carries over from A to Ā. A short
   code cell checks the recursion against the exact matrix exponential solution for a constant
   input. Euler's method is left to week 15.
8. **Linearization.** For ẋ = f(x, u), a first-order Taylor expansion about a steady state
   (x*, u*) gives δẋ ≈ A δx + B δu, with A = ∂f/∂x and B = ∂f/∂u evaluated at the steady state. The
   lecture states this generally. The example applies it.
9. **Summary.** Three key takeaways, each exactly two plain sentences.

Figure: a static SVG in `weeks/week-14/L14a/figs/`, drawn with TikZ/pgfplots in the house recipe,
with light and dark styles (see `instructor/FIGURE-THEMES.md`). The builder may generate the
trajectory data in Julia.

## Advanced notebook

File: `weeks/week-14/L14a/CHEME-5800-L14a-Advanced-ComputingEigenvalues-Fall-2026.ipynb`.
Contents: the eigenvalue equation and the characteristic polynomial (why it is not computed
directly for large matrices), power iteration (dominant eigenpair, Rayleigh quotient, the residual
check, the spectral gap), and QR iteration for all eigenvalues of a symmetric matrix. It uses the
package's `poweriteration` and `qriteration`, and compares each result with `eigen`. It is refactored
from 5820 L2a and L2c, not written fresh. Gram–Schmidt stays in 5820.

## Example notebook

File: `weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneSwitch-Fall-2026.ipynb`. Planned flow:

1. **Gene expression in plain terms.** Introduce DNA, the gene, mRNA, protein, transcription,
   translation, the promoter, RNA polymerase, a transcription factor, and an inducer. Then
   introduce the balances and the Boltzmann control in the chapter's notation. Define each term
   before using it.
2. **Network motifs.** Name the three motifs used, citing Shoval and Alon (2010). Include a small
   TikZ schematic of the three motifs in Alon's style (arrows for activation, blunt ends for
   repression).
3. **Build from config.** Build each motif with `build(MyGeneNetworkModel, path)` and print it
   with `equations`.
4. **Eigenvalues across motifs.** A short table of steady states and their Jacobian eigenvalues:
   - negative autoregulation: both eigenvalues negative,
   - positive autoregulation, middle steady state: one positive eigenvalue,
   - two-gene negative feedback loop (X activates Y, Y represses X): a complex pair.

   Together the three motifs show the lecture's cases in biology. Steep negative autoregulation
   can also give a complex pair, once its loop gain exceeds (a − b)²/4 (about 0.017 min⁻² here).
   The negative autoregulation config uses weak repression, so its eigenvalues stay real. No
   gene model gives purely imaginary eigenvalues, because the degradation and dilution terms keep
   the Jacobian's trace negative.
5. **The self-activating gene in detail.**
   - Plot the nullclines in the (m, p) plane with the three steady states.
   - Derive the 2×2 Jacobian by hand in a markdown cell. This step shows the saturating r_L term
     w Vmax_L K_L/(K_L + m)² in ∂(dp/dt)/∂m. Then check the hand result against the package
     `jacobian`.
   - Classify the low, middle, and high steady states.
6. **Inducer pulse and the S4 recursion.** Linearize about the low steady state, with the
   inducer deviation δI as the input. In this section the state space input is δI, and ū_X
   remains the transcriptional control. Discretize with `discretize`, run the recursion, and
   compare it with the nonlinear solution from `OrdinaryDiffEq`:
   - A small pulse: the linear and nonlinear responses match.
   - A large pulse: the nonlinear gene flips to the high steady state and stays there after the
     pulse ends. The linear model returns to the low state.

   The point is where linearization works and where it fails. The middle state's saddle marks the
   threshold.
7. **Summary.** Three key takeaways.

Computed plots follow the 5660 figure recipe (`:dodgerblue3`, see-through panel, and readability
under both `theme(:default)` and `theme(:dark)`). The example ships with outputs, like other
examples.

## Week 14 files

- Delete the prototype lecture and `weeks/week-14/src/Week14Core.jl`. Nothing outside week 14 uses
  either. Remove the `Week14Core` load from `L14a/Include.jl`, which then loads only the root
  bootstrap and the imports this meeting needs (LinearAlgebra, Plots, OrdinaryDiffEq, Test).
- Update `weeks/week-14/README.md` and `weeks/week-14/release.toml`: the entry notebook becomes
  the new lecture, and the advanced and example notebooks become supporting notebooks. Keep the
  `status = "prototype"` line until Jeff approves a release.
- Rewrite `instructor/validation/week-14/runtests.jl` for the new code (see Verification).

## Constraints

**Course rules**, from `AGENTS.md`, `CLAUDE.md`, the shared notebook style guide, and Jeff's
standing feedback:

- Paragraphs have at most 3 sentences or about 60 words, with one idea per sentence.
- Exactly three learning objectives and three key takeaways, with `___` before each major `##`
  section and at the end of the Summary.
- No "the figure shows" lead-ins. No links into other weeks; refer to them in words.
- Julia functions are linked as "[the `foo(...)` function](url)". No sentence opens with a
  backticked item or an acronym. A term linked once is linked at every mention.
- A blockquote is never the last thing in a markdown cell before code. Use one markdown cell
  between code cells.
- Define every term mentioned. Introduce biology in plain terms for CHEME 5800 students.
- No equations in README files.

**Feasibility checked 2026-11-19.** With the chapter's half-lives (2.5 min mRNA, 35 min protein)
and a 60 min doubling time, a quick scan found Boltzmann-controlled self-activation with three
steady states. The parameters were W_basal ≈ 0.005, W_active ≈ 10, n = 3, K ≈ 0.5,
Vmax_X G/(K_X + G) ≈ 0.02, Vmax_L ≈ 0.05, and K_L ≈ 0.05, in µM and min. With these values the
steady states are p* ≈ 0.011, 0.073, and 0.88 µM. Their eigenvalues are (−0.29, −0.029),
(−0.36, +0.035), and (−0.29, −0.031) per minute. The builder picks the final values. They must
satisfy:

- Self-activation at the baseline inducer has three steady states: low and high stable, and middle
  a saddle.
- A small inducer pulse returns the gene to the low state, and a large pulse flips it to the high
  state.
- The negative-feedback-loop config gives a complex pair at its steady state. Using the same
  half-lives for both genes guarantees one.
- Negative autoregulation gives two negative real eigenvalues.

**Problem set support.** The builder must be able to:

- build any config, including multi-regulator promoters,
- simulate a hidden config with an inducer schedule to generate data,
- simulate a student's candidate config against that data in the same session.

No problem set files are written now.

**Platform portability.** Eigenvectors differ in sign and scale across platforms (see the SVD
basis trap). Tests and notebook checks compare eigenvalues, residuals, and projections, never
specific eigenvector entries.

## Verification

- `instructor/validation/week-14/runtests.jl` tests:
  - ū stays in [0, 1].
  - An activator raises ū and a repressor lowers it.
  - `build` rejects an unknown regulator name.
  - The self-activating config has three steady states with the expected eigenvalue signs.
  - `jacobian` matches a central-difference Jacobian.
  - The bilinear recursion matches the exact solution for a constant input as Δt shrinks.
  - The discrete eigenvalues lie inside the unit circle for a stable A.
  - `poweriteration` and `qriteration` agree with `eigen`.
- All three notebooks execute top to bottom with the repo's execution recipe (see the week 1
  notebook verification notes), and the linter runs bare.
- One batched codex review of the diff, in a read-only sandbox, before reporting to Jeff.

## Approaches considered

- **A. TOML config, interpreted by one generic balance function in the course package.** Chosen.
  Students read one function, configs are readable, motifs can be swapped in one session, and the
  problem set can compare candidate structures without reloading code.
- **B. BSTModelKit.** It is Jeff's lab package and it already builds from TOML. It was rejected
  because power-law rates don't saturate, which makes switches and gates hard to reproduce, and
  because students can't read it.
- **C. Code generation (TOML to `.jl` model files).** Jeff has used this before and likes seeing
  the files. It was rejected for now because generated files collide in one session (each defines
  `balances!`), on-the-fly includes run into Julia's world-age rule, and the generator is a large
  amount of string-building code. The `equations` printer covers the visibility, and it can later
  write files.

## Left to the builder

- Parameter values within the constraints above.
- Final notebook and function names, following the course patterns.
- Whether `jacobian` uses ForwardDiff or central differences. Central differences need no new
  dependency and no closure. ForwardDiff is exact, but it needs `balances!` to accept dual numbers
  and adds a declared dependency. The example checks the hand-derived Jacobian either way.
- The figure layout and whether the lecture's fourth phase portrait panel stays.
- The pulse sizes, the Δt, and the time horizon in the example.
- Whether the advanced notebook keeps the prototype's spectral gap demonstration.
