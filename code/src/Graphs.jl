# ------------------------------------------------------------------------------------------------ #
# Graphs.jl
#
# Traversal, shortest-path, and maximum-flow functions for the course graph models
# (MySimpleDirectedGraphModel, MySimpleUndirectedGraphModel, and MyDirectedBipartiteGraphModel),
# which build(...) in Factory.jl creates from a dictionary of edge models.
#
# Where the course uses this file:
# - The L4d lab calls findshortestpath(...) with DijkstraAlgorithm() and BellmanFordAlgorithm().
# - The L5a worked example calls maximumflow(...) with FordFulkersonAlgorithm() and
#   EdmondsKarpAlgorithm(), and the L5b lab also calls maximumflow(...).
# - build(...) in Factory.jl calls _children(...) to fill the children field of a graph model.
# - walk(...) is not called in the week 3-5 notebooks; the L4b lab has students write their
#   own depth-first and breadth-first traversals.
# The L4c lecture teaches Dijkstra and Bellman-Ford with the edge-vector versions in
# ShortestPathAlgorithms.jl; the step names in the comments below follow that lecture.
#
# How a graph model stores a graph (the fields used below):
# - graph.nodes: a dictionary from node id to its node model (MyGraphNodeModel). build(...)
#   renumbers the node ids 1, 2, ..., n, in increasing order of the ids in the edge file.
# - graph.edges: a dictionary from the pair (source id, target id) to the weight of that edge.
# - graph.children: a dictionary from node id to the set of ids that its outgoing edges point to.
# - graph.capacity (MyDirectedBipartiteGraphModel only): a dictionary from (source id, target id)
#   to the flow bounds (lower, upper). It keeps the ids of the edge file, not the renumbered ids.
#
# Public functions:
#
#   children(graph, node)                         the ids of the nodes that node's outgoing edges point to
#   weight(graph, source, target)                 the weight of the edge source → target
#   weight(graph, source, target, edgemodels)     a weight looked up through a dictionary of edge models
#   walk(graph, startnode; algorithm)             every node reachable from startnode, in DFS or BFS order
#   findshortestpath(graph, start; algorithm)     shortest distances and predecessors (Dijkstra or Bellman-Ford)
#   maximumflow(graph, source, sink; algorithm)   the maximum flow and the edge flows (Ford-Fulkerson or Edmonds-Karp)
#
# Private helpers (a leading underscore marks a name that callers should not use):
#
#   _children(edges, id)                          scans the edge dictionary for the children of one node
#   _DFS(...), _BFS(...)                          the depth-first and breadth-first traversals behind walk
#   _search(graph, start, algorithm)              Dijkstra and Bellman-Ford, one method each, behind findshortestpath
#   _find_path_dfs(R, s, t), _find_path_bfs(R, s, t)  find an augmenting path in a residual-capacity matrix
#   _augment_path!(R, F, parent, s, t, Δ)         sends Δ more units of flow along an augmenting path
#   _edge_flows(C, F)                             lists the edges that carry positive flow
#   _flow(algorithm, C, source, sink)             the Ford-Fulkerson loop behind maximumflow, one method per algorithm
#
# Several functions here have more than one method with the same name. Julia picks the method
# from the types of the arguments; this is called multiple dispatch. For example,
# findshortestpath(...) calls _search(graph, start, algorithm), and Julia runs the Dijkstra
# method when algorithm is a DijkstraAlgorithm(), and the Bellman-Ford method when algorithm is
# a BellmanFordAlgorithm().
#
# Many signatures end in `where T <: AbstractGraphModel`. This makes T a type parameter: the
# argument `graph::T` may be any graph type that is a subtype of AbstractGraphModel.
# ------------------------------------------------------------------------------------------------ #

"""
    _children(edges::Dict{Tuple{Int64, Int64}, Number}, id::Int64) -> Set{Int64}

Return the ids of the children of node `id`: every node `v` with an edge `id → v`.

We scan every edge in `edges` and keep the target of each edge that starts at `id`.
`build(...)` in Factory.jl calls this function once per node to fill the `children` field of
a graph model.

### Arguments
- `edges::Dict{Tuple{Int64, Int64}, Number}`: the edge dictionary of a graph. Key `(u, v)` is
  the edge `u → v`; its value, the weight, is not used.
- `id::Int64`: the node whose children we want.

### Returns
- `Set{Int64}`: the ids of the targets of the edges that leave node `id`; empty when no edge
  leaves `id`.
"""
function _children(edges::Dict{Tuple{Int64, Int64}, Number}, id::Int64)::Set{Int64}

    # initialize -
    childrenset = Set{Int64}(); # an empty set of child ids

    # Simple but slow: we check every edge of the graph, not only the edges that leave node id.
    # Calling this once per node, as build(...) does, checks (number of nodes) × (number of edges)
    # pairs. Iterating over a dictionary gives key => value pairs; we unpack each pair into k,
    # the key (u, v), and _, the weight, which we do not use -
    for (k, _) ∈ edges
        if k[1] == id # k[1] is the source of the edge, and k[2] is its target
            push!(childrenset, k[2]);
        end
    end

    # return -
    return childrenset;
end

