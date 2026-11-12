# =============================================================================
# CHEME 5800 | L12d lab: the compute functions
# =============================================================================
# The patient, the network, value iteration on a grid, and DQN training.
#
#   treat(...)          one treatment cycle: the next state, the reward, and done
#   features(...)       the feature vector φ(s) of a patient state
#   qvalues(...)        the Q-values of every action in a patient state
#   greedyaction(...)   the action with the largest Q-value
#   solvegrid(...)      value iteration on a grid, for a reference policy
#   gridaction(...)     the action a grid policy gives a patient state
#   remember!(...)      adds one experience to the replay buffer
#   mydqn(...)          trains the network with DQN on the patient model
#   simulate(...)       follows a grid policy or a network from a starting state
# =============================================================================

# --- PUBLIC METHODS BELOW HERE --------------------------------------------------------------------------------------- #
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
If the treatment has already ended at `(B, Z)`, the state does not change, the reward is 0, and
`done` is `true`.
"""
function treat(model::MyPatientModel, B::Float64, Z::Float64, a::Int64)::Tuple{Float64,Float64,Float64,Bool}

    # a cure or a toxic death is absorbing: the treatment has ended -
    if (isterminal(model, B, Z) == true)
        return (B, Z, 0.0, true);
    end

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
    solvegrid(model::MyPatientModel; nlevels::Int64 = 201, γ::Float64 = 0.95,
        tolerance::Float64 = 1e-8, k_max::Int64 = 20000) -> MyGridPolicyModel

Compute an optimal dosing policy by value iteration on a grid of `nlevels` levels per axis. This
is the L12b method: each cycle starts from a grid point, and the next state is rounded to the
nearest grid point. With `nlevels = 41`, it is the L12b grid. A finer grid rounds the patient
state less, at the price of a larger table.

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
                next_iB[iB, iZ, a] = _snap(nlevels, B′);
                next_iZ[iB, iZ, a] = _snap(nlevels, Z′);

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
    iB = _snap(policy.nlevels, B);
    iZ = _snap(policy.nlevels, Z);
    return policy.π[iB, iZ];
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

with every error computed from the weights before the step. Each step also records the
mini-batch loss, half the mean squared error `(1/(2⋅batchsize))⋅Σᵢ (yᵢ - W[aᵢ,:]⋅φ(sᵢ))²`,
computed from the weights before the step.

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
- `loss::Array{Float64,1}`: the mini-batch loss of each gradient step, in order.
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
    losses = Array{Float64,1}(); # the mini-batch loss of each gradient step

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
                squared_error = 0.0; # the sum over the mini-batch of error²
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
                    squared_error = squared_error + δ^2;
                end
                W .= W .+ (α/batchsize).*gradient; # one gradient step on half the mean squared error
                updates = updates + 1;
                push!(losses, squared_error/(2*batchsize)); # half the mean squared error, before the step
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
    return (network = trained, cycles = cycles, updates = updates, loss = losses);
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
- `cycles::Int64`: the number of cycles in which a dose was given; 0 if the treatment had already
  ended at the start.
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
# --- PUBLIC METHODS ABOVE HERE --------------------------------------------------------------------------------------- #
