# L14a State Space Models and Gene Network Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the week 14 power iteration prototype with an LTI state space lecture, an
advanced eigenvalue notebook, and a gene network example. The example is built on a TOML-driven
gene network builder in the course package.

**Architecture:** The builder lives in the vendored course package (`code/src/GeneNetworks.jl`,
with types in `Types.jl` and `build` in `Factory.jl`). It reads one TOML file per motif into a
`MyGeneNetworkModel`. One generic `balances!` function and one Boltzmann `control` function
interpret the model. The notebooks call the package and `OrdinaryDiffEq` from the root
environment.

**Tech Stack:** Julia 1.12, TOML (stdlib), LinearAlgebra, OrdinaryDiffEq (root env only), Plots,
TikZ/pgfplots for the static SVG figures, and Jupyter with the `julia-1.12` kernel.

**Spec:** `docs/superpowers/specs/2026-11-19-l14a-state-space-gene-networks-design.md`

## Global Constraints

- Package code is plain course style: a docstring on every function and type, explicit loops and
  if-blocks, a comment on each step, no closures, no `do` blocks, no ternaries, and no
  `x || throw` or `&& return` one-liners.
- New types use the `My*` prefix and subtype `AbstractProcessModel`, the abstract type
  `MyMDPProblemModel` uses.
- Units are µM and min. θ = ln 2 / half-life. μ = ln 2 / doubling time.
- The state vector is `[m_1, …, m_N, p_1, …, p_N]`, in `[[genes]]` array order.
- Notebooks call `OrdinaryDiffEq.solve(...)`, qualified, because the course package also exports
  `solve`.
- Tests compare eigenvalues and residuals, never specific eigenvector entries.
- Notebook prose rules:
  - Paragraphs have at most 3 sentences or 60 words.
  - Exactly 3 learning objectives and 3 key takeaways, each two plain sentences.
  - `___` before each major `##` and at the end of the Summary.
  - No figure lead-ins and no cross-week links.
  - The API link convention applies, and no sentence opens with a backticked item or an acronym.
  - Define every term, including the biology for 5800 students.
  - No blockquote ends a cell right before code, and only one markdown cell sits between code
    cells.
- Plots use `framestyle = :box`, `fg_legend = :transparent`, `lw = 3`, `:dodgerblue3`, and
  `background_color_inside = RGBA(0.5, 0.5, 0.5, 0.12)`, with the legend inside when a corner is
  free. The setup cell offers `theme(:default)` / `# theme(:dark)`.
- SVG figures follow `instructor/FIGURE-THEMES.md`. Copy the `figs/<Name>/{.tex, Makefile,
  theme_svg.py}` layout and the image block from `weeks/week-13/L13a/figs/Fig-Client-Server/` and
  its notebook cell.
- Do not commit, push, or tag. Jeff commits when he asks.

## Review Focus

1. A config that names a regulator, inducer, or input that does not exist should raise an
   `ArgumentError` that names the field. A silent zero is wrong. Covered in Task 1.
2. A state that binds two regulators (AND logic) must multiply both bound fractions. Covered in
   Task 2.
3. An input schedule queried exactly at a breakpoint, or before the first time, must return a
   defined value: the value at or after the breakpoint, and the `initial` value before the first
   time. Covered in Task 2.
4. `steady_state` started from a poor guess must report `converged = false` and must not throw.
   Covered in Task 3.
5. `discretize` with a large Δt must keep a stable A stable. Covered in Task 4.

---

### Task 1: Week 14 scaffolding, types, and `build` from TOML

**Files:**
- Delete: `weeks/week-14/L14a/CHEME-5800-L14a-Lecture-DominantEigenpairs-PowerIteration-Fall-2026.ipynb`
  and `weeks/week-14/src/Week14Core.jl`, which removes the now-empty `weeks/week-14/src/` folder.
- Modify: `weeks/week-14/L14a/Include.jl`. Drop the `Week14Core` include and `using .Week14Core`.
  Imports become LinearAlgebra, OrdinaryDiffEq, Plots, PrettyTables (for the example's motif
  table), and Test.
