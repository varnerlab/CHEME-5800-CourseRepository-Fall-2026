module Week06Core

import GLPK
import JuMP
import LinearAlgebra: eigvals, norm
import MathOptInterface as MOI

export Reaction, build_stoichiometric_matrix, parse_reaction_file, solve_resource_lp,
    solve_urea_fba, spectral_radius, stationary_solve

struct Reaction
    name::String
    reactants::Dict{String, Float64}
    products::Dict{String, Float64}
    reversible::Bool
end

function _parse_side(text::AbstractString)
    side = strip(text)
    side == "[]" && return Dict{String, Float64}()
    terms = Dict{String, Float64}()
    for token in split(side, '+')
        field = strip(token)
        if occursin('*', field)
            coefficient, species = split(field, '*'; limit = 2)
            terms[strip(species)] = parse(Float64, strip(coefficient))
        else
            terms[field] = 1.0
        end
    end
    return terms
end

function parse_reaction_file(path::AbstractString)::Vector{Reaction}
    isfile(path) || throw(ArgumentError("reaction file does not exist: $(path)"))
    reactions = Reaction[]
    for record in eachline(path)
        line = strip(record)
        (isempty(line) || startswith(line, "//")) && continue
        fields = split(line, ','; limit = 4)
        length(fields) == 4 || throw(ArgumentError("expected four reaction fields: $(record)"))
        reversible = lowercase(strip(fields[4])) == "true" ? true :
            lowercase(strip(fields[4])) == "false" ? false :
            throw(ArgumentError("invalid reversibility flag: $(fields[4])"))
        push!(reactions, Reaction(strip(fields[1]), _parse_side(fields[2]), _parse_side(fields[3]), reversible))
    end
    isempty(reactions) && throw(ArgumentError("reaction file may not be empty"))
    length(unique(reaction.name for reaction in reactions)) == length(reactions) ||
        throw(ArgumentError("reaction names must be unique"))
    return reactions
end

function build_stoichiometric_matrix(reactions::AbstractVector{Reaction})
    species = String[]
    for reaction in reactions
        for name in Iterators.flatten((keys(reaction.reactants), keys(reaction.products)))
            name in species || push!(species, name)
        end
    end
    row = Dict(name => index for (index, name) in enumerate(species))
    S = zeros(Float64, length(species), length(reactions))
    for (column, reaction) in enumerate(reactions)
        for (name, coefficient) in reaction.reactants
            S[row[name], column] -= coefficient
        end
        for (name, coefficient) in reaction.products
            S[row[name], column] += coefficient
        end
    end
    return (S = S, species = species, names = [reaction.name for reaction in reactions])
end

"""Solve a two-product resource LP and return primal decisions and shadow prices."""
function solve_resource_lp(capacities::AbstractVector{<:Real} = [100.0, 90.0])
    length(capacities) == 2 || throw(DimensionMismatch("two resource capacities are required"))
    all(x -> isfinite(x) && x >= 0, capacities) || throw(ArgumentError("capacities must be finite and nonnegative"))
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    x = JuMP.@variable(model, x[1:2] >= 0)
    resource_one = JuMP.@constraint(model, 2x[1] + x[2] <= capacities[1])
    resource_two = JuMP.@constraint(model, x[1] + 3x[2] <= capacities[2])
    JuMP.@objective(model, Max, 3x[1] + 5x[2])
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    status == MOI.OPTIMAL || throw(ErrorException("resource LP did not solve to optimality: $(status)"))
    decisions = JuMP.value.(x)
    # JuMP reports nonpositive duals for a maximization problem with <= constraints.
    # Return positive marginal resource values for the instructional interpretation.
    shadow_prices = -[JuMP.dual(resource_one), JuMP.dual(resource_two)]
    return (decisions = decisions, objective = JuMP.objective_value(model),
        shadow_prices = shadow_prices, status = status)
end

