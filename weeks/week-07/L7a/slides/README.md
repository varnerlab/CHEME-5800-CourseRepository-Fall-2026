# L7a lecture slides

[PDF deck](CHEME-5800-L7a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L7a-Slides-Fall-2026.tex)

The 23-slide deck follows the [Dimensionality Reduction lecture](../CHEME-5800-L7a-Lecture-SVDAndDataReduction-Fall-2026.ipynb) in its order: the dimensionality-reduction problem, the empirical covariance matrix and its eigendecomposition, the move from eigendecomposition to the singular value decomposition, full and compact SVD, PCA from the SVD, the sum of rank-one blocks, and the Eckart–Young theorem. Three learning objectives align with three closing takeaways.

**Review status:** Reviewed and approved by the instructor on September 27, 2026, with the L7a lecture and example. See the [review record](../../../../instructor/reviews/L7a-dimensionality-reduction-slides-review.md).

The style files and Cornell seal are copied unchanged from L6c, which matches the approved L6a deck. The deck keeps their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L7a/` directory.

`make figures` refreshes the covariance figure in `assets/` from the lecture's [figure folder](../figs/). The figure is built in the CHEME 5660 repository; see the [figure README](../figs/README.md) before changing it. The deck uses the light PDF.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–7 | Dimensionality reduction problem, applications, composite features, and the linear transformation with its PCA and SVD routes |
| 8 | Covariance schematic with a two-sentence caption |
| 9–12 | Empirical covariance matrix, standard deviation and correlation, the data-matrix form, and matrix properties |
| 13–14 | Covariance eigendecomposition and principal components |
| 15 | From eigendecomposition to SVD |
| 16–20 | Full SVD, full and compact SVD (with the thin SVD Julia returns), PCA from the SVD, the sum of rank-one blocks, and the Eckart–Young theorem |
| 21–22 | Fun with SVD example and the L7b platelet lab |
| 23 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck follows the lecture's notation: $\hat{\boldsymbol\Sigma}$ for the covariance matrix, $\mathbf S$ for the matrix of singular values, and $\mathbf V$ for both the covariance eigenvectors and the right singular vectors. Three wording changes tighten the lecture's statements: Eckart–Young is stated for $k<r(\mathbf A)$, the full SVD's bases are described as bases for $\mathbb R^m$ and $\mathbb R^n$, and truncation is described as provably optimal. The lecture uses $\sigma_i$ for a feature's standard deviation and later for a singular value; the lecture and the SVD slide both say where the second meaning begins. The rank-$r$ factorization is the compact SVD, and the thin SVD keeps $\min(m,n)$ singular vectors, as Julia's `svd(...)` returns by default. The PCA-from-SVD slide shows the one-line reason the right singular vectors of the centered data are the covariance eigenvectors. The example slide summarizes the example's three tasks and its explanation of the first frame.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L7a-Lecture-SVDAndDataReduction-Fall-2026.ipynb | `8bd53da1c00d45492d6121caf6f91ed4018f479eb32eddab5a26339773ee6e10` |
| CHEME-5800-L7a-Example-FunWithSVD-Fall-2026.ipynb | `d95591b276cd6fdbf3865c2dac1e4ca90ac5f4176b4c6265e569dddf0bbe8bc3` |
| CHEME-5800-L7b-Lab-SVD-StoichiometricMatrix-Fall-2026.ipynb | `6a34e4311e3f5c0eb9785754a062c2cb845e829e6b33543540d395ac6941cb39` |
