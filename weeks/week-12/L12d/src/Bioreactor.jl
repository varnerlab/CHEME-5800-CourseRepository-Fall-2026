# =============================================================================
# CHEME 5800 | L12d lab code: a fed-batch bioreactor
# =============================================================================
# This file holds everything the lab uses:
#
#   MyFedBatchBioreactorModel   the bioreactor model: the state grid, the feeds, and the parameters
#   build(...)                  builds a MyFedBatchBioreactorModel from a NamedTuple of parameters
#   stateindex(...)             the grid state nearest a culture state (X, L, V)
#   decode(...)                 the culture state (X, L, V) of a grid state
#   isterminal(...)             is a state absorbing (harvested or crashed)?
#   world(...)                  one feed cycle: the next state and the reward
#   solve(...)                  value iteration (model-based) or Q-learning (model-free)
#   simulate(...)               run a feed policy from a starting state to the end of the batch
#   count_untried_pairs(...)    count the state-action pairs a Q-learning agent never tried
#
# These functions are complete; there is nothing to edit in this lab. Include.jl
# loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12dBioreactor

import VLDataScienceMachineLearningPackage: build, solve # we add methods for the bioreactor model to these two functions
using VLDataScienceMachineLearningPackage: MyQLearningAgentModel # the Q-learning agent type
using Random # Xoshiro, a seeded random number generator

export MyFedBatchBioreactorModel, stateindex, decode, isterminal, world, simulate, count_untried_pairs

"""
    mutable struct MyFedBatchBioreactorModel

The fed-batch bioreactor environment. The culture state is a point `(X, L, V)` on a cubic grid,
where `X` is the cell density, `L` is the lactate concentration, and `V` is the volume of
liquid in the reactor, each scaled to lie between 0 and 1. Each feed cycle, the agent chooses a
feed rate `f` from `feeds`. The feed adds volume and lets the cells grow, but it also makes
lactate and dilutes the culture. The batch ends with a harvest when the reactor is full, or
with a crash when the lactate reaches the crash level.

### Fields
- `nlevels::Int64`: the number of grid levels on each axis; `X`, `L`, and `V` each take the
  values `0, step, 2⋅step, …, 1`.
- `step::Float64`: the grid spacing, `1/(nlevels - 1)`.
- `coordinates::Dict{Int64,Tuple{Int64,Int64,Int64}}`: maps a state index `s` to its grid
  indices `(iX, iL, iV)`.
- `states::Dict{Tuple{Int64,Int64,Int64},Int64}`: maps grid indices `(iX, iL, iV)` to the
  state index `s`.
- `feeds::Array{Float64,1}`: the feed rate of each action; action `a` feeds at `feeds[a]`.
- `mumax::Float64`: the largest growth rate of the cells per cycle.
- `Kf::Float64`: the feed rate at which the feed factor `f/(Kf + f)` of the growth rate is one half.
- `KIL::Float64`: the lactate concentration at which the lactate factor `KIL/(KIL + L)` of the
  growth rate is one half.
- `kd::Float64`: the fraction of the cells that die each cycle.
- `yL::Float64`: the lactate made per cycle, per unit of feed and cell density.
- `kL::Float64`: the fraction of the lactate the cells consume each cycle.
- `qP::Float64`: the product made per unit of cell density and volume; a harvest earns `qP⋅X⋅V`.
- `vfeed::Float64`: the volume added per cycle at the full feed rate.
- `V0::Float64`: the starting volume.
- `Vmax::Float64`: the batch is harvested when `V ≥ Vmax`.
- `Lcrash::Float64`: the culture crashes when `L ≥ Lcrash`.
- `Rcrash::Float64`: the reward for a crash (negative).
"""
mutable struct MyFedBatchBioreactorModel

    # the state grid -
    nlevels::Int64
    step::Float64
    coordinates::Dict{Int64,Tuple{Int64,Int64,Int64}}
    states::Dict{Tuple{Int64,Int64,Int64},Int64}

    # the actions -
    feeds::Array{Float64,1}

    # the growth and lactate parameters -
    mumax::Float64
    Kf::Float64
    KIL::Float64
    kd::Float64
    yL::Float64
    kL::Float64
    qP::Float64

    # the volume parameters -
    vfeed::Float64
    V0::Float64
    Vmax::Float64

    # the crash level and its reward -
    Lcrash::Float64
    Rcrash::Float64

    # constructor: an empty model; build(...) fills in the fields -
    MyFedBatchBioreactorModel() = new();
