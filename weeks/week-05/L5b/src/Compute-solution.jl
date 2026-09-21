module L5bFlowValidation

# The course package supplies the edge-list reader and the graph model. We only
# need these three names from it.
import VLDataScienceMachineLearningPackage: MyConstrainedGraphEdgeModels,
    MyDirectedBipartiteGraphModel, build

# The names the notebook can use after `using .L5bFlowValidation`.
export build_sensitivity_graph, cut_capacity, parse_sensitivity_edge, validate_sensitivity_flow

"""
    parse_sensitivity_edge(record::String, delimiter::Char = ',')

Split one line of the edge-list file into its five numeric fields.

# Arguments
- `record`: One noncomment line of the file, for example `"1,2,0.0,0.0,1.0"`.
- `delimiter`: The character between fields. The lab's file uses a comma.

# Returns
A tuple `(source, target, cost, lower, upper)`. The node identifiers are `Int`;
the cost and the two capacity bounds are `Float64`. Capacities are measured in
assignments in this lab. A line with any number of fields other than five throws
an `ArgumentError`.
"""
function parse_sensitivity_edge(record::String, delimiter::Char = ',')

    # Split the line at each delimiter, then remove surrounding whitespace from each
    # piece. The dot in strip.(...) applies strip to every element of the array -
    fields = strip.(split(record, delimiter))
    if length(fields) != 5
        throw(ArgumentError("expected five edge fields, got $(length(fields))"))
    end

    # Convert each piece of text to a number -
    source = parse(Int, fields[1]);     # node the edge leaves
    target = parse(Int, fields[2]);     # node the edge enters
    cost = parse(Float64, fields[3]);   # cost per unit of flow (unused by maximum flow)
    lower = parse(Float64, fields[4]);  # lower flow bound [assignments]
    upper = parse(Float64, fields[5]);  # upper flow bound, the capacity [assignments]

    return (source, target, cost, lower, upper)
end

"""
    build_sensitivity_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)

Read a worker–task edge list and return a `MyDirectedBipartiteGraphModel`.

# Arguments
- `path`: Path to a comma-separated edge list. Each noncomment record contains
  the source node, target node, cost, lower capacity, and upper capacity.
- `source`, `sink`: Distinct source and sink node identifiers present in the data.
  Use contiguous integer node identifiers starting at one for the course solver.

# Returns and assumptions
The graph stores node models in `nodes` and, in `capacity`, a dictionary from
each directed edge `(u, v)` to its `(lower, upper)` flow bounds. Capacities are
measured in assignments in this lab. The maximum-flow solver ignores the cost
field and requires zero lower flow bounds, finite nonnegative upper bounds, and a
directed network suitable for source-to-sink flow. The supplied edge list satisfies
these assumptions; this builder does not validate every solver assumption.

The input file must exist. Lines beginning with `#` are comments.
"""
function build_sensitivity_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)

    # Check the arguments before doing any work -
    if isfile(path) == false
        throw(ArgumentError("edge-list path does not exist: $(path)"))
    end
    if source isa Bool || sink isa Bool
        throw(ArgumentError("source and sink must be vertex identifiers, not Bool"))
    end

    # Read the file into edge models, one per noncomment line, using our parser -
    edges = MyConstrainedGraphEdgeModels(path, parse_sensitivity_edge; delim = ',', comment = '#')

    # Assemble the graph model from the edges and the chosen source and sink -
    return build(MyDirectedBipartiteGraphModel, (s = Int(source), t = Int(sink), edges = edges))
end

