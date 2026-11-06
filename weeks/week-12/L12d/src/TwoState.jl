# =============================================================================
# CHEME 5800 | L12d lab: overestimation, Double Q-learning, and Double DQN
# =============================================================================
# This file holds the code of the lab:
#
#   maxbias(...)           the largest of several noisy estimates, with one or two sets of samples
#   greedyaction(...)      the action with the largest value; a tie is broken at random
#   twostate_qlearning(...)  Q-learning or Double Q-learning on the two-state problem
#   twostate_dqn(...)        DQN or Double DQN on the two-state problem
#
# The two-state problem (Sutton and Barto, 2018, Example 6.7) has a start state A and a state B.
# In A, the action "right" ends the episode with reward 0, and the action "left" moves to B with
# reward 0. In B, each of nB actions ends the episode with a reward drawn from a normal
# distribution with mean μ and standard deviation 1. With μ < 0, "right" is the better action.
#
# This code is complete. There is nothing to edit in this lab.
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12dTwoState

using Random # Xoshiro, a seeded random number generator

export maxbias, greedyaction, twostate_qlearning, twostate_dqn

"""
    maxbias(; nactions::Int64 = 10, nsamples::Int64 = 10, μ::Float64 = -0.1,
        trials::Int64 = 10_000, seed::Int64 = 1234) -> NamedTuple

Estimate the largest true action value from noisy samples, two ways, and average each estimate
over many trials. Every action has the same true value `μ`. In each trial, we draw `nsamples`
rewards for each action from a normal distribution with mean `μ` and standard deviation 1.

- The __single estimate__ averages all the rewards of each action, then takes the largest average.
- The __double estimate__ splits the rewards of each action into two halves. The first halves
  pick the action with the largest average, and the second halves report that action's average.

### Arguments
- `nactions::Int64 = 10`: the number of actions.
- `nsamples::Int64 = 10`: the number of rewards drawn for each action; an even number.
- `μ::Float64 = -0.1`: the true value of every action.
- `trials::Int64 = 10_000`: the number of trials to average over.
- `seed::Int64 = 1234`: the seed of the random number generator.

### Returns
A `NamedTuple` with the fields `single` and `double`: the average of each estimate over the
trials. An estimate whose average is above `μ` overestimates the largest true value.
"""
function maxbias(; nactions::Int64 = 10, nsamples::Int64 = 10, μ::Float64 = -0.1,
    trials::Int64 = 10_000, seed::Int64 = 1234)::NamedTuple

    # initialize -
    rng = Xoshiro(seed); # the seeded random number generator
    half = div(nsamples, 2); # the number of rewards in each half
    single_total = 0.0; # the sum of the single estimates over the trials
    double_total = 0.0; # the sum of the double estimates over the trials

    # main loop: one trial per pass -
    for trial ∈ 1:trials

        # draw the rewards: one row per action, one column per sample -
        rewards = μ .+ randn(rng, nactions, nsamples);

        # the average of each action: over all samples, and over each half -
        average_all = zeros(nactions);
        average_first = zeros(nactions);
        average_second = zeros(nactions);
        for a ∈ 1:nactions
            average_all[a] = sum(rewards[a, :])/nsamples;
            average_first[a] = sum(rewards[a, 1:half])/half;
            average_second[a] = sum(rewards[a, (half + 1):(2*half)])/half;
        end

        # the single estimate: the largest average -
        single_total = single_total + maximum(average_all);

        # the double estimate: the first halves choose, the second halves report -
        best = argmax(average_first);
        double_total = double_total + average_second[best];
    end

    # return the averages over the trials -
    return (single = single_total/trials, double = double_total/trials);
end

"""
    greedyaction(values::Array{Float64,1}, rng::AbstractRNG) -> Int64

Return the index of the largest entry of `values`. If several entries tie for the largest, pick
one of them at random with the generator `rng`.
"""
function greedyaction(values::Array{Float64,1}, rng::AbstractRNG)::Int64

    # collect every index that holds the largest value -
    largest = maximum(values);
    best = Array{Int64,1}();
    for a ∈ 1:length(values)
        if (values[a] == largest)
            push!(best, a);
        end
    end

    # pick one of them at random -
    return best[rand(rng, 1:length(best))];
end

"""
    epsilongreedy(values::Array{Float64,1}, ϵ::Float64, rng::AbstractRNG) -> Int64

Choose an action ϵ-greedily: with probability `ϵ` a random action, and otherwise the action with
the largest value.
"""
function epsilongreedy(values::Array{Float64,1}, ϵ::Float64, rng::AbstractRNG)::Int64
    if (rand(rng) < ϵ)
        return rand(rng, 1:length(values)); # explore: a random action
    end
    return greedyaction(values, rng); # exploit: the action with the largest value
end

