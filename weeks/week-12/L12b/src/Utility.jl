# =============================================================================
# CHEME 5800 | L12b supplied helpers: the adaptive dosing model
# =============================================================================
# This file holds everything the lab uses besides your Q-learning:
#
#   MyAdaptiveDosingModel   the patient model: the state grid, the doses, and the parameters
#   build(...)              builds a MyAdaptiveDosingModel from a NamedTuple of parameters
#   stateindex(...)         the grid state nearest a patient state (B, Z)
#   decode(...)             the patient state (B, Z) of a grid state
#   isterminal(...)         is a state absorbing (cured or toxic death)?
#   world(...)              one treatment cycle: the next state and the reward
#   solve(...)              value iteration: the optimal action values, from the known dynamics
#   simulate(...)           roll a dosing policy out from a starting state
#   mdpworld(...)           one step of a small problem whose moves are certain, for the check cell
#
# These functions are complete; your work for this meeting is in Compute.jl.
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12bUtility

import VLDataScienceMachineLearningPackage: build, solve # we add methods for the dosing model to these two functions
using VLDataScienceMachineLearningPackage: MyMDPProblemModel # the type of the small problem in the check cell

export MyAdaptiveDosingModel, stateindex, decode, isterminal, world, simulate, mdpworld

"""
    mutable struct MyAdaptiveDosingModel

The adaptive drug-dosing environment. The patient state is a point `(B, Z)` on a square grid,
where `B` is the tumor burden and `Z` is the accumulated toxicity, both scaled to lie between 0
and 1. Each treatment cycle, the agent chooses a dose `u` from `doses`. The tumor then grows
logistically and is killed in proportion to the dose, while the toxicity rises with the dose
and clears by a fixed fraction each cycle.

### Fields
- `nlevels::Int64`: the number of grid levels on each axis; `B` and `Z` each take the values
  `0, step, 2⋅step, …, 1`.
- `step::Float64`: the grid spacing, `1/(nlevels - 1)`.
- `coordinates::Dict{Int64,Tuple{Int64,Int64}}`: maps a state index `s` to its grid indices `(iB, iZ)`.
- `states::Dict{Tuple{Int64,Int64},Int64}`: maps grid indices `(iB, iZ)` to the state index `s`.
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
mutable struct MyAdaptiveDosingModel

    # the state grid -
    nlevels::Int64
    step::Float64
    coordinates::Dict{Int64,Tuple{Int64,Int64}}
    states::Dict{Tuple{Int64,Int64},Int64}

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
    MyAdaptiveDosingModel() = new();
end

"""
    build(modeltype::Type{MyAdaptiveDosingModel}, data::NamedTuple) -> MyAdaptiveDosingModel

Build an adaptive dosing environment from a `NamedTuple` of parameters, including the maps
between state indices and grid indices.

### Arguments
- `modeltype::Type{MyAdaptiveDosingModel}`: the type to build.
- `data::NamedTuple`: the parameters, with the fields `nlevels`, `doses`, `g`, `k`, `b`, `c`,
  `Bcure`, `Zlethal`, `wB`, `wZ`, `wu`, `rcure`, and `rdead`. Each has the meaning given in
  the docstring of `MyAdaptiveDosingModel`.

### Returns
- `MyAdaptiveDosingModel`: the environment. Its states are numbered `1, 2, …, nlevels^2`, and
  state `s` sits at the grid indices `coordinates[s]`.

### Example
```julia
env = build(MyAdaptiveDosingModel, (nlevels = 41, doses = [0.0, 1/3, 2/3, 1.0],
    g = 0.15, k = 0.35, b = 0.50, c = 0.35, Bcure = 0.10, Zlethal = 0.90,
    wB = 1.0, wZ = 1.0, wu = 0.10, rcure = 60.0, rdead = -60.0));
```
"""
function build(modeltype::Type{MyAdaptiveDosingModel}, data::NamedTuple)::MyAdaptiveDosingModel

    # initialize an empty model -
    model = modeltype();

    # the grid spacing: the levels are 0, step, 2⋅step, ..., 1 -
    nlevels = data.nlevels;
    model.nlevels = nlevels;
    model.step = 1.0/(nlevels - 1);

    # number the grid points: state s sits at the grid indices (iB, iZ) -
    coordinates = Dict{Int64,Tuple{Int64,Int64}}();
    states = Dict{Tuple{Int64,Int64},Int64}();
    s = 1;
    for iB ∈ 1:nlevels
        for iZ ∈ 1:nlevels
            coordinates[s] = (iB, iZ);
            states[(iB, iZ)] = s;
            s = s + 1;
        end
    end
    model.coordinates = coordinates;
    model.states = states;

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
    level(model::MyAdaptiveDosingModel, i::Int64) -> Float64

Return the value, between 0 and 1, of grid index `i` on either axis: `(i - 1)⋅step`.
"""
function level(model::MyAdaptiveDosingModel, i::Int64)::Float64
    return (i - 1)*model.step;