- Modify: `code/Project.toml`. Add `TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"` to `[deps]`
  and `TOML = "1.0"` to `[compat]`. Then run `julia --project=. -e 'using Pkg; Pkg.resolve()'` from
  the repo root.
- Modify: `code/src/Types.jl` (append), `code/src/Factory.jl` (append), and
  `code/src/VLDataScienceMachineLearningPackage.jl` (add `using TOML`, `include("GeneNetworks.jl")`
  after `Eigen.jl`, and the exports).
- Create: `code/src/GeneNetworks.jl` (header block only, in this task), and
  `code/src/data/motifs/positive-autoregulation.toml` with the spec's placeholder values.
- Rewrite: `instructor/validation/week-14/runtests.jl`. Keep the header lines 1–6, delete the
  three power iteration testsets, and add the new ones under `@meeting "L14a"`.

**Interfaces:**
- Produces these types:
  - `MyBoundRegulatorModel`, with fields `regulator::String`, `K::Float64`, `n::Float64`,
    `inducer::String`, `inducer_effect::String`, `K_I::Float64`, and `n_I::Float64`.
    `inducer == ""` means no inducer.
  - `MyControlStateModel`, with fields `W::Float64`, `active::Bool`, and
    `bound::Vector{MyBoundRegulatorModel}`.
  - `MyGeneModel`, with fields `name::String`, `G`, `Vmax_X`, `K_X`, `Vmax_L`, `K_L`, `θ_m`, and
    `θ_p` (all `Float64`), plus `promoter::Vector{MyControlStateModel}` and
    `translation::Vector{MyControlStateModel}`.
  - `MyInputScheduleModel`, with fields `initial::Float64`, `times::Vector{Float64}`, and
    `values::Vector{Float64}`.
  - `MyGeneNetworkModel <: AbstractProcessModel`, with fields `description::String`,
    `genes::Vector{MyGeneModel}`, `index::Dict{String,Int64}` (gene name to position), `μ::Float64`,
    and `inputs::Dict{String,MyInputScheduleModel}`.
- Produces these functions:
  - `build(model::Type{MyGeneNetworkModel}, path::String)::MyGeneNetworkModel`
  - `motif_path(name::String)::String`, which returns
    `joinpath(_PATH_TO_DATA, "motifs", name * ".toml")`.
- Exports: all five types, `motif_path`, and (in later tasks) the functions those tasks add.

- [ ] **Step 1: Write the failing tests** in `runtests.jl`. Write the temp configs with
  `mktempdir()` and `write(...)`.

```julia
@testset "L14a build from TOML" begin
    model = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
    @test length(model.genes) == 1
    @test model.genes[1].name == "X"
    @test length(model.genes[1].promoter) == 2
    @test model.genes[1].promoter[2].bound[1].regulator == "X"
    @test model.genes[1].promoter[2].bound[1].inducer == "I"
    @test isapprox(model.genes[1].θ_m, log(2) / 2.5)
    @test isapprox(model.μ, log(2) / 60.0)
    @test model.inputs["I"].initial == 1.0
    @test isempty(model.genes[1].translation)
    # gene order follows the [[genes]] array, not alphabetical order
    ordered = build(MyGeneNetworkModel, two_gene_config(["Zeta", "Alpha"]))
    @test [g.name for g in ordered.genes] == ["Zeta", "Alpha"]
    @test ordered.index["Alpha"] == 2
    # unknown names are rejected
    @test_throws ArgumentError build(MyGeneNetworkModel, config_with_regulator("Q"))
    @test_throws ArgumentError build(MyGeneNetworkModel, config_with_inducer("J"))
end
```

  `two_gene_config` and `config_with_regulator` are test-file helpers. They write minimal TOML
  strings to a temp file and return its path. `config_with_inducer` names an inducer that has no
  `[inputs.J]` table.

- [ ] **Step 2: Run the tests and confirm they fail**

  Run: `julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl`

  Expected: an error for `MyGeneNetworkModel` not defined.

