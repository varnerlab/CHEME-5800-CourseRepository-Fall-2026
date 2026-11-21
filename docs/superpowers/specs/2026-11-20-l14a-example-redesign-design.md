# L14a Example Redesign: One Gene Circuit at a Time

Date: 2026-11-20. Status: draft for Jeff's approval.

## Intent

Jeff ruled on 2026-11-20 that the L14a example notebook,
`weeks/week-14/L14a/CHEME-5800-L14a-Example-GeneSwitch-Fall-2026.ipynb`, "needs to be totally
redesigned". He named three problems:

- **Task 2 breaks on the other circuits.** The nullcline scan works only for one-gene circuits, and
  its check, the nullcline plot, the eigenvalue table, and all of Task 3 assume exactly three steady
  states. On negative autoregulation, the check fails (1 state found, 3 expected). On the negative
  feedback loop, the scan throws a `BoundsError`.
- **The inducer settings are impossible to find.** Only the self-activating circuit has an inducer.
  Its baseline sits at the bottom of the config file, its binding sits three levels deep in a
  promoter block, and the pulse levels and times sit inside a long code cell.
- **Task 3 is underwhelming.** The small pulse moves the protein by about 0.1%.

His requirement: **each task works with each model.**

What students should take from the example, in Jeff's words: they "should be able to see the
solution of the non-linear system, and the linearized model solution, and how we setup of the
model, interface with the ODE solver. And they should be able to play with the parameters and see
what happens."

## Goals

- One notebook that works on one circuit at a time. A settings cell names the circuit, and every
  task runs on any of the three circuits with no edit outside the settings cell.
- Students change parameters in two places: the settings cell (the circuit, the starting state,
  the inducer pulse, and the final time) and the circuit's config file (the rate constants, the
  binding constants, and the promoter weights).
- The model setup and the interface to the ODE solver are visible, each step in its own cell.
- Task 3 puts the nonlinear solution and the linearized (S4) solution on one figure, driven by
  the pulse in the settings cell.

## Non-goals

- Changes to the lecture beyond its two example boxes.
- The reinforcement learning problem set that will reuse the builder.
- Changes to the TOML schema or to the builder's function signatures.
- Nullcline analysis.
- Release, tagging, or pushing. Those need Jeff's explicit go-ahead.

## Anti-goals

- A setting that works for only one circuit, or any cell besides the settings cell that must be
  edited to switch circuits.
- A setting buried inside a long code cell.
- A starting guess picked by hand for each circuit.
- A default Task 3 figure whose response is too small to see.
- A check cell that fails when a student changes a setting the notebook invites them to change.

## Constraints

- **House rules.** Follow `AGENTS.md`, the shared notebook style guide, and the prose density rule
  in `CLAUDE.md`. Code cells follow the course style: `let` blocks, explicit loops and if-blocks,
  an in-line comment on every statement and loop header, and named constants instead of bare
  numbers. Results are shown in `pretty_table` tables, not with `print` or `println`. Link every
  function as "[the `foo(...)` function](url)". No sentence opens with a backticked item or an
  acronym. Define every term at first use. Levels inside the cell are in `nmol/gDW`, the inducer
  in the medium is in `µM`, and time is in `min`. Deviations are written with Δ (Δx, ΔI), and the
  rate of change is ẋ, never Δẋ. The ODE solve is called as `OrdinaryDiffEq.solve(...)`, because
  the course package also exports `solve`.
- **Lectures hold no code.** All code stays in the example.
- **Keep these parts as they are:** the Setup cell, the background section "Gene Expression and
  Its Model" (including the promoter section, whose brace labels Jeff had removed on 2026-11-20),
  the motif figure, and the Step Size Check in Task 3, which Jeff moved here from the lecture.
- **The self-activating circuit's activating inducer stays.** Jeff chose this case (the chapter's
  Lux case) on 2026-11-19.
- **The course environment gains SteadyStateDiffEq.** In a scratch copy of the root environment,
  `Pkg.add("SteadyStateDiffEq"; preserve = PRESERVE_ALL)` added SteadyStateDiffEq v2.11.0 and
  DiffEqCallbacks v4.18.3 and changed no other version. Add it to the root `Project.toml` and
  `Manifest.toml`, and add `using SteadyStateDiffEq` with a comment to section 3 of
  `L14a/Include.jl`.
- **`DynamicSS` integrates the model in time.** Run it on a model with no pulse schedule set, so
  that the inducer stays at its baseline. `DynamicSS` finds only stable steady states, which is
  intended: it finds where the cells end up. On 2026-11-20, `DynamicSS(Tsit5())` found the steady
  state of all three current circuits from all-zero levels and from a high protein level, with the
  balances below `5e-7 nmol/gDW/min` and eigenvalues that match the current notebook. The
  self-activating gene landed in its low state from zero and in its high state from the high start.