"""
    _DFS(graph::T, node::MyGraphNodeModel, visited::Set{Int64}, order::Array{Int64,1};
        verbose::Bool = false) -> Nothing where T <: AbstractGraphModel

Visit `node` and, recursively, every node reachable from it, in depth-first order.

This is the recursive depth-first search (DFS) of the L4b algorithm notebook. If `node` is not
yet visited, we mark it visited, append its id to `order`, and call `_DFS` on each child that
is not yet visited. Each call finishes the whole branch below one child before it moves to the
next child. The children come from a `Set`, which has no fixed order, so the children of a
node are not necessarily visited in increasing id order.

`walk` calls this function. The function changes `visited` and `order` in place.

### Arguments
- `graph::T`: the graph, where `T` is any subtype of `AbstractGraphModel`.
- `node::MyGraphNodeModel`: the node to visit.
- `visited::Set{Int64}`: the ids of the nodes visited so far. Every recursive call shares this set.
- `order::Array{Int64,1}`: the ids of the visited nodes, in visit order. Every recursive call
  shares this vector.
- `verbose::Bool = false`: when `true`, print the id of each node the search reaches (keyword
  argument).

### Returns
- `Nothing`. The visit order is in `order`.
"""
function _DFS(graph::T, node::MyGraphNodeModel, visited::Set{Int64}, order::Array{Int64,1};
    verbose::Bool = false) where T <: AbstractGraphModel

    # print - if verbose is true
    if (verbose == true)
        println("Visiting node: ", node.id);
    end

    # visit this node only if we have not visited it before; otherwise the call does nothing -
    if (in(node.id, visited) == false) # recursive case
        push!(visited, node.id); # add this node to the visited set -
        push!(order, node.id); # add this node to the order array

        mychildren = children(graph, node);  # get the children of the current node -

        # visit the children -
        for child in mychildren
            if (in(child, visited) == false) # a change from the lecture pseudocode: we call _DFS only on a child that is not yet visited, instead of calling it on every child and letting the call check
                _DFS(graph, graph.nodes[child], visited, order, verbose=verbose); # recursive call: finish the whole branch below this child before the next child
            end
        end
    end
end


"""
    _BFS(graph::T, node::MyGraphNodeModel, visited::Set{Int64}, order::Array{Int64,1};
        verbose::Bool = false) -> Nothing where T <: AbstractGraphModel

Visit every node reachable from `node` in breadth-first order, using a first-in-first-out queue.

This is breadth-first search (BFS). The queue holds the ids of discovered nodes that wait to be
processed. Each pass of the main loop removes the id at the front of the queue. If that node
is not yet visited, we mark it visited, append its id to `order`, and add each child that is
not yet visited to the back of the queue. The search visits the start node, then the nodes
one edge away, then the nodes two edges away, and so on.

This version marks a node as visited when it leaves the queue. The L4b algorithm notebook
marks a node when it enters the queue instead. Here a node can enter the queue more than once,
and the check on removal skips the repeats. The children come from a `Set`, which has no
fixed order.

`walk` calls this function. The function changes `visited` and `order` in place.

### Arguments
- `graph::T`: the graph, where `T` is any subtype of `AbstractGraphModel`.
- `node::MyGraphNodeModel`: the node to start from.
- `visited::Set{Int64}`: the ids of the nodes visited so far; normally empty at the start.
- `order::Array{Int64,1}`: the ids of the visited nodes, in visit order; normally empty at the start.
- `verbose::Bool = false`: when `true`, print each visited node and the queue (keyword argument).

### Returns
- `Nothing`. The visit order is in `order`.
"""
function _BFS(graph::T, node::MyGraphNodeModel, visited::Set{Int64}, order::Array{Int64,1};
    verbose::Bool = false) where T <: AbstractGraphModel

    # initialize -
    q = Queue{Int64}(); # an empty first-in-first-out queue of node ids, from DataStructures.jl

    # enqueue the first node -
    enqueue!(q, node.id); # enqueue! adds an id at the back of the queue

    # main loop -
    while isempty(q) == false
        v = dequeue!(q); # dequeue! removes and returns the id at the front of the queue
        if (in(v,visited) == false) # skip v if we already visited it; it can be in the queue more than once

            # print - if verbose is true. Inside a string, $(v) inserts the value of v -
            if (verbose == true)
                println("Visiting node: $(v). My Queue: $(q)");
            end

            push!(visited, v); # add this node to the visited set
            push!(order, v); # add this node to the order array

            # add each child that is not yet visited to the back of the queue -
            mychildren = children(graph, graph.nodes[v]);
            for child in mychildren
                if (in(child, visited) == false) # mod: don't enqueue if the child has already been visited
                    enqueue!(q, child);
                end
            end
        end
    end
end

"""
    _search(graph::T, start::MyGraphNodeModel, algorithm::DijkstraAlgorithm)
        -> Tuple{Dict{Int64, Float64}, Dict{Int64, Union{Nothing, Int64}}} where T <: AbstractGraphModel

Compute the shortest distance from `start` to every node of `graph` with Dijkstra's algorithm.
`findshortestpath` calls this method when `algorithm` is a `DijkstraAlgorithm()`.

A min-priority queue holds node ids, each with its distance estimate `dist[v]` as its
priority. After the "Initialize" step, each pass of the main loop does two of the L4c steps:

1. Select a vertex: remove the node `u` with the smallest estimate from the queue.
2. Relax its outgoing edges: for each child `w` of `u`, compute `alt = dist[u] + w(u,w)`,
   where `w(u,w)` is the edge weight. If `alt < dist[w]`, set `dist[w] = alt` and
   `prev[w] = u`, and lower the priority of `w` in the queue to `alt`.

This version differs from the L4c pseudocode in one way. We put every node in the queue at
the start, with priority 0 for `start` and `∞` for every other node, and we keep no processed
set. A node that has left the queue never gets a smaller estimate when every weight is
nonnegative, so it never re-enters the queue. The "Mark it as processed" step is therefore
not needed.

### Arguments
- `graph::T`: the graph, where `T` is any subtype of `AbstractGraphModel`. Every edge weight
  must be ≥ 0.
- `start::MyGraphNodeModel`: the node to start from.
- `algorithm::DijkstraAlgorithm`: selects this method; its value is not used.

### Returns
A tuple of two dictionaries, in this order:
- `distances::Dict{Int64, Float64}`: key `v` holds the shortest distance from `start` to node
  `v`; `Inf` when `v` is unreachable.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: key `v` holds the node before `v` on the
  selected shortest route; `nothing` when `v` is unreachable. The start node has no key.

### Throws
- `ArgumentError`: an edge weight is negative.
"""
function _search(graph::T, start::MyGraphNodeModel, algorithm::DijkstraAlgorithm) where T <: AbstractGraphModel

    # Dijkstra's greedy finalization requires every edge weight to be nonnegative.
    # Each entry of graph.edges is (source, target) => weight. The pattern ((source, target), _)
    # unpacks the key into source and target and drops the stored value with _ -
    for ((source, target), _) in graph.edges
        weight(graph, source, target) < 0 &&
            throw(ArgumentError("Dijkstra requires nonnegative edge weights")) # if this weight is negative, stop with an error
    end

    # Initialize: dist, prev, and the min-priority queue -
    distances = Dict{Int64, Float64}(); # dist[v]: the best distance to v found so far
    previous = Dict{Int64, Union{Nothing,Int64}}(); # prev[v]: the node before v on that route, or nothing
    queue = PriorityQueue{Int64, Float64}(); # exported from DataStructures.jl; keys are node ids, priorities are distance estimates

    # set distances and previous -
    distances[start.id] = 0.0; # distance from start to start is zero
    for (k, _) ∈ graph.nodes # graph.nodes maps each node id k to its node model; we need only the id, so _ drops the model
        if k != start.id
            distances[k] = Inf;
            previous[k] = nothing;
        end
        enqueue!(queue, k, distances[k]); # add nodes to the queue, with priority distances[k]
    end

    # main loop -
    while !isempty(queue) # process nodes in the queue until it is empty (!isempty(queue) is the same as isempty(queue) == false)

        # step 1, select a vertex: remove the node u with the smallest distance estimate -
        u = dequeue!(queue);
        mychildren = children(graph, graph.nodes[u]);

        # step 2, relax its outgoing edges -
        for w ∈ mychildren # iterate over the children set of the current node
            alt = distances[u] + weight(graph, u, w); # distance to u so far + weight of edge from u to w
            if alt < distances[w] # the route to w through u is cheaper than the best route to w found so far
                distances[w] = alt;
                previous[w] = u;
                queue[w] = alt; # lower the priority of w in the queue to alt
            end
        end
    end

    # return: the dist and prev dictionaries, as a tuple -
    return distances, previous;
