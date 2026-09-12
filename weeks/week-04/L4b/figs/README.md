# L4b network figure

`Fig-Example-Graph.tex` is the TikZ source for the weighted directed graph shared
by the breadth-first algorithm notebook, depth-first algorithm notebook, and lab.
Its six vertices, seven edge directions, and weights match
[`../data/SimpleGraph.txt`](../data/SimpleGraph.txt). The traversal algorithms
ignore the weights; they are retained in the figure for continuity with L4a.

Run `make` in this directory to build the PDF and SVG. The build requires
XeLaTeX, latexmk, pdf2svg, and Python 3. It uses Helvetica Neue when available and falls
back to TeX Gyre Heros. LaTeX intermediate files go to the repository's ignored
`build/figures/L4b/` directory.

The notebooks keep their existing `figs/Fig-Example-Graph.svg` links. The SVG is
generated from the PDF, including vector outlines for its text so that labels
do not depend on fonts installed on students' machines. Edit the TikZ source,
then rebuild both exports; do not edit the generated SVG by hand.
`svg_metadata.py` preserves the original accessible title and graph description
after conversion.
