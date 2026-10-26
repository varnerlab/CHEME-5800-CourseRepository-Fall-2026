module L11cGridWorld

using Random: AbstractRNG # the random number generator that drives the rollouts
using LinearAlgebra: I # the identity matrix, for the exact random-policy values

export SlipperyGridWorld, build_slippery_grid, q_value, value_iteration, greedy_policy,
    simulate, rollout_return, random_rollout, random_policy_values

const ACTION_NAMES = ["up", "down", "left", "right", "stay"]; # "stay" is the terminal state's dummy action
const MOVES = Dict(1 => (0, 1), 2 => (0, -1), 3 => (-1, 0), 4 => (1, 0), 5 => (0, 0)); # (Δx, Δy) of each action
const PERPENDICULAR = Dict(1 => (3, 4), 2 => (3, 4), 3 => (1, 2), 4 => (1, 2)); # the two slip directions of each move

"""
    SlipperyGridWorld

The slippery grid world of the L11c lecture, written as an MDP.

### Fields
- `squares::Vector{Tuple{Int,Int}}`: the `(x, y)` square of each state; state `s` is `squares[s]`.
- `index::Dict{Tuple{Int,Int},Int}`: the state of each square.
- `actions::Vector{Vector{Int}}`: the available actions `𝒜ₛ` of each state, numbered as in `ACTION_NAMES`.
- `terminal::Set{Int}`: the terminal states.
- `outcomes::Dict{Tuple{Int,Int},Vector{Tuple{Float64,Int,Float64}}}`: for each available state-action
  pair `(s, a)`, the possible outcomes `(probability, s′, r)` with their observed rewards `r`.
- `T::Array{Float64,3}`: the transition model, `T[s, s′, a]`.
- `R::Array{Float64,2}`: the expected reward `R[s, a]`, averaged over the outcomes.
- `γ::Float64`: the discount factor.
"""
struct SlipperyGridWorld
    squares::Vector{Tuple{Int,Int}}
    index::Dict{Tuple{Int,Int},Int}
    actions::Vector{Vector{Int}}
    terminal::Set{Int}
    outcomes::Dict{Tuple{Int,Int},Vector{Tuple{Float64,Int,Float64}}}
    T::Array{Float64,3}
    R::Array{Float64,2}
    γ::Float64
end

"""
    build_slippery_grid(; γ = 0.9, p_intended = 0.8, goal_reward = 10.0,
        bump_reward = -5.0, step_reward = -1.0) -> SlipperyGridWorld

Build the lecture's ``3 × 3`` grid world: the obstacle is at `(2, 2)` and the terminal goal is at `(3, 3)`.

A move succeeds with probability `p_intended`, and each perpendicular slip happens with probability
`(1 - p_intended)/2`. Entering the goal earns `goal_reward`; bumping into the obstacle earns
`bump_reward` and leaves the robot in place; every other outcome earns `step_reward`, including a slip
off the grid, which also leaves the robot in place. Moves off the grid are unavailable. The goal is
absorbing: its only action, "stay", keeps the robot there and earns zero reward.

### Arguments
- `γ::Float64 = 0.9`: the discount factor, `0 ≤ γ < 1`.
- `p_intended::Float64 = 0.8`: the probability that a move goes in the intended direction.
- `goal_reward`, `bump_reward`, `step_reward`: the observed reward of each kind of outcome.
"""
function build_slippery_grid(; γ::Float64 = 0.9, p_intended::Float64 = 0.8, goal_reward::Float64 = 10.0,
        bump_reward::Float64 = -5.0, step_reward::Float64 = -1.0)::SlipperyGridWorld

    # Initialize -
    obstacle = (2, 2);
    goal = (3, 3);
    squares = [(x, y) for y ∈ 1:3 for x ∈ 1:3 if (x, y) != obstacle]; # the eight traversable squares
    index = Dict(q => s for (s, q) ∈ enumerate(squares));
    N = length(squares); # number of states
    terminal = Set([index[goal]]);
    on_grid(q) = 1 ≤ q[1] ≤ 3 && 1 ≤ q[2] ≤ 3;

    # Where one step in direction m takes the robot from square q, and the observed reward -
    function outcome(q::Tuple{Int,Int}, m::Int)::Tuple{Int,Float64}
        target = q .+ MOVES[m];
        if (on_grid(target) == false)
            return (index[q], step_reward); # a slip off the grid leaves the robot in place
        elseif (target == obstacle)
            return (index[q], bump_reward); # a bump leaves the robot in place
        elseif (target == goal)
            return (index[goal], goal_reward);
        end
        return (index[target], step_reward);
    end

    # The available actions and their outcomes, state by state -
    actions = Vector{Vector{Int}}(undef, N);
    outcomes = Dict{Tuple{Int,Int},Vector{Tuple{Float64,Int,Float64}}}();
    for (s, q) ∈ enumerate(squares)
        if (s ∈ terminal)
            actions[s] = [5]; # the dummy action of an absorbing state
            outcomes[(s, 5)] = [(1.0, s, 0.0)];
            continue;
        end
        actions[s] = [a for a ∈ 1:4 if on_grid(q .+ MOVES[a])]; # moves off the grid are unavailable
        p_slip = (1.0 - p_intended) / 2;
        for a ∈ actions[s]
            (left, right) = PERPENDICULAR[a];
            outcomes[(s, a)] = [(p_intended, outcome(q, a)...), (p_slip, outcome(q, left)...),
                (p_slip, outcome(q, right)...)];
        end
    end

    # The transition model and the expected reward of each available state-action pair -
    T = zeros(N, N, length(ACTION_NAMES));
    R = zeros(N, length(ACTION_NAMES));
    for ((s, a), list) ∈ outcomes
        for (p, s′, r) ∈ list
            T[s, s′, a] += p;
            R[s, a] += p * r;
        end
    end

    return SlipperyGridWorld(squares, index, actions, terminal, outcomes, T, R, γ);
