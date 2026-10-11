# =============================================================================
# CHEME 5800 | L10d reference solution: Thompson sampling
# =============================================================================
# The completed my_thompson_sampling(...). Apart from this header, the TODO
# comments, and the completed lines, it matches the student file, Compute.jl,
# and it uses the same module name, so either file can be loaded in place of
# the other. The notebook has no other exercise answers.
# =============================================================================
module L10dThompson

import Distributions: Beta # the Beta distribution: rand(rng, Beta(α, β)) draws one sample
import Random: AbstractRNG # the type of a random number generator, such as MersenneTwister(5800)

export my_thompson_sampling

"""
    my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
        α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K)) -> NamedTuple

Play a binary Bernoulli bandit with `K` arms for `T` rounds using Thompson sampling, the
algorithm from the L10c lecture.

The agent models the unknown success probability of arm `a` with a Beta distribution. Its
belief before any pulls, the prior, is `Beta(α[a], β[a])`; after `S[a]` successes and `F[a]`
failures on arm `a`, its updated belief, the posterior, is `Beta(α[a] + S[a], β[a] + F[a])`.
In each round it draws one sample from the posterior of every arm, pulls the arm with the
highest sample, receives a reward of `1` (success) or `0` (failure) from `world`, and adds
the reward to the success or failure count of that arm.

### Arguments
- `world::Function`: the world. `world(a)` pulls arm `a` and returns its reward, `1` or `0`.
  The agent does not know the success probabilities the world uses.
- `K::Int64`: the number of arms, at least 1.
- `T::Int64`: the number of rounds, at least 1.
- `rng::AbstractRNG`: the random number generator for the samples from the posteriors.
  Required, so a run can be repeated exactly.
- `α::Array{Float64,1} = ones(K)`: the first Beta prior parameter of each arm, each positive.
- `β::Array{Float64,1} = ones(K)`: the second Beta prior parameter of each arm, each positive.
  With `α = β = 1`, every prior is uniform on `[0, 1]`.

### Returns
A `NamedTuple` with the fields:
- `actions::Array{Int64,1}`: the arm pulled in each round, `T` entries.
- `rewards::Array{Int64,1}`: the reward received in each round, `1` or `0`, `T` entries.
- `S::Array{Int64,1}`: the number of successes on each arm, `K` entries.
- `F::Array{Int64,1}`: the number of failures on each arm, `K` entries.

### Errors
Throws an `ArgumentError` if `K` or `T` is less than 1, `α` or `β` does not have `K`
positive entries, or `world` returns a value other than `0` or `1`.

### Example
```julia
rng = MersenneTwister(5800); # one random number generator for the agent and the world
world_function(a) = bernoulli_world(a, θ, rng); # the reward of arm a: 1 with probability θ[a], else 0
result = L10dThompson.my_thompson_sampling(world_function, length(θ), 5000, rng = rng);
result.S, result.F
```
"""
function my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
    α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K))::NamedTuple

    # Check the arguments; this part is complete -
    if K < 1 || T < 1
        throw(ArgumentError("K and T must each be at least 1"))
    end
    if length(α) != K || length(β) != K || !all(α .> 0) || !all(β .> 0)
        throw(ArgumentError("α and β must each have K positive entries"))
    end

    # Initialize; this part is complete -
    S = zeros(Int64, K); # successes on each arm, S(a)
    F = zeros(Int64, K); # failures on each arm, F(a)
    actions = zeros(Int64, T); # the arm pulled in each round
    rewards = zeros(Int64, T); # the reward received in each round
    p = zeros(K); # one sample from the posterior of each arm, p(a)

    # Main loop: one round of the game for each value of t -
    for t ∈ 1:T

        # Step 1: sample from the posterior of each arm -
        for a ∈ 1:K
            # TODO 1: a sample from Beta(α(a) + S(a), β(a) + F(a)) -
            p[a] = rand(rng, Beta(α[a] + S[a], β[a] + F[a]));
        end

        # TODO 2: the arm with the highest sample -
        aₜ = argmax(p);

        # Step 3: pull the arm and receive the reward; this part is complete -
        rₜ = world(aₜ); # 1 for a success, 0 for a failure
        if !(rₜ == 0 || rₜ == 1)
            throw(ArgumentError("world($(aₜ)) returned $(rₜ); a reward must be 0 or 1"))
        end
        actions[t] = aₜ; # store the arm
        rewards[t] = rₜ; # store the reward

        # TODO 3: update the success and failure counts of the arm we pulled -
        S[aₜ] = S[aₜ] + rₜ;
        F[aₜ] = F[aₜ] + (1 - rₜ);
    end

    # We get here after T rounds. Every round adds 1 to S or F, so their total must be T.
    # This part is complete -
    if sum(S) + sum(F) != T
        throw(ErrorException("Oooops! The `my_thompson_sampling(...)` function is not implemented yet - " *
                             "we'd better fix that. Complete TODO 1 through TODO 3."))
    end
    return (actions = actions, rewards = rewards, S = S, F = F);
end

end # module L10dThompson
