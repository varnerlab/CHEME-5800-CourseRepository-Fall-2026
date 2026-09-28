# L7a dimensionality reduction slide-deck review

**Status:** Reviewed and approved by the instructor on September 27, 2026. Approval
covers the 23-slide deck committed in `d0fac68`. The review is closed.

**Deck:** [L7a: Dimensionality Reduction](../../weeks/week-07/L7a/slides/CHEME-5800-L7a-Slides-Fall-2026.pdf)

**Editable source:** [LaTeX source](../../weeks/week-07/L7a/slides/CHEME-5800-L7a-Slides-Fall-2026.tex)

The deck is a note-taking companion to the [lecture](../../weeks/week-07/L7a/CHEME-5800-L7a-Lecture-SVDAndDataReduction-Fall-2026.ipynb)
and follows its order: the dimensionality-reduction problem, applications, composite
features, and the linear transformation; the covariance schematic; the empirical
covariance matrix, its data-matrix form, properties, and eigendecomposition;
principal components; the move to the SVD; full and compact SVD; PCA from the SVD;
the sum of rank-one blocks; the Eckart–Young theorem; the example, the L7b lab, and
the Summary. Three learning objectives align with three takeaways. The style files
and Cornell seal are copied unchanged from L6c, which matches the approved L6a deck.

## Review history

- **Codex review of the first draft.** It found one false transition ("Both routes
  start from the covariance matrix", although the SVD route starts from the centered
  data), undefined I, Iₘ, Iₙ, r, and 𝒪, two places where the order departed from
  the lecture (applications before composite features; the outer product before the
  covariance formula), and several compressed sentences. All were fixed. Its
  rewording of the lecture-and-example slide was declined in favor of the approved
  L6a form, "In this lecture, we …" and "In this example, we …".
- **Instructor density comments.** "Sign and Scale of Covariance => Bottom text, too
  dense" and "Summary => Dense". The caption became two sentences under a larger
  figure, and each takeaway became a bold label and one line, as in the L6a Summary.
- **Lecture fixes carried into the deck.** The σᵢ sentence (slide 16), "Full and
  Compact SVD" with the thin-SVD note (slide 17), and the new "PCA from the SVD"
  slide (18). A second codex pass confirmed them; its one finding, the σᵢ = 0
  convention past the rank on slide 18, was fixed.

Three wording changes tighten the lecture's statements and were confirmed correct by
codex: Eckart–Young is stated for k < r(A), the full SVD's bases are bases for ℝᵐ and
ℝⁿ, and truncation is described as provably optimal.

## Validation

- Built with XeLaTeX and latexmk; the final build has no overfull or underfull boxes
  and no missing characters.
- Rendered and inspected all 23 slides, and rechecked slides 2, 8, 16–18, and 23
  after the last edits. No text collides with the footer.
- Style files and seal are byte-identical to L6c; the covariance figure is
  byte-identical to `../figs/Fig-Covariance-Schematic.pdf`.
- Build instructions, coverage, and source notebook hashes are in the
  [slide README](../../weeks/week-07/L7a/slides/README.md). Classroom pacing has not
  been tested. This approval does not change the week 7 release status.

Approved PDF SHA-256: `73c51d54bd7229ec52a0fc48ce0d6cc338d538999a6205911f0bb221aa54b2db`

Approved LaTeX source SHA-256: `b7db506848ca5e5c2bc8363ffe56d360d29764f3463bdbe352deacd71b917d56`