end

"""
    build(modeltype::Type{MyFedBatchBioreactorModel}, data::NamedTuple) -> MyFedBatchBioreactorModel

Build a fed-batch bioreactor environment from a `NamedTuple` of parameters, including the maps
between state indices and grid indices.

### Arguments
- `modeltype::Type{MyFedBatchBioreactorModel}`: the type to build.
- `data::NamedTuple`: the parameters, with the fields `nlevels`, `feeds`, `mumax`, `Kf`, `KIL`,
  `kd`, `yL`, `kL`, `qP`, `vfeed`, `V0`, `Vmax`, `Lcrash`, and `Rcrash`. Each has the meaning
  given in the docstring of `MyFedBatchBioreactorModel`.

### Returns
- `MyFedBatchBioreactorModel`: the environment. Its states are numbered `1, 2, …, nlevels^3`,
  and state `s` sits at the grid indices `coordinates[s]`.
"""
function build(modeltype::Type{MyFedBatchBioreactorModel}, data::NamedTuple)::MyFedBatchBioreactorModel

    # initialize an empty model -
    model = modeltype();

    # the grid spacing: the levels are 0, step, 2⋅step, ..., 1 -
    nlevels = data.nlevels;
    model.nlevels = nlevels;
    model.step = 1.0/(nlevels - 1);

    # number the grid points: state s sits at the grid indices (iX, iL, iV) -
    coordinates = Dict{Int64,Tuple{Int64,Int64,Int64}}();
    states = Dict{Tuple{Int64,Int64,Int64},Int64}();
    s = 1;
    for iX ∈ 1:nlevels
        for iL ∈ 1:nlevels
            for iV ∈ 1:nlevels
                coordinates[s] = (iX, iL, iV);
                states[(iX, iL, iV)] = s;
                s = s + 1;
            end
        end
    end
    model.coordinates = coordinates;
    model.states = states;

    # copy the actions and the parameters -
    model.feeds = data.feeds;
    model.mumax = data.mumax;
    model.Kf = data.Kf;
    model.KIL = data.KIL;
    model.kd = data.kd;
    model.yL = data.yL;
    model.kL = data.kL;
    model.qP = data.qP;
    model.vfeed = data.vfeed;
    model.V0 = data.V0;
    model.Vmax = data.Vmax;
    model.Lcrash = data.Lcrash;
    model.Rcrash = data.Rcrash;

    # return -
    return model;
end

"""
    level(model::MyFedBatchBioreactorModel, i::Int64) -> Float64

Return the value, between 0 and 1, of grid index `i` on any axis: `(i - 1)⋅step`.
"""
function level(model::MyFedBatchBioreactorModel, i::Int64)::Float64
    return (i - 1)*model.step;
end

"""
    snap(model::MyFedBatchBioreactorModel, x::Float64) -> Int64

Return the grid index nearest the value `x`. A value below 0 or above 1 snaps to the first or
the last grid index.
"""
function snap(model::MyFedBatchBioreactorModel, x::Float64)::Int64

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
    stateindex(model::MyFedBatchBioreactorModel, X::Float64, L::Float64, V::Float64) -> Int64

Return the index of the grid state nearest the culture state `(X, L, V)`: the cell density, the
lactate concentration, and the volume.

### Example
```julia
s₀ = stateindex(env, 0.10, 0.0, 0.50); # a few cells, no lactate, and a half-full reactor
```
"""
function stateindex(model::MyFedBatchBioreactorModel, X::Float64, L::Float64, V::Float64)::Int64
    iX = snap(model, X); # the nearest cell-density level
    iL = snap(model, L); # the nearest lactate level
    iV = snap(model, V); # the nearest volume level
    return model.states[(iX, iL, iV)];
end

"""
    decode(model::MyFedBatchBioreactorModel, s::Int64) -> Tuple{Float64,Float64,Float64}

