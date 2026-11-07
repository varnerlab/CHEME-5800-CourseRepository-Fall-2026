# ------------------------------------------------------------------------------------------------ #
# Online.jl
#
# Online learning from expert advice, from the week-10 L10a lecture. The L10b lab checks the
# students' weighted majority function against play(model, data) for a
# MyBinaryWeightedMajorityAlgorithmModel. The method for a MyTwoPersonZeroSumGameModel plays a
# two-person zero-sum game with multiplicative weights; no notebook in this course calls it.
#
# Public functions:
#   play(model::MyBinaryWeightedMajorityAlgorithmModel, data)
#                                  plays T rounds of the weighted majority algorithm
#   play(model::MyTwoPersonZeroSumGameModel)
#                                  plays T rounds of a zero-sum game with multiplicative weights
#
# Both methods write the weights of every round into model.weights, and return that same array.
#
# Random numbers: the weighted majority method draws none. The zero-sum game method draws the row
# player's action in each round from Julia's default random number generator, and build(...) for
# that model draws the starting weights from the same generator.
# ------------------------------------------------------------------------------------------------ #

"""
    play(model::MyBinaryWeightedMajorityAlgorithmModel, data::Array{Float64,2}) -> Tuple{Array{Int64,2}, Array{Float64,2}}

Play `T` rounds of the binary weighted majority algorithm from the L10a lecture, and return the
record of the game and the weight of every expert in every round.

In each round `t = 1, 2, …, T`:
1. Ask each expert `i = 1, 2, …, n` for its prediction, `expert(i, t, data)`: 1 (up), -1 (down),
   or 0 (no prediction).
2. Predict by weighted vote. Add up the weights `wᵢ⁽ᵗ⁾` of the experts predicting 1, and,
   separately, of the experts predicting -1. Predict `ŷₜ = 1` if the first total is larger.
   Otherwise, including a tie, predict `ŷₜ = -1`. An expert predicting 0 counts toward neither side.
3. Ask the adversary for the actual outcome, `yₜ = adversary(t, data)`.
4. Update the weights. Expert `i` makes a mistake when its prediction differs from `yₜ`, so a
   prediction of 0 is a mistake when the outcome is 1 or -1. The new weight is
   `wᵢ⁽ᵗ⁺¹⁾ = wᵢ⁽ᵗ⁾⋅(1 − ϵ⋅mᵢ)`, where `mᵢ` is 1 for a mistake and 0 otherwise.

This method draws no random numbers itself. The game repeats exactly when the model's `expert` and
`adversary` functions are deterministic.

### Arguments
- `model::MyBinaryWeightedMajorityAlgorithmModel`: the game, built with `build(...)`. We use its
  fields `n`, the number of experts; `T`, the number of rounds; `ϵ`, the learning rate; `weights`,
  the `(T+1) × n` weight array, whose row 1 holds the starting weights (all ones from `build(...)`);
  `expert`, the function `expert(i, t, data)` that returns the integer prediction of expert `i` in
  round `t`; and `adversary`, the function `adversary(t, data)` that returns the actual outcome.
- `data::Array{Float64,2}`: the data passed on to `expert` and `adversary`, for example the daily
  growth rates in the L10b lab.

### Returns
A tuple `(results_array, weights)`:
- `results_array::Array{Int64,2}`: the `T × (n+3)` record of the game, one row per round (the L10b
  lab calls it `sims`). Columns 1 to `n` hold the predictions of experts 1 to `n`. Column `n+1`
  holds our prediction `ŷₜ`, column `n+2` holds the actual outcome `yₜ`, and column `n+3` holds our
  mistake: 1 if `ŷₜ ≠ yₜ`, otherwise 0.
- `weights::Array{Float64,2}`: the `(T+1) × n` weights, one column per expert. Row `t` holds the
  weights used in round `t`, so row `T+1` holds the weights after the last round. This is the
  model's own `model.weights` array, not a copy: `play(...)` overwrites rows 2 to `T+1` of it.

### Example
```julia
model = build(MyBinaryWeightedMajorityAlgorithmModel, (ϵ = 0.5, n = 2, T = 1,
    expert = (i, t, data) -> [1, -1][i], adversary = (t, data) -> 1));
(results_array, weights) = play(model, zeros(1, 1)); # results_array is [1 -1 -1 1 1], weights is [1.0 1.0; 1.0 0.5]
```
"""
function play(model::MyBinaryWeightedMajorityAlgorithmModel,
    data::Array{Float64,2})::Tuple{Array{Int64,2}, Array{Float64,2}}

    # initialize -
    n = model.n; # how many experts do we have?
    T = model.T; # how many rounds do we play?
    ϵ = model.ϵ; # learning rate
    weights = model.weights; # weights[t, i]: the weight of expert i in round t. This is the model's own array, not a copy, so the updates below change model.weights
    expert = model.expert; # expert function expert(i, t, data)
    adversary = model.adversary; # adversary function adversary(t, data)
    results_array = zeros(Int64, T, 3+n); # the record of the game: n expert predictions, our prediction, the outcome, our mistake

    # main simulation loop: one round t per pass -
    for t ∈ 1:T

        # step 1: query the experts -
        expert_predictions = zeros(Int64, n); # expert_predictions[i]: the prediction of expert i in round t
        for i ∈ 1:n
            expert_predictions[i] = expert(i, t, data); # call the expert function: the prediction of expert i in round t, 1, -1, or 0
        end

        # store the expert predictions in columns 1 to n -
        for i ∈ 1:n
            results_array[t, i] = expert_predictions[i];
        end

        # step 2: predict by weighted vote. findall(x -> x == -1, v) returns the indices of the experts that
        # predict -1; `x -> ...` is an anonymous function, a function with no name. The |> (pipe) passes those
        # indices to a second anonymous function, i -> sum(weights[t, i]), which adds up their weights in round t.
        # The sum is 0.0 when no expert is on that side -
        weight_down_vote = findall(x-> x == -1, expert_predictions) |> i-> sum(weights[t, i]); # total weight of the experts predicting -1
        weight_up_vote = findall(x-> x == 1, expert_predictions) |> i-> sum(weights[t, i]); # total weight of the experts predicting 1
        aggregator_prediction = (weight_up_vote > weight_down_vote) ? 1 : -1; # ŷₜ. `c ? a : b` means: if c is true, use a; otherwise, use b. A tie gives -1
        results_array[t,n+1] = aggregator_prediction; # store the aggregator prediction in column n+1

        # step 3: query the adversary -
        actual = adversary(t, data); # call the adversary function, returns the actual outcome yₜ at time t
        results_array[t, n+2] = actual; # store the adversary outcome in column n+2

        # compute the aggregator loss: 0 if we were right, 1 if we made a mistake. `end` is the last column, n+3 -
        results_array[t, end] = (aggregator_prediction == actual) ? 0 : 1;

        # step 4: compute the loss of each expert: 0 if it was right, 1 if it made a mistake -
        loss = zeros(Float64, n);
        for i ∈ 1:n
            loss[i] = (expert_predictions[i] == actual) ? 0.0 : 1.0; # the mistake indicator mᵢ of expert i
        end

        # update the weights: wᵢ⁽ᵗ⁺¹⁾ = wᵢ⁽ᵗ⁾⋅(1 − ϵ⋅mᵢ). A mistake multiplies the weight by 1 − ϵ; a correct prediction keeps it -
        for i ∈ 1:n
            weights[t+1, i] = weights[t, i]*(1 - ϵ*loss[i]);
        end
    end

    # return the record of the game and the weights -
    return (results_array, weights);