end

"""
    _search(graph::T, start::MyGraphNodeModel, algorithm::BellmanFordAlgorithm)
        -> Tuple{Dict{Int64, Float64}, Dict{Int64, Union{Nothing, Int64}}} where T <: AbstractGraphModel

Compute the shortest distance from `start` to every node of `graph` with the Bellman-Ford
algorithm, which allows negative edge weights. `findshortestpath` calls this method when
`algorithm` is a `BellmanFordAlgorithm()`.

The method follows the L4c pseudocode. After the "Initialize" step, we make at most `|V| − 1`
passes over the edges, where `|V|` is the number of nodes. Each pass does three steps:

1. Reset the change flag: `changed ← false`.
2. Relax every edge: for each edge `u → v`, compute `alt = dist[u] + w(u,v)`. If
   `alt < dist[v]`, set `dist[v] = alt`, `prev[v] = u`, and `changed ← true`.
3. Check for convergence: if no distance changed in the pass, stop the passes.

Then we check for a negative-weight cycle: if any edge can still lower a distance, a cycle
whose weights sum to a negative number is reachable from `start`, and no shortest path exists.

The L4c pseudocode skips an edge when `dist[u] = ∞`. This version does not skip it, but such an
edge changes nothing, because `alt = ∞ + w(u,v) = ∞` is never smaller than `dist[v]`. We visit the
edges in the order the `graph.edges` dictionary gives them. That order can change how many
passes we need, and which route we keep when two routes tie, but not the distances.

### Arguments
- `graph::T`: the graph, where `T` is any subtype of `AbstractGraphModel`. Weights may be negative.
- `start::MyGraphNodeModel`: the node to start from.
- `algorithm::BellmanFordAlgorithm`: selects this method; its value is not used.

### Returns
A tuple of two dictionaries, in this order:
- `distances::Dict{Int64, Float64}`: key `v` holds the shortest distance from `start` to node
  `v`; `Inf` when `v` is unreachable.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: key `v` holds the node before `v` on the
  selected shortest route; `nothing` for the start node and for unreachable nodes.

### Throws
- `ArgumentError`: a negative-weight cycle is reachable from `start`.
"""
function _search(graph::T, start::MyGraphNodeModel, algorithm::BellmanFordAlgorithm) where T <: AbstractGraphModel

    # initialize -
    distances = Dict{Int64, Float64}(); # dist[v]: the best distance to v found so far
    previous = Dict{Int64, Union{Nothing,Int64}}(); # prev[v]: the node before v on that route, or nothing
    nodes = graph.nodes;
    number_of_nodes = length(nodes); # |V|, the number of nodes

    # initialize distance and previous dictionaries: dist[v] = ∞ and prev[v] = nothing for every
    # node, then dist[start] = 0. The pattern (_, node) drops the key and keeps the node model -
    for (_, node) ∈ nodes
        distances[node.id] = Inf;
        previous[node.id] = nothing;
    end
    distances[start.id] = 0.0;

    # Relax every edge at most |V|-1 times. Stop when a full pass changes nothing.
    # The loop variable is `_` because we do not need the pass number -
    for _ in 1:(number_of_nodes - 1)

        # step 1, reset the change flag -
        changed = false

        # step 2, relax every edge. k is the key (u, v) of an edge; _ drops its stored weight -
        for (k, _) ∈ graph.edges

            u = k[1]; # the start of the edge
            v = k[2]; # the end of the edge

            alt = distances[u] + weight(graph, u, v); # the cost of reaching v through u
            if alt < distances[v]
                distances[v] = alt;
                previous[v] = u;
                changed = true
            end
        end

        # step 3, check for convergence -
        changed || break # if no distance changed in this pass, leave the loop
    end

    # Reject a reachable negative-weight cycle if one more relaxation is possible.
    for (k, _) ∈ graph.edges

        u = k[1];
        v = k[2];

        if distances[u] + weight(graph, u, v) < distances[v]
            throw(ArgumentError("The graph contains a negative cycle"));
        end
    end

    # return: the dist and prev dictionaries, as a tuple -
    return distances, previous;
end


