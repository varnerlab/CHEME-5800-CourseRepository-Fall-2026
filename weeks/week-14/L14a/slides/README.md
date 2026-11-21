# L14a lecture slides

[PDF deck](CHEME-5800-L14a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L14a-Slides-Fall-2026.tex)

The 21-slide deck follows the [Linear State Space Models and Stability lecture](../CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb) in its order. It opens with the linear time-invariant state space model and the open-loop solution, then covers eigenvectors, the eigendecomposition, and modes, with the eigenvectors and modes figure. It reads stability from the real part of each eigenvalue, gives the two-state test with the trace and the determinant, and shows the phase portraits on two slides, one for real and one for complex eigenvalues.

It then derives the forced solution in three steps, builds the bilinear discretization of the S4 sequence model from the trapezoid rule, and shows that the recursion keeps the stability of the continuous model. It closes with linearization about an operating point and about a steady state, the example, and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Written on November 20, 2026, after the lecture gained its dimension declarations, the capital Δ deviations, the determinant written as det(**A**), and the braces on Euler's formula. The first external review pass (8.5/10) led to five fixes: the example's peak rise, four symbol definitions, shorter takeaways, and the phase portraits split across two slides. The second pass rated the deck 9.2/10. The deck has no overfull or underfull boxes. Approved by the instructor on November 20, 2026.

The style files and Cornell seal are copied unchanged from L13a (identical to L13c, L12c, L12a, L10c, L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text and equations are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L14a/` directory.

`make figures` copies the two lecture figures into `assets/`, which the deck includes. Each figure is the light TikZ PDF in its [figure folder](../figs/), copied unchanged.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4 | The continuous-time LTI state space model, with the dimensions of the state, the input, and the two matrices |
| 5 | The open-loop solution and the matrix exponential |
| 6–7 | Eigenvectors, the eigendecomposition, and the modes of the model |
| 8 | Eigenvectors and modes (figure) |
| 9 | Euler's formula: the real part sets growth or decay, and the imaginary part sets the oscillation |
| 10 | Stability of the open-loop model, and the two-state test with the trace and det(**A**) |
| 11–12 | Phase portraits: the stable node and the saddle, then the center and the stable spiral (figure, one row per slide) |
| 13 | The forced solution, in three steps |
| 14–15 | S4, the trapezoid rule, and the bilinear discretization |
| 16 | The recursion keeps stability, and its error scales with Δt² |
| 17–18 | Linearization about an operating point: the deviations, the Taylor expansion, the Jacobians, and the constant term |
| 19 | Linearization about a steady state, and the three cases for the eigenvalues |
| 20 | Example: linearizing a gene circuit |
| 21 | Summary: three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch. Slide 6 links the advanced eigenvalue notebook, and slide 16 links the stability derivation.

The deck uses the lecture's notation: the state **x** with n states, the input **u** with d inputs, the state matrix **A**, the input matrix **B**, the modes, the trace τ and det(**A**), the step Δt, the discrete matrices Ā and B̄, the operating point, and the deviations Δ**x** and Δ**u**. The forced-solution derivation is condensed from seven lines to three, and the bilinear derivation is shown through its factored step. The objectives and takeaways are shortened from the lecture's to fit the slide format; they make the same claims. The two figures are the lecture's figures. Slides 11 and 12 each show one row of the phase portrait figure, cropped in LaTeX so that the panels are large enough to project; the figure file is unchanged.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb | `2709d6253831f03396abd1bd5ddd384d773590e2875381b2e8fe1aa0062aad40` |
| CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb | `df641aac3b951437753b1e37df99d9e5ed7bae0772f32cb7fe3ca6dad5d07d15` |