Return the culture state `(X, L, V)` of the grid state `s`: the cell density, the lactate
concentration, and the volume.
"""
function decode(model::MyFedBatchBioreactorModel, s::Int64)::Tuple{Float64,Float64,Float64}
    (iX, iL, iV) = model.coordinates[s];
    return (level(model, iX), level(model, iL), level(model, iV));
end

"""
    iscrashed(model::MyFedBatchBioreactorModel, s::Int64) -> Bool

Return `true` if the lactate of state `s` has reached the crash level, `L ≥ Lcrash`.
"""
function iscrashed(model::MyFedBatchBioreactorModel, s::Int64)::Bool
    (X, L, V) = decode(model, s); # the culture state of s
    return L ≥ model.Lcrash;
end

"""
    isharvested(model::MyFedBatchBioreactorModel, s::Int64) -> Bool

Return `true` if state `s` is a harvest: the reactor is full, `V ≥ Vmax`, and the culture has
not crashed. A state that meets both conditions counts as a crash, not a harvest.
"""
function isharvested(model::MyFedBatchBioreactorModel, s::Int64)::Bool
    (X, L, V) = decode(model, s); # the culture state of s
    if (iscrashed(model, s) == true)
        return false; # a crashed culture is never harvested
    end
    return V ≥ model.Vmax;
end

"""
    isterminal(model::MyFedBatchBioreactorModel, s::Int64) -> Bool

Return `true` if state `s` is absorbing: the batch has been harvested or the culture has
crashed. Once the culture enters an absorbing state, the batch ends.
"""
function isterminal(model::MyFedBatchBioreactorModel, s::Int64)::Bool
    if (iscrashed(model, s) == true)
        return true;
    end
    if (isharvested(model, s) == true)
        return true;
    end
    return false;
end

"""
    world(model::MyFedBatchBioreactorModel, s::Int64, a::Int64) -> Tuple{Int64,Float64}

Simulate one feed cycle. Given the current state `s` and the action `a`, return the next state
`s′` and the reward `r`.

The feed rate is `f = feeds[a]`. The feed adds the volume `ΔV = vfeed⋅f`, which dilutes the
culture by the fraction `D = ΔV/V`; in an empty reactor, `V = 0`, we divide by one grid step
instead, so we never divide by zero. The growth rate rises with the feed and falls with the
lactate, `μ = mumax⋅(f/(Kf + f))⋅(KIL/(KIL + L))`, and the state changes by one step of the
fed-batch balances

    X′ = X + μ⋅X⋅(1 - X) - kd⋅X - D⋅X     (growth, minus death and dilution)
    L′ = L + yL⋅f⋅X - kL⋅L - D⋅L          (lactate made, minus consumed and diluted)
    V′ = V + ΔV                           (the feed fills the reactor)