# --- MAXIMUM FLOW API BELOW HERE --------------------------------------------------------------------- #
#
# The maximum-flow functions work on n × n matrices whose rows and columns are the node ids
# 1, 2, ..., n:
# - C[u,v]: the capacity of the edge u → v, and 0 when there is no such edge.
# - R[u,v]: the residual capacity of the pair u → v, i.e., how much more flow we can send from u
#   to v. On an edge, it is the capacity minus the flow. On the reverse of an edge that carries
#   flow, it is the flow we can cancel. The residual graph has an edge u → v when R[u,v] > 0.
# - F[u,v]: the net flow from u to v. We keep F[v,u] = -F[u,v].
#
# The Ford-Fulkerson method (L5a lecture) starts with zero flow and repeats:
# 1. find an augmenting path, a path from the source s to the sink t in the residual graph;
#    stop when there is none;
# 2. compute the bottleneck capacity Δ, the smallest residual capacity on the path;
# 3. send Δ more units along the path, and update the residual capacities.
# FordFulkersonAlgorithm() finds the path with a depth-first search (_find_path_dfs), and
# EdmondsKarpAlgorithm() with a breadth-first search (_find_path_bfs), which finds a path with
# the fewest edges.

"""
    _find_path_dfs(R::AbstractMatrix{T}, s::Int, t::Int; atol::T = zero(T)) -> Tuple{Bool, Vector{Int}, T} where {T<:Real}

Find an augmenting path from `s` to `t` in the residual graph with a depth-first search, and
compute its bottleneck capacity. The `FordFulkersonAlgorithm()` method of `_flow` calls this
function.

The search may move from `u` to `v` only when the residual capacity `R[u,v]` is larger than
`atol`. We keep the discovered nodes on a stack (last in, first out). Each pass takes the node
discovered most recently, so the search follows one branch deep before it returns to older
nodes. Among the neighbors of a node, the one with the largest id is taken first, because it
was pushed last. When we discover a node `v` from a node `u`, we mark `v` as seen and record
`parent[v] = u`. Following `parent` back from `t` to `s` gives the path. The bottleneck
capacity is the smallest residual capacity on the path, `Δ = min R[u,v]` over its edges `u → v`.

### Arguments
- `R::AbstractMatrix{T}`: the `n × n` residual-capacity matrix; rows and columns are node ids
  `1, …, n`.
- `s::Int`: the source node.
- `t::Int`: the sink node.
- `atol::T = zero(T)`: residual capacities at or below `atol` count as zero (keyword argument).
  It must have the same number type `T` as the entries of `R`.

### Returns
A tuple of three values, in this order:
- `found::Bool`: `true` when the search reached `t`.
- `parent::Vector{Int}`: `parent[v]` is the node from which the search discovered `v`; 0 for
  `s` and for nodes the search did not discover.
- `Δ::T`: the bottleneck capacity of the path; `zero(T)` when no path was found.

### Throws
- `ArgumentError`: `R` is not square.
"""
function _find_path_dfs(R::AbstractMatrix{T}, s::Int, t::Int; atol::T=zero(T)) where {T<:Real}

    # initialize. A semicolon puts two statements on one line. The second statement says:
    # if R does not have as many columns as rows, stop with an error -
    n = size(R,1); size(R,2) == n || throw(ArgumentError("R must be square"))
    parent = fill(0, n) # parent[v]: the node from which we discovered v; 0 means not yet discovered
    seen = falses(n) # seen[v]: true once v has been discovered
    stack = Int[s]; seen[s] = true # the stack starts with the source, which counts as discovered

    # search: take the most recently discovered node off the stack, and discover its neighbors -
    while !isempty(stack)
        u = pop!(stack) # remove the node on top of the stack (the newest one)
        u == t && break # if we took the sink off the stack, stop the search

        # discover every neighbor v of u that is not yet seen and can still take flow from u.
        # @inbounds turns off index checking in the loop, for speed; every index here is in 1..n -
        @inbounds for v in 1:n
            if !seen[v] && R[u,v] > atol # !seen[v] means v is not yet seen
                parent[v] = u
                seen[v] = true
                push!(stack, v)
            end
        end
    end

    # if the search never discovered the sink, there is no augmenting path -
    if !seen[t]
        return false, parent, zero(T)
    end

    # compute the bottleneck capacity: walk back from t to s along parent, and keep the
    # smallest residual capacity. typemax(T) is the largest value of type T (Inf for Float64),
    # so the first edge always replaces it -
    Δ = typemax(T)
    v = t
    while v != s
        u = parent[v] # the node before v on the path
        Δ = min(Δ, R[u,v])
        v = u
    end

    # return: a path was found, the parent links that describe it, and its bottleneck capacity -
    return true, parent, Δ
end

