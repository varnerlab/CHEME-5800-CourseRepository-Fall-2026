# L5b maximum-flow sensitivity lab review

**Status:** Reviewed and approved by the instructor on September 16, 2026. Final approval covers the current saved notebook, including all three tasks and the Summary. The polish round is closed.

**Notebook:** [L5b Lab: Maximum-Flow Sensitivity and Bottlenecks](../../weeks/week-05/L5b/CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb)

**Final editorial score:** 9.0/10, compared with 6.5/10 before the polish round. These scores are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final | Basis for the final assessment |
|---|---:|---:|---|
| Technical correctness | 8.0 | 9.5 | Feasibility, agreement with the solver's reported value, and cut-based optimality are distinguished and checked for all three scenarios. |
| Organization | 7.0 | 9.0 | Three tasks progress from the baseline to capacity expansion and then outage, with both interventions compared against separate copies of the same baseline. |
| Narrative and reasoning | 5.0 | 9.0 | Node roles, assignment routes, predictions, conservation, and the meaning of each numerical result are explained. |
| Presentation | 6.0 | 9.0 | Restrained tables, rendered cut equations, clear section boundaries, and three developed retrospective takeaways support the teaching sequence. |
| Cognitive density and pacing | 6.0 | 8.5 | Prediction checkpoints and separate calculation, verification, and comparison steps provide stopping points; the outage-cut argument still requires deliberate classroom pacing. |

The lab now explains why three assignments is the baseline maximum, why expanding worker 3's capacity permits four assignments, and why blocking that worker's outgoing edges reduces the maximum to two. The outage uses the cut with source-side nodes `{1, 3}`: its capacity is two even though the cut containing only the source still has capacity three. The final comparison table reports each intervention's change relative to the baseline.

The supplied computation and student prediction work remain intact. Local helper documentation states arguments, units, returned fields, and the distinction between checking feasibility and certifying optimality.

Validation completed during the round and final review:

- All 11 code cells in the Task 3 draft executed successfully with Julia 1.12, including all 11 notebook assertions. The final saved code-cell sources and execution counts match that execution; the subsequent Summary revision changed only Markdown.
- Independent enumeration of all 2,048 source–sink cuts for each scenario confirmed minimum capacities of 3, 4, and 2, matching the computed flows and the cuts used in the notebook.
- The earlier course validation run recorded 36 passing Week 5 checks, including seven L5b checks. That suite was not rerun for the final Markdown-only Summary change.
- Notebook validity, 11 local link references across seven targets, three objectives, three tasks, three takeaways, task introductions, and section separators were checked.
- The entire saved narrative was rendered to HTML and inspected in five PNG sections. Equations, code, tables, output interpretation, and Summary formatting were readable without clipping.

No required corrections remain from this round. Classroom feedback should determine whether students need more time on the change of cut in Task 3. This review closes L5b polishing; it does not change the Week 5 release status.

Reviewed notebook SHA-256: `def6afcfe0cdb751b3d99ef35097bca17dddf4fd50db2b564c913a0bce7b6812`

Reviewed flow-validation helper SHA-256: `92070afe137290e69f186339a513aea7969e51c9f138686930feae6bc4fdd332`
