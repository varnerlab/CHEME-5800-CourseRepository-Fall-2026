module L5dMinCostFlow

import GLPK
import JuMP
import LinearAlgebra: dot
import MathOptInterface as MOI

export FlowEdge, block_assignments, flow_formulation, read_flow_edges,
    selected_assignments, solve_min_cost_flow, validate_flow_solution

struct FlowEdge
    source::Int64
    target::Int64
    cost::Float64
    lower::Float64
    upper::Float64

    function FlowEdge(source::Integer, target::Integer, cost::Real, lower::Real, upper::Real)
        source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
        target isa Bool && throw(ArgumentError("target must be a vertex identifier"))
        source == target && throw(ArgumentError("self edges are not supported"))
        all(isfinite, (cost, lower, upper)) || throw(ArgumentError("edge values must be finite"))
        0 <= lower <= upper || throw(ArgumentError("edge bounds must satisfy 0 ≤ lower ≤ upper"))
        return new(Int64(source), Int64(target), Float64(cost), Float64(lower), Float64(upper))
    end
end

function read_flow_edges(path::AbstractString)::Vector{FlowEdge}
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)"))
    edges = FlowEdge[]
    for record in eachline(path)
        line = strip(record)
        (isempty(line) || startswith(line, '#')) && continue
        fields = strip.(split(line, ','))
        length(fields) == 5 || throw(ArgumentError("expected five fields in record: $(record)"))
        push!(edges, FlowEdge(
            parse(Int, fields[1]), parse(Int, fields[2]), parse(Float64, fields[3]),
            parse(Float64, fields[4]), parse(Float64, fields[5]),
        ))
    end
    isempty(edges) && throw(ArgumentError("edge list may not be empty"))
    edge_pairs = [(edge.source, edge.target) for edge in edges]
    length(unique(edge_pairs)) == length(edge_pairs) || throw(ArgumentError("duplicate directed edges are not supported"))
    return edges
end

"""
    flow_formulation(edges::AbstractVector{FlowEdge}, source::Integer,
        sink::Integer, required_flow::Real)

Assemble node-edge incidence data for a minimum-cost flow model using inflow
minus outflow. This function returns model data; it does not solve the model.

# Arguments
- `edges`: Directed `FlowEdge` records. Each record supplies endpoints, cost per
  flow unit, and lower and upper bounds. In this lab, flow is measured in
  assignments and cost is measured in synthetic cost units per assignment.
- `source`, `sink`: Distinct node identifiers present in `edges`.
- `required_flow`: Finite, nonnegative net flow from source to sink, in the same
  units as the edge bounds (assignments in this lab).

# Returns
A named tuple with `A`, `b`, `c`, `lower`, `upper`, and `vertices`:
- `vertices` lists the node identifiers in ascending order; it defines row order.
- `A` has one row per node and one column per supplied edge, in input order.
  A column has -1 at the edge's source, +1 at its target, and zeros elsewhere.
- `b` is `-required_flow` at the source, `required_flow` at the sink, and zero
  at intermediate nodes. Its units are flow units.
- `c` contains costs per flow unit; the notebook denotes this vector by w.
- `lower` and `upper` contain the corresponding edge bounds, in flow units.

# Assumptions and scope
`FlowEdge` records have distinct endpoints, finite costs and bounds, and
`0 <= lower <= upper`. Node identifiers need not be consecutive; interpret rows
using `vertices`. This routine checks that the source and sink are distinct and
present in the network and that the required flow is finite and nonnegative. It does not check
whether the requested flow can be delivered within the supplied edge bounds.
"""
function flow_formulation(edges::AbstractVector{FlowEdge}, source::Integer, sink::Integer, required_flow::Real)
    source_id, sink_id = Int64(source), Int64(sink)
    source_id == sink_id && throw(ArgumentError("source and sink must differ"))
    isfinite(required_flow) && required_flow >= 0 || throw(ArgumentError("required flow must be finite and nonnegative"))
    vertices = sort!(collect(Set(vcat([e.source for e in edges], [e.target for e in edges]))))
    source_id in vertices || throw(ArgumentError("source is not in the graph"))
    sink_id in vertices || throw(ArgumentError("sink is not in the graph"))
    row = Dict(vertex => i for (i, vertex) in enumerate(vertices))
    A = zeros(Float64, length(vertices), length(edges))
    for (j, edge) in enumerate(edges)
        A[row[edge.source], j] = -1.0
        A[row[edge.target], j] = 1.0
    end
    b = zeros(Float64, length(vertices))
    b[row[source_id]] = -Float64(required_flow)
    b[row[sink_id]] = Float64(required_flow)
    return (
        A = A, b = b, c = [e.cost for e in edges],
        lower = [e.lower for e in edges], upper = [e.upper for e in edges],
        vertices = vertices,
    )
