module Week12Core

import Random
import Statistics: mean

export evaluate_policy, greedy_policy, learning_gridworld, policy_agreement,
    q_learning, value_iteration_reference

function learning_gridworld(; slip::Real = 0.1, gamma::Real = 0.95, step_reward::Real = -0.04)
    0 <= slip < 0.5 || throw(ArgumentError("slip must lie in [0,0.5)"))
    0 <= gamma < 1 || throw(ArgumentError("gamma must lie in [0,1)"))
    coordinates = [(row, column) for row in 1:3 for column in 1:4 if (row, column) != (2, 2)]
    index = Dict(coordinate => i for (i, coordinate) in enumerate(coordinates))
    goal, pit, start = index[(1, 4)], index[(2, 4)], index[(3, 1)]
    terminal = falses(length(coordinates)); terminal[[goal, pit]] .= true
    arrival_reward = fill(Float64(step_reward), length(coordinates))
    arrival_reward[goal], arrival_reward[pit] = 1.0, -1.0
    actions = [(-1, 0), (0, 1), (1, 0), (0, -1)]
    P = zeros(Float64, length(coordinates), 4, length(coordinates))
    for (state, coordinate) in enumerate(coordinates), action in 1:4
        if terminal[state]
            P[state, action, state] = 1.0
            continue
        end
        for (actual, probability) in ((action, 1 - 2slip), (mod1(action - 1, 4), slip), (mod1(action + 1, 4), slip))
            delta = actions[actual]
            proposed = (coordinate[1] + delta[1], coordinate[2] + delta[2])
            target = get(index, proposed, state)
            P[state, action, target] += probability
        end
    end
    return (P = P, rewards = arrival_reward, terminal = terminal, gamma = Float64(gamma),
        coordinates = coordinates, index = index, start = start,
        action_names = ["↑", "→", "↓", "←"])
end

function value_iteration_reference(world; tolerance::Real = 1e-12, max_iterations::Integer = 10_000)
    states, actions, _ = size(world.P)
    values = zeros(Float64, states)
    policy = zeros(Int, states)
    residuals = Float64[]
    for iteration in 1:max_iterations
        previous = copy(values)
        for state in 1:states
            world.terminal[state] && continue
            action_values = [sum(world.P[state, action, next] *
                (world.rewards[next] + (world.terminal[next] ? 0.0 : world.gamma * previous[next]))
                for next in 1:states) for action in 1:actions]
            values[state], policy[state] = findmax(action_values)
        end
        push!(residuals, maximum(abs.(values - previous)))
        residuals[end] <= tolerance && return (values = values, policy = policy,
            residuals = residuals, iterations = iteration, converged = true)
    end
    return (values = values, policy = policy, residuals = residuals,
        iterations = Int(max_iterations), converged = false)
end

function _sample_next(rng, probabilities)
    return searchsortedfirst(cumsum(probabilities), rand(rng))
end

function q_learning(world; episodes::Integer = 20_000, alpha::Real = 0.15,
    epsilon_start::Real = 1.0, epsilon_min::Real = 0.03, epsilon_decay::Real = 0.9995,
    max_steps::Integer = 100, seed::Integer = 5800)
    episodes > 0 || throw(ArgumentError("episodes must be positive"))
    0 < alpha <= 1 || throw(ArgumentError("alpha must lie in (0,1]"))
    0 <= epsilon_min <= epsilon_start <= 1 || throw(ArgumentError("epsilon bounds are invalid"))
    0 < epsilon_decay <= 1 || throw(ArgumentError("epsilon_decay must lie in (0,1]"))
    states, actions, _ = size(world.P)
    Q = zeros(Float64, states, actions)
    rng = Random.MersenneTwister(seed)
    nonterminal = findall(!, world.terminal)
    returns = zeros(Float64, episodes)
    epsilon = Float64(epsilon_start)
    for episode in 1:episodes
        state = rand(rng, nonterminal)
        discount, total = 1.0, 0.0
        for _ in 1:max_steps
            action = rand(rng) < epsilon ? rand(rng, 1:actions) : argmax(view(Q, state, :))
            next = _sample_next(rng, view(world.P, state, action, :))
            reward = world.rewards[next]
            target = reward + (world.terminal[next] ? 0.0 : world.gamma * maximum(view(Q, next, :)))
            Q[state, action] += alpha * (target - Q[state, action])
            total += discount * reward
            discount *= world.gamma
            state = next
            world.terminal[state] && break
        end
        returns[episode] = total
        epsilon = max(epsilon_min, epsilon * epsilon_decay)
    end
    return (Q = Q, returns = returns, final_epsilon = epsilon,
        policy = greedy_policy(Q, world.terminal))
end

function greedy_policy(Q::AbstractMatrix{<:Real}, terminal)
    length(terminal) == size(Q, 1) || throw(DimensionMismatch("terminal mask must match Q"))
    return [terminal[state] ? 0 : argmax(view(Q, state, :)) for state in axes(Q, 1)]
end

function policy_agreement(first, second, terminal)
    length(first) == length(second) == length(terminal) || throw(DimensionMismatch("policy dimensions must match"))
    states = findall(!, terminal)
    return count(state -> first[state] == second[state], states) / length(states)
end

function evaluate_policy(world, policy; episodes::Integer = 1000, max_steps::Integer = 100, seed::Integer = 5800)
    length(policy) == length(world.terminal) || throw(DimensionMismatch("policy must match world states"))
    rng = Random.MersenneTwister(seed)
    returns = zeros(Float64, episodes)
    for episode in 1:episodes
        state, discount = world.start, 1.0
        for _ in 1:max_steps
            action = policy[state]
            action in 1:4 || throw(ArgumentError("nonterminal policy actions must lie in 1:4"))
            next = _sample_next(rng, view(world.P, state, action, :))
            returns[episode] += discount * world.rewards[next]
            discount *= world.gamma
            state = next
            world.terminal[state] && break
        end
    end
    return (mean_return = mean(returns), returns = returns)
end

end
