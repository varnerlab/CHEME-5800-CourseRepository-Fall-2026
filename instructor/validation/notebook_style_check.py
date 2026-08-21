#!/usr/bin/env python3
"""House-style checks for the course notebooks.

The Julia suites under instructor/validation/week-NN/ check that the code is
correct. This checks the prose conventions around it, the ones that are easy to
drift on when editing a notebook by hand.

Checks
------
api-link      A Julia function, macro, or error type named in markdown prose is
              written as a link: [the `bitstring(...)` function](url), [the
              `@assert` macro](url), [an `ArgumentError`](url). The set of names
              worth linking is harvested from the notebooks themselves, so the
              repository defines its own vocabulary and no list needs updating
              here. Bare backticked *type* names in running prose (`String`,
              `Bool`, `Int`) are widespread and deliberately not flagged.
em-dash       Em dashes are not used in notebook prose. (Week README titles do
              use them; this only reads notebooks.)
cell-id       nbformat 4.5 requires a unique `id` on every cell. Cells added by
              editing the JSON directly are easy to create without one.
double-rule   A bare `___` cell immediately after a cell that already ends in
              `___` renders two horizontal lines.
empty-code    An empty code cell.

Usage
-----
    # everything, grouped by notebook
    python3 instructor/validation/notebook_style_check.py

    # just the notebooks you touched
    python3 instructor/validation/notebook_style_check.py weeks/week-02/L2a/*.ipynb

    # only what changed against a git ref: the practical mode while editing,
    # because it hides pre-existing findings you are not responsible for
    python3 instructor/validation/notebook_style_check.py --baseline HEAD

    # exit 1 when anything is reported, for a pre-commit hook or CI
    python3 instructor/validation/notebook_style_check.py --baseline HEAD --strict

Standard library only. Run from the repository root.
"""

from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import re
import subprocess
import sys

LINK = re.compile(r"\[([^\]]*?)\]\((https?://[^)]+)\)")
BACKTICK = re.compile(r"`([^`\n]+)`")
ERRORISH = re.compile(r"^[A-Z]\w*(Error|Exception)$")
MACRO = re.compile(r"^@\w+$")
# Function-shaped: lowercase start, may carry dots and a trailing !
FUNCTION = re.compile(r"^[a-z][\w.!]*$")

NOTEBOOK_GLOB = "weeks/**/*.ipynb"


def normalize(name: str) -> str:
    return name.replace("(...)", "").replace("()", "").strip()


def markdown_cells(notebook):
    for index, cell in enumerate(notebook["cells"]):
        if cell["cell_type"] == "markdown":
            yield index, "".join(cell["source"])


def build_link_vocabulary(paths):
    """name -> most common URL, harvested from every link label in the corpus.

    Built from the whole repository even when only a few notebooks are being
    checked, so that a name linked in week 4 still counts as linkable in week 1.
    """
    seen = collections.defaultdict(collections.Counter)
    for path in paths:
        try:
            notebook = json.load(open(path))
        except (OSError, ValueError):
            continue
        for _, source in markdown_cells(notebook):
            for match in LINK.finditer(source):
                label, url = match.group(1), match.group(2)
                for name in BACKTICK.finditer(label):
                    seen[normalize(name.group(1))][url] += 1
    return {name: urls.most_common(1)[0][0] for name, urls in seen.items()}


def link_spans(source):
    return [(m.start(), m.end()) for m in LINK.finditer(source)]


def check_api_links(notebook, vocabulary):
    """Flag function / macro / error names that should be links but are not."""
    for index, source in markdown_cells(notebook):
        spans = link_spans(source)
        reported = set()
        for match in BACKTICK.finditer(source):
            raw = match.group(1).strip()
            name = normalize(raw)
            if name in reported:
                continue
            if any(start <= match.start() < end for start, end in spans):
                continue
            linkable = (
                ERRORISH.match(name)
                or MACRO.match(name)
                or (FUNCTION.match(name) and name in vocabulary)
            )
            if not linkable:
                continue
            reported.add(name)
            url = vocabulary.get(name, "")
            hint = f" -> {url}" if url else " (no URL used elsewhere; find one)"
            yield "api-link", index, f"`{raw}` is not linked{hint}"


def check_em_dash(notebook):
    for index, source in markdown_cells(notebook):
        if "—" in source:
            yield "em-dash", index, "contains an em dash"


def check_cell_ids(notebook):
    if notebook.get("nbformat_minor", 0) < 5:
        return
    for index, cell in enumerate(notebook["cells"]):
        if "id" not in cell:
            yield "cell-id", index, "cell has no id (required by nbformat 4.5)"


def check_double_rules(notebook):
    cells = notebook["cells"]
    for index in range(1, len(cells)):
        this, prev = cells[index], cells[index - 1]
        if this["cell_type"] != "markdown" or prev["cell_type"] != "markdown":
            continue
        if "".join(this["source"]).strip() != "___":
            continue
        if "".join(prev["source"]).rstrip().endswith("___"):
            yield "double-rule", index, "bare `___` follows a cell already ending in `___`"


def check_empty_code(notebook):
    for index, cell in enumerate(notebook["cells"]):
        if cell["cell_type"] == "code" and not "".join(cell["source"]).strip():
            yield "empty-code", index, "empty code cell"


def findings_for(notebook, vocabulary):
    yield from check_api_links(notebook, vocabulary)
    yield from check_em_dash(notebook)
    yield from check_cell_ids(notebook)
    yield from check_double_rules(notebook)
    yield from check_empty_code(notebook)


def load_from_git(ref, path):
    result = subprocess.run(
        ["git", "show", f"{ref}:{path}"], capture_output=True, text=True
    )
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("paths", nargs="*", help="notebooks to check (default: all)")
    parser.add_argument(
        "--baseline",
        metavar="REF",
        help="only report findings absent from this git ref (e.g. HEAD)",
    )
    parser.add_argument(
        "--strict", action="store_true", help="exit 1 when anything is reported"
    )
    args = parser.parse_args()

    corpus = sorted(glob.glob(NOTEBOOK_GLOB, recursive=True))
    if not corpus:
        print("no notebooks found; run from the repository root", file=sys.stderr)
        return 2

    # The vocabulary always comes from the full corpus, so that checking one
    # notebook still knows what the rest of the repository links.
    vocabulary = build_link_vocabulary(corpus)

    targets = [os.path.relpath(p) for p in (args.paths or corpus)]
    total = 0
    for path in targets:
        try:
            notebook = json.load(open(path))
        except (OSError, ValueError) as error:
            print(f"{path}: cannot read ({error})", file=sys.stderr)
            continue

        current = list(findings_for(notebook, vocabulary))
        if args.baseline:
            previous = load_from_git(args.baseline, path)
            if previous is not None:
                before = {(kind, message) for kind, _, message in findings_for(previous, vocabulary)}
                current = [f for f in current if (f[0], f[2]) not in before]

        if not current:
            continue
        print(f"\n{path}")
        for kind, index, message in sorted(current, key=lambda f: (f[1], f[0])):
            print(f"  cell {index:>3}  [{kind}] {message}")
        total += len(current)

    scope = f" new since {args.baseline}" if args.baseline else ""
    print(f"\n{total} finding(s){scope} across {len(targets)} notebook(s).")
    if total and not args.baseline:
        print("Pre-existing findings are expected; use --baseline while editing.")
    return 1 if (total and args.strict) else 0


if __name__ == "__main__":
    sys.exit(main())