- [ ] **Step 3: Implement the types, `build`, and `motif_path`, and write the PAR config**

  `build` parses the file with `TOML.parsefile`. It reads half-lives per gene first, falling back
  to `[parameters]`. Missing optional fields get these defaults: `inducer = ""`, `K_I = 1.0`,
  `n_I = 1.0`, and empty `bound` and `translation` lists. After every gene is read, a second loop
  checks each bound regulator against `index` and each inducer against `inputs`. Any error message
  names the gene and the field.

- [ ] **Step 4: Run the tests and confirm they pass** (same command)

---

### Task 2: Boltzmann control, input schedules, and `balances!`

**Files:**
- Modify: `code/src/GeneNetworks.jl`, `code/src/VLDataScienceMachineLearningPackage.jl` (exports),
  and `instructor/validation/week-14/runtests.jl`.

**Interfaces:**
- Consumes the Task 1 types and `build`.
- Produces:
  - `set_input!(model::MyGeneNetworkModel, name::String, times::Vector{Float64}, values::Vector{Float64})::Nothing`
  - `input_value(model::MyGeneNetworkModel, name::String, t::Float64)::Float64`. It returns the value
    of the last breakpoint with `times[k] <= t`, or `initial` when `t < times[1]` or the schedule is
    empty.
  - `bound_fraction(model, b::MyBoundRegulatorModel, x::AbstractVector, t::Float64)::Float64`, which
    is xᵇⁿ/(Kⁿ + xᵇⁿ), with x_b = p_reg · f_I or p_reg · (1 − f_I).
  - `control(model, states::Vector{MyControlStateModel}, x::AbstractVector, t::Float64)::Float64`.
    It returns the active-weight sum divided by (1 + the all-weight sum), where a state's weight is
    `W` times the product of its bound fractions. It returns `1.0` when `states` is empty.
  - `transcription_control(model, j::Int64, x, t)::Float64` and
    `translation_control(model, j::Int64, x, t)::Float64`, which apply `control` to gene j's
    `promoter` and `translation` lists.
  - `balances!(dx::AbstractVector, x::AbstractVector, model::MyGeneNetworkModel, t)::Nothing`, which
    implements the spec's two balances, with `r_X = Vmax_X G/(K_X + G)` and
    `r_L = Vmax_L m/(K_L + m)`.

- [ ] **Step 1: Write the failing tests**

```julia
@testset "L14a Boltzmann control and balances" begin
    par = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
    levels = [0.0, 0.01, 0.1, 1.0, 10.0, 100.0]
    u = [transcription_control(par, 1, [0.0, p], 0.0) for p in levels]
    @test all(0.0 .<= u .<= 1.0)
    @test issorted(u)                                   # an activator raises the control
    W1 = par.genes[1].promoter[1].W
    @test isapprox(u[1], W1 / (1 + W1))                 # no protein: only the leak state
    @test translation_control(par, 1, [0.0, 1.0], 0.0) == 1.0
    # inducer raises the control at fixed protein
    set_input!(par, "I", [0.0], [10.0])
    @test transcription_control(par, 1, [0.0, 0.5], 1.0) > u_at_baseline
    # AND state: both regulators needed
    andnet = build(MyGeneNetworkModel, and_gate_config())   # Z active state binds X and Y
    low  = transcription_control(andnet, 3, x_with(pX = 10.0, pY = 0.0), 0.0)
    high = transcription_control(andnet, 3, x_with(pX = 10.0, pY = 10.0), 0.0)
    @test high > 10 * low
    # schedule edges
    set_input!(par, "I", [5.0, 10.0], [3.0, 1.0])
    @test input_value(par, "I", 4.9) == 1.0             # before the first time: initial
    @test input_value(par, "I", 5.0) == 3.0             # at a breakpoint: the new value
    @test input_value(par, "I", 12.0) == 1.0
    # balances at a hand-computed state
    x = [0.002, 0.3]; dx = zeros(2)
    balances!(dx, x, fresh_par, 0.0)
    @test isapprox(dx, hand_balances(fresh_par, x); rtol = 1e-12)
end
```

  `hand_balances` writes the two spec equations out directly from the config's numbers in the test
  file. `u_at_baseline` is the control at `p = 0.5` before the inducer change.

