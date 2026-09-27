# Old and new values in a Jacobi and a Gauss–Seidel sweep

The editable TikZ source shows five components while component 3 of iteration
k+1 is computed. Jacobi reads every other component from iteration k.
Gauss–Seidel reads components 1 and 2 from iteration k+1, because the sweep has
already updated them, and components 4 and 5 from iteration k. This matches the
component forms of the splittings M = D (Jacobi) and M = D + L (Gauss–Seidel)
in the L6c lecture.

Run `python3 build.py` in this directory. Requires `pdflatex` with TikZ,
`standalone`, Helvetica, and AMS symbols, plus `pdf2svg`.

- `.tex`: editable figure source.
- `.pdf`: light vector output for print and LaTeX.
- `.svg`: transparent outer canvas with light/dark screen palettes and light print colors.

Use the SVG with the notebook's `course-diagram` image block to receive the
editor theme. The build script retains the theme rules when regenerating the SVG.
Text is exported as vector glyphs, so no installed fonts are needed to view it.