end

"""
    q_value(world::SlipperyGridWorld, U::Vector{Float64}, s::Int, a::Int) -> Float64

The expected return `R(s,a) + γ⋅Σ T(s′|s,a)⋅U(s′)` of taking action `a` in state `s` and then
receiving the values `U`.
"""
function q_value(world::SlipperyGridWorld, U::Vector{Float64}, s::Int, a::Int)::Float64
    return world.R[s, a] + world.γ * sum(world.T[s, s′, a] * U[s′] for s′ ∈ eachindex(U));
end

"""
    value_iteration(world::SlipperyGridWorld; ϵ = 1e-6, k_max = 1000) -> NamedTuple

The L11c value iteration algorithm, maximizing over the available actions `𝒜ₛ` of each state.

Start from `U₀(s) = 0` and replace every value with its Bellman backup until no value changes by more
than `ϵ`, or until `k_max` sweeps; in the second case, log a warning.

### Returns
A `NamedTuple` with the values `U::Vector{Float64}`, the number of sweeps `iterations::Int`, and
`converged::Bool`.
"""
function value_iteration(world::SlipperyGridWorld; ϵ::Float64 = 1e-6, k_max::Int = 1000)::NamedTuple

    # Initialize -
    N = length(world.squares);
    U = zeros(N); # Uₖ(s)
    U_new = zeros(N); # Uₖ₊₁(s)
    k = 0;
    converged = false;

    # Main loop: one sweep over all the states each pass -
    while (converged == false)
        for s ∈ 1:N
            U_new[s] = maximum(q_value(world, U, s, a) for a ∈ world.actions[s]); # the Bellman backup
        end
        if (maximum(abs.(U_new .- U)) ≤ ϵ)
            converged = true;
        elseif (k + 1 ≥ k_max)
            @warn "Value iteration stopped after k_max = $(k_max) sweeps without meeting the tolerance ϵ = $(ϵ)."
            break;
        else
            k = k + 1;
            U .= U_new;
        end
    end

    return (U = copy(U_new), iterations = k + 1, converged = converged);
end

"""
    greedy_policy(world::SlipperyGridWorld, U::Vector{Float64}) -> Vector{Int}

The action of largest `q_value` in each state, breaking ties by the first available action.
"""
function greedy_policy(world::SlipperyGridWorld, U::Vector{Float64})::Vector{Int}
    return [world.actions[s][argmax([q_value(world, U, s, a) for a ∈ world.actions[s]])]
        for s ∈ eachindex(world.squares)];