- [ ] **Step 2: Run the tests and confirm the new testset fails**
- [ ] **Step 3: Implement the functions above**
- [ ] **Step 4: Run the tests and confirm they pass**

---

### Task 3: `equations`, Jacobians, and `steady_state`

**Files:**
- Modify: `code/src/GeneNetworks.jl`, the exports, and `runtests.jl`.

**Interfaces:**
- Consumes `balances!` and `input_value`.
- Produces:
  - `equations(model::MyGeneNetworkModel)::String`. It returns one line per balance, and one line
    per control showing each state's W, regulator, K, and n. The notebooks print it with
    `println`.
  - `jacobian(model, x::Vector{Float64}, t::Float64)::Matrix{Float64}`, by central differences
    with step `h = 1e-6 * max(abs(x[i]), 1e-3)`.
  - `input_jacobian(model, x::Vector{Float64}, t::Float64, name::String)::Vector{Float64}`. It uses
    a central difference in the input. The difference is taken on a `deepcopy(model)` with
    `set_input!` set to the constant values I ± h, so the caller's model is not changed.
  - `steady_state(model; guess::Vector{Float64}, t::Float64 = 0.0, tolerance::Float64 = 1e-12, maxiter::Int64 = 100)::NamedTuple`.
    It returns `(x, converged, iterations)`. Each Newton step is `x -= J \ f`. A step that leaves
    any entry negative halves the step until every entry is nonnegative. The function returns
    `converged = false` after `maxiter` steps instead of throwing.

- [ ] **Step 1: Write the failing tests**

```julia
@testset "L14a Jacobians and steady states" begin
    par = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
    x = [0.002, 0.3]
    J = jacobian(par, x, 0.0)
    @test isapprox(J, hand_jacobian(par, x); rtol = 1e-6)
    # hand_jacobian: [-(θ_m+μ)  r_X ∂ū/∂p ; Vmax_L K_L/(K_L+m)^2  -(θ_p+μ)],
    # with ∂ū/∂p written from the Boltzmann formula in the test file
    B = input_jacobian(par, x, 0.0, "I")
    @test B[2] == 0.0
    @test B[1] > 0.0
    text = equations(par)
    @test occursin("dm_X/dt", text)
    @test occursin("dp_X/dt", text)
    bad = steady_state(par; guess = [1e6, 1e6], maxiter = 5)
    @test bad.converged == false
end
```

- [ ] **Step 2: Run the tests and confirm they fail**
- [ ] **Step 3: Implement the four functions**
- [ ] **Step 4: Run the tests and confirm they pass**

---

### Task 4: `discretize`, `poweriteration`, and the `qriteration` replacement

**Files:**
- Modify: `code/src/GeneNetworks.jl` (`discretize`) and `code/src/Eigen.jl`. In `Eigen.jl`,
  replace `qriteration` and its helpers with the 5820 versions from
  `~/Desktop/julia_work/CHEME-5820-Instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/week-2/L2a/src/Eigendecomposition.jl`
  (`_rref!`, `_upper_triangular`, `_smallest_singular_vector`, `_nullspace_vector`, and
  `qriteration`), and add `poweriteration` from the same file. Keep the package's existing comment
  style: a header block, a docstring, and step comments. Rewrite any ternary or one-liner as an
  if-block. Then update the exports and `runtests.jl`.

**Interfaces:**
- Produces:
  - `discretize(A::Matrix{Float64}, B::AbstractVecOrMat{Float64}; Δt::Float64)::Tuple`, which
    returns `(Ā, B̄)` with `Ā = (I − Δt/2·A)⁻¹(I + Δt/2·A)` and `B̄ = (I − Δt/2·A)⁻¹ Δt·B`. B̄ has the
    shape of B.
  - `poweriteration(A, v; maxiter = 100, ϵ = 1e-4)::NamedTuple`, with the 5820 return names.
  - `qriteration(A; maxiter = 10, tolerance = 1e-9)`, with the signature unchanged.

- [ ] **Step 1: Write the failing tests**

