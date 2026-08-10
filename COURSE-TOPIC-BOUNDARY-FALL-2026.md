# CHEME 4800/5800 Fall 2026 Topic Boundary

**Status:** Approved working direction for topic selection and migration  
**Purpose:** Preserve the strongest 2024/2025 course material, make selective topic trades, and prepare students for CHEME 5820 without teaching the Spring course twice.

## 1. Governing direction

Fall 2026 is a repackaging and selective-rebalancing project, not a wholesale course redesign.

The course will:

1. Preserve the variety of worked examples from prior offerings rather than force one semester-long case.
2. Retain all 16 weeks and the lecture/lab rhythm.
3. Put student-authored, tested code earlier in the semester.
4. Reduce repeated surveys of closely related algorithms when one representative method is enough.
5. Use optional deeper-dive notebooks for proofs, solver internals, alternate algorithms, and additional breadth.
6. Treat preparation for CHEME 5820 as an explicit curriculum constraint.

Each topic normally has three layers:

- **Lecture:** basic theory and a worked example.
- **Lab:** implementation, testing, and interpretation; Julia remains primary, with selected Python work.
- **Deeper dive:** optional and ungraded; linked from the lecture and not assumed later.

## 2. Fall 5800 exit competencies

Students completing CHEME 5800 should be able to:

- write, test, debug, and document functions operating on arrays, tables, files, and structured data;
- work productively in a reproducible Julia environment and read a small amount of equivalent Python;
- translate an engineering or data problem into types, interfaces, matrices, graphs, objectives, constraints, states, and tests;
- solve and validate linear systems, least-squares models, regularized models, and a representative linear program;
- reason about graph traversal, shortest paths, capacity, and conservation;
- train and evaluate a basic classifier without treating a library result as self-validating;
- explain online learning, exploration versus exploitation, Markov models, MDPs, and basic Q-learning;
- consume a REST API and expose a small, typed capability through an MCP server;
- identify numerical, data, security, and modeling assumptions that limit a computational result.

These are operational competencies. CHEME 5800 should emphasize implementing, applying, testing, and interpreting them rather than surveying every available algorithm.

## 3. Boundary with CHEME 5820

### Fall 5800 supplies

- programming fluency, testing, debugging, environments, and data handling;
- matrix/vector computation, iterative methods, SVD, least squares, and regularization;
- loss functions, gradient-based optimization, binary classification, validation, and confusion matrices;
- graph representations and algorithms;
- probability, sampling, Markov models, MDPs, and tabular Q-learning;
- APIs, structured interfaces, schemas, provenance, and trust boundaries.

### Spring 5820 owns

- clustering and more advanced spectral learning methods;
- kernel methods and advanced classification;
- Hopfield and Boltzmann machines;
- feedforward neural networks and backpropagation as a full topic;
- embeddings, autoencoders, RNNs, LSTMs, attention, and transformers;
- structured state-space, spiking, and graph neural networks;
- deep reinforcement learning, including Deep Q-learning.

### Intentional versus accidental overlap

Some conceptual overlap is desirable, but it must change level:

- Fall **implements and applies** SVD, regularization, classification, and tabular Q-learning.
- Spring may **review briefly, generalize, or connect** those ideas to more advanced models.
- Spring should not repeat an unchanged Fall notebook, dataset, and task.
- Fall Hopfield and feedforward-network materials become optional previews or Spring source material, not common-core Fall units.
- Fall Q-learning remains common because Spring Deep Q-learning explicitly builds on it.

The banknote perceptron/logistic-regression sequence currently appears in both courses. Fall 2026 should use a different application or Spring should replace its duplicate; the two courses should not use the same notebook as separate core instruction.

## 4. Topic disposition

### Keep in the common core

- types, functions, arrays, dictionaries/tables, files, errors, tests, and debugging;
- selected iteration, recursion, sorting, and complexity ideas;
- graphs, traversal, and shortest paths;
- network flow, one coherent LP formulation/solution arc, dual interpretation, and FBA;
- iterative linear-system methods, SVD, least squares, regularization, and validation;
- binary classification and numerical optimization;
- one online-learning method, ordinary multiarm bandits, Markov models, MDPs, and tabular Q-learning;
- HTTP, JSON, REST APIs, typed schemas, MCP servers, and communication/security boundaries.

