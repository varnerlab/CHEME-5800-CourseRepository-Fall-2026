# L7a Fun with SVD example review — September 27, 2026

**Status:** Reviewed and approved by the instructor on September 27, 2026, at a
final score of 9/10 (the bar for "reviewed" is 9). Approval covers the current
saved notebook. Nothing was committed as part of the review.

Target: [Fun with SVD example](../../weeks/week-07/L7a/CHEME-5800-L7a-Example-FunWithSVD-Fall-2026.ipynb).

Companion records: [L7a lecture](L7a-dimensionality-reduction-lecture-review.md) and
[L7a slide deck](L7a-dimensionality-reduction-slides-review.md).

The notebook was ported the same day from the instructor's hand-made Fall 2025
example, with the scikit-image `camera` photograph (CC0) replacing the unlicensed
`lake_gray` image. Most of the prose is his; the review changed only what is listed
below.

## The error measure

The plot in Task 2 first showed the cumulative fraction of the squared Frobenius
norm, which jumps to 87% at one frame. The instructor found that implausible. The
number is correct but misleading: the image is not centered (mean pixel 0.51), and
a flat gray image at the mean brightness already carries 75.4% of the squared norm.
Dropping the squares was considered and rejected, because it reads 73% at 50 frames
when the rebuilt image is nearly indistinguishable from the original.

| Frames kept | Σσᵢ fraction | Σσᵢ² fraction | Relative error eₖ |
| ---: | ---: | ---: | ---: |
| 1 | 27.6% | 87.0% | 36.0% |
| 10 | 52.1% | 98.2% | 13.5% |
| 20 | 60.3% | 99.0% | 10.1% |
| 100 | 82.9% | 99.8% | 3.9% |

The instructor chose to plot the relative error
eₖ = ‖A − Âₖ‖_F / ‖A‖_F = √(1 − Fₖ), the same measure the L7b lab uses. The
plot is limited to frames 1 to 100 with the error axis starting at zero, and the
cell after it explains the first-frame drop by the mean brightness.

## Initial assessment

Overall: **7.5/10** before corrections.

| Dimension | Initial score | Evidence |
| --- | ---: | --- |
| Technical correctness | 8 | Cell 29 said the rank equals "the number of linearly independent blocks being added", which is false in general; the prose described an `I(...)` call the code does not make; grayscale values were called floating point although the file loads as `Gray{N0f8}`. |
| Organization | 7 | Task 3 asked about "all the frames" but added 20, and its "So what do we see?" was never answered; the Task 2 opening did not say what the task computes. |
| Narrative | 7.5 | No link to the L7a lecture; "sub-images" against "frames" everywhere else; a sales phrase and a preview sentence in the opening. |
| Presentation | 7 | One-sentence slogan takeaways in `**` against `__` objectives, with an unmeasured storage claim; four link labels outside the house form; "Let's setup". |
| Cognitive density | 8 | A duplicated sentence in the orthogonality check; the Data reduction box ran about 90 words with no break around its display. |

## Applied changes

1. Summary: three new takeaways, each a `__label:__` and two "We ..." sentences,
   with no math and only claims the notebook shows (about 10% error at 20 frames).
2. Task 3: heading "Can we rebuild the image from its first few frames?", "reconstruct"
   changed to "approximate" in its Idea box, and a new cell interpreting the 20-frame
   image and tying it to the error plot.
3. Rank Idea box: the rank equals the number of frames added because the left
   singular vectors of the frames are orthogonal to each other, and so are the right.
4. Setup line: "Let's set up our code environment:".
5. Orthogonality check: columns only, `I` defined as the identity matrix, the
   duplicate sentence cut, and the `I` link describes the bare constant the code uses.
6. Link labels in the "[the `foo(...)` function]" form for `convert`, `svd` (twice),
   `diagm`, `rank`, `foreach`, and "[the `@assert` macro]".
7. Task 2: "frames" in the heading, and an "In this task, ..." sentence that says
   what the task computes.
8. A paragraph below the objectives links the L7a lecture and states Eckart–Young
   as "the closest approximation of a given rank, measured by the total squared error".
9. Grayscale box: pixel brightness values, with aᵢⱼ defined as the pixel in row i
   and column j.
10. Opening: "a powerful tool" and the "This example will help you appreciate ..."
    sentence cut.
11. Data reduction box: split around its display in the L6a quoted-display pattern,
    the repeated dimension statement dropped, and `^{T}` changed to `^{\top}`.
12. Kernel metadata restored to `Julia 1.12` / `1.12` after a VS Code save set 1.12.7.

Preserved: the instructor's `number_of_frames = 20` in Task 3 (changed from 100 in
VS Code during the review) and his voice throughout ("Mind blown!", "But let's go
crazy!", "Wow!", "Hmmm. Not quite.").

## Validation

- `instructor/validation/notebook_style_check.py` on the notebook: 0 findings after
  every edit.
- `instructor/validation/week-07/runtests.jl`: L7a 5/5, L7b 35/35, L7d 6/6.
- The notebook was re-executed with `jupyter nbconvert` (kernel `julia-1.12`) for the
  plot changes; only the plot cell's output was copied back, since every other output
  was identical.
- Five read-only codex passes. Accuracy findings it raised, all applied: the first
  explanation overstated what the later frames carry; the Frobenius sentence dropped
  the square root; the Eckart–Young sentence lacked its norm; "reconstruct" under a
  first-few-frames heading. It rebuilt the image directly for several k and matched
  the formula to within 3 × 10⁻¹⁵, and confirmed the Data reduction box renders as
  one blockquote in VS Code's KaTeX renderer.
- Declined as overstated (codex's own grading): "the structural decomposition idea"
  in Task 3 and the "Thus" in the grayscale box.