```julia
@testset "L14a discretization and eigenvalue algorithms" begin
    A = [-1.0 0.5; -0.5 -2.0]; B = [1.0, 0.0]; x0 = [1.0, -1.0]; T = 4.0
    exact = exp(A * T) * x0 + A \ ((exp(A * T) - I) * B)       # constant input u = 1
    err = Float64[]
    for Δt in [0.1, 0.05]
        Ā, B̄ = discretize(A, B; Δt = Δt)
        x = copy(x0)
        for k in 1:round(Int, T / Δt)
            x = Ā * x + B̄ * 1.0
        end
        push!(err, norm(x - exact))
    end
    @test err[2] < err[1] / 3                                   # second order in Δt
    Ā, _ = discretize(A, B; Δt = 10.0)
    @test all(abs.(eigvals(Ā)) .< 1.0)                          # stable A stays stable at large Δt
    Āu, _ = discretize([0.2 0.0; 0.0 -1.0], B; Δt = 0.5)
    @test maximum(abs.(eigvals(Āu))) > 1.0
    S = [4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0]
    λ, V = qriteration(S; maxiter = 200)
    @test isapprox(sort(λ), sort(eigvals(Symmetric(S))); atol = 1e-6)
    for i in 1:3
        @test norm(S * V[i] - λ[i] * V[i]) < 1e-5
    end
    result = poweriteration(S, ones(3); maxiter = 500, ϵ = 1e-10)
    @test isapprox(result_value(result), maximum(eigvals(Symmetric(S))); atol = 1e-6)
end
```

  Here `result_value` reads the 5820 return field. Use the field name directly once the port is
  done.

- [ ] **Step 2: Run the tests and confirm they fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run the full suite and confirm it passes.** Also run
  `grep -rn "qriteration" weeks code/src` and confirm that no other caller depends on the old
  eigenvector `Dict` keys.

---

### Task 5: The three motif configs with tuned parameters

**Files:**
- Modify: `code/src/data/motifs/positive-autoregulation.toml`.
- Create: `code/src/data/motifs/negative-autoregulation.toml` and
  `code/src/data/motifs/negative-feedback-loop.toml`.
- Modify: `runtests.jl`.

Configs:
- **Positive autoregulation.** Start from the spec's feasibility values: W_basal 0.005,
  W_active 10, n = 3, K = 0.5, r_X = 0.02, Vmax_L 0.05, and K_L 0.05. Set G, Vmax_X, and K_X so that
  r_X = 0.02. Then adjust K and K_I so that the baseline I = 1 is bistable.
- **Negative autoregulation.** Gene X has an active RNA polymerase-only state and an inactive
  X-bound state. Use repression weak enough that the loop gain stays below (a − b)²/4.
- **Negative feedback loop.** Genes X and Y, in that order:
  - X's promoter has an active RNA polymerase-only state and an inactive Y-bound state.
  - Y's promoter has a leak state and an active X-bound state.
  - Both genes use the same half-lives.

- [ ] **Step 1: Write the failing tests**

```julia
@testset "L14a motif eigenvalues and pulses" begin
    par = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
    states = par_steady_states(par)                 # scans the 1-D steady-state curve, then steady_state(...)
    @test length(states) == 3
    λ = [eigvals(jacobian(par, s, 0.0)) for s in states]
    @test all(real.(λ[1]) .< 0) && all(real.(λ[3]) .< 0)
    @test count(real.(λ[2]) .> 0) == 1
    nar = build(MyGeneNetworkModel, motif_path("negative-autoregulation"))
    λn = eigvals(jacobian(nar, steady_state(nar; guess = [0.01, 0.1]).x, 0.0))
    @test all(imag.(λn) .== 0) && all(real.(λn) .< 0)
    nfl = build(MyGeneNetworkModel, motif_path("negative-feedback-loop"))
    λf = eigvals(jacobian(nfl, steady_state(nfl; guess = fill(0.05, 4)).x, 0.0))
    @test any(abs.(imag.(λf)) .> 1e-6)
    # pulses from the low state (OrdinaryDiffEq, Tsit5, tstops at the pulse edges)
    @test final_protein(par, states[1], small_pulse) < states[2][2]
    @test final_protein(par, states[1], large_pulse) > states[2][2]
end
```

  `par_steady_states` and `final_protein` are test-file helpers, and the example notebook repeats
  their logic in visible cells. Pick `small_pulse` and `large_pulse` while tuning: a start time,
  a stop time, and an inducer level each.

