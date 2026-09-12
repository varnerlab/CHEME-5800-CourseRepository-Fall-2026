# L4b function reference

The [L4b lab](../CHEME-5800-L4b-Lab-BreadthFirstAndDepthFirstSearch-Fall-2026.ipynb) uses the functions below to build and traverse a directed graph. Vertex identifiers are integers; they have no physical units. The traversal functions return visit orders, not paths or weighted distances.

The completed adjacency helper and traversal exercises are defined in [`src/Compute.jl`](../src/Compute.jl). The parser is defined in the lab notebook. Rerun the setup cell after saving changes to the student source file.

<a id="adjacency_from_edges"></a>
## adjacency_from_edges

```julia
adjacency_from_edges(edges) -> Dict{Int64, Vector{Int64}}
```

- **Input:** an iterable of directed `(source, target)` pairs with identifiers representable as `Int64`.
- **Result:** a dictionary mapping each vertex appearing in an edge to a sorted vector of distinct outgoing neighbors. A target with no outgoing edges has an empty vector. Isolated vertices absent from all edge pairs are not added.
- **Behavior:** builds a new dictionary without changing the input pairs. Weights are not part of this input.

The lab supplies this function; students do not need to implement it.

<a id="depth_first_order"></a>
## depth_first_order

```julia
depth_first_order(adjacency::AbstractDict, start::Integer) -> Vector{Int64}
```

- **Inputs:** an adjacency dictionary and starting vertex, using identifiers representable as `Int64`. Outgoing-neighbor collections must be finite; the lab represents every vertex as a key.
- **Result:** each reachable vertex exactly once, recorded on its first recursive visit. Outgoing neighbors are considered in ascending identifier order.
- **Behavior:** leaves the dictionary and neighbor collections unchanged. A vertex with no outgoing neighbors ends that branch. A missing neighbor key is treated as an empty neighbor list by the supplied helper.
- **Errors:** `ArgumentError` if `start` is a Boolean or is not a dictionary key. The unfinished student function raises its TODO error until implemented.

Complete TODOs 1–3 using the [depth-first algorithm notebook](../CHEME-5800-L4b-Algorithm-DepthFirstSearch-Fall-2026.ipynb).

<a id="visit"></a>
## visit

```julia
visit(vertex::Int64) -> Nothing
```

This is the nested helper students define inside `depth_first_order`, not an exported function. It shares the surrounding `visited` set and `order` vector. A call for an already visited vertex returns without changing them. On a first visit, it records the vertex and explores its ordered outgoing neighbors recursively. It returns after those calls finish.

<a id="breadth_first_order"></a>
## breadth_first_order

```julia
breadth_first_order(adjacency::AbstractDict, start::Integer) -> Vector{Int64}
```

- **Inputs:** the same adjacency dictionary and starting-vertex requirements as `depth_first_order`.
- **Result:** each reachable vertex exactly once, recorded when it is removed from the queue for processing. The order follows layers of increasing minimum edge count from `start`; neighbors are considered in ascending identifier order.
- **Behavior:** marks vertices when enqueued and leaves the input unchanged. The FIFO queue is the course's [`MyQueue`](../../../../code/src/StacksQueues.jl): [`push!`](../../../../code/src/StacksQueues.jl) enqueues a vertex, [`popfirst!`](../../../../code/src/StacksQueues.jl) removes the front vertex, and [`isempty`](../../../../code/src/StacksQueues.jl) checks whether processing is complete. Edge weights are ignored, and distances and predecessors are not returned.
- **Errors:** `ArgumentError` if `start` is a Boolean or is not a dictionary key. The unfinished student function raises its TODO error until implemented.

Complete TODOs 4–6 using the [breadth-first algorithm notebook](../CHEME-5800-L4b-Algorithm-BreadthFirstSearch-Fall-2026.ipynb).

<a id="parse_edge_record"></a>
## parse_edge_record

```julia
parse_edge_record(record::String, delimiter::Char = ',')
```

- **Inputs:** a data record containing `source,target,weight` and its delimiter. The source and target are integer identifiers; the weight is an edge cost in arbitrary units.
- **Result:** `(source::Int, target::Int, weight::Float64)` after removing surrounding whitespace.
- **Errors and malformed input:** returns `nothing` if there are not exactly three fields; invalid numeric fields raise a parsing error. The file reader expects a tuple, so malformed records are not silently skipped.

The [lab notebook](../CHEME-5800-L4b-Lab-BreadthFirstAndDepthFirstSearch-Fall-2026.ipynb) defines this callback and passes it to the course file reader, which skips comments and empty lines.
