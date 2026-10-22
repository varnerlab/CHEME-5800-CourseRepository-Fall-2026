# =============================================================================
# CHEME 5800 | L10d reference solution: Thompson sampling
# =============================================================================
# The completed my_thompson_sampling(...). Apart from this header, the TODO
# comments, and the completed lines, it matches the student file, Compute.jl,
# and it uses the same module name, so either file can be loaded in place of
# the other. The notebook has no other exercise answers.
# =============================================================================
module L10dThompson

# The names this file uses from other packages, listed so you can see where each comes from -
using Distributions: Beta # the Beta distribution: rand(rng, Beta(x, y)) draws one sample from it
using Random: AbstractRNG # the type of a random number generator, such as MersenneTwister(5800)

export my_thompson_sampling # the one function this module provides

"""
    my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
        α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K)) -> NamedTuple

Play a binary Bernoulli bandit with `K` arms for `T` rounds using Thompson sampling.

Each arm succeeds (reward `1`) with a probability that only the world knows, and fails
(reward `0`) otherwise. The agent describes what it believes about the success probability of
arm `a` with a Beta distribution:

- before any pulls, its belief (the prior) is `Beta(α[a], β[a])`;
- after `S[a]` successes and `F[a]` failures on arm `a`, its updated belief (the posterior) is
  `Beta(α[a] + S[a], β[a] + F[a])`.

In each round `t = 1, 2, ..., T`, the function carries out the four steps of the lecture's
algorithm:

1. Draw one sample `p[a]` from the posterior of every arm `a`.
2. Choose the arm `aₜ` with the largest sample.
3. Pull arm `aₜ` by calling `world(aₜ)`, which returns the reward `rₜ`, `1` or `0`.
4. Update the counts of arm `aₜ`: one more success if `rₜ = 1`, or one more failure if `rₜ = 0`.

With the default prior, an arm the agent has pulled only a few times has a wide posterior, so its
sample is sometimes the largest, even when its posterior mean is lower, and the arm gets pulled
again. This is how Thompson sampling explores.

### Arguments
- `world::Function`: the world. `world(a)` pulls arm `a` and returns its reward, `1` or `0`.
  The agent sees only these rewards, never the success probabilities.
- `K::Int64`: the number of arms, at least 1.
- `T::Int64`: the number of rounds, at least 1.
- `rng::AbstractRNG`: the random number generator for the samples from the posteriors. It has no
  default value, so you must pass one. In the notebook, the agent and the world share one
  generator, so a new generator made from the same seed repeats the whole game.
- `α::Array{Float64,1} = ones(K)`: the first prior parameter of each arm, each positive.
- `β::Array{Float64,1} = ones(K)`: the second prior parameter of each arm, each positive.
  The default, `α[a] = β[a] = 1`, is the uniform distribution on `[0, 1]`: before any pulls, the
  agent treats every success probability as equally likely.

The arguments after the semicolon, `rng`, `α`, and `β`, are keyword arguments: we pass them by
name, for example `my_thompson_sampling(world, 3, 5000, rng = rng)`.

### Returns
A `NamedTuple` with four fields (read one with `result.S`, and so on):
- `actions::Array{Int64,1}`: the arm pulled in each round, `T` entries.
- `rewards::Array{Int64,1}`: the reward received in each round, `1` or `0`, `T` entries.
- `S::Array{Int64,1}`: the number of successes on each arm, `K` entries.
- `F::Array{Int64,1}`: the number of failures on each arm, `K` entries.

Every round adds one success or one failure, so `sum(S) + sum(F)` equals `T`.

### Errors
- Throws an `ArgumentError` if `K` or `T` is less than 1, if `α` or `β` does not have `K`
  entries, if an entry of `α` or `β` is not positive, or if `world` returns a value other than
  `0` or `1`.
- Throws an `ErrorException` if the success and failure counts do not add up to `T` after the
  last round. The untouched student file stops here, because it never updates the counts.

### Example
```julia
θ = [0.90, 0.60, 0.80]; # the success probability of each arm: only the world knows these
rng = MersenneTwister(5800); # one random number generator for the agent and the world
world_function = a -> bernoulli_world(a, θ, rng); # a -> ... defines a function of a: the reward of arm a
result = L10dThompson.my_thompson_sampling(world_function, length(θ), 5000, rng = rng);
result.S .+ result.F # the number of times the agent pulled each arm
```
"""
function my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
    α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K))::NamedTuple

    # check the arguments; this part is complete -
    if K < 1 || T < 1
        throw(ArgumentError("K and T must each be at least 1"));
    end
    if length(α) != K || length(β) != K
        throw(ArgumentError("α and β must each have K entries, one for each arm"));
    end
    for a ∈ 1:K
        if α[a] <= 0 || β[a] <= 0
            throw(ArgumentError("every entry of α and β must be positive"));
        end
    end

    # initialize; this part is complete -
    S = zeros(Int64, K); # the number of successes on each arm, S(a)
    F = zeros(Int64, K); # the number of failures on each arm, F(a)
    actions = zeros(Int64, T); # the arm pulled in each round
    rewards = zeros(Int64, T); # the reward received in each round
    p = zeros(Float64, K); # one sample from the posterior of each arm, p(a); we refill it every round

    # main loop: one round of the game for each value of t -
    for t ∈ 1:T

        # Step 1: draw one sample from the posterior of each arm -
        for a ∈ 1:K
            # TODO 1: a sample from Beta(α(a) + S(a), β(a) + F(a)) -
            p[a] = rand(rng, Beta(α[a] + S[a], β[a] + F[a]));
        end

        # Step 2: choose the arm with the largest sample -
        # TODO 2: argmax(p) is the index of the largest entry of p -
        aₜ = argmax(p);

        # Step 3: pull the arm and receive the reward; this part is complete -
        rₜ = world(aₜ); # 1 for a success, 0 for a failure
        if rₜ != 0 && rₜ != 1
            throw(ArgumentError("world($(aₜ)) returned $(rₜ); a reward must be 0 or 1")); # $(...) puts a value into the text
        end
        actions[t] = aₜ; # store the arm we pulled in round t
        rewards[t] = rₜ; # store the reward we received in round t

        # Step 4: update the success and failure counts of the arm we pulled -
        # TODO 3: a success adds 1 to S(aₜ); a failure adds 1 to F(aₜ) -
        S[aₜ] = S[aₜ] + rₜ;
        F[aₜ] = F[aₜ] + (1 - rₜ);
    end

    # We get here after T rounds. Every round adds 1 to S or F, so their total must be T.
    # This part is complete -
    if sum(S) + sum(F) != T
        throw(ErrorException("Oooops! The `my_thompson_sampling(...)` function is not implemented yet - we'd better fix that. Complete TODO 1 through TODO 3."));
    end

    # return the history of the game and the final counts, as a NamedTuple -
    return (actions = actions, rewards = rewards, S = S, F = F);
end

end # module L10dThompson
