# ================================================================================================ #
# MDP.jl
#
# Markov decision processes (MDPs): value iteration, the action values Q(s,a), the policy, and two
# helpers for random rollouts on a grid world. The week 11 notebooks (the L11c random rollout
# example and the L11d value iteration lab) and the week 12 Q-learning notebooks (L12a, L12b) call
# these functions.
#
# An MDP is the tuple (𝒮, 𝒜, R(s,a), T(s′|s,a), γ). A MyMDPProblemModel `p` stores it as:
#   p.𝒮           the states s, numbered 1, 2, …, |𝒮|
#   p.𝒜           the actions a, numbered 1, 2, …, |𝒜|
#   p.R[s,a]      the reward R(s,a) of taking action a in state s
#   p.T[s,s′,a]   the probability T(s′|s,a) that action a in state s leads to state s′
#   p.γ           the discount factor γ, with 0 ≤ γ < 1
# The functions below use a state or an action directly as a row or column index, so they need
# this numbering. They also need R and T stored as arrays, not as functions.
#
# A value function U holds one number per state: U[s] is the value of state s. Value iteration
# builds U_1, U_2, … from U_0(s) = 0, and U_k approaches the optimal value function U* as k grows.
#
# Functions in this file:
#   myrandpolicy(...)                 a random action that keeps the robot on the grid
#   myrandstep(...)                   the next state and the reward of one move on the grid
#   lookahead(...)                    the value of one action in one state, R(s,a) + γ⋅Σ T(s′|s,a)⋅U(s′)
#   Q(...)                            the action value Q(s,a) of every state and action
#   policy(...)                       the action with the largest Q(s,a) in each state
#   backup(...)                       the Bellman backup of one state: the largest lookahead value
#   solve(...)                        value iteration: exactly k_max sweeps of the Bellman backup
#   iterative_policy_evaluation(...)  the values of a fixed policy, by exactly k_max sweeps
#   greedy(...)                       the best action in one state, and its lookahead value
#   (π::MyValueFunctionPolicy)(s)     call the result of solve(...) like a function to get its action in state s
# ================================================================================================ #

"""
    myrandpolicy(problem::MyMDPProblemModel, world::MyRectangularGridWorldModel, s::Int) -> Int

Choose a random action in state `s` that keeps the robot on the grid.

The function draws one of the four actions `1, 2, 3, 4`, each with probability 1/4, and looks up
the square that the action moves the robot to. If that square is on the grid, the function
returns the action. If not, it draws again. So each action that keeps the robot on the grid is
equally likely. The L11c random rollout example calls this function at every step of a rollout.

The draws come from Julia's global random number generator, so call `Random.seed!(...)` before a
run to make it repeatable. The function always draws from four actions: it does not read the
number of actions from `problem`.

### Arguments
- `problem::MyMDPProblemModel`: the MDP. We do not use it here.
- `world::MyRectangularGridWorldModel`: the grid world. We use its `coordinates` dictionary, which
  maps a state to its `(x, y)` square; its `states` dictionary, which maps a square to its state;
  and its `moves` dictionary, which maps an action to a change in position `(Δx, Δy)`.
- `s::Int`: the current state.

### Returns
- `Int`: an action whose move keeps the robot on the grid.
"""
function myrandpolicy(problem::MyMDPProblemModel,
    world::MyRectangularGridWorldModel, s::Int)::Int

    # initialize: a categorical distribution (from the Distributions package) that picks
    # 1, 2, 3, or 4, each with probability 0.25 -
    d = Categorical([0.25,0.25,0.25,0.25]);

    # we keep drawing until the move stays on the grid -
    should_choose_gain = true; # true while we still need to draw an action
    a = -1; # the action we return; -1 until we find one that stays on the grid
    while (should_choose_gain == true)

        # draw a random action from the distribution -
        aᵢ = rand(d);

        # get the move, and the current location -
        Δ = world.moves[aᵢ]; # the change in position (Δx, Δy) for action aᵢ
        current_position = world.coordinates[s] # the (x, y) square of state s
        new_position =  current_position .+ Δ # the dot adds the two tuples entry by entry: (x + Δx, y + Δy)

        # the new square has a state only if it is on the grid. If so, we keep this action and stop drawing -
        if (haskey(world.states, new_position) == true)
            a = aᵢ
            should_choose_gain = false;
        end
    end

    # return the action -
    return a;