end

"""
    solve_min_cost_flow(edges::AbstractVector{FlowEdge}, source::Integer,
        sink::Integer, required_flow::Real)

Solve the continuous minimum-cost flow model with JuMP and GLPK.

# Arguments
- `edges`: Directed edge records with finite costs per flow unit and bounds.
- `source`, `sink`: Distinct node identifiers present in the network.
- `required_flow`: Finite, nonnegative source-to-sink flow in the same units as
  the edge bounds (assignments in this lab).

# Returns and assumptions
Returns `flow` (edge-pair dictionary), `vector` (input edge order), `cost` (the
solver's objective value), `residual` (A*vector - b), `status`, and `formulation`.
Costs are in synthetic cost units in this lab. The input network must have
unique directed edge pairs for the returned dictionary to represent every edge.
Only an `OPTIMAL` termination status produces a result; otherwise an error is
thrown. Independent feasibility and cost checks remain the caller's task.
"""
function solve_min_cost_flow(edges::AbstractVector{FlowEdge}, source::Integer, sink::Integer, required_flow::Real)
    form = flow_formulation(edges, source, sink, required_flow)
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    n = length(edges)
    x = JuMP.@variable(model, [1:n])
    for i in 1:n
        JuMP.set_lower_bound(x[i], form.lower[i])
        JuMP.set_upper_bound(x[i], form.upper[i])
    end
    for row in axes(form.A, 1)
        JuMP.@constraint(model, sum(form.A[row, j] * x[j] for j in 1:n) == form.b[row])
    end
    JuMP.@objective(model, Min, sum(form.c[j] * x[j] for j in 1:n))
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    status == MOI.OPTIMAL || throw(ErrorException("minimum-cost flow did not solve to optimality: $(status)"))
    vector = JuMP.value.(x)
    flow = Dict((edge.source, edge.target) => vector[i] for (i, edge) in enumerate(edges))
    residual = form.A * vector - form.b
    return (
        flow = flow, vector = vector, cost = JuMP.objective_value(model),
        residual = residual, status = status, formulation = form,
    )
end

