# Week 5 natural-language pass

Completed September 19, 2026, following the approach in the
[CHEME 5660 handoff](../../../CHEME-5660-CourseRepository-Fall-2026/lectures/instructor/WEEK-5-NATURAL-LANGUAGE-HANDOFF.md)
and the shared notebook style guide. This was an authorized wording pass.
The existing notebook reviews remain closed; their scores and hashes describe
the snapshots recorded at the time of those reviews.

## Scope and changes

Reviewed all 40 `.ipynb`, `.md`, `.jl`, and `.tex` files under
`weeks/week-05`: seven notebooks, both companion slide sources, helper and
data references, Julia comments and docstrings, and figure sources. Figure
labels and edge-list comments were also inspected.

Applied 64 localized wording replacements in 17 source files: all seven
notebooks, two slide sources, four Markdown references, and four Julia files.
The edits restore articles and verbs, clarify the subjects of sentences, and
make units descriptions read naturally. Examples include:

- “The larger ratio receives the budget” became “We spend the budget on the
  fruit with the larger ratio.”
- “flows, capacities, and F use the same units” became “flows, capacities,
  and F are measured in the same units,” retaining the original mathematical
  notation.
- “We used basis linear systems…” became “We solved linear systems involving
  the basis matrix…”.

The explanations, worked examples, lab tasks, student TODOs, and reference
implementations retain their scope. Notebook Markdown grew from 18,937 to
19,030 whitespace-delimited words, about 0.5%. Two horizontal rules after the
final L5a Summary sections were removed to meet the repository agreement;
the other section boundaries and all headings are preserved.

Rebuilt the [L5a slides](../../weeks/week-05/L5a/slides/CHEME-5800-L5a-Slides-Fall-2026.pdf)
and [L5c slides](../../weeks/week-05/L5c/slides/CHEME-5800-L5c-Slides-Fall-2026.pdf)
with their existing design and build tools.

## Verification

- All seven notebooks pass nbformat validation and retain exactly three
  learning objectives and three key takeaways. All 48 code cells, outputs,
  execution counts, cell identifiers, and metadata are unchanged.
- All 65 displayed notebook equations are unchanged and render with the
  installed VS Code notebook math renderer. The displays and their surrounding
  explanations were visually inspected. A second renderer gives the same
  results before and after this pass, including its existing display-delimiter
  findings; neither renderer reports a KaTeX error.
- Notebook captures show readable text, equations, tables, and linked lecture
  figures, with no horizontal overflow in the captured sections. The in-app
  browser was unavailable; captures used an isolated temporary Chrome profile
  with HTTP and HTTPS requests blocked.
- All 105 local link and image targets checked in notebook Markdown and
  Markdown reference files resolve. Link targets are unchanged.
- Julia differences are confined to docstrings. Removing docstrings leaves
  byte-identical source; no numerical rerun was needed.
- Slide equations, frame structure, and figure references are unchanged.
  L5a remains 23 pages and L5c remains 30. All 12 pages with changed text were
  rendered and visually checked. Neither build reports an overfull or
  underfull box; the existing unicode-math package warnings remain.
- `git diff --check` passes. No commit, push, release, or student-bundle
  rebuild was performed.

Local evidence is in `build/week-05-natural-language-2026-09-19/`: baseline
copies, exact before/after replacements, notebook hashes and preservation
checks, HTML previews, notebook captures, slide comparisons, and build logs.

## Notebook snapshots after this pass

| Notebook | SHA-256 |
| --- | --- |
| [CHEME-5800-L5a-Lecture-MaximumFlowProblems-Fall-2026](../../weeks/week-05/L5a/CHEME-5800-L5a-Lecture-MaximumFlowProblems-Fall-2026.ipynb) | `ecbabd9d765a5b3f32ef44b9b4a2a16910bc71da5b6d123ce4b151be02b2ad62` |
| [CHEME-5800-L5a-WorkedExample-MaximumFlow-Fall-2026](../../weeks/week-05/L5a/CHEME-5800-L5a-WorkedExample-MaximumFlow-Fall-2026.ipynb) | `c220aac5cd525a08e672056c5d500e8246e74e272378ec295a368daf19a93aca` |
| [CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026](../../weeks/week-05/L5b/CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb) | `9f34504ff62ccdba35df16641b553b5d0e3cb1144bf7dcef5c09c14e146982fd` |
| [CHEME-5800-L5c-Algorithm-RevisedSimplex-Fall-2026](../../weeks/week-05/L5c/CHEME-5800-L5c-Algorithm-RevisedSimplex-Fall-2026.ipynb) | `936da6e3241460c56dd20e0d30992dfd899af10844009f761ff011c2808fdf30` |
| [CHEME-5800-L5c-Example-FruitAllocation-Fall-2026](../../weeks/week-05/L5c/CHEME-5800-L5c-Example-FruitAllocation-Fall-2026.ipynb) | `102e089476121f05452ce743d35c1f36ddeee2b3619778c358d6b724fdb30d72` |
| [CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026](../../weeks/week-05/L5c/CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb) | `c6c31d47050e3552a7e0613f2bdb7d1d2e214fa0fdbd4f96f7b25fd750022d2b` |
| [CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026](../../weeks/week-05/L5d/CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb) | `182028f62619b143067aad766b080c49df9ea6bb274eebe9108269efdf1a21ac` |
