# L6c iterative-methods slide-deck review

**Status:** Created and checked September 25, 2026; ready for instructor review. Instructor approval has not yet been recorded.

**Deck:** [L6c: Iterative Methods for Solving Linear Algebraic Equations](../../weeks/week-06/L6c/slides/CHEME-5800-L6c-Slides-Fall-2026.pdf)

**Editable source:** [LaTeX source](../../weeks/week-06/L6c/slides/CHEME-5800-L6c-Slides-Fall-2026.tex)

The 24-slide deck follows the cleaned lecture and its companion notebooks. The existing slide directory was empty. The new deck uses the exact style files and Cornell seal from L6a, also matching the supplied L5c and L5a decks. Three learning objectives align with three final takeaways.

Validation completed:

- Built with XeLaTeX and latexmk, with no overfull or underfull boxes or missing glyphs. The inherited unicode-math/mathtools compatibility warnings do not affect the rendered equations.
- Rendered and visually inspected all 24 slides; checked the algorithm, iteration-count bound, and SOR equations individually at full size. Rechecked the proof slide and Gauss–Seidel typography after the final edits.
- Checked correction signs and component dependencies under the common A = D + L + U convention, convergence assumptions, residual-first stopping logic, and the rounded sufficient iteration count.
- Confirmed all seven linked notebook targets exist locally. GitHub links use the corresponding main-branch paths; publication of the local changes remains outside this review.
- Confirmed the reference style files and seal assets are byte-for-byte identical, all 23 content slides carry source notes, and all extracted PDF text stays within the 16:9 page bounds.

The deck carries the corrected shared-solver stopping semantics and distinguishes residual tolerance from a solution-error bound. It avoids unconditional speed rankings and limits SOR's full convergence interval to symmetric positive definite matrices. The nonmonotone example illustrates why spectral radius below one does not imply a decreasing error norm at every step.

Build instructions, coverage, and source notebook hashes are in the [slide README](../../weeks/week-06/L6c/slides/README.md). Classroom pacing has not been tested. This work does not change the Week 6 release status.

Checked PDF SHA-256: `de6b6b7d6998d37055676c80ccec7e5f723a699736013c8b5737eabccacf6bcb`

Checked LaTeX source SHA-256: `d343b2cf2000a61add8f572da09a78b26efd65f554cb300caa8725cb820c5101`

## Terminology follow-up — September 25, 2026

The instructor requested a closer audit of definitions and ambiguous language. The deck previously defined the residual but introduced the correction primarily through equations. The revision explicitly defines a correction as the vector added to the current approximation and states that an update need not reduce either the residual norm or the solution-error norm.

Further changes define an iterate and the update counter, distinguish mathematical convergence from the solver's stopping flag, relate residual and error by r = −Ae, replace ambiguous error-growth language with error-norm growth, define a sweep, and clarify that the iteration-count bound is sufficient rather than minimal. The example now names the matrix checks and measured norms explicitly. The objectives refer to approximations approaching the solution, rather than corrections approaching it.

The deck remains 24 slides. Rebuilt and inspected the revised slides with the original typography. No overflow, missing glyphs, or text outside page bounds remains. The three objectives and three takeaways remain intact. This follow-up has not yet received instructor approval.

## Sentence-flow follow-up — September 25, 2026

The instructor corrected “Each component measures” to “Each component of the residual measures” and requested a full read for natural flow. Read all slide prose in sequence and revised missing subjects, unclear references, and compressed phrasing throughout. Examples include naming G and c instead of “Both,” stating the Jacobi conclusion explicitly, identifying the update rather than “One,” and explaining that iterates starting from other guesses approach the fixed point. The prose around the component formulas now names the components and iterates being used. The equations and slide design are unchanged.

Rebuilt and visually inspected all 24 slides. The build has no overflow or missing-glyph warnings, all text stays within page bounds, and the three objectives and takeaways remain intact. Instructor review remains open.