"""
    twostate_qlearning(; double::Bool = false, episodes::Int64 = 300, runs::Int64 = 1000,
        nB::Int64 = 10, μ::Float64 = -0.1, α::Float64 = 0.1, ϵ::Float64 = 0.1,
        seed::Int64 = 1234) -> Array{Float64,1}

Train `runs` independent agents on the two-state problem with Q-learning, or with Double
Q-learning if `double = true`, and return the fraction of the agents that chose "left" in state A
in each episode. The discount factor is 1.

- __Q-learning__ keeps one table. The target of "left" in A is `0 + max over b of QB[b]`.
- __Double Q-learning__ keeps two tables and acts on their sum. After each step, a coin flip picks
  the table to update. Its target uses the action that the updated table rates best, scored by
  the other table.

### Arguments
- `double::Bool = false`: `true` for Double Q-learning.
- `episodes::Int64 = 300`: the number of episodes of each agent.
- `runs::Int64 = 1000`: the number of agents, each with its own random numbers.
- `nB::Int64 = 10`: the number of actions in state B.
- `μ::Float64 = -0.1`: the mean reward of every action in B.
- `α::Float64 = 0.1`: the learning rate.
- `ϵ::Float64 = 0.1`: the exploration probability.
- `seed::Int64 = 1234`: agent `k` uses the seed `seed + k`.

### Returns
- `Array{Float64,1}`: entry `i` is the fraction of the agents that chose "left" in episode `i`.
"""
function twostate_qlearning(; double::Bool = false, episodes::Int64 = 300, runs::Int64 = 1000,
    nB::Int64 = 10, μ::Float64 = -0.1, α::Float64 = 0.1, ϵ::Float64 = 0.1,
    seed::Int64 = 1234)::Array{Float64,1}

    # initialize -
    left_count = zeros(episodes); # the number of agents that chose "left" in each episode

    # one independent agent per run -
    for k ∈ 1:runs
        rng = Xoshiro(seed + k);

        # the tables: A has the actions left (1) and right (2); B has nB actions -
        QA1 = zeros(2);
        QB1 = zeros(nB);
        QA2 = zeros(2); # the second tables, used only by Double Q-learning
        QB2 = zeros(nB);

        for i ∈ 1:episodes

            # in state A: choose left or right from the table (or the sum of the two tables) -
            a = 0;
            if (double == true)
                a = epsilongreedy(QA1 .+ QA2, ϵ, rng);
            else
                a = epsilongreedy(QA1, ϵ, rng);
            end

            # right: the episode ends with reward 0, and the target is 0 -
            if (a == 2)
                if (double == true && rand(rng) < 0.5)
                    QA2[2] = QA2[2] + α*(0.0 - QA2[2]);
                elseif (double == true)
                    QA1[2] = QA1[2] + α*(0.0 - QA1[2]);
                else
                    QA1[2] = QA1[2] + α*(0.0 - QA1[2]);
                end
                continue; # the next episode
            end

            # left: move to B with reward 0, and update the value of "left" -
            left_count[i] = left_count[i] + 1;
            if (double == true && rand(rng) < 0.5)
                target = 0.0 + QB1[argmax(QB2)]; # table 2 chooses, table 1 scores
                QA2[1] = QA2[1] + α*(target - QA2[1]);
            elseif (double == true)
                target = 0.0 + QB2[argmax(QB1)]; # table 1 chooses, table 2 scores
                QA1[1] = QA1[1] + α*(target - QA1[1]);
            else
                target = 0.0 + maximum(QB1); # one table chooses and scores
                QA1[1] = QA1[1] + α*(target - QA1[1]);
            end

            # in state B: choose an action; the episode ends with a random reward -
            b = 0;
            if (double == true)
                b = epsilongreedy(QB1 .+ QB2, ϵ, rng);
            else
                b = epsilongreedy(QB1, ϵ, rng);
            end
            r = μ + randn(rng);
            if (double == true && rand(rng) < 0.5)
                QB2[b] = QB2[b] + α*(r - QB2[b]);
            elseif (double == true)
                QB1[b] = QB1[b] + α*(r - QB1[b]);
            else
                QB1[b] = QB1[b] + α*(r - QB1[b]);
            end
        end
    end

    # return the fraction of the agents that chose "left" in each episode -
    return left_count ./ runs;
end

"""
    struct MyTwoStateTransitionModel

One experience on the two-state problem, stored in the replay buffer.

### Fields
- `s::Int64`: the state, 1 for A and 2 for B.
- `a::Int64`: the action taken.
- `r::Float64`: the reward received.
- `toB::Bool`: `true` if the action moved the agent from A to B; otherwise the episode ended.
"""
struct MyTwoStateTransitionModel
    s::Int64
    a::Int64
    r::Float64
    toB::Bool
end

