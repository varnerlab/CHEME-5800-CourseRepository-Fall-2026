# Notebook style audit — design

**Date:** 2026-08-11
**Status:** approved, pending implementation plan

## Problem

CHEME course notebooks are supposed to share one structure. In practice they drift.
The CHEME-5820 Spring-2026 corpus defines the house style by example, but the style is
recorded only as prose in `rules.md`, so conformance is checked by eye and varies from
notebook to notebook. CHEME-5800 week-01 was authored against a different, looser shape
and does not match.

We want a repeatable audit: given a notebook, report every structural deviation from the
house style, and mechanically repair the deviations that have exactly one correct answer.

## Reference corpus

House style is defined by these five notebooks in
`CHEME-5820-instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/`:

| Notebook | Role | Cells |
|---|---|---|
| `week-1/L1c/…-Lecture-K-means…` | prose lecture | 6 md, 0 code |
| `week-1/L1c/…-Example-K-Means-ConsumerSpending…` | code example | 22 md, 19 code |
| `week-7/L7c/…-Example-Training-SmallBoltzmannMachine…` | code example | 30 md, 22 code |
| `week-8/L8c/…-Example-FNN-ImageClassification…` | code example | 24 md, 16 code |
| `week-16/L16a/…-Example-LavaWorldProblem-Q-Learning…` | code example | 20 md, 13 code |

`rules.md` (and its byte-identical twin `CLAUDE.md`) in that repo is treated as
authoritative where the corpus disagrees with itself.

## Canonical skeleton (code-bearing notebook)

```
TITLE CELL (markdown)
  # <Title>
  <1–3 sentence intro>

  > __Learning Objectives:__
  >
  > By the end of this <lecture|example|lab>, you should be able to:
  > * __Title:__ description        ← exactly 3
  > * __Title:__ description
  > * __Title:__ description

  Let's get started!
  ___

## Background: <…>                  ← optional
  …
  ___

## Setup, Data, and Prerequisites    ← required in code-bearing notebooks
  First, we set up the computational environment by including the `Include.jl`
  file and loading any needed resources.

  > The [`include(...)` command](…) evaluates the contents of the input source
  > file, `Include.jl`, in the notebook's global scope. …

  Let's set up our code environment:
  [CODE] include(joinpath(@__DIR__, "Include.jl")); # include the Include.jl file
  <package / local-src note>
  ### Constants | ### Data | ### Implementation     ← optional
  ___

## <topical heading>  or  ## Task N: <name>
  prose paragraph (context)
  > __Question or heading:__
  >
  > body
  short transition sentence
  [CODE]
  ___

## Summary
  <one direct summary sentence>

  > __Key Takeaways:__
  >
  > * **Title:** explanation        ← exactly 3

  <one concluding sentence>
  ___
```

## Rules

### AUTO — exactly one correct output; the fixer rewrites these

| # | Rule |
|---|---|
| A1 | Horizontal rule glyph is `___`, never `---` or `***` |
| A2 | Every major section is terminated by `___`: as the last line of the section's final **markdown** cell, or as its own markdown cell when the section's final cell is **code**. A *major section* is the title block (everything before the first `##`), plus each `##` heading and the cells following it up to the next `##` or end of notebook. `###`/`####` subsections do not get their own `___`. |
| A3 | Objectives blockquote opens `> __Learning Objectives:__` followed by a blank `>` line |
| A4 | Takeaways blockquote opens `> __Key Takeaways:__` followed by a blank `>` line |
| A5 | Objectives preamble line is `> By the end of this <role>, you should be able to:` where `<role>` ∈ {lecture, example, lab}, chosen from the notebook filename |
| A6 | Every objective and takeaway title ends with a colon **inside** the bold: `__Title:__` or `**Title:**`, never `__Title__:` / `**Title**:` |
| A7 | `Let's get started!` is the last prose line of the title cell, immediately before its `___` |
| A8 | The setup section heading is exactly `## Setup, Data, and Prerequisites` |
| A9 | The include cell reads `include(joinpath(@__DIR__, "Include.jl")); # include the Include.jl file` |

**A6 covers only colon placement.** Bold delimiter style (`__` vs `**`) renders
identically — verified: `__Title:__` and `**Title:**` both produce
`<strong>Title:</strong>`, and intra-title `snake_case` is safe under both. The fixer
therefore accepts either delimiter and never rewrites one into the other. Normalizing it
would create diff churn across two repos for zero reader-visible benefit.

### FLAG — detected mechanically, repaired by hand

