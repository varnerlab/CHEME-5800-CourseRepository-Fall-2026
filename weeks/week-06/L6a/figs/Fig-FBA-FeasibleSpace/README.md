# Geometry of flux balance analysis

Adapted from Jeffrey D Varner's lab chapter figure:

- Repository: https://github.com/varnerlab/MRW-BTC4-Chapter-Varner
- Source: `chapter/figures/lp_geometry_fig/lp_geometry.tex`
- Commit: `881056b3c3c57d83036f2c219d81c848d763118d`
- Copyright (c) 2026 Jeffrey D Varner, MIT license; see [LICENSE](LICENSE).

The lecture version preserves the lab figure's layout, polygon, conservation
directions, optimal edge, alternate optima, and flux variability interval.
Changes are limited to the lecture's lower/upper bound notation, exact parallel
objective contours, and a theme-aware SVG export. This replaces the earlier
three-flux illustration derived from the conceptual sequence in Orth et al.

## Interpretation and geometry

The drawing is a schematic two-flux projection of a higher-dimensional flux
space, not the full state space of a model with only two reactions. The first
panel already imposes the steady-state balance equations. Its visible open
plane represents a projection of the null space. Bounds then define the
displayed bounded feasible polygon. The last panel illustrates an objective
that is constant along an entire optimal edge.

For the displayed polygon, an objective proportional to `10 v1 + 3 v2`
supports the edge joining `(3.80, 1.35)` and `(3.20, 3.35)`. Both endpoints
and their midpoint have objective value 42.05, while every other vertex has
a lower value. The indicated interval for v1 is `[3.20, 3.80]`.
These are drawing coordinates, not measured fluxes. The contour slope is
exactly `-10/3`, and the objective arrow is normal to the contours.

The illustration assumes a nonempty, bounded feasible region. Other problems
can have an empty or unbounded feasible set. Flux variability analysis at the
optimal objective finds the minimum and maximum of each reaction flux over
the optimal set; it does not imply that these flux intervals can be combined
independently.

## Rebuild

Run `python3 build.py` here. Requires Python 3, `pdflatex` with TikZ,
`standalone`, Helvetica, and AMS math, plus `pdf2svg`.

- `Fig-FBA-FeasibleSpace.tex`: editable TikZ source adapted from the lab.
- `Fig-FBA-FeasibleSpace.pdf`: light vector output for print and LaTeX.
- `Fig-FBA-FeasibleSpace.svg`: transparent outer canvas, light/dark screen
  palettes, and light print colors. Vector glyphs preserve the typography.

The lecture's `course-diagram` image block propagates the editor theme.
The build script regenerates all SVG theme rules on each build.