end;

"""
    myrandstep(problem::MyMDPProblemModel, world::MyRectangularGridWorldModel, s::Int, a::Int) -> Tuple{Int,Float64}

Take action `a` in state `s` on the grid, and return the next state `s′` and the reward `r`.

The reward is `r = R(s,a)`, read from `problem.R[s,a]`. The next state is the square that the
move of action `a` points to. If that square is off the grid, the robot stays where it is, so
`s′ = s`. The move itself is not random: the function does not read the transition
probabilities `T(s′|s,a)` and draws no random numbers. In a rollout, only the action is random,
because it comes from `myrandpolicy(...)`.

### Arguments
- `problem::MyMDPProblemModel`: the MDP. We use its reward array `R`.
- `world::MyRectangularGridWorldModel`: the grid world. We use its `coordinates`, `states`, and
  `moves` dictionaries, as in `myrandpolicy(...)`.
- `s::Int`: the state we are in.
- `a::Int`: the action we take.

### Returns
- `Tuple{Int,Float64}`: the tuple `(s′, r)` of the next state and the reward of taking action `a`
  in state `s`.
"""
function myrandstep(problem::MyMDPProblemModel,
    world::MyRectangularGridWorldModel, s::Int, a::Int)

    # get the reward R(s,a) of taking action a in state s -
    r = problem.R[s,a];

    # get the move, and the current location -
    Δ = world.moves[a]; # the change in position (Δx, Δy) for action a
    current_position = world.coordinates[s] # the (x, y) square of state s

    # propose a new position: the dot adds the two tuples entry by entry, (x + Δx, y + Δy) -
    new_position =  current_position .+ Δ
    s′ = s; # default: if the move leaves the grid, we stay in state s
    if (haskey(world.states, new_position) == true) # the new square has a state only if it is on the grid
        s′ = world.states[new_position]; # the state of the new square
    end

    # return the next state and the reward -
    return (s′,r)
end;

"""
    lookahead(p::MyMDPProblemModel, U::Vector{Float64}, s::Int64, a::Int64) -> Float64

Compute the lookahead value of taking action `a` in state `s`, given the value function `U`:

    R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U(s′)

The first term is the reward of the move. The second term is the value of the next state,
averaged over the possible next states `s′` with their probabilities `T(s′|s,a)`, and discounted
by `γ`. The Bellman backup, `backup(...)`, takes the largest of these values over the actions.

### Arguments
- `p::MyMDPProblemModel`: the MDP. We use its states `𝒮`, rewards `R`, transition array `T`, and
  discount factor `γ`.
- `U::Vector{Float64}`: the value function, one entry per state: `U[i]` is the value of the
  `i`-th state in `p.𝒮`.
- `s::Int64`: the state.
- `a::Int64`: the action.

### Returns
- `Float64`: the lookahead value of the pair `(s, a)`.
"""
function lookahead(p::MyMDPProblemModel, U::Vector{Float64}, s::Int64, a::Int64)::Float64

    # get the parts of the MDP we need -
    R = p.R;  # the rewards: R[s,a] is the reward of taking action a in state s
    T = p.T; # the transition probabilities: T[s,s′,a] is the probability that action a moves us from s to s′
    γ = p.γ; # the discount factor
    𝒮 = p.𝒮; # the states

    # compute the lookahead value and return it -
    # The generator inside sum(...) runs over the states: enumerate(𝒮) gives each position i
    # together with the state s′ = 𝒮[i], and sum(...) adds up T[s,s′,a]*U[i] over all of them.
    return R[s,a] + γ*sum(T[s,s′,a]*U[i] for (i,s′) in enumerate(𝒮))
end

