# PRIVATE METHODS BELOW HERE ================================================================================= #
# placeholder - always return 0
_null(action::Int64)::Int64 = return 0;

function _check_bandit_horizon(K::Int, T::Int)
    K ≥ 1 || throw(ArgumentError("K must be at least 1"))
    T ≥ K || throw(ArgumentError("T must be at least K, so every arm can be pulled once"))
end

_bandit_output(rewards, actions, return_history::Bool) =
    return_history ? (actions = actions, rewards = rewards) : rewards

function _solve(model::MyExploreFirstAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T);
    rewards = zeros(Float64, T, K); # rewards for each arm
    actions = zeros(Int, T); # selected arm, including pulls that earn zero
    totals = zeros(K); # reward sum for each arm
    pulls = zeros(Int, K); # actual pulls of each arm

    # Reserve at least one pull per arm and keep exploration within the horizon -
    Nₐ = clamp(round(Int, (T/K)^(2/3)*cbrt(log(T))), 1, fld(T, K));
    
    # exploration phase -
    counter = 1;
    for a ∈ 1:K
        for _ ∈ 1:Nₐ
            rewards[counter, a] = world(a); # store from action a
            actions[counter] = a;
            totals[a] += rewards[counter, a];
            pulls[a] += 1; # a zero reward still counts as a pull
            counter += 1;
        end
    end

    μ = totals ./ pulls; # average over every observed reward, including zeros

    # exploitation phase -
    a = argmax(μ); # compute the arm with best average reward
    for _ ∈ 1:(T - Nₐ*K)
        rewards[counter, a] = world(a); # store the reward
        actions[counter] = a;
        counter += 1;
    end
    
    # return -
    return _bandit_output(rewards, actions, return_history);
end

function _solve(model::MyEpsilonGreedyAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T);
    rewards = zeros(Float64, T, K); # rewards for each arm
    actions = zeros(Int, T); # selected arm in each round
    totals = zeros(K); # reward sum for each arm
    pulls = zeros(Int, K); # actual pulls of each arm

    # Pull every arm once before comparing sample means -
    for a ∈ 1:K
        rewards[a, a] = world(a);
        actions[a] = a;
        totals[a] = rewards[a, a];
        pulls[a] = 1;
    end

    for t ∈ (K+1):T
        ϵₜ = min(1.0, cbrt(K*log(t)/t)); # the L10c schedule, capped at probability one
        p = rand(); # decide whether to explore
        aₜ = 1;
        if (p ≤ ϵₜ)
            aₜ = rand(1:K); # uniformly random arm, possibly the current best
        else
            aₜ = argmax(totals ./ pulls); # highest sample mean; first arm breaks a tie
        end
        rewards[t, aₜ] = world(aₜ); # store the reward
        actions[t] = aₜ;
        totals[aₜ] += rewards[t, aₜ];
        pulls[aₜ] += 1;
    end

    # return -
    return _bandit_output(rewards, actions, return_history);
end

function _solve(model::MyUCB1AlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T);
    rewards = zeros(Float64, T, K); # rewards for each arm
    actions = zeros(Int, T); # selected arm in each round
    totals = zeros(K); # reward sum for each arm
    Nₐ = zeros(Int64, K); # number of times we have pulled each arm

    # try each arm once
    counter = 1;
    for a = 1:K
        rewards[counter, a] = world(a); # pull each arm once
        actions[counter] = a;
        totals[a] = rewards[counter, a];
        Nₐ[a] += 1; # increment the counter
        counter += 1;
    end
    
    # main loop -
    for t ∈ counter:T

        # Compute the UCB value from all observed rewards -
        tmp = zeros(Float64, K);
        μ = totals ./ Nₐ; # zero rewards contribute to the denominator
        
        for i ∈ 1:K
            tmp[i] = μ[i] + sqrt((2*log(t))/Nₐ[i]); # compute the UCB value
        end

        aₜ = argmax(tmp); # select the arm with the highest UCB value
        Nₐ[aₜ] += 1; # increment the counter
        rewards[t, aₜ] = world(aₜ); # store the reward
        actions[t] = aₜ;
        totals[aₜ] += rewards[t, aₜ];
    end

    # return -
    return _bandit_output(rewards, actions, return_history);
end

