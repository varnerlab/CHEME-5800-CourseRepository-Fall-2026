# ------------------------------------------------------------------------------------------------ #
# FlowValidation.jl
#
# Maximum-flow graph construction and independent flow validation used by the week-05 L5a lecture.
#
# The L5a worked example (worker-task assignments) reads a capacity network from an edge-list
# file with build_flow_graph, computes a maximum flow with maximumflow (in Graphs.jl), and then
# checks the returned edge flows with validate_flow. The L5b lab builds and checks its networks
# with its own versions of these functions, in the lab's src/Compute.jl.
#
# A flow assigns an amount f(u,v) to each edge u → v of a network. It is feasible when
# - every edge flow lies between zero and the edge capacity, 0 ≤ f(u,v) ≤ c(u,v), and
# - every vertex other than the source s and the sink t conserves flow: inflow = outflow.
# The flow value |f| is the net flow leaving the source: the flow out of s minus the flow into s.
#
# Public functions:
#
#   parse_constrained_edge(record)       splits one "source,target,cost,lower,upper" line into five numbers
#   build_flow_graph(path; source, sink) reads an edge-list file and builds the course flow-network model
#   validate_flow(graph, flow, s, t)     checks capacities, conservation, and source/sink balance of a flow
# ------------------------------------------------------------------------------------------------ #

# `MyConstrainedGraphEdgeModels`, `MyDirectedBipartiteGraphModel` and `build` are defined
# in Types.jl and Factory.jl, which this module's parent includes ahead of this file.

"""
    parse_constrained_edge(record::String, delimiter::Char = ',') -> Tuple{Int, Int, Float64, Float64, Float64}

Parse `source,target,cost,lower,upper` from one edge-list record.

One data line of an L5a edge-list file describes one directed edge with five fields: the
source vertex id, the target vertex id, the edge cost, the lower flow bound, and the upper flow
bound (the capacity). `build_flow_graph` passes this function to the file reader
`MyConstrainedGraphEdgeModels`, which calls it once per data line as `parse_constrained_edge(line, delimiter)`.

### Arguments
- `record::String`: one data line of the file, e.g., `"1,2,1,0,1"`.
- `delimiter::Char = ','`: the character that separates the fields (a positional argument
  with a default, not a keyword).

### Returns
- `Tuple{Int, Int, Float64, Float64, Float64}`: the five fields, in file order:
  `(source, target, cost, lower, upper)`.

### Throws
- `ArgumentError`: the line does not have exactly five fields, or a field is not a valid number.

### Example
```julia
parse_constrained_edge("1,2,0,0,1")   # (1, 2, 0.0, 0.0, 1.0)
```
"""
function parse_constrained_edge(record::String, delimiter::Char = ',')

    # split the line at each delimiter, and remove the spaces around each piece. The dot in
    # strip.(...) applies strip to every piece; this is called broadcasting -
    fields = strip.(split(record, delimiter))
    length(fields) == 5 || throw(ArgumentError("expected five edge fields")) # if the line does not have five fields, stop with an error

    # convert each text field to a number, and return the five numbers as a tuple -
    return (
        parse(Int, fields[1]), # source vertex id
        parse(Int, fields[2]), # target vertex id
        parse(Float64, fields[3]), # cost of the edge
        parse(Float64, fields[4]), # lower flow bound
        parse(Float64, fields[5]), # upper flow bound: the capacity
    )
end

"""
    build_flow_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13) -> MyDirectedBipartiteGraphModel

Load a constrained edge list and build the course bipartite graph model.

We read the edge-list file with `MyConstrainedGraphEdgeModels`, which skips every line that
is empty or contains `#`, and parses each other line with `parse_constrained_edge`. We then
build a `MyDirectedBipartiteGraphModel` with `build(...)`, which records the source, the sink,
and the `(lower, upper)` flow bounds of each edge in its `capacity` field. The defaults
`source = 1` and `sink = 13` match the L5a worker-task network.

### Arguments
- `path::AbstractString`: the path to the edge-list file. Each data line holds
  `source,target,cost,lower,upper`.
- `source::Integer = 1`: the id of the source vertex (keyword argument).
- `sink::Integer = 13`: the id of the sink vertex (keyword argument).

### Returns
- `MyDirectedBipartiteGraphModel`: the flow network. Its `nodes` field maps each vertex id to a
  node model, and its `capacity` field maps each edge `(u, v)` to its bounds `(lower, upper)`.

### Throws
- `ArgumentError`: the file does not exist, or `source` or `sink` is a `Bool`. A data line that
  `parse_constrained_edge` cannot read also raises an `ArgumentError`.

### Example
```julia
graph = build_flow_graph(joinpath(CHEME5800_L5A_DATA, "Workers-Tasks-Bipartite.edgelist");
    source = 1, sink = 13);
length(graph.nodes)   # 13
```
"""
function build_flow_graph(path::AbstractString; source::Integer = 1, sink::Integer = 13)

    # check the inputs. Julia counts true and false as integers, so we reject them by name -
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)")) # if the file does not exist, stop with an error
    source isa Bool && throw(ArgumentError("source must be a vertex identifier")) # if source is true or false, stop with an error
    sink isa Bool && throw(ArgumentError("sink must be a vertex identifier")) # if sink is true or false, stop with an error

    # read the file: one edge model per data line. We pass the function parse_constrained_edge
    # itself (not a call to it), and the reader calls it on each line -
    edges = MyConstrainedGraphEdgeModels(path, parse_constrained_edge; delim = ',', comment = '#')

    # build and return the flow-network model from the source, the sink, and the edges -
    return build(MyDirectedBipartiteGraphModel, (s = Int(source), t = Int(sink), edges = edges))
