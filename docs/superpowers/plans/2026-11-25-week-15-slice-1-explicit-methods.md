# Week 15 Slice 1 (Package, L15a, L15b) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first half of week 15: package reference methods for explicit Euler and RK4, the
memory-circuit config, a `balances!` that accepts dual numbers, the L15a lecture and example, and the
L15b lab, with their validation suite and release files.

**Architecture:** The reference methods join the course package as algorithm tags plus two
functions, `advance` (one step) and `integrate` (a fixed-step loop), and take the same
`f!(dx, x, p, t)` right-hand side as `ODEProblem`, so the package `balances!` runs in both. The L15a
example calls these package methods; the L15b lab has students write their own versions in
`src/Compute.jl` and check them against the package, the L6d `my_jacobi` pattern. A new week-15 suite
tests the package additions and runs every notebook's cells.

**Tech Stack:** Julia 1.12, the vendored course package `code/src`, OrdinaryDiffEq 7.6 (Tsit5,
Rodas5P, FBDF, default solver), Plots, Jupyter notebooks (nbformat 4.5, every cell with an `id`).

**Spec:** `docs/superpowers/specs/2026-11-25-week-15-ode-solvers-design.md` (approved by Jeff
2026-11-25). Read §3, §5, and §6 before any notebook task.

## Handoff for Claude

