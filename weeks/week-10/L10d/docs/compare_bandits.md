# Repeated bandit experiments

These helpers support [the L10d lab](../CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb)
and are defined, with Julia docstrings, in [Utility.jl](../src/Utility.jl). The setup file loads
them with `using .L10dUtility`, so the notebook calls them by their short names.

## `compare_bandits(arms, horizons, seeds)`

Play the explore-first, epsilon-greedy, and UCB1 algorithms on the same bandit many times, and
measure how much reward each algorithm gives up.

- `arms::Array{<:Distribution,1}` holds the reward distribution of each arm, of any kind (such as
  `Beta` or `Bernoulli`). Every reward must lie between 0 and 1.
- `horizons::Array{Int64,1}` holds the numbers of rounds to try, each at least the number of arms.
- `seeds::Array{Int64,1}` holds the random number seeds, one game per seed; at least two, all different.

For every horizon, algorithm, and seed, the function sets the seed, plays a new game, and records
two numbers. The gap loss charges each pull the difference between the best true mean reward and
the true mean reward of the arm it chose. The realized regret is the number of rounds times the
best true mean reward, minus the rewards actually received. Both have the same expected value.

The returned `NamedTuple` holds `labels` (the algorithm names), the inputs `horizons` and `seeds`,
and two arrays with one entry per game, `gap_regrets` and `realized_regrets`, indexed by
horizon × algorithm × seed. The matrices `mean_gap`, `sd_gap`, `se_gap`, and `mean_realized` are
indexed by horizon × algorithm. They hold the average gap loss over the seeds, its standard
deviation, its standard error (the standard deviation divided by the square root of the number of
seeds), and the average realized regret. Rewards and regrets have no units.

Each game calls `Random.seed!(seed)`, which resets Julia's global random number generator. Each
horizon starts a new game, because explore-first uses the number of rounds to set how long it
explores. The three algorithms start from the same seed, but they use random numbers differently,
so they do not see the same rewards.

<a id="bernoulli-world"></a>

## `bernoulli_world(a, θ, rng)`

Pull arm `a::Int64` of a binary Bernoulli bandit and return its reward: `1` with probability
`θ[a]`, and `0` otherwise. The vector `θ::Array{Float64,1}` holds the success probability of each
arm, each between 0 and 1, and `rng::AbstractRNG` is the random number generator that draws the
reward; each call moves `rng` forward. Only the world knows the success probabilities; the agent
sees only the returned reward.
