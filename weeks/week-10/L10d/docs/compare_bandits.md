# Repeated bandit experiments

These helpers support [the L10d lab](../CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb)
and are defined with Julia docstrings in [Utility.jl](../src/Utility.jl). The setup file loads
them with `using .L10dUtility`, so the notebook calls them by their short names.

## `compare_bandits(arms, horizons, seeds)`

Run explore-first, epsilon-greedy, and UCB1 at each horizon and seed.

- `arms::AbstractVector{<:Distribution}` holds independent, stationary reward
  distributions with support in `[0, 1]`.
- `horizons::Vector{Int}` holds round counts, each at least the number of arms.
- `seeds::Vector{Int}` holds at least two distinct random-number seeds.

The returned `NamedTuple` records `labels`, `horizons`, and `seeds`. The arrays
`gap_regrets` and `realized_regrets` have dimensions horizon × algorithm × seed.
For each game, gap loss sums the difference between the best true arm mean and
the true mean of the selected arm. Realized regret subtracts the observed reward
total from the horizon times the best true arm mean. Both have the same expectation.

The matrices `mean_gap`, `sd_gap`, `se_gap`, and `mean_realized` have dimensions
horizon × algorithm. They hold the sample mean gap loss, its sample standard
deviation across games, its standard error, and the sample mean realized regret.
The standard error is the standard deviation divided by the square root of the
number of seeds. Rewards and regret are dimensionless.

Every game resets Julia's default random number generator. Each horizon starts
a fresh game because explore-first uses the horizon to set its exploration budget.
Algorithms with the same seed can consume different random draws.

<a id="bernoulli-world"></a>

## `bernoulli_world(a, θ, rng)`

Draw a reward for one-based arm index `a::Int` using `rng::AbstractRNG`.
The vector `θ::Vector{Float64}` holds the arms' dimensionless success probabilities
in `[0, 1]`. The return value is `1` with probability `θ[a]` and `0` otherwise.
Only the world knows the success probabilities; the agent sees the returned reward.