end

"""
    play(model::MyTwoPersonZeroSumGameModel) -> Tuple{Array{Int64,2}, Array{Float64,2}}

Play `T` rounds of a two-person zero-sum game in which the row player learns with multiplicative
weights and the column player answers each round with its best response. No notebook in this
course calls this method.

The payoff matrix `M` holds the row player's payoff: `M[i, j]` is what the row player wins when it
plays row `i` and the column player plays column `j`, and the column player loses the same amount.
In each round `t = 1, 2, …, T`:
1. Turn the weights into a probability vector, `p = w⁽ᵗ⁾ / Σᵢ wᵢ⁽ᵗ⁾`, and draw the row player's
   action from it with `rand(Categorical(p))`.
2. Compute the row player's expected payoff for each column, `q = pᵀM`. The column player chooses
   the column `j⋆` with the smallest expected payoff; a tie goes to the smallest index.
3. Compute the loss of each row against that column, `l = −M[:, j⋆]`, and update the weights,
   `wᵢ⁽ᵗ⁺¹⁾ = wᵢ⁽ᵗ⁾⋅exp(−ϵ⋅lᵢ)`. Rows that pay well against `j⋆` gain weight relative to the others.

The column player's choice and the weight update use the probability vector `p`, not the sampled
action, so the sampled actions do not change the weights. This is the exponential form of the
multiplicative weights update; the L10a lecture uses the form `wᵢ⋅(1 − η⋅mᵢ)`.

Random draws: one `rand(Categorical(p))` per round, from Julia's default random number generator.
The starting weights in row 1 of `model.weights` are random too: `build(...)` draws them with
`rand(n)` from the same generator.

### Arguments
- `model::MyTwoPersonZeroSumGameModel`: the game, built with `build(...)`. We use its fields `n`,
  the number of row actions (experts); `T`, the number of rounds; `ϵ`, the learning rate;
  `weights`, the `(T+1) × n` weight array, whose row 1 holds the starting weights; and
  `payoffmatrix`, the payoff matrix `M`. The code builds the column player's choice as a vector of
  length `n`, so `M` must be square, `n × n`.

### Returns
A tuple `(results_array, weights)`:
- `results_array::Array{Int64,2}`: the `T × 2` record of the game, one row per round. Column 1
  holds the row player's sampled action, and column 2 holds the column player's action `j⋆`.
- `weights::Array{Float64,2}`: the `(T+1) × n` weights, one column per row action. Row `t` holds
  the weights used in round `t`. This is the model's own `model.weights` array, not a copy:
  `play(...)` overwrites rows 2 to `T+1` of it.
"""
function play(model::MyTwoPersonZeroSumGameModel)

    # initialize -
    n = model.n; # how many row actions (experts) do we have?
    T = model.T; # how many rounds do we play?
    ϵ = model.ϵ; # learning rate
    weights = model.weights; # weights[t, i]: the weight of row action i in round t. The model's own array, not a copy
    M = model.payoffmatrix; # payoff matrix: M[i, j] is the row player's payoff for row i against column j
    L = -M; # loss matrix: the row player's loss is the negative of its payoff
    results_array = zeros(Int64, T, 2); # column 1: the row player's action; column 2: the column player's action

    # main simulation loop: one round t per pass -
    for t ∈ 1:T

        # step 1: compute the probability vector p, and draw the row player's action from it -
        Φ = sum(weights[t, :]); # Φ is sum of the weights at time t
        p = weights[t, :]/Φ; # probability vector p: p[i] = wᵢ/Φ, so the entries add up to 1
        d = Categorical(p); # define the distribution that picks action i with probability p[i] (from the Distributions package)
        #results_array[t, 1] = argmax(p); # (commented out: an older rule that chose the most probable action)
        results_array[t, 1] = rand(d); # store the aggregator prediction: a random action drawn from p with the default random number generator

        # step 2: compute expected payoffs for column actions. transpose(p) * M is a 1 × n row;
        # `|> vec` passes it to vec(...), which turns it into a plain vector -
        q = transpose(p) * M |> vec;  # expected payoff for row player if column plays e_j
        qstar = argmin(q); # column player chooses action j⋆ to minimize row player's payoff; argmin returns the first index on a tie
        #qstar = argmax(q); # (commented out: a column player that maximizes the row player's payoff)
        results_array[t, 2] = qstar; # store the adversary action

        q̄ = zeros(Float64, n); # the column player's choice as a vector of length n: 1 in entry j⋆, 0 elsewhere
        q̄[qstar] = 1.0; # action for the adversary

        # step 3: compute the loss of each row action against column j⋆. L*q̄ picks column j⋆ of L, which is −M[:, j⋆] -
        l = L*q̄;

        # update the weights: wᵢ⁽ᵗ⁺¹⁾ = wᵢ⁽ᵗ⁾⋅exp(−ϵ⋅lᵢ) -
        for i ∈ 1:n
            weights[t+1, i] = weights[t, i]*exp(-ϵ*l[i]);
        end
    end

    # return the record of the game and the weights -
    return (results_array, weights);
end
