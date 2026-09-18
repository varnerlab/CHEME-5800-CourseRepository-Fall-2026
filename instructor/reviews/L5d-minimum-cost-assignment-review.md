# L5d minimum-cost assignment lab review

**Status:** Reviewed and approved by the instructor on September 18, 2026. Approval covers the saved notebook, including the final Task 2 readability improvements and the Summary lead-in and three general takeaways. The closing sentence remains reserved for the instructor's own edit. The polish round is closed. This review does not change the Week 5 release status.

**Notebook:** [L5d Lab: Minimum-Cost Assignment as a Flow Linear Program](../../weeks/week-05/L5d/CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb)

**Final editorial score:** 9.0/10, compared with 6.0/10 before the round. These are editorial judgments, not measured learning outcomes. The final Task 2 reading note and purpose comments address the remaining unexplained Julia idioms, raising the pacing assessment from 8.5 to 9.0 and the overall assessment from 8.9 to 9.0.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness | 7.5 | 9.5 |
| Organization | 7.0 | 9.0 |
| Narrative and explanation | 4.5 | 8.5 |
| Presentation | 5.5 | 9.0 |
| Cognitive density and pacing | 5.5 | 9.0 |

The lab now explains the node roles and edge records before constructing the model. Worked node balances lead into the incidence formulation, and the required flow is connected to the network's capacity. The solution discussion separates feasibility, integrality, cost accounting, and the lower-bound argument for optimality. Three objectives, three tasks, and three general takeaways agree with the material developed.

Computed assignment and cost tables support changes to the inputs. Task 3 uses explicit loops and separate calculation, display, and validation cells with purpose comments. Its explanation shows why blocking one assignment can change several workers' tasks and correctly conditions the original solution's feasibility on whether it used the blocked edge. The plot labels clear the edges, the node groups are identified, and the plotting routine is in local source.

The solution validator now recomputes balances from the edge list and candidate flows instead of trusting a cached residual. It also checks the recomputed cost against the solver-reported objective.

Validation completed during the round and final review:

- All 17 final code cells executed successfully during Task 3 review. Final checks confirm that their executable lines, outputs, execution counts, and metadata match that executed draft. The final Task 2 readability edit added comments and a short syntax explanation only. Later edits changed only Markdown and comments; no redundant execution was needed for the Summary.
- Thirty Task 3 assertions passed for each of three scenarios: the default blocked edge, an unused blocked edge, and a smaller required flow. Twenty additional comparison, enumeration, and exploration checks passed.
- Thirty-two validator regressions and all 36 existing Week 5 checks passed earlier in the round. Final source checks confirm that the saved validator matches the tested version.
- Independent enumeration and continuous optimization agreed on the supplied original and revised solutions. Figure checks covered original, disrupted, decimal-cost, and zero-flow cases; the saved plotting and setup sources match the tested versions.
- Notebook validity, all 15 local notebook references, three objectives/tasks/takeaways, and separator placement passed. No saved error outputs are present, and the final whitespace check passed.
- Rendered section previews were inspected throughout the review, including the equations, tables, and corrected network figure. The saved Summary was rendered after removing the rejected closing. Accepted material outside the Summary was preserved during this final save.

The closing remains the instructor's edit. Task 2 now explains its comprehensions and generators with a concrete example and official Julia references; purpose comments separate model solution, table construction, cost calculation, and display. The rendered additions were inspected, and all executable lines and outputs were preserved. Two private plotting helpers have explanatory comments but lack full docstrings. These observations were recorded without starting another rewrite. Classroom feedback is still needed to assess pacing.

Reviewed notebook SHA-256: `d918eaf73126304e353895d1de617b9fdac7ebdb4c5a6a30f6a416e606b685c9`
