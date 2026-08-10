# PRIVATE METHODS BELOW HERE ================================================================================= #
"""
    _world(model::MyRectangularGridWorldModel, s::Int, a::Int)::Tuple{Int,Float64}

Default `worldmodel` for [`solve(agent::MyQLearningAgentModel, environment::MyRectangularGridWorldModel; ...)`](@ref).
This is a teaching stub, not a real environment: it throws instead of silently doing nothing so that a caller who
forgets to supply `worldmodel` gets an immediate, loud error rather than an agent that never moves and never earns
reward. Callers (e.g. course notebooks) are expected to pass their own environment-dynamics function via the
`worldmodel` keyword.
"""
function _world(model::MyRectangularGridWorldModel, s::Int, a::Int)::Tuple{Int,Float64}
    throw(ArgumentError("No world model supplied. A `MyRectangularGridWorldModel` transition function must be " *
        "supplied via the `worldmodel` keyword argument to `solve`; the package does not ship a default " *
        "environment implementation."));
end


# PRIVATE METHODS ABOVE HERE ================================================================================= #

# PUBLIC METHODS BELOW HERE ================================================================================== #``
# Cool hack: What is going on with these?
# (model::MyRectangularGridWorldModel)(s::Int, a::Int) = _world(model, s, a);
# (model::MyQLearningAgentModel)(data::NamedTuple) = _update(model, data);

"""
    function solve(model::MyQLearningModel, environment::T, startstate::Int, maxsteps::Int;
        ϵ::Float64 = 0.2) -> MyQLearningModel where T <: AbstractWorldModel

Simulate the Q-Learning agent in the given environment starting from the given state for a maximum number of steps.

### Arguments
- `agent::MyQLearningAgentModel`: The Q-Learning agent model.
- `environment::MyRectangularGridWorldModel`: The environment model.
- `maxsteps::Int`: The maximum number of steps to simulate.
- `δ::Float64 = 0.02`: The convergence threshold. Default is 0.02.
- `worldmodel::Function = _world`: The world model function. Default is the private `_world` function, which throws
   unless overridden; callers must supply their own environment-dynamics function.

### Returns
- `MyQLearningAgentModel`: The updated Q-Learning agent model after simulation.
"""
function solve(agent::MyQLearningAgentModel, environment::MyRectangularGridWorldModel;
    maxsteps::Int = 100, δ::Float64 = 0.02, worldmodel::Function = _world)::MyQLearningAgentModel

    # initialize -
    actions = agent.actions;
    K = length(actions); # number of actions
    states = agent.states;
    Q₁ = agent.Q;
    γ = agent.γ;

    # simulation loop -
    for s ∈ states

        # initialize t -
        t = 1;
        has_converged = false;
        αₜ = copy(agent.α);
        while (has_converged == false)

            # compute the ϵ -
            ϵₜ = (1.0/(t^(1/3)))*(log(K*t))^(1/3); # compute the epsilon value -
            p = rand();

            aₜ = nothing;
            if p ≤ ϵₜ
                aₜ = rand(1:K); # generate a random action
            elseif p > ϵₜ
                aₜ = argmax(Q₁[s,:]); # select the greedy action, given state s
            end

            # compute new state and reward -
            s′, r = worldmodel(environment, s, aₜ);

            # use the update rule to update Q -
            Q₂ = copy(Q₁); # this seems really inefficient, but it is what it is ...
            Q₁[s,aₜ] += αₜ*(r+γ*maximum(Q₁[s′,:]) - Q₁[s,aₜ])

            # update stuff
            s = s′; # state update
            t += 1; # time update
            αₜ = 0.99*αₜ; # update the learning rate

            # check if we have converged -
            if ((t > maxsteps) || norm(Q₂ - Q₁) < δ)
                has_converged = true;
            end
        end
    end

    agent.Q = Q₁; # update the model

    # return -
    return agent
end