## Approaches

Three ways to organize the notebook were considered:

1. **One circuit at a time (chosen).** The settings cell names the circuit, and each task runs on
   that circuit. A change to one number changes one figure. The cost: students compare circuits
   only by rerunning.
2. **All three circuits in every task.** Each task loops over the circuits, and each figure has
   three panels. Students could compare circuits directly, but every cell would carry a loop over
   models, the figures would be busy, and an edit to one config file would change one panel of
   three.
3. **Three short notebooks, one per circuit.** Each notebook would be the simplest to read, but
   the code would be copied three times, every fix would be made three times, and the release
   would gain two notebooks.

Jeff picked approach 1, because the point is to play with one model and see what changes.

For where students change parameters, Jeff picked the settings cell plus the config file, over the
settings cell alone (students would never see what a binding constant or a half-life does) and
over overrides in the notebook (deep field paths like `model.genes[1].promoter[2].bound[1].K`).

Jeff decided the steady state comes from the ODE solver's own steady-state tool,
SteadyStateDiffEq, instead of the package's Newton function and hand-picked guesses.

## The design

### Config files

- A new folder, `L14a/config/`, holds copies of the three circuit files:
  `negative-autoregulation.toml`, `positive-autoregulation.toml`, and
  `negative-feedback-loop.toml`. The notebook builds from these copies, so students edit their own
  files and not the course package's data.
- In each file, the `[inputs.I]` table moves to the top, right after `[parameters]`. A comment
  says that the baseline inducer concentration is set there and that the pulse is set in the
  notebook's settings cell. TOML allows tables in any order, so the builder needs no change.
- The package copies in `code/src/data/motifs/` get the same content, so that `motif_path(...)`
  and the coming problem set see the same circuits.

### An inducer for every circuit

- Every circuit gets one inducer `I` that **activates** a regulator, as the self-activating file
  does now. The baseline is `1 µM` in all three files. A pulse then means the same thing in every
  circuit: the inducer is held at a set level for a set time and then returns to `1 µM`.
  - Negative autoregulation: `I` activates the repressor X.
  - Negative feedback loop: `I` activates one of the two regulators (the builder picks X or Y).
  - Positive autoregulation: unchanged.
- The constants of the first two circuits are retuned so that each circuit keeps its character at
  the baseline:
  - negative autoregulation: one stable steady state with two real, negative eigenvalues;
  - negative feedback loop: complex pairs with negative real parts and a period near 80 min;
  - positive autoregulation: unchanged, with its low state, saddle, and high state.

### The settings cell

The settings cell goes in the Setup section, right after the `Include.jl` cell. It defines these
names, each with an in-line comment and its unit:

| Name | Meaning |
|---|---|
| `circuit` | The config file name in `config/`, without `.toml`. |
| `starting_protein` | The protein level (nmol/gDW) of every gene at the start of Task 1 and of the steady-state search. The mRNA levels start at zero. For the self-activating gene, this setting picks the low or the high state. |
| `pulse_level` | The inducer concentration (µM) during the pulse. |
| `pulse_start`, `pulse_length` | When the pulse starts and how long it lasts (min). |
| `final_time` | The end of each simulation (min). |

No circuit name, pulse value, or start value appears in any other cell. The default `circuit` is
`positive-autoregulation`. The defaults are set so that the default pulse gives a response that
is easy to see in every circuit. The builder must
check that `starting_protein` with zero mRNA still lands the self-activating gene in its high
state.

### Task 1: Set up the model and solve the nonlinear balances

- Read the circuit's config file (linked) and build the model with
  `build(MyGeneNetworkModel, path)`.
- Show the interface to the ODE solver, one step per cell:
  - the state vector, all mRNA levels and then all protein levels, in the order of the genes in
    the file;
  - the call signature `balances!(dx, x, model, t)`, what each argument is, and what the `!`
    means;
  - `ODEProblem(balances!, x0, (0.0, final_time), model)`;
  - `OrdinaryDiffEq.solve(problem, Tsit5(); ...)`.
- Plot each protein level against time from the starting state. The plot shows how the circuit
  settles, and the negative feedback loop shows its damped oscillation.

### Task 2: Find the steady state and its eigenvalues

- Build a `SteadyStateProblem(balances!, x0, model)` from the same start, and solve it with
  `DynamicSS(Tsit5())`. The text says that this runs the same model until the balances stop
  changing.
- Compute the Jacobian at the steady state and show its eigenvalues in a table. Reuse the current
  Task 1 table code (real part, imaginary part, and whether the mode decays, grows, or
  oscillates), which already handles any number of genes. Add the time constant `1/|Re λ|` and,
  for a complex pair, the period `2π/|Im λ|`.
