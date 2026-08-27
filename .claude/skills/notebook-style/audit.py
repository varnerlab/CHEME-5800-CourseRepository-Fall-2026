#!/usr/bin/env python3
"""Audit (and optionally repair) CHEME course notebooks against the house style.

AUTO rules (A*) have exactly one correct output and are repaired by --fix.
FLAG rules (F*) are reported with a cell index but never auto-edited: fixing them
requires authoring prose.

Usage:
    audit.py NOTEBOOK [NOTEBOOK ...]          # report only
    audit.py --fix NOTEBOOK [NOTEBOOK ...]    # apply AUTO repairs in place
"""
import argparse
import json
import os
import re
import sys

HR = re.compile(r"^\s*(?:-{3,}|\*{3,}|_{3,})\s*$")
H1 = re.compile(r"^#\s+\S")
H2 = re.compile(r"^##\s+\S")
ITEM = re.compile(r"^>\s*(?:[*+-]|\d+[.)])\s+")
BULLET = re.compile(
    r"^(?P<pre>>\s*[*+-]\s+)(?P<open>__|\*\*)(?P<title>.+?)(?P=open)(?P<after>.*)$"
)
# Case-insensitive so capitalisation drift ("Key takeaways") is found and normalised
# by A3/A4 rather than silently reported as a missing block.
OBJ_HEAD = re.compile(r"^>\s*(?:__|\*\*)\s*Learning Objectives\s*:?\s*(?:__|\*\*)\s*$", re.I)
KEY_HEAD = re.compile(r"^>\s*(?:__|\*\*)\s*Key Takeaways\s*:?\s*(?:__|\*\*)\s*$", re.I)
ENVIRON = re.compile(r"\\(begin|end)\{([A-Za-z*]+)\}")

CANON_OBJ_HEAD = "> __Learning Objectives:__"
CANON_KEY_HEAD = "> __Key Takeaways:__"
CANON_INCLUDE = 'include(joinpath(@__DIR__, "Include.jl")); # include the Include.jl file'
CANON_SETUP_HEAD = "## Setup, Data, and Prerequisites"
GET_STARTED = "Let's get started!"
SETUP_QUOTE = (
    "> The [`include(...)` command](https://docs.julialang.org/en/v1/base/base/#include) "
    "evaluates the contents of the input source file, `Include.jl`, in the notebook's "
    "global scope. The `Include.jl` file sets paths, loads required external packages, "
    "etc. For additional information on functions and types used in this material, see "
    "the [Julia programming language documentation](https://docs.julialang.org/en/v1/)."
)
SETUP_TRANSITION = "Let's set up our code environment:"

# Inside any doc link whose text contains a backticked name, "method" -> "function"
# (a Julia "method" is one signature of a function; the docs document the function).
# Matches both "[the `f(...)` method]" and "[`f(...)` method]".
LINK_METHOD = re.compile(r"(\[[^\]]*`[^`]+`[^\]]*?)\bmethod\b(?=[^\[\]]*\])")
# A function-like code span: `name(...)`, `name()`, `name(x, y)`.
FUNC_SPAN = re.compile(r"`([A-Za-z_][A-Za-z0-9_!]*)\s*\([^`]*\)`")
# A bare code span used as the SUBJECT OF A VERB: "`filter` returns selected rows".
# A bare span alone is too ambiguous to flag -- "Python's `float` type", "any `isbits`
# value" and "sets are `unique`" are all modifiers, not function references. Requiring
# a following verb separates the real references from the grammatical noise.
VERB = (r"returns?|takes?|accepts?|computes?|gives?|produces?|maps?|converts?|"
        r"creates?|builds?|raises?|throws?|expects?|yields?|selects?|sorts?|"
        r"requires?|needs?|does|will|can|operates?|works?|applies|removes?")
BARE_SPAN = re.compile(r"`([a-z][A-Za-z0-9_]*!?)`\s+(?:" + VERB + r")\b")