each clipped to lie between 0 and 1, and the next state is the grid state nearest
`(X′, L′, V′)`. The reward is `Rcrash` if `s′` is a crash, the harvested product `qP⋅X′⋅V′` if
`s′` is a harvest, and zero otherwise. An absorbing state returns `(s, 0.0)`: the batch has ended.
"""
function world(model::MyFedBatchBioreactorModel, s::Int64, a::Int64)::Tuple{Int64,Float64}

    # an absorbing state: the batch has ended -
    if (isterminal(model, s) == true)
        return (s, 0.0);
    end

    # the current culture state and the feed rate -
    (X, L, V) = decode(model, s);
    f = model.feeds[a];

    # the volume added, the dilution, and the growth rate -
    ΔV = model.vfeed*f;
    D = ΔV/max(V, model.step); # max(...) avoids dividing by zero in an empty reactor
    μ = model.mumax*(f/(model.Kf + f))*(model.KIL/(model.KIL + L));

    # one cycle of the dynamics, clipped to [0, 1] -
    X_next = X + μ*X*(1 - X) - model.kd*X - D*X;
    L_next = L + model.yL*f*X - model.kL*L - D*L;
    V_next = V + ΔV;
    X_next = min(max(X_next, 0.0), 1.0); # min(max(x, 0), 1) keeps x between 0 and 1
    L_next = min(max(L_next, 0.0), 1.0);
    V_next = min(max(V_next, 0.0), 1.0);

    # the nearest grid state -
    s′ = stateindex(model, X_next, L_next, V_next);

    # the reward -
    r = 0.0; # nothing until the batch ends
    if (iscrashed(model, s′) == true)
        r = model.Rcrash; # the culture crashed
    elseif (isharvested(model, s′) == true)
        (X′, L′, V′) = decode(model, s′); # the grid values of the next state
        r = model.qP*X′*V′; # the product harvested
    end

    # return -
    return (s′, r);
end

"""
    solve(model::MyFedBatchBioreactorModel; γ::Float64 = 0.95, tolerance::Float64 = 1e-8,
        k_max::Int64 = 20000) -> Array{Float64,2}

Compute the optimal action-value table `Q⋆` by value iteration, using the known dynamics in
`world(...)`. This is the model-based answer that we compare Q-learning against.

Each action has a single next state here, so the Bellman backup of state `s` is
`U(s) = max over a of (r(s,a) + γ⋅U(s′(s,a)))`. The function first tabulates `s′(s,a)` and
`r(s,a)` with `world(...)`, then sweeps the backup over every state until no value changes by
more than `tolerance`, or for `k_max` sweeps. Absorbing states keep the value zero.

### Arguments
- `model::MyFedBatchBioreactorModel`: the environment.
- `γ::Float64 = 0.95`: the discount factor, `0 ≤ γ < 1`.
- `tolerance::Float64 = 1e-8`: stop when the largest change in a sweep is at most this.
- `k_max::Int64 = 20000`: the maximum number of sweeps.

### Returns
- `Array{Float64,2}`: the optimal action-value table, one row per state and one column per
  action; `Q⋆[s,a] = r(s,a) + γ⋅U⋆(s′(s,a))`, and the rows of absorbing states are zero. The
  optimal policy is `policy(Q⋆)`.
