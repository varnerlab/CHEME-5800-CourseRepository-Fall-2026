module Week11Core

import Random

export classic_gridworld, evolve_markov, generate_markov_sequence,
    validate_transition_matrix, value_iteration

function validate_transition_matrix(P::AbstractMatrix{<:Real}; atol::Real = 1e-10)
    size(P, 1) == size(P, 2) || throw(DimensionMismatch("transition matrix must be square"))
    all(x -> isfinite(x) && x >= -atol, P) || throw(ArgumentError("transition probabilities must be nonnegative and finite"))
    all(isapprox.(vec(sum(P; dims = 2)), 1.0; atol = atol)) || throw(ArgumentError("transition rows must sum to one"))
    return true
end

function evolve_markov(P::AbstractMatrix{<:Real}, initial::AbstractVector{<:Real}, steps::Integer)
    validate_transition_matrix(P)
    length(initial) == size(P, 1) || throw(DimensionMismatch("initial distribution must match P"))
    steps >= 0 || throw(ArgumentError("steps must be nonnegative"))
    all(x -> isfinite(x) && x >= 0, initial) && isapprox(sum(initial), 1.0; atol = 1e-10) ||
        throw(ArgumentError("initial distribution must be nonnegative and sum to one"))
    history = zeros(Float64, length(initial), steps + 1)
    history[:, 1] .= initial
    for step in 1:steps
        history[:, step + 1] .= transpose(P) * history[:, step]
    end
    return history
end

function generate_markov_sequence(labels, P::AbstractMatrix{<:Real}, start::Integer, length_out::Integer; seed::Integer = 5800)
    validate_transition_matrix(P)
    length(labels) == size(P, 1) || throw(DimensionMismatch("labels must match P"))
    start in eachindex(labels) || throw(ArgumentError("start state is invalid"))
    length_out >= 1 || throw(ArgumentError("sequence length must be positive"))
    rng = Random.MersenneTwister(seed)
    state = Int(start)
    sequence = [labels[state]]
    for _ in 2:length_out
        draw = rand(rng)
        cumulative = cumsum(view(P, state, :))
        state = searchsortedfirst(cumulative, draw)
        push!(sequence, labels[state])
    end
    return sequence
end

function classic_gridworld(; slip::Real = 0.1, gamma::Real = 0.95, step_reward::Real = -0.04)
    0 <= slip < 0.5 || throw(ArgumentError("slip must lie in [0,0.5)"))
    0 <= gamma < 1 || throw(ArgumentError("gamma must lie in [0,1)"))
    coordinates = [(row, column) for row in 1:3 for column in 1:4 if (row, column) != (2, 2)]
    index = Dict(coordinate => i for (i, coordinate) in enumerate(coordinates))
    goal, pit = index[(1, 4)], index[(2, 4)]
    terminal = falses(length(coordinates)); terminal[[goal, pit]] .= true
    rewards = fill(Float64(step_reward), length(coordinates)); rewards[goal] = 1.0; rewards[pit] = -1.0
    actions = [(-1, 0), (0, 1), (1, 0), (0, -1)]
    P = zeros(Float64, length(coordinates), 4, length(coordinates))
    for (state, coordinate) in enumerate(coordinates), action in 1:4
        if terminal[state]
            P[state, action, state] = 1.0
            continue
        end
        choices = ((action, 1 - 2slip), (mod1(action - 1, 4), slip), (mod1(action + 1, 4), slip))
        for (actual, probability) in choices
            delta = actions[actual]
            proposed = (coordinate[1] + delta[1], coordinate[2] + delta[2])
            target = get(index, proposed, state)
            P[state, action, target] += probability
        end
    end
    return (P = P, rewards = rewards, terminal = terminal, gamma = Float64(gamma),
        coordinates = coordinates, index = index, action_names = ["↑", "→", "↓", "←"])
end

function value_iteration(P::AbstractArray{<:Real, 3}, rewards::AbstractVector{<:Real}, gamma::Real;
    terminal = falses(length(rewards)), tolerance::Real = 1e-10, max_iterations::Integer = 10_000)
    states, actions, targets = size(P)
    states == targets == length(rewards) == length(terminal) || throw(DimensionMismatch("MDP dimensions are inconsistent"))
    all(isapprox.(vec(sum(P; dims = 3)), 1.0; atol = 1e-10)) || throw(ArgumentError("each state-action transition must sum to one"))
    0 <= gamma < 1 || throw(ArgumentError("gamma must lie in [0,1)"))
    values = zeros(Float64, states)
    residuals = Float64[]
    policy = ones(Int, states)
    for iteration in 1:max_iterations
        previous = copy(values)
        for state in 1:states
            if terminal[state]
                values[state] = rewards[state]
                policy[state] = 0
            else
                action_values = [rewards[state] + gamma * sum(P[state, action, next] * previous[next] for next in 1:states) for action in 1:actions]
                values[state], policy[state] = findmax(action_values)
            end
        end
        push!(residuals, maximum(abs.(values - previous)))
        residuals[end] <= tolerance && return (values = values, policy = policy,
            residuals = residuals, iterations = iteration, converged = true)
    end
    return (values = values, policy = policy, residuals = residuals,
        iterations = Int(max_iterations), converged = false)
end

end
