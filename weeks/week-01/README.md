# Week 1 — Primitive types, data representations, and floating point

Week 1 begins after the toolchain has been verified in
[Week 0](../week-00/README.md). The instructional sequence now has one job per
meeting: inspect primitive values, choose compound representations, understand
floating-point storage, and build a report from that representation.

## Learning objectives

By the end of the week, students should be able to:

1. inspect primitive values by type, storage size, and bit pattern;
2. distinguish character code points from stored character bytes;
3. choose tuples, arrays, sets, and dictionaries by the operations required;
4. explain and report how floating-point representation affects precision and comparison.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L1a | Mon. Aug. 24 | Values and primitive Julia types | [Lecture](L1a/CHEME-5800-L1a-Lecture-WorkingWithTypes-Fall-2026.ipynb) |
| L1b | Tue. Aug. 25 | Choosing and building data representations | [Lab](L1b/CHEME-5800-L1b-Lab-ChoosingDataRepresentations-Fall-2026.ipynb) |
| L1c | Wed. Aug. 26 | Floating-point representation | [Lecture](L1c/CHEME-5800-L1c-Lecture-WorkingWithFloatingPointTypes-Fall-2026.ipynb) · [Float32 example](L1c/CHEME-5800-L1c-Example-Float32Representation-Fall-2026.ipynb) |
| L1d | Thu. Aug. 27 | Building a floating-point report | [Lab](L1d/CHEME-5800-L1d-Lab-FloatingPointReport-Fall-2026.ipynb) |

Meetings follow the course-wide slot convention: **`a` and `c` are lectures
(Mon/Wed), `b` and `d` are labs (Tue/Thu)**.

## Preparation and validation

Complete the required Week 0 system check before L1a. The course environment is
installed once from the repository or extracted-bundle root:

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

L1b is a guided prediction-and-modification lab whose final check passes after its
examples run. L1d ships deliberately red and stays that way until the student
implements the floating-point report.

| Meeting | What ships incomplete | Goes green when |
|---|---|---|
| L1d | `float64_report` in `L1d/src/Compute.jl` is a stub with four `TODO`s | the student slices the three fields out of the bit pattern and rebuilds the value from them |

L1d carries two source files in its `src/` folder:

| File | Purpose |
|---|---|
| `Compute.jl` | Student-facing stub. Defines the module and signature, then throws the course's not-implemented error. |
| `Compute-solution.jl` | Reference solution. Uses the same module name and is excluded from the student bundle. |

## Source adaptation

- L1a retains the current Fall 2026 primitive-type development through characters
  and now ends before collections. Its opening objectives and summary match the
  narrower lecture boundary.
- L1b contains the former second half of L1a, reframed as a lab with three tasks,
  prediction and modification checkpoints, and an executable representation
  check. It introduces representation choice and
  mutability; Week 2 retains responsibility for table operations, grouping, and
  summarization.
- The former L1b toolchain smoke test now lives in required Week 0 onboarding. Its
  ideal-gas calculation is preserved there as an explicitly optional bridge rather
  than being required before the Week 2 functions and testing sequence.
- L1c and L1d retain the corrected Fall 2026 floating-point lecture/lab sequence.
  L1c develops positional representation, normalized floating-point values,
  reserved exponent patterns, and two's-complement integers. L1d turns that
  decomposition into the callable `float64_report` interface.