"""
    _find_path_bfs(R::AbstractMatrix{T}, s::Int, t::Int; atol::T = zero(T)) -> Tuple{Bool, Vector{Int}, T} where {T<:Real}

Find an augmenting path from `s` to `t` in the residual graph with a breadth-first search, and
compute its bottleneck capacity. The `EdmondsKarpAlgorithm()` method of `_flow` calls this
function.

This is the path search of the Edmonds-Karp algorithm. The search may move from `u` to `v`
only when the residual capacity `R[u,v]` is larger than `atol`. We keep the discovered nodes
in a first-in-first-out queue, so the search processes the nodes in the order it discovered
them, layer by layer. The path it finds therefore has the fewest edges. When we discover a
node `v` from a node `u`, we mark `v` as seen and record `parent[v] = u`. Following `parent` back
from `t` to `s` gives the path. The bottleneck capacity is the smallest residual capacity on
the path, `Δ = min R[u,v]` over its edges `u → v`.

The queue is a plain vector `q` of length `n` with two positions: `head`, the index of the
front of the queue, and `tail`, the index where the next node goes. Each node enters the queue
at most once, so `n` entries are enough.

### Arguments
- `R::AbstractMatrix{T}`: the `n × n` residual-capacity matrix; rows and columns are node ids
  `1, …, n`.
- `s::Int`: the source node.
- `t::Int`: the sink node.
- `atol::T = zero(T)`: residual capacities at or below `atol` count as zero (keyword argument).
  It must have the same number type `T` as the entries of `R`.

### Returns
A tuple of three values, in this order:
- `found::Bool`: `true` when the search reached `t`.
- `parent::Vector{Int}`: `parent[v]` is the node from which the search discovered `v`; 0 for
  `s` and for nodes the search did not discover.
- `Δ::T`: the bottleneck capacity of the path; `zero(T)` when no path was found.

### Throws
- `ArgumentError`: `R` is not square.
"""
function _find_path_bfs(R::AbstractMatrix{T}, s::Int, t::Int; atol::T=zero(T)) where {T<:Real}

    # initialize. A semicolon puts two statements on one line. The second statement says:
    # if R does not have as many columns as rows, stop with an error -
    n = size(R,1); size(R,2) == n || throw(ArgumentError("R must be square"))
    parent = fill(0, n) # parent[v]: the node from which we discovered v; 0 means not yet discovered
    seen   = falses(n) # seen[v]: true once v has been discovered
    q = Vector{Int}(undef, n); head = 1; tail = 1 # the queue: n slots, not yet filled (undef); head is the front, tail is the next free slot
    q[tail] = s; tail += 1 # add the source at the back of the queue; tail += 1 is short for tail = tail + 1
    seen[s] = true

    # search: take the oldest discovered node from the front of the queue, and discover its neighbors -
    while head < tail # the queue is not empty while head < tail
        u = q[head]; head += 1 # remove the node at the front of the queue
        u == t && break # if we took the sink from the queue, stop the search

        # discover every neighbor v of u that is not yet seen and can still take flow from u.
        # @inbounds turns off index checking in the loop, for speed; every index here is in 1..n -
        @inbounds for v in 1:n
            if !seen[v] && R[u,v] > atol # !seen[v] means v is not yet seen
                parent[v] = u
                seen[v] = true
                q[tail] = v; tail += 1 # add v at the back of the queue
            end
        end
    end

    # if the search never discovered the sink, there is no augmenting path -
    if !seen[t]
        return false, parent, zero(T)
    end

    # compute the bottleneck capacity: walk back from t to s along parent, and keep the
    # smallest residual capacity. typemax(T) is the largest value of type T (Inf for Float64),
    # so the first edge always replaces it -
    Δ = typemax(T)
    v = t
    while v != s
        u = parent[v] # the node before v on the path
        Δ = min(Δ, R[u,v])
        v = u
    end

    # return: a path was found, the parent links that describe it, and its bottleneck capacity -
    return true, parent, Δ
end

"""
    _augment_path!(R::AbstractMatrix{T}, F::AbstractMatrix{T}, parent::Vector{Int},
        s::Int, t::Int, Δ::T) -> Nothing where {T<:Real}

Send `Δ` more units of flow along the augmenting path from `s` to `t`, and update the residual
capacities. Both `_flow` methods call this function after each successful path search.

We walk the path backward from `t` to `s` with the `parent` links. For each path edge `u → v`:
- `R[u,v]` decreases by `Δ`: there is `Δ` less room to send flow from `u` to `v`.
- `R[v,u]` increases by `Δ`: we could later cancel these `Δ` units by sending flow from `v` to `u`.
- `F[u,v]` increases by `Δ` and `F[v,u]` decreases by `Δ`, which keeps `F[v,u] = −F[u,v]`.

When `u → v` is the reverse of an original edge `v → u`, the update lowers the flow on the
original edge `v → u`. This is how a backward residual edge cancels an earlier routing choice.

### Arguments
- `R::AbstractMatrix{T}`: the residual-capacity matrix; changed in place.
- `F::AbstractMatrix{T}`: the net-flow matrix; changed in place.
- `parent::Vector{Int}`: the parent links from `_find_path_dfs` or `_find_path_bfs`.
- `s::Int`: the source node.
- `t::Int`: the sink node.
- `Δ::T`: the amount of flow to send, normally the bottleneck capacity of the path.

### Returns
- `Nothing`. The `!` at the end of the name is the Julia convention for a function that
  changes its arguments; here `R` and `F` change.
"""
function _augment_path!(R::AbstractMatrix{T}, F::AbstractMatrix{T},
                       parent::Vector{Int}, s::Int, t::Int, Δ::T) where {T<:Real}

    # walk the path backward, from the sink to the source -
    v = t
    while v != s
        u = parent[v] # the path edge is u → v

        # update this edge. @inbounds turns off index checking, and begin ... end groups the
        # four lines so @inbounds applies to all of them. a -= b is short for a = a - b -
        @inbounds begin
            R[u,v] -= Δ # less room to send flow from u to v
            R[v,u] += Δ # more flow that we could cancel later by going from v back to u
            F[u,v] += Δ # Δ more net flow from u to v
            F[v,u] -= Δ # keep F[v,u] = -F[u,v]
        end
        v = u # step back one node along the path
    end
    return nothing
end

"""
    _edge_flows(C::AbstractMatrix, F::AbstractMatrix) -> Vector{Tuple}

List the edges of the original network that carry positive flow.

An edge `u → v` is listed when it is an edge of the network, `C[u,v] > 0`, and its net flow is
positive, `F[u,v] > 0`. Pairs with zero capacity, such as the reverse pairs that only the
residual graph uses, are left out.

### Arguments
- `C::AbstractMatrix`: the `n × n` capacity matrix.
- `F::AbstractMatrix`: the `n × n` net-flow matrix.

### Returns
- a vector of tuples `(u, v, F[u,v])`, one per listed edge, sorted by `u` and then by `v`.
"""
function _edge_flows(C::AbstractMatrix, F::AbstractMatrix)
    n = size(C,1) # the number of nodes

    # a comprehension with a filter: for every pair (u, v), keep the tuple (u, v, F[u,v]) only
    # when the `if` test is true, i.e., when u → v is an edge with positive flow -
    flows = [(u, v, F[u,v]) for u in 1:n, v in 1:n if C[u,v] > 0 && F[u,v] > 0]
    sort!(flows)  # optional: sort the tuples by u, then v. The caller, _flow, stores them in a dictionary, which has no order
    return flows
end

