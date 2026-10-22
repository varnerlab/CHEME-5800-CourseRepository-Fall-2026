# L10a lecture slides

[PDF deck](CHEME-5800-L10a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L10a-Slides-Fall-2026.tex)

The 18-slide deck follows the [Online Learning lecture](../CHEME-5800-L10a-Lecture-OnlineLearningAndRegret-Fall-2026.ipynb) in its order: the agent and environment schematic and the three families of methods, the online learning game and regret, online versus supervised learning and the best expert as the comparator, the weighted majority algorithm with its pseudocode, the four-round worked example and its weighted-vote figure, the mistake guarantee, and why we choose an expert at random, then the multiplicative weights problem setting, pseudocode, and regret bound, the comparison of the two guarantees, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 19, 2026; not yet reviewed by the instructor. A read-only codex review found no mathematical or factual errors and no layout problems (8.8/10). Its top suggestion was adopted: the multiplicative weights guarantee now states an upper bound on the expected cost, $2\sqrt{T\ln n}$ above the best expert's, and the loss-convention line says the signed-cost regret is twice the expected regret counted in mistakes. The lab bullets were merged and the weights figure enlarged. "About twice" became $2(1+\epsilon)$ when the lecture adopted it. The weights line chart was replaced by a weighted-vote figure that draws each round as a tug of war between the up and down experts, so each mistake shows as a block on the side opposite the outcome; its slide drops the lead-in to give the figure room. The build has no overfull or underfull boxes.

**Synced October 21, 2026** with the lecture's revised weighted majority section. Both pseudocode slides now follow the lecture's Initialize line ("Given ..., set ... $\gets$ ...") and its If/Otherwise branches. The Goal and the mistake guarantee name the additive term a constant, $2\ln n/\epsilon$, that does not depend on the number of rounds. A new slide, "Why Choose an Expert at Random?", carries the lecture's argument that an adversary can defeat any deterministic vote, which motivates the multiplicative weights algorithm. The comparison table states the learning rate behind the $2\sqrt{T\ln n}$ bound, and the Summary takeaways were shortened to the L6a shape, with no symbols. A read-only codex review of the synced deck scored it 9.4/10 and found no errors; its three minor suggestions were adopted: the problem-setting slide names $\mathbf p^{(t)}$ as our distribution over experts, the comparison table adds $T\ge4\ln n$ to the tuned bound, and the first two objectives were tightened.

The style files and Cornell seal are copied unchanged from L9a (identical to L7c, L7a, and L6c, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L10a/` directory.

`make figures` refreshes the two figures in `assets/`. The agent and environment schematic is converted from the lecture's [SVG figure](../figs/Fig-Schematic-RL.svg) with `rsvg-convert` (librsvg), which ignores the SVG's dark-mode style block and writes the light colors; the rule adds `xml:space="preserve"` to the SVG's text on the way in, because the "state s to s′" label places each piece at a fixed position and librsvg otherwise drops the space before "to". The weighted majority figure is the light PDF from [its TikZ folder](../figs/Fig-WMA-Weights/).

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–2 | Title and three learning objectives |
| 3–4 | The reinforcement and online learning problem, with the agent and environment schematic; the three families of methods and the feedback each uses |
| 5–6 | The online learning game and the regret; online versus supervised learning, and the best single expert as the comparator |
| 7–8 | The weighted majority game and goal; its pseudocode |
| 9–10 | The four-round worked example table; the weighted-vote figure and the regret |
| 11–12 | The mistake guarantee; why a deterministic vote can be defeated and why we choose an expert at random |
| 13–14 | The multiplicative weights problem setting, expected cost, and regret; its pseudocode |
| 15–16 | The regret bound and the choice of $\eta$; the comparison of the two guarantees and the loss conventions |
| 17 | Lab: the weighted majority algorithm on the stock market |
| 18 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: experts $i=1,\ldots,n$, rounds $t=1,\ldots,T$, weights $w_i^{(t)}$, the learning rates $\epsilon$ and $\eta$, the distribution $\mathbf p^{(t)}$, signed costs $m_i^{(t)}$, mistakes $M^{(t)}$ and $M_i^{(t)}$, and the regret $R(T)$. The lecture has no example notebook, so there is no example slide. The multiplicative weights pseudocode states the cost rule inline rather than as the lecture's cases display, so the algorithm fits on one slide.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L10a-Lecture-OnlineLearningAndRegret-Fall-2026.ipynb | `a9ce95ca7f2e2f8aec333f4f4c6f301c2edcbd5b012b5f71c08a523304b3f6bc` |
| CHEME-5800-L10b-Lab-WeightedMajorityAlgorithm-Fall-2026.ipynb | `aba703cff2fc3481f8739663d785b097219b8bc2607df7214242077d1b186e52` |
