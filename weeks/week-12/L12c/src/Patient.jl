# =============================================================================
# CHEME 5800 | L12c example: the patient without a grid
# =============================================================================
# This file holds the patient of the L12b lab, with one change: the tumor burden
# B and the toxicity Z are any numbers between 0 and 1, not grid levels.
#
#   MyPatientModel        the patient model: the doses and the parameters
#   build(...)            builds a MyPatientModel from a NamedTuple of parameters
#   isdead(...)           has the toxicity reached the lethal level?
#   iscured(...)          is the tumor small enough, with the patient alive?
#   isterminal(...)       has the treatment ended (cured or toxic death)?
#   treat(...)            one treatment cycle: the next state, the reward, and done
#   MyGridPolicyModel     a dosing policy stored as a table on a grid
#   solvegrid(...)        value iteration on a grid, for a reference policy
#   simulate(...)         roll a policy out from a starting state
#
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12cPatient

import VLDataScienceMachineLearningPackage: build # we add a method for the patient model to build

export MyPatientModel, isdead, iscured, isterminal, treat
export MyGridPolicyModel, solvegrid, gridaction, simulate

"""
    mutable struct MyPatientModel

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
- `Bcure::Float64`: the patient is cured when `B ≤ Bcure`.
- `Zlethal::Float64`: the patient dies of toxicity when `Z ≥ Zlethal`.
- `wB::Float64`, `wZ::Float64`, `wu::Float64`: the weights of the tumor burden, the toxicity,
  and the dose in the penalty of an ordinary cycle.
- `rcure::Float64`: the reward for a cure.
- `rdead::Float64`: the reward for a toxic death (negative).
"""
mutable struct MyPatientModel

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
    isdead(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the toxicity `Z` has reached the lethal level, `Z ≥ Zlethal`.
"""
function isdead(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    return Z ≥ model.Zlethal;
end

"""
    iscured(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the patient state `(B, Z)` is a cure: the tumor burden is at most `Bcure` and
the patient is alive. A state that meets both thresholds counts as a toxic death, not a cure.
"""
function iscured(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    if (isdead(model, B, Z) == true)
        return false; # a toxic death is never a cure
    end
    return B ≤ model.Bcure;
end

"""
    isterminal(model::MyPatientModel, B::Float64, Z::Float64) -> Bool

Return `true` if the treatment has ended: the patient is cured or has died of toxicity.
"""
function isterminal(model::MyPatientModel, B::Float64, Z::Float64)::Bool
    if (isdead(model, B, Z) == true)
        return true;
    end
    if (iscured(model, B, Z) == true)
        return true;
    end
    return false;
end

"""
    treat(model::MyPatientModel, B::Float64, Z::Float64, a::Int64) -> Tuple{Float64,Float64,Float64,Bool}

Simulate one treatment cycle from the patient state `(B, Z)` with the action `a`. Return the
next state `(B′, Z′)`, the reward `r`, and `done`, which is `true` if the treatment has ended.

The dose is `u = doses[a]`. The tumor burden and the toxicity change by

    B′ = B + g⋅B⋅(1 - B) - k⋅u⋅B     (logistic growth, minus the dose-dependent kill)
    Z′ = Z + b⋅u - c⋅Z               (toxicity loading, minus first-order clearance)

each clipped to lie between 0 and 1. These are the L12b equations, but the next state is not
rounded to a grid. The reward is `rdead` for a toxic death, `rcure` for a cure, and otherwise
the penalty `-(wB⋅B′ + wZ⋅Z′ + wu⋅u)` of the tumor, the toxicity, and the dose after the cycle.
"""
function treat(model::MyPatientModel, B::Float64, Z::Float64, a::Int64)::Tuple{Float64,Float64,Float64,Bool}

    # the dose of action a -
    u = model.doses[a];

    # one cycle of the dynamics, clipped to [0, 1] -
    B′ = B + model.g*B*(1 - B) - model.k*u*B;
    Z′ = Z + model.b*u - model.c*Z;
    B′ = min(max(B′, 0.0), 1.0); # min(max(x, 0), 1) keeps x between 0 and 1
    Z′ = min(max(Z′, 0.0), 1.0);

    # the reward, and whether the treatment has ended -
    if (isdead(model, B′, Z′) == true)
        return (B′, Z′, model.rdead, true); # toxic death
    end
    if (iscured(model, B′, Z′) == true)
        return (B′, Z′, model.rcure, true); # cure
    end
    r = -(model.wB*B′ + model.wZ*Z′ + model.wu*u); # the penalty of an ordinary cycle
    return (B′, Z′, r, false);
end

"""
    mutable struct MyGridPolicyModel

A dosing policy stored as a table on a square grid. The grid levels on each axis are
`0, step, 2⋅step, …, 1`, and the policy gives the patient in state `(B, Z)` the action of the
nearest grid point.

### Fields
- `nlevels::Int64`: the number of grid levels on each axis.
- `step::Float64`: the grid spacing, `1/(nlevels - 1)`.
- `π::Array{Int64,2}`: the action at each grid point; `π[iB, iZ]` is the action at the levels
  `B = (iB - 1)⋅step` and `Z = (iZ - 1)⋅step`.
"""
mutable struct MyGridPolicyModel
    nlevels::Int64
    step::Float64
    π::Array{Int64,2}

    # constructor: an empty model; solvegrid(...) fills in the fields -
    MyGridPolicyModel() = new();
end

"""
    snap(nlevels::Int64, x::Float64) -> Int64

Return the index of the grid level nearest the value `x`, on a grid of `nlevels` levels from 0 to 1.
The rounding is the same as in L12b, so a 41-level grid gives the L12b states.
"""
function snap(nlevels::Int64, x::Float64)::Int64

    # the nearest grid index -
    step = 1.0/(nlevels - 1);
    i = round(Int64, x/step) + 1;

    # keep the index on the grid -
    if (i < 1)
        i = 1;
    elseif (i > nlevels)
        i = nlevels;
    end

    # return -
    return i;
end

"""
    solvegrid(model::MyPatientModel; nlevels::Int64 = 201, γ::Float64 = 0.95,
        tolerance::Float64 = 1e-8, k_max::Int64 = 20000) -> MyGridPolicyModel

Compute an optimal dosing policy by value iteration on a grid of `nlevels` levels per axis. This
is the L12b method: each cycle starts from a grid point, and the next state is rounded to the
nearest grid point. With `nlevels = 41`, it is the L12b grid. A finer grid gives a policy closer
to the best policy for the patient without a grid, at the price of a larger table.

### Arguments
- `model::MyPatientModel`: the patient model.
- `nlevels::Int64 = 201`: the number of grid levels on each axis.
- `γ::Float64 = 0.95`: the discount factor, `0 ≤ γ < 1`.
- `tolerance::Float64 = 1e-8`: stop when the largest change in a sweep is at most this.
- `k_max::Int64 = 20000`: the maximum number of sweeps.

### Returns
- `MyGridPolicyModel`: the optimal policy on the grid. A grid point where the treatment has
  ended gets action 1.
"""
function solvegrid(model::MyPatientModel; nlevels::Int64 = 201, γ::Float64 = 0.95,
    tolerance::Float64 = 1e-8, k_max::Int64 = 20000)::MyGridPolicyModel

    # initialize -
    number_of_actions = length(model.doses);
    step = 1.0/(nlevels - 1);

    # tabulate the next grid point, the reward, and the end flag of every grid point and action -
    next_iB = Array{Int64,3}(undef, nlevels, nlevels, number_of_actions);
    next_iZ = Array{Int64,3}(undef, nlevels, nlevels, number_of_actions);
    reward = zeros(nlevels, nlevels, number_of_actions);
    terminal = falses(nlevels, nlevels);
    for iB ∈ 1:nlevels
        for iZ ∈ 1:nlevels
            B = (iB - 1)*step;
            Z = (iZ - 1)*step;
            terminal[iB, iZ] = isterminal(model, B, Z);
            for a ∈ 1:number_of_actions
                (B′, Z′, _, _) = treat(model, B, Z, a); # the _ discards the reward and the end flag; the grid decides both below
                next_iB[iB, iZ, a] = snap(nlevels, B′);
                next_iZ[iB, iZ, a] = snap(nlevels, Z′);

                # the grid decides the outcome at the rounded state, as in L12b -
                jB = next_iB[iB, iZ, a];
                jZ = next_iZ[iB, iZ, a];
                B_grid = (jB - 1)*step;
                Z_grid = (jZ - 1)*step;
                u = model.doses[a];
                if (isdead(model, B_grid, Z_grid) == true)
                    reward[iB, iZ, a] = model.rdead;
                elseif (iscured(model, B_grid, Z_grid) == true)
                    reward[iB, iZ, a] = model.rcure;
                else
                    reward[iB, iZ, a] = -(model.wB*B_grid + model.wZ*Z_grid + model.wu*u);
                end
            end
        end
    end

    # value iteration: sweep the Bellman backup until the values stop changing -
    U = zeros(nlevels, nlevels); # the values before this sweep
    U_new = zeros(nlevels, nlevels); # the values after this sweep
    converged = false; # set to true when a sweep changes no value by more than tolerance
    for k ∈ 1:k_max

        # one sweep over the grid points -
        for iB ∈ 1:nlevels
            for iZ ∈ 1:nlevels
                if (terminal[iB, iZ] == true)
                    U_new[iB, iZ] = 0.0; # the treatment has ended: nothing more to earn
                else
                    best = -Inf;
                    for a ∈ 1:number_of_actions
                        value = reward[iB, iZ, a] + γ*U[next_iB[iB, iZ, a], next_iZ[iB, iZ, a]];
                        if (value > best)
                            best = value;
                        end
                    end
                    U_new[iB, iZ] = best;
                end
            end
        end

        # the largest change in this sweep, then copy the new values into U -
        Δ = maximum(abs.(U_new .- U));
        U .= U_new;
        if (Δ ≤ tolerance)
            converged = true;
            break;
        end
    end

    # warn if we ran out of sweeps before the values settled -
    if (converged == false)
        @warn "Value iteration used all k_max = $(k_max) sweeps before the largest change fell to the tolerance. Try a larger k_max."
    end

    # the greedy action at each grid point; the first best action wins a tie -
    π = ones(Int64, nlevels, nlevels);
    for iB ∈ 1:nlevels
        for iZ ∈ 1:nlevels
            if (terminal[iB, iZ] == false)
                best = -Inf;
                for a ∈ 1:number_of_actions
                    value = reward[iB, iZ, a] + γ*U[next_iB[iB, iZ, a], next_iZ[iB, iZ, a]];
                    if (value > best)
                        best = value;
                        π[iB, iZ] = a;
                    end
                end
            end
        end
    end

    # package the policy -
    policy = MyGridPolicyModel();
    policy.nlevels = nlevels;
    policy.step = step;
    policy.π = π;

    # return -
    return policy;
end

"""
    gridaction(policy::MyGridPolicyModel, B::Float64, Z::Float64) -> Int64

Return the action that the grid policy gives the patient state `(B, Z)`: the action stored at
the nearest grid point.
"""
function gridaction(policy::MyGridPolicyModel, B::Float64, Z::Float64)::Int64
    iB = snap(policy.nlevels, B);
    iZ = snap(policy.nlevels, Z);
    return policy.π[iB, iZ];
end

"""
    simulate(model::MyPatientModel, policy::MyGridPolicyModel; B₀::Float64 = 0.9,
        Z₀::Float64 = 0.0, maxcycles::Int64 = 100, γ::Float64 = 0.95) -> NamedTuple

Follow a grid policy on the patient without a grid, from the starting state `(B₀, Z₀)`, until
the patient is cured, dies of toxicity, or `maxcycles` cycles have passed. Each cycle, the
policy gives the action of the grid point nearest the patient state.

### Returns
A `NamedTuple` with the fields:
- `B::Array{Float64,1}`: the tumor burden at the start of each cycle, and at the end.
- `Z::Array{Float64,1}`: the toxicity at the same times.
- `dose::Array{Float64,1}`: the dose given in each cycle.
- `outcome::Symbol`: `:cured`, `:dead`, or `:timeout` (the treatment has not ended after
  `maxcycles` cycles).
- `cycles::Int64`: the number of cycles in which a dose was given.
- `G::Float64`: the discounted return, `r₁ + γ⋅r₂ + γ²⋅r₃ + …`.
"""
function simulate(model::MyPatientModel, policy::MyGridPolicyModel; B₀::Float64 = 0.9,
    Z₀::Float64 = 0.0, maxcycles::Int64 = 100, γ::Float64 = 0.95)::NamedTuple

    # initialize -
    B_values = [B₀];
    Z_values = [Z₀];
    doses = Array{Float64,1}();
    B = B₀;
    Z = Z₀;
    G = 0.0; # the discounted return
    discount = 1.0; # γ to the power of the number of cycles so far

    # main loop: one treatment cycle per pass -
    for t ∈ 1:maxcycles

        # give the dose the policy chooses -
        a = gridaction(policy, B, Z);
        push!(doses, model.doses[a]);
        (B, Z, r, done) = treat(model, B, Z, a);
        push!(B_values, B);
        push!(Z_values, Z);
        G = G + discount*r;
        discount = discount*γ;

        # has the treatment ended? -
        if (done == true)
            outcome = :dead;
            if (iscured(model, B, Z) == true)
                outcome = :cured;
            end
            return (B = B_values, Z = Z_values, dose = doses, outcome = outcome, cycles = t, G = G);
        end
    end

    # the treatment has not ended after maxcycles cycles -
    return (B = B_values, Z = Z_values, dose = doses, outcome = :timeout, cycles = maxcycles, G = G);
end

end # module L12cPatient
