# L14a lecture slides

[PDF deck](CHEME-5800-L14a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L14a-Slides-Fall-2026.tex)

The 23-slide deck follows the [Linear State Space Models and Stability lecture](../CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb) in its order. It opens with the linear time-invariant state space model and the open-loop solution, then covers eigenvectors, the eigendecomposition, and modes, with the eigenvectors and modes figure. It reads stability from the real part of each eigenvalue, gives the two-state test with the trace and the determinant, and shows the phase portraits on two slides, one for real and one for complex eigenvalues.

It then derives the forced solution in three steps and defines a discretization. It builds the bilinear discretization from the trapezoid rule and the zero-order hold from the exact solution over one step, and shows that each recursion keeps the stability of the continuous model. It closes with linearization about an operating point and about a steady state, the example, and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Written on November 20, 2026, after the lecture gained its dimension declarations, the capital Δ deviations, the determinant written as det(**A**), and the braces on Euler's formula. The first external review pass (8.5/10) led to five fixes: the example's peak rise, four symbol definitions, shorter takeaways, and the phase portraits split across two slides. The second pass rated the deck 9.2/10. The deck has no overfull or underfull boxes. Approved by the instructor on November 20, 2026. Updated on November 23, 2026, to match the revised lecture: the sequence-model references were removed, the objectives and takeaways now cover both discretizations, and two zero-order hold slides were added. The update has not yet been reviewed by the instructor.

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
| 14–15 | A discretization, the trapezoid rule, and the bilinear discretization |
| 16 | The bilinear recursion keeps stability, and its error scales with Δt² |
| 17 | The zero-order hold: the exact solution over one step, with the input held constant |
| 18 | The zero-order hold keeps stability, and its cost compared with the bilinear discretization |
| 19–20 | Linearization about an operating point: the deviations, the Taylor expansion, the Jacobians, and the constant term |
| 21 | Linearization about a steady state, and the three cases for the eigenvalues |
| 22 | Example: linearizing a gene circuit |
| 23 | Summary: three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch. Slide 6 links the advanced eigenvalue notebook, and slide 16 links the stability derivation of the bilinear discretization.

The deck uses the lecture's notation: the state **x** with n states, the input **u** with d inputs, the state matrix **A**, the input matrix **B**, the modes, the trace τ and det(**A**), the step Δt, the discrete matrices Ā and B̄ of each discretization, the operating point, and the deviations Δ**x** and Δ**u**. The forced-solution derivation is condensed from seven lines to three, the bilinear derivation is shown through its factored step, and the zero-order hold derivation is condensed to three steps. The objectives and takeaways are shortened from the lecture's to fit the slide format; they make the same claims. The two figures are the lecture's figures. Slides 11 and 12 each show one row of the phase portrait figure, cropped in LaTeX so that the panels are large enough to project; the figure file is unchanged.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L14a-Lecture-LinearStateSpaceModels-Fall-2026.ipynb | `1853b50f5b635b7dac454905148f7c2e4abf05015d971c33a2672ae36cf10f20` |
| CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb | `9b1eb50360e1f519eb8aa41871ddf6d0285d3258edd0b7478306ef3ca3cd2d6c` |
