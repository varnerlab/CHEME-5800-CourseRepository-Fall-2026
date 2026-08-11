# Week 3 — Data provenance, recursion, and testable algorithms

Week 3 connects trustworthy data ingestion to algorithmic representation. It is
packaged as one top-level week containing the scheduled class meetings. Every
meeting folder has a local `Include.jl` that delegates to the single root Julia
environment, loads packages, and includes that meeting's source code.

## Learning objectives

By the end of the week, students should be able to:

1. read CSV records and JSON metadata while preserving their distinct roles;
2. inspect provenance before interpreting a dataset;
3. validate schema, uniqueness, numerical domains, and metadata consistency;
4. distinguish an iterative process from a recursive definition;
5. identify base cases, recursive cases, and repeated work;
6. specify sorting through ordering, permutation, and non-mutation properties; and
7. compare transparent teaching algorithms with Julia's production `sort`.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L3a | Mon. Sep. 7 | Labor Day — no class | — |
| L3b | Tue. Sep. 8 | CSV/JSON validation and provenance | [Lab](L3b/CHEME-5800-L3b-Lab-DataValidation-Provenance-Fall-2026.ipynb) |
| L3c | Wed. Sep. 9 | Iteration, recursion, and algorithmic representation | [Lecture](L3c/CHEME-5800-L3c-Lecture-RecursionConcept-Fall-2026.ipynb) · [Fibonacci example](L3c/CHEME-5800-L3c-Example-RecursiveFibonacci-Fall-2026.ipynb) |
| L3d | Thu. Sep. 10 | Sorting algorithms and performance | [Lab](L3d/CHEME-5800-L3d-Lab-AnotherLookAtSorting-Fall-2026.ipynb) · [Bubble-sort algorithm](L3d/CHEME-5800-L3d-Algorithm-Bubblesort-Fall-2026.ipynb) · [Quicksort algorithm](L3d/CHEME-5800-L3d-Algorithm-Quicksort-Fall-2026.ipynb) |

## Folder conventions

- `L3b`, `L3c`, and `L3d` match the identifiers used by the course schedule.
- Notebook roles describe the material rather than impose a fixed split. A meeting
  may use one integrated `Lab`, a `Lecture` with executable code and an `Example`,
  or supporting `Algorithm` and `Derivation` notebooks.
- `data` contains the files used by a meeting, including clearly named invalid
  examples when validation failure is part of the lesson.
- `src` contains the Julia or Python functions used by that meeting.

There are no `fixtures`, `extensions`, or nested generic `lectures`/`lab`
directories for students to interpret. Authoring-only Julia regression tests live
under `instructor/validation/week-03`.

## Data provenance

The L3b fulfillment-shift data are instructor-generated synthetic teaching values, not
experimental observations. [`L3b/data/README.md`](L3b/data/README.md) records the
purpose and SHA-256 digests. The intentionally invalid file is named
`fulfillment-shifts-invalid-example.csv` and lives beside the data contract it violates.

## Preparation and validation

Complete the one-time environment installation from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Then validate Week 3 from that same root:

```bash
julia --startup-file=no --project=. instructor/validation/week-03/runtests.jl
python -m unittest discover -s weeks/week-03/L3b/src -p 'test_*.py'
```

The Python comparison uses only the standard library supplied with Anaconda.

## Source adaptation

L3c directly adapts the Fall 2025 recursion lecture, its executable recursive-power
demonstration, the recursive Fibonacci example, and the original figure assets.
L3d directly adapts the Fall 2025 sorting lab and its Bubble Sort and Quicksort
algorithm notebooks; its benchmark duration is capped for repeatable classroom and
CI execution. L3b and its synthetic data bundle are new for Fall 2026. Problem
sets and their simultaneously released solutions use separate repositories and
are not included here.
