# CHEME notebook canon

Derived from the CHEME-5820 Spring-2026 corpus and its `rules.md`. Where the corpus
disagrees with itself, `rules.md` and the majority reading win.

## Skeleton — code-bearing notebook

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

## Setup, Data, and Prerequisites    ← required when the notebook has code
  First, we set up the computational environment by including the `Include.jl`
  file and loading any needed resources.

  > The [`include(...)` command](https://docs.julialang.org/en/v1/base/base/#include)
  > evaluates the contents of the input source file, `Include.jl`, in the notebook's
  > global scope. The `Include.jl` file sets paths, loads required external packages,
  > etc. For additional information on functions and types used in this material, see
  > the [Julia programming language documentation](https://docs.julialang.org/en/v1/).

  Let's set up our code environment:
  [CODE] include(joinpath(@__DIR__, "Include.jl")); # include the Include.jl file
  <package / local-src note>
  ### Constants | ### Data | ### Implementation     ← optional subsections
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

A **prose lecture** (no code) is the same minus the Setup section, and may carry an
`## Example` section linking to companion notebooks:

```
## Example
Today, we will use the following examples to illustrate key concepts:

> [▶ <Title>](<notebook>.ipynb). <One or two sentences on what the example does.>

Optional advanced notebooks that extend today's material are listed in the
Optional Advanced Material section at the end of this lecture.
___
```

## Optional Advanced Material (CHEME 5660 rule, set 2026-08-16)

When a lecture folder has an `advanced/` directory, the lecture notebook carries a
`## Optional Advanced Material` section, and it lives **at the end, immediately
before `## Summary`** — the same position the deck's "Optional Advanced Material"
frame and the LaTeX notes' section occupy, so the three artifacts stay in the same
order. Rationale (Jeff, 2026-08-16): the advanced notebooks *extend* material the
student has not met yet at the top of the notebook, so at the top they are a list of
unfamiliar titles and at the end they are "where each thread goes next"; and
`## Examples` is the required path, which must not be diluted with optional items.

Shape:

```
## Optional Advanced Material
The notebooks below extend today's material. They are optional and are not
prerequisites for <next lecture>; the [advanced index](advanced/README.md) lists
them with a suggested order.

* [▶ <Title>](advanced/<folder>/<notebook>.ipynb). <One sentence on what it does.>
* [▶ <Title>](advanced/<folder>/<notebook>.ipynb). <One sentence on what it does.>
___
```

Bullets, not blockquotes (F5 forbids consecutive blockquotes, and connective prose
between four links would be padding). Discoverability from the top comes from the
one-line pointer at the end of `## Examples` shown in the skeleton above, not from
listing the optional notebooks there. An in-context link to a single advanced
notebook inside the section it extends (e.g. a derivation notebook next to the
equation it derives) is fine and does not replace the section. Reference
implementations: L2b, L3a, L3b, L4a, L4b lecture notebooks (Fall 2026); L2b shows
the consolidation from scattered pointers. Adding the section to a notebook means
adding (or updating) the deck frame — see the deck rules in
`lectures/templates/vnslides.sty` — and the `advanced/README.md` must list every
notebook the section lists.

## AUTO rules — one correct output, repaired by `--fix`

| # | Rule |
|---|---|
| A1 | Horizontal rule glyph is `___`, never `---` or `***` |
| A2 | Every major section is terminated by `___`: as the last line of the section's final **markdown** cell, or as its own markdown cell when the section's final cell is **code**. A *major section* is the title block (everything before the first `##`) plus each `##` heading and its following cells up to the next `##`. `###`/`####` subsections get no `___`. |
| A3 | Objectives blockquote opens `> __Learning Objectives:__` then a blank `>` line |
| A4 | Takeaways blockquote opens `> __Key Takeaways:__` then a blank `>` line |
| A5 | Objectives carry a preamble line between heading and bullets. If absent, insert `> By the end of this <role>, you should be able to:` with role from the filename. Existing preamble wording is never rewritten. |
| A6 | Objective and takeaway titles end with a colon **inside** the bold: `__Title:__` / `**Title:**`, never `__Title__:` / `**Title**:`. **Scoped to the objectives and takeaways blockquotes only.** |
| A7 | `Let's get started!` is the last prose line of the title cell, immediately before its `___` |
| A8 | Setup heading is exactly `## Setup, Data, and Prerequisites` |
| A9 | The include cell reads `include(joinpath(@__DIR__, "Include.jl")); # include the Include.jl file` |
| A10 | Documentation links say **function**, not "method": `[the \`typeof(...)\` function](url)`. In Julia a *method* is one signature of a function; the docs document the function. |
| A11 | The Setup section contains the canonical `include(...)` blockquote and the line `Let's set up our code environment:` before the include cell |
| A12 | A doc link whose text is only a function **reference** span — literal ``` `name(...)` ``` — reads ``[the `name(...)` function](url)``: the article and the word "function" sit inside the link (rule set 2026-08-26; the Documentation links section below prescribed the form from the start, but nothing enforced it). ``[`pretty_table(...)`](url)`` is auto-expanded, with "The" when the link opens a sentence, cell, table cell, list item, or blockquote line. Link text already carrying other words (`command`, `package`, `standard library`, `function`, …) is left alone — the canonical include blockquote's ``[`include(...)` command]`` stays. A span with concrete arguments falls to F20. |

### Why A6 is colon-only

`__x__` and `**x**` produce identical HTML:

```
__Title:__  →  <strong>Title:</strong>   ┐ identical
**Title:**  →  <strong>Title:</strong>   ┘

__Title__:  →  <strong>Title</strong>:   ┐ identical
**Title**:  →  <strong>Title</strong>:   ┘
```

Only the colon's position is reader-visible (bold colon vs plain). Normalising the
delimiter would churn source across two repos for zero benefit, so it is not a rule.

### Why A6 is scoped

Body blockquotes contain definition bullets whose bold is a *term*, not a title:

```
> * **K-means++**: Select initial centroids using probabilistic sampling …
> * __Convergence guarantee__: K-means is guaranteed to converge …
```

Pulling the colon inside the bold there would be wrong. A6 applies only inside the
objectives and takeaways blockquotes.

## FLAG rules — detected, repaired by hand

| # | Rule |
|---|---|
| F1 | Exactly 3 learning objectives and exactly 3 key takeaways. When there are more, **merge or rewrite** so three items cover the same ground — never silently drop material. |
| F2 | Every objective and takeaway carries a `Title:` prefix |
| F3 | Summary = one direct summary sentence, the takeaways blockquote, one concluding sentence |
| F4 | A short transition sentence precedes every code cell. Checked as: the preceding cell is markdown and its last non-blank line is ordinary prose — not a blockquote (`>`), heading, list item, or `___`. Consecutive code cells are exempt. |
| F5 | No two consecutive blockquotes without connective prose — both within a cell and across adjacent cells |
| F6 | No equations inside objectives or takeaways |
| F7 | `$$`/`$` balanced; every `\begin{…}` has a matching `\end{…}` |
| F8 | A code-bearing notebook has a `## Setup, Data, and Prerequisites` section |
| F9 | Exactly one H1, and it is the first line of the first cell |
| F10 | Each learning objective is two to three **complete sentences** in the claim–mechanism–implication shape: the ability, the mechanism as the notebook actually does it, then why it matters or where it recurs (JV ratified the thorough shape 2026-08-27; week-02 is the reference). Never a fragment. |
| F11 | Each key takeaway is two to three **complete sentences** in the same claim–mechanism–implication shape as F10. Every mechanism named must be supported by what the notebook actually does. |
| F12 | A function named as a code span is linked to its docs somewhere in the notebook. Two forms are detected: `` `name(...)` `` anywhere, and a bare `` `name` `` **used as the subject of a verb** ("`filter` returns selected rows") when `name` appears in `julia-functions.txt`. Functions and types the notebook defines itself are exempt. |

### Why the bare-name check is verb-anchored

A bare `` `name` `` span is ambiguous — it may be a function, a variable, or a type.
Flagging every one produced three false positives for every real finding:

| Text | Verdict |
|---|---|
| "``filter`` **returns** selected rows" | real — subject of a verb |
| "Python's built-in ``float`` **type**" | false — a Python type, not a Julia call |
| "Any ``isbits`` **value**" | false — used as a modifier |
| "sets are ``unique`` **but** …" | false — an adjective |

Requiring a following verb separates them cleanly. `julia-functions.txt` beside this
file holds the 794 known function names, generated from `names(Base)`, `Statistics` and
`DataFrames` filtered to `Function` bindings, with names too generic to be meaningful in
prose (`in`, `get`, `run`, `map`, `sum`, `length`, …) removed. Regenerate it if the
course adds packages whose functions should be linked.
| F13 | A multi-statement code cell that mutates an object at global scope (a field assignment, or the same name bound twice) is wrapped in `let ... end`. A block of **distinct constant assignments is exempt** — wrapping it would hide the names from later cells. |
| F14 | When a cell is `name = let ... end`, the prose immediately above names the variable and its type as `` `name::Type` `` — e.g. "the `X::Array{Float64,2}` variable holds the concentration profile" |
| F15 | A markdown note follows the include cell, saying which packages and local source files were loaded and linking their documentation. A bare `___` does not count. |
| F16 | **A lab must ship something incomplete for students to finish in class.** Satisfied by a stub marker in a sibling `src/` file, or by a `TODO` addressed to the student in a notebook code cell. Applies only to notebooks whose filename contains `-Lab-`. |
| F17 | No em dashes (U+2014) in markdown prose. Reword with paired commas, parentheses, a colon, a semicolon, or a sentence break. En dashes in numeric ranges and name compounds (`Cont–Kukanov–Stoikov`) stay. The CHEME-5820 corpus predates this rule and still contains them; do not treat that as license. |
| F18 | No positional forward references to later notebook content, such as “the cell below,” “the next cell,” “the following cell,” or “the code below.” Name the action or object directly so prose remains correct when cells move. Ordinary mathematical or physical uses such as “below zero” are allowed. |
| F19 | A `## Task N:` section opens with at least one **motivation sentence** — why the previous result makes this the next step — before any instruction, blockquote, table, list, or code (rule set 2026-08-26). The checker catches only the mechanical signals: no prose at all before the first non-prose construct, or a first sentence starting with an action imperative (`Open`, `Complete`, `Run`, …). Rhetorical imperatives (`Consider`, `Recall`, `Suppose`) do not flag. The heuristic under-detects — when repairing, read the arc and judge whether the opening actually motivates. |
| F20 | A doc link whose text is a call with **concrete arguments** — ``[`typemax(Int64)`](url)`` — reads as a value in its sentence, so A12's expansion would be wrong ("the value exceeds the `typemax(Int64)` *function*"). No mechanical rewrite is safe: reword the prose by hand so the link names the function as ``[the `name(...)` function](url)`` (rule set 2026-08-26). |
| F21 | A prose sentence never opens with a backticked code span — "`` `Int(c)` `` does exactly that" and "`` `Float16` `` halves the width" both lead with code where the prose should name the thing: "The `` `Int(...)` `` constructor does exactly that", "The `` `Float16` `` type halves the width" (rule set 2026-08-28 for function spans, tightened to all spans the same day). This is the unlinked cousin of A12, which puts "The" inside a linked span that opens a sentence. Checked at line starts (after blockquote and list markers) and after sentence-ending punctuation. Two openers stay legal: a span immediately followed by a colon is a definition entry — the Input/Output/Errors contract form `` `name::Type` ``: description — and a span that is the entire line is a display, not a sentence. Linked spans fall under A12/F20. |

## Labs: students must do something

Every lab is a 50-minute meeting in which students write code. A lab that only reads
and runs pre-written code is not a lab, no matter how clean it is. This is course
policy, and F16 enforces it.

**The two-file convention.** A lab's `src/` folder carries both files side by side:

| File | Contents |
|---|---|
| `Compute.jl` | Student-facing. Module, signature, docstring, `# TODO:` comments describing what to write, and a throw at the end. |
| `Compute-solution.jl` | Reference solution. **Same module name**, so the two are drop-in interchangeable. |

Declare the solution in the week's `release.toml` under `instructor_only_paths` so it is
not bundled for students. The week's `runtests.jl` should include the solution rather
than `Include.jl`, and should separately assert that the student file still contains its
`TODO` markers and none of the solution's distinctive expressions — that guard catches a
solution leaking into the student tree.

**The throw.** House style, carried over from the 2025 labs:

```julia
throw(ErrorException("Oooops! The `name(...)` function is not implemented yet - " *
                     "we'd better fix that."))
```

**Sizing.** Fifty minutes, shared with discussion and setup, so scope one function or
one clearly bounded piece of one. Give students the scaffolding — types, signature,
helper functions, the test set that acts as the specification — and have them write the
body. A lab that requires building a whole program from nothing is mis-sized.

**The notebook must say what to write.** A stub in `src/` is not discoverable on its
own. The lab needs a section that names the file, lists what each `TODO` expects, and
points at the test cell as the definition of done.

## Writing the prose

The rules above catch structure. They cannot catch a lab that is technically
conforming and still bad to read. When writing or reviewing body prose:

- **Show the governing equation.** If the notebook computes something from a physical
  or mathematical relation, that relation appears as display math, with every symbol
  defined and its units given. A lab that names a quantity only in prose has skipped
  the step that makes the code checkable.
- **Give the notebook a narrative arc.** A section is not a heading followed by one
  sentence and a code cell. Each section should say what question it is answering, why
  the previous result made it the next question, and what to watch for in the output.
  F19 enforces the Task-section case: one motivation sentence before the first
  instruction. Jeff, 2026-08-26: "one motivation sentence in each task would go a long
  way to making the notebooks have a better (and easier to understand) arc."
- **A lab is not a novel.** Add substance, not volume. If a paragraph does not tell the
  reader something they need in order to run or interpret the next cell, cut it.
- **Name variables with their types in the prose.** "We store the result in the
  `pressure_Pa::Float64` variable" beats "we store the result".
- **Be honest about what a check establishes.** If a reference value was derived from
  the same formula being tested, say so rather than presenting it as independent
  confirmation.

## Figures

A figure goes inline in the prose cell of the section it illustrates, positioned next to
the sentence that describes what it draws. It does not get a markdown cell of its own,
and it does not open a section ahead of that section's heading.

**No caption line.** Do not introduce a figure with a bold lead-in such as
`__A zero-coupon Treasury bill as dated, signed cash flows.__ The investor pays …`.
This is a notebook, not a paper: the prose immediately above the figure has already said
what the figure shows, so a caption restates it, and a rendered notebook gives the bold
line the visual weight of a heading it has not earned. Let the surrounding prose carry
the explanation and put the description in the `alt` attribute, where it does real work
for screen readers.

```
A T-bill has two cash-flow events from the investor's perspective: the purchase
price $-V_B$ at time $0$ and the face-value receipt $+V_P$ at maturity.

<div>
    <center>
        <img src="figs/Fig-L2a-TBill-CashFlows.svg" width="505" alt="Timeline for a
             zero-coupon Treasury bill showing its purchase price today and par-value
             payment at maturity"/>
    </center>
</div>

$$ … $$
```

Leave a blank line on both sides of the `<div>` block. A `$$` display or a paragraph
opening immediately after `</div>` with no blank line between them will not render.

## Documentation links

Write links as ``[the `name(...)` function](url)`` — backticked name, the word
"function", with a little of the surrounding sentence carrying the link. Prefer the
**manual** sections over the terse keyword entries for teaching material.

| Thing | URL |
|---|---|
| `typeof` | `https://docs.julialang.org/en/v1/base/base/#Core.typeof` |
| `sizeof` | `https://docs.julialang.org/en/v1/base/base/#Base.sizeof-Tuple%7BType%7D` |
| `bitstring` | `https://docs.julialang.org/en/v1/base/numbers/#Base.bitstring` |
| `isprimitivetype` | `https://docs.julialang.org/en/v1/base/base/#Base.isprimitivetype` |
| `reinterpret` | `https://docs.julialang.org/en/v1/base/arrays/#Base.reinterpret` |
| `Int` / `Bool` / `UInt32` | `…/base/numbers/#Core.Int`, `#Core.Bool`, `#Core.UInt32` |
| `struct` | `https://docs.julialang.org/en/v1/manual/types/#Composite-Types` |
| `mutable struct` | `https://docs.julialang.org/en/v1/manual/types/#Mutable-Composite-Types` |
| `new` / inner constructors | `https://docs.julialang.org/en/v1/manual/constructors/#man-inner-constructor-methods` |
| `let` | `https://docs.julialang.org/en/v1/base/base/#let` |
| `include` | `https://docs.julialang.org/en/v1/base/base/#include` |

All verified live 2026-08-11. Check any new anchor before using it — the anchor must
appear as an `id="..."` in the page.

## Non-rules

- H2 section names (topical vs `## Task N:`) — never renamed
- Bold delimiter style — see A6
- H1 title wording — `# L1a: <Title>` and `# Example: <Title>` both occur
- Prose length beyond the F4/F5 structural checks

## Reference corpus

`CHEME-5820-instances/Spring-2026/CHEME-5820-Lectures-Spring-2026/lectures/`

| Notebook | Role | Audit status 2026-08-11 |
|---|---|---|
| `week-16/L16a/…-Example-LavaWorldProblem-Q-Learning…` | code example | **clean — best reference** |
| `week-8/L8c/…-Example-FNN-ImageClassification…` | code example | 3 findings |
| `week-7/L7c/…-Example-Training-SmallBoltzmannMachine…` | code example | 5 findings |
| `week-1/L1c/…-Example-K-Means-ConsumerSpending…` | code example | 3 findings |
| `week-1/L1c/…-Lecture-K-means…` | prose lecture | 2 findings |

Prefer L16a when you need a worked example of the canon.