"""
    validate_sensitivity_flow(graph, flow::AbstractDict, source::Integer,
        sink::Integer; atol::Real = 1e-8)

Independently check a candidate flow and recompute its net source outflow.

# Arguments
- `graph`: Directed graph with `nodes` and a `capacity` dictionary whose keys are
  directed edge pairs and whose values are `(lower, upper)` flow bounds.
- `flow`: Dictionary from directed edge pairs to numeric flows. Missing graph
  edges are treated as carrying zero flow; keys absent from the graph invalidate
  the capacity check.
- `source`, `sink`: Distinct source and sink node identifiers present in `graph`.
- `atol`: Nonnegative absolute tolerance in flow units (assignments in this lab).

# Returns
A named tuple with `valid`, `value`, `capacity_ok`, `conservation_ok`, `balance_ok`,
and `residuals`. Each residual is incoming minus outgoing flow at a node. `value`
is the net source outflow, in assignments. `valid` requires the capacity,
intermediate-node conservation, and source–sink balance checks to pass.

# Assumptions and scope
Use zero lower flow bounds and finite numeric capacities and flows. The helper
checks nonnegativity and upper capacities; it does not enforce nonzero lower
bounds. The caller must compare `value` with the solver's reported total. These
checks establish feasibility; a separate cut bound is needed to certify optimality.
"""
function validate_sensitivity_flow(graph, flow::AbstractDict, source::Integer, sink::Integer; atol::Real = 1e-8)

    # Check the arguments before doing any work -
    source_id = Int(source);
    sink_id = Int(sink);
    if source_id == sink_id
        throw(ArgumentError("source and sink must differ"))
    end
    if atol < 0
        throw(ArgumentError("atol must be nonnegative"))
    end

    # Check 1: edge capacities. Every edge's flow must lie between zero and its
    # upper bound, give or take the tolerance atol. An edge missing from the flow
    # dictionary carries zero flow.
    # Looping over a dictionary gives (key, value) pairs: here the key is the edge
    # (u, v) and the value is its (lower, upper) bounds.
    capacity_ok = true
    for (edge, bounds) in graph.capacity
        upper = bounds[2];                  # the capacity of this edge [assignments]
        f = get(flow, edge, 0.0);           # the flow on this edge, zero if absent
        if f < -atol || f > upper + atol
            capacity_ok = false             # this edge is over capacity or negative
        end
    end
    for edge in keys(flow)
        if haskey(graph.capacity, edge) == false
            capacity_ok = false             # the flow names an edge the graph does not have
        end
    end

    # Check 2: net inflow at every node. For each node we add up the flow on the
    # edges that enter it, add up the flow on the edges that leave it, and store
    # the difference (incoming minus outgoing) as that node's residual.
    residuals = Dict{Int64, Float64}()
    for vertex in keys(graph.nodes)
        incoming = 0.0                      # total flow entering this node [assignments]
        outgoing = 0.0                      # total flow leaving this node [assignments]
        for edge in keys(graph.capacity)
            f = get(flow, edge, 0.0);       # the flow on this edge, zero if absent
            if edge[2] == vertex
                incoming += f               # the edge enters this node
            end
            if edge[1] == vertex
                outgoing += f               # the edge leaves this node
            end
        end
        residuals[vertex] = incoming - outgoing
    end

    # The flow value is the net flow leaving the source: outgoing minus incoming,
    # which is the negative of the source's residual.
    value = -residuals[source_id]

    # Check 3: conservation. Every node other than the source and the sink must
    # have zero net inflow (what comes in goes out).
    conservation_ok = true
    for vertex in keys(residuals)
        if vertex == source_id || vertex == sink_id
            continue                        # the ends of the network are exempt
        end
        if abs(residuals[vertex]) > atol
            conservation_ok = false
        end
    end

    # Check 4: balance. The net flow leaving the source must equal the net flow
    # entering the sink, within the tolerance.
    balance_ok = abs(residuals[sink_id] - value) <= atol

    # Package everything the notebook may want to inspect -
    return (
        valid = capacity_ok && conservation_ok && balance_ok,
        value = value,
        capacity_ok = capacity_ok,
        conservation_ok = conservation_ok,
        balance_ok = balance_ok,
        residuals = residuals,
    )
end

"""
    cut_capacity(graph, S)

Sum the upper capacities of the edges directed from the node set `S` to the
remaining nodes, which form the other side `T` of the cut.

# Arguments
- `graph`: Directed graph whose `capacity` dictionary maps directed edge pairs
  `(u, v)` to `(lower, upper)` flow bounds.
- `S`: Collection of node identifiers on the source side of the cut, for example
  `[1]` or `1:8`. For a source–sink cut it contains the source and not the
  sink; this function does not check that.

# Returns and interpretation
The cut capacity ``c(S,T)`` in flow units (assignments in this lab), as a `Float64`
for this lab's data: the sum of the upper bounds on edges whose first endpoint lies in `S` and whose second
endpoint does not. Edges directed from `T` back into `S` do not contribute.
For every source–sink cut, that is, every `S` holding the source and not the
sink, every feasible flow value is at most this number.
"""
function cut_capacity(graph, S)

    # A Set makes "is this node in S?" a fast lookup -
    inside = Set{Int}(S)

    # Walk every edge and add the capacity of each one that leaves S -
    total = 0.0
    for (edge, bounds) in graph.capacity
        u = edge[1];                        # the edge leaves node u ...
        v = edge[2];                        # ... and enters node v
        upper = bounds[2];                  # the capacity of this edge [assignments]
        if (u in inside) && !(v in inside)
            total += upper                  # u is in S and v is in T: this edge crosses the cut
        end
    end

    return total
end

end
