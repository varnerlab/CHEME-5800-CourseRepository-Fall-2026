# L5b cut diagrams

Each diagram has a subfolder containing its editable standalone TikZ source, a
Makefile, and generated PDF and SVG files. `vnflow-figure.tex` is a copy of the
L5a typography, colors, and arrow styles; `figure.mk` supplies the common build
rules, and `theme_svg.py` adds the dark-screen palette the notebook needs.

| Folder | Diagram |
|---|---|
| `Fig-Baseline-SourceCut` | The baseline maximum flow of three with the cut `S = {1}` |
| `Fig-Expanded-SourceCut` | The expanded maximum flow of four after edge `(1, 3)` gains capacity two |
| `Fig-Outage-WorkerCut` | The outage maximum flow of two after worker 3's outgoing edges are blocked, with the cut `S = {1, 3}` |

All three diagrams draw the full 13-node worker–task network from the lab's edge
list and the Edmonds–Karp solutions the notebook computes. Red edges cross the
cut from `S` to `T`, dashed where the capacity is zero; gray edges carry flow inside `T`; light edges carry no flow.

From this directory, build every diagram with `make`, or build one with:

```sh
make -C Fig-Baseline-SourceCut
```

The build requires XeLaTeX, `latexmk`, and `pdf2svg`. Run `make clean` to
remove temporary compilation files while keeping the PDF and SVG exports.
