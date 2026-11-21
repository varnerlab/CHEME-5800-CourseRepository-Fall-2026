# L14a Example Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the L14a example so that every task runs on any of the three gene circuits,
chosen in one settings cell, with the nonlinear and linearized solutions on one figure.

**Architecture:** The notebook builds one circuit from a TOML copy in `L14a/config/`. Task 1 sets
up the model and solves it with OrdinaryDiffEq, Task 2 finds the steady state with
SteadyStateDiffEq's `DynamicSS` and reads the eigenvalues, and Task 3 linearizes, runs the S4
recursion, and compares both models for the pulse in the settings cell. The week-14 suite runs
the notebook's code cells once per circuit.

**Tech Stack:** Julia 1.12, the vendored course package (`code/src/GeneNetworks.jl`),
OrdinaryDiffEq, SteadyStateDiffEq (new), Plots, PrettyTables, Jupyter notebooks, LaTeX Beamer
deck.

**Spec:** `docs/superpowers/specs/2026-11-20-l14a-example-redesign-design.md`

## Global Constraints

- No commits, tags, or pushes: Jeff reviews the notebook before anything is committed.
- Code cells: `let` blocks, explicit loops and if-blocks, an in-line comment on every statement
  and loop header, named constants instead of bare numbers, no closures, `do` blocks, ternaries,
  or `x || throw` one-liners.
- Results appear in `pretty_table` tables (`backend = :text`, one keyword per line), never in
  `print` or `println`.
- Prose: paragraphs of at most 3 sentences or about 60 words; no sentence opens with a
  backticked item or an acronym; functions linked as "[the `foo(...)` function](url)"; every term
  defined at first use; no "the figure shows" lead-ins; no em dashes.
- Units: levels inside the cell in `nmol/gDW`, the inducer in the medium in `µM`, time in `min`.
- Notation: deviations are Δx and ΔI; the rate of change is ẋ, never Δẋ; the state matrix is
  **A**, never J.
- Solver calls are qualified: `OrdinaryDiffEq.solve(...)` and `SteadyStateDiffEq.solve(...)`,
  because the course package also exports `solve`.
- Keep unchanged: the Setup cells, the background cell (id `background`), and the motif figure.
- Every inducer activates its regulator (`inducer_effect = "activates"`), and the baseline is
  `initial = 1.0` µM in all three files.
- Default settings: `circuit = "positive-autoregulation";` written exactly so, on its own line.
- Figures follow the house style: a see-through gray panel
  (`background_color_inside = RGBA(0.5, 0.5, 0.5, 0.12)`), `framestyle = :box`,
  `fg_legend = :transparent`, `:dodgerblue3` and `:red`, and the legend inside the plot.

## Review Focus

1. **A pulse that runs past `final_time`, or `pulse_length = 0.0`:** the notebook runs, and the
   figure shows what falls inside the time span. (Task 4 test: `pulse edge cases run`.)
2. **`pulse_level` equal to the baseline (`1.0` µM):** the deviation is zero and the Step Size
   Check must not divide by zero. The check therefore uses its own named test deviation, not the
   settings pulse. (Task 4 test: `zero pulse runs`.)
3. **`starting_protein = 0.0` for the self-activating gene:** Task 2 lands in the low state and
   Tasks 2 and 3 still run. (Task 3 test: `low start runs`.)
4. **A config edit that removes the stable steady state:** the Task 2 check fails with a message
   containing "no stable steady state". (Task 3 test: `unstable circuit message`.)
5. **A `final_time` that is not a multiple of `Δt`:** the recursion times and the solver's saved
   times stay the same length. (Task 4 test: `odd final time runs`.)

---

### Task 1: Add SteadyStateDiffEq to the course environment

**Files:**
- Modify: `Project.toml`, `Manifest.toml` (repository root)
- Modify: `weeks/week-14/L14a/Include.jl` (section 3, IMPORTS)

**Interfaces:**
- Produces: `SteadyStateProblem`, `DynamicSS`, and `SteadyStateDiffEq.solve` in the notebook
  scope after the setup cell.

- [ ] **Step 1: Write the failing check.** Run
  `julia --startup-file=no --project=. -e 'using SteadyStateDiffEq'` from the repository root.
  Expected: an error that the package is not found.