- [ ] **Step 2: Run the tests and confirm they fail**
- [ ] **Step 3: Write the two new configs and tune all three until the tests pass.** Record the
  final values and the eigenvalues in a comment block at the top of each config.
- [ ] **Step 4: Run the full suite and confirm it passes**

---

### Task 6: Advanced notebook, computing eigenvalues

**Files:**
- Create: `weeks/week-14/L14a/CHEME-5800-L14a-Advanced-ComputingEigenvalues-Fall-2026.ipynb`.

Copy the 5820 L2a eigendecomposition and power iteration cells, and the L2c QR iteration cells.
Then edit them to fit:
- Use the 5800 setup cell: `include(joinpath(@__DIR__, "Include.jl"))`.
- Use the package's `poweriteration` and `qriteration`.
- Compare each result with the [`eigen(...)` function], using eigenvalues and residuals only.
- Add one short paragraph on why the characteristic polynomial is not used for large matrices.
- Keep the prototype's spectral gap demonstration if it fits within the prose limits.
- Leave Gram–Schmidt out.
- Write in the house structure: a title, three learning objectives, Setup, sections separated by
  `___`, and a Summary with three takeaways.

- [ ] **Step 1: Build the notebook. Every cell needs an `id`.**
- [ ] **Step 2: Execute it in place from its folder**

  Run: `cd weeks/week-14/L14a && jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.kernel_name=julia-1.12 --ExecutePreprocessor.timeout=900 CHEME-5800-L14a-Advanced-ComputingEigenvalues-Fall-2026.ipynb`

  Expected: the notebook runs with no errors and every `@test` passes. Then check `git diff` for
  kernel metadata changes and revert them.

- [ ] **Step 3: Lint it**

  Run: `python3 instructor/validation/notebook_style_check.py weeks/week-14/L14a/CHEME-5800-L14a-Advanced-ComputingEigenvalues-Fall-2026.ipynb`

  Use the bare form, not `--baseline`. Expected: 0 findings.

---

### Task 7: Lecture notebook and the phase portrait figure

**Files:**
- Create: `weeks/week-14/L14a/CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb`.
- Create: `weeks/week-14/L14a/figs/Fig-PhasePortraits/{Fig-PhasePortraits.tex, Makefile, theme_svg.py}`
  and the built `.pdf` and `.svg`.

The figure is a 2×2 pgfplots grid of trajectories from several initial points, with the
eigenvector directions drawn where they are real:
- **Stable node:** A = diag(−1, −3).
- **Saddle:** A = diag(1, −2).
- **Center:** A = [0 2; −2 0].
- **Stable spiral:** A = [−0.3 2; −2 −0.3].

Each panel title gives its eigenvalues. Generate the trajectory data in Julia, or use
pgfplots parametric curves, since every solution is analytic. Copy the Makefile and
`theme_svg.py` from the L13a client-server figure.

Lecture sections follow the spec's list, items 1–9. Copy the LTI block and the bilinear
discretization box from the 5820 L14a lecture and edit them; do not write them fresh. The lecture
has two code cells:
- The open-loop modes: `eigen(A)` for the stable spiral matrix, and a check that
  `V * Diagonal(exp.(λ * t)) * inv(V) * x0 ≈ exp(A * t) * x0`.
- The recursion versus the exact solution for a constant input: the Task 4 test case, with the
  error printed for two Δt values.

The title block links the example and the advanced notebook, and Section 4 links the advanced
notebook again.

- [ ] **Step 1: Build and theme the figure. Check the SVG in both themes.**
- [ ] **Step 2: Build the notebook**
- [ ] **Step 3: Execute it in place** (the Task 6 command, with this file name). Expected: no errors.
- [ ] **Step 4: Lint it bare.** Expected: 0 findings. Then check every paragraph against the prose
  limits by hand.