### Compress or move to deeper dives

- hexadecimal/text representation beyond the essential encoding idea;
- custom stacks, queues, linked lists, replay buffers, and multiple sorting implementations;
- detailed Ford-Fulkerson variants and proofs;
- simplex, revised-simplex, interior-point, and duality proofs;
- multiplicative weights as an LP solver;
- combinatorial bandits and regret derivations;
- policy-gradient and actor-critic derivations.

### Leave to CHEME 5820

- Hopfield and Boltzmann machines as required topics;
- feedforward-network architecture and training as a required topic;
- deep Q-networks and other deep reinforcement-learning methods;
- embeddings, autoencoders, sequence models, attention, transformers, state-space models, spiking networks, and GNNs.

Nothing in these lists requires deleting good historical notebooks. Non-core materials remain available as curated deeper dives or as source material for CHEME 5820.

## 5. Rebalanced Fall sequence

| Week | Core topic boundary |
|---:|---|
| 1 | Toolchain, values/types, floating-point behavior, and a first tested calculation |
| 2 | Functions, interfaces, arrays/tables, errors, tests, and debugging |
| 3 | Files/structured data plus selected iteration, recursion, sorting, and complexity |
| 4 | Graph representations, traversal, and shortest paths |
| 5 | Network flow and linear-program formulation |
| 6 | Dual interpretation/FBA plus iterative linear-system methods |
| 7 | SVD and data reduction |
| 8 | Least squares, regularization, cross-validation, and model checking |
| 9 | Binary classification and numerical optimization |
| 10 | Online learning and ordinary multiarm bandits |
| 11 | Markov models, MDPs, value iteration, and policy reasoning |
| 12 | Tabular Q-learning and sequential-decision integration |
| 13 | HTTP/JSON/REST clients and MCP servers |
| 14 | Integration, practicum launch, and Thanksgiving break |
| 15 | Numerical dynamics/solver choice, practicum studio, and CHEME 5820 bridge |
| 16 | Course synthesis and transition to CHEME 5820 |

## 6. Communications and MCP unit contract

The communication unit should occupy a real lecture/lab sequence rather than a single late-semester survey.

Students will:

1. inspect an HTTP request/response and parse a documented JSON payload;
2. implement and test a small API client with explicit error handling;
3. distinguish an API from an MCP server and identify host, client, and server responsibilities;
4. define a typed MCP tool and a read-only resource around an existing course computation or dataset;
5. test discovery, a valid call, malformed input, and a denied or unsupported action without requiring a paid model account;
6. explain least privilege, secret handling, side effects, and why model-selected tool calls still require application/user controls.

The common lab should use a supported official SDK and MCP Inspector. In Fall 2026, Python is the preferred implementation language because it has an official MCP SDK and provides a deliberate cross-language lab. Protocol internals that are likely to change should remain a deeper dive; the common core should emphasize stable concepts, schemas, testing, and trust boundaries.

## 7. Consequences for migration and data

Topic selection precedes final data placement.

- Fall image collections are not required merely because historical Hopfield/FNN notebooks used them.
- The Fall classification dataset should differ from the Spring 5820 banknote example.
- Large financial data should be retained only if the selected SVD/online-learning activities need the full history; a documented teaching subset is preferable when it preserves the objective.
- The data inventory should be filtered against this approved topic boundary before deciding which files belong in Git, a weekly bundle, or a separate asset.

## 8. Selected implementation cases and next actions

The classification, communications/MCP, and Week 15 cases are specified in [CHEME 4800/5800 Fall 2026 Content Selections](COURSE-CONTENT-SELECTIONS-FALL-2026.md):

- AI4I predictive maintenance for the shared perceptron/logistic-regression case;
- NWS plus deterministic fixtures for REST;
- a local, read-only urea-cycle flux-balance MCP server;
- numerical time integration and solver choice for Week 15.

Before bulk migration:

1. Review the rebalanced schedule at session level.
2. Adapt and run-validate the 20-item deeper-dive launch set selected from verified historical sources.
3. Build the Week 13 communications unit as the first vertical prototype.
4. Filter and place only the data required by selected common-core content.
5. Resolve the root environment and release-validation policy.