end

"""
    snap(model::MyAdaptiveDosingModel, x::Float64) -> Int64

Return the grid index nearest the value `x`. A value below 0 or above 1 snaps to the first or
the last grid index.
"""
function snap(model::MyAdaptiveDosingModel, x::Float64)::Int64

    # the nearest grid index -
    i = round(Int64, x/model.step) + 1;

    # keep the index on the grid -
    if (i < 1)
        i = 1;
    elseif (i > model.nlevels)
        i = model.nlevels;
    end

    # return -
    return i;
end

"""
    stateindex(model::MyAdaptiveDosingModel, B::Float64, Z::Float64) -> Int64

Return the index of the grid state nearest the patient state `(B, Z)`, where `B` is the tumor
burden and `Z` is the toxicity.

### Example
```julia
s₀ = stateindex(env, 0.90, 0.0); # a large tumor and no toxicity
```
"""
function stateindex(model::MyAdaptiveDosingModel, B::Float64, Z::Float64)::Int64
    iB = snap(model, B); # the nearest tumor-burden level
    iZ = snap(model, Z); # the nearest toxicity level
    return model.states[(iB, iZ)];
end

"""
    decode(model::MyAdaptiveDosingModel, s::Int64) -> Tuple{Float64,Float64}

Return the patient state `(B, Z)` of the grid state `s`: the tumor burden and the toxicity.
"""
function decode(model::MyAdaptiveDosingModel, s::Int64)::Tuple{Float64,Float64}
    (iB, iZ) = model.coordinates[s];
    return (level(model, iB), level(model, iZ));
end

"""
    isdead(model::MyAdaptiveDosingModel, s::Int64) -> Bool

Return `true` if the toxicity of state `s` has reached the lethal level, `Z ≥ Zlethal`.
"""
function isdead(model::MyAdaptiveDosingModel, s::Int64)::Bool
    (iB, iZ) = model.coordinates[s]; # the grid indices of state s
    Z = level(model, iZ); # the toxicity
    return Z ≥ model.Zlethal;
end

"""
    iscured(model::MyAdaptiveDosingModel, s::Int64) -> Bool

Return `true` if state `s` is a cure: the tumor burden is at most `Bcure` and the patient is
alive. A state that meets both thresholds counts as a toxic death, not a cure.
"""
function iscured(model::MyAdaptiveDosingModel, s::Int64)::Bool
    (iB, iZ) = model.coordinates[s]; # the grid indices of state s
    B = level(model, iB); # the tumor burden
    if (isdead(model, s) == true)
        return false; # a toxic death is never a cure
    end
    return B ≤ model.Bcure;
end

"""
    isterminal(model::MyAdaptiveDosingModel, s::Int64) -> Bool

Return `true` if state `s` is absorbing: the patient is cured or has died of toxicity. Once the
patient enters an absorbing state, the treatment ends.
"""
function isterminal(model::MyAdaptiveDosingModel, s::Int64)::Bool
    if (isdead(model, s) == true)
        return true;
    end
    if (iscured(model, s) == true)
        return true;
    end
    return false;
end

