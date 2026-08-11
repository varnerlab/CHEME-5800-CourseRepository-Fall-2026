# Week 1 — Values, types, tools, and a first tested calculation

Week 1 establishes the working pattern used throughout CHEME 4800/5800:

> represent a problem, compute a result, test the result, and interpret what it means.

The week is packaged by scheduled class meeting. Every meeting has a local
`Include.jl` that activates the single pinned root environment, loads the packages
used by that meeting, and includes its local source code.

## Learning objectives

By the end of the week, students should be able to:

1. inspect primitive, collection, and composite types and their representations;
2. run a Julia notebook and local source code from beginning to end;
3. translate an engineering equation and unit contract into a tested function;
4. use `Test`, `@test`, `@test_throws`, and `isapprox`; and
5. explain how floating-point representation affects precision and comparison.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L1a | Mon. Aug. 24 | Values, expressions, and Julia types | [Lecture](L1a/CHEME-5800-L1a-Lecture-WorkingWithTypes-Fall-2026.ipynb) |
| L1b | Tue. Aug. 25 | Toolchain and notebook smoke test | [Lab](L1b/CHEME-5800-L1b-Lab-ToolchainSmokeTest-Fall-2026.ipynb) |
| L1c | Wed. Aug. 26 | First tested engineering calculation | [Lab](L1c/CHEME-5800-L1c-Lab-FirstTestedCalculation-Fall-2026.ipynb) |
| L1d | Thu. Aug. 27 | Floating-point representation and behavior | [Lab](L1d/CHEME-5800-L1d-Lab-WorkingWithFloatingPointTypes-Fall-2026.ipynb) · [Float32 example](L1d/CHEME-5800-L1d-Example-Float32Representation-Fall-2026.ipynb) |

There are no generic `lectures`, `lab`, `fixtures`, or `extensions` directories.
Notebook roles describe the material actually used in a meeting.

## Preparation and validation

Install the course environment once from the repository or extracted bundle root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Then validate Week 1 from the authoring-repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-01/runtests.jl
```

Problem sets and their simultaneously released solutions use separate repositories
and are not included in this weekly instructional unit.

### In-class work students complete

Two notebooks ship deliberately red and stay that way until a student does something.
This is intentional; do not "fix" it.

| Meeting | What ships incomplete | Goes green when |
|---|---|---|
| L1b | `do_you_see_the_histogram` starts `false` and is asserted | the student looks at the plot and sets it `true` |
| L1c | `ideal_gas_pressure` in `L1c/src/Compute.jl` is a stub with two `TODO`s | the student writes the validation loop and the `P = nRT/V` return |

L1c therefore carries two source files in `L1c/src/`:

| File | Purpose |
|---|---|
| `Compute.jl` | Student-facing stub. Defines the module and signature, throws `"Oops! The ideal_gas_pressure(...) method has not been implemented yet."` |
| `Compute-solution.jl` | Reference solution. Same module name, so the two are drop-in interchangeable. Listed in `instructor_only_paths` so it is not bundled for students. |

`instructor/validation/week-01/runtests.jl` runs the engineering-calculation tests
against `Compute-solution.jl`, and separately asserts that the student-facing
`Compute.jl` still contains its `TODO` markers and does **not** contain the solution's
return expression. If that guard fails, a solution has leaked into the student tree.

## Source adaptation

- L1a directly retains and reformats the detailed Fall 2025 treatment of primitive,
  collection, and composite Julia types.
- L1b directly retains the Fall 2025 end-to-end notebook smoke test, including its
  terminal histogram, local `HelloWorld.jl`, and executable tests. Its setup now
  delegates to the one root environment instead of creating a meeting environment.
  The histogram confirmation flag now starts `false` and is asserted by the test
  suite, so **L1b does not pass on a first run until the student flips it**.
- L1c is new for Fall 2026 because the rebalanced sequence calls for a tested
  engineering calculation during the first week.
- L1d directly retains the Fall 2025 positional-number, `Float64`, and `Float32`
  development and its original figure assets. Setup and notebook presentation were
  updated, and the derivations were corrected during a Fall 2026 accuracy review:
  the `Float32` significand formula now matches the code it describes, the sign
  term reads $(-1)^{d}$ rather than $-1^{d}$, the `Float32` range bounds are
  stated as $2^{-126}$ (smallest normal) and $\approx 3.4\times 10^{38}$ (largest
  finite) instead of $\pm 2^{\pm 127}$, and both reconstruction formulas are now
  scoped to finite normalized values. New material covers the reserved exponent
  patterns and two's-complement integers.

