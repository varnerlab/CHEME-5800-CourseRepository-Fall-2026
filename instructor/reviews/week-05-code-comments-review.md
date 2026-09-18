# Week 5 code-cell commenting pass

**Status:** Completed September 18, 2026. Reviewed every code cell in all seven Week 5 notebooks: 48 cells reviewed, 35 updated, and 13 retained with their existing comments.

| Notebook | Cells reviewed | Cells updated |
|---|---:|---:|
| [L5a maximum-flow lecture](../../weeks/week-05/L5a/CHEME-5800-L5a-Lecture-MaximumFlowProblems-Fall-2026.ipynb) | 1 | 1 |
| [L5a maximum-flow worked example](../../weeks/week-05/L5a/CHEME-5800-L5a-WorkedExample-MaximumFlow-Fall-2026.ipynb) | 10 | 10 |
| [L5b sensitivity lab](../../weeks/week-05/L5b/CHEME-5800-L5b-Lab-MaximumFlowSensitivity-Fall-2026.ipynb) | 11 | 7 |
| [L5c revised-simplex notebook](../../weeks/week-05/L5c/CHEME-5800-L5c-Algorithm-RevisedSimplex-Fall-2026.ipynb) | 1 | 1 |
| [L5c fruit-allocation example](../../weeks/week-05/L5c/CHEME-5800-L5c-Example-FruitAllocation-Fall-2026.ipynb) | 7 | 7 |
| [L5c linear-programming lecture](../../weeks/week-05/L5c/CHEME-5800-L5c-Lecture-LinearProgramming-Fall-2026.ipynb) | 1 | 1 |
| [L5d minimum-cost assignment lab](../../weeks/week-05/L5d/CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb) | 17 | 8 |

The comments explain setup, array and edge indexing, units, comprehensions and generators, independent scenario copies, and what each validation check establishes. Existing clear comments were retained. Comprehension and generator explanations include official Julia references.

Verification:

- All seven notebooks pass notebook-format validation.
- Julia parsed syntax trees match before and after for all 48 code cells, ignoring source-location metadata. Only comments and whitespace changed.
- All narrative, equations, saved outputs, execution counts, cell order, identifiers, and metadata are preserved from the working copies at the start of this pass, including existing instructor edits.
- All 48 code cells were visually inspected across twelve rendered review pages. Comments are readable and unclipped.
- Computational tests were not rerun because executable code did not change. Previous execution evidence and review scores remain applicable.

The prior notebook approvals are retained. This pass covers notebook code cells; it does not edit slide decks or shared source files.

Notebook hashes after this commenting pass:

- **L5a maximum-flow lecture:** `90f1bc26ea2b4d18f9156a0be6489a4273045fb5081d54f22ce9e72f3761eea9`
- **L5a maximum-flow worked example:** `2c0d3f1f045641896d3d2826ef85e1b91fb130b5124f5b56f6bdb1be72061737`
- **L5b sensitivity lab:** `ee327f4bdaf461ee2a57888470b01a397d3add04bf139c6f01890354ddbadb83`
- **L5c revised-simplex notebook:** `5b492f35057ef62611b707ce09c375cad6fa3148545a851514629f2cf38487b3`
- **L5c fruit-allocation example:** `3146268b46d79ee81120549fad71e199110a66e579340738e633fa14ad3de019`
- **L5c linear-programming lecture:** `b7396e0eb55755c391f1ac8033a8920afe4b55b14a498ac329cabfb8faf440a9`
- **L5d minimum-cost assignment lab:** `e97e21eb259261f5864d0ccde8a48a73b745804ba085fde99bed890f7579e91c`