"""
    lookahead(p::MyMDPProblemModel, U::Function, s::Int64, a::Int64) -> Float64

Compute the same lookahead value as the method above,

    R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U(s′)

when the value function `U` is a Julia function rather than a vector. We call `U(s′)` to get
the value of state `s′`.

### Arguments
- `p::MyMDPProblemModel`: the MDP. We use its states `𝒮`, rewards `R`, transition array `T`, and
  discount factor `γ`.
- `U::Function`: the value function: `U(s′)` returns the value of state `s′`.
- `s::Int64`: the state.
- `a::Int64`: the action.

### Returns
- `Float64`: the lookahead value of the pair `(s, a)`, when `U` returns `Float64` values.
"""
function lookahead(p::MyMDPProblemModel, U::Function, s::Int64, a::Int64)

    # get the parts of the MDP we need. This one line unpacks four fields at once:
    # 𝒮 = p.𝒮, T = p.T, R = p.R, and γ = p.γ -
    𝒮, T, R, γ = p.𝒮, p.T, p.R, p.γ;

    # compute the lookahead value and return it. The generator inside sum(...) adds up
    # T[s,s′,a]*U(s′) over every state s′ in 𝒮 -
    return R[s,a] + γ*sum(T[s,s′,a]*U(s′) for s′ in 𝒮)
end


"""
    Q(p::MyMDPProblemModel, U::Array{Float64,1}) -> Array{Float64,2}

Compute the action value `Q(s,a)` of every state `s` and action `a` from a value function `U`:

    Q(s,a) = R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U(s′)

`Q(s,a)` is the reward of taking action `a` in state `s`, plus the discounted value of the next
state, averaged over the possible next states. When `U` is the optimal value function `U*`, the
result is the optimal action value `Q*(s,a)`. This is the formula of `lookahead(...)`, computed
for every pair `(s,a)`.

### Arguments
- `p::MyMDPProblemModel`: the MDP. We use its states `𝒮`, actions `𝒜`, rewards `R`, transition
  array `T`, and discount factor `γ`.
- `U::Array{Float64,1}`: the value function, one entry per state: `U[s]` is the value of state `s`.

### Returns
- `Array{Float64,2}`: the action values, one row per state and one column per action: entry
  `[s,a]` is `Q(s,a)`.
"""
function Q(p::MyMDPProblemModel, U::Array{Float64,1})::Array{Float64,2}

    # get the parts of the MDP we need -
    R = p.R;  # the rewards: R[s,a] is the reward of taking action a in state s
    T = p.T; # the transition probabilities: T[s,s′,a]
    γ = p.γ; # the discount factor
    𝒮 = p.𝒮; # the states
    𝒜 = p.𝒜 # the actions

    # initialize: an |𝒮|-by-|𝒜| array. The undef means the entries start as whatever is in
    # memory; the loops below fill every entry, because the states and actions are numbered from 1 -
    Q_array = Array{Float64,2}(undef, length(𝒮), length(𝒜))

    # compute the Q-value function: one entry for each state s and each action a -
    for i ∈ eachindex(𝒮) # eachindex(𝒮) gives the positions 1, 2, …, |𝒮| of the array 𝒮
        s = 𝒮[i]; # get the state s
        for j ∈ eachindex(𝒜)
            a = 𝒜[j]; # get the action a

            # compute the Q-value -
            # We take the reward of action a in state s, and add γ times the values U[s′] of the
            # next states, each weighted by its probability T[s,s′,a]. The comprehension
            # [... for s′ in 𝒮] builds an array with one term per next state s′, and sum(...) adds them up.
            Q_array[s,a] = R[s,a] + γ*sum([T[s,s′,a]*U[s′] for s′ in 𝒮]);
        end
    end

    # return the action values -
    return Q_array
end

"""
    policy(Q_array::Array{Float64,2}) -> Array{Int64,1}

Compute the policy `π(s) = argmax_a Q(s,a)`: in each state, the action with the largest action value.

`Q_array` has one row per state and one column per action, so the policy picks the column of the
largest entry in each row. When several actions tie for the largest value, `argmax` returns the
first of them, the one with the smallest action number. When `Q_array` holds the optimal action
values `Q*(s,a)`, the result is the optimal policy `π*`.

### Arguments
- `Q_array::Array{Float64,2}`: the action values, one row per state and one column per action,
  e.g., the output of `Q(...)` or a table learned by Q-learning.

### Returns
- `Array{Int64,1}`: the policy, one entry per state: entry `s` is the action `π(s)`.

### Example
```julia
policy([1.0 3.0; 2.0 0.5]) # returns [2, 1]: action 2 in state 1, and action 1 in state 2
```
"""
function policy(Q_array::Array{Float64,2})::Array{Int64,1}

    # get the dimension: NR is the number of rows, one per state. The _ discards the number of columns -
    (NR, _) = size(Q_array);

    # initialize: an array with one entry per state, filled in below -
    π_array = Array{Int64,1}(undef, NR)

    # main loop: in each state, pick the column (action) with the largest action value -
    for s ∈ 1:NR
        π_array[s] = argmax(Q_array[s,:]); # Q_array[s,:] is row s; argmax gives the position of its largest entry
    end

    # return the policy -
    return π_array;
