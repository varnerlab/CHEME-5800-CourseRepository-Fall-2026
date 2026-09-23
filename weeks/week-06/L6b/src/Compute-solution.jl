# Reference implementation for L6b. The notebook loads src/Compute.jl, which
# ships the same working code because this meeting is walked through in class.
module L6bOverflow

import JSON
import DataFrames: DataFrame
import VLDataScienceMachineLearningPackage: solve_flux_balance, check_flux_balance

export load_core_model, with_bounds, with_uptake_limit, solve_growth, exchange_table, flux_checks

"""
    load_core_model(path::AbstractString)

Read a BiGG model stored as JSON, such as `e_coli_core.json`, and build its flux
balance data.

Returns a named tuple with:
- `S`: the stoichiometric matrix, one row per metabolite and one column per reaction.
- `reactions`, `names`: reaction identifiers (for example `EX_glc__D_e`) and
  descriptive names, in column order.
- `metabolites`: metabolite identifiers, in row order.
- `lower`, `upper`: flux bounds from the file, in mmol/gDW/h.
- `biomass`: the identifier of the biomass reaction, whose flux is the growth
  rate in 1/h.
- `exchanges`: the identifiers of the exchange reactions (`EX_...`).

BiGG writes an exchange reaction as `A → ∅`, so a negative flux is uptake and a
positive flux is secretion.
"""
function load_core_model(path::AbstractString)
    isfile(path) || throw(ArgumentError("model file does not exist: $(path)"))
    model = JSON.parsefile(path)
    metabolites = [String(m["id"]) for m in model["metabolites"]]
    row = Dict(id => i for (i, id) in enumerate(metabolites))
    reactions = [String(r["id"]) for r in model["reactions"]]
    S = zeros(Float64, length(metabolites), length(reactions))
    for (j, r) in enumerate(model["reactions"]), (id, coefficient) in r["metabolites"]
        S[row[id], j] = Float64(coefficient)
    end
    biomass = only(filter(id -> startswith(id, "BIOMASS"), reactions))
    return (S = S, reactions = reactions, names = [String(r["name"]) for r in model["reactions"]],
        metabolites = metabolites,
        lower = [Float64(r["lower_bound"]) for r in model["reactions"]],
        upper = [Float64(r["upper_bound"]) for r in model["reactions"]],
        biomass = biomass, exchanges = filter(id -> startswith(id, "EX_"), reactions))
end

function _index(model, reaction::AbstractString)
    j = findfirst(==(reaction), model.reactions)
    isnothing(j) && throw(ArgumentError("unknown reaction $(reaction)"))
    return j
end

"""
    with_bounds(model, reaction, lower, upper)

Return a copy of `model` in which `reaction` has flux bounds `lower` and `upper`
(mmol/gDW/h). Setting both to zero removes the reaction, as a gene knockout would.
The input is unchanged.
"""
function with_bounds(model, reaction::AbstractString, lower::Real, upper::Real)
    lower <= upper || throw(ArgumentError("the lower bound must be at most the upper bound"))
    j = _index(model, reaction)
    lo, hi = copy(model.lower), copy(model.upper)
    lo[j], hi[j] = lower, upper
    return (; model..., lower = lo, upper = hi)
end

"""
    with_uptake_limit(model, exchange, limit)

Return a copy of `model` in which the cell can take up at most `limit` (mmol/gDW/h,
nonnegative) through the exchange reaction `exchange`, for example `"EX_o2_e"`.
Because uptake is a negative exchange flux, this sets the lower bound to `-limit`
and keeps the upper bound, so secretion is unchanged. The input is unchanged.
"""
function with_uptake_limit(model, exchange::AbstractString, limit::Real)
    limit >= 0 || throw(ArgumentError("an uptake limit must be nonnegative"))
    j = _index(model, exchange)
    return with_bounds(model, exchange, -limit, model.upper[j])
end

"""
    solve_growth(model)

Maximize the biomass flux, the growth rate in 1/h, subject to the balances and
the model's bounds, using `solve_flux_balance(...)` from the course package.

Returns a named tuple with `status`, `optimal`, `flux` (mmol/gDW/h, in reaction
order), and `growth`. When the solver does not report `OPTIMAL`, `flux` and
`growth` are `nothing`.
"""
function solve_growth(model)
    c = zeros(length(model.reactions))
    c[_index(model, model.biomass)] = 1.0
    result = solve_flux_balance(model.S, model.lower, model.upper, c)
    return (status = result.status, optimal = result.optimal, flux = result.flux,
        growth = result.objective)
end

"""
    exchange_table(model, result; atol = 1e-6)

List the exchange fluxes that are not zero in an optimal `result`, largest
magnitude first. Returns a `DataFrame` with `reaction`, `name`, `flux`
(mmol/gDW/h), and `direction` (`"uptake"` for a negative flux, `"secretion"` for a
positive one).
"""
function exchange_table(model, result; atol::Real = 1e-6)
    result.optimal || throw(ArgumentError("an unsolved model has no fluxes to list"))
    rows = DataFrame(reaction = String[], name = String[], flux = Float64[], direction = String[])
    for id in model.exchanges
        j = _index(model, id)
        v = result.flux[j]
        abs(v) > atol || continue
        push!(rows, (id, model.names[j], v, v < 0 ? "uptake" : "secretion"))
    end
    return sort!(rows, :flux; by = abs, rev = true)
end

"""
    flux_checks(model, result; atol = 1e-6)

Check an optimal `result` independently of the solver with `check_flux_balance(...)`
from the course package: every metabolite balances (`S*v = 0`) and every flux is
within its bounds, to the absolute tolerance `atol` in mmol/gDW/h.
"""
function flux_checks(model, result; atol::Real = 1e-6)
    result.optimal || throw(ArgumentError("an unsolved model has no fluxes to check"))
    return check_flux_balance(model.S, result.flux, model.lower, model.upper; atol = atol)
end

end
