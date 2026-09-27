# Error bound against the number of corrections

The pgfplots source draws the bound q^k E_0 with E_0 = 1 for contraction
factors q = 0.5, 0.8, and 0.9 on a logarithmic axis, with the solution-error
tolerance 10^-3 dashed. These are bounds, not simulated iterations. Each marker
is the smallest k with q^k E_0 <= 10^-3, that is ceil(ln(1000)/(-ln q)):
10, 31, and 66. The q = 0.5 count matches the worked example in the L6c lecture.

Run `python3 build.py` in this directory. Requires `pdflatex` with pgfplots,
`standalone`, Helvetica, and AMS symbols, plus `pdf2svg`.

- `.tex`: editable figure source.
- `.pdf`: light vector output for print and LaTeX.
- `.svg`: transparent outer canvas with light/dark screen palettes and light print colors.

Use the SVG with the notebook's `course-diagram` image block to receive the
editor theme. The build script retains the theme rules when regenerating the SVG.
Text is exported as vector glyphs, so no installed fonts are needed to view it.
