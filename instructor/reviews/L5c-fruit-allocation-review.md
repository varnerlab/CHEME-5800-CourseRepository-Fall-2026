# L5c fruit-allocation example review

**Status:** Reviewed and approved by the instructor on September 17, 2026. Final approval covers the current saved notebook, all three tasks, the Summary including its revised closing sentence, and the figure with trimmed margins. The polish round is closed.

**Notebook:** [L5c Example: Apples, Oranges, and Linear Allocation](../../weeks/week-05/L5c/CHEME-5800-L5c-Example-FruitAllocation-Fall-2026.ipynb)

**Final editorial score:** 9.0/10, compared with 6.5/10 before the polish round. These scores are editorial judgments, not measured learning outcomes. This final assessment supersedes the earlier recorded score and includes the accepted closing-sentence revision.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness | 8.0 | 9.5 |
| Organization | 6.5 | 9.0 |
| Narrative and explanation | 5.5 | 9.0 |
| Presentation | 5.5 | 9.0 |
| Cognitive density and pacing | 6.5 | 8.5 |

The example now develops the allocation model and utility-per-dollar predictions, compares solver results in complete computed tables, and independently verifies feasibility and optimality. Predictions and checks use the current prices, budget, and utility coefficients. The geometric explanation defines the figure's slope notation, and the closing derivation explains why equal ratios yield multiple optimal allocations. Three learning objectives and three retrospective takeaways align with the three tasks.

The [three-case schematic](../../weeks/week-05/L5c/figs/Fig-ThreeCases-LP-Schematic.svg) has a shorter SVG viewport, removing empty margins while preserving all drawing elements and labels. It remains a schematic rather than a plot regenerated from the inputs, as explained in the notebook.

Validation completed during the round and final review:

- All seven final code cells executed successfully with Julia 1.12.7. The final saved code matches that execution; the subsequent closing-sentence revision changed only Markdown and preserved all outputs.
- All 21 model checks passed for the default inputs, an alternate interior optimum, and two changed-input scenarios: 84 passing assertions across four runs.
- Checks covered notebook validity, execution counts, local links, documentation anchors, complete table contents, three objectives/tasks/takeaways, equation lead-ins, and section separators.
- The complete saved narrative and four contiguous rendered sections were inspected, including equations, code, tables, the figure, and the Summary.
- The revised closing sentence was rendered, visually checked, and approved. The saved Summary matches the reviewed preview.
- Rendered figure pixels were unchanged within the retained viewport. SVG validity, provenance hashes, and whitespace checks passed.

No required corrections remain from this round. Classroom feedback should determine whether the algebra, code, and geometry need more teaching time. On September 17, the notebook hash was updated to the final approved closing-sentence revision, and the figure hash was reconfirmed. This review does not change the Week 5 release status.

Reviewed notebook SHA-256: `83f977ad761ce7d81abb7e917dd46bbd407c6bdb75591a404c382d47b6991af2`

Reviewed figure SHA-256: `bcff2d81c91c297060b996b4a3066261d02070e79464fd50dbea5184a133508f`
