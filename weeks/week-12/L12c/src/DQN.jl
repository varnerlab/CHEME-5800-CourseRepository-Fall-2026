# =============================================================================
# CHEME 5800 | L12c example: deep Q-learning with a linear Q-network
# =============================================================================
# This file holds the DQN agent of the example:
#
#   MyLinearQNetworkModel   the linear Q-network: the centers, the width, and the weights
#   build(...)              builds a MyLinearQNetworkModel with all weights zero
#   features(...)           the feature vector φ(s) of a patient state
#   qvalues(...)            the Q-values of every action in a patient state
#   greedyaction(...)       the action with the largest Q-value
#   MyTransitionModel       one stored experience (φ(s), a, r, φ(s′), done)
#   MyReplayBufferModel     the replay buffer of the most recent experiences
#   remember!(...)          adds one experience to the replay buffer
#   mydqn(...)              trains the network with DQN on the patient model
#   simulate(...)           roll the greedy policy of the network out from a starting state
#
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12cDQN

import VLDataScienceMachineLearningPackage: build # we add methods for the network and the buffer
using Random # Xoshiro, a seeded random number generator
using ..L12cPatient # the patient model: treat, isterminal, and iscured
import ..L12cPatient: simulate # we add a method that follows the greedy policy of a network

export MyLinearQNetworkModel, features, qvalues, greedyaction
export MyTransitionModel, MyReplayBufferModel, remember!, mydqn

"""
    mutable struct MyLinearQNetworkModel

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
mutable struct MyLinearQNetworkModel
    W::Array{Float64,2}
    centers::Array{Float64,2}
    σ::Float64

    # constructor: an empty model; build(...) fills in the fields -
    MyLinearQNetworkModel() = new();
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
    features(network::MyLinearQNetworkModel, B::Float64, Z::Float64) -> Array{Float64,1}

Return the feature vector `φ(s)` of the patient state `s = (B, Z)`. Entry `j` of the vector is the
basis function `exp(-d²/(2σ²))`, where `d` is the distance from `(B, Z)` to center `j`. The last entry is
the constant 1.
"""
function features(network::MyLinearQNetworkModel, B::Float64, Z::Float64)::Array{Float64,1}

    # initialize -
    number_of_basis_functions = size(network.centers, 1);
    φ = zeros(number_of_basis_functions + 1);

    # one basis function per center -
    for j ∈ 1:number_of_basis_functions
        d² = (B - network.centers[j, 1])^2 + (Z - network.centers[j, 2])^2; # squared distance to center j
        φ[j] = exp(-d²/(2*network.σ^2));
    end

    # the constant feature -
    φ[number_of_basis_functions + 1] = 1.0;

    # return -
    return φ;
end

"""
    qvalues(network::MyLinearQNetworkModel, B::Float64, Z::Float64) -> Array{Float64,1}

Return the Q-values of every action in the patient state `(B, Z)`: the vector `W⋅φ(s)`, with
one entry per action.
"""
function qvalues(network::MyLinearQNetworkModel, B::Float64, Z::Float64)::Array{Float64,1}
    φ = features(network, B, Z);
    return network.W*φ;
end

"""
    greedyaction(network::MyLinearQNetworkModel, B::Float64, Z::Float64) -> Int64

Return the action with the largest Q-value in the patient state `(B, Z)`. The first such action
wins a tie.
"""
function greedyaction(network::MyLinearQNetworkModel, B::Float64, Z::Float64)::Int64
    return argmax(qvalues(network, B, Z));
end

"""
    struct MyTransitionModel

One experience of the agent, stored in the replay buffer.

### Fields
- `φ::Array{Float64,1}`: the features of the state `s`.
- `a::Int64`: the action taken in `s`.
- `r::Float64`: the reward received.
- `φ′::Array{Float64,1}`: the features of the next state `s′`.
- `done::Bool`: `true` if the treatment ended at `s′`.
"""
struct MyTransitionModel
    φ::Array{Float64,1}
    a::Int64
    r::Float64
    φ′::Array{Float64,1}
    done::Bool
end

"""
    mutable struct MyReplayBufferModel

The replay buffer: a memory of the most recent experiences. Once the buffer holds `capacity`
experiences, each new experience replaces the oldest one.

### Fields
- `memory::Array{MyTransitionModel,1}`: the stored experiences.
- `capacity::Int64`: the most experiences the buffer holds.
- `oldest::Int64`: the slot of the oldest experience, which the next experience replaces once
  the buffer is full.
"""
mutable struct MyReplayBufferModel
    memory::Array{MyTransitionModel,1}
    capacity::Int64
    oldest::Int64

    # constructor: an empty model; build(...) fills in the fields -
    MyReplayBufferModel() = new();
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

