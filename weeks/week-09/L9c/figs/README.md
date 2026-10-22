# L9c figures

## Gradient descent schematic

`Fig-GD-Schematic/` holds the lecture's gradient descent schematic: a loss with a
local minimum θ<sub>2</sub> and a lower minimum θ<sub>1</sub>, and the
negative gradients at two starting points, θ<sub>3</sub> and θ<sub>0</sub>. It was
redrawn in TikZ on October 9, 2026 after the Fall 2025 schematic, which set its
labels with a capital theta and no subscripts. The new figure uses the lecture's
notation: lowercase θ with subscripts and the gradient written ∇<sub>θ</sub>. The
four point colors are the 2025 figure's.

| File | Role |
|---|---|
| `Fig-GD-Schematic.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `Fig-GD-Schematic.pdf` | Light figure for notes and slides |
| `Fig-GD-Schematic.svg` | Notebook figure |

From that folder, run `make` to rebuild both outputs and `make clean` to remove
the LaTeX temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard
library only). `pdf2svg` traces the glyphs to paths, so the SVG needs no fonts.
`theme_svg.py`, adapted from the L7c figure script, adds a `<style id="course-theme">`
block that maps each light color to a dark screen color under
`prefers-color-scheme: dark`. An unmapped color stops the build, so a palette
change in the source must be added to the script's mapping.

## Logistic function figure

`Fig-Logistic-Function/` holds the figure that opens the lecture's Logistic
Regression section: the probability of the label y = +1 against the score
x̂<sup>⊤</sup>θ, P = σ(2βx̂<sup>⊤</sup>θ), for β = 1/4, 1, and 4, with dashed guides at
probability 1/2 and at the decision boundary. It was drawn in TikZ on October 9, 2026
with the same palette, Makefile, and theme script as the gradient descent schematic.
pgfmath overflows above exp(9.7), so each curve is drawn in two halves that only
exponentiate a non-positive number; the `.tex` comments explain this.

## Simulated annealing schematic

`Fig-SA-Schematic/` holds the figure in the lecture's Simulated Annealing section.
It redraws the gradient descent schematic's loss curve, with the same palette and
notation, so the two figures can be compared directly. Started at θ<sub>3</sub>,
simulated annealing moves downhill to the local minimum θ<sub>2</sub>, where
gradient descent stops. At a high temperature it accepts an uphill move of size
ΔP toward the hump (orange) and moves downhill to θ<sub>1</sub>; at a low
temperature it rejects a large uphill move away from θ<sub>1</sub> (dashed gray).
It was drawn in TikZ on October 19, 2026, with the same Makefile and theme script as
the gradient descent schematic; the script maps the new orange to a dark color.

## Convexity figure

`Fig-Convexity/` holds the two-panel figure in the lecture's How Good Is Gradient
Descent? subsection. The left panel draws a convex loss, x<sup>2</sup> rotated by
20°, with the chord from f(**a**) to f(**b**) above the graph and the gap at
t**a** + (1 − t)**b** marked. The right panel redraws the gradient descent
schematic's loss with the chord from θ<sub>2</sub> to θ<sub>1</sub>, which the
hump rises above. It was drawn in TikZ on October 22, 2026, with the same palette,
Makefile, and theme script as the gradient descent schematic; the `.tex` comments
record how the rotated parabola's points were computed.
