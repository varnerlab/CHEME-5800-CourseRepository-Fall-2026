# L6c lecture slides

[PDF deck](CHEME-5800-L6c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L6c-Slides-Fall-2026.tex)

The 24-slide deck follows the reviewed [Iterative Methods lecture](../CHEME-5800-L6c-Lecture-GeneralIterativeMethod-Fall-2026.ipynb) and its algorithm, convergence, and computational companions. It covers residual corrections, stationary iterations, convergence criteria, error bounds, and Jacobi, Gauss–Seidel, and successive over-relaxation. Three learning objectives align with three closing takeaways.

**Review status:** Created and checked September 25, 2026; ready for instructor review. See the [review record](../../../../instructor/reviews/L6c-iterative-methods-slides-review.md).

The style files and Cornell seal are copied unchanged from L6a and match the supplied L5c and L5a references. The deck retains their 16:9 format, typography, palette, title page, and footer. Text, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L6c/` directory.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source and Cornell seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, lecture and example links |
| 4–6 | Linear system, residual, matrix splitting, and general algorithm |
| 7–9 | Stationary form, residual-correction derivation, and error propagation |
| 10–13 | Spectral-radius criterion, temporary error growth, strict diagonal dominance, and the Jacobi proof |
| 14–15 | Contracting-norm bound, sufficient iteration count, and boundary cases |
| 16–20 | Common splitting convention; Jacobi, Gauss–Seidel, and SOR updates; relaxation assumptions |
| 21–23 | Work per iteration, Fun with Iterative Methods example, and L6d lab |
| 24 | Summary with three key takeaways |

## Sources and scope

Notebook-section mappings and supporting references appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations. The temporary-growth example comes from the advanced convergence companion; component updates come from the algorithm companions. The SOR reading is the lecture's Netlib reference.

The deck defines the iterate, residual, correction, and solution error explicitly. It distinguishes mathematical convergence from satisfying the residual stopping test. The algorithm checks the residual before the update limit and returns immediately. The iteration-count bound concerns solution error and is distinguished from the residual stopping tolerance. SOR's full convergence interval is stated for symmetric positive definite matrices. The benchmark discussion acknowledges explicit inverses and stored iterates in the course implementation; the slides make no universal performance ranking.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L6c-Lecture-GeneralIterativeMethod-Fall-2026.ipynb | `a06bacdd0a5388d679ac6793bfd6e35f1aae9fad8674b0e810f6ed2f65ba4b74` |
| CHEME-5800-L6c-Example-FunWithIterativeSolvers-Fall-2026.ipynb | `48f99c5f264e32fb15d16170057a0d3430accb3858684857aab92bf1f6ccb4ba` |
| CHEME-5800-L6c-Algorithm-JacobiMethod-Fall-2026.ipynb | `56cfe43454de56d499ec7f1c838faf8d4417096b79206c353c008c5a083f6333` |
| CHEME-5800-L6c-Algorithm-GaussSeidel-Fall-2026.ipynb | `749343a2c0eaabed7ac63f492cc35c401ed0a7a583c32fe2b8d6a8597492e7c7` |
| CHEME-5800-L6c-Algorithm-SOR-Fall-2026.ipynb | `18a3b30f804fa8094f1b80a3a39ceab210c04948654996b6f168085eb3bfbdb3` |
| CHEME-5800-L6c-Advanced-Convergence-IterativeMethods-Fall-2026.ipynb | `6613880b8e6be5a24cb237344a2353a44dee0f1a5d99c6f86835745417240b55` |
| CHEME-5800-L6d-Lab-IterativeLinearSolvers-Fall-2026.ipynb | `bb1cd8ce274f4c47643d05bf5cda88672ecc2649e715a07ee0dbec0152b9b49c` |
