# Week 15 design: numerical solution of initial value problems on gene circuits

**Date:** 2026-11-25. **Status:** draft for Jeff's approval. **Scope:** all four week-15 meetings
(L15a, L15b, L15c, L15d), the course-package additions they need, the validation suite, and the
release files. L15a and L15b are built first.

## 1. Intent

By the end of week 15, students are comfortable solving systems of ordinary differential equations
numerically, typically initial value problems. They know the basics of the common methods and the
trade-offs of each: accuracy, stability, and cost. The treatment is high-level, but deep enough that
students can implement the common methods themselves (Jeff, 2026-11-25).

The week also carries one practical message: these methods are typically not written by hand. Students
write Euler, Runge–Kutta 4, and implicit Euler to understand how a solver works, and they use
DifferentialEquations.jl for real work (Jeff, 2026-11-25).

The case study for the whole week is the synthetic gene circuit of L14a and PS6:

- the **memory circuit** of PS6 (Alon's regulated feedback motif: the inducer I binds protein X,
  X activates genes Y and Z, and Y and Z activate each other), and
- the **negative feedback loop** of L14a (X activates Y, Y represses X; the inducer sets the fraction
  of Y that can bind), which oscillates, plus a **fast-binding variant** of it that is stiff (Jeff
  approved this stiff case on 2026-11-25).

## 2. Goals, non-goals, anti-goals

**Goals**

- Students can state an initial value problem, step it forward with a one-step method, and explain
  local error, global error, and the order of a method.
- Students can implement explicit Euler, classical Runge–Kutta 4 (RK4), and implicit Euler with a
  Newton solve, and check them against a library solution.
- Students can predict the step limit of an explicit method from the Jacobian eigenvalues, recognize
  a stiff problem, and say why implicit methods help on it.
- Students know what an adaptive solver does (error estimate, tolerances, accepted and rejected steps)
  and why an input that jumps needs solver stops.
- Students can choose a DifferentialEquations.jl solver for a problem and check a solution by
  tightening the tolerance.
- L15d helps students finish PS6. Jeff wants this overlap, because the practicum is released and
  students will want time for it.

**Non-goals (left to other courses)**

- Multistep method derivations. BDF is named only as the family that stiff library solvers use.
- Butcher tableaux, order conditions, and convergence proofs.
- L-stability and symplectic methods.
- Differential-algebraic equations, boundary value problems, and partial differential equations.
- Stochastic simulation of gene expression.
- Events and callbacks beyond solver stops at input jumps.
- Sensitivities, adjoints, and neural ODEs.
- The CHEME 5820 bridge. It moves to L16a, whose title already covers the transition to 5820. Week 15
  does not name S4, Mamba, or their papers.

**Anti-goals (failure even if the notebooks run)**

- A week that teaches students to write production solvers. Every hand-written method is presented as
  a way to understand a library method.
- A stiff example that is not stiff. The stiff solvers must win clearly on work (steps and f
  evaluations), and the notebook must show it.
- A model that departs from Jeff's form. The fast-binding variant adds one binding reaction and keeps
  every existing term of the L14a and PS6 model (see `present-models-in-instructor-form`).
- Material that only restates L14a. L14a already covers the bilinear and zero-order hold
  discretizations, stability from the eigenvalues, and a `Tsit5` solve with inducer pulses. Week 15
  refers back to that material in words and builds on it.

## 3. Constraints

**Schedule.** L15a lecture Monday 2026-11-30, L15b lab Tuesday 12-01, L15c lecture Wednesday 12-02,
L15d lab Thursday 12-03. PS6 is due Saturday 12-05. L16a (12-07) is the synthesis lecture.

**House rules that apply to every notebook** (all recorded in memory and in the shared notebook style
guide, `../CHEME-5660-CourseRepository-Fall-2026/lectures/instructor/NOTEBOOK-STYLE-GUIDE.md`):

- Lectures are theory only: zero code cells, no Setup section, at most six `##` sections counting
  Examples and Summary. Every computation goes in the companion example.