"""
    remember!(buffer::MyReplayBufferModel, transition::MyTransitionModel) -> Nothing

Add one experience to the replay buffer. If the buffer is full, the new experience replaces the
oldest one.
"""
function remember!(buffer::MyReplayBufferModel, transition::MyTransitionModel)::Nothing

    # room left: add the experience at the end -
    if (length(buffer.memory) < buffer.capacity)
        push!(buffer.memory, transition);
        return nothing;
    end

    # full: replace the oldest experience, then move the oldest slot forward by one -
    buffer.memory[buffer.oldest] = transition;
    buffer.oldest = buffer.oldest + 1;
    if (buffer.oldest > buffer.capacity)
        buffer.oldest = 1; # wrap around to the first slot
    end
    return nothing;
end

"""
    mydqn(network::MyLinearQNetworkModel, model::MyPatientModel; episodes::Int64 = 3000,
        maxcycles::Int64 = 80, γ::Float64 = 0.95, α::Float64 = 0.05, capacity::Int64 = 20_000,
        batchsize::Int64 = 32, warmup::Int64 = 1000, C::Int64 = 500, ϵ_start::Float64 = 1.0,
        ϵ_floor::Float64 = 0.05, seed::Int64 = 1234) -> NamedTuple

Train a linear Q-network on the patient model with deep Q-learning (DQN).

Each episode starts the patient at a random state and treats the patient for at most
`maxcycles` cycles. The agent picks each dose ϵ-greedily from the main network and stores the
experience in the replay buffer. Once the buffer holds `warmup` experiences, every cycle also
takes one gradient step on a random mini-batch of `batchsize` stored experiences. The target of
experience `i` is `yᵢ = rᵢ + γ⋅(1 - doneᵢ)⋅max over a′ of Q⁻(s′ᵢ, a′)`, computed with the
target network `Q⁻`, a copy of the main network made every `C` cycles, counted over all
episodes. Here `doneᵢ` is `true` only for a cure or a toxic death; an episode that stops at
`maxcycles` leaves it `false`. The gradient step is

    W[a,:] ← W[a,:] + (α/batchsize)⋅Σ over the experiences i with aᵢ = a of (yᵢ - W[a,:]⋅φ(sᵢ))⋅φ(sᵢ),

with every error computed from the weights before the step.

### Arguments
- `network::MyLinearQNetworkModel`: the untrained network; its weights are copied, not changed.
- `model::MyPatientModel`: the patient model, which plays the role of the world.
- `episodes::Int64 = 3000`: the number of episodes.
- `maxcycles::Int64 = 80`: the most cycles in one episode.
- `γ::Float64 = 0.95`: the discount factor.
- `α::Float64 = 0.05`: the learning rate of the gradient step.
- `capacity::Int64 = 20_000`: the size of the replay buffer.
- `batchsize::Int64 = 32`: the number of experiences in a mini-batch.
- `warmup::Int64 = 1000`: the number of experiences stored before training starts.
- `C::Int64 = 500`: the number of cycles between copies of the main network to the target network.
- `ϵ_start::Float64 = 1.0`, `ϵ_floor::Float64 = 0.05`: the exploration rate in episode `i` is
  `ϵ_start - i/(0.7⋅episodes)`, but never below `ϵ_floor`. With the defaults, it falls in a
  straight line from 1, reaches 0.05 after 66.5 percent of the episodes, then stays there.
- `seed::Int64 = 1234`: the seed of the random number generator, for a run we can repeat.

### Returns
A `NamedTuple` with the fields:
- `network::MyLinearQNetworkModel`: the trained network.
- `cycles::Int64`: the number of cycles of experience over all episodes.
- `updates::Int64`: the number of gradient steps taken.
"""
function mydqn(network::MyLinearQNetworkModel, model::MyPatientModel; episodes::Int64 = 3000,
    maxcycles::Int64 = 80, γ::Float64 = 0.95, α::Float64 = 0.05, capacity::Int64 = 20_000,
    batchsize::Int64 = 32, warmup::Int64 = 1000, C::Int64 = 500, ϵ_start::Float64 = 1.0,
    ϵ_floor::Float64 = 0.05, seed::Int64 = 1234)::NamedTuple

    # initialize -
    rng = Xoshiro(seed); # the seeded random number generator
    trained = deepcopy(network); # the main network; the caller's network is left as it was
    W = trained.W; # the weights of the main network (W changes trained.W)
    W⁻ = copy(W); # the weights of the target network
    number_of_actions = size(W, 1);
    buffer = build(MyReplayBufferModel, (capacity = capacity,));
    cycles = 0; # cycles of experience so far
    updates = 0; # gradient steps so far

    # main loop: one episode per pass -
    for episode ∈ 1:episodes

        # the exploration rate falls in a straight line, then stays at ϵ_floor -
        ϵ = ϵ_start - episode/(0.7*episodes);
        if (ϵ < ϵ_floor)
            ϵ = ϵ_floor;
        end

        # start the patient at a random state where the treatment has not ended -
        B = rand(rng);
        Z = 0.85*rand(rng);
        while (isterminal(model, B, Z) == true)
            B = rand(rng);
            Z = 0.85*rand(rng);
        end

        # treat the patient for at most maxcycles cycles -
        for t ∈ 1:maxcycles

            # choose the dose ϵ-greedily from the main network -
            φ = features(trained, B, Z);
            a = 0;
            if (rand(rng) ≤ ϵ)
                a = rand(rng, 1:number_of_actions); # explore: a random dose
            else
                a = argmax(W*φ); # exploit: the dose with the largest Q-value
            end

            # one treatment cycle, and store the experience -
            (B′, Z′, r, done) = treat(model, B, Z, a);
            φ′ = features(trained, B′, Z′);
            remember!(buffer, MyTransitionModel(φ, a, r, φ′, done));
            cycles = cycles + 1;

            # training step: once the buffer is warm, one gradient step on a random mini-batch -
            if (length(buffer.memory) ≥ warmup)
                gradient = zeros(size(W)); # the sum over the mini-batch of error × features
                for i ∈ 1:batchsize
                    e = buffer.memory[rand(rng, 1:length(buffer.memory))]; # a random stored experience

                    # the target, from the target network; an ended treatment has no future value -
                    y = e.r;
                    if (e.done == false)
                        y = e.r + γ*maximum(W⁻*e.φ′);
                    end

                    # the error on the action taken, and its contribution to the gradient step -
                    δ = y - sum(W[e.a, :].*e.φ);
                    gradient[e.a, :] = gradient[e.a, :] .+ δ.*e.φ;
                end
                W .= W .+ (α/batchsize).*gradient; # one gradient step on half the mean squared error
                updates = updates + 1;
            end

            # every C cycles, copy the main network to the target network -
            if (cycles % C == 0)
                W⁻ .= W;
            end

            # move to the next state; stop if the treatment has ended -
            B = B′;
            Z = Z′;
            if (done == true)
                break;
            end
        end
    end

    # return -
    return (network = trained, cycles = cycles, updates = updates);
