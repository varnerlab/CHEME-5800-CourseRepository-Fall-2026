# ------------------------------------------------------------------------------------------------ #
# LinearPrograms.jl
#
# Fruit-allocation linear program used by the week-05 L5c lecture.
# ------------------------------------------------------------------------------------------------ #

import GLPK
import JuMP
import LinearAlgebra: dot
const MOI = JuMP.MOI   # JuMP re-exports MathOptInterface, which is not a direct dependency


"""Solve the two-or-more-good budget allocation LP with nonnegative quantities."""
function solve_fruit_problem(
    utilities::AbstractVector{<:Real},
    prices::AbstractVector{<:Real},
    budget::Real,
)
    length(utilities) == length(prices) || throw(DimensionMismatch("utilities and prices must have equal length"))
    isempty(utilities) && throw(ArgumentError("at least one good is required"))
    all(isfinite, utilities) || throw(ArgumentError("utilities must be finite"))
    all(isfinite, prices) || throw(ArgumentError("prices must be finite"))
    all(>=(0), utilities) || throw(ArgumentError("utilities must be nonnegative"))
    all(>(0), prices) || throw(ArgumentError("prices must be positive"))
    isfinite(budget) && budget >= 0 || throw(ArgumentError("budget must be finite and nonnegative"))

    u, p, available = Float64.(utilities), Float64.(prices), Float64(budget)
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    n = length(u)
    x = JuMP.@variable(model, x[1:n] >= 0)
    JuMP.@constraint(model, sum(p[i] * x[i] for i in 1:n) <= available)
    JuMP.@objective(model, Max, sum(u[i] * x[i] for i in 1:n))
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    status == MOI.OPTIMAL || throw(ErrorException("fruit LP did not solve to optimality: $(status)"))
    quantities = JuMP.value.(x)
    return (
        quantities = quantities,
        utility = JuMP.objective_value(model),
        expenditure = dot(p, quantities),
        status = status,
        utility_per_dollar = u ./ p,
    )
end
