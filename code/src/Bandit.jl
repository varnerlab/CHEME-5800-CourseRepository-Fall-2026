# ------------------------------------------------------------------------------------------------ #
# Bandit.jl
#
# Multi-armed bandit algorithms used by the week-10 bandit material. The L10c UCB1 example checks
# its hand-played game against solve(...), and the L10d lab plays explore-first, epsilon-greedy,
# and UCB1 with solve(...).
#
# A bandit problem has K arms. In each round t = 1, 2, …, T, the agent pulls one arm aₜ and sees
# only the reward rₜ of that arm. The functions in this file never see the reward distributions.
# They call a world(a) function that the caller writes, and world(a) returns one reward of arm a.
#
# Public functions:
#   solve(model; T, world, return_history)   plays T rounds with explore-first, epsilon-greedy, or UCB1
#   solve(model, context; T, world, startdayindex)
#                                            plays T rounds of the consumer-choice bandit, whose arms
#                                            are bundles of goods (no notebook in this course uses it)
#   regret(rewards)                          estimates the regret curve of a game from its reward
#                                            matrix (no notebook in this course uses it)
#
# Private functions (a leading underscore marks a helper that the package does not export):
#   _null(action)                            a placeholder world that always returns a reward of 0
#   _check_bandit_horizon(K, T)              stops with an error unless K ≥ 1 and T ≥ K
#   _bandit_output(rewards, actions, return_history)
#                                            chooses what solve(...) returns
#   _solve(...)                              one method for each algorithm; solve(...) calls these
#
# Random numbers: epsilon-greedy and the consumer-choice bandit call rand() and rand(1:K). Both
# draw from Julia's default random number generator, the one that Random.seed!(seed) resets. In
# the course notebooks, world(a) draws from the same generator, so calling Random.seed!(seed)
# before solve(...) repeats the whole game exactly.
# ------------------------------------------------------------------------------------------------ #

# PRIVATE METHODS BELOW HERE ================================================================================= #

# A one-line function: `f(x) = expression` defines the function f, which returns the value of the expression.
"""
    _null(action::Int64) -> Int64

A placeholder world function that always returns a reward of 0, whatever arm is pulled.

The `solve(...)` methods use `_null` as the default value of their `world` keyword argument. For
the three bandit algorithms, a call that leaves out `world` still runs, but every reward is 0.
The consumer-choice method calls `world` with three arguments, so `_null` fails there with a
`MethodError`.

### Arguments
- `action::Int64`: the arm that was pulled. The function ignores it.

### Returns
- `Int64`: always `0`.
"""
_null(action::Int64)::Int64 = return 0;

"""
    _check_bandit_horizon(K::Int, T::Int) -> Bool

Check that a bandit game can be played before we start it. There must be at least one arm, and at
least as many rounds as arms, so that every arm can be pulled once.

### Arguments
- `K::Int`: the number of arms.
- `T::Int`: the number of rounds.

### Returns
- `Bool`: `true` when both checks pass. The `_solve(...)` methods ignore this value.

### Throws
- `ArgumentError` when `K < 1`, with the message "K must be at least 1".
- `ArgumentError` when `T < K`, with the message "T must be at least K, so every arm can be pulled once".
"""
function _check_bandit_horizon(K::Int, T::Int)

    # check the number of arms. `x || throw(...)` means: if x is false, stop with an error -
    K ≥ 1 || throw(ArgumentError("K must be at least 1"))

    # check the number of rounds: if T ≥ K is false, stop with an error -
    T ≥ K || throw(ArgumentError("T must be at least K, so every arm can be pulled once"))
end

# A one-line function written over two lines: the expression after `=` is the return value.
"""
    _bandit_output(rewards, actions, return_history::Bool) -> Union{Array{Float64,2}, NamedTuple}

Choose what a bandit `solve(...)` call returns: the reward matrix alone, or the reward matrix
together with the arm pulled in each round.

### Arguments
- `rewards`: the `T × K` reward matrix of the game. Row `t` holds the reward of round `t` in the
  column of the arm pulled in that round, and zeros in every other column.
- `actions`: the vector of length `T` that holds the arm pulled in each round.
- `return_history::Bool`: `true` to return both arrays, `false` to return the reward matrix only.

### Returns
- When `return_history` is `true`: the `NamedTuple` `(actions = actions, rewards = rewards)`.
- When `return_history` is `false`: the reward matrix `rewards`.
"""
_bandit_output(rewards, actions, return_history::Bool) =
    return_history ? (actions = actions, rewards = rewards) : rewards # if return_history is true, return both arrays in a NamedTuple; otherwise, return the reward matrix only

