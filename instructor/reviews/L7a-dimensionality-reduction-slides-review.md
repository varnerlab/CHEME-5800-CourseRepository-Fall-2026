# L7a dimensionality reduction slide-deck review

**Status:** Reviewed and approved by the instructor on September 27, 2026, and the
re-synced deck approved again on October 2, 2026 ("Slides look great. let's use
these"). Approval covers the 23-slide deck with the hashes below. The review is closed.

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

## October 2 sync with the polished lecture

The lecture had a polish pass on October 2 (new objectives and takeaways, accuracy
fixes, and reorganized cells), and twelve slides were updated to match. Slide 2 takes
the three new objective labels; slide 23 takes the new takeaway labels, still one
line each. Slides 5, 6, 7, 11, 12, 15, 16, 17, 19, and 20 carry the lecture's fixes:
about a million pixel dimensions and the cited Netflix claim, mean-subtracted
composite features, the $y_j$ and $\boldsymbol\phi_j$ notation, the dropped
correlation denial, the variance reason for positive semidefiniteness, "principal
directions", named singular-vector columns, the column and row spaces of the full
SVD, "rank-one matrices", and $\mathbf B\in\mathbb R^{m\times n}$. To keep the
first three edits from overflowing, slides 2, 5, and 16 were reworded and slides 5
and 16 got tighter spacing; no font sizes changed. The build has no overfull or
underfull boxes. A read-only codex pass rated all 13 edits fixed and found no
contradiction with the lecture or departure from its order; it noted the undefined
vector norm (slide 12) and big-O (slide 17, pre-existing), left as standard notation.

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

Approved PDF SHA-256: `12afc112c6a31344123804eea3c04402646cbff8583c612d2fe44142c471d29c`

Approved LaTeX source SHA-256: `6aec3fbb7edc1189d77849f1d26ab757b8a51aba47b8e76cd0ddc208b0e4d436`
