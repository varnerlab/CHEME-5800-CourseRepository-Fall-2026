module Week10Core

import Distributions: Beta
import Random

export run_bandit, weighted_majority

function weighted_majority(losses::AbstractMatrix{<:Real}; eta::Real = 0.5)
    all(x -> isfinite(x) && 0 <= x <= 1, losses) || throw(ArgumentError("losses must lie in [0,1]"))
    eta > 0 || throw(ArgumentError("eta must be positive"))
    rounds, experts = size(losses)
    rounds > 0 && experts > 0 || throw(ArgumentError("loss matrix may not be empty"))
    weights = ones(Float64, experts)
    probabilities = zeros(Float64, rounds, experts)
    expected_losses = zeros(Float64, rounds)
    for round in 1:rounds
        probabilities[round, :] .= weights ./ sum(weights)
        expected_losses[round] = sum(probabilities[round, :] .* losses[round, :])
        weights .*= exp.(-eta .* losses[round, :])
    end
    expert_totals = vec(sum(losses; dims = 1))
    learner_total = sum(expected_losses)
    return (probabilities = probabilities, expected_losses = expected_losses,
        learner_total = learner_total, expert_totals = expert_totals,
        regret = learner_total - minimum(expert_totals), final_weights = weights)
end

function _validate_bandit(probabilities, horizon, algorithm)
    values = Float64.(collect(probabilities))
    !isempty(values) && all(x -> isfinite(x) && 0 <= x <= 1, values) ||
        throw(ArgumentError("arm probabilities must lie in [0,1]"))
    horizon >= length(values) || throw(ArgumentError("horizon must be at least the number of arms"))
    algorithm in (:ucb1, :thompson) || throw(ArgumentError("unknown bandit algorithm: $(algorithm)"))
    return values
end

function run_bandit(probabilities, horizon::Integer; algorithm::Symbol = :ucb1, seed::Integer = 5800)
    values = _validate_bandit(probabilities, horizon, algorithm)
    arms = length(values)
    rng = Random.MersenneTwister(seed)
    counts = zeros(Int, arms)
    successes = zeros(Int, arms)
    actions, rewards = zeros(Int, horizon), zeros(Int, horizon)
    for round in 1:horizon
        action = if round <= arms
            round
        elseif algorithm == :ucb1
            estimates = successes ./ counts
            bonus = sqrt.(2log(round) ./ counts)
            argmax(estimates .+ bonus)
        else
            samples = [rand(rng, Beta(successes[a] + 1, counts[a] - successes[a] + 1)) for a in 1:arms]
            argmax(samples)
        end
        reward = rand(rng) < values[action] ? 1 : 0
        actions[round], rewards[round] = action, reward
        counts[action] += 1
        successes[action] += reward
    end
    expected_reward = sum(values[action] for action in actions)
    regret = horizon * maximum(values) - expected_reward
    return (actions = actions, rewards = rewards, counts = counts,
        estimates = successes ./ counts, cumulative_reward = cumsum(rewards),
        total_reward = sum(rewards), expected_regret = regret)
end

end