"""
    _solve(model::MyExploreFirstAlgorithmModel; T::Int = 0, world::Function = _null,
        return_history::Bool = false) -> Union{Array{Float64,2}, NamedTuple}

Play `T` rounds of a `K`-arm bandit with the explore-first algorithm.

The algorithm has two phases. In the exploration phase, it pulls each arm `N` times: arm 1 in the
first `N` rounds, then arm 2 in the next `N` rounds, and so on. The number of pulls per arm is
`N = (T/K)^(2/3)⋅(log T)^(1/3)`, where `log` is the natural logarithm. We round `N` to the nearest
integer (a value exactly halfway rounds to the even integer). We raise it to 1 if it is smaller, so
every arm is pulled at least once, and lower it to `⌊T/K⌋` if it is larger, so the exploration fits
in `T` rounds.

After exploration, we compute the sample mean reward `μ̄(a)` of each arm, the sum of its rewards
divided by `N`, and choose the arm `â` with the largest sample mean. A tie goes to the arm with the
smallest index. In the exploitation phase, we pull `â` in each of the remaining `T − K⋅N` rounds.

The function draws no random numbers itself. All randomness comes from `world`, which is called
`N` times for arm 1, then `N` times for arm 2, and so on, and then `T − K⋅N` times for arm `â`.

### Arguments
- `model::MyExploreFirstAlgorithmModel`: the algorithm. We use its number of arms, `model.K`.
- `T::Int = 0`: the number of rounds. It must be at least `K`, so always pass it.
- `world::Function = _null`: the function `world(a)` that returns one reward of arm `a`.
- `return_history::Bool = false`: `true` to also return the arm pulled in each round.

### Returns
- With `return_history = false`: the `T × K` reward matrix. Row `t` holds the reward of round `t`
  in the column of the arm pulled in that round, and zeros in every other column.
- With `return_history = true`: the `NamedTuple` `(actions = actions, rewards = rewards)`, where
  `actions` is the vector of length `T` that holds the arm pulled in each round.

### Throws
- `ArgumentError` when `K < 1` or `T < K` (see `_check_bandit_horizon`).
"""
function _solve(model::MyExploreFirstAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T); # stop with an error unless K ≥ 1 and T ≥ K
    rewards = zeros(Float64, T, K); # rewards[t, a]: the reward of round t, in the column of the arm a pulled in round t
    actions = zeros(Int, T); # actions[t]: the arm pulled in round t, including pulls that earn zero
    totals = zeros(K); # totals[a]: the sum of the rewards of arm a during exploration
    pulls = zeros(Int, K); # pulls[a]: the number of times we pulled arm a during exploration

    # compute Nₐ, the number of pulls per arm (N in the lecture): (T/K)^(2/3)⋅(log T)^(1/3), rounded
    # to the nearest integer, then clamped between 1 (every arm is pulled at least once) and
    # fld(T, K) = ⌊T/K⌋ (the exploration fits in T rounds). cbrt(x) is the cube root of x -
    Nₐ = clamp(round(Int, (T/K)^(2/3)*cbrt(log(T))), 1, fld(T, K));

    # exploration phase: pull arm 1 Nₐ times, then arm 2 Nₐ times, and so on -
    counter = 1; # the current round t
    for a ∈ 1:K
        for _ ∈ 1:Nₐ # `_` is a loop variable we never use: we only repeat the body Nₐ times
            rewards[counter, a] = world(a); # pull arm a and store its reward in row t = counter, column a
            actions[counter] = a; # record the arm pulled in this round
            totals[a] += rewards[counter, a]; # add the reward to the total of arm a (x += y means x = x + y)
            pulls[a] += 1; # a zero reward still counts as a pull
            counter += 1; # move to the next round
        end
    end

    # compute the sample mean reward μ̄(a) of each arm. The ./ divides each total by the pull count
    # of the same arm, element by element, and zero rewards count in the average -
    μ = totals ./ pulls;

    # exploitation phase: pull the arm with the largest sample mean in every remaining round -
    a = argmax(μ); # â, the arm with the largest sample mean; argmax returns the first index on a tie
    for _ ∈ 1:(T - Nₐ*K) # the T − K⋅Nₐ rounds left after exploration
        rewards[counter, a] = world(a); # pull arm â and store its reward in row t = counter, column â
        actions[counter] = a; # record the arm pulled in this round
        counter += 1; # move to the next round
    end

    # return the reward matrix, and also the actions when return_history is true -
    return _bandit_output(rewards, actions, return_history);