# Positional descriptions of content that has not appeared yet make notebook prose
# brittle when cells move. Keep this deliberately narrower than a ban on the word
# "below": mathematical phrases such as "below zero" are valid. The matched nouns
# identify notebook artifacts, while "next/following cell" covers the other common
# form directly.
# A markdown link whose text is nothing but a backticked function *reference*
# span -- literal `name(...)`, dotted names allowed -- with at most a stray
# leading article. The canonical form carries "the ... function" inside the
# link (canon: Documentation links). A span with concrete arguments
# (`typemax(Int64)`) is an expression, not a reference: expanding it would say
# "the typemax(Int64) function" where the prose means the value, so those fall
# to F20 for a hand reword instead.
BARE_FUNC_LINK = re.compile(
    r"\[\s*(?:[Tt]he\s+)?"
    r"(?P<span>`[A-Za-z_@][A-Za-z0-9_!.]*\s*\(\s*\.\.\.\s*\)`)"
    r"\s*\]\((?P<url>[^)]+)\)"
)
BARE_CALL_LINK = re.compile(
    r"\[\s*(?:[Tt]he\s+)?"
    r"(?P<span>`[A-Za-z_@][A-Za-z0-9_!.]*\s*\((?!\s*\.\.\.\s*\))[^`]*\)`)"
    r"\s*\]\((?P<url>[^)]+)\)"
)
TASK_HEAD = re.compile(r"^##\s+Task\s+\d+\s*:", re.I)
# Action imperatives that open an instruction rather than a motivation.
# Rhetorical imperatives (Consider, Recall, Note, Suppose, Imagine) invite
# thought, not action, and are deliberately absent.
TASK_IMPERATIVE = re.compile(
    r"^(?:Open|Complete|Implement|Run|Write|Fill|Finish|Edit|Modify|Create|"
    r"Add|Delete|Install|Restart|Execute|Copy|Build|Define|Uncomment|Replace)\b",
    re.I,
)
FORWARD_REF = re.compile(
    r"\b(?:the\s+)?(?:"
    r"(?:next|following)\s+(?:(?:code|markdown)\s+)?(?:cell|code\s+block|section)"
    r"|(?:(?:code|markdown)\s+)?cells?\s+(?:immediately\s+)?below"
    r"|(?:everything|material|discussion|analysis|derivation|equations?|formulas?|"
    r"figures?|tables?|plots?|examples?|code(?:\s+blocks?)?|sections?|subsections?|"
    r"paragraphs?|outputs?|results?|tests?|checks?|variables?|names?|implementations?|"
    r"summations?|sums?|expressions?|indices)\s+"
    r"(?:(?:shown|given|listed|presented|defined|computed|calculated|reported)\s+)?below"
    r")\b",
    re.I,
)


def _known_functions():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "julia-functions.txt")
    try:
        with open(path, encoding="utf-8") as handle:
            return frozenset(l.strip() for l in handle if l.strip())
    except OSError:
        return frozenset()


JULIA_FUNCTIONS = _known_functions()
# A top-level assignment: column 0 only, so indented continuation lines inside a
# multi-line call (e.g. "        nrows=number_of_rows,") are not mistaken for bindings.
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_!]*)(\.[A-Za-z0-9_!]+)?\s*=[^=]")
LET_BIND = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_!]*)\s*=\s*let\b")
CODE_EXEMPT = ("let", "function", "struct", "mutable struct", "module", "macro",
               "@testset", "try", "abstract", "begin", "include", "using", "import",
               "quote", "for", "while", "if", "@assert")


def src(cell):
    return "".join(cell["source"])


def put(cell, text):
    cell["source"] = text.splitlines(keepends=True)


def role_of(path):
    name = os.path.basename(path)
    for key, role in (
        ("-Lecture-", "lecture"),
        ("-Example-", "example"),
        ("-Activity-", "activity"),
        ("-Lab-", "lab"),
    ):
        if key in name:
            return role
    return "example"


def first_line(cell):
    for line in src(cell).splitlines():
        if line.strip():
            return line
    return ""


def sections(cells):
    """[(start, end)] half-open ranges. Index 0 is the title block."""
    starts = [0]
    for i, c in enumerate(cells):
        if i and c["cell_type"] == "markdown" and H2.match(first_line(c)):
            starts.append(i)
    return [(s, starts[k + 1] if k + 1 < len(starts) else len(cells))
            for k, s in enumerate(starts)]


def quote_span(lines, i):
    """Half-open span of the contiguous '>' block containing line i."""
    a = i
    while a > 0 and lines[a - 1].lstrip().startswith(">"):
        a -= 1
    b = i
    while b + 1 < len(lines) and lines[b + 1].lstrip().startswith(">"):
        b += 1
    return a, b + 1


