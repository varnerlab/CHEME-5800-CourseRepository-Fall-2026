"""
Abstract base type for all flux calculation models.
Subtypes carry the data required to formulate and solve a flux balance problem.
"""
abstract type AbstractFluxCalculationModel end

"""
    MyPrimalFluxBalanceAnalysisCalculationModel <: AbstractFluxCalculationModel

Data model for the primal flux balance analysis (FBA) problem.
The zero-argument constructor leaves fields uninitialized. Use `build` to attach
all arrays before calling `solve`; the model itself performs no validation.
The solver maximizes `objective' * flux` subject to `S*flux == 0` and the bounds.
Fluxes and bounds use the same rate units (mmol/gDW/h in the urea example).
Positive flux follows the written reaction direction; the objective coefficients
select the desired signed fluxes.

### Fields
- `S::Array{Float64,2}`: stoichiometric matrix (species × reactions).
- `fluxbounds::Array{Float64,2}`: flux bounds array (reactions × 2), where column 1 is the lower bound and column 2 is the upper bound.
- `objective::Array{Float64,1}`: objective function coefficients (length = number of reactions).
- `species::Array{String,1}`: species names/ids ordered to match the rows of `S`.
- `reactions::Array{String,1}`: reaction names/ids ordered to match the columns of `S`.
"""
mutable struct MyPrimalFluxBalanceAnalysisCalculationModel <: AbstractFluxCalculationModel

    # data -
    S::Array{Float64,2}; # stoichiometric matrix
    fluxbounds::Array{Float64,2}; # flux bounds
    objective::Array{Float64,1}; # objective function coefficients
    species::Array{String,1}; # species names/ids
    reactions::Array{String,1}; # reaction names/ids

    # methods -
    MyPrimalFluxBalanceAnalysisCalculationModel() = new();
end