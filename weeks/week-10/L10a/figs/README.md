# L10a figures

## Agent and environment schematic

`Fig-Schematic-RL.svg` opens the lecture's General Reinforcement/Online Learning
Problem section: an agent takes an action, and the environment returns a reward
and the next state. It is an SVG with a dark-mode style block. The slide deck
converts it to a light PDF with `rsvg-convert`; see `../slides/Makefile`.

## Weighted majority vote

`Fig-WMA-Weights/` holds the figure in the lecture's worked example of the
weighted majority algorithm. Each of the four rounds is drawn as a tug of war:
every expert is a numbered block, as wide as its weight before the round, on the
side it predicted (down to the left, up to the right). Columns headed weight
voting add up the weights of the experts on each side, with the heavier total in bold, and that side is our
prediction. The outcome's side
is shaded, so blocks on the other side are the mistakes: they are outlined in red
and are half as wide in the next round (ε = 1/2). Our prediction is outlined in
red in the rounds we get wrong. Red is reserved for mistakes, so no expert is
drawn in red, orange, or green. The values come from the worked-example table.
It was drawn in TikZ on October 19, 2026 with the palette, Makefile, and theme
script of the week-9 figures; it replaced an earlier line chart of the weights.

| File | Role |
|---|---|
| `Fig-WMA-Weights.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `Fig-WMA-Weights.pdf` | Light figure for notes and slides |
| `Fig-WMA-Weights.svg` | Notebook figure |

From that folder, run `make` to rebuild both outputs and `make clean` to remove
the LaTeX temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard
library only). An unmapped color stops the build, so a palette change in the
source must be added to the script's mapping.