- [ ] **Step 2: Add the package without moving any existing version.** Run
  `julia --startup-file=no --project=. -e 'using Pkg; Pkg.add("SteadyStateDiffEq"; preserve = Pkg.PRESERVE_ALL)'`.
- [ ] **Step 3: Check the diff.** `git diff Manifest.toml` must add only `SteadyStateDiffEq`
  (v2.11.0) and `DiffEqCallbacks` (v4.18.3), and change no other entry.
- [ ] **Step 4: Add the import.** In section 3 of `L14a/Include.jl`, after the `OrdinaryDiffEq`
  line, add `using SteadyStateDiffEq # SteadyStateProblem and DynamicSS, to find a steady state by running the model until it settles; call it as SteadyStateDiffEq.solve(...)`.
- [ ] **Step 5: Verify.** Run the week-14 suite (command in Task 5). Expected: all tests pass, as
  before.

### Task 2: Config files with an inducer in every circuit

**Files:**
- Create: `weeks/week-14/L14a/config/negative-autoregulation.toml`,
  `weeks/week-14/L14a/config/positive-autoregulation.toml`,
  `weeks/week-14/L14a/config/negative-feedback-loop.toml`
- Modify: `code/src/data/motifs/*.toml` (the same content as the L14a copies)
- Test: `instructor/validation/week-14/runtests.jl`, testset "L14a motif eigenvalues and pulses"
  (rewritten), plus the helpers `par_steady_states` and `final_protein` if they are no longer used

**Interfaces:**
- Produces: three config files, each with `[inputs.I]` (`initial = 1.0`) right after
  `[parameters]`, and a comment above `[inputs.I]` that says the baseline is set there and the
  pulse is set in the notebook's settings cell. A helper in the suite,
  `l14a_config(name::String)::String`, returns the path of an L14a copy.
- Produces: `THINGS_TO_TRY`, a vector of `(circuit::String, field::String, value::Float64)` in the
  suite. It lists every config change that the notebook's Things to try list names (Task 4 fills
  in the final entries).

- [ ] **Step 1: Write the failing tests.** Rewrite the testset. Use `DynamicSS(Tsit5())` from
  zero levels and, for the self-activating gene, from `starting_protein = 1.0` with zero mRNA.

```julia
@testset "L14a motif eigenvalues and pulses" begin
    # the L14a copies and the package copies are the same files -
    for name in ["negative-autoregulation", "positive-autoregulation", "negative-feedback-loop"]
        @test read(l14a_config(name), String) == read(motif_path(name), String)
    end
    # every circuit has the inducer I, activating, at 1 µM -
    for name in ["negative-autoregulation", "positive-autoregulation", "negative-feedback-loop"]
        model = build(MyGeneNetworkModel, l14a_config(name))
        @test haskey(model.inputs, "I")
        @test model.inputs["I"].initial == 1.0
    end
    # negative autoregulation: two real, negative eigenvalues -
    # positive autoregulation: low state from zero, high state from protein 1.0, both stable
    #   (p ≈ 0.0113 and p ≈ 0.884, rtol 1e-2, unchanged from the current file) -
    # negative feedback loop: complex pairs, every real part ≤ -0.005 1/min, and a period
    #   2π/max|Im λ| between 60 and 100 min -
    # B = input_jacobian(model, x, 0.0, "I") has a nonzero mRNA entry in every circuit -
    # every entry of THINGS_TO_TRY keeps its circuit stable: DynamicSS succeeds and every real
    #   part is negative -
    # NFL with n = 6 on both regulators: DynamicSS does not return Success -
end
```

- [ ] **Step 2: Run the suite.** Expected: FAIL. The L14a copies do not exist, and negative
  autoregulation and the feedback loop have no inducer.
- [ ] **Step 3: Write the three files.** Copy the package files, then move `[inputs.I]` to the
  top. Add an activating inducer to negative autoregulation (on the repressor X) and to the
  feedback loop (the builder picks X or Y). Retune `K`, `K_I`, `n_I`, or `W` until Step 1's
  assertions pass, and update each file's header comment with the new steady state and
  eigenvalues. Copy the three files over the package copies.
