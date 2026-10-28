# =============================================================================
# CHEME 5800 | L10d supplied helpers: the Bernoulli world and repeated bandit games
# =============================================================================
# bernoulli_world(...) is the world in Task 3: it returns a reward of 1 or 0.
# compare_bandits(...) plays explore-first, epsilon-greedy, and UCB1 many times,
# with different seeds and numbers of rounds, for Task 2.
# You do not need to edit this file; your work is in Compute.jl. Include.jl
# loads this file only once, so if you do edit it, restart the kernel.
# =============================================================================
module L10dUtility

# The names this file uses from other packages, listed so you can see where each comes from -
import Random # we call Random.seed!(...) by its full name, as in the notebook
using Random: AbstractRNG # the type of a random number generator, such as MersenneTwister(5800)
using Distributions: Distribution, Bernoulli # the type every distribution belongs to, and the Bernoulli distribution
using Statistics: mean, std # the average and the standard deviation
using VLDataScienceMachineLearningPackage: build, solve # build an algorithm, then play a game with it
using VLDataScienceMachineLearningPackage: MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel,
    MyUCB1AlgorithmModel # the three bandit algorithms from the course package

export bernoulli_world, compare_bandits # the two functions this module provides

"""
    bernoulli_world(a::Int64, θ::Array{Float64,1}, rng::AbstractRNG) -> Int64

Pull arm `a` of a binary Bernoulli bandit and return its reward: `1` (a success) with
probability `θ[a]`, and `0` (a failure) otherwise.

This is the world in Task 3. The success probabilities `θ` belong to the world; the agent never
sees them, only the reward this function returns.

### Arguments
- `a::Int64`: the arm to pull, a number from `1` to `length(θ)`.
- `θ::Array{Float64,1}`: the success probability of each arm, each between `0` and `1`.
- `rng::AbstractRNG`: the random number generator that draws the reward. A new generator made
  from the same seed gives the same rewards for the same sequence of pulls.

### Returns
- `Int64`: the reward, `1` or `0`.

### Errors
Throws a `BoundsError` if `a` is not between `1` and `length(θ)`, and a `DomainError` if `θ[a]`
is not between `0` and `1`.

### Side effect
Each call draws one random number, which moves `rng` forward.

### Example
```julia
θ = [0.90, 0.60, 0.80]; # the success probabilities of three arms
rng = MersenneTwister(5800); # a random number generator with a fixed seed
r = bernoulli_world(1, θ, rng); # 1 with probability 0.90, 0 with probability 0.10
```
"""
function bernoulli_world(a::Int64, θ::Array{Float64,1}, rng::AbstractRNG)::Int64

    # draw one Bernoulli random variable: true with probability θ[a], false otherwise -
    success = rand(rng, Bernoulli(θ[a]));

    # turn true or false into the reward 1 or 0 -
    if success == true
        return 1;
    else
        return 0;
    end
end