"""Solve the compact urea-cycle FBA model using documented Fall 2025 enzyme bounds."""
function solve_urea_fba(reactions::AbstractVector{Reaction})
    form = build_stoichiometric_matrix(reactions)
    n = length(reactions)
    lower, upper = fill(-10.0, n), fill(10.0, n)
    vmax = Dict("v1" => 0.10, "v2" => 0.0328, "v3" => 1.90, "v4" => 4.10, "v5" => 0.10)
    for (index, reaction) in enumerate(reactions)
        if haskey(vmax, reaction.name)
            lower[index] = 0.0
            upper[index] = vmax[reaction.name]
        end
    end
    urea_exchange = findfirst(==("b4"), form.names)
    isnothing(urea_exchange) && throw(ArgumentError("model requires the b4 urea exchange"))
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    v = JuMP.@variable(model, v[1:n])
    for index in 1:n
        JuMP.set_lower_bound(v[index], lower[index])
        JuMP.set_upper_bound(v[index], upper[index])
    end
    for row in axes(form.S, 1)
        JuMP.@constraint(model, sum(form.S[row, column] * v[column] for column in 1:n) == 0)
    end
    JuMP.@objective(model, Max, -v[urea_exchange])
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    status == MOI.OPTIMAL || throw(ErrorException("FBA problem did not solve to optimality: $(status)"))
    flux = JuMP.value.(v)
    return (flux = flux, objective = JuMP.objective_value(model), residual = form.S * flux,
        names = form.names, species = form.species, S = form.S, lower = lower, upper = upper, status = status)
end

function spectral_radius(matrix::AbstractMatrix{<:Real})::Float64
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch("matrix must be square"))
    return maximum(abs, eigvals(Float64.(matrix)); init = 0.0)
end

"""Run Jacobi, Gauss–Seidel, or SOR and retain residual history."""
function stationary_solve(A::AbstractMatrix{<:Real}, b::AbstractVector{<:Real};
    method::Symbol = :jacobi, omega::Real = 1.0, tolerance::Real = 1e-10,
    max_iterations::Integer = 10_000, initial = zeros(length(b)))
    n, m = size(A)
    n == m == length(b) || throw(DimensionMismatch("A must be square and match b"))
    length(initial) == n || throw(DimensionMismatch("initial guess must match b"))
    method in (:jacobi, :gauss_seidel, :sor) || throw(ArgumentError("unknown stationary method: $(method)"))
    0 < omega < 2 || throw(ArgumentError("omega must lie in (0,2)"))
    tolerance > 0 || throw(ArgumentError("tolerance must be positive"))
    max_iterations > 0 || throw(ArgumentError("max_iterations must be positive"))
    matrix, rhs = Float64.(A), Float64.(b)
    all(index -> matrix[index, index] != 0, 1:n) || throw(ArgumentError("diagonal entries must be nonzero"))
    x = Float64.(initial)
    residuals = Float64[norm(matrix * x - rhs)]
    for iteration in 1:max_iterations
        previous = copy(x)
        if method == :jacobi
            for i in 1:n
                x[i] = (rhs[i] - sum(matrix[i, j] * previous[j] for j in 1:n if j != i)) / matrix[i, i]
            end
        else
            for i in 1:n
                left = sum(matrix[i, j] * x[j] for j in 1:(i - 1); init = 0.0)
                right = sum(matrix[i, j] * previous[j] for j in (i + 1):n; init = 0.0)
                candidate = (rhs[i] - left - right) / matrix[i, i]
                x[i] = method == :sor ? (1 - omega) * previous[i] + omega * candidate : candidate
            end
        end
        push!(residuals, norm(matrix * x - rhs))
        residuals[end] <= tolerance && return (solution = x, residuals = residuals,
            iterations = iteration, converged = true)
    end
    return (solution = x, residuals = residuals, iterations = Int(max_iterations), converged = false)
end

end
