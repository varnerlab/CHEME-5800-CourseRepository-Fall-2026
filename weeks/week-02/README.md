# Week 2 — Functions, tests, and text representation

Week 2 moves from defining functions to testing numerical interfaces and processing
Unicode text. The week is packaged by class meeting, and every meeting-local
`Include.jl` delegates to the single pinned root Julia environment.

## Learning objectives

By the end of the week, students should be able to:

1. define documented Julia functions with explicit input and output behavior;
2. explain interface, method, scope, mutation, early return, and multiple dispatch;
3. use reference cases, numerical limits, errors, and regression tests to evaluate a function;
4. map ASCII and Unicode characters to decimal and hexadecimal code points;
5. distinguish a Unicode code point from its UTF-8 byte representation; and
6. build and test a tabular character report by iterating safely over a string.

## Class-meeting sequence

| Meeting | Date | Topic | Notebook |
|---|---|---|---|
| L2a | Mon. Aug. 31 | Functions, interfaces, mutation, and dispatch | [Lecture](L2a/CHEME-5800-L2a-Lecture-IntroductionToFunctions-Fall-2026.ipynb) |
| L2b | Tue. Sep. 1 | Testing and strengthening a Fibonacci function | [Lab](L2b/CHEME-5800-L2b-Lab-DefensiveFibonacci-Fall-2026.ipynb) |
| L2c | Wed. Sep. 2 | Hexadecimal numbers and text representation | [Lecture](L2c/CHEME-5800-L2c-Lecture-HexadecimalAndTextRepresentation-Fall-2026.ipynb) |
| L2d | Thu. Sep. 3 | Building and testing a Unicode character table | [Lab](L2d/CHEME-5800-L2d-Lab-UnicodeCharacterTable-Fall-2026.ipynb) |

The meetings form two direct lecture-lab pairs. L2a introduces Fibonacci as a
function interface, and L2b tests and strengthens that interface. L2c introduces
ASCII, Unicode, hexadecimal code points, and UTF-8 strings, and L2d applies those
ideas in a table-building function.

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

The L2a syntax comparison includes small, optional Julia, Python, C, and Octave programs.
The L2b lab also includes an optional Python implementation of the defensive Fibonacci
interface. The Python programs require only Python 3.11 or newer and its standard
library. The C and
Octave examples require their respective local tools.

Problem sets and their simultaneously released solutions use separate repositories.

### In-class work students complete

Both labs ship with incomplete functions that raise a direct implementation error
until students complete the marked sections.

| Meeting | What ships incomplete | Goes green when |
|---|---|---|
| L2b | `fibonacci_sequence` in `L2b/src/Compute.jl` is a stub with three `TODO`s | the student implements validation, allocation, boundary handling, and checked iteration |
| L2d | `character_table` in `L2d/src/Compute.jl` is a stub with three `TODO`s | the student allocates the typed table, adds one row per character, and returns the completed table |

Each lab carries `Compute.jl` for students and `Compute-solution.jl` as the instructor
reference in the same `src/` folder. Each pair uses the same module and public function
names so the files are interchangeable. Both solutions are listed in `release.toml`
under `instructor_only_paths`. `instructor/validation/week-02/runtests.jl` validates
the reference solutions and separately confirms that the student files remain incomplete.

## Source adaptation

- L2a adapts the detailed Fall 2025 functions lecture and uses Fibonacci throughout
  its discussion of interfaces, mutation, and dispatch. Its syntax comparison links
  to matching Julia, Python, C, and Octave examples.
- L2b adapts the former defensive Fibonacci lab into a direct continuation of L2a.
  It begins with a reproducible `Int64` overflow, then implements and tests a guarded
  interface. The optional Python section uses the same documented contract.
- L2c promotes the Fall 2025 hexadecimal and text-representation example to the
  lecture. The material uses ASCII, Unicode, sets, dictionaries, strings, and an
  explicit base-conversion algorithm in one connected example.
- L2d applies the L2c material by building a `DataFrame` with one row per character
  in a technical label. The lab emphasizes direct string iteration, typed empty
  results, and tests for ASCII, Unicode, empty, and invalid inputs.
