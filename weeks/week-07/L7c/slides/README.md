# L7c lecture slides

[PDF deck](CHEME-5800-L7c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L7c-Slides-Fall-2026.tex)

The 18-slide deck follows the [Ordinary Least Squares lecture](../CHEME-5800-L7c-Lecture-OrdinaryLeastSquares-Fall-2026.ipynb) in its order: the regression schematic, the linear model, the overdetermined case with the normal equations and unbiasedness, the underdetermined case with the least-norm solution, the SVD solution and its comparison with direct methods, and the error model, error variance, standard errors, and confidence intervals. Three learning objectives align with three closing takeaways.

**Review status:** Built October 5, 2026; included in the week-07.2 release. A read-only codex review found one error inherited from the lecture (regularization damps the *contributions* of small singular values, not the singular values) and minor definition and layout gaps; all were fixed in the deck. The build has no overfull or underfull boxes.

The style files and Cornell seal are copied unchanged from L7a (identical to L6c, which matches the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L7c/` directory.

`make figures` refreshes the regression schematic in `assets/` from the lecture's [figure folder](../figs/Fig-LinearRegressionModel-Schematic/), where the TikZ source and its Makefile live. The deck uses the light PDF.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and L7d lab links |
| 4–5 | Regression schematic with a two-sentence caption; the linear model in index and matrix form |
| 6–7 | Overdetermined case: normal equations, column-space projection, solution, and unbiasedness |
| 8–9 | Underdetermined case: least-norm solution, row-space projection and bias, and the null-space reason for the smallest solution |
| 10–12 | SVD solution, reading it as a weighted sum, and SVD versus direct methods (conditioning, cost, Julia's backslash) |
| 13–17 | Error model and scope, error variance, parameter variance and standard errors, their uses, and confidence intervals |
| 18 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: the augmented data matrix $\hat{\mathbf X}$, augmented features $\hat{\mathbf x}_i$, parameters $\theta$ and estimate $\hat\theta$, residuals $r_i$, and $\mathbf S$ for the matrix of singular values, as in L7a. The Greek vectors $\theta$ and $\epsilon$ are set plain, as the notebook renders them and as the figure labels them. The deck has no example slide because L7c has no example notebook; the lab appears on the third slide and in the Summary.

Source notebook snapshot (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L7c-Lecture-OrdinaryLeastSquares-Fall-2026.ipynb | `09e50ee4559166ac18bbea2ac7f42b28742b624a958ce612f73cb7d9eaac5000` |