- [ ] **Step 4: Run the suite.** Expected: PASS, with every other L14a testset unchanged.

### Task 3: New notebook, settings cell, Task 1, and Task 2

**Files:**
- Rename: `git mv weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneSwitch-Fall-2026.ipynb weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb`
- Modify: the renamed notebook (title cell, a new `settings` cell, Tasks 1 and 2; delete the old
  Task 1 and Task 2 cells)
- Test: `instructor/validation/week-14/runtests.jl`, new testset "L14a example runs for every
  circuit"

**Interfaces:**
- Consumes: Task 1's imports and Task 2's config files.
- Produces these notebook globals, read by Task 4:
  - from the code cell with id `settings`: `circuit::String`, `starting_protein::Float64`,
    `pulse_level::Float64`, `pulse_start::Float64`, `pulse_length::Float64`,
    `final_time::Float64`;
  - from cell `build-model`: `model::MyGeneNetworkModel`, built from
    `joinpath(@__DIR__, "config", circuit * ".toml")`;
  - from cell `ode-solve`: `x_start::Vector{Float64}` (zero mRNA, then `starting_protein` for
    every gene) and `settling`, the ODE solution from `x_start`;
  - from cell `steady-state`: `x_steady::Vector{Float64}`.
- Produces in the suite: `run_example(replacements::Vector{Pair{String,String}}; after_build = nothing, stop_after = "")::Module`.
  It runs the notebook's code cells in order in a fresh module, with `REPL.softscope`, as the
  week-07 runner does. It applies each replacement to the `settings` cell's source and asserts
  that each one matched. If `after_build` is a model, it is assigned to `model` right after cell
  `build-model`. It stops after the cell whose id is `stop_after`, when given.

- [ ] **Step 1: Write the failing tests.**

```julia
@testset "L14a example runs for every circuit" begin
    for name in ["negative-autoregulation", "positive-autoregulation", "negative-feedback-loop"]
        ws = run_example(["circuit = \"positive-autoregulation\";" => "circuit = \"$(name)\";"])
        @test ws.circuit == name
        @test length(ws.x_steady) == 2 * length(ws.model.genes)
    end
    # low start runs: PAR from protein 0.0 lands in the low state -
    ws = run_example([r"starting_protein = [0-9.]+;" => "starting_protein = 0.0;"])
    @test ws.x_steady[2] < 0.05
    # unstable circuit message: NFL with n = 6 on both regulators, Task 2 throws -
    nfl = build(MyGeneNetworkModel, l14a_config("negative-feedback-loop"))
    # (set n = 6 on both bound regulators of nfl)
    err = try
        run_example(["circuit = \"positive-autoregulation\";" => "circuit = \"negative-feedback-loop\";"];
            after_build = nfl, stop_after = "steady-state")
        nothing
    catch e
        e
    end
    @test err !== nothing
    @test occursin("no stable steady state", sprint(showerror, err))
end
```

  (`run_example` accepts a `Regex` or a `String` as the pattern.)
- [ ] **Step 2: Run the suite.** Expected: FAIL, because the notebook has no `settings` cell.
- [ ] **Step 3: Rename the notebook, and write the title cell.** The title is "Example:
  Linearizing a Gene Circuit". The intro paragraph is short. The three learning objectives use
  two plain sentences each: build and solve a circuit's model with the ODE solver; find its
  steady state and read the eigenvalues; compare the linearized and nonlinear solutions for an
  inducer pulse.
- [ ] **Step 4: Add the `settings` code cell** after `setup-code`, with a markdown lead-in. It
  defines the six names, each with its unit in the comment, and names the baseline's place in
  the config file in the comment of the pulse lines. The default `pulse_level`,
  `pulse_start`, `pulse_length`, and `final_time` are the builder's choice. For every circuit,
  the default pulse must move a protein by at least 10% of its steady-state level in the
  nonlinear model (Task 4 tests this).
