#!/usr/bin/env python3
"""Add a dark screen palette to a notebook SVG exported from mdp-figure.tex.

Keep the original drawing and light/print colors intact. Match the rounded RGB
colors rather than pdf2svg's fractional percentages, which vary across versions.
"""

import re
import sys
from pathlib import Path
from xml.etree import ElementTree


# Original TikZ color -> dark screen color (same meaning, adjusted contrast).
DARK_COLORS = {
    (0, 0, 0): "#e5e7eb",        # text
    (255, 255, 255): "#1f1f1f",  # label backings (match the editor canvas)
    (51, 51, 51): "#d1d5db",     # action dots
    (64, 64, 64): "#cbd5e1",     # arrows and arrowheads
    (76, 76, 76): "#9aa3ad",     # grid lines
    (102, 102, 102): "#9ca3af",  # axes and ticks
    (115, 115, 115): "#a3a9b1",  # notes
    (178, 89, 0): "#f0a050",     # chosen action, focus state
    (255, 229, 204): "#4a3420",  # focus state fill
    (217, 217, 217): "#41464d",  # obstacle
    (219, 255, 219): "#1f3d27",  # goal
    (224, 224, 255): "#26304f",  # state fill
    (0, 0, 153): "#8fa8ff",      # state outline
    (191, 191, 191): "#6b7280",  # dashed landing spots
}


def rgb(color):
    if color.startswith("rgb("):
        return tuple(round(float(v.strip().rstrip("%")) *
                           (255 / 100 if "%" in v else 1))
                     for v in color[4:-1].split(","))
    if re.fullmatch(r"#[0-9a-fA-F]{6}", color):
        return tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))
    raise ValueError(f"Unsupported SVG color: {color}")


def theme_svg(path):
    source = path.read_text()
    # Re-running the postprocessor replaces its own style block.
    source = re.sub(r'<style id="course-theme">.*?</style>\n?', "", source,
                    flags=re.DOTALL)
    drawing = ElementTree.fromstring(source)
    rules = []
    for attribute in ("fill", "stroke"):
        colors = sorted({e.attrib[attribute] for e in drawing.iter()
                         if attribute in e.attrib and e.attrib[attribute] != "none"})
        for color in colors:
            # Fail on an unrecognized color so a changed TikZ palette is reviewed.
            dark = DARK_COLORS[rgb(color)]
            rules.append(f'    [{attribute}="{color}"] {{ {attribute}: {dark}; }}')
    style = ('<style id="course-theme">\n'
             '  @media screen and (prefers-color-scheme: dark) {\n' +
             '\n'.join(rules) + '\n  }\n'
             '  @media print { svg { background: white; } }\n</style>\n')
    end = source.index(">", source.index("<svg")) + 1
    path.write_text(source[:end] + "\n" + style + source[end:].lstrip("\n"))


if __name__ == "__main__":
    for filename in sys.argv[1:]:
        theme_svg(Path(filename))
