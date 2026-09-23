# ------------------------------------------------------------------------------------------------ #
# FluxBalance.jl
#
# Flux balance analysis used by the week-06 L6b lab (E. coli core metabolism): solve the
# flux balance linear program and check a flux vector. L6a carries its own code in
# weeks/week-06/L6a/src.
# ------------------------------------------------------------------------------------------------ #

import GLPK
import JuMP
const _FBA_MOI = JuMP.MOI # JuMP re-exports MathOptInterface, which is not a direct dependency

"""
    solve_flux_balance(S, lower, upper, c)

Solve the flux balance linear program with JuMP and GLPK:

    maximize c'v   subject to   S v = 0,   lower ≤ v ≤ upper.

`S` is the stoichiometric matrix (species by reactions); `lower`, `upper`, and the
objective coefficients `c` have one entry per reaction, in column order. A lower
bound may be `-Inf` and an upper bound `Inf`, for a flux with no limit on that side.

Returns a named tuple `(status, optimal, flux, objective)`. When the solver does not
report `OPTIMAL`, for example `INFEASIBLE`, `flux` and `objective` are `nothing`,
so check `optimal` before reading them.
"""
function solve_flux_balance(S::AbstractMatrix{<:Real}, lower::AbstractVector{<:Real},
        upper::AbstractVector{<:Real}, c::AbstractVector{<:Real})
    n = size(S, 2)
    length(lower) == length(upper) == length(c) == n ||
        throw(DimensionMismatch("lower, upper, and c need one entry per reaction (column of S)"))
    all(lower .<= upper) || throw(ArgumentError("every lower bound must be at most its upper bound"))
    any(==(Inf), lower) && throw(ArgumentError("a lower bound cannot be Inf"))
    any(==(-Inf), upper) && throw(ArgumentError("an upper bound cannot be -Inf"))
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    v = JuMP.@variable(model, v[1:n])
    for j in 1:n
        isfinite(lower[j]) && JuMP.set_lower_bound(v[j], lower[j])
        isfinite(upper[j]) && JuMP.set_upper_bound(v[j], upper[j])
    end
    JuMP.@constraint(model, S * v .== 0)
    JuMP.@objective(model, Max, sum(c[j] * v[j] for j in 1:n))
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    status == _FBA_MOI.OPTIMAL || return (status = status, optimal = false, flux = nothing, objective = nothing)
    return (status = status, optimal = true, flux = JuMP.value.(v), objective = JuMP.objective_value(model))
end

"""
    check_flux_balance(S, flux, lower, upper; atol = 1e-8)

Check a flux vector independently of the solver. Returns a named tuple with
`balance_ok` (every entry of `S*flux` within `atol` of zero), `bounds_ok` (every flux
within its bounds, to `atol`), `maximum_residual` (the largest `|S*flux|` entry), and
`valid` (both checks pass).
"""
function check_flux_balance(S::AbstractMatrix{<:Real}, flux::AbstractVector{<:Real},
        lower::AbstractVector{<:Real}, upper::AbstractVector{<:Real}; atol::Real = 1e-8)
    size(S, 2) == length(flux) == length(lower) == length(upper) ||
        throw(DimensionMismatch("flux and bounds need one entry per reaction (column of S)"))
    maximum_residual = maximum(abs, S * flux; init = 0.0)
    balance_ok = maximum_residual <= atol
    bounds_ok = all(lower[j] - atol <= flux[j] <= upper[j] + atol for j in eachindex(flux))
    return (valid = balance_ok && bounds_ok, balance_ok = balance_ok, bounds_ok = bounds_ok,
        maximum_residual = maximum_residual)
end