"""
    twostate_dqn(; double::Bool = false, episodes::Int64 = 300, runs::Int64 = 1000,
        nB::Int64 = 10, μ::Float64 = -0.1, α::Float64 = 0.5, ϵ::Float64 = 0.1,
        batchsize::Int64 = 8, warmup::Int64 = 8, C::Int64 = 25, seed::Int64 = 1234) -> Array{Float64,1}

Train `runs` independent agents on the two-state problem with DQN, or with Double DQN if
`double = true`, and return the fraction of the agents that chose "left" in state A in each
episode. The discount factor is 1.

The Q-network is linear with one-hot features: one weight per state and action, the same numbers
as a table. Every step stores the transition in a replay buffer. Once the buffer holds `warmup`
transitions, every step takes one gradient step on a random mini-batch of `batchsize` transitions.
The target network is a copy of the Q-network, made every `C` steps.

- __DQN:__ the target of "left" in A is `0 + max over b of QB⁻[b]`, from the target network.
- __Double DQN:__ the Q-network picks the best action in B, and the target network scores it.

### Arguments
- `double::Bool = false`: `true` for Double DQN.
- `episodes::Int64 = 300`, `runs::Int64 = 1000`, `nB::Int64 = 10`, `μ::Float64 = -0.1`,
  `ϵ::Float64 = 0.1`: as in `twostate_qlearning(...)`.
- `α::Float64 = 0.5`: the learning rate of the gradient step.
- `batchsize::Int64 = 8`: the number of transitions in a mini-batch.
- `warmup::Int64 = 8`: the number of transitions stored before training starts.
- `C::Int64 = 25`: the number of steps between copies of the Q-network to the target network.
- `seed::Int64 = 1234`: agent `k` uses the seed `seed + k`.

### Returns
- `Array{Float64,1}`: entry `i` is the fraction of the agents that chose "left" in episode `i`.
"""
function twostate_dqn(; double::Bool = false, episodes::Int64 = 300, runs::Int64 = 1000,
    nB::Int64 = 10, μ::Float64 = -0.1, α::Float64 = 0.5, ϵ::Float64 = 0.1,
    batchsize::Int64 = 8, warmup::Int64 = 8, C::Int64 = 25, seed::Int64 = 1234)::Array{Float64,1}

    # initialize -
    left_count = zeros(episodes); # the number of agents that chose "left" in each episode

    # one independent agent per run -
    for k ∈ 1:runs
        rng = Xoshiro(seed + k);

        # the Q-network (one weight per state and action) and the target network -
        QA = zeros(2);
        QB = zeros(nB);
        QA⁻ = zeros(2);
        QB⁻ = zeros(nB);
        buffer = Array{MyTwoStateTransitionModel,1}(); # the replay buffer; 300 episodes never fill it
        steps = 0;

        for i ∈ 1:episodes
            s = 1; # every episode starts in A
            while (s != 0) # s = 0 marks the end of the episode

                # choose an action ϵ-greedily, take it, and store the transition -
                if (s == 1)
                    a = epsilongreedy(QA, ϵ, rng);
                    if (a == 1)
                        left_count[i] = left_count[i] + 1;
                        push!(buffer, MyTwoStateTransitionModel(1, 1, 0.0, true));
                        s = 2; # left: move to B
                    else
                        push!(buffer, MyTwoStateTransitionModel(1, 2, 0.0, false));
                        s = 0; # right: the episode ends
                    end
                else
                    b = epsilongreedy(QB, ϵ, rng);
                    r = μ + randn(rng);
                    push!(buffer, MyTwoStateTransitionModel(2, b, r, false));
                    s = 0; # any action in B ends the episode
                end
                steps = steps + 1;

                # training step: one gradient step on a random mini-batch -
                if (length(buffer) ≥ warmup)
                    gradient_A = zeros(2);
                    gradient_B = zeros(nB);
                    for j ∈ 1:batchsize
                        e = buffer[rand(rng, 1:length(buffer))]; # a random stored transition

                        # the target: the reward, plus the value of B if the move went to B -
                        y = e.r;
                        if (e.toB == true && double == true)
                            y = e.r + QB⁻[argmax(QB)]; # the Q-network picks, the target network scores
                        elseif (e.toB == true)
                            y = e.r + maximum(QB⁻); # the target network picks and scores
                        end

                        # the error on the action taken -
                        if (e.s == 1)
                            gradient_A[e.a] = gradient_A[e.a] + (y - QA[e.a]);
                        else
                            gradient_B[e.a] = gradient_B[e.a] + (y - QB[e.a]);
                        end
                    end
                    QA .= QA .+ (α/batchsize).*gradient_A;
                    QB .= QB .+ (α/batchsize).*gradient_B;
                end

                # every C steps, copy the Q-network to the target network -
                if (steps % C == 0)
                    QA⁻ .= QA;
                    QB⁻ .= QB;
                end
            end
        end
    end

    # return the fraction of the agents that chose "left" in each episode -
    return left_count ./ runs;
end

end # module L12dTwoState
