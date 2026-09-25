# L6a lecture slides

**Review status:** The original deck was approved September 25, 2026 at 9/10. A second synchronization pass on September 25 followed the instructor's hand edits to the lecture and example; the current deck has 21 slides. See the [review record](../../../../instructor/reviews/L6a-flux-balance-slides-review.md).

[PDF deck](CHEME-5800-L6a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L6a-Slides-Fall-2026.tex)

The 21-slide deck follows the instructor-edited [Metabolic Engineering and Flux Balance Analysis lecture](../CHEME-5800-L6a-Lecture-FluxBalanceAnalysis-Fall-2026.ipynb) in its order: FBA definition and linear-program geometry, stoichiometric matrix with the control-volume example and exchange reactions, the flux-bounds model, then the boxed FBA problem and the urea-cycle example. The urea-cycle example provides the computational work. The SVD example now belongs to L7b and is no longer presented as an L6a example.

The style files and Cornell seal are copied unchanged from the supplied L5c deck, matching the L5a reference. The deck retains their 16:9 format, typography, palette, margins, title page, and footer. Text, equations, and tables are editable in the LaTeX source. The metabolic diagram remains vector artwork, with its editable TikZ master linked below.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The copied style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here, while LaTeX intermediate files go to the repository's ignored `build/slides/L6a/` directory.

`make figures` refreshes the three local figure PDFs (metabolic map, linear-program geometry, control volume) from the lecture figure folders. To change the artwork, edit and rebuild the [TikZ master](../figs/Fig-Central-Metabolism/Fig-Central-Metabolism.tex) following its [figure README](../figs/Fig-Central-Metabolism/README.md), then run `make`. A single untitled slide displays the complete map immediately before “What Is Metabolic Engineering?”

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the figure assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–5 | Complete pathway figure on one untitled slide, followed by metabolic engineering and early readings |
| 6–7 | Flux balance analysis definition and components; conservation, bounds, and alternate optima figure |
| 8–11 | Stoichiometric matrix from a reconstruction, five data resources, the control-volume column example, exchange reactions |
| 12–14 | Annotated flux-bounds model and nomenclature, including enzyme capacity, activity, saturation, and reversibility |
| 15–16 | Simplified bounds model and exchange-bound interpretation |
| 17–19 | Flux balance approximation, the boxed FBA problem, and the uptake-positive urea-export objective |
| 20 | Urea-cycle example: build, bound, solve, check |
| 21 | Summary with three key takeaways and the metabolic-engineering closing |

## Sources

Lecture snapshot SHA-256:

`8ab18b5fed68b8a2a3a76c954cd1964c704a87bfb5db7a66b22335d74af67f9c`

The lecture and example links now reflect the urea-cycle focus of L6a. Slide 3
also links directly to the KEGG metabolic pathways map for use during lecture.

The light metabolic-map PDF is copied directly from the lecture's [central-metabolism figure](../figs/Fig-Central-Metabolism/Fig-Central-Metabolism.pdf). The geometry and control-volume PDFs are copied from [Fig-FBA-FeasibleSpace](../figs/Fig-FBA-FeasibleSpace/) and [Fig-Stoichiometric-ControlVolume](../figs/Fig-Stoichiometric-ControlVolume/). Its [source notes](../figs/Fig-Central-Metabolism/README.md) document scientific scope and references. The map is a teaching overview, not a complete stoichiometric model. The single overview slide preserves the complete figure as context for the engineering problem, without a separate pathway-biology discussion.

The LaTeX source includes notebook-section mappings and source references in Beamer notes, omitted from the projected PDF. Resource links and early metabolic-engineering readings come from the lecture. The objective and exchange slides use the urea example's uptake-positive convention: negative exchange flux represents export, so the urea objective has coefficient −1. Computational setup and detailed derivations remain in the linked notebooks.