end

"""
    simulate(model::MyPatientModel, network::MyLinearQNetworkModel; B₀::Float64 = 0.9,
        Z₀::Float64 = 0.0, maxcycles::Int64 = 100, γ::Float64 = 0.95) -> NamedTuple

Follow the greedy policy of the network on the patient, from the starting state `(B₀, Z₀)`, until
the patient is cured, dies of toxicity, or `maxcycles` cycles have passed. There is no
exploration: each cycle gives the dose with the largest Q-value.

### Returns
A `NamedTuple` with the same fields as the grid-policy method of `simulate`: `B`, `Z`, `dose`,
`outcome`, `cycles`, and `G`, the discounted return.
"""
function simulate(model::MyPatientModel, network::MyLinearQNetworkModel; B₀::Float64 = 0.9,
    Z₀::Float64 = 0.0, maxcycles::Int64 = 100, γ::Float64 = 0.95)::NamedTuple

    # initialize -
    B_values = [B₀];
    Z_values = [Z₀];
    doses = Array{Float64,1}();
    B = B₀;
    Z = Z₀;
    G = 0.0; # the discounted return
    discount = 1.0; # γ to the power of the number of cycles so far

    # a start where the treatment has already ended gets no dose -
    if (isterminal(model, B, Z) == true)
        outcome = :dead;
        if (iscured(model, B, Z) == true)
            outcome = :cured;
        end
        return (B = B_values, Z = Z_values, dose = doses, outcome = outcome, cycles = 0, G = G);
    end

    # main loop: one treatment cycle per pass -
    for t ∈ 1:maxcycles

        # give the dose with the largest Q-value -
        a = greedyaction(network, B, Z);
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

end # module L12cDQN
