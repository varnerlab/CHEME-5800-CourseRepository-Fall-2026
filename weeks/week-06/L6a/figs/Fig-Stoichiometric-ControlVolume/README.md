# Stoichiometric reaction and control volume

The editable TikZ source shows `∅ → A + 2B → C → ∅`, with a dashed
control-volume boundary around the internal reaction. The exterior arrows show
material-flow directions, not a choice of exchange-flux sign convention.
The inlet groups the supply of A and B schematically; in the model, their
individual exchange reactions have separate stoichiometric columns.

Run `python3 build.py` in this directory. Requires `pdflatex` with TikZ,
`standalone`, Helvetica, and AMS symbols, plus `pdf2svg`.

- `.tex`: editable figure source.
- `.pdf`: light vector output for print and LaTeX.
- `.svg`: transparent outer canvas with light/dark screen palettes and light print colors.

Use the SVG with the notebook's `course-diagram` image block to receive the
editor theme. The build script retains the theme rules when regenerating the SVG.
Text is exported as vector glyphs, so no installed fonts are needed to view it.