"""
    _flow(algorithm::FordFulkersonAlgorithm, C::AbstractMatrix{T}, source::Int64, sink::Int64;
        atol::Float64 = 1e-8) -> Tuple{T, Dict{Tuple{Int64,Int64}, T}} where {T<:Real}

Compute a maximum flow from `source` to `sink` with the Ford-Fulkerson method, finding each
augmenting path with a depth-first search (`_find_path_dfs`). `maximumflow` calls this method
when `algorithm` is a `FordFulkersonAlgorithm()`.

We start with zero flow, so the residual capacities equal the capacities, `R = C`. We then
repeat the L5a steps: find an augmenting path and its bottleneck capacity `Δ`
(`_find_path_dfs`), stop when there is no path, and otherwise send `Δ` more units along the path
(`_augment_path!`) and add `Δ` to the flow value.

### Arguments
- `algorithm::FordFulkersonAlgorithm`: selects this method; its value is not used.
- `C::AbstractMatrix{T}`: the `n × n` capacity matrix; rows and columns are node ids `1, …, n`.
  Its entries must be `Float64`, because the path search requires `atol` and `C` to have the
  same number type.
- `source::Int64`: the source node.
- `sink::Int64`: the sink node.
- `atol::Float64 = 1e-8`: residual capacities at or below `atol` count as zero (keyword argument).

### Returns
A tuple of two values, in this order:
- `maxflow::T`: the maximum flow value, i.e., the total flow from `source` to `sink`.
- `flows::Dict{Tuple{Int64,Int64}, T}`: key `(u, v)` holds the flow on edge `u → v`, for every
  edge with positive flow. An edge missing from the dictionary carries zero flow.
"""
function _flow(algorithm::FordFulkersonAlgorithm, C::AbstractMatrix{T}, source::Int64, sink::Int64;
    atol::Float64=1e-8)::Tuple{T, Dict{Tuple{Int64,Int64}, T}} where {T<:Real}

    # initialize -
    n = size(C,1) # the number of nodes
    R = Matrix{T}(C) # residual capacities: a copy of C, because the flow starts at zero
    F = zeros(T, n, n) # net flows: zero everywhere at the start
    maxflow = zero(T) # the flow value |f|, which starts at zero
    flows = Dict{Tuple{Int64,Int64}, T}();
    s = source;
    t = sink;

    # run the search: one augmenting path per pass, until no path is left -
    while true
        found, parent, Δ = _find_path_dfs(R, s, t; atol=atol) # unpack the three returned values
        found || break # if no augmenting path was found, leave the loop
        _augment_path!(R, F, parent, s, t, Δ) # send Δ more units along the path
        maxflow += Δ # the flow value grows by Δ
    end

    # populate the flows dictionary. Each item of flow_tuple is a tuple (u, v, flow), which
    # the loop unpacks into three variables -
    flow_tuple = _edge_flows(C, F);
    for (u, v, flow) ∈ flow_tuple
        flows[(u, v)] = flow
    end

    # returns a tuple of the maximum flow and the edge flows
    return (maxflow, flows)
end

"""
    _flow(algorithm::EdmondsKarpAlgorithm, C::AbstractMatrix{T}, source::Int64, sink::Int64;
        atol::Float64 = 1e-8) -> Tuple{T, Dict{Tuple{Int64,Int64}, T}} where {T<:Real}

Compute a maximum flow from `source` to `sink` with the Edmonds-Karp algorithm: the
Ford-Fulkerson method with each augmenting path found by a breadth-first search
(`_find_path_bfs`), so each path has the fewest edges. `maximumflow` calls this method when
`algorithm` is an `EdmondsKarpAlgorithm()`.

The steps are the same as in the `FordFulkersonAlgorithm()` method; only the path search differs.

### Arguments
- `algorithm::EdmondsKarpAlgorithm`: selects this method; its value is not used.
- `C::AbstractMatrix{T}`: the `n × n` capacity matrix; rows and columns are node ids `1, …, n`.
  Its entries must be `Float64`, because the path search requires `atol` and `C` to have the
  same number type.
- `source::Int64`: the source node.
- `sink::Int64`: the sink node.
- `atol::Float64 = 1e-8`: residual capacities at or below `atol` count as zero (keyword argument).

### Returns
A tuple of two values, in this order:
- `maxflow::T`: the maximum flow value, i.e., the total flow from `source` to `sink`.
- `flows::Dict{Tuple{Int64,Int64}, T}`: key `(u, v)` holds the flow on edge `u → v`, for every
  edge with positive flow. An edge missing from the dictionary carries zero flow.
"""
function _flow(algorithm::EdmondsKarpAlgorithm, C::AbstractMatrix{T}, source::Int64, sink::Int64;
    atol::Float64=1e-8)::Tuple{T, Dict{Tuple{Int64,Int64}, T}} where {T<:Real}

    # initialize -
    n = size(C,1) # the number of nodes
    R = Matrix{T}(C) # residual capacities: a copy of C, because the flow starts at zero
    F = zeros(T, n, n) # net flows: zero everywhere at the start
    maxflow = zero(T) # the flow value |f|, which starts at zero
    flows = Dict{Tuple{Int64,Int64}, T}();
    s = source;
    t = sink;

    # run the search: one augmenting path per pass, until no path is left -
    while true
        found, parent, Δ = _find_path_bfs(R, s, t; atol=atol) # unpack the three returned values
        found || break # if no augmenting path was found, leave the loop
        _augment_path!(R, F, parent, s, t, Δ) # send Δ more units along the path
        maxflow += Δ # the flow value grows by Δ
    end

    # populate the flows dictionary. Each item of flow_tuple is a tuple (u, v, flow), which
    # the loop unpacks into three variables -
    flow_tuple = _edge_flows(C, F);
    for (u, v, flow) ∈ flow_tuple
        flows[(u, v)] = flow
    end

    # returns a tuple of the maximum flow and the edge flows
    return (maxflow, flows)
end
# --- MAXIMUM FLOW API ABOVE HERE --------------------------------------------------------------------- #

# --- PUBLIC API BELOW HERE --------------------------------------------------------------------------- #

