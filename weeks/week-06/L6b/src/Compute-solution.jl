# Reference implementation for L6b. The notebook loads src/Compute.jl, which
# ships the same working code because this meeting is walked through in class.
module L6bOverflow

# Packages this file uses. JSON reads the BiGG model file, DataFrame holds the
# exchange table, and the two course-library functions solve and check the
# flux balance linear program -
import JSON
import DataFrames: DataFrame
import VLDataScienceMachineLearningPackage: solve_flux_balance, check_flux_balance

export load_core_model, with_bounds, with_uptake_limit, solve_growth, exchange_table, flux_checks

"""
    load_core_model(path::AbstractString) -> NamedTuple

Read a BiGG model stored as JSON, such as `data/e_coli_core.json`, and build the
data that flux balance analysis needs.

# Arguments
- `path::AbstractString`: path to the JSON model file.

# Returns
A `NamedTuple` with the fields:
- `S::Matrix{Float64}`: the stoichiometric matrix, one row per metabolite and one
  column per reaction, in the order the file lists them.
- `reactions::Vector{String}`: reaction identifiers, for example `"EX_glc__D_e"`,
  in column order.
- `names::Vector{String}`: descriptive reaction names, in column order.
- `metabolites::Vector{String}`: metabolite identifiers, in row order.
- `lower::Vector{Float64}`, `upper::Vector{Float64}`: the flux bounds from the
  file, in mmol/gDW/h, one entry per reaction.
- `biomass::String`: the identifier of the biomass reaction, whose flux is the
  growth rate in 1/h.
- `exchanges::Vector{String}`: the identifiers of the exchange reactions, the
  ones whose identifier starts with `"EX_"`.

BiGG writes an exchange reaction as `A → ∅`, so a negative exchange flux is
uptake and a positive exchange flux is secretion.

# Throws
- `ArgumentError` if the file does not exist or has no `BIOMASS...` reaction.
"""
function load_core_model(path::AbstractString)

    # check: does the file exist? -
    isfile(path) || throw(ArgumentError("model file does not exist: $(path)"))

    # read the JSON file into nested dictionaries and arrays -
    data = JSON.parsefile(path)

    # metabolites are the rows of S. Build the row labels, and a dictionary
    # that maps a metabolite identifier to its row index -
    metabolites = [String(m["id"]) for m ∈ data["metabolites"]]
    row = Dict{String,Int}()
    for (i, id) ∈ enumerate(metabolites)
        row[id] = i
    end

    # reactions are the columns of S. Build the column labels and names -
    reactions = [String(r["id"]) for r ∈ data["reactions"]]
    names = [String(r["name"]) for r ∈ data["reactions"]]

    # build S: start from zeros, then fill in each reaction's coefficients.
    # Each reaction record lists its metabolites as id => coefficient, negative
    # for a reactant and positive for a product -
    S = zeros(Float64, length(metabolites), length(reactions))
    for (j, r) ∈ enumerate(data["reactions"])
        for (id, coefficient) ∈ r["metabolites"]
            S[row[id], j] = Float64(coefficient) # row = metabolite, column = reaction
        end
    end

    # bounds: one lower and one upper bound per reaction, from the file -
    lower = [Float64(r["lower_bound"]) for r ∈ data["reactions"]]
    upper = [Float64(r["upper_bound"]) for r ∈ data["reactions"]]

    # find the biomass reaction (its identifier starts with BIOMASS) -
    k = findfirst(id -> startswith(id, "BIOMASS"), reactions)
    isnothing(k) && throw(ArgumentError("model has no BIOMASS reaction: $(path)"))
    biomass = reactions[k]

    # find the exchange reactions (identifiers start with EX_) -
    exchanges = filter(id -> startswith(id, "EX_"), reactions)

    # return everything as a named tuple -
    return (S = S, reactions = reactions, names = names, metabolites = metabolites,
        lower = lower, upper = upper, biomass = biomass, exchanges = exchanges)
end

"""
    _index(model, reaction::AbstractString) -> Int

Return the column index of `reaction` in `model.reactions`. Internal helper.

# Throws
- `ArgumentError` if `reaction` is not in the model.
"""
function _index(model, reaction::AbstractString)
    j = findfirst(==(reaction), model.reactions) # nothing if not found
    isnothing(j) && throw(ArgumentError("unknown reaction $(reaction)"))
    return j
end

"""
    with_bounds(model, reaction::AbstractString, lower::Real, upper::Real) -> NamedTuple

Return a copy of `model` in which `reaction` has the flux bounds `lower ≤ v ≤ upper`
(mmol/gDW/h). Every other field of the model is shared with the input, and the
input itself is unchanged. Setting both bounds to zero removes the reaction, as
a gene knockout would.

# Arguments
- `model`: a model from [`load_core_model`](@ref).
- `reaction::AbstractString`: a reaction identifier, for example `"ATPM"`.
- `lower::Real`, `upper::Real`: the new bounds, in mmol/gDW/h.

# Throws
- `ArgumentError` if `lower > upper` or `reaction` is not in the model.
"""
function with_bounds(model, reaction::AbstractString, lower::Real, upper::Real)

    # check: the bounds must be ordered -
    lower <= upper || throw(ArgumentError("the lower bound must be at most the upper bound"))

    # which column? -
    j = _index(model, reaction)

    # copy the bound arrays so the input model is not changed, then edit entry j -
    new_lower = copy(model.lower)
    new_upper = copy(model.upper)
    new_lower[j] = lower
    new_upper[j] = upper

    # build the new model: (; model..., ...) copies every field of model, then
    # the two fields named after it replace the old lower and upper -
    return (; model..., lower = new_lower, upper = new_upper)
