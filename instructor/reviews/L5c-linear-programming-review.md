# L5c linear-programming lecture review

**Status:** Reviewed and approved by the instructor on September 17, 2026. Final approval covers the current saved notebook, the worked allocation and network-flow examples, both figures, the duality and solver-workflow sections, and the Summary with its revised framing and general key takeaways. The polish round is closed.

**Notebook:** [L5c: Introduction to Linear Programming](../../weeks/week-05/L5c/CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb)

**Final editorial score:** 9.1/10, compared with 6.5/10 before the polish round. These scores are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness | 5.5 | 9.3 |
| Organization | 7.0 | 9.2 |
| Narrative flow | 6.0 | 9.1 |
| Presentation | 7.0 | 9.2 |
| Cognitive density and pacing | 6.5 | 8.8 |

The lecture follows the supplied depth-first-search notebook's explanatory pattern: definitions and assumptions, worked calculations, and interpretation. The network example distinguishes a specified delivery from maximum flow. The duality section corrects indexing and equality/free-variable rules, develops weak and strong duality, and interprets the consumer's budget shadow price. The solver workflow separates status, feasibility, recomputed objectives, and optimality bounds. Three objectives and three retrospective takeaways align; the takeaways remain applicable when numerical example parameters change.

Validation completed during the polish round and final review:

- Notebook structure, all seven distinct local links/images, SVG validity, section separators, and preservation of approved wording passed.
- Each revised section was rendered and visually inspected; the saved closing sections were rendered again for the final check.
- Worked allocation, geometry, consumer-dual, and network-flow calculations were verified analytically using exact rational arithmetic.
- Code, outputs, execution counts, and metadata match the initial notebook. Julia and companion notebooks were not executed during this prose and figure polish.

No required corrections remain from this round. Classroom feedback should determine whether the developed algebra, network example, and duality need more teaching time.

Reviewed notebook SHA-256: `8cbe0b38110cba482879b0df5175278ad24111f65c53b8264130a88dd17d3a89`

Reviewed [three-case allocation schematic](../../weeks/week-05/L5c/figs/Fig-ThreeCases-LP-Schematic.svg) SHA-256: `bcff2d81c91c297060b996b4a3066261d02070e79464fd50dbea5184a133508f`

Reviewed [three-node flow diagram](../../weeks/week-05/L5c/figs/Fig-MinCostFlow-ThreeNode.svg) SHA-256: `b772806c39a108e112d1eca2d5489267b4903b81dc1c59dea5c6b65614cc03c4`
