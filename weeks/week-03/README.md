# Week 3 — Stacks, queues, recursion, and testable algorithms

Week 3 connects disciplined data structures to the algorithms that rely on them.
It is packaged as one top-level week containing the scheduled class meetings.
Every meeting folder has a local `Include.jl` that delegates to the single root
Julia environment, loads packages, and includes that meeting's source code.

## Learning objectives

By the end of the week, students should be able to:

1. explain last-in-first-out and first-in-first-out access disciplines and choose between them;
2. operate array-backed stacks and queues through a public interface with a private implementation;
3. recognize the call stack, parser delimiter checks, and search frontiers as stacks and queues at work;
4. distinguish an iterative process from a recursive definition;
5. identify base cases, recursive cases, and repeated work;
6. complete and verify a bubble-sort implementation against a reference ordering; and
7. compare transparent teaching algorithms with Julia's production `sort`.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L3a | Mon. Sep. 7 | Labor Day — no class | — |
| L3b | Tue. Sep. 8 | Stacks and queues | [Lecture](L3b/CHEME-5800-L3b-Lecture-StacksAndQueues-Fall-2026.ipynb) |
| L3c | Wed. Sep. 9 | Iteration, recursion, and algorithmic representation | [Lecture](L3c/CHEME-5800-L3c-Lecture-RecursionConcept-Fall-2026.ipynb) · [Fibonacci example](L3c/CHEME-5800-L3c-Example-RecursiveFibonacci-Fall-2026.ipynb) |
| L3d | Thu. Sep. 10 | Sorting algorithms and performance | [Lab](L3d/CHEME-5800-L3d-Lab-AnotherLookAtSorting-Fall-2026.ipynb) · [Bubble-sort algorithm](L3d/CHEME-5800-L3d-Algorithm-Bubblesort-Fall-2026.ipynb) · [Quicksort algorithm](L3d/CHEME-5800-L3d-Algorithm-Quicksort-Fall-2026.ipynb) |

With the Monday holiday, the Tuesday slot carries this week's first lecture
rather than a lab. Stacks and queues need a full session here because the
week-4 graph-search algorithms consume them as building blocks: the L3b call
stack sets up the L3c recursion lecture, recursion powers the L3d quicksort,
and the queue returns as the breadth-first search frontier.

## Folder conventions

- `L3b`, `L3c`, and `L3d` match the identifiers used by the course schedule.
- Notebook roles describe the material rather than impose a fixed split. A meeting
  may use one integrated `Lab`, a `Lecture` with executable code and an `Example`,
  or supporting `Algorithm` and `Derivation` notebooks.
- `L3d/sounds` holds the optional bubble-sort tone library described in
  [`L3d/sounds/README.md`](L3d/sounds/README.md).
- `src` contains the Julia functions used by that meeting.

There are no `fixtures`, `extensions`, or nested generic `lectures`/`lab`
directories for students to interpret. Authoring-only Julia regression tests live
under `instructor/validation/week-03`.

## In-class work students complete

The L3d lab ships an incomplete function that raises a direct implementation
error until students complete the marked sections.

| Meeting | What ships incomplete | Goes green when |
|---|---|---|
| L3d | `bubblesort!` in `L3d/src/Compute.jl` is a stub with three `TODO`s | the student implements the passes, the neighbor swap, and the early exit |

The lab carries `Compute.jl` for students and `Compute-solution.jl` as the
instructor reference in the same `src/` folder. Both declare the `L3dSorting`
module, so the files are drop-in interchangeable. The solution is listed in
`release.toml` under `instructor_only_paths`.
`instructor/validation/week-03/runtests.jl` validates the reference solution and
separately confirms that the student file remains incomplete.

## Preparation and validation

Complete the one-time environment installation from the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Then validate Week 3 from that same root:

```bash
julia --startup-file=no --project=. instructor/validation/week-03/runtests.jl
```

## Source adaptation

The L3b stacks-and-queues lecture is new for Fall 2026. L3c directly adapts the
Fall 2025 recursion lecture, its executable recursive-power demonstration, the
recursive Fibonacci example, and the original figure assets. L3d directly adapts
the Fall 2025 sorting lab and its Bubble Sort and Quicksort algorithm notebooks;
its benchmark duration is capped for repeatable classroom and CI execution, and
its student-completed `bubblesort!` stub with the optional tone library adapts
the Fall 2024 bubble-sort discussion lab. Problem sets and their simultaneously
released solutions use separate repositories and are not included here.