"""
    world(model::MyAdaptiveDosingModel, s::Int64, a::Int64) -> Tuple{Int64,Float64}

Simulate one treatment cycle. Given the current state `s` and the action `a`, return the next
state `s′` and the reward `r`.

The dose is `u = doses[a]`. The tumor burden and the toxicity change by

    B′ = B + g⋅B⋅(1 - B) - k⋅u⋅B     (logistic growth, minus the dose-dependent kill)
    Z′ = Z + b⋅u - c⋅Z               (toxicity loading, minus first-order clearance)

each clipped to lie between 0 and 1, and the next state is the grid state nearest `(B′, Z′)`.
The reward is `rdead` if `s′` is a toxic death, `rcure` if `s′` is a cure, and otherwise the
penalty `-(wB⋅B′ + wZ⋅Z′ + wu⋅u)` of the tumor, the toxicity, and the dose after the cycle.
An absorbing state returns `(s, 0.0)`: the treatment has ended.
"""
function world(model::MyAdaptiveDosingModel, s::Int64, a::Int64)::Tuple{Int64,Float64}

    # an absorbing state: the treatment has ended -
    if (isterminal(model, s) == true)
        return (s, 0.0);
    end

    # the current patient state and the dose -
    (B, Z) = decode(model, s);
    u = model.doses[a];

    # one cycle of the dynamics, clipped to [0, 1] -
    B_next = B + model.g*B*(1 - B) - model.k*u*B;
    Z_next = Z + model.b*u - model.c*Z;
    B_next = min(max(B_next, 0.0), 1.0); # min(max(x, 0), 1) keeps x between 0 and 1
    Z_next = min(max(Z_next, 0.0), 1.0);

    # the nearest grid state -
    s′ = stateindex(model, B_next, Z_next);

    # the reward -
    r = 0.0;
    if (isdead(model, s′) == true)
        r = model.rdead; # toxic death
    elseif (iscured(model, s′) == true)
        r = model.rcure; # cure
    else
        (B′, Z′) = decode(model, s′); # the grid values of the next state
        r = -(model.wB*B′ + model.wZ*Z′ + model.wu*u); # the penalty of an ordinary cycle
    end

    # return -
    return (s′, r);
end

"""
    solve(model::MyAdaptiveDosingModel; γ::Float64 = 0.95, tolerance::Float64 = 1e-8,
        k_max::Int64 = 20000) -> Array{Float64,2}

Compute the optimal action-value table `Q⋆` by value iteration, using the known dynamics in
`world(...)`. This is the model-based answer that we compare Q-learning against.

Each action has a single next state here, so the Bellman backup of state `s` is
`U(s) = max over a of (r(s,a) + γ⋅U(s′(s,a)))`. The function first tabulates `s′(s,a)` and
`r(s,a)` with `world(...)`, then sweeps the backup over every state until no value changes by
more than `tolerance`, or for `k_max` sweeps. Absorbing states keep the value zero.

### Arguments
- `model::MyAdaptiveDosingModel`: the environment.
- `γ::Float64 = 0.95`: the discount factor, `0 ≤ γ < 1`.
- `tolerance::Float64 = 1e-8`: stop when the largest change in a sweep is at most this.
- `k_max::Int64 = 20000`: the maximum number of sweeps.

### Returns
- `Array{Float64,2}`: the optimal action-value table, one row per state and one column per
  action; `Q⋆[s,a] = r(s,a) + γ⋅U⋆(s′(s,a))`, and the rows of absorbing states are zero. The
  optimal policy is `policy(Q⋆)`.
"""
function solve(model::MyAdaptiveDosingModel; γ::Float64 = 0.95, tolerance::Float64 = 1e-8,
    k_max::Int64 = 20000)::Array{Float64,2}

    # initialize -
    number_of_states = model.nlevels^2;
    number_of_actions = length(model.doses);

    # tabulate the next state and the reward of every state-action pair -
    next_state = Array{Int64,2}(undef, number_of_states, number_of_actions);
    reward = Array{Float64,2}(undef, number_of_states, number_of_actions);
    terminal = Array{Bool,1}(undef, number_of_states);
    for s ∈ 1:number_of_states
        terminal[s] = isterminal(model, s);
        for a ∈ 1:number_of_actions
            (s′, r) = world(model, s, a);
            next_state[s,a] = s′;
            reward[s,a] = r;
        end
    end

    # value iteration: sweep the Bellman backup until the values stop changing -
    U = zeros(number_of_states); # the values before this sweep
    U_new = zeros(number_of_states); # the values after this sweep
    converged = false; # set to true when a sweep changes no value by more than tolerance
    for k ∈ 1:k_max

        # one sweep over the states -
        for s ∈ 1:number_of_states
            if (terminal[s] == true)
                U_new[s] = 0.0; # an absorbing state earns nothing more
            else
                best = -Inf;
                for a ∈ 1:number_of_actions
                    value = reward[s,a] + γ*U[next_state[s,a]];
                    if (value > best)
                        best = value;
                    end
                end
                U_new[s] = best;
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
        @warn "Value iteration used all k_max = $(k_max) sweeps before the largest change fell to the tolerance, so Q⋆ may not be optimal. Try a larger k_max."
    end

    # the action values of the converged value function -
    Q = zeros(number_of_states, number_of_actions);
    for s ∈ 1:number_of_states
        if (terminal[s] == false)
            for a ∈ 1:number_of_actions
                Q[s,a] = reward[s,a] + γ*U[next_state[s,a]];
            end
        end
    end

    # return -
    return Q;
