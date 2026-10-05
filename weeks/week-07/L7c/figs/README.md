# L7c figures

## Linear regression schematic

`Fig-LinearRegressionModel-Schematic/` holds the lecture's regression schematic:
observations, the fitted model line, and the residuals. It was redrawn in TikZ on
October 5, 2026 after the Fall 2025 schematic, which labeled the residual
y<sub>i</sub> − x<sub>i</sub><sup>⊤</sup>β. The new figure uses the lecture's
notation: observations (x<sub>i</sub>, y<sub>i</sub>), the model
x̂<sup>⊤</sup>θ̂ with augmented features x̂, the fitted value
x̂<sub>i</sub><sup>⊤</sup>θ̂ for the highlighted observation, and its residual
r<sub>i</sub> = y<sub>i</sub> − x̂<sub>i</sub><sup>⊤</sup>θ̂. The axes are labeled
with the lecture's words, feature and response. The drawn line is the least-squares fit of the
eight drawn points (their residuals sum to zero and are orthogonal to the feature),
so the picture shows what the lecture's estimate computes.

| File | Role |
|---|---|
| `Fig-LinearRegressionModel-Schematic.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `Fig-LinearRegressionModel-Schematic.pdf` | Light figure for notes and slides |
| `Fig-LinearRegressionModel-Schematic.svg` | Notebook figure |

From that folder, run `make` to rebuild both outputs and `make clean` to remove
the LaTeX temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard
library only). Math is set in the standard TeX fonts, so `\hat{\mathbf{\theta}}`
renders as the same plain θ̂ that the notebook shows.

The palette matches the L7a covariance schematic. `pdf2svg` traces the glyphs to
paths, and `theme_svg.py`, adapted from the CHEME 5660 L5b figure script, adds a
`<style id="course-theme">` block that maps each light color to a dark screen color
under `prefers-color-scheme: dark`. The lecture's image block passes VS Code's
selected theme to the SVG, so changing the editor theme repaints the figure. Print
and the PDF use the light palette. An unmapped color stops the build, so a palette
change in the source must be added to the script's mapping.

## Dot-product schematic

`Fig-InnerProduct-NeedToRedrawThis.png` is the dot-product schematic linked from
the lecture's SVD section, copied unchanged from the Fall 2025 L7c folder on
October 5, 2026. Its file name records that it is due to be redrawn.

PNG SHA-256: `b6661f544e93554d05260dbe691bb553ccad3d74d26291f70d92e9c633802629`