"""
function solve(model::MyFedBatchBioreactorModel; γ::Float64 = 0.95, tolerance::Float64 = 1e-8,
    k_max::Int64 = 20000)::Array{Float64,2}

    # initialize -
    number_of_states = model.nlevels^3;
    number_of_actions = length(model.feeds);

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
    solve(agent::MyQLearningAgentModel, model::MyFedBatchBioreactorModel;
        episodes::Int64 = 200_000, maxsteps::Int64 = 80, seed::Int64 = 5800,
        ϵ_start::Float64 = 1.0, ϵ_floor::Float64 = 0.05) -> NamedTuple

Train a Q-learning agent on the bioreactor, model-free: the agent only sees the next state and
the reward that `world(...)` returns for the feed it chose.

Each episode starts from a random state that is not absorbing and runs until the batch ends or
`maxsteps` cycles pass. Each cycle, the agent chooses its action with the epsilon-greedy rule,
observes `(s′, r)`, and updates `Q[s,a]` toward the target `r + γ⋅max Q[s′,:]`. The rows of
absorbing states are set to zero at the start and never updated, so the target of a move into
one is `r`.

The learning rate of the n-th update of a pair `(s,a)` is `1/n`, so `Q[s,a]` is the running
average of the targets that pair has seen (the agent's own `α` field is not used). The
exploration probability of episode `i` is `ϵ = max(ϵ_floor, ϵ_start - i/(0.7⋅episodes))`: with
the defaults, it falls in a straight line from 1 to 0.05 over the first 70 percent of the
episodes, then stays at 0.05. Setting `ϵ_start` and `ϵ_floor` to the same value keeps `ϵ` fixed
at that value, and setting both to zero gives a purely greedy agent.

### Arguments
- `agent::MyQLearningAgentModel`: the agent; we use its discount factor `γ` and start from a copy
  of its table `Q`, one row per state and one column per action. The agent's own table is not changed.
- `model::MyFedBatchBioreactorModel`: the environment.
- `episodes::Int64 = 200_000`: the number of episodes.
- `maxsteps::Int64 = 80`: the most cycles in one episode.
- `seed::Int64 = 5800`: the seed of the random number generator, so a run can be repeated exactly.
- `ϵ_start::Float64 = 1.0`: the exploration probability at the start of training.
- `ϵ_floor::Float64 = 0.05`: the smallest exploration probability.

### Returns
A `NamedTuple` with the fields:
- `Q::Array{Float64,2}`: the learned action values. The learned policy is `policy(Q)`.
- `visits::Array{Int64,2}`: the number of times the agent took each action in each state.
"""
function solve(agent::MyQLearningAgentModel, model::MyFedBatchBioreactorModel;
    episodes::Int64 = 200_000, maxsteps::Int64 = 80, seed::Int64 = 5800,
    ϵ_start::Float64 = 1.0, ϵ_floor::Float64 = 0.05)::NamedTuple

    # initialize -
    rng = Xoshiro(seed); # our own random number generator, so a run can be repeated exactly
    Q = copy(agent.Q); # the table we update: a copy, so the agent's own table is not changed
    γ = agent.γ; # the discount factor
    number_of_states = model.nlevels^3;
    number_of_actions = length(model.feeds);
    visits = zeros(Int64, number_of_states, number_of_actions); # visits[s,a]: how many times we took action a in state s

    # the states an episode may start from: every state that is not absorbing. The row of an
    # absorbing state is set to zero, because the batch has ended and earns nothing more -
    starts = Array{Int64,1}();
    for s ∈ 1:number_of_states
        if (isterminal(model, s) == false)
            push!(starts, s);
        else
            for a ∈ 1:number_of_actions
                Q[s,a] = 0.0;
            end
        end
    end

    # main loop: one episode per pass -
    for episode ∈ 1:episodes

        # the exploration probability for this episode -
        ϵ = ϵ_start - episode/(0.7*episodes);
        if (ϵ < ϵ_floor)
            ϵ = ϵ_floor;
        end

        # a random starting state -
        s = starts[rand(rng, 1:length(starts))];
        t = 0; # the step counter
        while (isterminal(model, s) == false && t < maxsteps)

            # choose the action with the epsilon-greedy rule -
            p = rand(rng);
            a = 0;
            if (p ≤ ϵ)
                a = rand(rng, 1:number_of_actions); # exploration: a random action
            else
                a = argmax(Q[s,:]); # exploitation: the action with the largest value (the first, if tied)
            end

            # take the action and observe the next state and the reward -
            (s′, r) = world(model, s, a);

            # update the action value with the learning rate 1/n -
            visits[s,a] = visits[s,a] + 1;
            α = 1.0/visits[s,a];
            target = r + γ*maximum(Q[s′,:]); # the temporal difference target
            Q[s,a] = Q[s,a] + α*(target - Q[s,a]);

            # move to the next state -
            s = s′;
            t = t + 1;
        end
    end

    # return -
    return (Q = Q, visits = visits);
end