end

"""
    _solve(model::MyEpsilonGreedyAlgorithmModel; T::Int = 0, world::Function = _null,
        return_history::Bool = false) -> Union{Array{Float64,2}, NamedTuple}

Play `T` rounds of a `K`-arm bandit with the epsilon-greedy algorithm.

The algorithm first pulls each arm once: arm `a` in round `a`, for `a = 1, 2, …, K`. Then, in each
round `t = K+1, K+2, …, T`, it takes four steps:
1. Compute the exploration probability `ϵₜ = min(1, (K⋅log t / t)^(1/3))`, where `log` is the
   natural logarithm.
2. Draw a uniform random number `u` between 0 and 1. If `u ≤ ϵₜ`, explore: choose an arm uniformly
   at random from `1, 2, …, K`, which can be the current best arm. Otherwise, exploit: choose the arm
   with the largest sample mean reward `μ̄(a)`. A tie goes to the arm with the smallest index.
3. Pull the chosen arm `aₜ` and receive the reward `rₜ`.
4. Add `rₜ` to the total reward of arm `aₜ` and add 1 to its pull count `Nₐ`. The sample mean
   `μ̄(a)` is the total reward of arm `a` divided by `Nₐ`.

Random draws, in order: the first `K` rounds call `world(1)`, `world(2)`, …, `world(K)`. Each later
round calls `rand()` for `u`, then `rand(1:K)` for the arm only when it explores, then `world(aₜ)`.
Both `rand` calls use Julia's default random number generator, so `Random.seed!(seed)` before the
call repeats the algorithm's draws. The whole game repeats when `world` also draws from the default
generator, as in the course notebooks.

### Arguments
- `model::MyEpsilonGreedyAlgorithmModel`: the algorithm. We use its number of arms, `model.K`.
- `T::Int = 0`: the number of rounds. It must be at least `K`, so always pass it.
- `world::Function = _null`: the function `world(a)` that returns one reward of arm `a`.
- `return_history::Bool = false`: `true` to also return the arm pulled in each round.

### Returns
- With `return_history = false`: the `T × K` reward matrix. Row `t` holds the reward of round `t`
  in the column of the arm pulled in that round, and zeros in every other column.
- With `return_history = true`: the `NamedTuple` `(actions = actions, rewards = rewards)`, where
  `actions` is the vector of length `T` that holds the arm pulled in each round.

### Throws
- `ArgumentError` when `K < 1` or `T < K` (see `_check_bandit_horizon`).
"""
function _solve(model::MyEpsilonGreedyAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T); # stop with an error unless K ≥ 1 and T ≥ K
    rewards = zeros(Float64, T, K); # rewards[t, a]: the reward of round t, in the column of the arm a pulled in round t
    actions = zeros(Int, T); # actions[t]: the arm pulled in round t
    totals = zeros(K); # totals[a]: the sum of the rewards of arm a
    pulls = zeros(Int, K); # pulls[a]: Nₐ, the number of times we pulled arm a, including pulls that earn zero

    # pull every arm once, so each arm has a sample mean before we compare them -
    for a ∈ 1:K
        rewards[a, a] = world(a); # round a pulls arm a, so the reward goes in row a, column a
        actions[a] = a; # record the arm pulled in round a
        totals[a] = rewards[a, a]; # the total reward of arm a so far
        pulls[a] = 1; # arm a now has one pull
    end

    # main loop: one round t per pass -
    for t ∈ (K+1):T

        # step 1: compute the exploration probability from the L10c lecture, capped at 1 -
        ϵₜ = min(1.0, cbrt(K*log(t)/t)); # cbrt(x) is the cube root of x

        # step 2: choose the arm aₜ: explore with probability ϵₜ, otherwise exploit -
        p = rand(); # u, a uniform random number between 0 and 1, from the default generator
        aₜ = 1; # the arm we pull this round, chosen below
        if (p ≤ ϵₜ)
            aₜ = rand(1:K); # explore: an arm chosen uniformly at random, which can be the current best arm
        else
            aₜ = argmax(totals ./ pulls); # exploit: the arm with the largest sample mean totals[a]/pulls[a]; argmax returns the first index on a tie
        end

        # step 3: pull arm aₜ, and record the arm and the reward -
        rewards[t, aₜ] = world(aₜ); # store the reward in row t, column aₜ
        actions[t] = aₜ; # record the arm pulled in round t

        # step 4: update the total reward and the pull count of arm aₜ -
        totals[aₜ] += rewards[t, aₜ]; # add the reward to the total of arm aₜ (x += y means x = x + y)
        pulls[aₜ] += 1; # one more pull of arm aₜ
    end

    # return the reward matrix, and also the actions when return_history is true -
    return _bandit_output(rewards, actions, return_history);
