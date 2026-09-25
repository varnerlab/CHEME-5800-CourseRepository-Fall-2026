#!/usr/bin/env python3
"""Build portable PDFs and fixed/automatic-theme SVGs from the TikZ source."""
import re
import subprocess
from pathlib import Path
from xml.etree import ElementTree as ET

HERE = Path(__file__).resolve().parent
STEM = "Fig-Central-Metabolism"
DARK = {
    (30, 41, 59): "#e6edf5", (83, 98, 119): "#b4c1d2",
    (36, 99, 168): "#7db9f2", (121, 82, 160): "#c7a3ed",
    (164, 96, 20): "#e9b66d", (19, 123, 105): "#79cfba",
    (255, 255, 255): "#121923",
    (165, 63, 104): "#f0a5c2", (152, 99, 0): "#f2cd76",
    (215, 222, 231): "#394654",
}


def rgb(value):
    """Parse an SVG rgb(...) or six-digit hex color into an integer RGB tuple.

    RGB channels may be numbers or percentages. Unsupported formats raise
    ValueError; this parser expects the formats emitted by pdf2svg.
    """
    if value.startswith("rgb("):
        return tuple(round(float(v.strip().rstrip("%")) *
                           (2.55 if "%" in v else 1))
                     for v in value[4:-1].split(","))
    if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        return tuple(int(value[i:i + 2], 16) for i in (1, 3, 5))
    raise ValueError(f"Unexpected color {value}")


def decorate(source, theme):
    """Return SVG text with accessibility labels and the requested theme CSS.

    source is pdf2svg output; theme is auto, light, or dark. Every explicit
    fill/stroke color except none must occur in DARK, the light-to-dark palette.
    Unknown colors raise KeyError so palette changes require an explicit mapping.
    Auto uses dark colors only on dark screens, retaining light print output.
    """
    drawing = ET.fromstring(source)
    rules = []
    for attr in ("fill", "stroke"):
        for color in sorted({e.attrib[attr] for e in drawing.iter()
                             if attr in e.attrib and e.attrib[attr] != "none"}):
            rules.append(f'[{attr}="{color}"] {{ {attr}: {DARK[rgb(color)]}; }}')
    css = "\n".join(rules)
    if theme == "auto":
        css = "@media screen and (prefers-color-scheme: dark) {\n" + css + "\n}"
    elif theme == "light":
        css = ""
    title = '<title id="figure-title">Central metabolism: selected carbon-flow routes</title>'
    desc = ('<desc id="figure-desc">Glycolysis connects glucose to pyruvate and acetyl-CoA. '
            'Branches supply pentose sugars, lactate, fatty acids, and the TCA cycle. '
            'A circular eight-intermediate TCA cycle supplies glutamate. ATP, NADH, NADPH, and FADH2 accounting and oxidative phosphorylation are shown. Nucleotides, lipids, and proteins '
            'illustrate biosynthetic products. This is a simplified, non-stoichiometric map.</desc>')
    source = source.replace('<svg ', '<svg role="img" aria-labelledby="figure-title figure-desc" ', 1)
    pos = source.index(">", source.index("<svg")) + 1
    insert = "\n" + title + "\n" + desc + '\n<style id="course-theme">\n' + css + "\n</style>\n"
    return source[:pos] + insert + source[pos:]


def run(*args):
    """Run a build command in the figure directory, capturing combined output.

    Raise CalledProcessError on nonzero exit and FileNotFoundError if the tool
    is unavailable. The caller prints captured diagnostics when a build fails.
    """
    subprocess.run(args, cwd=HERE, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def main():
    """Build light/dark PDFs and three SVG variants beside the TikZ source.

    Requires pdflatex and pdf2svg on PATH; see README.md for TeX dependencies.
    Existing outputs are overwritten. Remove aux/log files after success;
    failed builds retain their diagnostic files.
    """
    try:
        run("pdflatex", "-interaction=nonstopmode", "-halt-on-error", STEM + ".tex")
        run("pdflatex", "-interaction=nonstopmode", "-halt-on-error", "-jobname=" + STEM + "-dark",
            r"\def\darkmode{1}\input{" + STEM + ".tex}")
        run("pdf2svg", STEM + ".pdf", STEM + "-light.svg")
        source = (HERE / (STEM + "-light.svg")).read_text()
        for suffix, theme in [("", "auto"), ("-light", "light"), ("-dark", "dark")]:
            (HERE / (STEM + suffix + ".svg")).write_text(decorate(source, theme))
    except subprocess.CalledProcessError as error:
        print(error.stdout.decode(errors="replace"))
        raise
    for suffix in ["", "-dark"]:
        for ext in ["aux", "log"]:
            (HERE / (STEM + suffix + "." + ext)).unlink(missing_ok=True)
    print("Built TikZ PDFs and SVGs (automatic, light, and dark).")


if __name__ == "__main__":
    main()
