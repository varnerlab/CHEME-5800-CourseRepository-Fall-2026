module L5aFlowValidation

import VLDataScienceMachineLearningPackage: MyConstrainedGraphEdgeModels,
    MyDirectedBipartiteGraphModel, build

export build_flow_graph, parse_constrained_edge, validate_flow

"""Parse `source,target,cost,lower,upper` from one edge-list record."""
function parse_constrained_edge(record::String, delimiter::Char = ',')
    fields = strip.(split(record, delimiter))
    length(fields) == 5 || throw(ArgumentError("expected five edge fields"))
    return (
        parse(Int, fields[1]),
        parse(Int, fields[2]),
        parse(Float64, fields[3]),
        parse(Float64, fields[4]),
        parse(Float64, fields[5]),
    )
end

"""Load a constrained edge list and build the course bipartite graph model."""
function build_flow_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)"))
    source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
    sink isa Bool && throw(ArgumentError("sink must be a vertex identifier"))
    edges = MyConstrainedGraphEdgeModels(path, parse_constrained_edge; delim = ',', comment = '#')
    return build(MyDirectedBipartiteGraphModel, (s = Int(source), t = Int(sink), edges = edges))
end

"""Independently check capacity, conservation, and source/sink balance for a flow."""
function validate_flow(graph, flow::AbstractDict, source::Integer, sink::Integer; atol::Real = 1e-8)
    source_id, sink_id = Int(source), Int(sink)
    source_id == sink_id && throw(ArgumentError("source and sink must differ"))
    atol >= 0 || throw(ArgumentError("atol must be nonnegative"))

    capacity_ok = true
    for (edge, (_, upper)) in graph.capacity
        value = get(flow, edge, 0.0)
        capacity_ok &= value >= -atol && value <= upper + atol
    end
    capacity_ok &= all(edge -> haskey(graph.capacity, edge), keys(flow))

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