end

"""
    backup(problem::MyMDPProblemModel, U::Array{Float64,1}, s::Int64) -> Float64

Compute the Bellman backup of state `s`: the largest lookahead value over the actions,

    U_{k+1}(s) = max_{a ∈ 𝒜} ( R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U_k(s′) )

Here `U_k` is the value function passed in as `U`, and the result is the new value `U_{k+1}(s)`
of state `s`. Value iteration, `solve(...)`, applies this backup to every state in each sweep.

### Arguments
- `problem::MyMDPProblemModel`: the MDP.
- `U::Array{Float64,1}`: the current value function `U_k`, one entry per state.
- `s::Int64`: the state.

### Returns
- `Float64`: the new value `U_{k+1}(s)`, the largest lookahead value over the actions.
"""
function backup(problem::MyMDPProblemModel, U::Array{Float64,1}, s::Int64)::Float64

    # compute the lookahead value of each action a in 𝒜, and return the largest. The generator
    # inside maximum(...) calls lookahead(...) once for each action -
    return maximum(lookahead(problem, U, s, a) for a ∈ problem.𝒜);
end

"""
    solve(model::MyValueIterationModel, problem::MyMDPProblemModel) -> MyValueFunctionPolicy

Estimate the optimal value function `U*` of an MDP by value iteration, with a fixed number of sweeps.

We start from `U_0(s) = 0` for every state. Then we apply the Bellman backup to every state,

    U_{k+1}(s) = max_{a ∈ 𝒜} ( R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U_k(s′) )

for `k = 0, 1, …, k_max − 1`. One pass over all the states is one sweep. Each sweep computes
every new value from the previous sweep's values `U_k`, and then replaces `U_k` with `U_{k+1}`.

The function always runs exactly `k_max` sweeps. It does not check whether the values have
stopped changing, and it never stops early. For `0 ≤ γ < 1`, `U_k` approaches `U*` as `k`
grows, so a large `k_max` gives values close to `U*`. This version follows the value iteration
function of the Algorithms for Decision Making book; the L11d lab adds a convergence check.

### Arguments
- `model::MyValueIterationModel`: holds `k_max`, the number of sweeps.
- `problem::MyMDPProblemModel`: the MDP `(𝒮, 𝒜, R(s,a), T(s′|s,a), γ)`.

### Returns
- `MyValueFunctionPolicy`: a struct with two fields: `problem`, the MDP we solved, and `U`, the
  values after `k_max` sweeps, one entry per state. The struct can be called like a function:
  `π(s)` returns the greedy action in state `s` (see the last method in this file).
"""
function solve(model::MyValueIterationModel, problem::MyMDPProblemModel)::MyValueFunctionPolicy

    # get the number of sweeps from the model -
    k_max = model.k_max;

    # initialize: U_0(s) = 0 for every state. The comprehension [0.0 for _ ∈ problem.𝒮] makes a
    # vector with one 0.0 per state; the _ means we do not use the state itself -
    U = [0.0 for _ ∈ problem.𝒮];

    # main loop: exactly k_max sweeps, with no convergence check -
    for _ ∈ 1:k_max

        # one sweep: the comprehension computes backup(...) for every state from the old U, and
        # collects the results in a new vector, which then replaces U -
        U = [backup(problem, U, s) for s ∈ problem.𝒮];
    end

    # return the MDP and the values together, as a MyValueFunctionPolicy -
    return MyValueFunctionPolicy(problem, U);
end

