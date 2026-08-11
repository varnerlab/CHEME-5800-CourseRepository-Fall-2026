# Week 4 — Graph representations, traversal, and shortest paths

Week 4 develops one coherent graph-computation arc: represent a graph, traverse
its reachable vertices, optimize a weighted path, and interpret the selected route
in a production-planning example. Every meeting-local `Include.jl` delegates to
the single pinned root Julia environment and loads only that meeting's packages
and source.

## Learning objectives

By the end of the week, students should be able to:

1. represent directed and undirected graphs using edge lists, adjacency lists, and matrices;
2. identify tree, complete, and bipartite structure and its algorithmic implications;
3. implement and test deterministic breadth-first and depth-first traversal;
4. formulate a weighted single-source shortest-path problem;
5. select Dijkstra or Bellman–Ford from the graph's edge-weight contract;
6. reconstruct and independently validate a computed route; and
7. interpret how a production-cost change alters an optimal process path.

## Class-meeting sequence

| Meeting | Date | Topic | Notebooks |
|---|---|---|---|
| L4a | Mon. Sep. 14 | Graph/tree structure and representations | [Lecture](L4a/CHEME-5800-L4a-Lecture-GraphAndTreeRepresentations-Fall-2026.ipynb) |
| L4b | Tue. Sep. 15 | Breadth-first and depth-first traversal | [Lab](L4b/CHEME-5800-L4b-Lab-BreadthFirstAndDepthFirstSearch-Fall-2026.ipynb) · [BFS algorithm](L4b/CHEME-5800-L4b-Algorithm-BreadthFirstSearch-Fall-2026.ipynb) · [DFS algorithm](L4b/CHEME-5800-L4b-Algorithm-DepthFirstSearch-Fall-2026.ipynb) |
| L4c | Wed. Sep. 16 | Dijkstra and Bellman–Ford shortest paths | [Lecture](L4c/CHEME-5800-L4c-Lecture-ShortestPathAlgorithms-Fall-2026.ipynb) |
| L4d | Thu. Sep. 17 | Production-planning shortest path and sensitivity | [Lab](L4d/CHEME-5800-L4d-Lab-ProductionPlanningShortestPath-Fall-2026.ipynb) |

The two traversal notebooks are supporting `Algorithm` notebooks, not an
`extensions` hierarchy. They expose implementation details selected for the
CHEME 5800 path while the integrated L4b lab remains the main meeting notebook.

## Data provenance

The edge lists are small instructor-authored synthetic teaching examples retained
from Fall 2025. Each data directory records its purpose and SHA-256 digest. The
L4a/L4b graph is duplicated deliberately so each meeting folder can run without a
cross-meeting relative-data dependency.

## Preparation and validation

Install the course environment once from the repository or extracted bundle root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Then validate Week 4 from the authoring-repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-04/runtests.jl
```

Problem sets and their simultaneously released solutions use separate repositories
and are not included in this weekly instructional unit.

## Source adaptation

- L4a directly retains the detailed Fall 2025 graph/tree lecture and its original
  figure assets. A tested edge-list, adjacency-list, and adjacency-matrix comparison
  was added to connect the mathematical discussion to executable representation.
- L4b directly retains the Fall 2025 graph-construction and BFS/DFS lab, plus the
  original algorithm explanations. The old solution/student split was removed;
  traversal now uses deterministic local implementations with explicit contracts.
- L4c directly retains the Fall 2025 shortest-path formulation and Dijkstra and
  Bellman–Ford explanations. Executable current-Julia comparisons, negative-edge
  validation, path reconstruction, and negative-cycle detection were added.
- L4d directly retains the Fall 2025 production-process graph, schematic, route
  visualization, and equipment-discount scenario. Its setup now uses the root
  environment, and Bellman–Ford provides an independent check of Dijkstra's result.

