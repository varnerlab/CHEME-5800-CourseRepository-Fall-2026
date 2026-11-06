# =============================================================================
# CHEME 5800 | L12b student work: Q-learning
# =============================================================================
# This is the file you edit in this lab. Complete myqlearning(...) below by
# filling in the lines marked TODO 1, TODO 2, and TODO 3; everything else is
# already written. Each TODO is one line of the Q-learning algorithm.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the training cell and the check cell.
# You are done when every test in the check cell passes.
# =============================================================================
module L12bQLearning

import VLDataScienceMachineLearningPackage: MyQLearningAgentModel # the agent type
using Random # Xoshiro, a seeded random number generator

export myqlearning

"""
    myqlearning(agent::MyQLearningAgentModel, environment; worldmodel::Function,
        absorbing::Set{Int64}, episodes::Int64 = 200_000, maxsteps::Int64 = 80,
        ϵ_start::Float64 = 1.0, ϵ_floor::Float64 = 0.05, seed::Int64 = 1234) -> NamedTuple

Learn the action values of an environment by episodic Q-learning.

The agent never reads the rules of `environment`. It only calls `worldmodel(environment, s, a)`,
which returns the next state `s′` and the reward `r` of taking action `a` in state `s`, as if
the agent had tried that action.

Each episode starts in a random state that is not absorbing, and runs until the agent enters an
absorbing state or has taken `maxsteps` steps. Each step chooses an action with the
epsilon-greedy rule: with probability `ϵ` a random action, and otherwise the action with the
largest value in the current row of `Q`. The agent takes the action, observes `(s′, r)`, and moves
`Q[s,a]` a fraction `α` of the way toward the temporal difference target `r + γ⋅max Q[s′,:]`.
The rows of absorbing states are set to zero at the start and never updated, because an episode
ends there and earns nothing more.

Two schedules follow the convergence conditions of the lecture:
- The learning rate of the n-th update of a pair `(s,a)` is `α = 1/n`. `Q[s,a]` is then the
  average of the targets that pair has seen. The agent's own `α` field is not used.
- The exploration probability of episode `i` is `ϵ = max(ϵ_floor, ϵ_start - i/(0.7⋅episodes))`.
  With the defaults, it falls in a straight line from 1, reaches 0.05 after 66.5 percent of the
  episodes, then stays at 0.05. Setting `ϵ_start` and `ϵ_floor` to zero gives a purely greedy agent.

### Arguments
- `agent::MyQLearningAgentModel`: the agent. We use its discount factor `γ` and start from a copy
  of its table `Q`, one row per state and one column per action. The agent's own table is not changed.
- `environment`: the world. We only pass it to `worldmodel`. Its states are numbered
  `1, 2, …, |𝒮|` and its actions `1, 2, …, |𝒜|`.
- `worldmodel::Function`: the function `worldmodel(environment, s, a)` that returns the next
  state and the reward, `(s′, r)`.
- `absorbing::Set{Int64}`: the states that end an episode.
- `episodes::Int64 = 200_000`: the number of episodes.
- `maxsteps::Int64 = 80`: the most steps in one episode.
- `ϵ_start::Float64 = 1.0`: the exploration probability at the start of training.
- `ϵ_floor::Float64 = 0.05`: the smallest exploration probability.
- `seed::Int64 = 1234`: the seed of the random number generator, so a run can be repeated exactly.

### Returns
A `NamedTuple` with the fields:
- `Q::Array{Float64,2}`: the learned action values, one row per state and one column per action.
- `visits::Array{Int64,2}`: the number of times the agent took each action in each state.

### Example
```julia
result = L12bQLearning.myqlearning(agent, env; worldmodel = world, absorbing = absorbing_states,
    episodes = 200_000, maxsteps = 80, seed = 1234);
result.Q, result.visits
```
"""
function myqlearning(agent::MyQLearningAgentModel, environment; worldmodel::Function,
    absorbing::Set{Int64}, episodes::Int64 = 200_000, maxsteps::Int64 = 80,
    ϵ_start::Float64 = 1.0, ϵ_floor::Float64 = 0.05, seed::Int64 = 1234)::NamedTuple

    # Initialize; this part is complete -
    rng = Xoshiro(seed); # our own random number generator, so a run can be repeated exactly
    γ = agent.γ; # the discount factor
    Q = copy(agent.Q); # the table we update: a copy, so the agent's own table is not changed
    number_of_states = size(Q, 1); # one row per state
    number_of_actions = size(Q, 2); # one column per action
    visits = zeros(Int64, number_of_states, number_of_actions); # visits[s,a]: how many times we took action a in state s
    message = "Oooops! The `myqlearning(...)` function is not implemented yet - " *
        "we'd better fix that. Complete TODO 1 through TODO 3.";

    # The states an episode may start from: every state that is not absorbing. The row of an
    # absorbing state is set to zero, because an episode ends there. This part is complete -
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

        # The exploration probability of this episode: it falls in a straight line from
        # ϵ_start, and never below ϵ_floor. This part is complete -
        ϵ = ϵ_start - episode/(0.7*episodes);
        if (ϵ < ϵ_floor)
            ϵ = ϵ_floor;
        end

        # Start in a random state that is not absorbing. This part is complete -
        s = starts[rand(rng, 1:length(starts))];
        t = 0; # the step counter

        # One step each pass, until we enter an absorbing state or run out of steps -
        while (in(s, absorbing) == false && t < maxsteps)

            # Choose the action with the epsilon-greedy rule -
            p = rand(rng); # a random number between 0 and 1
            a = 0; # the action; 0 means "not chosen yet"
            if (p ≤ ϵ)
                a = rand(rng, 1:number_of_actions); # exploration: a random action. This part is complete
            else
                # TODO 1: exploitation. Replace 0 with the greedy action, the action with the
                # largest value in row s of Q. Hint: Q[s,:] is row s of Q, and argmax(x)
                # returns the index of the largest entry of the vector x (the first one, if
                # several entries tie for the largest).
                a = 0;
            end
            if (a == 0) # this part is complete: a blank TODO 1 leaves 0 behind
                throw(ErrorException(message));
            end

            # Take action a, and observe the next state and the reward. This part is complete -
            (s′, r) = worldmodel(environment, s, a);

            # The learning rate of this update is 1/n, where n counts the updates of the
            # pair (s,a) so far, this one included. This part is complete -
            visits[s,a] = visits[s,a] + 1;
            α = 1.0/visits[s,a];

            # TODO 2: the temporal difference target. Replace NaN with r + γ⋅max Q[s′,:], the
            # reward plus the discounted value of the best action in the next state. Hint:
            # maximum(x) returns the largest entry of x. When s′ is absorbing, its row of Q is
            # zero (we set it above), so the target is just r; no special case is needed.
            target = NaN;

            # TODO 3: the update. Replace NaN with the new value of Q[s,a], which moves the old
            # value a fraction α of the way toward the target: Q[s,a] + α⋅(target - Q[s,a]).
            # Hint: target - Q[s,a] is the temporal difference error. The first update of a
            # pair has α = 1, which makes the new value the target itself.
            Q[s,a] = NaN;
            if (isnan(Q[s,a]) == true) # this part is complete: a blank TODO leaves NaN, "not a number", behind
                throw(ErrorException(message));
            end

            # Move to the next state. This part is complete -
            s = s′;
            t = t + 1;
        end
    end

    # return the learned table and the visit counts -
    return (Q = Q, visits = visits);
end

end # module L12bQLearning