- Prose density: paragraphs of at most three sentences or about 60 words; one idea per sentence.
- Learning objectives and key takeaways are exactly three bullets of two plain sentences each.
- No run values, setting values, or code constants in markdown or comments. Figures and the one
  load-bearing table carry the numbers.
- A settings cell holds every input students change, with a comment that says what each one does and
  where any baseline lives. Pulses show in the figure's input panel.
- Every code statement and loop header has an in-line comment. Loop ranges and check values are
  named constants or derived. Plain course-style Julia: documented top-level functions, explicit
  loops and if-blocks, no closures, `do` blocks, ternary chains, or `x || throw` one-liners.
- Tests and notebook checks read settings and configs and derive their expectations. No hardcoded
  values.
- Braces label equation terms instead of symbol-definition bullets. No "the figure shows" lead-ins.
  No cross-week links. Define every term at first use, and gloss biology terms.
- Write the gene model in Jeff's form, term for term, as L14a does.

**Notation.** Follow L14a: state x, input u, right-hand side f, Jacobian (state matrix) A, eigenvalues
λ. The time step is Δt (Jeff: "In the finite diff world we use Δ"), not h. Concentrations inside the
cell are in nmol/gDW, the medium in µM, and time in min.

**Environment.** The course environment has OrdinaryDiffEq (the ODE part of DifferentialEquations.jl,
with the Tsit5, Verner, Rosenbrock, BDF, and Default solver subpackages), SteadyStateDiffEq, and
DiffEqCallbacks. No package is added. The notebooks teach DifferentialEquations.jl by name and say
that the course loads its ODE part, OrdinaryDiffEq. The full metapackage would add solvers week 15 does
not use and a much longer first compile on student laptops.

**Existing files.** `weeks/week-15` holds the August placeholder notebooks (assistant-written; the
lectures have code cells), a fermentation lab, and `src/Week15Core.jl`. All of them are replaced.
The week-level `src/` is deleted (lecture code lives in the package; labs keep their own `src/`).
There is no hand-edited source to copy: the 2024 three-gene and fermentation labs are not on this
machine, and 2025 week 15 covered Hopfield networks. The CHEME 5820 Spring 2026 L14a lecture
(`~/Desktop/julia_work/CHEME-5820-Instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/week-14/L14a/`)
uses Euler; the builder should mine it for text before writing new prose.

## 4. Approaches considered

**Week structure.**

- **A. Explicit methods first, then implicit and adaptive methods (chosen by Jeff).** L15a/L15b cover
  initial value problems, Euler, Runge–Kutta, and stability; L15c/L15d cover implicit methods,
  stiffness, adaptive steps, and solver choice. Students write methods in both labs, and L15d ends in
  the PS6 pattern.
- **B. Write the methods first, then use a library.** All fixed-step methods in L15a/L15b; library
  solvers only in L15c/L15d. Rejected: one implementation lab instead of two.

**Stiff case.**

- **The PS6 memory circuit with fast inducer binding.** Rejected in favor of Jeff's suggestion of a
  negative feedback circuit with oscillations.
- **The L14a negative feedback loop as it is.** It oscillates, but it is not stiff (see §5). It stays in
  L15a/L15b as the oscillation case.
- **The negative feedback loop with fast binding of the inducer to protein Y (chosen, Jeff 2026-11-25).**
  It keeps the oscillation and adds a fast mode far from the expression modes.

## 5. Verified facts the design rests on

These were computed on 2026-11-25 with the course package (`build(MyGeneNetworkModel, path)` loads
the PS6 `data/memory.toml` directly). The spike scripts are in the session scratchpad and are not
course code. Notebooks must not state these numbers in text (see §3); they are here so the builder
knows what the figures will show.

**The memory circuit is not stiff.** At the low and high steady states, the three mRNA modes sit near
−0.15/min and the three protein modes near −0.03/min. The ratio is about 5, and the explicit Euler step
limit, 2/|λ|max, is about 13 min.

