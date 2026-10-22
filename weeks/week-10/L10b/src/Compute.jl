# =============================================================================
# CHEME 5800 | L10b student work: the weighted majority algorithm
# =============================================================================
# This is the file you edit in this lab. Complete my_weighted_majority(...)
# below by filling in the three places marked TODO 1, TODO 2, and TODO 3;
# everything else is already written. Each TODO is part of one step of the
# weighted majority algorithm from the lecture. Each TODO comment says what to
# write and gives a hint, and the docstring lists the three steps.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the result cell and the check cell.
# You are done when every test in the check cell passes.
# =============================================================================
module L10bWMA

# The name this file uses from the course package, listed so you can see where it comes from -
import VLDataScienceMachineLearningPackage: MyBinaryWeightedMajorityAlgorithmModel # the type of the game that build(...) returns

export my_weighted_majority # the one function this module provides

"""
    my_weighted_majority(model::MyBinaryWeightedMajorityAlgorithmModel,
        data::Array{Float64,2}) -> Tuple{Array{Int64,2}, Array{Float64,2}}

Play the binary weighted majority game from the lecture for `model.T` rounds.

Every expert starts with weight 1. In each round `t = 1, 2, ..., T`, the function asks each
expert `i` for its prediction, `1` (up), `-1` (down), or `0` (no move), and then carries out the
three steps of the lecture's algorithm:

1. **Vote (TODO 1).** Add up the weight of the experts predicting `1` and the weight of the
   experts predicting `-1`. Predict `ŷ = 1` if the experts predicting up carry more weight, and
   `ŷ = -1` otherwise, so a tie gives `-1`. An expert that predicts `0` counts toward neither side.
2. **Outcome.** Ask the adversary for the actual outcome `y` of round `t`, `1` or `-1`.
3. **Update (TODO 2 and TODO 3).** For each expert `i`, set `mistake = 1` if its prediction
   differs from `y` and `mistake = 0` if it matches; an expert that predicted `0` made a
   mistake. Then multiply the weight of expert `i` by `1 - ϵ⋅mistake` to get its weight for
   the next round. Here `weights[t, i]` is the weight of expert `i` in round `t`, and `ϵ` is
   the learning rate. A mistake multiplies the weight by `1 - ϵ`, and a correct prediction
   leaves it unchanged.

### Arguments
- `model::MyBinaryWeightedMajorityAlgorithmModel`: the game, built with the course package's
  `build(...)` method. The fields used are:
    - `n::Int64`: the number of experts.
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
Throws an `ErrorException` with an "Oooops!" message if our prediction in a round is not `1`
or `-1`. This is what happens while TODO 1 is not done.

### Example
After the notebook's setup and Task 1 cells have defined `expert(...)`, `adversary(...)`, and
`growth_rate_array`:
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

        # Step 1: the weighted majority vote. First, add up the weight of the experts on
        # each side; this part is complete -
        weight_up = 0.0; # total weight of the experts predicting 1
        weight_down = 0.0; # total weight of the experts predicting -1
        for i ∈ 1:n
            if (predictions[i] == 1)
                weight_up += weights[t, i]; # a += b is short for a = a + b
            elseif (predictions[i] == -1)
                weight_down += weights[t, i];
            end
        end

        # TODO 1: our prediction (step 1).
        # Replace the line ŷ = 0; below with an if-else block that sets ŷ to 1 when the
        # experts predicting up carry more weight than the experts predicting down, and to -1
        # otherwise. The two totals are already in weight_up and weight_down.
        # Hint: an if-else block has the form
        #     if (condition)
        #         ... # these lines run when condition is true
        #     else
        #         ... # these lines run when condition is false
        #     end
        # Compare the two totals with >. Then check which branch a tie (equal totals) lands
        # in: a tie must give ŷ = -1.
        ŷ = 0;

        # Our prediction must be 1 or -1, so we stop with an error if TODO 1 is not done.
        # This part is complete -
        if (ŷ != 1 && ŷ != -1)
            throw(ErrorException("Oooops! The `my_weighted_majority(...)` function is not implemented yet - we'd better fix that. Complete TODO 1 through TODO 3."));
        end

        # Step 2: the adversary reveals the actual outcome. This part is complete -
        y = adversary(t, data);

        # Step 3: lower the weight of every expert that predicted incorrectly -
        for i ∈ 1:n

            # TODO 2: expert i's mistake (step 3).
            # Replace the line mistake = 0; below with an if-else block that sets mistake to 0
            # when expert i's prediction, predictions[i], matches the actual outcome, y, and to
            # 1 when it differs.
            # Hint: use the same if-else form as in TODO 1. In Julia, a == b is true when a and
            # b are equal. A prediction of 0 (no move) never equals y, which is 1 or -1, so your
            # block counts it as a mistake without any extra code.
            mistake = 0;

            # TODO 3: the weight update (step 3).
            # Replace the right-hand side, weights[t, i], with the weight for round t multiplied
            # by (1 - ϵ*mistake). The result goes in weights[t+1, i], the weight for round t+1.
            # Hint: in Julia, * multiplies two numbers. Check both cases: when mistake is 1, the
            # factor is 1 - ϵ, so the weight shrinks; when mistake is 0, the factor is 1, so the
            # weight stays the same.
            weights[t+1, i] = weights[t, i];
        end

        # Record this round. This part is complete -
        for i ∈ 1:n
            sims[t, i] = predictions[i]; # the experts' predictions
        end
        sims[t, n+1] = ŷ; # our prediction
        sims[t, n+2] = y; # the actual outcome
        if (ŷ == y)
            sims[t, n+3] = 0; # we predicted correctly
        else
            sims[t, n+3] = 1; # our mistake
        end
    end

    # return -
    return (sims, weights);
end

end # module L10bWMA
