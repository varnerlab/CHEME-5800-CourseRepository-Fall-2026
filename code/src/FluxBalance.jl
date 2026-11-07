# ------------------------------------------------------------------------------------------------ #
# FluxBalance.jl
#
# Flux balance analysis used by the week-06 L6b lab (E. coli core metabolism): solve the
# flux balance linear program and check a flux vector. L6a carries its own code in
# weeks/week-06/L6a/src.
#
# A flux is the rate of one reaction. Flux balance analysis assumes every chemical species in the
# cell is at steady state: the reactions make each species exactly as fast as they use it. Among
# the flux vectors that satisfy this balance and the bounds on each flux, it picks one that
# maximizes an objective, such as the growth rate.
#
# Functions in this file:
#   solve_flux_balance(...)   solve the flux balance linear program with JuMP and GLPK
#   check_flux_balance(...)   check a flux vector against the balances and the bounds, without the solver
# ------------------------------------------------------------------------------------------------ #

import GLPK # the GLPK linear programming solver
import JuMP # JuMP builds optimization models and passes them to a solver
const _FBA_MOI = JuMP.MOI # JuMP re-exports MathOptInterface, which is not a direct dependency

"""
    solve_flux_balance(S::AbstractMatrix{<:Real}, lower::AbstractVector{<:Real},
        upper::AbstractVector{<:Real}, c::AbstractVector{<:Real}) -> NamedTuple

Solve the flux balance linear program with JuMP and the GLPK solver:

    maximize cᵀv   subject to   S⋅v = 0   and   lower ≤ v ≤ upper

Here `v` is the vector of reaction fluxes, one entry per reaction. The constraint `S⋅v = 0` says
that every species is at steady state: the reactions make it exactly as fast as they use it. The
bounds limit each flux. The objective `cᵀv = Σⱼ cⱼ⋅vⱼ` is the quantity we maximize, for example
the flux of the biomass reaction, which is the growth rate.

### Arguments
- `S::AbstractMatrix{<:Real}`: the stoichiometric matrix, one row per species and one column per
  reaction. Entry `S[i,j]` is the amount of species `i` that one unit of flux of reaction `j`
  makes (a positive entry) or uses (a negative entry). `AbstractMatrix{<:Real}` means a matrix of
  any real number type.
- `lower::AbstractVector{<:Real}`: the lower bound of each flux, in the column order of `S`. A
  bound of `-Inf` means the flux has no lower limit. A bound of `Inf` is not allowed.
- `upper::AbstractVector{<:Real}`: the upper bound of each flux, in the column order of `S`. A
  bound of `Inf` means the flux has no upper limit. A bound of `-Inf` is not allowed.
- `c::AbstractVector{<:Real}`: the objective coefficient of each flux, in the column order of `S`.

### Returns
A `NamedTuple` with the fields:
- `status`: the solver's termination status, for example `OPTIMAL` or `INFEASIBLE`.
- `optimal::Bool`: `true` when `status` is `OPTIMAL`.
- `flux::Vector{Float64}`: the optimal flux of each reaction, in the column order of `S`. It is
  `nothing` when `optimal` is `false`.
- `objective::Float64`: the optimal value of `cᵀv`. It is `nothing` when `optimal` is `false`.

When the solver does not report `OPTIMAL`, for example `INFEASIBLE`, `flux` and `objective` are
`nothing`, so check `optimal` before reading them.

### Throws
- `DimensionMismatch` if `lower`, `upper`, and `c` do not each have one entry per column of `S`.
- `ArgumentError` if a lower bound is larger than its upper bound.
- `ArgumentError` if a lower bound is `Inf`, or an upper bound is `-Inf`.

### Example
```julia
S = [1.0 -1.0 0.0; 0.0 1.0 -1.0]; # species A and B; reactions: uptake of A, A -> B, and B out
result = solve_flux_balance(S, [0.0, 0.0, 0.0], [5.0, 3.0, 10.0], [0.0, 0.0, 1.0]);
result.objective # 3.0: the A -> B reaction, capped at 3, limits the flux out
```
"""
function solve_flux_balance(S::AbstractMatrix{<:Real}, lower::AbstractVector{<:Real},
        upper::AbstractVector{<:Real}, c::AbstractVector{<:Real})

    # check the inputs. "condition || throw(...)" means: if the condition is false, stop with an
    # error. "condition && throw(...)" means: if the condition is true, stop with an error -
    n = size(S, 2) # the number of reactions: the number of columns of S
    length(lower) == length(upper) == length(c) == n || # true only when all four numbers are equal
        throw(DimensionMismatch("lower, upper, and c need one entry per reaction (column of S)"))
    all(lower .<= upper) || throw(ArgumentError("every lower bound must be at most its upper bound")) # lower .<= upper compares the bounds entry by entry
    any(==(Inf), lower) && throw(ArgumentError("a lower bound cannot be Inf")) # ==(Inf) is the test "x == Inf"; any(...) is true if some entry passes it
    any(==(-Inf), upper) && throw(ArgumentError("an upper bound cannot be -Inf"))

    # build the model: JuMP with the GLPK solver, and no solver printout -
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)

    # the decision variables: one flux v[j] per reaction, with no bounds yet -
    v = JuMP.@variable(model, v[1:n])

    # set the bounds. An infinite bound means no limit, so we set only the finite ones.
    # "isfinite(...) && JuMP.set_...(...)" runs the set_... call only when the bound is finite -
    for j in 1:n
        isfinite(lower[j]) && JuMP.set_lower_bound(v[j], lower[j])
        isfinite(upper[j]) && JuMP.set_upper_bound(v[j], upper[j])
    end

    # the steady-state balances: S*v is a vector with one entry per species, and .== makes one
    # constraint "entry = 0" for each species -
    JuMP.@constraint(model, S * v .== 0)

    # the objective: maximize cᵀv. The generator inside sum(...) builds the terms c[j]*v[j] for j = 1, …, n -
    JuMP.@objective(model, Max, sum(c[j] * v[j] for j in 1:n))

    # solve -
    JuMP.optimize!(model)
    status = JuMP.termination_status(model) # why the solver stopped, e.g., OPTIMAL or INFEASIBLE

    # if the status is not OPTIMAL, return now, with no flux and no objective value -
    status == _FBA_MOI.OPTIMAL || return (status = status, optimal = false, flux = nothing, objective = nothing)

    # otherwise, return the optimal fluxes and the objective value. JuMP.value.(v) applies JuMP.value to each variable -
    return (status = status, optimal = true, flux = JuMP.value.(v), objective = JuMP.objective_value(model))
