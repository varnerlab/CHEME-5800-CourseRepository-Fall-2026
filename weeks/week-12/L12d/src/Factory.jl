# =============================================================================
# CHEME 5800 | L12d lab: the factory
# =============================================================================
# The build(...) methods. Each one takes a NamedTuple of parameters and returns a
# filled-in model. The grid policy is built by solvegrid(...) in Compute.jl.
#
#   build(MyPatientModel, ...)          the patient model
#   build(MyLinearQNetworkModel, ...)   a linear Q-network with all weights zero
#   build(MyReplayBufferModel, ...)     an empty replay buffer
# =============================================================================

# --- PUBLIC METHODS BELOW HERE --------------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyPatientModel}, data::NamedTuple) -> MyPatientModel

Build the patient model from a `NamedTuple` of parameters.

### Arguments
- `modeltype::Type{MyPatientModel}`: the type to build.
- `data::NamedTuple`: the parameters, with the fields `doses`, `g`, `k`, `b`, `c`, `Bcure`,
  `Zlethal`, `wB`, `wZ`, `wu`, `rcure`, and `rdead`. Each has the meaning given in the docstring
  of `MyPatientModel`.

### Returns
- `MyPatientModel`: the patient model.

### Example
```julia
patient = build(MyPatientModel, (doses = [0.0, 1/3, 2/3, 1.0],
    g = 0.15, k = 0.35, b = 0.50, c = 0.35, Bcure = 0.10, Zlethal = 0.90,
    wB = 1.0, wZ = 1.0, wu = 0.10, rcure = 60.0, rdead = -60.0));
```
"""
function build(modeltype::Type{MyPatientModel}, data::NamedTuple)::MyPatientModel

    # initialize an empty model -
    model = modeltype();

    # copy the actions and the parameters -
    model.doses = data.doses;
    model.g = data.g;
    model.k = data.k;
    model.b = data.b;
    model.c = data.c;
    model.Bcure = data.Bcure;
    model.Zlethal = data.Zlethal;
    model.wB = data.wB;
    model.wZ = data.wZ;
    model.wu = data.wu;
    model.rcure = data.rcure;
    model.rdead = data.rdead;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyLinearQNetworkModel}, data::NamedTuple) -> MyLinearQNetworkModel

Build a linear Q-network whose weights are all zero.

### Arguments
- `modeltype::Type{MyLinearQNetworkModel}`: the type to build.
- `data::NamedTuple`: the fields `nactions` (the number of actions), `m` (the number of
  centers on each axis), and `σ` (the width of every basis function).

### Returns
- `MyLinearQNetworkModel`: the network, with `m^2 + 1` features and a zero weight matrix of size
  `nactions × (m^2 + 1)`.

### Example
```julia
network = build(MyLinearQNetworkModel, (nactions = 4, m = 6, σ = 0.15));
```
"""
function build(modeltype::Type{MyLinearQNetworkModel}, data::NamedTuple)::MyLinearQNetworkModel

    # initialize an empty model -
    network = modeltype();

    # place the centers on an m × m grid over the square -
    m = data.m;
    levels = range(0.0, 1.0, length = m); # m evenly spaced values from 0 to 1
    centers = zeros(m*m, 2);
    j = 1;
    for cB ∈ levels
        for cZ ∈ levels
            centers[j, 1] = cB;
            centers[j, 2] = cZ;
            j = j + 1;
        end
    end
    network.centers = centers;
    network.σ = data.σ;

    # all weights start at zero: one row per action, one column per feature (m^2 basis functions + 1 constant) -
    network.W = zeros(data.nactions, m*m + 1);

    # return -
    return network;
end

"""
    build(modeltype::Type{MyReplayBufferModel}, data::NamedTuple) -> MyReplayBufferModel

Build an empty replay buffer that holds at most `data.capacity` experiences.
"""
function build(modeltype::Type{MyReplayBufferModel}, data::NamedTuple)::MyReplayBufferModel
    buffer = modeltype();
    buffer.memory = Array{MyTransitionModel,1}();
    buffer.capacity = data.capacity;
    buffer.oldest = 1;
    return buffer;
end
# --- PUBLIC METHODS ABOVE HERE --------------------------------------------------------------------------------------- #
