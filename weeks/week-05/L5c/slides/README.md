# L5c lecture slides

[PDF deck](CHEME-5800-L5c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L5c-Slides-Fall-2026.tex)

The 30-slide deck follows the [linear-programming lecture](../CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb): the primal form, consumer choice with a condensed apples-versus-oranges example, the *E. coli* consumer-choice aside, minimum-cost flow with the three-node worked network, the consumer dual and the general primal–dual pair, solver checks, the optional algorithm notebooks, and three general key takeaways. Computational setup remains in the notebooks.

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

`da1765266e40336abd9a37bbbef8c18f51383bbde2c92e6b13e3fe44fa0ef6fc`

The figure PDFs are direct vector conversions of the example notebook's [allocation schematic](../figs/Fig-ThreeCases-LP-Schematic.svg) and the lecture's [three-node flow diagram](../figs/Fig-MinCostFlow-ThreeNode.svg). Their source SVGs are unchanged; provenance is recorded in the [lecture figure notes](../figs/README.md).

The LaTeX source maps slide groups to notebook sections and includes source references in Beamer notes. The three apples-versus-oranges slides draw on the [example notebook](../CHEME-5800-L5c-FruitProblem-Primal-Example-Fall-2026.ipynb), which now holds the worked allocation and its geometry. Notes are omitted from the projected PDF. Numerical examples use the lecture's current parameters; the three closing takeaways do not depend on those values.
