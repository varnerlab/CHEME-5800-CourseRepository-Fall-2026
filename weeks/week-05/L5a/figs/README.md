# L5a network diagrams

Each slide diagram has a subfolder containing its editable standalone TikZ
source, a Makefile, and generated PDF and SVG files. The shared
`vnflow-figure.tex` file sets the course typography, colors, and arrow styles;
`figure.mk` supplies the common build rules.

| Folder | Diagram |
|---|---|
| `Fig-Residual-FirstFlow` | Initial unit flow through the four-vertex network |
| `Fig-Residual-Augmentation` | Residual path that cancels the earlier middle-edge flow |
| `Fig-Residual-RevisedFlow` | Revised feasible flow of two |
| `Fig-Cut-Balance` | A feasible flow of one crossing a cut of capacity two |
| `Fig-Cut-Optimality` | A maximum flow of two, with saturated outgoing cut edges and zero return flow |
| `Fig-Worker-SourceCut` | Three source-to-worker edges in the supplied assignment network |

From this directory, build all diagrams with `make`, or build one with:

```sh
make -C Fig-Cut-Optimality
```

The build requires XeLaTeX, `latexmk`, and `pdf2svg`. To build only a PDF:

```sh
make -C Fig-Cut-Optimality Fig-Cut-Optimality.pdf
```

Run `make clean` to remove temporary compilation files while keeping the PDF
and SVG exports. The slide Makefile builds the figures it needs automatically.

The cut diagrams use the same five-vertex network and the partition
`S = {s, a}`, `T = {b, c, t}`. In the balance diagram, two units cross from
S to T and one returns, giving net flow one. In the optimality diagram,
the return flow is canceled and that unit reaches the sink instead, giving
net flow two. At this point, exactly s and a are reachable from s in the
residual graph.

`Fig-L5a-ResidualRerouting.svg` is the existing lecture-notebook figure.
The slides use the three standalone TikZ panels listed above.
