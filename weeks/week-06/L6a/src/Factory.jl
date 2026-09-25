"""
    build(modeltype::Type{MyPrimalFluxBalanceAnalysisCalculationModel}, data::NamedTuple)

Construct a populated flux balance model. No dimension or bound validation is
performed; callers must supply mutually consistent arrays.

### Arguments
- `modeltype`: `MyPrimalFluxBalanceAnalysisCalculationModel`.
- `data`: named tuple with `S::Matrix{Float64}` (`m × n`),
  `fluxbounds::Matrix{Float64}` (`n × 2`, lower then upper),
  `objective::Vector{Float64}` (length `n`), `species::Vector{String}`
  (length `m`), and `reactions::Vector{String}` (length `n`). Species match
  rows of `S`; reactions match columns, bound rows, and objective entries.
  Flux bounds use a consistent rate basis (mmol/gDW/h in the urea example).

### Returns and mutation
Return a `MyPrimalFluxBalanceAnalysisCalculationModel` whose fields reference
the supplied arrays; they are not copied. Editing an array entry through the
model also changes the original array. Replacing a field attaches a new array.
Missing fields and incompatible field types raise Julia errors during construction.
"""
function build(modeltype::Type{MyPrimalFluxBalanceAnalysisCalculationModel},
    data::NamedTuple)::MyPrimalFluxBalanceAnalysisCalculationModel

    # get data -
    S = data.S;
    fluxbounds = data.fluxbounds;
    objective = data.objective;
    species = data.species;
    reactions = data.reactions;
 
    # build an empty model -
    model = modeltype();
 
    # add data to the model -
    model.S = S;
    model.fluxbounds = fluxbounds;
    model.objective = objective;
    model.species = species;
    model.reactions = reactions;
     
     # return the model -
     return model;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #