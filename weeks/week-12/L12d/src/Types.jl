# =============================================================================
# CHEME 5800 | L12d lab: the types
# =============================================================================
# Every type of the lab, with its abstract parent type. The factory functions in
# Factory.jl fill in the fields.
#
#   MyPatientModel          the patient: the doses and the parameters
#   MyGridPolicyModel       a dosing policy stored as a table on a grid
#   MyLinearQNetworkModel   the linear Q-network: the centers, the width, and the weights
#   MyTransitionModel       one stored experience (φ(s), a, r, φ(s′), done)
#   MyReplayBufferModel     the replay buffer of the most recent experiences
# =============================================================================

abstract type AbstractPatientModel end
abstract type AbstractDosingPolicyModel end
abstract type AbstractTransitionModel end
abstract type AbstractReplayBufferModel end

"""
    mutable struct MyPatientModel <: AbstractPatientModel

The adaptive drug-dosing patient of the L12b lab, without the grid. The patient state is a pair
`(B, Z)` of numbers between 0 and 1, where `B` is the tumor burden and `Z` is the accumulated
toxicity. Each treatment cycle, the agent chooses a dose `u` from `doses`. The tumor then grows
logistically and is killed in proportion to the dose, while the toxicity rises with the dose
and clears by a fixed fraction each cycle.

### Fields
- `doses::Array{Float64,1}`: the dose of each action; action `a` gives the dose `doses[a]`.
- `g::Float64`: the tumor growth rate per cycle.
- `k::Float64`: the fraction of the tumor killed per cycle at full dose.
- `b::Float64`: the toxicity added per cycle at full dose.
- `c::Float64`: the fraction of the toxicity cleared per cycle.
- `Bcure::Float64`: the patient is cured when `B ≤ Bcure` and the patient is alive.
- `Zlethal::Float64`: the patient dies of toxicity when `Z ≥ Zlethal`.
- `wB::Float64`, `wZ::Float64`, `wu::Float64`: the weights of the tumor burden, the toxicity,
  and the dose in the penalty of an ordinary cycle.
- `rcure::Float64`: the reward for a cure.
- `rdead::Float64`: the reward for a toxic death (negative).
"""
mutable struct MyPatientModel <: AbstractPatientModel

    # the actions -
    doses::Array{Float64,1}

    # the dynamics -
    g::Float64
    k::Float64
    b::Float64
    c::Float64

    # the absorbing states -
    Bcure::Float64
    Zlethal::Float64

    # the rewards -
    wB::Float64
    wZ::Float64
    wu::Float64
    rcure::Float64
    rdead::Float64

    # constructor: an empty model; build(...) fills in the fields -
    MyPatientModel() = new();
end

"""
    mutable struct MyGridPolicyModel <: AbstractDosingPolicyModel

A dosing policy stored as a table on a square grid. The grid levels on each axis are
`0, step, 2⋅step, …, 1`, and the policy gives the patient in state `(B, Z)` the action of the
nearest grid point.

### Fields
- `nlevels::Int64`: the number of grid levels on each axis.
- `step::Float64`: the grid spacing, `1/(nlevels - 1)`.
- `π::Array{Int64,2}`: the action at each grid point; `π[iB, iZ]` is the action at the levels
  `B = (iB - 1)⋅step` and `Z = (iZ - 1)⋅step`.
"""
mutable struct MyGridPolicyModel <: AbstractDosingPolicyModel
    nlevels::Int64
    step::Float64
    π::Array{Int64,2}

    # constructor: an empty model; solvegrid(...) fills in the fields -
    MyGridPolicyModel() = new();
end

"""
    mutable struct MyLinearQNetworkModel <: AbstractDosingPolicyModel

A linear Q-network for the patient. The network computes the Q-value of action `a` in the
patient state `s = (B, Z)` as the weighted sum `Q(s, a) = W[a,:]⋅φ(s)`, where `φ(s)` is the
feature vector of the state.

The features are radial basis functions with centers on an `m × m` grid that covers the square
`0 ≤ B ≤ 1`, `0 ≤ Z ≤ 1`. Basis function `j` equals 1 at its center and falls toward 0
with the distance from it. A last feature is the constant 1.

### Fields
- `W::Array{Float64,2}`: the weights, one row per action and one column per feature.
- `centers::Array{Float64,2}`: the centers of the basis functions, one row per basis function; column 1 is `B` and column 2 is `Z`.
- `σ::Float64`: the width of every basis function.
"""
mutable struct MyLinearQNetworkModel <: AbstractDosingPolicyModel
    W::Array{Float64,2}
    centers::Array{Float64,2}
    σ::Float64

    # constructor: an empty model; build(...) fills in the fields -
    MyLinearQNetworkModel() = new();
end

"""
    struct MyTransitionModel <: AbstractTransitionModel

One experience of the agent, stored in the replay buffer.

### Fields
- `φ::Array{Float64,1}`: the features of the state `s`.
- `a::Int64`: the action taken in `s`.
- `r::Float64`: the reward received.
- `φ′::Array{Float64,1}`: the features of the next state `s′`.
- `done::Bool`: `true` if the treatment ended at `s′`.
"""
struct MyTransitionModel <: AbstractTransitionModel
    φ::Array{Float64,1}
    a::Int64
    r::Float64
    φ′::Array{Float64,1}
    done::Bool
end

"""
    mutable struct MyReplayBufferModel <: AbstractReplayBufferModel

The replay buffer: a memory of the most recent experiences. Once the buffer holds `capacity`
experiences, each new experience replaces the oldest one.

### Fields
- `memory::Array{MyTransitionModel,1}`: the stored experiences.
- `capacity::Int64`: the most experiences the buffer holds.
- `oldest::Int64`: the slot of the oldest experience, which the next experience replaces once
  the buffer is full.
"""
mutable struct MyReplayBufferModel <: AbstractReplayBufferModel
    memory::Array{MyTransitionModel,1}
    capacity::Int64
    oldest::Int64

    # constructor: an empty model; build(...) fills in the fields -
    MyReplayBufferModel() = new();
end