end

"""
    _solve(model::MyUCB1AlgorithmModel; T::Int = 0, world::Function = _null,
        return_history::Bool = false) -> Union{Array{Float64,2}, NamedTuple}

Play `T` rounds of a `K`-arm bandit with the UCB1 algorithm.

The algorithm first pulls each arm once: arm `a` in round `a`, for `a = 1, 2, …, K`. Then, in each
round `t = K+1, K+2, …, T`, it computes the upper confidence bound of each arm `a`, the sample mean
reward `μ̄(a)` plus the confidence radius `U(a,t)`:

`μ̄(a) + U(a,t)`, with `U(a,t) = sqrt(2⋅log(t) / Nₐ)`.

Here `μ̄(a)` is the total reward of arm `a` divided by `Nₐ`, `Nₐ` is the number of times arm `a` has
been pulled before round `t`, and `log` is the natural logarithm. The algorithm pulls the arm with
the largest bound, and a tie goes to the arm with the smallest index. The radius is large for an arm
with few pulls, so the algorithm keeps returning to the arms it knows least about.

The function draws no random numbers itself. All randomness comes from `world`, which is called
once per round, in round order.

### Arguments
- `model::MyUCB1AlgorithmModel`: the algorithm. We use its number of arms, `model.K`.
- `T::Int = 0`: the number of rounds. It must be at least `K`, so always pass it.
- `world::Function = _null`: the function `world(a)` that returns one reward of arm `a`.
- `return_history::Bool = false`: `true` to also return the arm pulled in each round.

### Returns
- With `return_history = false`: the `T × K` reward matrix. Row `t` holds the reward of round `t`
  in the column of the arm pulled in that round, and zeros in every other column.
- With `return_history = true`: the `NamedTuple` `(actions = actions, rewards = rewards)`, where
  `actions` is the vector of length `T` that holds the arm pulled in each round.

### Throws
- `ArgumentError` when `K < 1` or `T < K` (see `_check_bandit_horizon`).
"""
function _solve(model::MyUCB1AlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # initialize -
    K = model.K; # number of arms
    _check_bandit_horizon(K, T); # stop with an error unless K ≥ 1 and T ≥ K
    rewards = zeros(Float64, T, K); # rewards[t, a]: the reward of round t, in the column of the arm a pulled in round t
    actions = zeros(Int, T); # actions[t]: the arm pulled in round t
    totals = zeros(K); # totals[a]: the sum of the rewards of arm a
    Nₐ = zeros(Int64, K); # Nₐ[a]: the number of times we have pulled arm a

    # pull every arm once, so every arm has a sample mean and Nₐ[a] ≥ 1 before we compute a radius -
    counter = 1; # the current round t
    for a = 1:K # `for a = 1:K` is the same loop as `for a ∈ 1:K`
        rewards[counter, a] = world(a); # round a pulls arm a, so the reward goes in row a, column a
        actions[counter] = a; # record the arm pulled in round a
        totals[a] = rewards[counter, a]; # the total reward of arm a so far
        Nₐ[a] += 1; # arm a now has one pull (x += y means x = x + y)
        counter += 1; # move to the next round
    end

    # main loop: one round t per pass, from round K + 1 (the value of counter now) to round T -
    for t ∈ counter:T

        # compute the upper confidence bound of each arm from all observed rewards -
        tmp = zeros(Float64, K); # tmp[i]: the upper confidence bound of arm i in round t
        μ = totals ./ Nₐ; # μ̄(a) of each arm: ./ divides element by element, and zero rewards count in the average

        for i ∈ 1:K
            tmp[i] = μ[i] + sqrt((2*log(t))/Nₐ[i]); # μ̄(i) + U(i,t), with the radius U(i,t) = sqrt(2⋅log(t)/Nᵢ)
        end

        # pull the arm with the largest bound, and record the arm and the reward -
        aₜ = argmax(tmp); # the arm with the largest upper confidence bound; argmax returns the first index on a tie
        Nₐ[aₜ] += 1; # one more pull of arm aₜ
        rewards[t, aₜ] = world(aₜ); # pull arm aₜ and store its reward in row t, column aₜ
        actions[t] = aₜ; # record the arm pulled in round t
        totals[aₜ] += rewards[t, aₜ]; # add the reward to the total of arm aₜ
    end

    # return the reward matrix, and also the actions when return_history is true -
    return _bandit_output(rewards, actions, return_history);
end

"""
    _solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
        T::Int = 0, world::Function = _null, startdayindex::Int = 1) -> Tuple

Play `T` rounds of the consumer-choice bandit with an epsilon-greedy rule. Each arm is a bundle of
`K` goods: a vector of `K` zeros and ones, where a 1 means the bundle includes that good. No
notebook in this course calls this method.

__Arms and bundles.__ There are `N = 2^K` arms. Arm `i` uses the binary digits of `i`, least
significant digit first, padded with zeros to `K` digits; Julia's `digits(i, base=2, pad=K)` makes
this vector. The binary digits of `N` itself need `K+1` digits, so arm `N` uses the digits of
`N − 1` instead. As a result, arms `N − 1` and `N` both choose every good, and no arm chooses the
empty bundle.

__The world.__ The call `world(startdayindex, aₜ, context)` returns four values `(r, n, p, γ)`: the
reward `r` of the bundle `aₜ`, and three vectors of length `K` that we store without using. Every
call passes the same `startdayindex`.

__The method.__
1. Initialize: for each arm `i = 1, 2, …, N`, call the world once with the bundle of arm `i`. Set
   the estimated reward `μ[i] = (1 − 1/T)⋅μₒ[i] + (1/T)⋅r`, a blend of the starting estimate
   `μₒ[i]` from the context and the observed reward `r`.
2. For each round `t = 2, 3, …, T`: compute `ϵₜ = (log(K⋅t) / t)^(1/3)`, which is not capped at 1.
   Draw a uniform random number `u` between 0 and 1. If `u ≤ ϵₜ`, choose the arm `î` uniformly at
   random from `1, 2, …, N`. Otherwise, choose the arm with the largest `μ`, the first one on a tie.
   Call the world with the bundle of arm `î` and receive the reward `rₜ`. Move `μ[î]` a fraction
   `1/t` of the way toward the reward: `μ[î] ← μ[î] + (1/t)⋅(rₜ − μ[î])`.

Random draws, in order: the `N` world calls of step 1; then, in each round, `rand()` for `u`,
`rand(1:N)` only when exploring, and the world call. Both `rand` calls use Julia's default random
number generator.

### Arguments
- `model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`: the algorithm. We use `model.K`, the
  number of goods.
- `context::MyConsumerChoiceBanditContextModel`: the problem data. We use `context.μₒ`, the starting
  estimate of the reward of each of the `N` arms, and pass `context` on to `world`.
- `T::Int = 0`: the number of rounds. It must be at least 1: with `T = 0`, the first store into
  the reward history fails with a `BoundsError`.
- `world::Function = _null`: the function `world(startdayindex, aₜ, context)` described above. The
  default `_null` takes one argument, so it fails with a `MethodError`; always pass `world`.
- `startdayindex::Int = 1`: the day index passed to `world` in every call.

### Returns
A tuple `(R, μ, S, P, G)`:
- `R::Array{Float64,2}`: the `T × N` reward history. Row 1 holds the reward of every arm from
  step 1. Row `t ≥ 2` holds the reward of round `t` in the column of the arm chosen, and zeros
  elsewhere.
- `μ::Array{Float64,1}`: the final estimated reward of each of the `N` arms.
- `S`, `P`, `G::Array{Float64,2}`: the `T × K` histories of the second, third, and fourth values
  that `world` returns; the comments in the code call them shares purchased, prices, and
  preferences. Row 1 holds the values from the last call of step 1, the call for arm `N`.

### Throws
- `BoundsError` when `T = 0`, at the first store into the reward history.
- `ArgumentError` when `T` is negative, because the history arrays cannot have a negative size.
"""
function _solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
    T::Int = 0, world::Function = _null, startdayindex::Int = 1)

    # initialize -
    K = model.K; # the number of goods to choose from
    N = 2^K; # the number of arms: each of the K goods is either in the bundle (1) or not (0)
    μₒ = context.μₒ; # the starting estimate of the reward of each arm (bundle of goods)

    μ = zeros(Float64, N); # μ[i]: the estimated reward of arm i
    R = zeros(Float64, T, N); # R[t, i]: the reward history, one row per round and one column per arm
    S = zeros(Float64, T, K); # history of the second value world returns (the number of shares)
    P = zeros(Float64, T, K); # history of the third value world returns (the prices)
    G = zeros(Float64, T, K); # history of the fourth value world returns (the preferences)

    # step 1: try every arm once, and blend its reward into the starting estimate.
    # digits(i, base=2, pad=K) returns the binary digits of i, least significant first, padded with zeros to at least K entries -
    for i ∈ 1:N
        aₜ = digits(i, base=2, pad=K); # the bundle of arm i: the binary digits of i
        if (i == N)
            aₜ = digits(i - 1, base=2, pad=K); # N = 2^K needs K+1 binary digits, so arm N uses the digits of N − 1 (every good)
        end
        r,n,p,γ = world(startdayindex, aₜ, context); # the world returns four values; we unpack them into r, n, p, γ
        μ[i] = μₒ[i]*(1-1/T) + (1/T)*r; # blend: (1 − 1/T)⋅μₒ[i] + (1/T)⋅r

        R[1, i] = r; # row 1 holds the reward of every arm
        S[1, :] = n; # store n in row 1 (each arm overwrites it, so arm N's values remain)
        P[1, :] = p; # store p in row 1 (each arm overwrites it)
        G[1, :] = γ; # store γ in row 1 (each arm overwrites it)
    end

    # step 2, main loop: one round t per pass -
    for t ∈ 2:T
        ϵₜ = (1.0/(t^(1/3)))*(log(K*t))^(1/3); # the exploration probability (log(K⋅t)/t)^(1/3), not capped at 1

        # choose the arm î: explore with probability ϵₜ, otherwise exploit -
        p = rand(); # u, a uniform random number between 0 and 1, from the default generator
        aₜ = nothing; # the bundle we choose, set below (nothing is Julia's "no value yet")
        î = nothing; # the index of the arm we choose, set below
        if (p ≤ ϵₜ)
            î = rand(1:N); # explore: an arm chosen uniformly at random from 1, 2, …, N
        else
            î = argmax(μ); # exploit: the arm with the largest estimated reward; argmax returns the first index on a tie
        end
        aₜ = digits(î, base=2, pad=K); # the bundle of arm î: the binary digits of î
        if (î == N)
            aₜ = digits(î - 1, base=2, pad=K); # arm N uses the digits of N − 1, as in step 1
        end

        # call the world with the bundle, and unpack the four values it returns -
        rₜ, nₜ, pₜ, γₜ = world(startdayindex, aₜ, context); # every call passes the same startdayindex

        # move μ[î] a fraction 1/t of the way toward the reward rₜ (x += y means x = x + y) -
        μ[î]+=(1/t)*(rₜ - μ[î]);

        # store the reward in row t, column î -
        R[t, î] = rₜ;

        # @show t, î, R[t, î], μ[î]; # debug output (commented out, so it does not run)

        # store the other three values in row t -
        S[t, :] = nₜ; # the second value world returns (the number of shares)
        P[t, :] = pₜ; # the third value world returns (the prices)
        G[t, :] = γₜ; # the fourth value world returns (the preferences)
    end

    # return the five arrays as a tuple -
    return R, μ, S, P, G;