end

"""
    with_uptake_limit(model, exchange::AbstractString, limit::Real) -> NamedTuple

Return a copy of `model` in which the cell can take up at most `limit` (mmol/gDW/h)
through the exchange reaction `exchange`, for example `"EX_o2_e"`. The input is
unchanged.

Because BiGG writes exchanges as `A → ∅`, uptake is a negative flux, so this sets
the lower bound to `-limit` and keeps the upper bound. Secretion through the same
exchange is therefore unchanged. A `limit` of zero shuts off uptake.

# Throws
- `ArgumentError` if `limit < 0` or `exchange` is not in the model.
"""
function with_uptake_limit(model, exchange::AbstractString, limit::Real)

    # check: a limit is a rate, so it cannot be negative -
    limit >= 0 || throw(ArgumentError("an uptake limit must be nonnegative"))

    # which column? we need it to keep the current upper bound -
    j = _index(model, exchange)

    # uptake is negative, so "at most limit in" means lower bound = -limit -
    return with_bounds(model, exchange, -limit, model.upper[j])
end

"""
    solve_growth(model) -> NamedTuple

Maximize the biomass flux, the growth rate in 1/h, subject to the steady-state
balances `S v = 0` and the model's flux bounds. The linear program is solved by
`solve_flux_balance(...)` from the course package (JuMP with GLPK).

# Returns
A `NamedTuple` with the fields:
- `status`: the solver's termination status, `OPTIMAL` when a solution was found.
- `optimal::Bool`: `true` when `status` is `OPTIMAL`.
- `flux::Vector{Float64}`: the optimal flux of every reaction, in mmol/gDW/h and
  in column order of `model.S` (the biomass flux is in 1/h).
- `growth::Float64`: the optimal biomass flux, the growth rate in 1/h.

When the solver does not report `OPTIMAL`, for example when the bounds make the
problem infeasible, `flux` and `growth` are `nothing`; check `optimal` first.
"""
function solve_growth(model)

    # objective: weight one on the biomass reaction, zero on every other reaction -
    c = zeros(Float64, length(model.reactions))
    c[_index(model, model.biomass)] = 1.0

    # solve: maximize c'v subject to S v = 0 and lower ≤ v ≤ upper -
    result = solve_flux_balance(model.S, model.lower, model.upper, c)

    # repackage: the objective value is the biomass flux, i.e., the growth rate -
    return (status = result.status, optimal = result.optimal, flux = result.flux,
        growth = result.objective)
end

"""
    exchange_table(model, result; atol::Real = 1e-6) -> DataFrame

List the exchange fluxes that are not zero in an optimal `result`, largest
magnitude first.

# Arguments
- `model`: a model from [`load_core_model`](@ref).
- `result`: the output of [`solve_growth`](@ref) for that model.
- `atol::Real`: fluxes with `|v| ≤ atol` (mmol/gDW/h) are treated as zero and left out.

# Returns
A `DataFrame` with one row per nonzero exchange flux and the columns `reaction`
(identifier), `name` (descriptive name), `flux` (mmol/gDW/h, signed), and
`direction` (`"uptake"` for a negative flux, `"secretion"` for a positive one).

# Throws
- `ArgumentError` if `result.optimal` is `false`.
"""
function exchange_table(model, result; atol::Real = 1e-6)

    # check: there are no fluxes to list unless the solve was optimal -
    result.optimal || throw(ArgumentError("an unsolved model has no fluxes to list"))

    # initialize an empty table with typed columns -
    rows = DataFrame(reaction = String[], name = String[], flux = Float64[], direction = String[])

    # main loop: look at each exchange reaction, keep the nonzero ones -
    for id ∈ model.exchanges
        j = _index(model, id)
        v = result.flux[j]
        if abs(v) > atol
            direction = v < 0 ? "uptake" : "secretion" # BiGG sign convention
            push!(rows, (id, model.names[j], v, direction))
        end
    end

    # sort by |flux|, largest first, and return -
    return sort!(rows, :flux; by = abs, rev = true)
end

"""
    flux_checks(model, result; atol::Real = 1e-6) -> NamedTuple

Check an optimal `result` independently of the solver, using
`check_flux_balance(...)` from the course package.

# Arguments
- `model`: a model from [`load_core_model`](@ref).
- `result`: the output of [`solve_growth`](@ref) for that model.
- `atol::Real`: absolute tolerance in mmol/gDW/h for both checks.

# Returns
A `NamedTuple` with the fields `balance_ok` (every entry of `S*flux` is within
`atol` of zero), `bounds_ok` (every flux is within its bounds, to `atol`),
`maximum_residual` (the largest `|S*flux|` entry), and `valid` (both checks pass).

# Throws
- `ArgumentError` if `result.optimal` is `false`.
"""
function flux_checks(model, result; atol::Real = 1e-6)

    # check: there are no fluxes to check unless the solve was optimal -
    result.optimal || throw(ArgumentError("an unsolved model has no fluxes to check"))

    # delegate to the course library: S*v = 0 and lower ≤ v ≤ upper -
    return check_flux_balance(model.S, result.flux, model.lower, model.upper; atol = atol)
end

end # module L6bOverflow