**Resume at the [L15a review checkpoint](#task-4-l15a-example-explicit-methods-on-the-two-circuits).**
Codex picked up after Claude implemented the package work in Tasks 1 and 2.
Codex completed the two L15a notebooks and showed them to Jeff for review.

Apply any L15a feedback, then start [Task 5, the L15b lab](#task-5-l15b-lab-write-explicit-euler-and-rk4),
once Jeff approves or asks to continue. All work is in the working tree on `main`.

### What Codex changed

- **Package validation.** Verified the inherited fixed-step methods, dual-number support in
  `balances!`, and the byte-for-byte PS6 copy of `code/src/data/motifs/memory.toml`. Hardened
  `integrate` against nonfinite times or steps and intervals that would round to zero steps.
  Its docstring now explains why RK4 can sample a right-continuous input jump even if the jump
  is on a grid boundary.
- **L15a lecture.** Replaced the August placeholder with the
  [theory lecture](../../../weeks/week-15/L15a/CHEME-5800-L15a-Lecture-InitialValueProblems-Fall-2026.ipynb).
  It follows the L14a callout and Examples layout, adapts the CHEME 5820 Euler eigenvalue map
  without copying the topic prose, and cites Hairer, Nørsett, and Wanner for RK4 and stability.
  It has four level-two sections and zero code cells.
- **L15a example.** Wrote and executed the
  [worked example](../../../weeks/week-15/L15a/CHEME-5800-L15a-Example-ExplicitMethods-Fall-2026.ipynb),
  replaced the local `Include.jl`, and copied both circuit configs from the package. The example
  has 20 cells and about 1,020 Markdown words. Its three saved figures have alt text and were
  inspected in both themes.
- **Validation and week files.** Wired the
  [Week 15 suite](../../../instructor/validation/week-15/runtests.jl) through the real L15a
  `Include.jl` and added the notebook cell runner and settings overrides. Updated the Week 15
  README and manifest to point to the new L15a files. The manifest is at `prototype` with
  L15a as the bundle scope.

### Details worth carrying into L15b

- The pulse comparison steps through both jumps and supplies their times as `tstops` to
  `Tsit5`. The order study restarts from the reference state at the end of the pulse and holds the
  input at baseline. It uses that smooth interval to measure first- and fourth-order convergence.
- The stability experiment uses the smallest Euler bound over the decaying modes. The slow
  oscillatory pair sets the limit in the supplied negative feedback loop. Increasing each
  regulator's binding order by one changes the model itself and produces sustained oscillations
  in the library solution.
- After that config edit, Newton's method can fail from the zero state. The example retries
  from the equilibrium of the original packaged motif. When the edited model has a nondecaying
  mode, the stability figure displays the library trajectory.
- For L15b, follow the L6d reload pattern and call `L15bMethods` functions qualified.
  Keep the lab output-free and use the Task 5 checks for the starter, solution, and edited settings.
  Leave the remaining placeholder cleanup for Task 6.

### Verification at handoff

- Week 15 passed **91 checks** (27 fixed-step, 16 memory and dual-number, 48 L15a). The example
  suite covers off-grid settings, altered settings, rendering with an oversized step, and the
  binding-order exercise. The notebook was in place before the L15a suite was added, so the
  planned failure against a missing notebook was skipped.
- Week 14 passed **358 checks**. Claude's Task 2 report also records an earlier L14a execution
  with zero differences in text and table outputs.
- Both L15a notebooks passed both style checkers. The example ran in Julia 1.12 Jupyter from its
  meeting folder with `--project=@.`. The bundle scope command selected L15a. A local bundle
  build requires the manifest to be marked ready or released.

Re-run the following from the repository root after changes.

```bash
julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl
RELEASE_MEETINGS=L15a julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl
julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl
python3 .claude/skills/notebook-style/audit.py weeks/week-15/L15a/*.ipynb
python3 instructor/validation/notebook_style_check.py --strict weeks/week-15/L15a/*.ipynb
python3 scripts/build_week.py 15 --allow-dirty --force --scope-only
```

## Global Constraints

- No commit, push, or tag unless Jeff asks. Leave work in the working tree.
- Lectures: zero code cells, no Setup, at most six `##` sections counting Examples and Summary.
- Prose: at most three sentences or about 60 words per paragraph; one idea per sentence.
- Learning objectives and key takeaways: exactly three bullets, two plain sentences each.
- No run values, setting values, or code constants in markdown or comments.
- One settings cell holds every input students change; its comment says what each input does and where any baseline lives.
- Every code statement and loop header has an in-line comment; loop ranges and check values are named or derived.
- Plain course-style Julia in package and student code: documented top-level functions, explicit loops and if-blocks; no closures, `do` blocks, ternary chains, or `x || throw` one-liners.
- Tests and notebook checks derive expectations from settings, configs, and the package. No hardcoded values.
- Notation from L14a: x, u, f, A, λ; the time step is `Δt`, never `h`. Inside the cell nmol/gDW, the medium µM, time min.
- No cross-week links; refer to L14a and PS6 in words. Do not name S4 or Mamba.
- Write the gene model in Jeff's form, as the L14a example does (`present-models-in-instructor-form`).
- `OrdinaryDiffEq.solve(...)` is always called qualified, because the course package exports `solve`.
- Run notebook cells from the notebook's own folder with `--project=@.` (memory `week-01-notebook-verification`).
- Each notebook passes `python3 .claude/skills/notebook-style/audit.py` and `python3 instructor/validation/notebook_style_check.py --strict` with 0 findings.
- One batched codex review per meeting in a read-only sandbox (memory `codex-review-use-read-only-sandbox`), before Jeff sees it.

## Review Focus

1. **Off-grid inputs:** a student sets `Δt` so the grid does not end at `final_time`, or a pulse edge falls between grid points. Expect a clear `ArgumentError` from `integrate`, and a clear assertion message in the example's settings check, never a silently shifted run. (Tests in Task 1 and Task 4.)
2. **RK4 across an input jump:** an RK4 stage that lands on or past a pulse edge sees the new input and drops RK4 to first order near the jump. The order study must run on an interval with no input change. (Test in Task 4.)
3. **Name clashes in a notebook session:** `advance`, `integrate`, `ExplicitEulerMethod`, and `RungeKutta4Method` must resolve to the course package after the L15a and L15b `Include.jl` load OrdinaryDiffEq, Plots, and SteadyStateDiffEq. (Test in Task 1.)
4. **Large steps invited by Things to Try:** Euler above a circuit's step limit can produce negative or infinite levels. The notebook must finish and its figures must draw. (Test in Task 4.)
5. **Edit, save, re-run in the lab:** re-including `src/Compute.jl` replaces the module; qualified calls must keep working, and checks must pass for any `Δt` a student tries. (Test in Task 5.)

---

### Task 1: Package reference methods for explicit Euler and RK4

**Files:**
- Modify: `code/src/Types.jl` (new abstract type and two tags, beside `AbstractLinearSolverAlgorithm` and `JacobiMethod`)
- Create: `code/src/FixedStepMethods.jl`
- Modify: `code/src/VLDataScienceMachineLearningPackage.jl` (include after `GeneNetworks.jl`; exports in the gene-network block, commented like their neighbors)
- Replace: `instructor/validation/week-15/runtests.jl` (new suite; this task writes its first testset)

**Interfaces:**
- Produces:
  - `abstract type AbstractFixedStepAlgorithm end`
  - `struct ExplicitEulerMethod <: AbstractFixedStepAlgorithm end`
  - `struct RungeKutta4Method <: AbstractFixedStepAlgorithm end`
  - `advance(f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64; algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod())::Vector{Float64}`: one step; does not change `x`.
  - `integrate(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64, algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod())::NamedTuple` returning `(t::Vector{Float64}, x::Matrix{Float64}, evaluations::Int64)`. Row `k` of `x` is the state at `t[k]`; `t[k] = t_start + (k − 1)Δt` (computed, not accumulated); `evaluations` counts calls of `f!`.
  - Docstrings in the package standard. The `integrate` docstring says that an input jump inside a step lowers the order of RK4.

- [x] **Step 1: Write the failing tests** in a `@testset "fixed-step reference methods"` of the new suite. The suite header copies the week-14 pattern (`WEEK_ROOT`, `release_scope.jl`, `released("L15a") && include(...L15a/Include.jl)`). Use the test equation as a one-state system, `decay!(dx, x, p, t)` with `dx[1] = p * x[1]`, defined in the suite:

```julia
λ = -0.3; Δt = 0.5; z = λ * Δt
@test advance(decay!, [1.0], λ, 0.0, Δt; algorithm = ExplicitEulerMethod())[1] ≈ 1 + z
@test advance(decay!, [1.0], λ, 0.0, Δt; algorithm = RungeKutta4Method())[1] ≈ 1 + z + z^2/2 + z^3/6 + z^4/24
x = [1.0]; advance(decay!, x, λ, 0.0, Δt); @test x == [1.0]             # x is not changed
run = integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 10.0, Δt = Δt, algorithm = RungeKutta4Method())
@test length(run.t) == 21 && run.t[end] == 10.0 && size(run.x) == (21, 1)
@test run.evaluations == 4 * 20
# measured order from step halving: log2(e(Δt)/e(Δt/2)) near 1 and 4
for (alg, order) in ((ExplicitEulerMethod(), 1), (RungeKutta4Method(), 4))
    e1 = abs(integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 10.0, Δt = 0.5, algorithm = alg).x[end, 1] - exp(10λ))
    e2 = abs(integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 10.0, Δt = 0.25, algorithm = alg).x[end, 1] - exp(10λ))
    @test abs(log2(e1 / e2) - order) < 0.15
end
# Euler above its limit 2/|λ| grows; below it decays
@test abs(integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 100.0, Δt = 2.5 / abs(λ)).x[end, 1]) > 1
@test abs(integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 100.0, Δt = 1.5 / abs(λ)).x[end, 1]) < 1
@test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 10.0, Δt = 0.3)   # 10/0.3 is not whole
@test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = 0.0, t_final = 10.0, Δt = 0.0)
@test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = 5.0, t_final = 5.0, Δt = 0.5)
# names resolve to the course package in a notebook session (L15a Include.jl loads OrdinaryDiffEq and Plots)
for name in (:advance, :integrate, :ExplicitEulerMethod, :RungeKutta4Method)
    @test parentmodule(getfield(Main, name)) === VLDataScienceMachineLearningPackage
end
```

Also one test on a gene circuit: `integrate(balances!, x₀, model; ...)` with RK4 at a small `Δt` on `motif_path("negative-feedback-loop")` matches an `OrdinaryDiffEq.solve(..., Tsit5(); reltol = 1e-10, abstol = 1e-12)` reference at `t_final` to a relative error below `1e-6`, from the zero state.

- [x] **Step 2: Run the suite and see the new testset fail**

Run: `julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl`
Expected: FAIL with `UndefVarError: advance` (the L15a `Include.jl` is written in Task 4; until then, include the root `Include.jl` plus `using OrdinaryDiffEq, Plots` at the top of the testset, and switch to the L15a include in Task 4).

- [x] **Step 3: Implement the tags in `Types.jl` and `advance` and `integrate` in `FixedStepMethods.jl`**

`advance` dispatches on the tag: Euler `x + Δt k₁`; RK4 the four classical slopes at `t`, `t + Δt/2`, `t + Δt/2`, `t + Δt`. `integrate` checks its arguments (`Δt > 0`, `t_final > t_start`, `(t_final − t_start)/Δt` within `1e-9` of a whole number) with explicit if-blocks, allocates the matrix, and loops `advance`. One scratch `dx` per stage is fine.

- [x] **Step 4: Run the suite; the testset passes**

Run: `julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl`
Expected: PASS for "fixed-step reference methods".

- [x] **Step 5: Run the week-14 suite; nothing changed there**

Run: `julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl`
Expected: every test passes (358 at release week-14.3).

### Task 2: Memory-circuit config and a `balances!` that accepts dual numbers

**Files:**
- Create: `code/src/data/motifs/memory.toml` (byte-for-byte copy of `~/Desktop/julia_work/PS6-CHEME-4880-5800-Fall-2026/data/memory.toml`)
- Modify: `code/src/GeneNetworks.jl` (`input_value`, `bound_fraction`, `control`, `transcription_control`, `translation_control`, `translation_rate`, `balances!`)
- Test: `instructor/validation/week-15/runtests.jl`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `motif_path("memory")`; `balances!` callable with `ForwardDiff.Dual` entries in `x` and in `t` (Rosenbrock methods differentiate in `t`). Return annotations `::Float64` on the listed functions become `::Real` or are removed; `t::Float64` arguments become `t::Real`; `balances!` drops `Float64(t)`.

- [x] **Step 1: Write the failing tests** in `@testset "memory config and generic balances!"`:
  - `read(motif_path("memory")) == read(PS6 path)` is not testable on a student machine, so test instead that `build(MyGeneNetworkModel, motif_path("memory"))` has three genes named X, Y, Z and one inducer `I` with `initial == 0.0` read from the parsed TOML.
  - For `motif_path("negative-feedback-loop")` over `(0.0, 3000.0)` from the zero state: `OrdinaryDiffEq.solve(prob, Rodas5P())`, `FBDF()`, and `OrdinaryDiffEq.solve(prob)` (the default solver) return `Success`, and each final state matches the same solver with `autodiff = OrdinaryDiffEq.AutoFiniteDiff()` to `rtol = 1e-5`.
  - The same check with an inducer pulse set by `set_input!` (a schedule with two times), so a Dual `t` crosses a jump.

- [x] **Step 2: Run the suite; the Rodas5P/FBDF/default calls fail** with a `MethodError` or `InexactError` involving `ForwardDiff.Dual`.

- [x] **Step 3: Generalize the number types in the listed functions.** Keep every formula and comment; only the annotations and the `Float64(t)` conversion change. Update the docstring signatures to match.

- [x] **Step 4: Run the week-15 suite; both testsets pass.**

- [x] **Step 5: Prove L14a unchanged.** Run the week-14 suite (all pass), and re-execute the L14a example and compare every text output and every table with the committed notebook. Expected: identical (SVGs may differ only in clip ids).

### Task 3: L15a lecture (theory only)

**Files:**
- Create: `weeks/week-15/L15a/CHEME-5800-L15a-Lecture-InitialValueProblems-Fall-2026.ipynb`, title "L15a: Initial Value Problems and Explicit Methods"
- Delete: `weeks/week-15/L15a/CHEME-5800-L15a-Lecture-DynamicsAsAlgorithms-Fall-2026.ipynb`

**Interfaces:**
- Consumes: the example's file name from Task 4, for the Examples cell.

- [x] **Step 1: Mine the sources.** Read the L14a lecture (voice, box style, braces, the Examples cell) and the Euler text in `~/Desktop/julia_work/CHEME-5820-Instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/week-14/L14a/`. Reuse Jeff's sentences where they fit; record what was reused.
- [x] **Step 2: Write the notebook** with Jeff's structure (2026-11-25: "Intro, Summary, Euler and RK"):
  - **Intro:** the title block, which states the initial value problem (ẋ = f(x, u), x(t₀) = x₀), the time grid, and the one-step update, and says that we write simple methods by hand to understand them and use DifferentialEquations.jl in practice. Then the house `## Examples` cell linking the example.
  - **`## Explicit Euler`:** the derivation, local and global error, the order of a method, and `### Stability` (the test equation, the amplification factor, Δt < 2/|λ| for real λ and |1 + Δtλ| < 1 for complex λ, the fastest Jacobian eigenvalue sets the limit, and Euler adds amplitude to an oscillation at every step).
  - **`## Runge–Kutta Methods`:** Heun's method, classical RK4 (the four slopes, in braces), order four, cost in f evaluations, and RK4's larger stability region in one short paragraph.
  - **`## Summary`.**
  - The title block closes with "Let's get started!". The trace argument belongs to L15c, not here. Cite one standard numerical-methods text for the RK4 and stability results, verified by DOI.
- [x] **Step 3: Check the structure.** Count code cells (must be 0) and `##` headings (must be 4: Examples, Explicit Euler, Runge–Kutta Methods, Summary). Run both style checkers on the file. Expected: 0 code cells, 4 sections, 0 findings.
- [x] **Step 4: Check prose density.** Every paragraph at most three sentences or about 60 words; fix by splitting, not compressing.

### Task 4: L15a example: explicit methods on the two circuits

**Files:**
- Create: `weeks/week-15/L15a/CHEME-5800-L15a-Example-ExplicitMethods-Fall-2026.ipynb`, title "Example: Explicit Methods on Gene Circuits"
- Replace: `weeks/week-15/L15a/Include.jl` (the placeholder; copy the L14a layout; imports `LinearAlgebra`, `Test`, `OrdinaryDiffEq`, `Plots`; `import SteadyStateDiffEq` plus `using SteadyStateDiffEq: SteadyStateProblem, DynamicSS` and `PrettyTables` only if the notebook uses them)
- Create: `weeks/week-15/L15a/config/memory.toml` and `weeks/week-15/L15a/config/negative-feedback-loop.toml` (byte copies of the package motifs)
- Test: `instructor/validation/week-15/runtests.jl`

**Interfaces:**
- Consumes: `advance`, `integrate`, `ExplicitEulerMethod`, `RungeKutta4Method` (Task 1); `motif_path("memory")` and generic `balances!` (Task 2); package `build`, `set_input!`, `steady_state`, `jacobian`.
- Produces (cell ids the suite reads): `settings`, `build-model`, `reference-run`, `fixed-step-runs`, `order-study`, `eigenvalues`, `stability-runs`, `things-to-try`. Settings names: `circuit` (`"memory"` or `"negative-feedback-loop"`), `Δt`, `final_time`, `pulse_level`, `pulse_start`, `pulse_length`, `stability_factors`, `stability_final_time`. Globals the suite reads: `reference` (the `Tsit5` solution), `reltol` and `abstol` (its tolerances), `runs::Dict{String, NamedTuple}` (keys `"Euler"` and `"RK4"`, values from `integrate`), `step_sizes::Vector{Float64}` (derived from `Δt`), `errors::Dict{String, Vector{Float64}}` and `measured_orders::Dict{String, Vector{Float64}}` (same keys), `λ_by_circuit::Dict{String, Vector{ComplexF64}}`, `Δt_limit::Float64` (the negative feedback loop's Euler limit), `stability_runs::Dict{Float64, NamedTuple}` (keyed by each factor in `stability_factors`).

- [x] **Step 1: Add the L15a suite tests** in `@meeting "L15a" begin @testset "L15a example" ... end end`, with a `run_example` helper copied from the week-14 suite (cell runner with `REPL.softscope`, settings replacements, `nbvar` for world age). Tests, all derived:
  - Each file in `L15a/config/` is byte-identical to its package motif (`read(path) == read(motif_path(name))`).
  - The settings check rejects an off-grid pulse edge: a run with `pulse_start` set to `Δt / 3` throws with a message naming the setting.
  - The reference run uses solver stops at both pulse edges, and its final time equals `final_time`.
  - Each fixed-step run's grid ends at `final_time`, and `evaluations` equals steps × stages.
  - The order study's interval contains no input change (its start is at or after `pulse_start + pulse_length`), and `measured_orders` are within 0.15 of 1 (Euler) and 0.3 of 4 (RK4). Every RK4 error exceeds 100 × the reference `reltol`.
  - `Δt_limit` equals the minimum over modes of `−2 Re λ / |λ|²` from `eigvals(jacobian(model, x⋆, t))` at the negative feedback loop's steady state, recomputed in the test.
  - The Euler run below the limit settles (its last-quarter range of protein Y is under 1% of its mean); the run above the limit does not (range over 10%). Factors come from `stability_factors`.
  - A settings copy that changes every setting (other circuit, `Δt / 2`, other pulse, other factors) runs to the end and still passes the order and limit checks.
  - A run with `Δt` above the memory circuit's Euler limit (computed from its own eigenvalues) finishes and draws its figures.
  - Things to Try: the binding-order bullet's value, read from the cell text, makes the negative feedback loop not settle.
- **Step 2: Skipped.** The notebook was in place when the L15a suite was added.
- [x] **Step 3: Write the notebook** in the L14a example layout, but tight (Jeff, 2026-11-25: "keep it tight, the examples have been too long"). Budget: at most 20 cells and about 1,200 words of markdown, about half of the L14a example (32 cells, 2,666 words). Each task gets one lead paragraph, its code cells, one figure, and one short "What do we see?" paragraph. No model section: one paragraph in Setup points back to L14a and PS6 in words. Layout: title block (three objectives), Setup, Task 1 (Euler and RK4 against the reference through a pulse), Task 2 (log–log error against `Δt` with order-one and order-four guide lines, and f evaluations), Task 3 (eigenvalues of both circuits, the Euler limit of each mode, Euler on the negative feedback loop below and above its limit), Things to Try (binding order 4 in `config/negative-feedback-loop.toml`; RK4 above Euler's limit; another pulse), Summary. Starting states: the memory circuit at its low steady state with no inducer; the negative feedback loop from the zero state. The error measure: the largest difference in protein Y over the shared grid, divided by the reference's largest protein Y. The reference: `Tsit5`, `reltol = 1e-10`, `abstol = 1e-12`, `tstops` at the pulse edges, one sentence saying L15c explains the stops. Figures in the house style (`figure-style-5660-recipe`), the pulse in an input panel.
- [x] **Step 4: Execute the notebook from its folder and save outputs** (examples ship with outputs).
- [x] **Step 5: Run the week-15 suite; all testsets pass.** Run both style checkers on the example: 0 findings. Count cells and markdown words against the Step 3 budget, and cut until the example is within it.
- [x] **Step 6: Separate read-only review of L15a.** Claude reviewed both notebooks on 2026-11-26, then ran one read-only codex pass (lecture 9/10, example 7.5/10 before the accepted fixes). The fixes covered whole-number settings, pulse edges snapped to the integrator's grid, no lecture numbers in prose, and wording. Suite 91/91, both style checkers clean.
- [ ] **Step 7: Checkpoint: Jeff reviews L15a.** Show the lecture and example; record his changes; do not start Task 5 until he approves or says to go on.

### Task 5: L15b lab: write explicit Euler and RK4

**Files:**
- Create: `weeks/week-15/L15b/CHEME-5800-L15b-Lab-ExplicitMethods-Fall-2026.ipynb`, title "L15b Lab: Writing Explicit Euler and Runge–Kutta 4"
- Create: `weeks/week-15/L15b/src/Compute.jl` (module `L15bMethods`, student stubs)
- Create: `weeks/week-15/L15b/src/solution/Compute-solution.jl` (module `L15bMethods`, the reference)
- Create: `weeks/week-15/L15b/src/Visualize.jl` (module `L15bPlots`, supplied figures)
- Create: `weeks/week-15/L15b/Include.jl` (L6d pattern: unguarded `include` of `src/Compute.jl`, guarded `Visualize.jl`, `using .L15bPlots`, no `using .L15bMethods`)
- Create: `weeks/week-15/L15b/config/` (the same two byte copies)
- Delete: `weeks/week-15/L15b/CHEME-5800-L15b-Lab-ThreeGeneDynamics-Fall-2026.ipynb`
- Test: `instructor/validation/week-15/runtests.jl`

**Interfaces:**
- Consumes: `advance`, `integrate`, the tags (Task 1); `motif_path`, `balances!` (Task 2).
- Produces (module `L15bMethods`, exports only these three):
  - `my_euler_step(f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}`
  - `my_rk4_step(f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}`
  - `my_integrate(method_step::Function, f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64)::NamedTuple` returning `(t, x)` in the layout of `integrate`.
  - Each stub has a docstring with the method and a worked one-step example on the test equation, numbered steps, a TODO with a `Hint:` under it, and ends in `error("...")` naming the function.

- [ ] **Step 1: Write the failing suite tests** in `@meeting "L15b" begin @testset "L15b lab" ... end end`:
  - Starter: each of the three functions throws an `ErrorException`; the module exports exactly the three names; starter and solution have the same code lines outside the TODO lines (the week-13 `code_lines` helper).
  - Solution, loaded into the module in place of the starter: each step equals `advance(...; algorithm = ...)` to `rtol = 1e-12` at three random states of each circuit; `my_integrate` equals `integrate` to `rtol = 1e-12` for both methods at the notebook's `Δt` and at `Δt / 2`.
  - Reload: re-including `src/Compute.jl` twice, then calling `L15bMethods.my_euler_step` qualified, works.
  - Notebook with the solution: runs end to end; its check cells pass at the default settings and with every setting changed; it ships without outputs.
- [ ] **Step 2: Run the suite; the L15b testset fails.**
- [ ] **Step 3: Write the solution file, then the starter** from it (same lines, TODO bodies removed).
- [ ] **Step 4: Write the notebook** in the house lab layout: title block, Setup, three tasks per spec §6 (Task 1 Euler checked against the package and `Tsit5` on the memory circuit; Task 2 RK4, same checks; Task 3 measured order from step halving, the step where Euler produces a false oscillation on the negative feedback loop against the eigenvalue limit, then one `OrdinaryDiffEq.solve` call and a comparison of f evaluations with `sol.stats.nf`), Summary. Check cells compare against the package and the student's own runs, never pinned counts (`lab-check-cells-data-independent`). Clear all outputs.
- [ ] **Step 5: Run the week-15 suite and both style checkers.** Expected: all pass, 0 findings.
- [ ] **Step 6: Codex review of L15b** (read-only). Apply fixes; re-run Step 5.
- [ ] **Step 7: Checkpoint: Jeff reviews L15b.**

### Task 6: Week files and full validation

**Files:**
- Modify: `weeks/week-15/README.md` (week-14 layout: session table with L15a and L15b, L15c and L15d listed as coming; data and execution contracts; sources)
- Modify: `weeks/week-15/release.toml` (`title`, `entry_notebooks`, `supporting_notebooks`, `datasets` for the configs, `student_paths = ["README.md", "L15a"]` until L15b releases, `status = "prototype"`)
- Delete: `weeks/week-15/src/` (`Week15Core.jl`), `weeks/week-15/L15c/*` and `weeks/week-15/L15d/*` placeholders, after confirming each file is a placeholder from commit 8efbdf0 or earlier with no later hand edits (`git log --follow`)

- [ ] **Step 1: Confirm the placeholders** with `git log --oneline --follow` on each file to delete. Expected: no commit by Jeff after August. If one exists, stop and ask.
- [ ] **Step 2: Update README and release.toml; delete the placeholders.**
- [ ] **Step 3: Run the release checks on the working tree.**

Run: `julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl` and `RELEASE_MEETINGS="L15a" julia --startup-file=no --project=. instructor/validation/week-15/runtests.jl`, the week-14 suite, both style checkers on `weeks/week-15/*/*.ipynb`, and `python3 scripts/build_week.py 15 --allow-dirty --force --scope-only`.
Expected: every suite passes, 0 style findings, and the scope check lists only the L15a files.

- [ ] **Step 4: Report to Jeff** with the test counts and anything skipped. No commit or tag until he asks.