end

# PRIVATE METHODS ABOVE HERE ================================================================================= #

# PUBLIC METHODS BELOW HERE ================================================================================== #
"""
    solve(model::AbstractBanditAlgorithmModel; T::Int = 0, world::Function = _null,
        return_history::Bool = false) -> Union{Array{Float64,2}, NamedTuple}

Play `T` rounds of a stationary stochastic bandit with the explore-first, epsilon-greedy, or UCB1
algorithm, chosen by the type of `model`.

Each call to `world(a)` should draw one reward of arm `a`, independently, from the arm's fixed
reward distribution, with rewards between 0 and 1. The algorithms see only these rewards. Every
sample mean includes the rewards that are exactly zero, and every tie goes to the arm with the
smallest index.

The three algorithms:
- Explore-first pulls each arm `N` times, where `N = (T/K)^(2/3)⋅(log T)^(1/3)` rounded to the
  nearest integer and kept between 1 and `⌊T/K⌋`. Then it pulls the arm with the largest sample
  mean for the rest of the game.
- Epsilon-greedy pulls every arm once. Then, in round `t`, it pulls a random arm with probability
  `ϵₜ = min(1, (K⋅log t / t)^(1/3))`, and otherwise the arm with the largest sample mean.
- UCB1 pulls every arm once. Then, in round `t`, it pulls the arm with the largest
  `μ̄(a) + sqrt(2⋅log(t) / Nₐ)`, where `μ̄(a)` is the sample mean and `Nₐ` the pull count of arm `a`.

Random draws: only epsilon-greedy draws random numbers itself, with `rand()` and `rand(1:K)` from
Julia's default random number generator. Call `Random.seed!(seed)` before `solve(...)` to repeat a
game; the course notebooks' `world(a)` functions draw from the same generator. The `_solve(...)`
method of each algorithm gives the order of the draws.

### Arguments
- `model::AbstractBanditAlgorithmModel`: the algorithm, built with `build(...)`: a
  `MyExploreFirstAlgorithmModel`, `MyEpsilonGreedyAlgorithmModel`, or `MyUCB1AlgorithmModel`. We use
  its number of arms, `model.K`.
- `T::Int = 0`: the number of rounds. It must be at least `model.K`, so always pass it.
- `world::Function = _null`: the function `world(a)` that returns one reward of arm `a`. The default,
  the private `_null` function, always returns 0.
- `return_history::Bool = false`: `true` to also return the arm pulled in each round.

### Returns
- With `return_history = false`: the `T × K` reward matrix. Row `t` holds the reward of round `t`
  in the column of the arm `aₜ` pulled in that round, and zeros in every other column. A pulled arm
  can also earn zero.
- With `return_history = true`: the `NamedTuple` `(actions = actions, rewards = rewards)`.
  `actions::Vector{Int}` holds the arm pulled in each round, and `rewards` is the same matrix. Use
  `actions` to count pulls, because the reward matrix alone cannot show a pull that earned zero.

### Throws
- `ArgumentError` when `model.K < 1` or `T < model.K`.

### Example
```julia
using Random, Distributions
arms = [Beta(2.0, 2.0), Beta(10.0, 2.0), Beta(2.0, 10.0)]; # the reward distribution of each arm
world = a -> rand(arms[a]); # one reward of arm a
Random.seed!(5800); # the same seed gives the same game
m = build(MyUCB1AlgorithmModel, (K = 3,));
game = solve(m, T = 1000, world = world, return_history = true);
game.actions # the arm pulled in each round
```
"""
function solve(model::AbstractBanditAlgorithmModel; T::Int = 0, world::Function = _null,
    return_history::Bool = false)

    # call the _solve(...) method for the type of model, and return what it returns -
    return _solve(model, T = T, world = world, return_history = return_history);