end

"""
    simulate(model::MyAdaptiveDosingModel, π::Array{Int64,1}, s₀::Int64;
        maxsteps::Int64 = 100) -> NamedTuple

Follow the dosing policy `π` from the starting state `s₀` until the patient is cured, dies of
toxicity, or `maxsteps` cycles have passed.

### Arguments
- `model::MyAdaptiveDosingModel`: the environment.
- `π::Array{Int64,1}`: the action to take in each state, i.e., `π[s]` is the action in state `s`.
- `s₀::Int64`: the starting state.
- `maxsteps::Int64 = 100`: the most cycles to simulate.

### Returns
A `NamedTuple` with the fields:
- `B::Array{Float64,1}`: the tumor burden at the start of each cycle, and at the end.
- `Z::Array{Float64,1}`: the toxicity at the same times.
- `dose::Array{Float64,1}`: the dose given in each cycle, with a final 0 for the last state.
- `outcome::Symbol`: `:cured`, `:dead`, or `:timeout` (no absorbing state within `maxsteps` cycles).
- `steps::Int64`: the number of cycles in which a dose was given.
"""
function simulate(model::MyAdaptiveDosingModel, π::Array{Int64,1}, s₀::Int64;
    maxsteps::Int64 = 100)::NamedTuple

    # initialize -
    B_values = Array{Float64,1}();
    Z_values = Array{Float64,1}();
    doses = Array{Float64,1}();
    s = s₀;

    # main loop: one treatment cycle per pass -
    for t ∈ 1:maxsteps

        # record the current patient state -
        (B, Z) = decode(model, s);
        push!(B_values, B);
        push!(Z_values, Z);

        # has the treatment ended? -
        if (isterminal(model, s) == true)
            push!(doses, 0.0);
            outcome = :dead;
            if (iscured(model, s) == true)
                outcome = :cured;
            end
            return (B = B_values, Z = Z_values, dose = doses, outcome = outcome, steps = t - 1);
        end

        # give the dose the policy chooses, and move to the next state -
        a = π[s];
        push!(doses, model.doses[a]);
        (s, _) = world(model, s, a); # the _ discards the reward, which we do not need here
    end

    # all maxsteps cycles are used: record where the last cycle left the patient -
    (B, Z) = decode(model, s);
    push!(B_values, B);
    push!(Z_values, Z);
    push!(doses, 0.0); # no dose after the last cycle

    # did the last cycle end the treatment? If not, the run timed out -
    outcome = :timeout;
    if (iscured(model, s) == true)
        outcome = :cured;
    elseif (isterminal(model, s) == true)
        outcome = :dead;
    end
    return (B = B_values, Z = Z_values, dose = doses, outcome = outcome, steps = maxsteps);
end

"""
    mdpworld(problem::MyMDPProblemModel, s::Int64, a::Int64) -> Tuple{Int64,Float64}

Simulate one step of a Markov decision process whose moves are certain. Given the state `s` and
the action `a`, return the next state `s′`, the one state with `T[s,s′,a] = 1`, and the reward
`R[s,a]`. The check cell of the notebook uses it on a small problem whose answers we work out
by hand.

### Arguments
- `problem::MyMDPProblemModel`: the problem; we use its transition array `T` and its reward
  matrix `R`.
- `s::Int64`: the current state.
- `a::Int64`: the action.

### Returns
- `Tuple{Int64,Float64}`: the next state `s′` and the reward `r`.
"""
function mdpworld(problem::MyMDPProblemModel, s::Int64, a::Int64)::Tuple{Int64,Float64}
    s′ = argmax(problem.T[s, :, a]); # the next state: the one with probability 1
    r = problem.R[s, a]; # the reward
    return (s′, r);
end

end # module L12bUtility