"""
    children(graph::T, node::MyGraphNodeModel) -> Set{Int64} where T <: AbstractGraphModel

Returns the set of child node IDs for a given node in the graph.

A child of `node` is a node that an outgoing edge of `node` points to. We look the set up in
the `children` field of the graph, which `build(...)` filled when it made the graph. The
function returns the set stored in the graph, not a copy, so changing the returned set changes
the graph.

### Arguments
- `graph::T`: The graph to search where `T <: AbstractGraphModel`.
- `node::MyGraphNodeModel`: The node to find children for.

### Returns
- `Set{Int64}`: The set of child node IDs; empty when no edge leaves `node`.

### Throws
- `KeyError`: `node.id` is not a key of `graph.children`.
"""
function children(graph::T, node::MyGraphNodeModel)::Set{Int64} where T <: AbstractGraphModel
    return graph.children[node.id]; # the set of child ids stored under this node's id
end

"""
    weight(graph::T, source::Int64, target::Int64, edgemodels::Dict{Int64, MyGraphEdgeModel}) -> Any where T <: AbstractGraphModel

Returns the weight of the edge between two nodes in the graph, looked up through a dictionary
of edge models.

This method reads the value stored in `graph.edges` for the pair `(source, target)`, treats
that value as an edge id, and returns the `weight` field of the edge model with that id in
`edgemodels`. The graphs that `build(...)` makes store the edge weight itself in `graph.edges`,
not an edge id. For those graphs, this method uses the weight as if it were an id; use the
three-argument `weight(graph, source, target)` instead. No course notebook calls this method.

### Arguments
- `graph::T`: The graph to search where `T <: AbstractGraphModel`.
- `source::Int64`: The ID of the source node.
- `target::Int64`: The ID of the target node.
- `edgemodels::Dict{Int64, MyGraphEdgeModel}`: a dictionary from edge id to edge model.

### Returns
- `Any`: The `weight` field of the edge model, which can be of any type. The method returns
  `nothing` when the graph has no edge from `source` to `target`, or when the value stored for
  that edge is `nothing`.

### Throws
- `KeyError`: the value stored in `graph.edges` is not a key of `edgemodels`.
"""
function weight(graph::T, source::Int64, target::Int64, edgemodels::Dict{Int64, MyGraphEdgeModel})::Any where T <: AbstractGraphModel

    # check that the edge source → target exists; if it does not, return nothing -
    if !haskey(graph.edges, (source, target))
        return nothing # the graph has no edge from source to target
    end

    # read the stored value, and treat it as an edge id -
    edge_id = graph.edges[(source, target)]
    if edge_id === nothing # === tests whether two values are identical; here, whether edge_id is nothing
        return nothing # the edge has no stored value
    end
    return edgemodels[edge_id].weight # the weight field of the edge model with this id
end

"""
    weight(graph::T, source::Int64, target::Int64) -> Float64 where T <: AbstractGraphModel

This function returns the weight of the edge between two nodes in a graph model.

We look up the pair `(source, target)` in the `edges` dictionary of the graph, which stores
the weight of each edge. The shortest-path methods of `findshortestpath` call this function
for every edge they relax.

### Arguments
- `graph::T`: the graph model to search. This is a subtype of `AbstractGraphModel`.
- `source::Int64`: the source node id.
- `target::Int64`: the target node id.

### Returns
- `Float64`: the weight of the edge between the source and target nodes. An integer weight
  is converted to `Float64`.

### Throws
- `KeyError`: the graph has no edge from `source` to `target`.
- `MethodError`: the stored weight is `nothing`, i.e., the edge has no weight.
"""
function weight(graph::T, source::Int64, target::Int64)::Float64 where T <: AbstractGraphModel
    return graph.edges[(source, target)][1]; # graph.edges[(source, target)] is the weight, a number; indexing a number with [1] gives the number itself, so [1] leaves the weight unchanged
end

"""
    walk(graph::T, startnode::MyGraphNodeModel; algorithm::AbstractGraphTraversalAlgorithm = BreadthFirstSearchAlgorithm(),
        verbose::Bool = false) -> Array{Int64,1} where T <: AbstractGraphModel

The `walk` function traverses the graph starting from a given node using the specified algorithm (either Depth-First Search or Breadth-First Search).
It maintains a set of visited nodes to avoid cycles and ensure that each node is processed only once.

Depth-first search (`_DFS`) follows one branch as far as it can before it returns to try the
next branch. Breadth-first search (`_BFS`) visits the nodes in layers: the start node, then
every node one edge away, then every node two edges away, and so on. Both searches read the
children of each node from a `Set`, which has no fixed order, so the order among the children
of one node is not necessarily increasing.

### Arguments
- `graph::T`: The graph to traverse, where `T` is any subtype of `AbstractGraphModel`.
- `startnode::MyGraphNodeModel`: The node to start the traversal from.
- `algorithm::AbstractGraphTraversalAlgorithm = BreadthFirstSearchAlgorithm()`: The algorithm
  to use for the traversal, a keyword argument. Pass `DepthFirstSearchAlgorithm()` or
  `BreadthFirstSearchAlgorithm()`.
- `verbose::Bool = false`: Whether to print each visited node while the search runs (keyword
  argument).

### Returns
- `Array{Int64,1}`: The collection of visited node IDs in the order they were visited. Only
  the nodes reachable from `startnode` appear.

### Throws
- `ErrorException`: `algorithm` is neither a `DepthFirstSearchAlgorithm` nor a
  `BreadthFirstSearchAlgorithm`.
"""
function walk(graph::T, startnode::MyGraphNodeModel;
    algorithm::AbstractGraphTraversalAlgorithm = BreadthFirstSearchAlgorithm(),
    verbose::Bool = false)::Array{Int64,1} where T <: AbstractGraphModel

    # initialize: no node visited yet, and an empty visit order -
    visited = Set{Int64}();
    order = Array{Int64,1}();

    # run the chosen traversal. `x isa T` is true when the value x has type T. Both helpers
    # fill visited and order in place -
    if algorithm isa DepthFirstSearchAlgorithm
        _DFS(graph, startnode, visited, order; verbose=verbose);
    elseif algorithm isa BreadthFirstSearchAlgorithm
        _BFS(graph, startnode, visited, order; verbose=verbose);
    else
        throw(ErrorException("Unsupported graph traversal algorithm"));
    end

    # return the ids of the visited nodes, in visit order -
    return order;
end