end

"""
    validate_flow(graph, flow::AbstractDict, source::Integer, sink::Integer; atol::Real = 1e-8) -> NamedTuple

Independently check capacity, conservation, and source/sink balance for a flow.

We do not trust the flow value that a maximum-flow algorithm reports. Instead we recompute
everything from the edge flows, as in the L5a lecture:

1. Edge capacities: every edge flow satisfies `0 ≤ f(u,v) ≤ c(u,v)`, and every edge in `flow`
   is an edge of the graph. An edge missing from `flow` carries zero flow.
2. Conservation: at every vertex other than the source and the sink, inflow equals outflow.
3. Source-sink balance: the net flow into the sink equals the net flow out of the source.

For each vertex `v` we compute the residual `inflow(v) − outflow(v)`. The flow value is
`|f| = −residual(s)`, the net flow leaving the source. Every comparison allows an error of
`atol`, to absorb floating-point rounding. The lower flow bounds stored in the graph are not
used: the capacity check always uses zero as the lower bound.

### Arguments
- `graph`: the flow network, e.g., from `build_flow_graph`. It must have a `capacity` field,
  a dictionary from each edge `(u, v)` to its bounds `(lower, upper)`, and a `nodes` field, a
  dictionary keyed by vertex id.
- `flow::AbstractDict`: the edge flows, a dictionary from `(u, v)` to `f(u,v)`, e.g., the
  second value returned by `maximumflow`.
- `source::Integer`: the id of the source vertex `s`.
- `sink::Integer`: the id of the sink vertex `t`; it must differ from `s`.
- `atol::Real = 1e-8`: the absolute tolerance for every comparison, in flow units; `atol ≥ 0`
  (keyword argument).

### Returns
A `NamedTuple` with the fields:
- `valid::Bool`: `true` when all three checks pass.
- `value::Float64`: the flow value `|f|`, recomputed from the edge flows.
- `capacity_ok::Bool`: the result of check 1.
- `conservation_ok::Bool`: the result of check 2.
- `balance_ok::Bool`: the result of check 3.
- `residuals::Dict{Int64, Float64}`: key `v` holds `inflow(v) − outflow(v)`.

### Throws
- `ArgumentError`: `source` equals `sink`, or `atol` is negative.
- `KeyError`: `source` or `sink` is not a vertex of the graph.

### Example
```julia
value, flow = maximumflow(graph, graph.nodes[1], graph.nodes[13]; algorithm = EdmondsKarpAlgorithm());
report = validate_flow(graph, flow, 1, 13);
report.valid   # true
report.value   # 3.0 for the L5a worker-task network
```
"""
function validate_flow(graph, flow::AbstractDict, source::Integer, sink::Integer; atol::Real = 1e-8)

    # check the inputs. The first line assigns two variables at once -
    source_id, sink_id = Int(source), Int(sink)
    source_id == sink_id && throw(ArgumentError("source and sink must differ")) # if the source equals the sink, stop with an error
    atol >= 0 || throw(ArgumentError("atol must be nonnegative")) # if atol is negative, stop with an error

    # check 1, edge capacities: 0 ≤ f(u,v) ≤ upper for every edge of the graph.
    # The loop unpacks each entry of graph.capacity: edge is the pair (u, v), and the bounds
    # (lower, upper) are unpacked into (_, upper); `_` drops the lower bound, which we do not use -
    capacity_ok = true
    for (edge, (_, upper)) in graph.capacity
        value = get(flow, edge, 0.0) # the flow on this edge, or 0.0 when the edge is not in the flow dictionary
        capacity_ok &= value >= -atol && value <= upper + atol # a &= b is short for a = a & b: capacity_ok stays true only while every edge passes
    end

    # every edge that carries flow must be an edge of the graph. all(f, xs) is true when
    # f(x) is true for every x; here f is the anonymous function edge -> haskey(graph.capacity, edge) -
    capacity_ok &= all(edge -> haskey(graph.capacity, edge), keys(flow))

    # compute the residual inflow(v) - outflow(v) at every vertex -
    residuals = Dict{Int64, Float64}()
    for vertex in keys(graph.nodes)

        # sum(... for edge in ... if ...) adds up one term per edge that passes the `if` test.
        # incoming: the flows on the edges that end at vertex. init = 0.0 makes an empty sum 0.0 -
        incoming = sum((get(flow, edge, 0.0) for edge in keys(graph.capacity) if edge[2] == vertex); init = 0.0)

        # outgoing: the flows on the edges that start at vertex -
        outgoing = sum((get(flow, edge, 0.0) for edge in keys(graph.capacity) if edge[1] == vertex); init = 0.0)

        residuals[vertex] = incoming - outgoing
    end

    # the flow value |f|: the net flow leaving the source, i.e., minus its residual -
    value = -residuals[source_id]

    # check 2, conservation: every vertex is the source or the sink, or has a residual of zero
    # (within atol). The generator gives one true/false per vertex, and all(...) is true when
    # every one is true. The || skips the residual test for the source and the sink -
    conservation_ok = all(
        vertex in (source_id, sink_id) || abs(residuals[vertex]) <= atol
        for vertex in keys(residuals)
    )

    # check 3, source-sink balance: the net flow into the sink equals the flow value -
    balance_ok = abs(residuals[sink_id] - value) <= atol

    # return the three checks, their combination, the flow value, and the residuals -
    return (
        valid = capacity_ok && conservation_ok && balance_ok, # true only when all three checks pass
        value = value,
        capacity_ok = capacity_ok,
        conservation_ok = conservation_ok,
        balance_ok = balance_ok,
        residuals = residuals,
    )
end
