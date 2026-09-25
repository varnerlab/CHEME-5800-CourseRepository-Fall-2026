# L6b overflow-metabolism lab review

**Status:** Reviewed and approved by the instructor on September 24, 2026. Approval covers the saved notebook, including the opening, all three tasks, result interpretations, units, implementation references, and Summary. The polish round is closed.

**Notebook:** [L6b Lab: Overflow Metabolism in E. coli](../../weeks/week-06/L6b/CHEME-5800-L6b-Lab-OverflowMetabolism-Fall-2026.ipynb)

**Final editorial score:** 9.1/10, compared with 8.6/10 before the polish round. These scores are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness and code agreement | 8.0 | 9.2 |
| Organization | 9.2 | 9.2 |
| Narrative and interpretation | 8.4 | 9.1 |
| Rendered presentation | 8.8 | 9.2 |
| Cognitive density and pacing | 8.8 | 8.8 |

Approved revisions:

- Distinguished secretion under an imposed oxygen-uptake limit from the biological causes of aerobic overflow, with the opening, third objective, Task 3 interpretation, and third takeaway aligned.
- Explained acetate-associated ATP production and cited the protein-allocation interpretation of aerobic overflow.
- Corrected the description of glucose carbon entering biomass or leaving as carbon dioxide; defined gDW and clarified flux units.
- Attributed the solver to the course library while retaining the connection to the linear-programming formulation from L6a.
- Added the required closing Summary separator.

Validation completed during the polish round:

- The three main scenarios were solved using the existing Julia implementation. Growth rates were 0.8739215069691043, 0.7178372245942451, and 0.21166294973552482 h⁻¹ for oxygen-uptake limits of 1000, 15, and 0 mmol gDW⁻¹ h⁻¹. All balance and bound checks passed; the largest balance residual was 2.0730084315800968e-11.
- Notebook validity, local file links, three objectives and takeaways, task introductions, major-section separators, and the final separator passed.
- The complete narrative was read, and the rendered notebook was inspected in Chrome with its existing figures and outputs.
- Code cells, outputs, execution counts, and cell metadata were preserved. The existing Julia-version metadata update to 1.12.7 was retained. Computational behavior did not change, so the prose revisions required no repeat execution.
- The notebook passed `git diff --check`.

No required corrections remain from this round. The absence of a protein-allocation constraint is now an explicit model limitation. Discussion tasks and pacing remain unchanged. Figures and plotting code were not edited; dark appearance was not rechecked during this pass.

Reviewed notebook SHA-256: `1fe9ba9e106b59b8084c9deeb02cb02e86c7e15297f2efeb33892877a35ce909`
