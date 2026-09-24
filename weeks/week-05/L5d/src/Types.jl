"""
    FlowEdge(source::Integer, target::Integer, cost::Real, lower::Real, upper::Real)

Store a directed edge and its linear-program data. `source` and `target` are
distinct integer node identifiers. `cost` is the cost per unit of flow, while
`lower` and `upper` are the required minimum and allowed maximum flows.

For the teaching network, flow is measured in assignments and cost in survey-score
points per assignment. All three edge values must be finite, with
`0 <= lower <= upper`; a negative cost is allowed for an assignment bonus.
"""
struct FlowEdge
    source::Int64 # node from which flow leaves; the -1 entry in its incidence column
    target::Int64 # node that receives flow; the +1 entry in its incidence column
    cost::Float64 # w_j: score points per assignment in the teaching model
    lower::Float64 # ℓ_j: minimum flow on this edge
    upper::Float64 # c_j: maximum flow on this edge

    function FlowEdge(
        source::Integer,
        target::Integer,
        cost::Real,
        lower::Real,
        upper::Real,
    )

        # Bool is an Integer in Julia, but true and false are not node identifiers here.
        if source isa Bool || target isa Bool
            throw(ArgumentError("source and target must be vertex identifiers"))
        end

        if source == target
            throw(ArgumentError("self edges are not supported"))
        end

        # Require finite costs and a valid interval for flow; negative costs are allowed -
        if !all(isfinite, (cost, lower, upper))
            throw(ArgumentError("edge values must be finite"))
        end

        if !(0 <= lower <= upper)
            throw(ArgumentError("edge bounds must satisfy 0 ≤ lower ≤ upper"))
        end

        # Use consistent numeric types when assembling arrays for the solver -
        return new(Int64(source), Int64(target), Float64(cost), Float64(lower), Float64(upper))
    end
end
