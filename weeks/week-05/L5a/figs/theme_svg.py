#!/usr/bin/env python3
"""Add a dark screen palette to a notebook SVG exported from vnflow-figure.tex.

Keep the original drawing and light/print colors intact. Match the rounded RGB
colors rather than pdf2svg's fractional percentages, which vary across versions.
"""

import re
import sys
from pathlib import Path
from xml.etree import ElementTree


# Original TikZ color -> dark screen color (same meaning, adjusted contrast).
DARK_COLORS = {
    (255, 255, 255): "#232830",  # node and label surfaces
    (51, 51, 51): "#cbd5e1",    # node outlines
    (94, 94, 94): "#d4dae2",    # body text, edges, and arrowheads
    (255, 100, 78): "#ff8879",  # saturated cut edges
    (87, 154, 202): "#84bee8",  # return edge and S label
    (247, 250, 252): "#243647", # S partition
    (250, 250, 250): "#282d35", # T partition
    (163, 199, 226): "#466681", # S border
    (190, 195, 198): "#626d7a",  # T border
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
