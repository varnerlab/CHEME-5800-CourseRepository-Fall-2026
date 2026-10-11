# =============================================================================
# CHEME 5800 | L10b student work: the weighted majority algorithm
# =============================================================================
# This is the file you edit in this lab. Complete my_weighted_majority(...)
# below by filling in the three lines marked TODO 1, TODO 2, and TODO 3;
# everything else is already written. Each TODO is part of one step of the
# weighted majority algorithm from the L10a lecture.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the result cell and the check cell.
# You are done when every test in the check cell passes.
# =============================================================================
module L10bWMA

import VLDataScienceMachineLearningPackage: MyBinaryWeightedMajorityAlgorithmModel

export my_weighted_majority

"""
    my_weighted_majority(model::MyBinaryWeightedMajorityAlgorithmModel,
        data::Array{Float64,2}) -> Tuple{Array{Int64,2}, Array{Float64,2}}

Play the binary weighted majority game from the L10a lecture for `model.T` rounds.

Every expert starts with weight 1. In each round `t`, we ask each expert for its prediction,
add up the weight of the experts predicting `1` (up) and the weight of the experts predicting
`-1` (down), and predict the side with the larger weight. A tie goes to `-1`, and an expert
that predicts `0` counts toward neither side. The adversary then reveals the actual outcome,
and every expert that predicted it incorrectly has its weight multiplied by `1 - ϵ`.

### Arguments
- `model::MyBinaryWeightedMajorityAlgorithmModel`: the game, built with the course package's
  `build(...)` method. The fields used are:
    - `n::Int64`: the number of experts. A tied vote predicts -1.
    - `T::Int64`: the number of rounds.
    - `ϵ::Float64`: the learning rate, `0 < ϵ ≤ 1/2`.
    - `expert::Function`: `expert(i, t, data)` returns the prediction of expert `i` in
      round `t`: `1` (up), `-1` (down), or `0` (no move).
    - `adversary::Function`: `adversary(t, data)` returns the actual outcome of round `t`.
- `data::Array{Float64,2}`: the data the experts and the adversary read. It is passed to
  them unchanged.

### Returns
A tuple `(sims, weights)`, with the same layout as the course package's `play(...)` method:
- `sims::Array{Int64,2}`: the record of the game, `T × (n+3)`. Row `t` holds the `n`
  experts' predictions, our prediction (column `n+1`), the actual outcome (column `n+2`),
  and our mistake (column `n+3`: `1` if our prediction was incorrect, otherwise `0`).
- `weights::Array{Float64,2}`: the expert weights, `(T+1) × n`. Row `t` holds the weights
  used in round `t`, so row 1 is all ones and row `T+1` holds the weights after the last
  round.

### Errors
Throws an `ErrorException` if our prediction in a round is not `1` or `-1`.

### Example
```julia
model = build(MyBinaryWeightedMajorityAlgorithmModel,
    (ϵ = 10/252, n = 5, T = 252, expert = expert, adversary = adversary));
(sims, weights) = L10bWMA.my_weighted_majority(model, growth_rate_array);
```
"""
function my_weighted_majority(model::MyBinaryWeightedMajorityAlgorithmModel,
    data::Array{Float64,2})::Tuple{Array{Int64,2}, Array{Float64,2}}

    # Initialize; this part is complete -
    n = model.n; # number of experts
    T = model.T; # number of rounds
    ϵ = model.ϵ; # learning rate
    expert = model.expert; # expert(i, t, data) returns expert i's prediction in round t
    adversary = model.adversary; # adversary(t, data) returns the actual outcome of round t
    sims = zeros(Int64, T, n+3); # the record of the game, one row per round
    weights = ones(Float64, T+1, n); # every expert starts with weight 1

    # Main loop: one round of the game for each value of t -
    for t ∈ 1:T

        # Ask each expert for its prediction. This part is complete -
        predictions = zeros(Int64, n); # one prediction per expert
        for i ∈ 1:n
            predictions[i] = expert(i, t, data); # 1 (up), -1 (down), or 0 (no move)
        end

        # Step 1: the weighted majority vote. First, add up the weight behind each
        # answer; this part is complete -
        weight_up = 0.0; # total weight of the experts predicting 1
        weight_down = 0.0; # total weight of the experts predicting -1
        for i ∈ 1:n
            if (predictions[i] == 1)
                weight_up += weights[t, i];
            elseif (predictions[i] == -1)
                weight_down += weights[t, i];
            end
        end

        # TODO 1: our prediction. Replace the right-hand side, 0, with 1 when the experts
        # predicting up carry more weight than the experts predicting down, and -1
        # otherwise (a tie goes to -1). The two totals are in weight_up and weight_down.
        # Hint: the ternary operator, condition ? a : b, is a when condition is true and b
        # when it is false.
        ŷ = 0;

        # Our prediction must be 1 or -1. This part is complete -
        if !(ŷ == 1 || ŷ == -1)
            throw(ErrorException("Oooops! The `my_weighted_majority(...)` function is not implemented yet - " *
                                 "we'd better fix that. Complete TODO 1 through TODO 3."))
        end

        # Step 2: the adversary reveals the actual outcome. This part is complete -
        y = adversary(t, data);

        # Step 3: lower the weight of every expert that predicted incorrectly -
        for i ∈ 1:n

            # TODO 2: expert i's mistake. Replace the right-hand side, 0, with 1 when expert
            # i's prediction, predictions[i], differs from the actual outcome, y, and 0 when
            # it matches. An expert that predicted 0 (no move) made a mistake.
            mistake = 0;

            # TODO 3: the weight update. Replace the right-hand side, weights[t, i], with
            # the weight multiplied by (1 - ϵ⋅mistake), so a mistake multiplies the weight by
            # 1 - ϵ and a correct prediction leaves it unchanged. The weight for round t is
            # weights[t, i], and its update goes in weights[t+1, i].
            weights[t+1, i] = weights[t, i];
        end

        # Record this round. This part is complete -
        for i ∈ 1:n
            sims[t, i] = predictions[i]; # the experts' predictions
        end
        sims[t, n+1] = ŷ; # our prediction
        sims[t, n+2] = y; # the actual outcome
        sims[t, n+3] = (ŷ == y) ? 0 : 1; # our mistake
    end

    # return -
    return (sims, weights);
end

end # module L10bWMA