**No circuit in this model class can be stiff.** In `balances!`, each species depends on its own level
only through its loss term. So the Jacobian's diagonal is minus the loss constants at every state, and
the trace is constant: −0.3631/min for the negative feedback loop at every binding order tested (3, 4,
6, 8). At a stable steady state, no mode can decay faster than the total loss rate. The lecture can use
this argument in plain words to explain why the course model is not stiff and where stiffness comes
from.

**The negative feedback loop oscillates and stresses Euler.** With the L14a config (binding order
n = 3, inducer at its 1 µM baseline):

- The eigenvalues are −0.178 ± 0.0643i (fast) and −0.00323 ± 0.0643i (slow), a decaying oscillation
  with a period of about 100 min.
- For a complex eigenvalue, Euler is stable when Δt < −2 Re λ / |λ|². The slow oscillatory mode sets
  the limit at about 1.56 min; the fast mode would allow 9.9 min.
- Euler from a zero state, last 1000 of 6000 min: at Δt = 1.0 min it settles at the steady state
  (p_Y = 4.19 nmol/gDW). At Δt = 1.7, 2, 3, and 5 min it settles instead on a sustained oscillation
  whose amplitude grows with Δt (at 5 min, p_Y cycles between 2.4 and 9.7). Euler produces an
  oscillation the circuit does not have.
- Raising the binding order to 4 (both regulators) makes the steady state unstable; the circuit then
  oscillates forever (p_Y between 3.3 and 8.6).
- It is not stiff: over 3000 min at reltol 1e-6, abstol 1e-9, `Tsit5` used 2,721 f evaluations,
  `Rodas5P` 6,808, and `FBDF` 3,104 (n = 3).

**The fast-binding variant is stiff.** The spike replaced the equilibrium fraction of Y carrying the
inducer with a complex c (nmol/gDW) and the balance

    dc/dt = k_on I (p_Y − c) − k_off c − (θ_p + μ) c,   k_off = K_I k_on,

with the available repressor a = c. The spike assumed k_on = 60 µM⁻¹ min⁻¹ (10⁶ M⁻¹ s⁻¹), so
k_off = 60/min at K_I = 1 µM. Results:

- The slow behavior matches the equilibrium model to about 0.1% (p_Y at 500, 1000, and 3000 min).
- The eigenvalues are the four of the equilibrium model plus one binding mode at −120/min. The
  stiffness ratio is about 37,000, and the explicit Euler limit is about 0.0167 min (1 s).
- Over 3000 min at the same tolerances: `Tsit5` took 102,688 steps (616,131 f evaluations), `Rodas5P`
  482 steps (7,312), `FBDF` 1,243 steps (3,314), and the default solver 2,364 steps (21,400).
- Wall-clock times in the spike included first-call compilation and an allocating wrapper, so they
  are not evidence. The notebooks compare steps and f evaluations, and time only warmed-up calls if
  they show time at all.

**The package `balances!` rejects dual numbers.** `Rodas5P`, `FBDF`, and the default solver fail with
their default automatic differentiation, and run only with `autodiff = AutoFiniteDiff()`. This is
fixed in the package (§7).

## 6. The meetings

Each lecture has a companion example in the same folder, in the L14a layout (title block, Setup, a
short model section, three tasks, Things to Try, Summary). Each lab has three tasks, student code in
`src/Compute.jl`, supplied figures in `src/Visualize.jl`, and its solution in
`src/solution/Compute-solution.jl`. Students check their functions against the package reference
methods, as in the L6d `my_jacobi` lab.

All hand-written methods use the same right-hand side signature as `ODEProblem`, `f!(dx, x, p, t)`.
The package `balances!` is that function, with the network as `p`. Students then see that the same
`balances!` runs in their own Euler loop and in a DifferentialEquations.jl solve.

### L15a lecture: initial value problems and explicit methods (theory only)

