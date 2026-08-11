module L5dMinCostFlow

import GLPK
import JuMP
import LinearAlgebra: dot
import MathOptInterface as MOI

export FlowEdge, flow_formulation, read_flow_edges, selected_assignments,
    solve_min_cost_flow, validate_flow_solution

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

"""Build the node-edge incidence form `A*x = b` using inflow minus outflow."""
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
        flow = flow, vector = vector, cost = dot(form.c, vector),
        residual = residual, status = status, formulation = form,
    )
end

function validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)
    length(edges) == length(result.vector) || throw(DimensionMismatch("one flow value is required per edge"))
    bounds_ok = all(
        edge.lower - atol <= result.vector[i] <= edge.upper + atol
        for (i, edge) in enumerate(edges)
    )
    balance_ok = maximum(abs, result.residual; init = 0.0) <= atol
    objective_ok = isapprox(dot([e.cost for e in edges], result.vector), result.cost; atol = atol)
    return (valid = bounds_ok && balance_ok && objective_ok,
        bounds_ok = bounds_ok, balance_ok = balance_ok, objective_ok = objective_ok)
end

function selected_assignments(result; workers = 2:4, tasks = 5:8, atol::Real = 1e-8)
    return sort([
        (worker = edge[1], task = edge[2], flow = value)
        for (edge, value) in result.flow
        if edge[1] in workers && edge[2] in tasks && value > atol
    ]; by = item -> (item.worker, item.task))
end

end