---

### Task 8: Example notebook, the gene switch

**Files:**
- Create: `weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneSwitch-Fall-2026.ipynb`.
- Create: `weeks/week-14/L14a/figs/Fig-Motifs/{Fig-Motifs.tex, Makefile, theme_svg.py}` and the
  built files.

The motif schematic shows the three motifs in Alon's style: circles for proteins, arrows for
activation, and blunt ends for repression.

The notebook follows the spec's example flow, items 1–7. The cells that decide content are:
- **The motif table:** `build(...)`, `steady_state(...)`, and `eigvals(jacobian(...))` for each
  motif, shown with `pretty_table` or a printed table.
- **The nullcline plot** in the (m, p) plane, with the three PAR steady states marked.
- **The hand Jacobian.** A markdown derivation, then a cell that compares it with `jacobian(...)`.
- **The linearization about the low state:** `A = jacobian(...)`,
  `B = input_jacobian(..., "I")`, and `Ā, B̄ = discretize(A, B; Δt = Δt)`.
- **The visible recursion loop**, over the inducer deviation δI_k.
- **The nonlinear solve** with `OrdinaryDiffEq.solve(ODEProblem(balances!, x0, tspan, model), Tsit5(); tstops = ...)`.
- **The comparison plots** for the small and large pulses, from Task 5. In each plot, the inducer
  is drawn as a dashed step line, not a fill. Add a dashed line at the saddle's protein level.

The biology introduction defines DNA, gene, mRNA, protein, transcription, translation, promoter,
RNA polymerase, transcription factor, and inducer in plain words. It cites Shoval and Alon (2010)
by DOI, Moon et al. (2012), Adhikari et al. (2020), and the chapter as in preparation. The example
ships with outputs.

- [ ] **Step 1: Build and theme the motif figure**
- [ ] **Step 2: Build the notebook**
- [ ] **Step 3: Execute it in place.** Expected: no errors, and the plots render in both
  `theme(:default)` and `theme(:dark)`. Rerun the light version last.
- [ ] **Step 4: Lint it bare and check the prose limits.** Expected: 0 findings.

---

### Task 9: Week files and final verification

**Files:**
- Modify: `weeks/week-14/README.md`. Update the L14a row and the description paragraph, with no
  equations. Remove the "full eigendecomposition ... remains in CHEME 5820" framing where it no
  longer applies.
- Modify: `weeks/week-14/release.toml`:
  - `entry_notebooks`: the lecture.
  - `supporting_notebooks`: the advanced and example notebooks.
  - `student_paths = ["README.md", "L14a"]`, now that `src` is gone.
  - Keep `status = "prototype"`.

- [ ] **Step 1: Run the full week suite**

  Run: `julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl`

  Expected: all L14a testsets pass.

- [ ] **Step 2: Run the bundle checks**

  Run: `python3 -m pytest instructor/validation/test_week_bundles.py -q -k "14"`, or the file's
  documented form.

  Expected: pass. If the bundle test reads `release.toml`, confirm that it accepts the new paths.

- [ ] **Step 3: Run the other weeks' suites that load the package.** This step checks that the
  `Eigen.jl` replacement and the new exports broke nothing, at minimum for weeks 6, 7, 11, and 12.
  Expected: the same results as before the change. Weeks 8 and 11 have known failures from Jeff's
  own commits, so compare against `git stash` runs if they fail.
- [ ] **Step 4: Run one batched codex review**

  Run: `codex exec --sandbox read-only --skip-git-repo-check "$(cat prompt.md)" < /dev/null > codex-out.txt 2>&1`

  Write `prompt.md` in the scratchpad. It lists each change with a numbered line, the
  measurements each change relies on, and the linter's rules. Apply its accuracy findings. Take
  only the prose suggestions that are plainer and true. Afterwards, check `git status` for stray
  metadata edits.

- [ ] **Step 5: Report to Jeff.** Cover what was built, which 2025 and 5820 pieces were kept and
  why anything was dropped, the suite and codex results as they read, and at most one question.
