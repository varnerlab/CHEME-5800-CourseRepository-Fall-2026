# Week 2 — Functions, errors, collections, and defensive programs

Week 2 moves from evaluating expressions to designing small programs with explicit
interfaces. The week is packaged by class meeting, and every meeting-local
`Include.jl` delegates to the single pinned root Julia environment.

## Learning objectives

By the end of the week, students should be able to:

1. define documented Julia functions with explicit input and output behavior;
2. explain interface, method, scope, mutation, early return, and multiple dispatch;
3. use errors, reference cases, and tests to diagnose a numerical program;
4. select arrays, dictionaries, named tuples, sets, and tables by required operation;
5. filter, transform, group, and summarize tabular data; and
6. implement a defensive numerical interface with edge-case and overflow checks.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L2a | Mon. Aug. 31 | Functions, interfaces, mutation, and dispatch | [Lecture](L2a/CHEME-5800-L2a-Lecture-IntroductionToFunctions-Fall-2026.ipynb) |
| L2b | Tue. Sep. 1 | Errors, tests, and debugging a numerical program | [Lab](L2b/CHEME-5800-L2b-Lab-ErrorsTestsDebugging-Fall-2026.ipynb) |
| L2c | Wed. Sep. 2 | Collections, tables, and representation | [Lecture](L2c/CHEME-5800-L2c-Lecture-CollectionsAndTables-Fall-2026.ipynb) · [Hexadecimal/text example](L2c/CHEME-5800-L2c-Example-HexadecimalAndTextRepresentation-Fall-2026.ipynb) |
| L2d | Thu. Sep. 3 | Building a defensive Fibonacci program | [Lab](L2d/CHEME-5800-L2d-Lab-DefensiveFibonacci-Fall-2026.ipynb) |

The hexadecimal notebook is not hidden in an `extensions` folder. It is a
substantive representation example that supports L2c's work with dictionaries,
sets, strings, and iteration.

## Preparation and validation

Install the course environment once from the repository or extracted bundle root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Then validate Week 2 from the authoring-repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-02/runtests.jl
python -m unittest discover -s weeks/week-02/L2b/src -p 'test_*.py'
```

The Python comparison uses only the standard library supplied with Anaconda.
Problem sets and their simultaneously released solutions use separate repositories.

## Source adaptation

- L2a directly adapts the detailed Fall 2025 functions lecture. Its executable
  error demonstration is now caught so the notebook can run deterministically.
- L2b is new for Fall 2026 and uses a residence-time unit defect to distinguish a
  crashing program from a program that silently returns the wrong answer.
- L2c's table workflow is new for the rebalanced course. The full Fall 2025
  hexadecimal/text lab is retained beside it because it provides a richer
  collections and representation example than the earlier short replacement.
- L2d keeps the Fall 2025 defensive-programming objective while replacing the
  comment/uncomment workflow with one deterministic, fully tested interface.

