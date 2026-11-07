# =============================================================================
# CHEME 5800 | L12a example code: Q-learning
# =============================================================================
# This file holds myqlearning(...), the Q-learning that the example runs. It
# follows the pseudocode in the notebook line by line.
#
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12aQLearning

import VLDataScienceMachineLearningPackage: MyQLearningAgentModel, MyMDPProblemModel # the agent and the world types
using Random # Xoshiro, a seeded random number generator

export myqlearning

"""
    myqlearning(agent::MyQLearningAgentModel, environment::MyMDPProblemModel;
        worldmodel::Function, absorbing::Set{Int64}, episodes::Int64 = 2000,
        maxsteps::Int64 = 500, ϵ::Float64 = 0.1, seed::Int64 = 5800) -> NamedTuple

Learn the action values of a world by episodic Q-learning.

The agent never reads the rewards or the transition probabilities stored in `environment`. It
only calls `worldmodel(environment, s, a, rng)`, which returns the next state `s′` and the reward
`r` of taking action `a` in state `s`, as if the roomba had tried the move.

Each episode starts in a random state that is not absorbing, and runs until the agent enters an
absorbing state or has taken `maxsteps` steps. Each step chooses an action with the
epsilon-greedy rule: with probability `ϵ` a random action, and otherwise the action with the
largest value in the current row of `Q`. The agent takes the action, observes `(s′, r)`, and moves
`Q[s,a]` a fraction `α` of the way toward the temporal difference target `r + γ⋅max Q[s′,:]`.
The rows of absorbing states are set to zero at the start and never updated, because an episode
ends there and earns nothing more.

### Arguments
- `agent::MyQLearningAgentModel`: the agent. We use its learning rate `α`, its discount factor
  `γ`, and its table `Q`, one row per state and one column per action, as the starting table.
  The agent's own table is not changed.
- `environment::MyMDPProblemModel`: the world. We only pass it to `worldmodel`. Its states are
  numbered `1, 2, …, |𝒮|` and its actions `1, 2, …, |𝒜|`.
- `worldmodel::Function`: the function `worldmodel(environment, s, a, rng)` that returns the
  next state and the reward, `(s′, r)`.
- `absorbing::Set{Int64}`: the states that end an episode.
- `episodes::Int64 = 2000`: the number of episodes.
- `maxsteps::Int64 = 500`: the most steps in one episode.
- `ϵ::Float64 = 0.1`: the exploration probability, between 0 and 1.
- `seed::Int64 = 5800`: the seed of the random number generator, so a run can be repeated exactly.

### Returns
A `NamedTuple` with the fields:
- `Q::Array{Float64,2}`: the learned action values, one row per state and one column per action.
- `visits::Array{Int64,2}`: the number of times the agent took each action in each state.

### Example
```julia
agent = build(MyQLearningAgentModel, (states = 𝒮, actions = 𝒜, α = 0.5, γ = 0.95,
    Q = zeros(length(𝒮), length(𝒜))));
result = myqlearning(agent, m; worldmodel = lavaworld, absorbing = absorbing_states);
result.Q, result.visits
```
"""
function myqlearning(agent::MyQLearningAgentModel, environment::MyMDPProblemModel;
    worldmodel::Function, absorbing::Set{Int64}, episodes::Int64 = 2000,
    maxsteps::Int64 = 500, ϵ::Float64 = 0.1, seed::Int64 = 5800)::NamedTuple

    # Initialize -
    rng = Xoshiro(seed); # our own random number generator, so a run can be repeated exactly
    α = agent.α; # the learning rate
    γ = agent.γ; # the discount factor
    Q = copy(agent.Q); # the table we update: a copy, so the agent's own table is not changed
    number_of_states = size(Q, 1); # one row per state
    number_of_actions = size(Q, 2); # one column per action
    visits = zeros(Int64, number_of_states, number_of_actions); # visits[s,a]: how many times we took action a in state s

    # The states an episode may start from: every state that is not absorbing. The row of an
    # absorbing state is set to zero, because an episode ends there -
    starts = Array{Int64,1}();
    for s ∈ 1:number_of_states
        if (in(s, absorbing) == false)
            push!(starts, s);
        else
            for a ∈ 1:number_of_actions
                Q[s,a] = 0.0;
            end
        end
    end

    # Main loop: one episode each pass -
    for episode ∈ 1:episodes

        # Start in a random state that is not absorbing -
        s = starts[rand(rng, 1:length(starts))];
        t = 0; # the step counter

        # One step each pass, until we enter an absorbing state or run out of steps -
        while (in(s, absorbing) == false && t < maxsteps)

            # Choose the action with the epsilon-greedy rule -
            p = rand(rng); # a random number between 0 and 1
            a = 0; # the action, chosen below
            if (p ≤ ϵ)
                a = rand(rng, 1:number_of_actions); # exploration: a random action
            else
                a = argmax(Q[s,:]); # exploitation: the greedy action
            end

            # Take action a, and observe the next state and the reward -
            (s′, r) = worldmodel(environment, s, a, rng);
            visits[s,a] = visits[s,a] + 1;

            # The temporal difference target -
            target = r + γ*maximum(Q[s′,:]);

            # The update: move Q[s,a] a fraction α of the way toward the target -
            Q[s,a] = Q[s,a] + α*(target - Q[s,a]);

            # Move to the next state -
            s = s′;
            t = t + 1;
        end
    end

    # return the learned table and the visit counts -
    return (Q = Q, visits = visits);
end

end # module L12aQLearning
