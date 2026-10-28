# L11a lecture slides

[PDF deck](CHEME-5800-L11a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L11a-Slides-Fall-2026.tex)

The 15-slide deck follows the [Markov Models lecture](../CHEME-5800-L11a-Lecture-MarkovModels-Fall-2026.ipynb) in its order: the Markov model tuple and the state space with its two examples, the Markov property, the one-step transition probabilities, and why the Markov property matters, the transition matrix schematic and its three properties, the stationary distribution with its steady-state analogy and the power iteration algorithm, the left vector-matrix product with the ergodicity and spectral gap notes, the three-state example, the lab, and the Summary. Three learning objectives align with three closing takeaways.

**Review status:** Built October 26, 2026; not yet reviewed by the instructor. A read-only codex review scored the first build 8.8/10 and found every equation and claim faithful to the notebooks. Its four findings were applied: the one-step slide and the Summary no longer name another lecture (the course rule of October 15), the power iteration output line now covers the iteration-limit case, the third takeaway states the ergodic assumption, and the example slide says the state frequencies are similar rather than equal. The deck was not re-scored after these fixes. The same day, the lecture regained its Fall 2025 subsection "Why the Markov Property Matters", and the deck gained a slide for it; after instructor review, its "Why is this cool?" box was removed from both, since it previewed later material. The build has no overfull or underfull boxes.

The style files and Cornell seal are copied unchanged from L10c (identical to L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L11a/` directory.

`make figures` refreshes the transition matrix, vector-matrix product, and three-state chain figures in `assets/` from the lecture's [figure folder](../figs/) with `rsvg-convert` (librsvg), which ignores each SVG's dark-mode style block and writes the light colors. As in the L10a deck, the rule adds `xml:space="preserve"` to the SVG's text on the way in, so librsvg keeps the spaces inside labels. The notebook SVGs are unchanged.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4 | Discrete Markov model states: the tuple $(\mathcal S,\mathbf P)$ and the two state-space examples |
| 5–7 | The Markov property definition and the modeling assumption; one-step transition probabilities and time-homogeneity; why the Markov property matters |
| 8–9 | The transition matrix schematic; its three properties |
| 10–11 | The stationary distribution and $\pi_k=\pi_0\mathbf P^k$; the power iteration algorithm |
| 12 | The left vector-matrix product schematic, ergodicity, and the spectral gap |
| 13 | Example: the three-state chain and the example's three tasks |
| 14 | Lab: a Markov word generator |
| 15 | Summary with three key takeaways |

The lecture's Lab section also links an optional position-aware protein-generator
example. It is an extension for students to explore and does not add a separate
slide to the core 15-slide deck.

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the model $\mathcal M=(\mathcal S,\mathbf P)$, states $s_1,\ldots,s_N$, the state $X_n$ at time step $n$, one-step probabilities $p_{ij}$, row distributions $\pi_n$, the stationary distribution $\bar\pi$, the tolerance $\epsilon$, the iteration limit $T$, and the counter $t$. The three-state schematic comes from the example notebook; the lecture itself does not show it. The example slide gives no transition probabilities, seeds, or sample counts, since those are set in the example's code cells. The Summary closes with the example's closing sentence.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L11a-Lecture-MarkovModels-Fall-2026.ipynb | `c7cf559c77804de3f732407a2e25df6ef8499887d839213baa11f88e05cf5627` |
| CHEME-5800-L11a-Example-MarkovModels-Fall-2026.ipynb | `8bb3e71337bcb673ab0935d9da9c0f72d76f5c4ff1f77476fb4eca5e565c6d70` |
| CHEME-5800-L11b-Lab-MarkovWordGenerator-Fall-2026.ipynb | `ac579c52fc6b3422c2c6198d3917e5288c3e7da67449638c81643cf7447d10d1` |
