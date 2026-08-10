# CHEME 4800/5800 Fall 2026 Content Selections

**Status:** Working implementation selections, ready for row-level review  
**Depends on:** [CHEME 4800/5800 Fall 2026 Topic Boundary](COURSE-TOPIC-BOUNDARY-FALL-2026.md)  
**Purpose:** Resolve the remaining classification, communications/MCP, and Week 15 choices without reopening the whole course design.

## 1. Selected cases

| Course location | Working selection | Disposition of older material |
|---|---|---|
| Week 9 classification | AI4I 2020 predictive-maintenance data | Replace banknote as the common case; retain XOR as an optional linear-separability demonstration |
| Week 13 REST | National Weather Service API plus committed response fixtures | Adapt the strong 2024/2025 NWS client; retain BiGG as an optional domain extension |
| Week 13 MCP | Local, read-only urea-cycle network resource and flux-balance checking tool | Reuse the small 2025 FBA case, not the 15 MB genome-scale save state |
| Week 15 advanced topic | Dynamics as algorithms: explicit Euler, stability, and build-versus-buy ODE solvers | Replace Fall Hopfield/FNN; adapt the 2024 three-gene and fermentation examples |

These selections preserve the useful historical material while giving each new or revised block a distinct reason to exist.

## 2. Week 9: predictive-maintenance classification