"""
    validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)

Recompute node balances and total cost from a candidate edge-flow vector.

# Arguments
- `edges`: Original directed edge records in the same order as `result.vector`.
- `result`: A candidate with `vector`, `cost`, and `formulation`. The formulation's
  `vertices` and `b` give the expected node order and net inflows. Preserve those
  model inputs when checking an edited candidate.
- `atol`: Finite, nonnegative absolute tolerance. It is used for flow quantities
  (assignments here) and cost differences (synthetic cost units here). The default
  is appropriate for this lab's small coefficients; relative tolerance is zero.

# Returns and scope
Returns the flags `valid`, `bounds_ok`, `balance_ok`, and `objective_ok`, plus the
freshly computed `residual`, `maximum_balance_residual`, and `recomputed_cost`.
The balances are accumulated directly from the supplied edge endpoints and
candidate vector; the solver's stored residual and incidence matrix are not used.
These checks establish numerical feasibility and objective consistency, not
optimality or integrality. The edge dictionary is not the candidate checked here.
"""
function validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)
    isfinite(atol) && atol >= 0 || throw(ArgumentError("atol must be finite and nonnegative"))
    length(edges) == length(result.vector) || throw(DimensionMismatch("one flow value is required per edge"))
    vertices = result.formulation.vertices
    expected = result.formulation.b
    length(vertices) == length(expected) || throw(DimensionMismatch("one required balance is needed per node"))
    row = Dict(vertex => i for (i, vertex) in enumerate(vertices))
    net_inflow = zeros(Float64, length(vertices))
    for (i, edge) in enumerate(edges)
        net_inflow[row[edge.source]] -= result.vector[i]
        net_inflow[row[edge.target]] += result.vector[i]
    end
    residual = net_inflow - expected
    maximum_balance_residual = maximum(abs, residual; init = 0.0)
    recomputed_cost = dot([e.cost for e in edges], result.vector)
    bounds_ok = all(
        edge.lower - atol <= result.vector[i] <= edge.upper + atol
        for (i, edge) in enumerate(edges)
    )
    balance_ok = maximum_balance_residual <= atol
    objective_ok = isapprox(recomputed_cost, result.cost; atol = atol, rtol = 0.0)
    return (valid = bounds_ok && balance_ok && objective_ok,
        bounds_ok = bounds_ok, balance_ok = balance_ok, objective_ok = objective_ok,
        residual = residual, maximum_balance_residual = maximum_balance_residual,
        recomputed_cost = recomputed_cost)
end

"""
    selected_assignments(result; workers = 2:4, tasks = 5:8, atol::Real = 1e-8)

Extract positive worker-to-task flows from a solved network.

# Arguments and return
- `result`: A solution with a `flow` dictionary indexed by directed edge pairs.
- `workers`, `tasks`: Collections of node identifiers for the two node groups.
- `atol`: Flow threshold, in assignments in this lab; only values above it appear.

Returns named tuples `(worker, task, flow)`, sorted by worker and task identifiers.
Values are not rounded or forced to integers. Checking whether they represent
whole assignments is separate from extracting the positive edges.
"""
function selected_assignments(result; workers = 2:4, tasks = 5:8, atol::Real = 1e-8)
    return sort([
        (worker = edge[1], task = edge[2], flow = value)
        for (edge, value) in result.flow
        if edge[1] in workers && edge[2] in tasks && value > atol
    ]; by = item -> (item.worker, item.task))
end


"""
    block_assignments(edges::AbstractVector{FlowEdge}, pairs)

Return a copy of `edges` in which every `(source, target)` pair listed in
`pairs` has both flow bounds set to zero, making that assignment unavailable.

# Arguments
- `edges`: Directed `FlowEdge` records in the order used by the flow variables.
- `pairs`: A collection of `(source, target)` node-identifier pairs to block.

# Returns and scope
A new vector of `FlowEdge` records in the same order as `edges`; the input is
not modified. A blocked edge keeps its endpoints and cost and receives
`lower = upper = 0.0`, so it stays in the model and in `result.flow` but can
carry no flow. Every pair must name an edge in `edges`; otherwise an
`ArgumentError` is thrown. Blocking does not check whether the required flow
remains feasible; the solver reports that when the model is solved.
"""
function block_assignments(edges::AbstractVector{FlowEdge}, pairs)
    blocked = Set{Tuple{Int64,Int64}}()
    for pair in pairs
        length(pair) == 2 || throw(ArgumentError("each pair must be a (source, target) tuple"))
        push!(blocked, (Int64(pair[1]), Int64(pair[2])))
    end
    present = Set((edge.source, edge.target) for edge in edges)
    for pair in blocked
        pair in present || throw(ArgumentError("edge $(pair) is not in the network"))
    end
    return [
        (edge.source, edge.target) in blocked ?
            FlowEdge(edge.source, edge.target, edge.cost, 0.0, 0.0) : edge
        for edge in edges
    ]
end

end
