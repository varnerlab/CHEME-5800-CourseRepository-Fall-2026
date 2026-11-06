# L12c figures

## Q-networks

`Fig-Q-Networks/` holds the figure in the lecture's Q-Networks section. Both panels map a state
s to one Q-value per action. The top panel is the linear Q-network of the example: gray arrows
send the state to fixed features φ₁, …, φₚ, and blue lines, the learned weights W, join every
feature to every Q-value. The bottom panel is a deep Q-network: the state enters a shaded box
of three hidden layers, all learned, and one arrow fans out to the Q-values. The bottom panel is
adapted from the DQN schematic of the eCornell AI in finance session 3 lecture (May 2026).

It was drawn in TikZ on November 6, 2026 with the palette, Makefile, and theme script of the
L10c figures.

| File | Role |
|---|---|
| `Fig-Q-Networks.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `Fig-Q-Networks.pdf` | Light figure for notes and slides |
| `Fig-Q-Networks.svg` | Notebook figure |

From the folder, run `make` to rebuild both outputs and `make clean` to remove the LaTeX
temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard library only). An
unmapped color stops the build, so a palette change in the source must be added to the script's
mapping.