"""
    simulate(model::MyFedBatchBioreactorModel, π::Array{Int64,1}, s₀::Int64;
        maxsteps::Int64 = 80, γ::Float64 = 0.95) -> NamedTuple

Follow the feed policy `π` from the starting state `s₀` until the batch is harvested, the
culture crashes, or `maxsteps` cycles have passed, and add up the discounted rewards along the way.

### Arguments
- `model::MyFedBatchBioreactorModel`: the environment.
- `π::Array{Int64,1}`: the action to take in each state, i.e., `π[s]` is the action in state `s`.
- `s₀::Int64`: the starting state.
- `maxsteps::Int64 = 80`: the most cycles to simulate.
- `γ::Float64 = 0.95`: the discount factor used for the discounted return `G`.

### Returns
A `NamedTuple` with the fields:
- `X::Array{Float64,1}`: the cell density at the start of each cycle, and at the end.
- `L::Array{Float64,1}`: the lactate concentration at the same times.
- `V::Array{Float64,1}`: the volume at the same times.
- `feed::Array{Float64,1}`: the feed rate in each cycle, with a final 0 for the last state.
- `product::Float64`: the product harvested, `qP⋅X⋅V` at the harvest, or 0 if there was none.
- `outcome::Symbol`: `:harvest`, `:crash`, or `:timeout` (no absorbing state within `maxsteps` cycles).
- `steps::Int64`: the number of cycles in which the agent chose a feed.
- `G::Float64`: the discounted return, `r₁ + γ⋅r₂ + γ²⋅r₃ + …`, the quantity the optimal policy
  makes as large as possible.
"""
function simulate(model::MyFedBatchBioreactorModel, π::Array{Int64,1}, s₀::Int64;
    maxsteps::Int64 = 80, γ::Float64 = 0.95)::NamedTuple

    # initialize -
    X_values = Array{Float64,1}();
    L_values = Array{Float64,1}();
    V_values = Array{Float64,1}();
    feeds = Array{Float64,1}();
    G = 0.0; # the discounted return so far
    s = s₀;

    # main loop: one feed cycle per pass -
    for t ∈ 1:maxsteps

        # record the current culture state -
        (X, L, V) = decode(model, s);
        push!(X_values, X);
        push!(L_values, L);
        push!(V_values, V);

        # has the batch ended? -
        if (isterminal(model, s) == true)
            push!(feeds, 0.0);
            outcome = :crash;
            product = 0.0;
            if (isharvested(model, s) == true)
                outcome = :harvest;
                product = model.qP*X*V; # the product harvested
            end
            return (X = X_values, L = L_values, V = V_values, feed = feeds,
                product = product, outcome = outcome, steps = t - 1, G = G);
        end

        # feed at the rate the policy chooses, and move to the next state -
        a = π[s];
        push!(feeds, model.feeds[a]);
        (s, r) = world(model, s, a);
        G = G + γ^(t - 1)*r; # the reward of cycle t, discounted by γ^(t-1)
    end

    # all maxsteps cycles are used: record where the last cycle left the culture -
    (X, L, V) = decode(model, s);
    push!(X_values, X);
    push!(L_values, L);
    push!(V_values, V);
    push!(feeds, 0.0); # no feed after the last cycle

    # did the last cycle end the batch? If not, the run timed out -
    outcome = :timeout;
    product = 0.0;
    if (isharvested(model, s) == true)
        outcome = :harvest;
        product = model.qP*X*V; # the product harvested
    elseif (iscrashed(model, s) == true)
        outcome = :crash;
    end
    return (X = X_values, L = L_values, V = V_values, feed = feeds,
        product = product, outcome = outcome, steps = maxsteps, G = G);
end

"""
    count_untried_pairs(model::MyFedBatchBioreactorModel, visits::Array{Int64,2}) -> Tuple{Int64,Int64}

Count the state-action pairs that a Q-learning agent never tried, in the states that are not
absorbing. An absorbing state ends the episode, so no agent can try an action there.

### Arguments
- `model::MyFedBatchBioreactorModel`: the environment.
- `visits::Array{Int64,2}`: the visit counts returned by `solve(...)`, one row per state and one
  column per action.

### Returns
- `Tuple{Int64,Int64}`: the number of pairs with zero visits, and the number of pairs checked.
"""
function count_untried_pairs(model::MyFedBatchBioreactorModel, visits::Array{Int64,2})::Tuple{Int64,Int64}

    # initialize -
    number_untried = 0; # pairs with zero visits
    number_checked = 0; # pairs in states that are not absorbing

    # main loop: check every pair of every state that is not absorbing -
    for s ∈ 1:size(visits, 1)
        if (isterminal(model, s) == false)
            for a ∈ 1:size(visits, 2)
                number_checked = number_checked + 1;
                if (visits[s, a] == 0)
                    number_untried = number_untried + 1;
                end
            end
        end
    end

    # return -
    return (number_untried, number_checked);
end

end # module L12dBioreactor
