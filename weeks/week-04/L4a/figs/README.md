# L4a figures

Each TikZ figure has its own directory containing a standalone `.tex` source and
`Makefile`. Run `make` in that directory to create its PDF and SVG, or run
`make` here to build all figures. The build requires XeLaTeX, latexmk, and pdf2svg.
Run `make clean` to remove intermediate LaTeX files while retaining the exports.

The slides include the generated PDFs. Notebooks can use the corresponding SVGs,
for example `figs/Fig-Complete-Bipartite-Graph/Fig-Complete-Bipartite-Graph.svg`.
The sources do not depend on the slide deck or its style files.

The complete-graph, bipartite-schematic, and tree-schematic directories also produce a `-panel` version without the title
for slides that already supply a heading. Each pair of versions uses the same figure
source. The full SVGs are also copied to their original flat paths for compatibility.
The lecture notebook uses the bipartite and tree schematics directly from their subfolders.
