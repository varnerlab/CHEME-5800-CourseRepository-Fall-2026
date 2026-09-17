# L5c lecture slides

[PDF deck](CHEME-5800-L5c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L5c-Slides-Fall-2026.tex)

The 30-slide deck follows the [reviewed linear-programming lecture](../CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb): primal and consumer models, worked allocation and geometry, minimum-cost flow, duality, solver checks, and three general key takeaways. Computational setup remains in the notebook.

The three style files and Cornell seal are copied unchanged from the supplied L5a deck. These style files also match the L4a and L4c decks. The deck retains their 16:9 format, typography, colors, margins, title page, and footer.

## Build

From this directory, run:

```sh
make
```

The build requires XeLaTeX, `latexmk`, and `rsvg-convert`. The PDF is written here; LaTeX intermediate files go to the repository's ignored `build/slides/L5c/` directory. The copied style uses Helvetica Neue when available and includes font fallbacks.

`make figures` regenerates the vector figure PDFs. `make clean` removes LaTeX intermediate files; `make distclean` also removes the generated deck and figure PDFs.

## Sources

The lecture snapshot used for the deck has SHA-256:

`8cbe0b38110cba482879b0df5175278ad24111f65c53b8264130a88dd17d3a89`

The figure PDFs are direct vector conversions of the lecture's [allocation schematic](../figs/Fig-ThreeCases-LP-Schematic.svg) and [three-node flow diagram](../figs/Fig-MinCostFlow-ThreeNode.svg). Their source SVGs are unchanged; provenance is recorded in the [lecture figure notes](../figs/README.md).

The LaTeX source maps slide groups to notebook sections and includes source references in Beamer notes. Notes are omitted from the projected PDF. Numerical examples use the lecture's current parameters; the three closing takeaways do not depend on those values.