end

"""
    simulate(world::SlipperyGridWorld, rng::AbstractRNG, s::Int, a::Int) -> Tuple{Int,Float64}

Execute action `a` in state `s` and return the next state `s′` and the observed reward `r`, drawn from
the outcomes of `(s, a)`. This is the only way a random rollout touches the environment.
"""
function simulate(world::SlipperyGridWorld, rng::AbstractRNG, s::Int, a::Int)::Tuple{Int,Float64}

    # Draw one outcome with its probability -
    u = rand(rng);
    cumulative = 0.0;
    list = world.outcomes[(s, a)];
    for (p, s′, r) ∈ list
        cumulative += p;
        if (u < cumulative)
            return (s′, r);
        end
    end
    return (list[end][2], list[end][3]); # guards against rounding in the cumulative sum
end

"""
    rollout_return(world::SlipperyGridWorld, rng::AbstractRNG, s₀::Int, d::Int) -> Float64

One random rollout from `s₀`, steps 1 and 2 of the L11c algorithm: choose actions uniformly from `𝒜ₛ`
and add the discounted observed rewards until the depth `d` is reached or the robot enters a terminal
state. Return the discounted return `G`.
"""
function rollout_return(world::SlipperyGridWorld, rng::AbstractRNG, s₀::Int, d::Int)::Float64

    # Initialize the rollout -
    s = s₀;
    t = 0;
    G = 0.0;
    terminated = (s₀ ∈ world.terminal);

    # Simulate until the depth limit or a terminal state -
    while (terminated == false)
        a = world.actions[s][rand(rng, 1:length(world.actions[s]))]; # a random available action
        (s′, r) = simulate(world, rng, s, a);
        G += world.γ^t * r;
        t += 1;
        if (t ≥ d || s′ ∈ world.terminal)
            terminated = true;
        else
            s = s′;
        end
    end

    return G;
end

"""
    random_rollout(world::SlipperyGridWorld, rng::AbstractRNG, N::Int, d::Int) -> NamedTuple

The L11c random rollout algorithm: `N` rollouts, each from a starting state chosen uniformly from all
states, with depth limit `d`. Each return updates the incremental mean of its starting state.

### Returns
A `NamedTuple` with the estimates `U::Vector{Float64}` and the visit counts `n::Vector{Int}`. A state
that never served as a starting state keeps the estimate zero and the count zero.
"""
function random_rollout(world::SlipperyGridWorld, rng::AbstractRNG, N::Int, d::Int)::NamedTuple

    # Initialize -
    Û = zeros(length(world.squares));
    n = zeros(Int, length(world.squares));

    # N rollouts, each from a uniformly chosen starting state -
    for _ ∈ 1:N
        s₀ = rand(rng, eachindex(world.squares));
        G = rollout_return(world, rng, s₀, d);
        n[s₀] += 1;
        Û[s₀] += (G - Û[s₀]) / n[s₀]; # the incremental mean
    end

    return (U = Û, n = n);
end

"""
    random_policy_values(world::SlipperyGridWorld; d = nothing) -> Vector{Float64}

The exact expected return of the random policy, which picks each available action with equal
probability. With a depth `d`, apply `d` steps of policy evaluation from zero, which gives the expected
return of a rollout stopped after `d` steps. Without one, solve the linear system for the return
without a depth limit.
"""
function random_policy_values(world::SlipperyGridWorld; d::Union{Nothing,Int} = nothing)::Vector{Float64}

    # The random policy's expected reward and transition matrix -
    N = length(world.squares);
    R_π = [sum(world.R[s, a] for a ∈ world.actions[s]) / length(world.actions[s]) for s ∈ 1:N];
    P_π = [sum(world.T[s, s′, a] for a ∈ world.actions[s]) / length(world.actions[s]) for s ∈ 1:N, s′ ∈ 1:N];

    # Without a depth limit: solve (I - γP_π)U = R_π -
    if isnothing(d)
        return (I - world.γ * P_π) \ R_π;
    end

    # With a depth limit: d steps of policy evaluation -
    U = zeros(N);
    for _ ∈ 1:d
        U = R_π .+ world.γ .* (P_π * U);
    end
    return U;
end

end # module L11cGridWorld
