# L6a lecture slides

**Review status:** The original deck was approved September 25, 2026 at 9/10. The subsequent requested prose and lecture-synchronization pass is complete; the current deck has 20 slides. See the [review record](../../../../instructor/reviews/L6a-flux-balance-slides-review.md).

[PDF deck](CHEME-5800-L6a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L6a-Slides-Fall-2026.tex)

The 20-slide deck follows the reviewed [Metabolic Engineering and Flux Balance Analysis lecture](../CHEME-5800-L6a-Lecture-FluxBalanceAnalysis-Fall-2026.ipynb). It covers metabolic-network connections, data sources, stoichiometric matrices, the flux balance approximation and linear program, enzyme-capacity bounds, and the simplified bounds model. The urea-cycle example provides the computational work. The SVD example now belongs to L7b and is no longer presented as an L6a example.

The style files and Cornell seal are copied unchanged from the supplied L5c deck, matching the L5a reference. The deck retains their 16:9 format, typography, palette, margins, title page, and footer. Text, equations, and tables are editable in the LaTeX source. The metabolic diagram remains vector artwork, with its editable TikZ master linked below.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The copied style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here, while LaTeX intermediate files go to the repository's ignored `build/slides/L6a/` directory.

`make figures` refreshes the local metabolic-map PDF from the approved figure's light PDF. To change the artwork, edit and rebuild the [TikZ master](../figs/Fig-Central-Metabolism/Fig-Central-Metabolism.tex) following its [figure README](../figs/Fig-Central-Metabolism/README.md), then run `make`. A single untitled slide displays the complete map immediately before “What Is Metabolic Engineering?”

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the figure assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–5 | Complete pathway figure on one untitled slide, followed by the metabolic-engineering definition and early readings |
| 6–8 | Flux balance analysis, network scope and compartments, five biological data resources |
| 9–10 | Stoichiometric matrix and the reaction A + 2B → C |
| 11–13 | Stationary-pool assumptions, the full linear program, and the uptake-positive urea-export objective |
| 14–16 | Annotated flux-bounds model and nomenclature, including enzyme capacity, activity, saturation, and reversibility |
| 17–19 | Simplified bounds, exchange-direction interpretation, and the urea-cycle example |
| 20 | Summary with three general takeaways and the production-limit interpretation |

## Sources

Lecture snapshot SHA-256:

`3620abef9e4dccc30656a71223f930adfa2268147d98a8f3d098bf4797392f57`

The lecture and example links now reflect the urea-cycle focus of L6a. Slide 3
also links directly to the KEGG metabolic pathways map for use during lecture.

The light metabolic-map PDF is copied directly from the lecture's [central-metabolism figure](../figs/Fig-Central-Metabolism/Fig-Central-Metabolism.pdf). Its [source notes](../figs/Fig-Central-Metabolism/README.md) document scientific scope and references. The map is a teaching overview, not a complete stoichiometric model. The single overview slide preserves the complete figure as context for the engineering problem, without a separate pathway-biology discussion.

The LaTeX source includes notebook-section mappings and source references in Beamer notes, omitted from the projected PDF. Resource links and early metabolic-engineering readings come from the lecture. The objective and exchange slides use the urea example's uptake-positive convention: negative exchange flux represents export, so the urea objective has coefficient −1. Computational setup and detailed derivations remain in the linked notebooks.
