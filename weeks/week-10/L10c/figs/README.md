# L10c figures

## Bandit arms

`Fig-Bandit-Arms/` holds the figure that opens the lecture's What Is a Bandit
Problem? section. Four arms are drawn as vertical reward axes from 0 to 1, each
with its reward distribution beside it and a tick at its mean reward. A dashed
line marks the best mean reward, and a red bracket marks the gap of arm 1. Arm 2
is the pulled arm: it is shaded blue and shows its one observed reward as a dot,
while the other arms are labeled as reporting nothing. The distributions are
Beta(3, 5), Beta(5, 4), Beta(7, 3), and Beta(4, 5), the family the lab's arms
use; the source lists their means.

## UCB1 worked example

`Fig-UCB-Example/` holds the figure in the lecture's UCB1 worked example. Each of
the two arms is a row on a reward scale: an open dot at its sample mean and a bar
that extends by its confidence radius to its upper confidence bound (arm 1:
0.750 + 0.947 = 1.697; arm 2: 0 + 1.893 = 1.893). The selected arm, arm 2, is
blue, and a dashed line marks the largest possible reward, 1.

Both were drawn in TikZ on October 20, 2026 with the palette, Makefile, and theme
script of the L10a weighted majority figure. On October 22, 2026, their labels
were enlarged so they stay readable on the slides, which scale the figures down.

## Thompson sampling worked example

`Fig-Thompson-Example/` holds the figure on the slide deck's Thompson sampling
worked example; the lecture does not use it yet. Each of the two arms is a row on
a success-probability scale with its posterior density above it, a tick at the
posterior mean, and a dot at its posterior sample: arm 1, Beta(4, 2) with mean
2/3 and sample 0.55; arm 2, Beta(1, 2) with mean 1/3 and sample 0.70. The
selected arm, arm 2, is blue. It was drawn on October 21, 2026 with the palette
and build of the bandit arms figure.

| File | Role |
|---|---|
| `Fig-*.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `Fig-*.pdf` | Light figure for notes and slides |
| `Fig-*.svg` | Notebook figure |

From either folder, run `make` to rebuild both outputs and `make clean` to remove
the LaTeX temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard
library only). An unmapped color stops the build, so a palette change in the
source must be added to the script's mapping.
