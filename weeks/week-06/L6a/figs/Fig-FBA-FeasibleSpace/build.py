#!/usr/bin/env python3
"""Build the TikZ PDF and an SVG that follows the notebook's light/dark theme."""
import re
import subprocess
from pathlib import Path
from xml.etree import ElementTree as ET

HERE = Path(__file__).resolve().parent
STEM = "Fig-FBA-FeasibleSpace"
DARK = {
    (220, 234, 245): "#203b54",  # feasible region
    (70, 130, 180): "#84bee8",   # feasible border and labels
    (224, 138, 20): "#f2b85b",   # objective contours
    (184, 54, 54): "#ff9292",    # alternate optima and flux range
    (70, 70, 70): "#cbd5e1",     # axes and body labels
    (166, 166, 166): "#8f9daf",  # candidate directions
    (178, 178, 178): "#9aa7b7",  # stage arrows
    (172, 172, 172): "#95a2b3",  # range projection guides
    (255, 255, 255): "#121923",  # small label surfaces
    (0, 0, 0): "#e6edf5",       # headings and mathematical labels
}


def rgb(value):
    """Convert pdf2svg's numeric or percentage RGB values to integer channels."""
    if value.startswith("rgb("):
        return tuple(round(float(v.strip().rstrip("%")) *
                           (2.55 if "%" in v else 1))
                     for v in value[4:-1].split(","))
    if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        return tuple(int(value[i:i + 2], 16) for i in (1, 3, 5))
    raise ValueError(f"Unexpected color: {value}")


def decorate(source):
    """Preserve light print colors; remap all explicit colors on dark screens."""
    drawing = ET.fromstring(source)
    rules = []
    for attr in ("fill", "stroke"):
        colors = sorted({e.attrib[attr] for e in drawing.iter()
                         if attr in e.attrib and e.attrib[attr] != "none"})
        for color in colors:
            rules.append(f'    [{attr}="{color}"] {{ {attr}: {DARK[rgb(color)]}; }}')
    insert = ('\n<title id="figure-title">Conservation, flux bounds, and an optimal face</title>\n'
              '<desc id="figure-desc">A two-flux projection shows steady-state '
              'directions, a bounded feasible polytope, and parallel objective '
              'contours reaching an optimal edge. Three points on that edge '
              'illustrate alternate optima. Its projection onto flux v1 gives '
              'the flux variability range at the optimal objective.</desc>\n'
              '<style id="course-theme">\n'
              '  @media screen and (prefers-color-scheme: dark) {\n' +
              '\n'.join(rules) + '\n  }\n'
              '  @media print { svg { background: white; } }\n</style>\n')
    source = source.replace('<svg ', '<svg role="img" aria-labelledby="figure-title figure-desc" ', 1)
    pos = source.index(">", source.index("<svg")) + 1
    return source[:pos] + insert + source[pos:]


def main():
    """Compile with pdflatex and pdf2svg, retaining diagnostics on failure."""
    for args in [
        ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", STEM + ".tex"],
        ["pdf2svg", STEM + ".pdf", STEM + ".svg"],
    ]:
        result = subprocess.run(args, cwd=HERE, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        if result.returncode:
            raise RuntimeError(result.stdout)
    path = HERE / (STEM + ".svg")
    path.write_text(decorate(path.read_text()))
    for ext in ("aux", "log"):
        (HERE / (STEM + "." + ext)).unlink(missing_ok=True)
    print("Built PDF and theme-aware SVG.")


if __name__ == "__main__":
    main()