**Superseded by Jeff, 2026-11-25:** the lecture has an intro, Euler, RK, and a Summary ("Intro,
Summary, Euler and RK"). The intro (title block and Examples cell) states the initial value problem;
stability is a subsection of the Euler section; RK4's stability region is one paragraph of the RK
section. The plan carries the final structure. The six-section list below is the original draft.

Sections (six, counting Examples and Summary):

1. **Examples.** The house Examples cell linking the L15a example.
2. **The Initial Value Problem.** ẋ = f(x, u) with x(t₀) = x₀, and u = u(t) for the inducer. The time
   grid t_k = t₀ + kΔt. A one-step method x_{k+1} = x_k + Δt × (a slope estimate). The L14a recursion
   is the linear special case, referred to in words. Opens with the question of how a solver such as
   `Tsit5` steps the memory circuit forward, and says that we write simple methods by hand to
   understand them and use DifferentialEquations.jl in practice.
3. **Explicit Euler.** Derived from the integral form of the step with the slope held at its left
   value. Local error O(Δt²), global error O(Δt), the order of a method, and the step-halving check.
4. **Runge–Kutta Methods.** Several slope samples inside the step. Heun's method as a predictor and a
   corrector, then classical RK4 (the four slopes, in braces). Order four means halving Δt cuts the
   error by about 16. Cost counted in f evaluations per step, and accuracy per unit of cost.
5. **Stability of Explicit Methods.** The test equation ẋ = λx and the amplification factor
   (1 + Δtλ for Euler, the degree-four polynomial for RK4). The stability region. For real λ, Euler
   needs Δt < 2/|λ|; for complex λ, |1 + Δtλ| < 1. The fastest Jacobian eigenvalue (L14a, in words)
   sets the limit. An oscillatory mode makes the limit much tighter: Euler adds amplitude to an
   oscillation at every step. A short definition of stiffness as a forward reference to L15c.
6. **Summary.**

### L15a example: explicit methods on the two circuits

Keep it tight (Jeff, 2026-11-25: "the examples have been too long"): about half of the L14a example,
with no model section of its own.

- **Settings cell:** circuit (memory or negative feedback loop), method (Euler or RK4), Δt, final time,
  and the inducer pulse (the memory circuit needs a pulse to switch on). Pulse edges must fall on the
  time grid; the settings comment says so, and the code checks it.
- **Model section:** short. It points back to L14a in words and shows only what the tasks need. The
  memory circuit's config is the PS6 `memory.toml`, copied into `L15a/config/`.
- **Task 1, Euler and RK4 on the memory circuit:** fixed-step solutions (package reference methods)
  against a `Tsit5` reference solved at a tight tolerance, through a pulse that switches the memory
  on.
- **Task 2, error and cost:** error at a fixed time against Δt on a log–log figure, with the slopes of
  orders one and four, and the f evaluations of each method. The step sizes stay above the floor set by
  the reference tolerance.
- **Task 3, stability:** the package `steady_state` and `jacobian` give the eigenvalues of each circuit
  and the Euler step limit of each mode (the one table, if any). Euler on the negative feedback loop
  just below and just above its limit, against the reference.
- **Things to Try:** raise the negative feedback loop's binding order to 4 (sustained oscillation);
  RK4 above Euler's limit; another pulse.

### L15b lab: write explicit Euler and RK4

Student functions in `src/Compute.jl` (names are the builder's call, `my_` prefix as in L6d), each
with a docstring, steps, and a Hint under every TODO:

- `my_euler_step(f!, x, p, t, Δt)` returns the next state.
- `my_rk4_step(f!, x, p, t, Δt)` returns the next state.
- `my_integrate(step, f!, x0, p, t_start, t_final, Δt)` loops a step function over the grid and
  returns the times and the states.

Tasks:

1. **Euler.** Write the step and the loop. Check against the package Euler to round-off and against
   `Tsit5` on the memory circuit.
2. **RK4.** Write the step. Same checks.
3. **Order and stability.** Measure each method's order from step halving. Find the step where Euler
   produces a false oscillation on the negative feedback loop, and compare it with the step limit
   from the Jacobian eigenvalues. End with the same circuit in one `solve` call, and compare f
   evaluations (`sol.stats`).

Checks are data-independent: they compare against the package and the student's own runs, never
pinned counts.

### L15c lecture: implicit methods, stiffness, adaptive steps, and choosing a solver (theory only)

Sections (six):

1. **Examples.**
2. **Implicit Methods.** Implicit Euler and the trapezoidal rule. Each step solves a nonlinear equation
   for x_{k+1} with Newton's method and the Jacobian, at the cost of a linear solve per iteration. The
   amplification factors 1/(1 − Δtλ) and (1 + Δtλ/2)/(1 − Δtλ/2). Both are stable for every Δt when
   Re λ < 0. Implicit Euler damps an oscillation, while the trapezoidal rule keeps its amplitude. The
   trapezoidal rule applied to the linear model, with the input held over the step, is the bilinear
   discretization of L14a (in words).
3. **Stiffness.** A problem is stiff when stability, not accuracy, sets the explicit step. The spread of
   Jacobian eigenvalues. Why the course model is not stiff (the trace argument of §5, in words), and
   how fast binding adds a mode far from the expression modes. The equilibrium bound fraction used
   since L14a is the slow limit of that binding.
4. **Adaptive Step Size.** An embedded pair estimates the local error from two methods of different
   order (`Tsit5` is a 5(4) pair). The tolerance abstol + reltol·|x|, accept or reject, and the step
   update with a safety factor. An input that jumps needs solver stops, or the solver can step over a
   short pulse.
5. **Choosing a Solver.** One table of DifferentialEquations.jl families: explicit Runge–Kutta
   (`Tsit5`, `Vern7`), Rosenbrock (`Rodas5P`), BDF (`FBDF`, `QNDF`), and the default solver that switches
   when a problem turns stiff, with order, stability, cost per step, and use. When writing your own
   method makes sense. Checking a solution by tightening the tolerance.
6. **Summary.**

### L15c example: the stiff circuit and adaptive solvers

- **Settings cell:** circuit (negative feedback loop, equilibrium or fast binding), solver, tolerances,
  pulse.
- **Task 1, the stiff circuit:** the fast-binding model in Jeff's form plus the one binding balance; its
  eigenvalues (the binding mode far from the expression modes); the same slow behavior as the
  equilibrium model.
- **Task 2, explicit against implicit:** explicit Euler below the binding limit and implicit Euler
  (package reference) at a large Δt; then `Tsit5` against `Rodas5P` and `FBDF`, with the step size
  each solver takes over time and the work counts.
- **Task 3, adaptive steps and pulses:** the step-size trace of `Tsit5` across an inducer pulse; a short
  pulse skipped when the solve has no stops (the builder must show this honestly or drop it); a
  tolerance-tightening check.

### L15d lab: write implicit Euler, then use the library

1. **Implicit Euler.** Students write `my_implicit_euler_step(f!, x, p, t, Δt)` with Newton
   iterations, using the package `jacobian` for the Jacobian. Checked against the package reference.
   Run on the stiff circuit at a step far above the explicit limit.
2. **Solver choice.** The stiff circuit with `Tsit5`, `Rodas5P`, `FBDF`, and the default solver;
   students compare steps and f evaluations from `sol.stats` and explain the result.
3. **The PS6 pattern.** The memory circuit with inducer pulses: students write a solve with solver
   stops at the pulse edges and output every minute, then check it by tightening the tolerance. This
   task is meant to help students finish PS6 (Jeff, 2026-11-25). It helps with the code, not the
   report: the task uses pulses other than PS6's 60-min, 5 µM pulse, does not use the loop-cut
   `memory-no-loop.toml`, and does not scan for the shortest remembered pulse. The shipped solution
   therefore holds the solve pattern but none of the PS6 report numbers. (My call; see §11.)

## 7. Package changes (`code/src`)

1. **Reference fixed-step methods:** explicit Euler, RK4, and implicit Euler with Newton, all taking
   `f!(dx, x, p, t)`, returning the times and the states, and counting f evaluations. Names must not
   clash with OrdinaryDiffEq exports (`solve` and `step!` already clash; `integrate` or method types are
   the builder's call). Documented and commented to the package standard.
2. **Fast inducer binding:** an optional per-regulator binding rate in the network config. When it is
   present, the regulator–inducer complex becomes a state after the proteins,
   `x = [m₁…m_N, p₁…p_N, c…]`, with the balance in §5. The binding needs `n_I = 1`, and the config is
   rejected otherwise. `equations(...)`, `steady_state`, and `jacobian` handle the extra states. Every
   existing config gives exactly the outputs it gives today, and the week-14 suite still passes.
3. **A sourced binding rate (approved by Jeff, 2026-11-25: "use the test tube rate"):** k_off comes from the in vitro time for IPTG to
   dissociate from the lac repressor, 0.8–1 s (BioNumbers BNID 102034, from Dunaway et al., J. Biol.
   Chem. 255:10115, 1980), so k_off ≈ 60/min, and k_on = k_off / K_I from the config. This is the
   spike's value. The variant keeps the assumption the equilibrium model already makes: the inducer
   inside the cell equals the inducer in the medium. Living cells are slower: Elf, Li, and Xie
   (Science, 2007) measured about 851 M⁻¹ s⁻¹ for IPTG binding the repressor–operator complex in
   E. coli, an order of magnitude below the in vitro estimate, and suggested that IPTG's membrane
   permeability limits it. At the micromolar inducer levels of the configs, that rate would put the
   binding mode among the expression modes, and the variant would not be stiff. The L15c example
   states the fast-uptake assumption in one plain sentence. The builder re-runs the stiffness check
   of §5 with the final config.
4. **Generic `balances!`:** accept any number type so that the default automatic differentiation
   works in `Rodas5P`, `FBDF`, and the default solver. Prove every L14a output unchanged.
5. **Configs:** the memory circuit (the PS6 `memory.toml`, already public) and the fast-binding
   negative feedback loop join `code/src/data/motifs/`. Each meeting folder gets a `config/` copy, as
   L14a does.

## 8. Validation and release

- Replace `instructor/validation/week-15/runtests.jl`. It tests the package additions (reference
  methods against known orders, the binding variant against the equilibrium model, rejection of bad
  configs), every notebook's globals after execution, the lab starters (fail on the TODOs) and
  solutions (pass), and that student modules export only student functions. No hardcoded values;
  verify with a copy that changes every setting.
- The week-14 suite must still pass after the package changes.
- Update `weeks/week-15/README.md` and `release.toml`; remove the placeholder notebooks, the
  fermentation lab, and `src/Week15Core.jl`. Labs ship without outputs. Each meeting releases on its
  own (`cadence = "meeting"`, as the current file says), starting with L15a.
- Codex verifies each notebook once, in a read-only sandbox, before Jeff sees it.

## 9. Order of work

1. Package: reference explicit methods, the memory-circuit config, generic `balances!`.
2. L15a lecture, then the L15a example. Jeff reviews.
3. L15b lab. Jeff reviews.
4. Package: fast binding (with the sourced rate and the re-run stiffness check) and implicit Euler.
5. L15c lecture and example, then the L15d lab.
6. Slide decks for L15a and L15c in the L14a template, after each lecture is approved.

## 10. Left to the builder

- Function and type names, file names under the house pattern
  (`CHEME-5800-L15a-Lecture-…-Fall-2026.ipynb`), and notebook titles.
- Figure designs, within the house figure style (see `figure-style-5660-recipe`).
- The exact error measure for the order plots and the step sizes, as long as the measured order is
  clean.
- Whether a derivation outgrows a lecture box and moves to an Advanced notebook, as the L14a
  bilinear stability proof once did.

## 11. Calls made without Jeff (for him to check)

- The CHEME 5820 bridge moves from L15c to L16a, and week 15 does not name S4 or Mamba.
- The environment keeps OrdinaryDiffEq and does not add the DifferentialEquations.jl metapackage.
- The step size is written Δt, following L14a.
- The memory circuit (PS6) carries accuracy and order in L15a/L15b; the negative feedback loop carries
  oscillations and the Euler step limit.
- Students check their methods against package reference methods (the L6d pattern), so the examples
  call the package and the labs re-implement the methods.
- Lab solutions go in `src/solution/Compute-solution.jl`.
- L15d Task 3 follows the PS6 solve pattern with different pulses and no PS6 report runs (§6).
- Slide decks for L15a and L15c come after each lecture is approved.