| # | Rule |
|---|---|
| F1 | Exactly 3 learning objectives and exactly 3 key takeaways |
| F2 | Every objective and takeaway carries a `Title:` prefix |
| F3 | Summary section = one direct summary sentence, then the takeaways blockquote, then one concluding sentence |
| F4 | A short transition sentence precedes every code cell. Checked mechanically: the cell immediately before a code cell must be markdown, and its last non-blank line must be ordinary prose — not a blockquote line (`>`), not a heading (`#`), not a list item, not `___` |
| F5 | No two consecutive blockquotes without connective prose. Applies both *within* a cell (two `>` blocks separated only by blank lines) and *across* cells (a cell ending in `>` followed by a cell starting with `>`) |
| F6 | No equations (`$…$`, `$$…$$`) inside objectives or takeaways |
| F7 | `$$`/`$` delimiters balanced; every `\begin{…}` has a matching `\end{…}` |
| F8 | A code-bearing notebook has a `## Setup, Data, and Prerequisites` section |
| F9 | The notebook has exactly one H1, and it is the first line of the first cell |
| F10 | Prose states each idea or action directly instead of referring to its position in the notebook or course timeline. Avoid phrases such as “above,” “below,” “previous,” “next cell,” “following cell,” “earlier,” “later,” “in the lecture,” and “the rest of the course.” Use a direct prompt such as “Let's calculate…” when introducing an action. |

**F1 repair policy:** when a notebook has more than three objectives or takeaways,
**merge related items or rewrite the set** so that three items cover the same ground.
Do not silently drop material.

### Explicit non-rules

These are deliberately *not* enforced, to avoid over-reach:

- **H2 section names.** Example notebooks use `## Task N: <name>`; lecture notebooks use
  topical headings. Both are valid. The linter never renames an H2.
- **Bold delimiter style.** See A6.
- **H1 title wording.** `# L1a: <Title>` and `# Example: <Title>` both occur.
- **Cell-level prose length**, beyond the F4/F5 structural checks.

## Architecture

Skill installed at `~/.claude/skills/notebook-style/` so it resolves against both the
5800 and 5820 repositories.

```
~/.claude/skills/notebook-style/
├── SKILL.md         invocation, canon summary, repair workflow for FLAG rules
├── canon.md         the full skeleton + rule catalogue (this document's core)
└── audit.py         linter: checks A1–A9 + F1–F9, reports cell indices
                     --fix applies A1–A9 only; FLAG findings are never auto-edited
```

`audit.py` contract:

- Input: one or more `.ipynb` paths.
- Default: report violations to stdout, one line per finding, as
  `<file>:<cell-index> <RULE-ID> <message>`; exit non-zero if any finding.
- `--fix`: apply AUTO repairs in place, re-run checks, print what changed. FLAG
  findings remain and still cause a non-zero exit.
- The notebook JSON round-trips with `indent=1` and a trailing newline, matching the
  existing on-disk format so diffs stay minimal.

Separating AUTO from FLAG is the core design decision: deterministic rules get
deterministic, byte-identical repairs on every run, and authorial work (writing three
titled objectives, adding transition sentences) stays with a human or the model, with the
linter pointing at the exact cell.

## Scope of first application

The five CHEME-5800 week-01 notebooks:

- `weeks/week-01/L1a/…-Lecture-WorkingWithTypes…`
- `weeks/week-01/L1b/…-Lab-ToolchainSmokeTest…`
- `weeks/week-01/L1c/…-Lab-FirstTestedCalculation…`
- `weeks/week-01/L1d/…-Lab-WorkingWithFloatingPointTypes…`
- `weeks/week-01/L1d/…-Example-Float32Representation…`

Known incoming state: all five use `---` separators, all five have **four** numbered
learning objectives with no titles, all five have three numbered takeaways with no
titles, none has `Let's get started!`, and the setup prose differs across L1a/L1c/L1d.

The 2026-08-11 accuracy-review edits to these notebooks introduced their own violations
(blockquote bodies on the heading line, consecutive blockquotes in L1d). These are in
scope and must not be exempted.

Re-styling the CHEME-5820 corpus is **out of scope**, though the skill will work there.
Running it on 5820 would flag the K-means Lecture's `**Title**:` takeaways (A6).

## Verification

1. `audit.py` is run against the five 5820 reference notebooks and every finding is
   triaged as either a linter bug or genuine corpus drift.

   **Result (2026-08-11):** the first run produced 17 findings and exposed three linter
   bugs — A6 was applied notebook-wide instead of being scoped to the objectives and
   takeaways blocks (it was rewriting ordinary definition bullets); F4 demanded a
   transition sentence between consecutive code cells; and the heading regexes were
   case-sensitive, so `__Key takeaways:__` was reported as a missing block rather than as
   capitalisation drift. After fixing all three, 13 findings remain and all are genuine
   drift. `L16a-Example-LavaWorldProblem-Q-Learning` is fully clean and is the best
   worked reference. The 5820 corpus is not modified.
2. `audit.py` on week-01 before changes reproduces the known incoming state above.
3. After repair, `audit.py` reports zero findings on all five week-01 notebooks.
4. All five notebooks still execute end to end, and
   `instructor/validation/week-01/runtests.jl` still passes 15/15. L1b still fails its
   histogram-flag test by design.
