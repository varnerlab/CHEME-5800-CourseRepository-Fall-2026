# =============================================================================
# CHEME 5800 | L10d supplied helpers: repeated bandit games and the Bernoulli world
# =============================================================================
# compare_bandits(...) replays explore-first, epsilon-greedy, and UCB1 over many
# seeds and horizons for Task 2; bernoulli_world(...) is the world for Task 3.
# You do not need to edit this file; your work is in Compute.jl. Include.jl
# loads this file once, so after an edit here, restart the kernel.
# =============================================================================
module L10dUtility

using Distributions: Distribution, Bernoulli # reward distributions
using Random: AbstractRNG, seed! # repeatable games
using Statistics: mean, std # averages and variation across games
using VLDataScienceMachineLearningPackage: build, solve,
    MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel

export compare_bandits, bernoulli_world

"""
    bernoulli_world(a::Int, θ::Vector{Float64}, rng::AbstractRNG) -> Int

Pull arm `a` and return 1 with probability `θ[a]`, otherwise 0, using `rng`.
Arm indices are one-based and each dimensionless success probability lies in `[0, 1]`.
The probabilities belong to the world; the agent receives only the returned reward.
"""
function bernoulli_world(a::Int, θ::Vector{Float64}, rng::AbstractRNG)::Int
    return rand(rng, Bernoulli(θ[a])) ? 1 : 0;
end

"""
    compare_bandits(arms::AbstractVector{<:Distribution}, horizons::Vector{Int},
        seeds::Vector{Int}) -> NamedTuple

Run explore-first, epsilon-greedy, and UCB1 on independent stationary rewards drawn
from `arms`, at each horizon and seed. Distributions must have support in `[0, 1]`.
Each horizon must be at least the number of arms; use at least two distinct seeds.
Round counts, rewards, and regret are dimensionless.

The world draws a new reward on each pull. Each algorithm starts from the supplied
seed, so a game is repeatable; algorithms can consume different random draws. An
explore-first game is restarted for each horizon because its exploration budget
depends on the horizon. The function resets Julia's default random number generator.

Returns `labels`, `horizons`, and `seeds`, with `gap_regrets` and `realized_regrets`
indexed by `(horizon, algorithm, seed)`. For selected arms `a_t`, the former is
`sum(maximum(μ) - μ[a_t])`; the latter is `T*maximum(μ) - sum(rewards)`, where
`μ = mean.(arms)` is known to the evaluator. These quantities have the same expectation.
The matrices `mean_gap`, `sd_gap`, `se_gap`, and `mean_realized` are indexed by
`(horizon, algorithm)`; `se_gap` is the sample standard deviation divided by the
square root of the number of seeds.
"""
function compare_bandits(arms::AbstractVector{<:Distribution}, horizons::Vector{Int},
    seeds::Vector{Int})::NamedTuple

    # Check the experiment design -
    K = length(arms);
    K ≥ 1 || throw(ArgumentError("supply at least one arm"));
    !isempty(horizons) && all(horizons .≥ K) || throw(ArgumentError("every horizon must be at least K"));
    length(seeds) ≥ 2 && length(unique(seeds)) == length(seeds) ||
        throw(ArgumentError("supply at least two distinct seeds"));
    all(d -> minimum(d) ≥ 0 && maximum(d) ≤ 1, arms) ||
        throw(ArgumentError("reward distributions must have support in [0, 1]"));

    # Initialize -
    labels = ["Explore-first", "ε-greedy", "UCB1"];
    models = [MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel];
    μ = mean.(arms); # true arm means, known only to the evaluator
    μstar = maximum(μ);
    gap_regrets = zeros(length(horizons), length(models), length(seeds));
    realized_regrets = similar(gap_regrets);

    # Restart each game at each horizon and seed -
    for (h, T) ∈ enumerate(horizons)
        for (j, M) ∈ enumerate(models)
            for (s, seed) ∈ enumerate(seeds)
                seed!(seed);
                world = a -> rand(arms[a]); # reveal only the selected arm's reward
                game = solve(build(M, (K = K,)), T = T, world = world, return_history = true);
                gap_regrets[h, j, s] = sum(μstar - μ[a] for a ∈ game.actions);
                realized_regrets[h, j, s] = T*μstar - sum(game.rewards);
            end
        end
    end

    # Summarize variation across seeds -
    mean_gap = dropdims(mean(gap_regrets, dims = 3), dims = 3);
    sd_gap = dropdims(std(gap_regrets, dims = 3), dims = 3);
    se_gap = sd_gap ./ sqrt(length(seeds));
    mean_realized = dropdims(mean(realized_regrets, dims = 3), dims = 3);
    return (; labels, horizons = copy(horizons), seeds = copy(seeds), gap_regrets,
        realized_regrets, mean_gap, sd_gap, se_gap, mean_realized);
end

end # module L10dUtility
