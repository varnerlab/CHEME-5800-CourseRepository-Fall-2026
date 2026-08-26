---
name: notebook-style
description: Audit and repair CHEME course Jupyter notebooks against the house structural style (title block with three learning objectives, Setup section, `___` section terminators, Summary with three key takeaways). Use when asked to "style audit", "check notebook formatting", "conform this notebook", "fix the structure", or when authoring a new CHEME lecture/lab/example notebook that must match the existing corpus.
---

# CHEME notebook style audit

Enforces the structure shared by the CHEME-5800 and CHEME-5820 notebook corpora.
The canonical skeleton and the full rule catalogue are in `canon.md` — **read it before
making any judgment call.** The reference implementation is `audit.py`.

## Workflow

### 1. Report

```bash
python3 ~/.claude/skills/notebook-style/audit.py <notebook.ipynb> [...]
```

Prints one line per finding as `<AUTO|FLAG> cell <n> <RULE> <message>`, exits non-zero if
anything is outstanding. Run this first, always. Never edit before you have the report.

### 2. Repair the mechanical rules

```bash
python3 ~/.claude/skills/notebook-style/audit.py --fix <notebook.ipynb> [...]
```

`--fix` applies only the **AUTO** rules (A1–A12), which have exactly one correct output:
separator glyphs, `___` placement, blockquote headings and their blank `>` line, the
objectives preamble, colon-inside-bold on objective/takeaway titles, `Let's get started!`,
the Setup heading, the canonical include cell, "method" -> "function" in doc links, the
Setup include blockquote and transition line, and bare function-span doc links expanded
to the `[the \`name(...)\` function](url)` form. These repairs are idempotent — running
`--fix` twice changes nothing the second time.

`--fix` never touches **FLAG** rules. It writes JSON back with `indent=1` and a trailing
newline to match the on-disk format, so diffs stay minimal.

### 3. Repair the authorial rules by hand

FLAG findings (F1–F9) need prose written. Work through them in this order:

**F1 — exactly three objectives and three takeaways.** This is the one that takes real
thought. When a notebook has more than three, **merge related items or rewrite the whole
set so three items cover the same ground. Never silently drop material.** Read the
notebook's actual content first; the objectives must be supported by what is really there.

**F2 — every item needs a `Title:` prefix.** Objectives use `* __Title:__ description`,
takeaways use `* **Title:** explanation`. The colon goes inside the bold. Delimiter style
is free — do not rewrite `__` into `**` or vice versa.

**F3 — Summary is three parts**: one direct summary sentence, the takeaways blockquote,
then one concluding sentence about implications or next steps.

**F4 — a transition sentence before every code cell.** Usually short and often a question:
"So what do we see?", "Let's see what we get!", "Do we see what we expect?". A blockquote
must never run straight into a code cell.

**F5 — no consecutive blockquotes.** Put a sentence of connective prose between them.

**F6 — no equations in objectives or takeaways.** Describe the concept in words.

**F7 — LaTeX balance.** Match `$$`/`$`, close every `\begin{}`.

**F8/F9 — structural.** A code-bearing notebook needs a Setup section; the notebook needs
exactly one H1 as the first line of the first cell.

**F18 — no positional forward references.** Replace phrases such as “the cell below,”
“the next cell,” or “the code below” with a direct statement of the action or object.
The rule does not ban ordinary mathematical or physical uses such as “below zero.”

**F19 — a motivation sentence opens every `## Task N:` section.** Say why the previous
result makes this the next step before telling the student what to do. The checker only
catches an opening action imperative (“Open”, “Complete”, …) or a task with no prose at
all — when repairing, read the arc yourself and write the bridge: one or two sentences
grounded in what the notebook actually established, no more.

**F20 — no calls with concrete arguments as link text.** ``[`typemax(Int64)`](url)``
reads as a value in its sentence, so A12's mechanical expansion would be wrong. Reword
the prose so the link names the function — e.g. "exceeds the largest `Int64` value,
which [the `typemax(...)` function](url) returns."

### 4. Verify

Re-run the report until only accepted findings remain, then confirm the notebook still
executes end to end. Formatting changes must not alter behaviour.

## Language rules for anything you write

From the corpus style guide, these govern all generated prose:

- Direct, simple, concise. Avoid adjectives.
- Plain words over writerly framing. Name the thing ("the corrected interface"), never
  a clever noun standing in for it ("the repair", "the ask", "the build"). Jeff flagged
  "the repair" as chippy, 2026-08-26.
- Content must be supported by what is actually in the notebook. Do not invent claims.
- Prefer short blockquote sections over long interpretive paragraphs.
- When unsure, make a section shorter, not longer.
- **Never caption a figure with a bold lead-in line.** A figure goes inline in the prose
  cell of the section it illustrates, with no caption above it — the prose already says
  what it shows, and the description belongs in `alt`. See the Figures section of
  `canon.md`.

## Deliberate non-rules

Do not "fix" these — they are legitimate variation:

- **H2 section names.** Example notebooks use `## Task N: <name>`; lecture notebooks use
  topical headings. Both are correct. Never rename an H2.
- **`## Optional Advanced Material` placement is fixed, not free.** When a lecture has an
  `advanced/` folder the section goes at the end, immediately before `## Summary`, with a
  one-line pointer at the end of `## Examples`; see the Optional Advanced Material section of
  `canon.md`. Do not move it up or fold the links into `## Examples`.
- **Bold delimiter style.** `__x__` and `**x**` render identically. Only colon *placement*
  is enforced.
- **H1 title wording.** `# L1a: <Title>` and `# Example: <Title>` both occur.

## Known corpus drift

The CHEME-5820 reference notebooks are not themselves fully clean. As of 2026-08-11 the
audit reports 13 findings across them, with `L16a-Example-LavaWorldProblem-Q-Learning`
the only fully conforming notebook. Do not treat a 5820 notebook as authoritative over
`canon.md` on a point where they disagree.
