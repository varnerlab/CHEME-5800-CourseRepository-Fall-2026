# L7a Fun with SVD example review — September 27 and October 2, 2026

**Status:** Reviewed and approved by the instructor on September 27, 2026, at a
final score of 9/10 (the bar for "reviewed" is 9). Revised on October 2, 2026, in a
polish, voice, and navigation pass and by restoring the 2025 sailboat image at the
instructor's request (see [October 2 revision](#october-2-revision)), scored 9/10,
and approved by the instructor the same day ("fix those three items, then mark it
approved"). Approval covers the notebook with the SHA-256 at the end of this
record. Nothing has been committed.

Target: [Fun with SVD example](../../weeks/week-07/L7a/CHEME-5800-L7a-Example-FunWithSVD-Fall-2026.ipynb).

Companion records: [L7a lecture](L7a-dimensionality-reduction-lecture-review.md) and
[L7a slide deck](L7a-dimensionality-reduction-slides-review.md).

The notebook was ported the same day from the instructor's hand-made Fall 2025
example, with the scikit-image `camera` photograph (CC0) replacing the unlicensed
`lake_gray` image. That swap was the assistant's port decision, recorded here but
never offered to the instructor as a choice; it was reversed on October 2. Most of
the prose is his; the September 27 review changed only what is listed below. The
error-measure numbers in the next section are for the cameraman image.

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

## October 2 revision

The instructor asked for a "polish/voice/navigation pass ... if score is below 9",
then asked "why didn't we use the Sailboat example from 2025???" and chose to
restore it through TestImages.jl ("Let's do 1 => I want the sailboat back").

### Polish, voice, and navigation

Initial score: **8/10**. The September 27 takeaways and code held up; the rest had
fallen behind the house example form and the lecture polished the same morning.

| Dimension | Before | After | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 8.5 | 9.5 | "Convert the image into grayscale values" was wrong (it loads as grayscale); the matrix of singular values was Σ against the lecture's S. |
| Organization | 7.5 | 9 | The prose said "first, we compute the rank", but the rank cell followed the frames cell; Task 1's checks had no heading; one `___` opened a cell instead of closing the previous one. |
| Narrative and voice | 8 | 9 | Objectives were verb fragments ("__Decompose__ ... and understand ... You'll learn ..."); "students will explore"; "the structural decomposition idea"; stock Summary opener and closer. |
| Presentation | 8 | 8.5 | The setup claimed "we'll also use" a package the notebook never calls; "matrix blocks" where the lecture now says rank-one components. |
| Cognitive density | 8.5 | 9 | The Frobenius norm was defined twice in consecutive sentences. |

Applied changes:

1. Title cell: an opening question and a one-sentence definition; three objectives
   in the house form (label, "what it is" sentence, "We'll ..." sentence); the
   lecture link as the "In this example, ..." overview below the objectives.
2. Setup: the standard L6a example opening with an `__Include:__` box; the package
   sentence now says the setup loads the course package and points to its
   documentation.
3. Task 1: heading parallel with Tasks 2 and 3; an "In this task, ..." sentence
   that says what it computes; a `### Check: Orthogonal factors and reconstruction`
   heading over the two `@assert` checks; `ΣM` named as the lecture's S, and
   U S Vᵀ in the reconstruction sentence and the Data reduction box.
4. Task 2: the rank cell moved ahead of the frames cell, with lead-ins for each;
   one Frobenius-norm sentence; a code lead-in before the error plot.
5. Task 3: the frames sum tied to the Data reduction box; stage and trailing
   comments in the reconstruction cell (code unchanged); the rank subsection
   retitled "What is the rank of the rebuilt image?" with "frames" for "blocks".
6. Summary: an opener with parallel verbs and a closer that points to
   `number_of_frames` and the L7b lab. The approved takeaways kept their form.
7. Kernel metadata back to `Julia 1.12` / `1.12` after a VS Code save
   (commit 9c99b72) set 1.12.7.

Preserved: "Hmmm. Not quite.", "But let's go crazy!", "Mind blown!", "Wow!",
"Strange syntax alert!", and `number_of_frames = 20`.

A read-only codex pass rated 12 of 14 changes fixed and two overcorrected, both
applied: objective 1 called the singular-value matrix orthogonal, and a new
sentence equated the code's `Σ` vector with the lecture's matrix S (cut, which
also keeps the "Hmmm. Not quite." reveal intact). Its older finding, that
`svd(...)` returns a factorization rather than a vector, was fixed as well.

### Sailboat restored

The image is `testimage("lake_gray")`, as in 2025.

- TestImages.jl was added to the root `Project.toml` and `Manifest.toml` with
  `Pkg.PRESERVE_ALL`; the only new entries are TestImages 1.9.0 and
  StringDistances 0.11.3, and no other package version changed.
- `L7a/Include.jl` loads TestImages and no longer defines `CHEME5800_L7A_DATA`;
  `L7a/data/` (`camera.png` and its README) was deleted; `release.toml` drops
  those datasets and sets `network_required = true`; the week README says the
  first run needs an internet connection.
- The Data cell restores the instructor's 2025 TestImages sentence and links
  `testimage(...)`. The image loads as `Matrix{GrayA{N0f8}}`, so the convert
  sentence names the alpha channel, which `Gray.(img)` drops.

| Frames kept | Relative error eₖ |
| ---: | ---: |
| 1 | 31.3% |
| 10 | 16.8% |
| 20 | 12.8% |
| 50 | 7.6% |
| 100 | 4.3% |

The image has rank 512, and the 20-frame sum has rank 20. The mean pixel is
0.488; a flat image at that brightness holds 78.3% of the squared norm and frame 1
holds 90.2%, so "the first frame mostly holds the image's average brightness"
still holds. At 20 frames the trees and shoreline are clear while the sailboat is
a faint smudge; by about 50 frames it is easy to make out. The interpretation
cell and the second takeaway now say this.

### Validation

- Re-executed with `jupyter nbconvert` (kernel `julia-1.12`) on a scratch copy;
  every code cell's outputs were copied back by cell id. No errors or stderr.
- `instructor/validation/notebook_style_check.py`: 0 findings.
- `instructor/validation/week-07/runtests.jl`: L7a 5/5, L7b 35/35, L7d 6/6;
  `test_week_bundles.py`: 10 passed.
- A read-only codex pass on the swap recomputed every percentage, both ranks,
  and the brightness fractions, checked the descriptions against rendered
  previews, and found no stale cameraman or offline text in the repository. It
  could not confirm from the diff alone that `PRESERVE_ALL` was used.

### Final fixes before approval

The 9/10 assessment listed three small items, and the instructor asked for all three:

1. Task 3 is now "Approximate the image from its first few frames", and its
   opening sentence says the first few frames approximate the image; it had said
   "Reconstruct" although the task adds 20 frames.
2. The error-plot cell names the frame count `total_frames` instead of
   `number_of_modes` (a local inside its `let` block, distinct from the Task 3
   global `number_of_frames`).
3. The setup cell offers the theme choice from the
   [figure-theme convention](../FIGURE-THEMES.md), in the L6a example's form:
   `theme(:default)` with `# theme(:dark)` commented. The error plot was drawn in
   both themes and reads clearly in each.

The notebook was re-executed (no errors or stderr; the setup cell prints
nothing), the style check reported 0 findings, and the week 7 suite passed
(L7a 5/5, L7b 35/35, L7d 6/6). Not changed: the plot's `fontsize=18` keywords on
`xlabel!` and `ylabel!`, which Plots ignores, so the axis labels use the default
size.

Approved notebook SHA-256 (October 2, 2026): `fe6f224dc346b7d4f1e53f5ae9888ae54d230472414209e13b53e51cfef4e737`
