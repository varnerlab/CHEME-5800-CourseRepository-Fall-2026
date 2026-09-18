module L5bFlowValidation

import VLDataScienceMachineLearningPackage: MyConstrainedGraphEdgeModels,
    MyDirectedBipartiteGraphModel, build

export build_sensitivity_graph, parse_sensitivity_edge, validate_sensitivity_flow

function parse_sensitivity_edge(record::String, delimiter::Char = ',')
    fields = strip.(split(record, delimiter))
    length(fields) == 5 || throw(ArgumentError("expected five edge fields"))
    return (
        parse(Int, fields[1]), parse(Int, fields[2]), parse(Float64, fields[3]),
        parse(Float64, fields[4]), parse(Float64, fields[5]),
    )
end

"""
    build_sensitivity_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)

Read a worker–task edge list and return a `MyDirectedBipartiteGraphModel`.

# Arguments
- `path`: Path to a comma-separated edge list. Each noncomment record contains
  source node, target node, cost, lower capacity, and upper capacity.
- `source`, `sink`: Distinct source and sink node identifiers present in the data.
  Use contiguous integer node identifiers starting at one for the course solver.

# Returns and assumptions
The graph stores node models and edge-capacity tuples `(lower, upper)`. Capacities
are measured in assignments in this lab. The maximum-flow solver ignores the cost
field and requires zero lower flow bounds, finite nonnegative upper bounds, and a
directed network suitable for source-to-sink flow. The supplied edge list satisfies
these assumptions; this builder does not validate every solver assumption.

The input file must exist. Lines beginning with `#` are comments.
"""
function build_sensitivity_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)"))
    source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
    sink isa Bool && throw(ArgumentError("sink must be a vertex identifier"))
    edges = MyConstrainedGraphEdgeModels(path, parse_sensitivity_edge; delim = ',', comment = '#')
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
    source_id, sink_id = Int(source), Int(sink)
    source_id == sink_id && throw(ArgumentError("source and sink must differ"))
    atol >= 0 || throw(ArgumentError("atol must be nonnegative"))
    capacity_ok = all(
        get(flow, edge, 0.0) >= -atol && get(flow, edge, 0.0) <= upper + atol
        for (edge, (_, upper)) in graph.capacity
    ) && all(edge -> haskey(graph.capacity, edge), keys(flow))
    residuals = Dict{Int64, Float64}()
    for vertex in keys(graph.nodes)
        incoming = sum((get(flow, edge, 0.0) for edge in keys(graph.capacity) if edge[2] == vertex); init = 0.0)
        outgoing = sum((get(flow, edge, 0.0) for edge in keys(graph.capacity) if edge[1] == vertex); init = 0.0)
        residuals[vertex] = incoming - outgoing
    end
    value = -residuals[source_id]
    conservation_ok = all(
        vertex in (source_id, sink_id) || abs(residuals[vertex]) <= atol
        for vertex in keys(residuals)
    )
    balance_ok = abs(residuals[sink_id] - value) <= atol
    return (
        valid = capacity_ok && conservation_ok && balance_ok,
        value = value,
        capacity_ok = capacity_ok,
        conservation_ok = conservation_ok,
        balance_ok = balance_ok,
        residuals = residuals,
    )
end

end
