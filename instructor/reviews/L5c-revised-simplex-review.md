# L5c revised-simplex algorithm review

**Status:** Reviewed and approved by the instructor on September 17, 2026. Final approval covers the current saved notebook, including the derivation, compact four-step pseudocode, worked numerical pivot, bulleted performance discussion, opening and setup, and Summary with three key takeaways. The polish round is closed.

**Notebook:** [L5c Supporting Algorithm: Revised Simplex](../../weeks/week-05/L5c/CHEME-5800-L5c-Algorithm-RevisedSimplex-Fall-2026.ipynb)

**Final editorial score:** 9.0/10, compared with 6.0/10 before the polish round. These scores are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness | 4.5 | 9.5 |
| Organization | 7.0 | 9.0 |
| Narrative flow | 6.0 | 9.0 |
| Presentation | 6.5 | 9.0 |
| Cognitive density and pacing | 5.5 | 8.5 |

The notebook now defines the augmented constraint matrix and slack objective coefficients, distinguishes basis selection from feasibility and degeneracy, derives the reduced-cost optimality certificate and ratio test, and updates the solution using saved basis indices before exchanging columns. Optimal, unbounded, and iteration-limit outcomes are distinct. The discussion explains cycling and Bland's rule while retaining Dantzig's entering rule in the pseudocode.

The pseudocode follows the instructor's preferred compact 2025 format. The numerical example traces its four steps and checks the new reduced costs after the pivot. The performance discussion separates pivot count from work per pivot and explains basis factorizations and sparsity. Three learning objectives align with three retrospective takeaways.

Validation completed during the polish round and final review:

- Notebook validity, preservation of every approved section, local links, objective and takeaway counts, and section separators passed.
- The complete notebook was rendered and visually inspected, including all 20 display-math blocks and the inline-math pseudocode.
- The worked pivot was independently checked with NumPy, and its linear program was solved with SciPy/HiGHS. The degeneracy counterexample was also independently verified.
- Code, outputs, execution counts, cell metadata, and notebook metadata match the initial snapshot. The Julia setup cell was not rerun; the notebook contains no executable simplex implementation.
- External references were checked during the section reviews, and `git diff --check` passed for the notebook.

No required corrections remain from this round. The derivation and compact pseudocode remain substantial supporting reading; classroom pacing is untested. This review closes the notebook polish round without changing the Week 5 release status.

Reviewed notebook SHA-256: `c005d450affec5a12607ff0a377d868f00bbff144c5f665d95e8070935384255`