"""
    compare_bandits(arms::Array{<:Distribution,1}, horizons::Array{Int64,1},
        seeds::Array{Int64,1}) -> NamedTuple

Play the explore-first, epsilon-greedy, and UCB1 algorithms on the same bandit many times, and
measure how much reward each algorithm gives up.

For every horizon `T` in `horizons` (the number of rounds in a game), every algorithm, and every
seed in `seeds`, the function sets the seed, plays a new game of `T` rounds, and records two
numbers for that game:

- the **gap loss**, `G = Σₜ (μ⋆ - μ(aₜ))`. Each pull is charged the gap of the arm it chose, how
  much less that arm earns on average than the best arm, so a pull of the best arm costs nothing.
- the **realized regret**, `R = T⋅μ⋆ - Σₜ rₜ`: the expected reward from always pulling the best
  arm, minus the rewards the algorithm actually received.

Here `μ(a)` is the true mean reward of arm `a`, `μ⋆` is the largest of them, `aₜ` is the arm pulled
in round `t`, and `rₜ` is its reward. We can compute both numbers because we know the true means;
the algorithms never see them. The two numbers have the same expected value, so their averages
over many games should agree.

Each horizon starts a new game, rather than reading the first rounds of a longer game, because
the explore-first algorithm uses `T` to decide how long to explore. The three algorithms start
from the same seed, but they use random numbers differently, so they do not see the same rewards.

### Arguments
- `arms::Array{<:Distribution,1}`: the reward distribution of each arm. `<:Distribution` means any
  kind of distribution, such as `Beta` or `Bernoulli`. Every reward must lie between `0` and `1`.
- `horizons::Array{Int64,1}`: the numbers of rounds to try, each at least the number of arms.
- `seeds::Array{Int64,1}`: the random number seeds, one game per seed; at least two, all different.

### Returns
A `NamedTuple` with these fields:
- `labels::Array{String,1}`: the algorithm names, `"Explore-first"`, `"ε-greedy"`, and `"UCB1"`.
- `horizons` and `seeds`: the inputs, so the results record how they were made.
- `gap_regrets::Array{Float64,3}`: the gap loss of every game. Entry `[h, j, s]` is the game with
  horizon `horizons[h]`, algorithm `labels[j]`, and seed `seeds[s]`.
- `realized_regrets::Array{Float64,3}`: the realized regret of every game, in the same layout.
- `mean_gap::Array{Float64,2}`: the average gap loss over the seeds. Entry `[h, j]` is horizon
  `horizons[h]` and algorithm `labels[j]`.
- `sd_gap::Array{Float64,2}`: the standard deviation of the gap loss over the seeds, which
  measures how much the gap loss varies from game to game.
- `se_gap::Array{Float64,2}`: the standard error of the average gap loss, the standard deviation
  divided by the square root of the number of seeds. It measures how precisely the games pin down
  the average.
- `mean_realized::Array{Float64,2}`: the average realized regret over the seeds.

Rewards and regrets have no units.

### Errors
Throws an `ArgumentError` if `arms` is empty, if a reward distribution reaches outside `[0, 1]`,
if `horizons` is empty, if a horizon is smaller than the number of arms, or if `seeds` has fewer
than two entries or a repeated entry.

### Side effect
Each game calls `Random.seed!(seed)`, which resets Julia's global random number generator.

### Example
```julia
arms = [Beta(2.0, 2.0), Beta(10.0, 2.0)]; # two arms; the second has the higher mean reward
ensemble = compare_bandits(arms, [100, 1000], [1, 2, 3]); # 2 horizons × 3 algorithms × 3 seeds = 18 games
ensemble.mean_gap # a 2 × 3 matrix: one row per horizon, one column per algorithm
```
"""
function compare_bandits(arms::Array{<:Distribution,1}, horizons::Array{Int64,1},
    seeds::Array{Int64,1})::NamedTuple

    # check the arguments -
    K = length(arms); # the number of arms
    if K < 1
        throw(ArgumentError("supply at least one arm"));
    end
    for a ∈ 1:K
        if minimum(arms[a]) < 0 || maximum(arms[a]) > 1 # the smallest and largest possible rewards of arm a
            throw(ArgumentError("every reward must lie between 0 and 1, but arm $(a) can fall outside [0, 1]"));
        end
    end
    if length(horizons) < 1
        throw(ArgumentError("supply at least one horizon"));
    end
    for T ∈ horizons
        if T < K
            throw(ArgumentError("every horizon must be at least the number of arms, K = $(K)"));
        end
    end
    if length(seeds) < 2 || length(unique(seeds)) != length(seeds) # unique(...) drops repeated seeds
        throw(ArgumentError("supply at least two seeds, all different"));
    end

    # initialize -
    labels = ["Explore-first", "ε-greedy", "UCB1"]; # the names of the three algorithms
    models = [MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel]; # their types, in the same order
    number_of_horizons = length(horizons);
    number_of_algorithms = length(models);
    number_of_seeds = length(seeds);
    μ = zeros(Float64, K); # the true mean reward of each arm: we know it, the algorithms do not
    for a ∈ 1:K
        μ[a] = mean(arms[a]);
    end
    μstar = maximum(μ); # μ⋆, the mean reward of the best arm
    gap_regrets = zeros(Float64, number_of_horizons, number_of_algorithms, number_of_seeds); # one entry per game
    realized_regrets = zeros(Float64, number_of_horizons, number_of_algorithms, number_of_seeds); # one entry per game

    # main loop: play one game for each horizon, algorithm, and seed -
    for h ∈ 1:number_of_horizons
        T = horizons[h]; # the number of rounds in this game
        for j ∈ 1:number_of_algorithms
            for s ∈ 1:number_of_seeds

                # set the seed, so this game can be repeated exactly -
                Random.seed!(seeds[s]);

                # play the game, as in the Task 1 cells of the notebook -
                world = a -> rand(arms[a]); # a -> ... defines a function of a: world(a) draws one reward from arms[a]
                model = build(models[j], (K = K,)); # (K = K,) is a NamedTuple with one field; the comma makes it a tuple
                game = solve(model, T = T, world = world, return_history = true); # game.actions and game.rewards

                # gap loss: add up the gap of the arm pulled in each round -
                gap = 0.0;
                for t ∈ 1:T
                    aₜ = game.actions[t]; # the arm pulled in round t
                    gap = gap + (μstar - μ[aₜ]);
                end
                gap_regrets[h, j, s] = gap;

                # realized regret: T⋅μ⋆ minus the total reward received -
                total_reward = sum(game.rewards); # row t holds the reward of round t in the column of the pulled arm, and zeros elsewhere
                realized_regrets[h, j, s] = T*μstar - total_reward;
            end
        end
    end

    # summarize each horizon and algorithm over the seeds -
    mean_gap = zeros(Float64, number_of_horizons, number_of_algorithms);
    sd_gap = zeros(Float64, number_of_horizons, number_of_algorithms);
    se_gap = zeros(Float64, number_of_horizons, number_of_algorithms);
    mean_realized = zeros(Float64, number_of_horizons, number_of_algorithms);
    for h ∈ 1:number_of_horizons
        for j ∈ 1:number_of_algorithms
            gaps = gap_regrets[h, j, :]; # the : picks every seed, so gaps holds one gap loss per seed
            mean_gap[h, j] = mean(gaps); # the average gap loss
            sd_gap[h, j] = std(gaps); # how much the gap loss varies from game to game
            se_gap[h, j] = sd_gap[h, j]/sqrt(number_of_seeds); # how precisely the games pin down the average
            mean_realized[h, j] = mean(realized_regrets[h, j, :]); # the average realized regret
        end
    end

    # return the inputs, every game, and the summaries in one NamedTuple. We copy the inputs, so
    # changing the horizons or seeds arrays later does not change this record -
    return (labels = labels, horizons = copy(horizons), seeds = copy(seeds),
        gap_regrets = gap_regrets, realized_regrets = realized_regrets,
        mean_gap = mean_gap, sd_gap = sd_gap, se_gap = se_gap, mean_realized = mean_realized);
end

end # module L10dUtility
