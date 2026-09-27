#!/usr/bin/env python3
"""Build the TikZ PDF and an SVG that follows the notebook's light/dark theme."""
import re
import subprocess
from pathlib import Path
from xml.etree import ElementTree as ET

HERE = Path(__file__).resolve().parent
STEM = "Fig-Jacobi-GaussSeidel-Sweep"
DARK = {
    (30, 41, 59): "#e6edf5",     # text
    (83, 98, 119): "#b4c1d2",    # notes and old-value arrows
    (148, 163, 184): "#8294ad",  # old-value borders
    (243, 246, 250): "#202d3d",  # old-value fill
    (36, 99, 168): "#7db9f2",    # updated values
    (220, 234, 245): "#203b54",  # updated-value fill
    (19, 123, 105): "#79cfba",   # component being computed
    (221, 241, 236): "#1b3d37",  # component being computed, fill
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
    insert = ('\n<title id="figure-title">Old and new values in a Jacobi and a '
              'Gauss–Seidel sweep</title>\n'
              '<desc id="figure-desc">Two rows of five components show which values '
              'each method reads when it computes component three of iteration k '
              'plus one. Jacobi reads every other component from iteration k. '
              'Gauss–Seidel reads components one and two from iteration k plus one, '
              'because they are already updated, and components four and five from '
              'iteration k.</desc>\n'
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
