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
| L1b | Tue. Aug. 25 | Toolchain check and a first tested calculation | [Lab](L1b/CHEME-5800-L1b-Lab-ToolchainAndFirstCalculation-Fall-2026.ipynb) |
| L1c | Wed. Aug. 26 | Floating-point representation | [Lecture](L1c/CHEME-5800-L1c-Lecture-WorkingWithFloatingPointTypes-Fall-2026.ipynb) · [Float32 example](L1c/CHEME-5800-L1c-Example-Float32Representation-Fall-2026.ipynb) |
| L1d | Thu. Aug. 27 | Building a floating-point report | [Lab](L1d/CHEME-5800-L1d-Lab-FloatingPointReport-Fall-2026.ipynb) |

Meetings follow the course-wide slot convention: **`a` and `c` are lectures (Mon/Wed),
`b` and `d` are labs (Tue/Thu)**.

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
| L1b | `do_you_see_the_histogram` starts `false`, and `ideal_gas_pressure` in `L1b/src/Compute.jl` is a stub with two `TODO`s | the student confirms the plot, then writes the validation and the `P = nRT/V` return |
| L1d | `float64_report` in `L1d/src/Compute.jl` is a stub with four `TODO`s | the student slices the three fields out of the bit pattern and rebuilds the value from them |

L1b and L1d each carry two source files in their `src/` folder:

| File | Purpose |
|---|---|
| `Compute.jl` | Student-facing stub. Defines the module and signature, throws `"Oooops! The `name(...)` function is not implemented yet - we'd better fix that."` |
| `Compute-solution.jl` | Reference solution. Same module name, so the two are drop-in interchangeable. Listed in `instructor_only_paths` so it is not bundled for students. |

`instructor/validation/week-01/runtests.jl` runs the tests against each
`Compute-solution.jl`, and separately asserts that both student-facing `Compute.jl`
files still contain their `TODO` markers and none of the solutions' distinctive
expressions. If that guard fails, a solution has leaked into the student tree.

## Source adaptation

- L1a directly retains and reformats the detailed Fall 2025 treatment of primitive,
  collection, and composite Julia types.
- L1b directly retains the Fall 2025 end-to-end notebook smoke test, including its
  terminal histogram, local `HelloWorld.jl`, and executable tests. Its setup now
  delegates to the one root environment instead of creating a meeting environment.
  The histogram confirmation flag now starts `false` and is asserted by the test
  suite, so **L1b does not pass on a first run until the student flips it**.
- L1c restores the Fall 2025 Wednesday floating-point **lecture**. An earlier Fall 2026
  draft had relabelled that lecture as the L1d lab and invented a new lab for the L1c
  slot, which left week 1 with three labs, one lecture, and a Thursday floating-point
  lab whose lecture had been deleted. The ideal-gas tested calculation from that draft
  is retained, folded into L1b where it follows the toolchain check.
- L1d is a new lab for Fall 2026 in which students turn the L1c decomposition into a
  callable `float64_report` interface. The positional-number, `Float64`, and `Float32`
  development it was previously built from now lives in the L1c lecture, which
  directly retains the Fall 2025 material and its original figure assets. Setup and notebook presentation were
  updated, and the derivations were corrected during a Fall 2026 accuracy review:
  the `Float32` significand formula now matches the code it describes, the sign
  term reads $(-1)^{d}$ rather than $-1^{d}$, the `Float32` range bounds are
  stated as $2^{-126}$ (smallest normal) and $\approx 3.4\times 10^{38}$ (largest
  finite) instead of $\pm 2^{\pm 127}$, and both reconstruction formulas are now
  scoped to finite normalized values. New material covers the reserved exponent
  patterns and two's-complement integers.