end


"""
    solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
        T::Int = 0, world::Function = _null, startdayindex::Int = 1) -> Tuple

Play `T` rounds of the consumer-choice bandit, whose arms are bundles of goods, with an
epsilon-greedy rule. This function passes its arguments to the private `_solve(...)` method for
these two types; that method's documentation describes the algorithm and the order of the random
draws. No notebook in this course calls this method.

### Arguments
- `model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`: the algorithm. We use `model.K`, the
  number of goods, which gives `N = 2^K` arms.
- `context::MyConsumerChoiceBanditContextModel`: the problem data. We use `context.μₒ`, the starting
  estimate of the reward of each arm, and pass `context` on to `world`.
- `T::Int = 0`: the number of rounds. It must be at least 1, so always pass it.
- `world::Function = _null`: the function `world(startdayindex, aₜ, context)` that returns the
  reward of the bundle `aₜ` and three vectors of length `K`. Always pass it: the default `_null`
  takes one argument and fails with a `MethodError`.
- `startdayindex::Int = 1`: the day index passed to `world` in every call.

### Returns
- A tuple `(R, μ, S, P, G)`: the `T × N` reward history, the final estimated reward of each arm,
  and the `T × K` histories of the other three values `world` returns.
"""
function solve(model::MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, context::MyConsumerChoiceBanditContextModel;
    T::Int = 0, world::Function = _null, startdayindex::Int = 1)

    # call the private method that plays the game, and return what it returns -
    return _solve(model, context, T = T, world = world, startdayindex = startdayindex);