- Tie the table to the Task 1 plot: the slowest time constant sets how long the circuit takes to
  settle, and a complex pair sets the period of the oscillation.

### Task 3: Linearize, solve with the S4 recursion, and compare

- Compute `A = jacobian(...)` and `B = input_jacobian(..., "I")` at the steady state, and
  `discretize(A, B; Δt)`.
- Keep the Step Size Check. It must work for every circuit and every pulse level.
- Set the pulse from the settings cell on a copy of the model with `set_input!(...)`. Solve the
  nonlinear model from the steady state, with `tstops` at the pulse edges. Run the S4 recursion on
  the deviations.
- Draw one figure. The top panel shows the inducer. The bottom panel shows the protein level of
  each gene, with the nonlinear model solid, the linear model dashed, and one color per gene.
  Follow the house figure style: a see-through gray panel, `:dodgerblue3` and `:red`, and the
  legend inside the plot when a corner is free.
- Show a table with the peak deviation and the final protein level of each model.

### Things to try

End Task 3 with a short list. Each item says what to change and what to look at:

- a smaller pulse, so that the two models agree;
- a longer removal of the inducer in the self-activating circuit, which flips the switch while
  the linear model returns;
- a different binding order `n` or half-binding level `K` in the config file, which moves the
  steady state and the eigenvalues, with the range named so that the circuit stays stable;
- a different circuit;
- a different `starting_protein` for the self-activating gene, which starts it in its other
  stable state.

### What comes out

- The nullcline scan, the nullcline plot, the three-state table, and the classification text.
- The hand-picked starting guesses, and the package's `steady_state(...)` call in the notebook.
  The function stays in the package, because the tests use it.
- The cross-circuit eigenvalue table in Task 1. Students compare circuits by switching the
  `circuit` setting.
- The two fixed pulses (`0.9 µM` and `0 µM`) and their table.

### Prose and the default run

(My call.) The default circuit is positive autoregulation, the circuit Jeff chose for the example
on 2026-11-19. The markdown after each result describes the default run with its numbers, and each
such paragraph opens with "With the default settings". The objectives, the key takeaways, the
lecture's example boxes, and slide 20 stay general and quote no run numbers, so they hold for any
circuit.

### Checks in the notebook

Checks must hold for any settings a student is invited to try: the solver returned success, the
balances at the steady state are near zero, and the recursion is stable. A check never pins a
number that depends on the default settings.

**Loss of stability (Jeff, 2026-11-20: steer around it).** A config edit can leave a circuit with
no stable steady state. With the current feedback-loop file, raising `n` from `4` to `5` makes the
largest real part of the eigenvalues +0.0003 1/min, the oscillation never dies out, and
`DynamicSS` returns `Failure`. The design steers around this case:

- Retune the feedback loop with a margin from that point. Every change the Things to try list
  names must keep each circuit stable, and the builder checks each one.
- If a student goes past the stable range anyway, the Task 2 check fails with a plain message
  that no stable steady state was found. Task 3 is not expected to run in that case.
- Refining the `DynamicSS` result with Newton's method was tested and rejected. From the point
  where `DynamicSS` stops, Newton converged at `n = 5` and `n = 8` but not at `n = 6`.

### Title, links, and other files

- New title: "Example: Linearizing a Gene Circuit". New file name:
  `CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb`. Rewrite the three learning objectives
  and the three key takeaways, two plain sentences each.
- Update every reference to the old file and its content: the lecture's Examples cell and its
  example box in the Linearization section; slide 3 ("Lecture and Example"), slide 20 (the
  example slide), and `\examplelink` in the deck, with the PDF rebuilt; the week README row;
  `release.toml`, including the new `config/` folder if the release rules require listing it.
- Tests in `instructor/validation/week-14/runtests.jl`: rewrite "L14a motif eigenvalues and
  pulses" for the new config files, using `DynamicSS`. Add a test that runs the example's code
  cells once per circuit, with only the `circuit` setting replaced, and requires every cell to
  pass.

## Left to the builder

- The inducer constants (`K_I`, `n_I`), the regulator the feedback-loop inducer acts on, and any
  retuned `K` or `W`, within the character rules above.
- The default settings values, `Δt`, and `final_time`.
- The exact cell breakdown, and whether Task 1 shows a table that maps config fields to the
  symbols in the balances.
- The figure details within the house style.

## Verification

- The per-circuit test runs the notebook for all three circuits, and the full week-14 suite
  passes.
- Codex checks the finished diff once, per Jeff's standing order.
- Jeff reviews the notebook before anything is committed.