"""
    iterative_policy_evaluation(p::MyMDPProblemModel, π, k_max::Int) -> Array{Float64,1}

Compute the value function of a fixed policy `π` by repeated sweeps.

The policy chooses the action `π(s)` in each state, so there is no maximum over actions. We start
from `U_0(s) = 0` and apply, to every state,

    U_{k+1}(s) = R(s,π(s)) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,π(s))⋅U_k(s′)

for exactly `k_max` sweeps, with no convergence check. For `0 ≤ γ < 1`, `U_k` approaches the value
of the policy as `k` grows: the expected discounted reward of following `π` from each state.

### Arguments
- `p::MyMDPProblemModel`: the MDP.
- `π`: the policy: anything we can call as `π(s)` to get the action in state `s`, e.g., a Julia
  function or the `MyValueFunctionPolicy` returned by `solve(...)`.
- `k_max::Int`: the number of sweeps.

### Returns
- `Array{Float64,1}`: the values after `k_max` sweeps, one entry per state.
"""
function iterative_policy_evaluation(p::MyMDPProblemModel, π, k_max::Int)

    # get the parts of the MDP. Only 𝒮 is used below; lookahead(...) reads R, T, and γ from p itself -
    R = p.R;  # the rewards: R[s,a]
    T = p.T; # the transition probabilities: T[s,s′,a]
    γ = p.γ; # the discount factor
    𝒮 = p.𝒮; # the states

    # initialize: U_0(s) = 0 for every state -
    U = [0.0 for s ∈ 𝒮];

    # main loop: exactly k_max sweeps. Each sweep builds a new vector from the old U: for each
    # state s, the lookahead value of the action π(s) that the policy chooses -
    for _ ∈ 1:k_max
        U = [lookahead(p, U, s, π(s)) for s ∈ 𝒮]
    end

    # return the values of the policy -
    return U;
end

"""
    greedy(problem::MyMDPProblemModel, U::Array{Float64,1}, s::Int64) -> NamedTuple

Find the greedy action in state `s`: the action with the largest lookahead value,

    argmax_{a ∈ 𝒜} ( R(s,a) + γ⋅Σ_{s′ ∈ 𝒮} T(s′|s,a)⋅U(s′) )

and return it together with its lookahead value. When `U` is the optimal value function `U*`, the
action is an optimal action `π*(s)` and its value is `U*(s)`. When several actions tie, we keep
the first.

### Arguments
- `problem::MyMDPProblemModel`: the MDP.
- `U::Array{Float64,1}`: the value function, one entry per state.
- `s::Int64`: the state.

### Returns
A `NamedTuple` with the fields:
- `a::Int64`: the greedy action. `findmax` returns the position of the action in `problem.𝒜`,
  which equals the action because the actions are numbered `1, 2, …, |𝒜|`.
- `u::Float64`: the lookahead value of that action.
"""
function greedy(problem::MyMDPProblemModel, U::Array{Float64,1}, s::Int64)

    # findmax(f, collection) calls f on every entry of the collection, and returns the largest
    # value and its position. Here f is the anonymous function a -> lookahead(problem, U, s, a),
    # which gives the lookahead value of action a, and the collection is the actions 𝒜 -
    u, a = findmax(a->lookahead(problem, U, s, a), problem.𝒜);

    # return the action and its value, as a NamedTuple with the fields a and u -
    return (a=a, u=u)
end

"""
    (π::MyValueFunctionPolicy)(s::Int64) -> Int64

Call a `MyValueFunctionPolicy` like a function: `π(s)` returns the greedy action in state `s`.

This one line gives the struct `MyValueFunctionPolicy` a method, so that an instance `π`, such as
the result of `solve(...)`, can be called as `π(s)`. The call returns the field `a` of
`greedy(π.problem, π.U, s)`: the action with the largest lookahead value under the values `π.U`.

### Arguments
- `π::MyValueFunctionPolicy`: the policy, which holds the MDP (`π.problem`) and the values (`π.U`).
- `s::Int64`: the state.

### Returns
- `Int64`: the greedy action in state `s`.
"""
(π::MyValueFunctionPolicy)(s::Int64) = greedy(π.problem, π.U, s).a; # .a picks the action out of the NamedTuple that greedy(...) returns
