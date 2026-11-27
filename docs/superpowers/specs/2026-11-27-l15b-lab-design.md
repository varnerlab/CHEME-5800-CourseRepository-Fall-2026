# L15b lab design: explicit methods and the library solve, aimed at PS6 and the practicum

Date: 2026-11-27. This short design replaces the L15b section of §6 in
[the week-15 design](2026-11-25-week-15-ode-solvers-design.md) and moves Task 3 of L15d into L15b.
Every other part of that design still holds.

## Intent

Jeff, 2026-11-27: "We need to craft the lab so that students can use the ideas for PS6 and the
practicum. We want to be able to help students complete these assignments (without doing the exact
problem)."

The two assignments ask students to write these pieces:

- **PS6 (due Saturday 12-05).** Students write `control`, `balances!(dx, x, parameters, t)`, and
  `simulate`. The `simulate` function runs `Tsit5` with `tstops` at the pulse edges, saves the state
  every minute, checks the return code, and copies the solution into `t` and an `x` with one column
  per time.
- **Practicum, CHEME 5800 track (released 11-24).** Part 2 asks for the zero-order hold as a
  `_solve` method that Julia picks by the type of the algorithm. The method is a fixed-step loop
  that sets aside the times and a 2N × (steps + 1) state matrix, evaluates the model at the start of
  each step, and writes the next column. Question 2 asks how the gap between the zero-order hold and
  `Tsit5` grows with the step, and why the feedback circuit is more sensitive to the step.

## Goals, non-goals, anti-goals

- **Goal.** Students practice each code pattern the assignments need, on a different circuit and
  with different methods. The patterns are the in-place right-hand side `f!(dx, x, p, t)`, a
  fixed-step loop that dispatches on the method's type and fills one column per time, the library
  solve with stops, saved times, and a return-code check, and the error of a fixed-step method
  against the library solve as the step grows.
- **Non-goals.** Students do not write `control`, `balances!`, or the zero-order hold. The lab
  does not use the PS6 circuit as shipped, the PS6 pulses (5 µM for 60 min or 10 min), the
  loop-cut circuit, or a pulse-threshold scan. It does not use the practicum circuit (genes X, Y,
  and R).
- **Anti-goal.** The shipped solution must not answer any PS6 or practicum question.

## Approaches

- **A. Move the PS6 solve pattern into L15b (Jeff picked A, 2026-11-27).** Students see the
  solve on Tuesday 12-01, four days before PS6 is due. The lab gets longer by one section, and the
  solver stops appear before the L15c lecture explains adaptive steps.
- **B. Keep the solve in L15d (12-03), as in the 11-25 design.** This follows the order of the
  theory, but it leaves only two days before the deadline.

## The lab

**Student functions** in `src/Compute.jl`, module `L15bMethods`. Each function has a docstring,
numbered steps, a TODO with a `Hint:` under it, and ends in `error(...)` that names the function.

- `mysolve(f!, x₀, p; t_start, t_final, stops, Δt_save, reltol, abstol)` builds the `ODEProblem`
  and runs `Tsit5` with both tolerances and with `tstops` at the stops inside the time span. It
  saves a state every `Δt_save`, stops with an
  error when the return code is not a success, and returns `(t, x, evaluations)`. The matrix `x`
  has one column per saved time, and `evaluations` comes from `solution.stats.nf`.
- `mystep(algorithm::ExplicitEulerMethod, f!, x, p, t, Δt)` and
  `mystep(algorithm::RungeKutta4Method, f!, x, p, t, Δt)` are two methods of one function. Julia
  picks the method by the type of the package's own method tags, as the package `advance` does.
- `myintegrate(f!, x₀, p; t_start, t_final, Δt, algorithm)` loops `mystep` over the grid and
  returns `(t, x, evaluations)`, with one column per time.

**Tasks.** All three tasks use the L15a memory circuit (gene Z shortened) and the L15a pulse
start and concentration. Tasks 2 and 3 use the L15a pulse length.

1. **The library solve.** Students write `mysolve` and solve a short pulse with and without the
   stops, which shows why the stops matter (see Verified: stops). The short pulse is not a PS6
   pulse. The library solve comes first for two reasons. Students who do not finish the lab still
   leave with the piece PS6 needs, and `mysolve` provides the reference for Tasks 2 and 3.
2. **Explicit Euler.** Students write the Euler `mystep` and `myintegrate`. The checks compare
   the student's Euler run with the package `integrate` to round-off, after the transpose. A
   figure draws that run against the student's `mysolve` through the pulse.
3. **RK4 and the step.** Students write the RK4 `mystep`, with the same package check. They then
   compare Euler and RK4 against `mysolve` as the step grows: the largest difference in protein
   Y against `Δt`, the order from step halving on the smooth interval after the pulse, and the
   rate evaluations against `evaluations` of the library solve.

**Things to Try.** A step above the memory circuit's Euler limit, another pulse, and tighter
`mysolve` tolerances. Each item is a change to the settings, so the lab needs only the memory
config. Students who want the exact limit compute it from the Jacobian, as the L15a example does.
(Planning call, 2026-11-27: the negative feedback loop would need a second config and its own run
cells.)

**Layout and checks.** The lab follows the house lab layout and the L6d reload pattern:
qualified `L15bMethods.` calls, figures in `src/Visualize.jl`, and the solution in
`src/solution/`. One settings cell holds every input. Check cells compare against the package and
the student's own runs, never against pinned counts. The lab ships without outputs.

## Calls I made (for Jeff to check)

- **Columns, not rows.** `mysolve` and `myintegrate` return one column per time, as PS6 and
  the practicum do. The package `integrate` and the L15a example use one row per time, so the checks
  transpose the package output.
- **Stability moves to Things to Try.** The 11-25 design had students find Euler's false
  oscillation on the negative feedback loop. The L15a example already shows that oscillation, so
  the lab spends its time on the two assignment patterns.
- **The library solve comes first** (reasons in Task 1).
- **No assignment names in the notebook.** No week-15 notebook names PS6 or the practicum, so
  Jeff can make the link in class.
- **L15d.** L15d loses its Task 3 and keeps implicit Euler and solver choice. Its tolerance check
  and the rest of its details get settled when L15c and L15d are planned.

## Verified: stops

Run on 2026-11-27 with the L15a memory config from its low steady state to 480 min, `Tsit5` with
`saveat = 1.0`, and the PS6 tolerances (`reltol = 1e-8`, `abstol = 1e-12`). The default tolerances
give the same picture.

- **The L15a pulse (4 µM from 40 min for 72 min).** The stops change nothing that matters: the
  largest difference in protein Y is 1.4e-4 nmol/gDW, against a peak of about 1,886. Both runs
  switch to the high state.
- **Short pulses (4 µM for 2, 5, 10, or 20 min).** Without the stops, the solver steps over the
  pulse entirely. Protein Y stays flat at the low state, and the solve uses 111 rate evaluations
  instead of about 2,000. With the stops, protein Y peaks at 16 to 57 nmol/gDW and returns to the
  low state.

Task 1 therefore uses a short pulse for the comparison. The L15a pulse alone would not show any
difference.