end

"""
    check_flux_balance(S::AbstractMatrix{<:Real}, flux::AbstractVector{<:Real},
        lower::AbstractVector{<:Real}, upper::AbstractVector{<:Real}; atol::Real = 1e-8) -> NamedTuple

Check a flux vector independently of the solver: does it balance every species, and does it stay
within its bounds?

We compute the residual `S⋅flux`, which is zero for a flux vector at steady state, and find its
largest entry in absolute value. The balance check passes when that largest residual is at most
`atol`. The bounds check passes when `lower[j] − atol ≤ flux[j] ≤ upper[j] + atol` for every
reaction `j`. The tolerance `atol` allows for the small rounding errors of floating point arithmetic.

### Arguments
- `S::AbstractMatrix{<:Real}`: the stoichiometric matrix, one row per species and one column per reaction.
- `flux::AbstractVector{<:Real}`: the flux of each reaction, in the column order of `S`.
- `lower::AbstractVector{<:Real}`: the lower bound of each flux.
- `upper::AbstractVector{<:Real}`: the upper bound of each flux.
- `atol::Real = 1e-8`: the absolute tolerance of both checks, in the units of the fluxes.

### Returns
A `NamedTuple` with the fields:
- `valid::Bool`: `true` when both checks pass.
- `balance_ok::Bool`: `true` when every entry of `S⋅flux` is within `atol` of zero.
- `bounds_ok::Bool`: `true` when every flux is within its bounds, to `atol`.
- `maximum_residual`: the largest absolute entry of `S⋅flux`, or `0.0` when `S` has no rows.

### Throws
- `DimensionMismatch` if `flux`, `lower`, and `upper` do not each have one entry per column of `S`.
"""
function check_flux_balance(S::AbstractMatrix{<:Real}, flux::AbstractVector{<:Real},
        lower::AbstractVector{<:Real}, upper::AbstractVector{<:Real}; atol::Real = 1e-8)

    # check the sizes: if the four numbers are not all equal, stop with an error -
    size(S, 2) == length(flux) == length(lower) == length(upper) ||
        throw(DimensionMismatch("flux and bounds need one entry per reaction (column of S)"))

    # the balance check: the largest absolute entry of S*flux. maximum(abs, x) applies abs to
    # each entry of x and returns the largest; init = 0.0 is the answer when x is empty -
    maximum_residual = maximum(abs, S * flux; init = 0.0)
    balance_ok = maximum_residual <= atol

    # the bounds check: the generator inside all(...) tests lower[j] - atol <= flux[j] <= upper[j] + atol
    # for every reaction j, and all(...) is true only if every test passes -
    bounds_ok = all(lower[j] - atol <= flux[j] <= upper[j] + atol for j in eachindex(flux))

    # return the overall verdict, the two checks, and the largest residual -
    return (valid = balance_ok && bounds_ok, balance_ok = balance_ok, bounds_ok = bounds_ok,
        maximum_residual = maximum_residual)
end
