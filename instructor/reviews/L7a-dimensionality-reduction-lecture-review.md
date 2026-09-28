# L7a dimensionality reduction lecture review — September 27, 2026

**Status:** Reviewed and approved by the instructor on September 27, 2026, together
with the L7a example and slide deck. Approval covers the lecture committed in
`d0fac68`. The review is closed.

Target: [Dimensionality Reduction lecture](../../weeks/week-07/L7a/CHEME-5800-L7a-Lecture-SVDAndDataReduction-Fall-2026.ipynb).

Companion records: [Fun with SVD example](L7a-fun-with-svd-review.md) and
[L7a slide deck](L7a-dimensionality-reduction-slides-review.md).

## Source

The lecture was rebuilt on September 27 from the instructor's hand-made Fall 2025
notebook, keeping its cell ids, rather than from the 2026 scaffold, which had
wrapped the same prose in four one-line objectives, a setup cell, a code cell, and
a second Summary. The port added the theme-aware covariance schematic from CHEME
5660 L5b with a short caption, and put the mathematics in the 2025 takeaways into
words, following the instructor's rule against equations in objectives and
takeaways. The instructor judged the resulting lecture tight.

## Changes during the slide review

Building the slide deck surfaced three technical issues in the lecture. The
instructor approved fixing them in both the lecture and the deck:

1. **Two meanings of σᵢ.** The covariance section uses σᵢ for a feature's standard
   deviation and the SVD section for a singular value. The full-SVD bullet now says
   "From here on, σᵢ denotes a singular value."
2. **Thin and compact SVD.** The factorization that keeps only the first r(A)
   singular vectors was called the thin SVD, which usually names the factorization
   with min(m, n) columns. It is now the **compact SVD** (objective 2, the Cons
   bullet, and its definition). A new **Thin SVD** paragraph says the thin SVD keeps
   min(m, n) singular vectors on each side and that Julia's `svd(...)` returns it by
   default, which is the form the example uses.
3. **PCA from the SVD.** The lecture stated that PCA and the SVD of the centered
   data are equivalent without showing why. A new subsection before "Dimensionality
   Reduction?" derives Σ̂ = V(SᵀS/(n−1))Vᵀ from the full SVD of the centered data,
   so the right singular vectors are the covariance eigenvectors and
   λᵢ = σᵢ²/(n−1), taking σᵢ = 0 past the rank.

The objectives and takeaways keep the instructor's 2025 format; this review did not
change them beyond the one term in objective 2.

## Validation

- `instructor/validation/notebook_style_check.py` on the lecture: 0 findings.
- The diff against the pre-edit copy contains only the three fixes; cell ids and
  metadata are unchanged.
- Read-only codex review confirmed the matrix dimensions (X̃ is n × m here, the
  general A is m × n), the eigenvalue formula including the zero case, Julia's thin
  default against the LinearAlgebra documentation, and that the new callout renders
  as one blockquote. Its one finding, the zero-singular-value convention missing
  from the matching slide, was fixed in the deck.

Approved lecture SHA-256: `8bd53da1c00d45492d6121caf6f91ed4018f479eb32eddab5a26339773ee6e10`