end


"""
    regret(rewards::Array{Float64,2}) -> Array{Float64,1}

Estimate the regret curve of one bandit game from its `T × K` reward matrix. No notebook in this
course calls this function: the L10d lab computes its regret curves from the true arm means.

The function does not know the true mean reward of any arm, so it estimates each one from the game:
- `μ[a]` is the average of the nonzero entries in column `a` of `rewards`. Zero entries are skipped,
  so a pull that earned exactly 0 does not count. A column with no nonzero entry gives `NaN` (not a
  number), and then every entry of the result is `NaN`.
- `μ⋆` is the largest estimated mean, `max μ[a]`.
- The arm `aⱼ` pulled in round `j` is taken to be `argmax(rewards[j, :])`, the column of the largest
  entry in row `j`. For a row of zeros, `argmax` returns 1, so a pull that earned 0 counts as a pull
  of arm 1. This works only when the rewards are not negative.

The estimated regret after `t` rounds is `R(t) = t⋅μ⋆ − Σⱼ μ[aⱼ]`, with the sum over
`j = 1, 2, …, t`. This is the lecture's gap loss, `Σⱼ (μ⋆ − μ[aⱼ])`, computed with the estimated
means. It is not the lab's regret, `t⋅μ⋆ − Σⱼ rⱼ`, which uses the true `μ⋆` and the rewards themselves.

### Arguments
- `rewards::Array{Float64,2}`: the `T × K` reward matrix from `solve(...)`: one row per round and
  one column per arm, with the reward of each round in the column of the arm pulled and zeros
  elsewhere.

### Returns
- `Array{Float64,1}`: the vector of length `T` whose entry `t` is the estimated regret after `t` rounds.
"""
function regret(rewards::Array{Float64,2})::Array{Float64,1}

    # initialize -
    T = size(rewards, 1); # the number of rounds (rows)
    K = size(rewards, 2); # the number of arms (columns)
    regret = zeros(Float64, T); # regret[t]: the estimated regret after t rounds (a local variable with the same name as the function)

    # first: estimate the mean reward of each arm from its nonzero rewards.
    # findall(x -> x != 0.0, column) returns the rows where the column is not zero; `x -> ...` is an
    # anonymous function, a function with no name. The |> (pipe) passes those rows to a second
    # anonymous function, i -> mean(rewards[i, a]), which averages the entries of column a in those rows -
    μ = zeros(Float64, K); # μ[a]: the estimated mean reward of arm a
    for a ∈ 1:K
        μ[a] = findall(x -> x != 0.0, rewards[:, a]) |> i-> mean(rewards[i, a]); # NaN when column a has no nonzero entry
    end
    μₒ = maximum(μ); # μ⋆, the largest estimated mean reward (NaN if any μ[a] is NaN)

    # compute the estimated regret after each round t -
    for t ∈ 1:T

        # add up the estimated mean reward of the arm pulled in each round j = 1, …, t -
        tmp = 0.0; # Σⱼ μ[aⱼ] over the rounds so far
        for j = 1:t
            aₜ = argmax(rewards[j, :]); # the arm pulled in round j: the column of the largest entry in row j (arm 1 for a row of zeros)
            tmp += μ[aₜ]; # add the estimated mean reward of that arm (x += y means x = x + y)
        end
        regret[t] = μₒ*t - tmp; # R(t) = t⋅μ⋆ − Σⱼ μ[aⱼ]
    end

    # return the regret curve -
    return regret;
end
# PUBLIC METHODS ABOVE HERE ================================================================================== #