function _solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
    T::Int = 0, world::Function = _null, startdayindex::Int = 1)

    # initialize -
    K = model.K; # get the number of goods to choose from
    N = 2^K; # this is the maximum number of arms we can have (we have K goods, with each good being {0 | 1})
    μₒ = context.μₒ; # get the average rewards for each possible goods combination
   
    μ = zeros(Float64, N); # average reward for each possible goods combination
    R = zeros(Float64, T, N);
    S = zeros(Float64, T, K); # history of the number of shares 
    P = zeros(Float64, T, K); # history of fill prices for each asset
    G = zeros(Float64, T, K); # history of preferences

    # so before we start, go through every possible arm, and compute the average reward -
    # this means that we try each possible arm at least once, and compute the average reward
    for i ∈ 1:N
        aₜ = digits(i, base=2, pad=K); # generate a binary representation of the number, with K digits  
        if (i == N)
            aₜ = digits(i - 1, base=2, pad=K); # generate a binary representation of the number, with K digits  
        end
        r,n,p,γ = world(startdayindex, aₜ, context); # get the reward from the world (use the first day of the OOS data)
        μ[i] = μₒ[i]*(1-1/T) + (1/T)*r; # update the average reward for the chosen arm (learning rate = α)
        
        R[1, i] = r; # store the reward in the rewards array
        S[1, :] = n; # store the number of shares purchased in the first round
        P[1, :] = p; # store the probabilities in the first round
        G[1, :] = γ; # store the preferences in the first round
    end

    # main -
    for t ∈ 2:T
        ϵₜ = (1.0/(t^(1/3)))*(log(K*t))^(1/3); # compute the epsilon value -

        # if we were to purchase stuff, how much would we purchase?
        p = rand(); # role a random number
        aₜ = nothing; # initialize action vector
        î = nothing; # index of the combination of goods
        if (p ≤ ϵₜ)
            î = rand(1:N); # randomly select an integer from 1 to N (this will be used to generate a binary representation of the action vector)
        else
            î = argmax(μ); # compute the arm with best average reward
        end
        aₜ = digits(î, base=2, pad=K); # generate a binary representation of the number, with K digits  
        if (î == N)
            aₜ = digits(î - 1, base=2, pad=K); # generate a binary representation of the number, with K digits  
        end

        # call out to the world, record the result.
        rₜ, nₜ, pₜ, γₜ = world(startdayindex, aₜ, context); # get the reward from the world (use the first day of the OOS data)

        # for each arm, compute the reward -
        μ[î]+=(1/t)*(rₜ - μ[î]); # update the average reward for the chosen arm (learning rate = α)

        # store other data -
        R[t, î] = rₜ; # store the reward in the rewards array

        # @show t, î, R[t, î], μ[î]; # debug output

        S[t, :] = nₜ; # store the number of shares purchased in the first round
        P[t, :] = pₜ; # store the probabilities in the first round
        G[t, :] = γₜ; # store the preferences in the first round
    end

    # return -
    return R, μ, S, P, G;
end

# PRIVATE METHODS ABOVE HERE ================================================================================= #

# PUBLIC METHODS BELOW HERE ================================================================================== #`
"""
    solve(model::AbstractBanditAlgorithmModel; T::Int = 0, world::Function = _null,
        return_history::Bool = false)

Play a stationary stochastic bandit using explore-first, epsilon-greedy, or UCB1.
Each call to `world(a)` independently draws a reward in `[0, 1]` from arm `a`'s
fixed distribution. Rewards and round indices are dimensionless. All sample means
include zero rewards, and ties select the first maximizing arm.

### Arguments
- `model::AbstractBanditAlgorithmModel`: The model to use to solve the bandit problem.
- `T::Int = 0`: Number of rounds, at least `model.K`. Supply it explicitly.
- `world::Function = _null`: The function that returns the reward for a given action. Default is the private `_null` function.
- `return_history::Bool = false`: Return the selected arms as well as the reward matrix.

Explore-first pulls each arm `clamp(round(Int, (T/K)^(2/3)*cbrt(log(T))), 1, fld(T,K))`
times before committing. Epsilon-greedy and UCB1 first pull every arm once.
Epsilon-greedy then explores with probability `min(1, cbrt(K*log(t)/t))`.
UCB1 maximizes the sample mean plus `sqrt(2*log(t)/pulls[a])`.

### Returns
- By default, a `T × K` reward matrix. Row `t` stores the observed reward in
  column `a_t`, with zeros in all other columns. A selected arm can also earn zero.
- With `return_history = true`, `(actions, rewards)` where `actions::Vector{Int}`
  records the selected arm in every round and `rewards` is the same matrix.
  Use `actions` to count pulls; the reward matrix alone cannot identify a zero-reward pull.

Throws `ArgumentError` for `K < 1` or `T < K`.
"""
function solve(model::AbstractBanditAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)
    return _solve(model, T = T, world = world, return_history = return_history);
end


"""
    solve(model::AbstractBanditAlgorithmModel, context::AbstractBanditProblemContextModel;
        T::Int = 0, world::Function = _null)

Solve the contextual bandit problem using the given model and context.

### Arguments
- `model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`: The model to use to solve the bandit problem.
- `context::MyConsumerChoiceBanditContextModel`: The context model to use. Must be a subtype of `AbstractBanditProblemContextModel`.
- `T::Int = 0`: The number of rounds to play. Default is 0.
- `world::Function = _null`: The function that returns the reward for a given action. Default is the private `_null` function.
- `startdayindex::Int = 1`: The starting time index for the context model. Default is 1. This is useful for time series data.
"""
function solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
    T::Int = 0, world::Function = _null, startdayindex::Int = 1)
    return _solve(model, context, T = T, world = world, startdayindex = startdayindex);
end


"""
    regret(rewards::Array{Float64,2})::Array{Float64,1}

Compute the regret for the given rewards.

### Arguments
- `rewards::Array{Float64,2}`: The rewards for each arm at each round.

### Returns
- `Array{Float64,1}`: The regret at each round.
"""
function regret(rewards::Array{Float64,2})::Array{Float64,1}
    
    # initialize -
    T = size(rewards, 1); # how many rounds did we play?
    K = size(rewards, 2); # how many arms do we have?
    regret = zeros(Float64, T); # initialize the regret array

    # first: compute the best arm in hindsight -
    μ = zeros(Float64, K); # average reward for each arm
    for a ∈ 1:K
        μ[a] = findall(x -> x != 0.0, rewards[:, a]) |> i-> mean(rewards[i, a]); # compute the average reward
    end
    μₒ = maximum(μ); # compute the best average reward

    # compute the regret -
    for t ∈ 1:T

        # what action was taken at time t?
        tmp = 0.0;
        for j = 1:t
            aₜ = argmax(rewards[j, :]); # get the action that was taken
            tmp += μ[aₜ]; # compute the hypothetical average reward
        end
        regret[t] = μₒ*t - tmp; # compute the regret at time t
    end

    # return -
    return regret;
end
# PUBLIC METHODS ABOVE HERE ================================================================================== #`