def find_block(cells, head_re):
    """(cell_index, line_index) of a blockquote heading, or None."""
    for i, c in enumerate(cells):
        if c["cell_type"] != "markdown":
            continue
        for j, line in enumerate(src(c).splitlines()):
            if head_re.match(line):
                return i, j
    return None


class Audit:
    def __init__(self, path, fix=False):
        self.path = path
        self.fix = fix
        self.nb = json.load(open(path))
        self.cells = self.nb["cells"]
        self.role = role_of(path)
        self.findings = []
        self.repairs = []

    def flag(self, idx, rule, msg):
        self.findings.append((idx, rule, msg))

    def repaired(self, idx, rule, msg):
        self.repairs.append((idx, rule, msg))

    # ---------------- AUTO ----------------

    def a1_separator_glyph(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            lines = src(c).splitlines()
            bad = [k for k, l in enumerate(lines) if HR.match(l) and l.strip() != "___"]
            if not bad:
                continue
            if self.fix:
                for k in bad:
                    lines[k] = "___"
                put(c, "\n".join(lines))
                self.repaired(i, "A1", f"{len(bad)} rule(s) -> ___")
            else:
                self.flag(i, "A1", f"{len(bad)} horizontal rule(s) not '___'")

    def a2_section_termination(self):
        # Work backwards so insertions do not shift earlier indices.
        for start, end in reversed(sections(self.cells)):
            if end <= start:
                continue
            last = self.cells[end - 1]
            if last["cell_type"] == "markdown":
                lines = [l for l in src(last).splitlines() if l.strip()]
                if lines and lines[-1].strip() == "___":
                    continue
                if self.fix:
                    put(last, src(last).rstrip() + "\n\n___")
                    self.repaired(end - 1, "A2", "appended '___' to section")
                else:
                    self.flag(end - 1, "A2", "section does not end with '___'")
            else:
                if self.fix:
                    self.cells.insert(end, {
                        "cell_type": "markdown", "id": f"sep{end:04d}",
                        "metadata": {}, "source": ["___"],
                    })
                    self.repaired(end, "A2", "inserted standalone '___' cell after code")
                else:
                    self.flag(end - 1, "A2",
                              "section ends in code with no standalone '___' cell")

    def _canon_head(self, head_re, canon, rule):
        loc = find_block(self.cells, head_re)
        if loc is None:
            return None
        i, j = loc
        lines = src(self.cells[i]).splitlines()
        changed = False
        if lines[j].rstrip() != canon:
            if self.fix:
                lines[j] = canon
                changed = True
                self.repaired(i, rule, f"heading -> {canon}")
            else:
                self.flag(i, rule, f"heading is {lines[j].strip()!r}, want {canon!r}")
        # blank '>' line directly after the heading
        nxt = lines[j + 1].strip() if j + 1 < len(lines) else ""
        if nxt != ">":
            if self.fix:
                lines.insert(j + 1, ">")
                changed = True
                self.repaired(i, rule, "inserted blank '>' after heading")
            else:
                self.flag(i, rule, "no blank '>' line after heading")
        if changed:
            put(self.cells[i], "\n".join(lines))
        return i

    def a3_a4_headings(self):
        self._canon_head(OBJ_HEAD, CANON_OBJ_HEAD, "A3")
        self._canon_head(KEY_HEAD, CANON_KEY_HEAD, "A4")

    def a5_preamble(self):
        loc = find_block(self.cells, OBJ_HEAD)
        if loc is None:
            return
        i, j = loc
        lines = src(self.cells[i]).splitlines()
        a, b = quote_span(lines, j)
        # a preamble is a non-blank, non-item '>' prose line after the heading
        has = any(
            lines[k].strip() not in (">", "")
            and not ITEM.match(lines[k])
            and not OBJ_HEAD.match(lines[k])
            for k in range(j + 1, b)
        )
        if has:
            return
        line = f"> By the end of this {self.role}, you should be able to:"
        if self.fix:
            at = j + 2 if j + 1 < len(lines) and lines[j + 1].strip() == ">" else j + 1
            lines.insert(at, line)
            put(self.cells[i], "\n".join(lines))
            self.repaired(i, "A5", "inserted objectives preamble")
        else:
            self.flag(i, "A5", f"missing preamble line ({line!r})")

    def a6_colon_inside_bold(self):
        # Scoped to the objectives and takeaways blockquotes ONLY. Ordinary definition
        # bullets elsewhere (e.g. "* **K-means++**: Select initial centroids ...") use
        # the bold as a term with a following colon; rewriting those would be wrong.
        spans = {}
        for head_re in (OBJ_HEAD, KEY_HEAD):
            loc = find_block(self.cells, head_re)
            if loc is None:
                continue
            i, j = loc
            a, b = quote_span(src(self.cells[i]).splitlines(), j)
            spans.setdefault(i, []).append((a, b))

        for i, ranges in spans.items():
            c = self.cells[i]
            lines = src(c).splitlines()
            hits = []
            for a, b in ranges:
                for k in range(a, b):
                    m = BULLET.match(lines[k])
                    if m and not m.group("title").rstrip().endswith(":") \
                            and m.group("after").lstrip().startswith(":"):
                        hits.append(k)
            if not hits:
                continue
            if self.fix:
                for k in hits:
                    m = BULLET.match(lines[k])
                    after = m.group("after").lstrip()[1:]
                    lines[k] = (m.group("pre") + m.group("open") + m.group("title")
                                + ":" + m.group("open") + after)
                put(c, "\n".join(lines))
                self.repaired(i, "A6", f"{len(hits)} title colon(s) moved inside bold")
            else:
                self.flag(i, "A6", f"{len(hits)} title(s) with colon outside the bold")

    def a7_get_started(self):
        start, end = sections(self.cells)[0]
        for i in range(start, end):
            if self.cells[i]["cell_type"] != "markdown":
                continue
            if GET_STARTED in src(self.cells[i]):
                return
        i = end - 1
        c = self.cells[i]
        if c["cell_type"] != "markdown":
            self.flag(i, "A7", f"title block missing {GET_STARTED!r}")
            return
        if self.fix:
            lines = src(c).splitlines()
            while lines and not lines[-1].strip():
                lines.pop()
            if lines and lines[-1].strip() == "___":
                lines = lines[:-1]
                while lines and not lines[-1].strip():
                    lines.pop()
                lines += ["", GET_STARTED, "___"]
            else:
                lines += ["", GET_STARTED]
            put(c, "\n".join(lines))
            self.repaired(i, "A7", f"added {GET_STARTED!r}")
        else:
            self.flag(i, "A7", f"title block missing {GET_STARTED!r}")

    def a8_setup_heading(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            fl = first_line(c)
            if not H2.match(fl):
                continue
            low = fl.lower()
            if "setup" in low and fl.strip() != CANON_SETUP_HEAD:
                if self.fix:
                    lines = src(c).splitlines()
                    for k, l in enumerate(lines):
                        if l.strip() == fl.strip():
                            lines[k] = CANON_SETUP_HEAD
                            break
                    put(c, "\n".join(lines))
                    self.repaired(i, "A8", f"heading -> {CANON_SETUP_HEAD!r}")
                else:
                    self.flag(i, "A8", f"setup heading is {fl.strip()!r}")

    def a10_link_method_to_function(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            new = LINK_METHOD.sub(r"\1function", text)
            if new == text:
                continue
            n = len(LINK_METHOD.findall(text))
            if self.fix:
                put(c, new)
                self.repaired(i, "A10", f"{n} doc link(s) 'method' -> 'function'")
            else:
                self.flag(i, "A10", f"{n} doc link(s) say 'method', want 'function'")

    def a12_doc_link_form(self):
        """A doc link whose text is only a function-call span reads
        [the `name(...)` function](url). Link text that already carries other
        words ("command", "package", "standard library", "function", ...) is
        left alone."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            names = []

            def expand(m):
                span, url = m.group("span"), m.group("url")
                prev = text[:m.start()].rstrip()
                # Sentence-, cell-, table-, list- or blockquote-initial -> "The"
                cap = not prev or prev[-1] in ".!?>|"
                names.append(span)
                return f"[{'The' if cap else 'the'} {span} function]({url})"

            new = BARE_FUNC_LINK.sub(expand, text)
            if new == text:
                continue
            if self.fix:
                put(c, new)
                self.repaired(i, "A12", f"expanded {', '.join(names)} to "
                                        "'the ... function' link form")
            else:
                for name in names:
                    self.flag(i, "A12", f"doc link {name} should read "
                                        f"'[the {name} function](url)'")

    def a11_setup_block(self):
        """The setup section needs the include blockquote and the transition line."""
        idx = None
        for i, c in enumerate(self.cells):
            if c["cell_type"] == "markdown" and first_line(c).strip() == CANON_SETUP_HEAD:
                idx = i
                break
        if idx is None:
            return
        c = self.cells[idx]
        text = src(c)
        has_quote = "`include(...)` command" in text
        has_trans = SETUP_TRANSITION in text
        if has_quote and has_trans:
            return
        if not self.fix:
            if not has_quote:
                self.flag(idx, "A11", "setup section missing the include blockquote")
            if not has_trans:
                self.flag(idx, "A11", f"setup section missing {SETUP_TRANSITION!r}")
            return
        lines = [l for l in text.splitlines()]
        while lines and not lines[-1].strip():
            lines.pop()
        if not has_quote:
            lines += ["", SETUP_QUOTE]
        if not has_trans:
            lines += ["", SETUP_TRANSITION]
        put(c, "\n".join(lines))
        self.repaired(idx, "A11", "added include blockquote / transition line")

    def a9_include_cell(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "code":
                continue
            body = src(c).strip()
            if "Include.jl" not in body or not body.startswith("include"):
                continue
            if body != CANON_INCLUDE:
                if self.fix:
                    put(c, CANON_INCLUDE)
                    self.repaired(i, "A9", "canonicalised include cell")
                else:
                    self.flag(i, "A9", f"include cell is {body!r}")
            return

    # ---------------- FLAG ----------------

    def _items(self, head_re):
        loc = find_block(self.cells, head_re)
        if loc is None:
            return None, None, []
        i, j = loc
        lines = src(self.cells[i]).splitlines()
        a, b = quote_span(lines, j)
        return i, lines, [lines[k] for k in range(j + 1, b) if ITEM.match(lines[k])]

    def f1_f2_f6_items(self):
        for head_re, label, rule_prefix in (
            (OBJ_HEAD, "learning objectives", "objectives"),
            (KEY_HEAD, "key takeaways", "takeaways"),
        ):
            i, lines, items = self._items(head_re)
            if i is None:
                self.flag(0, "F1", f"no {label} block found")
                continue
            if len(items) != 3:
                self.flag(i, "F1", f"{len(items)} {label} (must be exactly 3)")
            untitled = [t for t in items if not BULLET.match(t)]
            if untitled:
                self.flag(i, "F2",
                          f"{len(untitled)}/{len(items)} {label} lack a 'Title:' prefix")
            withmath = [t for t in items if "$" in t]
            if withmath:
                self.flag(i, "F6", f"{len(withmath)} {label} contain equations")

    def f10_f11_item_prose(self):
        """Objectives and takeaways are 2-3 complete sentences (claim, mechanism, implication)."""
        for head_re, label, rule in ((OBJ_HEAD, "objective", "F10"),
                                     (KEY_HEAD, "takeaway", "F11")):
            i, _, items = self._items(head_re)
            if i is None:
                continue
            for n, item in enumerate(items, 1):
                m = BULLET.match(item)
                body = (m.group("after") if m else re.sub(ITEM, "", item)).strip()
                if not body.endswith((".", "!", "?")):
                    self.flag(i, rule, f"{label} {n} is not a complete sentence "
                                       f"(no terminal punctuation)")
                elif len(body) < 60:
                    self.flag(i, rule, f"{label} {n} is a fragment "
                                       f"({len(body)} chars): {body[:44]!r}")

    def f12_unlinked_functions(self):
        """A function mentioned as a code span should be linked to its docs somewhere."""
        linked, mentions = set(), {}
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            for link_text in re.findall(r"\[([^\]]+)\]\([^)]+\)", text):
                for name in FUNC_SPAN.findall(link_text):
                    linked.add(name)
                for name in re.findall(r"`([A-Za-z_][A-Za-z0-9_!]*)`", link_text):
                    linked.add(name)
            stripped = re.sub(r"\[[^\]]+\]\([^)]+\)", "", text)
            for name in FUNC_SPAN.findall(stripped):
                mentions.setdefault(name, i)
            # A bare `name` span counts only when it is a known Julia function --
            # otherwise every backticked variable would be reported.
            for name in BARE_SPAN.findall(stripped):
                if name in JULIA_FUNCTIONS:
                    mentions.setdefault(name, i)
        # Functions the notebook defines itself have no external docs to link to.
        local = set()
        for c in self.cells:
            if c["cell_type"] == "code":
                local |= set(re.findall(r"^\s*function\s+([A-Za-z_][A-Za-z0-9_!]*)",
                                        src(c), re.M))
                local |= set(re.findall(r"^([A-Za-z_][A-Za-z0-9_!]*)\s*=\s*function\b",
                                        src(c), re.M))
                # Types defined here are constructors too, and have no external docs.
                local |= set(re.findall(
                    r"^\s*(?:mutable\s+)?struct\s+([A-Za-z_][A-Za-z0-9_!]*)",
                    src(c), re.M))
                local |= set(re.findall(r"^\s*abstract\s+type\s+([A-Za-z_][A-Za-z0-9_!]*)",
                                        src(c), re.M))
        for name, i in sorted(mentions.items(), key=lambda kv: kv[1]):
            if name not in linked and name not in local:
                self.flag(i, "F12", f"`{name}(...)` is never linked to its docs")

    def f13_let_wrapping(self):
        """Multi-statement cells that bind globals belong in a let ... end block."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "code":
                continue
            lines = [l for l in src(c).splitlines()
                     if l.strip() and not l.strip().startswith("#")]
            if len(lines) < 2:
                continue
            head = lines[0].strip()
            if LET_BIND.match(head) or any(head.startswith(e) for e in CODE_EXEMPT):
                continue
            # A block of distinct constant assignments is deliberate and must stay
            # global -- wrapping it in `let` would hide the names from later cells.
            # The hazard is building one object through intermediate steps: a field
            # assignment, or the same name bound more than once.
            names, fields, repeats = [], 0, 0
            for l in lines:
                m = ASSIGN.match(l)
                if not m:
                    continue
                if m.group(2):
                    fields += 1
                elif m.group(1) in names:
                    repeats += 1
                else:
                    names.append(m.group(1))
            if fields or repeats:
                why = "field assignment(s)" if fields else "rebound name(s)"
                self.flag(i, "F13", f"{len(lines)} statements with {fields or repeats} "
                                    f"{why} at global scope, not wrapped in let ... end")

    def f14_let_result_typed(self):
        """`name = let ... end` must have `name::Type` described in the prose above."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "code" or i == 0:
                continue
            m = LET_BIND.match(src(c))
            if not m:
                continue
            name = m.group(1)
            prev = self.cells[i - 1]
            text = src(prev) if prev["cell_type"] == "markdown" else ""
            if f"`{name}::" not in text:
                self.flag(i, "F14", f"`{name} = let ... end` but the prose above never "
                                    f"gives `{name}::<Type>`")

    def f3_summary(self):
        idx = None
        for start, end in sections(self.cells):
            if first_line(self.cells[start]).strip().lower().startswith("## summary"):
                idx = start
                break
        if idx is None:
            self.flag(len(self.cells) - 1, "F3", "no '## Summary' section")
            return
        lines = src(self.cells[idx]).splitlines()
        head = next(k for k, l in enumerate(lines) if l.strip().lower().startswith("## summary"))
        qs = [k for k, l in enumerate(lines) if l.lstrip().startswith(">")]
        if not qs:
            self.flag(idx, "F3", "summary has no takeaways blockquote")
            return
        lead = [l for l in lines[head + 1:qs[0]] if l.strip()]
        tail = [l for l in lines[qs[-1] + 1:] if l.strip() and l.strip() != "___"]
        if not lead:
            self.flag(idx, "F3", "summary missing the direct summary sentence")
        if not tail:
            self.flag(idx, "F3", "summary missing the concluding sentence")

    def f4_transition_before_code(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "code" or i == 0:
                continue
            prev = self.cells[i - 1]
            if prev["cell_type"] == "code":
                continue  # consecutive code cells are legitimate; no transition needed
            if prev["cell_type"] != "markdown":
                self.flag(i, "F4", "code cell not preceded by a markdown cell")
                continue
            lines = [l for l in src(prev).splitlines() if l.strip()]
            if not lines:
                self.flag(i, "F4", "preceding markdown cell is empty")
                continue
            last = lines[-1].strip()
            if last.startswith(">") or last.startswith("#") or HR.match(last) \
                    or re.match(r"^(?:[*+-]|\d+[.)])\s+", last):
                self.flag(i, "F4",
                          f"no transition sentence before code (previous line: {last[:48]!r})")

    def f5_consecutive_blockquotes(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            lines = src(c).splitlines()
            blocks, k = [], 0
            while k < len(lines):
                if lines[k].lstrip().startswith(">"):
                    a, b = quote_span(lines, k)
                    blocks.append((a, b))
                    k = b
                else:
                    k += 1
            for (a1, b1), (a2, _) in zip(blocks, blocks[1:]):
                if not any(lines[k].strip() for k in range(b1, a2)):
                    self.flag(i, "F5", f"consecutive blockquotes at lines {b1}-{a2}")
            if i + 1 < len(self.cells) and self.cells[i + 1]["cell_type"] == "markdown":
                cur = [l for l in lines if l.strip()]
                nxt = [l for l in src(self.cells[i + 1]).splitlines() if l.strip()]
                if cur and nxt and cur[-1].lstrip().startswith(">") \
                        and nxt[0].lstrip().startswith(">"):
                    self.flag(i, "F5", "cell ends in a blockquote and the next begins with one")

    def f7_latex(self):
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            if text.count("$$") % 2:
                self.flag(i, "F7", f"odd number of '$$' ({text.count('$$')})")
            stripped = re.sub(r"\$\$.*?\$\$", "", text, flags=re.S)
            stripped = re.sub(r"`[^`]*`", "", stripped)
            singles = len(re.findall(r"(?<!\\)\$", stripped))
            if singles % 2:
                self.flag(i, "F7", f"odd number of inline '$' ({singles})")
            opened = {}
            for kind, name in ENVIRON.findall(text):
                opened[name] = opened.get(name, 0) + (1 if kind == "begin" else -1)
            for name, n in opened.items():
                if n:
                    self.flag(i, "F7", f"unbalanced \\begin/\\end for {name!r}")

    def f15_post_include_note(self):
        """A note must follow the include cell: which packages / local source it loaded."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "code" or "Include.jl" not in src(c):
                continue
            nxt = self.cells[i + 1] if i + 1 < len(self.cells) else None
            body = src(nxt).strip() if nxt and nxt["cell_type"] == "markdown" else ""
            if not body or HR.match(body) or body == "___":
                self.flag(i, "F15", "no markdown note after the include cell "
                                    "(say what it loaded and link the docs)")
            return

    def f16_lab_has_student_work(self):
        """A lab must ship something incomplete for students to finish in class.

        Satisfied by a stub marker in a sibling src/ file, or by a TODO addressed to
        the student in a notebook code cell (e.g. a confirmation flag they must set).
        """
        if self.role != "lab":
            return
        marker = re.compile(r"TODO|Oooo?o?ps!|not (?:yet )?implemented|"
                            r"has not been implemented|your code here", re.I)
        for c in self.cells:
            if c["cell_type"] == "code" and marker.search(src(c)):
                return
        srcdir = os.path.join(os.path.dirname(os.path.abspath(self.path)), "src")
        if os.path.isdir(srcdir):
            for name in sorted(os.listdir(srcdir)):
                if not name.endswith((".jl", ".py")) or "-solution" in name:
                    continue
                try:
                    if marker.search(open(os.path.join(srcdir, name),
                                          encoding="utf-8", errors="ignore").read()):
                        return
                except OSError:
                    continue
        self.flag(0, "F16", "lab ships nothing for students to complete "
                            "(no stub in src/, no TODO in a code cell)")

    def f17_em_dashes(self):
        """Em dashes are not house style; reword with commas, parentheses, or a colon."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            n = text.count("—")
            if not n:
                continue
            line = next(l for l in text.splitlines() if "—" in l)
            self.flag(i, "F17", f"{n} em dash(es), e.g. {line.strip()[:60]!r}")

    def f18_forward_references(self):
        """Prose names the action or object directly, not by a later cell's position."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            text = src(c)
            for match in FORWARD_REF.finditer(text):
                self.flag(i, "F18", f"forward reference {match.group(0)!r}; "
                                      "name the action or object directly")

    def f8_setup_present(self):
        if not any(c["cell_type"] == "code" for c in self.cells):
            return
        if not any(c["cell_type"] == "markdown"
                   and first_line(c).strip() == CANON_SETUP_HEAD for c in self.cells):
            self.flag(0, "F8", f"code-bearing notebook has no {CANON_SETUP_HEAD!r}")

    def f9_single_h1(self):
        h1 = [i for i, c in enumerate(self.cells)
              if c["cell_type"] == "markdown"
              and any(H1.match(l) for l in src(c).splitlines())]
        if len(h1) != 1:
            self.flag(h1[1] if len(h1) > 1 else 0, "F9", f"{len(h1)} H1 headings (want 1)")
        elif h1[0] != 0 or not H1.match(first_line(self.cells[0])):
            self.flag(h1[0], "F9", "H1 is not the first line of the first cell")

    def f20_call_links(self):
        """A doc link whose text is a call with concrete arguments reads as a
        value in the sentence; no mechanical rewrite of the link text is safe.
        Reword the prose so the link names the function."""
        for i, c in enumerate(self.cells):
            if c["cell_type"] != "markdown":
                continue
            for m in BARE_CALL_LINK.finditer(src(c)):
                self.flag(i, "F20", f"link text {m.group('span')} is a call with "
                                    "concrete arguments; reword so the link names "
                                    "the function as '[the `name(...)` function](url)'")

    def f19_task_motivation(self):
        """A Task section opens with motivation, not an instruction (heuristic).

        The checker only catches the mechanical signals: no prose at all before
        the first blockquote/table/list/code, or a first sentence that starts
        with an action imperative. Whether a passing sentence actually motivates
        the task is judged by hand.
        """
        for start, end in sections(self.cells):
            head = first_line(self.cells[start]).strip()
            if not TASK_HEAD.match(head):
                continue
            lines = src(self.cells[start]).splitlines()
            k = next(i for i, l in enumerate(lines) if l.strip())
            body = None
            for line in lines[k + 1:]:
                s = line.strip()
                if not s:
                    continue
                if s.startswith((">", "#", "|", "*", "-", "+", "```")) or HR.match(s):
                    break
                body = s
                break
            if body is None:
                self.flag(start, "F19", "task section has no prose before its first "
                                        "blockquote/table/list/code; open with a "
                                        "motivation sentence")
            elif TASK_IMPERATIVE.match(body):
                self.flag(start, "F19", f"task opens with the instruction "
                                        f"{body.split()[0]!r}; add a motivation "
                                        "sentence before it")

    # ---------------- driver ----------------

    def run(self):
        auto = (self.a1_separator_glyph, self.a3_a4_headings, self.a5_preamble,
                self.a6_colon_inside_bold, self.a7_get_started, self.a8_setup_heading,
                self.a10_link_method_to_function, self.a12_doc_link_form,
                self.a11_setup_block,
                self.a9_include_cell, self.a2_section_termination)
        for step in auto:
            step()
        if self.fix:
            json.dump(self.nb, open(self.path, "w"), indent=1, ensure_ascii=False)
            open(self.path, "a").write("\n")
        for step in (self.f1_f2_f6_items, self.f10_f11_item_prose,
                     self.f15_post_include_note, self.f16_lab_has_student_work,
                     self.f12_unlinked_functions, self.f13_let_wrapping,
                     self.f14_let_result_typed, self.f3_summary,
                     self.f4_transition_before_code, self.f5_consecutive_blockquotes,
                     self.f7_latex, self.f8_setup_present, self.f9_single_h1,
                     self.f17_em_dashes, self.f18_forward_references,
                     self.f19_task_motivation, self.f20_call_links):
            step()
        return self.findings, self.repairs


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("notebooks", nargs="+")
    ap.add_argument("--fix", action="store_true", help="apply AUTO (A*) repairs in place")
    args = ap.parse_args()

    total = 0
    for path in args.notebooks:
        audit = Audit(path, fix=args.fix)
        findings, repairs = audit.run()
        name = os.path.basename(path)
        print(f"\n=== {name}  [role: {audit.role}]")
        for idx, rule, msg in repairs:
            print(f"  FIXED  cell {idx:>3}  {rule}  {msg}")
        for idx, rule, msg in sorted(findings):
            print(f"  {'FLAG ' if rule[0] == 'F' else 'AUTO '} cell {idx:>3}  {rule}  {msg}")
        if not findings and not repairs:
            print("  clean")
        total += len(findings)
    print(f"\n{total} outstanding finding(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