- [ ] **Step 5: Write Task 1, "Set Up the Model and Solve the Balances".** Use one cell per step:
  - a link to the config file;
  - cell `build-model`;
  - markdown on the state order (all mRNA, then all protein, in the file's gene order) and on
    the `balances!(dx, x, model, t)` signature, its arguments, and the `!`;
  - cell `ode-problem`, which calls `ODEProblem(balances!, x_start, (0.0, final_time), model)`;
  - cell `ode-solve`, which calls `OrdinaryDiffEq.solve(problem, Tsit5(); saveat = ...)`;
  - a plot of each protein against time, with one color per gene;
  - a "With the default settings" paragraph.
- [ ] **Step 6: Write Task 2, "The Steady State and Its Eigenvalues".**
  - Cell `steady-state` builds `SteadyStateProblem(balances!, x_start, model)` and calls
    `SteadyStateDiffEq.solve(problem, DynamicSS(Tsit5()))`. The `model` here has no pulse
    schedule, so the inducer stays at its baseline while `DynamicSS` integrates. If the solver does not report
    success, it throws an `ErrorException` from an if-block. The message says that no stable
    steady state was found, and that the circuit may oscillate without settling.
  - The `@test` checks that the balances at `x_steady` have a norm below a named tolerance.
  - The eigenvalue table reuses the old `motif-table` row logic for one circuit: real part,
    imaginary part, mode, time constant `1/|Re λ|`, and the period `2π/|Im λ|` for a complex
    pair (`—` otherwise).
  - A "With the default settings" paragraph ties the slowest time constant and any period to
    the Task 1 plot.
- [ ] **Step 7: Delete the old Tasks 1 and 2.** Delete the cells `task-1` through `classify`.
  Keep `background` unchanged. Keep the old `motif-table` code only as the source for Step 6.
- [ ] **Step 8: Run the suite and the linter.** Run the suite (Task 5 command), then
  `python3 instructor/validation/notebook_style_check.py weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb`.
  Expected: the suite passes, and the linter reports no findings in the new cells.

### Task 4: Task 3 of the notebook, Things to try, and the summary

**Files:**
- Modify: the renamed notebook (Task 3 cells, Things to try, Summary)
- Test: `instructor/validation/week-14/runtests.jl`, testset "L14a example runs for every
  circuit" (extended), and `THINGS_TO_TRY` (final entries)

**Interfaces:**
- Consumes: `model`, `x_steady`, and the settings names from Task 3.
- Produces in cell `linearize`: `A`, `B`, `Ā`, `B̄`, and `Δt`. In cell `pulse-run`: `pulse`, a
  `NamedTuple` with `t::Vector{Float64}`, `I::Vector{Float64}`,
  `p_linear::Matrix{Float64}`, and `p_nonlinear::Matrix{Float64}`, with one column per gene.

- [ ] **Step 1: Write the failing tests** in the per-circuit loop and as edge cases:

```julia
# per circuit, with the default pulse; ws_N is the number of genes -
ws_N = length(ws.model.genes)
deviation = maximum(abs.(ws.pulse.p_nonlinear .- ws.x_steady[ws_N+1:end]'), dims = 1)
@test maximum(deviation ./ ws.x_steady[ws_N+1:end]') >= 0.10   # the default pulse is visible
@test size(ws.pulse.p_linear) == size(ws.pulse.p_nonlinear)
# pulse edge cases run: a zero-length pulse, and a pulse past the final time -
run_example([r"pulse_length = [0-9.]+;" => "pulse_length = 0.0;"])
run_example([r"pulse_start = [0-9.]+;" => "pulse_start = 1.0e6;"])
# zero pulse runs: the pulse level equals the baseline -
ws = run_example([r"pulse_level = [0-9.]+;" => "pulse_level = 1.0;"])
@test maximum(abs.(ws.pulse.p_linear .- ws.x_steady[ws_N+1:end]')) < 1e-12
# odd final time runs -
run_example([r"final_time = [0-9.]+;" => "final_time = 333.3;"])
```

- [ ] **Step 2: Run the suite.** Expected: FAIL, because `pulse` is not defined.
- [ ] **Step 3: Write cell `linearize`.** It computes `A = jacobian(model, x_steady, 0.0)`,
  `B = input_jacobian(model, x_steady, 0.0, "I")`, and `discretize(A, B; Δt = Δt)`, with
  `Δt = 1.0` min, and shows the eigenvalue table of **A** and **Ā** from the old cell.
- [ ] **Step 4: Keep the Step Size Check.** Move the old `step-check` cell. Its deviation is a
  named test constant (`ΔI_test = -0.1` µM), not the settings pulse. The ratio check stays at
  `rtol = 0.05`.
- [ ] **Step 5: Write cell `pulse-run`.** On a `deepcopy` of `model`, call
  `set_input!(trial, "I", [pulse_start, pulse_start + pulse_length], [pulse_level, baseline])`.
  The times are `t_k = k Δt` for `k = 0, …, floor(Int, final_time / Δt)`. Run the S4 recursion on
  Δx, and solve the nonlinear model from `x_steady` with `saveat = t` and with `tstops` at the
  pulse edges inside the span. Show a table with each gene's peak deviation and final protein
  level for each model.
- [ ] **Step 6: Write cell `pulse-plot`.** The inducer panel is on top, at 30% of the height,
  drawn as a dashed `:steppost` line in the legend font color. The bottom panel shows the protein
  of each gene: the nonlinear model solid, the linear model dashed, gene 1 in `:dodgerblue3`,
  gene 2 in `:red`. Follow with a "With the default settings" paragraph.
- [ ] **Step 7: Write the Things to try list** at the end of Task 3: 4 to 5 bullets, each a full
  sentence that says what to change and what to look at, as the spec lists them. Name the stable
  range for every config change, and copy each config change into `THINGS_TO_TRY`.
- [ ] **Step 8: Delete the old Task 3 cells** (`task-3` through `large-result`), after Steps 3
  to 6 have taken what they reuse.
- [ ] **Step 9: Rewrite the Summary.** Three key takeaways, two plain sentences each, with no
  run numbers.
- [ ] **Step 10: Run the suite and the linter** (same commands as Task 3 Step 8). Expected: PASS
  and no linter findings.

### Task 5: Links, slides, release manifest, and verification

**Files:**
- Modify: `weeks/week-14/L14a/CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb`
  (the example boxes in cells 1 and 4)
- Modify: `weeks/week-14/L14a/slides/CHEME-5800-L14a-Slides-Fall-2026.tex` (`\examplelink`,
  slide 3 "Lecture and Example", slide 20), the rebuilt PDF, and `slides/README.md` (the slide 20
  title and the source-hash row)
- Modify: `weeks/week-14/README.md` (the L14a row), `weeks/week-14/release.toml`
  (`supporting_notebooks`, and add the three `L14a/config/*.toml` files to `datasets`)

- [ ] **Step 1: Check for stale references.** Run
  `grep -rn "GeneSwitch\|gene switch\|self-activating gene switch" weeks/week-14 instructor/validation/week-14`.
  Expected: matches in the five files listed above.
- [ ] **Step 2: Update the links and text.** Change the link text in the two lecture boxes and on
  the slides to "Linearize a gene circuit". Rewrite each box and slide 20 with no run numbers:
  three steps that match the new tasks, and one sentence about playing with the settings and the
  config file.
- [ ] **Step 3: Rebuild the deck** with `make` in `L14a/slides`. Expected: the PDF builds, and
  the only warning is the known bold-math font warning. Update the hash in `slides/README.md`
  with `shasum -a 256` of the new notebook.
- [ ] **Step 4: Run the full verification.**
  - `julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl`. Expected:
    every test passes.
  - `python3 instructor/validation/notebook_style_check.py weeks/week-14/L14a/*.ipynb`.
    Expected: no new findings.
  - Step 1's grep. Expected: no matches.
  - `python3 scripts/build_week.py 14 --output-dir /tmp/…`, with a scratchpad path. Expected:
    the bundle builds and contains `L14a/config/*.toml`.
- [ ] **Step 5: Execute the notebook in place** with the default settings, so that its saved
  outputs match the code (week 5 and later keep outputs).
- [ ] **Step 6: Run one codex pass** over the whole diff: `codex exec --sandbox read-only
  --skip-git-repo-check "$(cat prompt.md)" < /dev/null > out.txt 2>&1`. Give one numbered line per
  change and the numbers each change relies on. Apply its accuracy findings, and report what it
  said to Jeff.