"""
    findshortestpath(graph::T, start::MyGraphNodeModel;
        algorithm::AbstractGraphSearchAlgorithm = BellmanFordAlgorithm()) -> Tuple where T <: AbstractGraphModel

The function computes the shortest paths from a starting node to all other nodes in a graph model.

The shortest path to a node `v` is the route from `start` to `v` whose edge weights have the
smallest sum; that sum is the distance to `v`. The function passes the work to a `_search`
method, and Julia picks the method from the type of `algorithm`:

- `DijkstraAlgorithm()`: Dijkstra's algorithm. It needs every edge weight to be ≥ 0.
- `BellmanFordAlgorithm()`: the Bellman-Ford algorithm. It allows negative weights, and it
  stops with an error when a cycle with negative total weight is reachable from `start`.

To recover the route to a node `v`, follow the predecessors back from `v`: `v`, `previous[v]`,
`previous[previous[v]]`, …, until you reach `start`.

### Arguments
- `graph::T`: the graph model to search. This is a subtype of `AbstractGraphModel`.
- `start::MyGraphNodeModel`: the node to start the search from.
- `algorithm::AbstractGraphSearchAlgorithm`: the algorithm to use for the search (keyword
  argument). The default is `BellmanFordAlgorithm()`, but it can also be `DijkstraAlgorithm()`.

### Returns
A tuple of two dictionaries, in this order:
- `distances::Dict{Int64, Float64}`: key `v` holds the distance from `start` to node `v`;
  `Inf` when `v` is unreachable.
- `previous::Dict{Int64, Union{Nothing, Int64}}`: key `v` holds the node before `v` on the
  shortest route; `nothing` when `v` is unreachable. For the start node, Bellman-Ford stores
  `nothing`, and Dijkstra stores no key.

### Errors
- `ArgumentError`: Dijkstra is selected for a graph with a negative edge weight, or Bellman–Ford finds a reachable negative-weight cycle.

### Example
```julia
# directedgraphmodel = build(MySimpleDirectedGraphModel, myedgemodels), as in the L4d lab
(d, p) = findshortestpath(directedgraphmodel, directedgraphmodel.nodes[1];
    algorithm = DijkstraAlgorithm());
```
"""
function findshortestpath(graph::T, start::MyGraphNodeModel;
    algorithm::AbstractGraphSearchAlgorithm = BellmanFordAlgorithm()) where T <: AbstractGraphModel
    return _search(graph, start, algorithm); # Julia runs the _search method that matches the type of algorithm
end

"""
    maximumflow(graph::T, source::MyGraphNodeModel, sink::MyGraphNodeModel;
        algorithm::AbstractGraphFlowAlgorithm = FordFulkersonAlgorithm(), atol::Float64 = 1e-8) -> Tuple where T <: AbstractGraphModel

This function computes the maximum flow in a directed graph from a source node to a sink node using the specified algorithm.
The current implementation does not use the lower bound on the edge capacity (assumes all edges have a lower capacity bound of 0).

We copy the upper flow bound of each edge from `graph.capacity` into an `n × n` capacity
matrix `C`, where `n` is the number of nodes, and pass `C` to a `_flow` method. Julia picks the
method from the type of `algorithm`:

- `FordFulkersonAlgorithm()`: the Ford-Fulkerson method, finding each augmenting path with a
  depth-first search.
- `EdmondsKarpAlgorithm()`: the Edmonds-Karp algorithm, finding each augmenting path with a
  breadth-first search, so each path has the fewest edges.

Both return a maximum flow, but they can split it differently among the edges.

The capacity dictionary keeps the node ids of the edge file, and we use them directly as row
and column numbers of `C`. So the node ids in the edge file must be `1, 2, …, n`.

### Arguments
- `graph::T`: The graph to search. This needs to be a directed graph, with capacities on the
  edges: it must have a `capacity` field, as a `MyDirectedBipartiteGraphModel` does.
- `source::MyGraphNodeModel`: The source node.
- `sink::MyGraphNodeModel`: The sink node.
- `algorithm::AbstractGraphFlowAlgorithm`: The algorithm to use for the search (keyword
  argument). The default is `FordFulkersonAlgorithm()`. The `EdmondsKarpAlgorithm()` can also
  be used.
- `atol::Float64`: The absolute tolerance for floating point comparisons (default is 1e-8):
  residual capacities at or below `atol` count as zero (keyword argument).

### Returns
A tuple of two values, in this order:
- `Float64`: The maximum flow value.
- `Dict{Tuple{Int64,Int64}, Float64}`: A dictionary mapping each edge (as a tuple of source and
  target node IDs) to its flow value. Only edges with positive flow appear; an edge missing
  from the dictionary carries zero flow.

### Throws
- `BoundsError`: a node id in `graph.capacity` is not in `1, 2, …, n`.

### Example
```julia
# directed_graph = build_flow_graph(edge_path; source = 1, sink = 13), as in the L5a worked example
edmonds_value, edmonds_flow = maximumflow(
    directed_graph, directed_graph.nodes[1], directed_graph.nodes[13];
    algorithm = EdmondsKarpAlgorithm(),
);
```
"""
function maximumflow(graph::T, source::MyGraphNodeModel, sink::MyGraphNodeModel;
    algorithm::AbstractGraphFlowAlgorithm = FordFulkersonAlgorithm(), atol::Float64 = 1e-8) where T <: AbstractGraphModel

    # both algorithms work on the capacity matrix C, so before we call the specific algorithm, we need to build that matrix from the graph model -
    n = length(graph.nodes); # the number of nodes, n
    C = zeros(Float64, n, n); # create a capacity matrix: C[u,v] = 0 means no edge from u to v
    for (edge, value) ∈ graph.capacity # edge is the pair (u, v), and value is its bounds (lower, upper)
        C[edge[1], edge[2]] = value[2]; # right now, we are ignoring the lower bound (value[1]) - TODO: fix this later
    end

    # get the ids for the source and sink nodes -
    s = source.id;
    t = sink.id;

    # call the flow calculation: Julia runs the _flow method that matches the type of algorithm -
    return _flow(algorithm, C, s, t; atol=atol);
end

# --- PUBLIC API ABOVE HERE --------------------------------------------------------------------------- #