Use the [UCI AI4I 2020 Predictive Maintenance Dataset](https://archive.ics.uci.edu/dataset/601/ai4i%2B2020%2Bpredictive%2Bmaint) for both the perceptron and logistic-regression meetings.

The dataset is a good Fall case because it is small enough to distribute directly, has an engineering interpretation, and exposes a real validation issue: machine failures are uncommon enough that raw accuracy can be misleading. UCI reports 10,000 observations, six feature variables, no missing values, a 509.8 KB CSV, and a CC BY 4.0 license.

### Common task contract

Students will:

1. separate identifiers, input features, and targets;
2. exclude the five failure-mode target columns from the feature matrix to prevent target leakage;
3. make a reproducible stratified train/test split;
4. standardize continuous features using training-set statistics only;
5. fit a perceptron and logistic-regression model to the same split;
6. compare accuracy with a confusion matrix, recall, precision, and a majority-class baseline;
7. explain the engineering tradeoff between a missed failure and a false alarm.

The existing 2025 classification scaffolding remains useful for types, optimization, and plotting, but its banknote-specific data loader and narrative should be replaced. The XOR notebook becomes a short optional demonstration of why a linear classifier can fail; it is not the common lab.

### Data placement

When migration begins, store the original CSV with an attribution/readme rather than hiding the download inside notebook execution. Record the UCI DOI `10.24432/C5HS5C`, retrieval date, license, original filename, and a checksum. Do not preprocess the only retained copy.

## 3. Week 13: REST to MCP

### 3.1 REST client

Adapt the 2024/2025 National Weather Service client. The [NWS API documentation](https://weather-gov.github.io/api/general-faqs) describes an HTTPS, JSON/GeoJSON REST-style service and links its OpenAPI description. Its location forecast workflow also naturally demonstrates linked requests, response schemas, caching, headers, and recoverable failures.

The common lab must not require the live service to be available. It should include small recorded response fixtures and tests for:

- a successful points response followed by a forecast response;
- a malformed or incomplete payload;
- a non-success HTTP status;
- missing required fields;
- a live call as an optional integration test.

The client should send an identifiable, configurable `User-Agent`, as required by the NWS documentation. Secrets or paid API keys are not part of this lab.

### 3.2 MCP server

Build a local Python MCP server around the small urea-cycle network introduced in the Week 6 FBA lab. Use the [official Python MCP SDK](https://github.com/modelcontextprotocol/python-sdk) and [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector). The common activity uses local standard I/O transport and does not require a model account, remote deployment, OAuth, or a paid service.

The minimum server contract is:

- a read-only resource such as `cheme://metabolic-network/urea-cycle` containing a compact, documented network representation;
- a typed `summarize_network` tool that reports dimensions and named reactions/species;
- a typed `check_flux_balance` tool that validates a proposed flux vector and returns the residual `S*v` plus an explicit tolerance-based result;
- clear errors for incorrect vector length, non-finite inputs, and an unknown network identifier;
- no tool that mutates files, changes network bounds, executes arbitrary code, or accesses secrets.

Students test capability discovery, resource reading, a valid balanced input, an invalid or malformed input, and an unsupported action in Inspector. The numerical result should also be covered by ordinary unit tests so that protocol testing is not mistaken for computation testing.

The Python server may use a compact JSON representation derived from the existing `Network.net` source. A reference result generated by the Julia Week 6 implementation should be retained as a cross-language test fixture.

MCP implementation details should be revalidated shortly before the November unit. The protocol had a major `2026-07-28` revision, so the release should lock and test a compatible SDK/Inspector pair while the lecture emphasizes durable ideas—tools, resources, schemas, capability discovery, and trust boundaries—rather than a memorized wire lifecycle.

### 3.3 BiGG disposition

Keep the historical BiGG example as an optional extension or a source of attributed fixtures, not as a required live dependency. On August 10, 2026, the documented HTTP API returned the model index, but the HTTPS endpoint was not reachable. That makes it valuable for discussing transport security and service dependencies, but unsuitable as the only path through a graded lab.

Do not migrate `saved-model-iYO844.jld2` merely to support this unit. The small urea-cycle representation is sufficient for the MCP objectives and is substantially easier to inspect and test.

## 4. Week 15: dynamics as algorithms

Replace the former Fall Hopfield/FNN block with one compact advanced lecture:

> **Dynamics as algorithms: explicit Euler, numerical stability, and build-versus-buy ODE solvers**

Adapt two existing 2024 activities:

- `CHEME-4800-5800-Labs-AY-2024/week-9/Lab-9b`: implement a single-step solver for a three-gene memory network;
- `CHEME-4800-5800-Labs-AY-2024/week-9/Lab-9d`: solve the _Klebsiella oxytoca_ mixed-sugar model with a library solver.

The lecture should use a small explicit-Euler implementation to make time stepping, local error, step-size sensitivity, and stability concrete, then contrast it with a maintained solver package. This is a worked advanced topic, not a new multi-week differential-equations unit and not a separate graded lab during practicum week.

The Week 15 bridge can then connect:

`continuous dynamics -> time discretization -> discrete state update -> Spring state-space/spiking models`

Fall owns the numerical-computation prerequisite. Spring still owns the state-space and spiking architectures.

## 5. Deeper-dive scope control

The first rebalanced draft contained 74 deeper-dive labels. They were a topic wish list, not an approved requirement to author 74 notebooks. The working schedule now carries a 20-item launch set tied to verified 2024/2025 source families.

For the first Fall 2026 release:

1. migrate only deeper dives with a verified historical source and a clear link to a common-core meeting;
2. prefer one strong optional notebook over several overlapping variants;
3. link to Spring-owned neural/deep-RL material rather than duplicating it in the Fall release;
4. remove an unbuilt label from the student schedule instead of shipping a placeholder;
5. add new deeper dives only after all common lectures, labs, data, and tests run cleanly.

### Verified source families worth curating first

| Area | Historical source available | Recommended use |
|---|---|---|
| Data structures and recursion | 2025 stacks/queues/linked lists and recursive Fibonacci notebooks | Optional implementation variants |
| Sorting | 2025 bubble-sort and quicksort reference notebooks | One comparison notebook |
| Graphs | 2025 BFS/DFS algorithm notebooks | Optional algorithm detail |
| LP internals | 2025 revised-simplex and interior-point notebooks | Solver-internals deeper dives |
| Iterative linear solvers | 2025 Jacobi, Gauss-Seidel, SOR, and convergence notebooks | Algorithms plus one convergence notebook |
| SVD inference | 2025 confidence-interval derivation notebook | Optional derivation after adaptation |
| Online/sequential decisions | 2025 MWA, bandit, combinatorial-bandit, and Q-learning materials | Curate ordinary-bandit extensions; leave deep RL to Spring |
| REST | 2024/2025 NWS and BiGG examples | NWS core source; BiGG optional extension |
| Dynamic simulation | 2024 three-gene and fermentation labs | Week 15 source and optional second case |

Proofs and advanced topics from the earlier draft that are not represented by a verified source remain backlog ideas, not migration commitments. The 20 launch labels still require adaptation and run validation; “verified source” means that a relevant historical notebook exists, not that it is already release-ready.

## 6. Concrete authoring work created by these selections

| Artifact | Work type |
|---|---|
| AI4I data/provenance record | New small data asset and attribution |
| Week 9 student/solution notebooks | Adapt existing classifier scaffolding to a shared engineering case |
| NWS fixtures and client tests | Adapt existing client and add deterministic tests |
| Urea-cycle JSON fixture | Derive a small inspectable representation from the 2025 FBA source |
| MCP server, tests, and Inspector instructions | New content; highest-risk authoring block |
| Week 15 dynamics lecture | Adapt two 2024 activities into one worked bridge lecture |
| Deeper dives | Curate verified sources only; no blanket authoring program |

The Week 13 communications unit is the best first vertical prototype because it is the largest net-new block and exercises Python packaging, fixtures, tests, documentation, and cross-language course data without forcing bulk migration of the rest of the semester.
