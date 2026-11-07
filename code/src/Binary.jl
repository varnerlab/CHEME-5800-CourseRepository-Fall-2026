# ------------------------------------------------------------------------------------------------ #
# Binary.jl
#
# Binary (two-class) classification used by the week-09 material. The L9a Perceptron example, the
# L9b XOR lab, and the L9d banknote lab train Perceptrons with learn(...), label examples with
# classify(...), and count the kinds of mistakes with confusion(...). The L9c example also uses
# confusion(...). No notebook in this course uses the logistic regression methods: the L9c and
# L9d notebooks write their own gradient descent.
#
# Labels are -1 and 1. Each row of a feature matrix is one example, and its last column is usually
# a 1, so the last parameter acts as the bias. The notebooks call the parameter vector θ; the model
# types in this file store it in the field β.
#
# Public functions:
#   learn(features, labels, algorithm; ...)   trains a Perceptron or a logistic regression model
#   classify(features, algorithm)             labels (Perceptron) or scores (logistic regression) each example
#   classify(test, algorithm; reverse)        the one-example form; it always fails (see its docstring)
#   confusion(actual, model)                  counts the true/false positives and negatives in a 2 × 2 matrix
#
# Private functions:
#   ∇f(f, x, y, T, λ, θ, h)                   estimates the gradient of a loss by forward finite differences
#   _count_mistakes(features, labels, β)      counts the examples on the wrong side of the boundary, or on it
#   _learn(...)                               the Perceptron (with the optional pocket rule) and the
#                                             logistic regression training loops
#   _classify(...)                            the Perceptron labels and the logistic regression probabilities
#
# No function in this file draws random numbers.
# ------------------------------------------------------------------------------------------------ #

# --- PRIVATE API BELOW HERE -------------------------------------------------------------------------------------- #
"""
    ∇f(f, x, y, T, λ, θ, h) -> Array{Float64}

Estimate the gradient of the loss `f(x, y, T, λ, θ)` with respect to the parameters `θ` by forward
finite differences. The logistic regression `_learn(...)` method calls this function once for each
training example.

For each parameter `θᵢ`, we nudge it by a small step `h` and measure how much the loss changes:

`∂f/∂θᵢ ≈ (f(x, y, T, λ, θ + h⋅eᵢ) − f(x, y, T, λ, θ)) / h`,

where `eᵢ` is the vector with a 1 in entry `i` and zeros elsewhere. The loop evaluates `f` twice for
each parameter: once at the nudged parameters and once at `θ`.

### Arguments
- `f`: the loss function, called as `f(x, y, T, λ, θ)`. The logistic regression model stores it in
  its field `L`.
- `x`: the feature vector of one training example.
- `y`: the label of the example, -1 or 1.
- `T`: passed on to `f` unchanged; the logistic regression model calls it the inverse temperature.
- `λ`: passed on to `f` unchanged; the logistic regression model calls it the regularization parameter.
- `θ`: the parameter vector at which we estimate the gradient. It is not changed.
- `h`: the finite-difference step size.

### Returns
- `Array{Float64}`: the estimated gradient, with the same shape as `θ`.
"""
function ∇f(f,x,y,T,λ,θ,h)

    # initialize: one entry of the gradient for each parameter -
    diff = zeros(size(θ)) # diff[i]: the estimated partial derivative with respect to θ[i] (a local variable; Julia also has a diff function)

    # main loop: nudge one parameter at a time -
    for i ∈ eachindex(θ) # eachindex(θ) gives every index of θ, in order
        θᵢ = copy(θ) # a fresh copy of the parameters, so θ is not changed; one copy per parameter is slow ("bad")
        θᵢ[i] += h # nudge parameter i by the step h (x += y means x = x + y)
        diff[i] = (f(x, y, T, λ, θᵢ) - f(x, y, T, λ, θ)) / h # the forward difference: the change in the loss divided by the step
    end

    # return the estimated gradient -
    return diff
end

# A one-line function: `f(x) = expression` defines the function f, which returns the value of the expression.
# `Array{<:Number,2}` means a matrix whose entries are any kind of number (Int64, Float64, ...).
# In the expression: features*β is the score x̂ᵀθ of every example; labels .* (...) multiplies each label by its
# score, entry by entry; .≤ 0 compares each product with 0, giving a vector of true/false values; count(...)
# counts the true values.
"""
    _count_mistakes(features::Array{<:Number,2}, labels::Array{<:Number,1}, β::AbstractVector{<:Number}) -> Int

Count the examples that the parameters `β` get wrong. Example `i` is a mistake when
`yᵢ⋅(x̂ᵢᵀβ) ≤ 0`: it is on the wrong side of the decision boundary, or on the boundary itself.
The pocket algorithm calls this function to score parameters; the L9a example calls this count `E(θ)`.

### Arguments
- `features::Array{<:Number,2}`: the feature matrix, one example `x̂ᵢ` per row.
- `labels::Array{<:Number,1}`: the label `yᵢ` of each example, -1 or 1.
- `β::AbstractVector{<:Number}`: the parameter vector, θ in the notebooks.

### Returns
- `Int`: the number of examples with `yᵢ⋅(x̂ᵢᵀβ) ≤ 0`.
"""
_count_mistakes(features::Array{<:Number,2}, labels::Array{<:Number,1}, β::AbstractVector{<:Number}) = count(labels .* (features*β) .≤ 0);

"""
    _learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::MyPerceptronClassificationModel;
        maxiter::Int64 = 100, verbose::Bool = false, pocket::Bool = false) -> MyPerceptronClassificationModel

Train a Perceptron classifier with the online Perceptron algorithm from the L9a lecture, and
optionally keep the best parameters with the pocket algorithm from the L9a example.

The algorithm passes through the training examples in row order, one example at a time. Example
`(x̂, y)` is a mistake when `y⋅(x̂ᵀθ) ≤ 0`, and then we update the parameters, `θ ← θ + y⋅x̂`, right
away. After each pass, we stop if the pass made at most `M` mistakes, where `M = algorithm.mistakes`
is the mistake threshold, or if we have made `maxiter` passes (`T` in the notebooks). Otherwise, we
start another pass. The mistakes of a pass are counted while the parameters change, so no single
parameter vector makes that count.

With `pocket = true`, after every update we count the training mistakes `E(θ)` of the new parameters
on all the examples. If they make fewer mistakes than the pocket copy `θₚ`, they become the new
pocket copy. At the end, we return the pocket copy instead of the parameters from the last update.

There are no random draws: every pass visits the examples in the same order.

### Arguments
- `features::Array{<:Number,2}`: the training feature matrix, one example `x̂` per row. Its last
  column is usually a 1, so the last parameter acts as the bias.
- `labels::Array{<:Number,1}`: the label `y` of each training example, -1 or 1.
- `algorithm::MyPerceptronClassificationModel`: the model. `algorithm.β` holds the starting
  parameters (θ in the notebooks), and `algorithm.mistakes` holds the mistake threshold `M`.
- `maxiter::Int64 = 100`: the largest number of passes through the training data.
- `verbose::Bool = false`: `true` to print the number of passes and the mistakes of the last pass,
  and, when `pocket = true`, the training mistakes of the pocket copy.
- `pocket::Bool = false`: `true` to return the parameters with the fewest training mistakes.

### Returns
- `MyPerceptronClassificationModel`: the same `algorithm` object that was passed in, with
  `algorithm.β` replaced by the learned parameters: the pocket copy when `pocket = true`, otherwise
  the parameters after the last update. The starting parameter vector itself is not changed.
"""
function _learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::MyPerceptronClassificationModel;
    maxiter::Int64 = 100, verbose::Bool = false, pocket::Bool = false)

    # get data from the algorithm -
    β = algorithm.β; # θ, the starting parameters
    m = algorithm.mistakes; # M, the mistake threshold: we stop after a pass with at most M mistakes
    is_ok_to_continue = true; # true while we should make another pass
    loop_counter = 1; # the number of the current pass
    error_counter = 0; # the number of mistakes in the current pass

    # main loop -
    β̂ = copy(β); # the parameters we update: a copy, so the starting parameters are not changed
    β_pocket = copy(β̂); # pocket: θₚ, the parameters with the fewest training mistakes so far
    pocket_mistakes = _count_mistakes(features, labels, β_pocket); # pocket: Eₚ, the training mistakes of θₚ
    while (is_ok_to_continue == true)

        # one pass through the training data, one example at a time -
        error_counter = 0; # reset the mistake count at the start of each pass
        for i ∈ eachindex(labels) # eachindex(labels) gives the row numbers 1, 2, …, n, in order

            x = features[i,:]; # x̂, the feature vector of example i: row i of the matrix, as a vector
            y = labels[i]; # the label of example i, -1 or 1

            # check: is example i a mistake, y⋅(x̂ᵀθ) ≤ 0? sum(β̂.*x) multiplies entry by entry and adds up, which is x̂ᵀθ -
            if (y*sum(β̂.*x)) ≤ 0
                β̂ = β̂ .+ y*x; # the Perceptron update θ ← θ + y⋅x̂ (.+ adds entry by entry)
                error_counter+=1 # one more mistake in this pass (x += y means x = x + y)

                # pocket: score the updated parameters on every training example, and keep them if they are the best so far -
                if (pocket == true)
                    mistakes_now = _count_mistakes(features, labels, β̂); # E(θ) of the updated parameters
                    if (mistakes_now < pocket_mistakes)
                        β_pocket = copy(β̂); # the new pocket copy θₚ
                        pocket_mistakes = mistakes_now; # and its mistake count Eₚ
                    end
                end
            end
        end # end training loop for

        # should we stay in the loop? we stop after the last allowed pass, or after a pass with at most M mistakes.
        # `||` means "or" -
        if (loop_counter >= maxiter || error_counter ≤ m)
            is_ok_to_continue = false; # we are done!
        else
            is_ok_to_continue = true; # we are not done yet!
            loop_counter+=1; # count the next pass
        end
    end

    # print the results if verbose is true -
    if (verbose == true)
        println("Stopped after number of iterations: ", loop_counter, ". We have number of errors: ", error_counter); # the number of passes, and the mistakes of the last pass
        if (pocket == true)
            println("Pocket coefficients make number of training errors: ", pocket_mistakes); # Eₚ, the training mistakes of the pocket copy
        end
    end

    # update the model: the pocket parameters if requested, otherwise the parameters from the last update.
    # `c ? a : b` means: if c is true, use a; otherwise, use b -
    algorithm.β = (pocket == true) ? β_pocket : β̂;

    # return the model, which now holds the learned parameters -
    return algorithm;
end


"""
    _learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::MyLogisticRegressionClassificationModel;
        maxiter::Int64 = 100, verbose::Bool = false) -> MyLogisticRegressionClassificationModel

Train a logistic regression classifier by gradient descent, with the gradient estimated by forward
finite differences. No notebook in this course calls this method.

The total loss is the sum of the loss `L(x̂ᵢ, yᵢ, T, λ, β)` over the training examples, where `L` is
the loss function stored in the model. In each iteration, we take three steps:
1. Estimate the gradient of the total loss, `∇L = Σᵢ ∇f(L, x̂ᵢ, yᵢ, T, λ, β, h)`, where `∇f(...)`
   uses forward finite differences with the step `h`.
2. Take a gradient descent step with the learning rate `α`: `β ← β − α⋅∇L`.
3. Stop if the length of the gradient, `‖∇L‖₂`, is at most `ϵ`. Otherwise, start another
   iteration, up to `maxiter` iterations.

The stopping test of step 3 uses the gradient of step 1, which was computed before the step 2 update.

### Arguments
- `features::Array{<:Number,2}`: the training feature matrix, one example `x̂` per row.
- `labels::Array{<:Number,1}`: the label `y` of each training example, -1 or 1.
- `algorithm::MyLogisticRegressionClassificationModel`: the model. We use its fields `β`, the
  starting parameters (θ in the notebooks); `α`, the learning rate; `ϵ`, the stopping tolerance on
  `‖∇L‖₂`; `L`, the loss function `L(x, y, T, λ, β)`; `T`, which the model calls the inverse
  temperature; `λ`, the regularization parameter; and `h`, the finite-difference step size. This
  method passes `T` and `λ` on to `L` and does not use them itself.
- `maxiter::Int64 = 100`: the largest number of gradient descent iterations.
- `verbose::Bool = false`: `true` to print the iteration count and the last gradient length. When
  the loop stops at `maxiter` iterations, the printed count is `maxiter + 1`.

### Returns
- `MyLogisticRegressionClassificationModel`: the same `algorithm` object that was passed in, with
  `algorithm.β` replaced by the learned parameters.
"""
function _learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::MyLogisticRegressionClassificationModel;
    maxiter::Int64 = 100, verbose::Bool = false)

    # get data from the algorithm -
    β = algorithm.β; # parameters, θ in the notebooks
    α = algorithm.α; # learning rate
    ϵ = algorithm.ϵ; # stopping tolerance on the length of the gradient
    L = algorithm.L; # loss function L(x, y, T, λ, β) of one example
    T = algorithm.T; # inverse temperature parameter, passed on to L
    λ = algorithm.λ; # regularization parameter, passed on to L
    h = algorithm.h; # finite difference step size
    is_ok_to_continue = true; # true while we should take another step
    loop_counter = 1; # the number of the current iteration

    # main loop -
    βᵢ = copy(β); # the parameters we update, starting from the initial guess: a copy, so the model's starting vector is not changed
    error = nothing; # the length of the gradient, set in the loop (nothing means "no value yet"; Julia also has an error function)
    while (is_ok_to_continue == true && loop_counter ≤ maxiter)

        # initialize the gradient -
        ∇L = zeros(size(βᵢ)); # ∇L: the gradient of the total loss, one entry per parameter

        # step 1: compute the gradient of the total loss, adding the gradient of each example's loss -
        for i ∈ eachindex(labels) # for each training pair

            x = features[i,:]; # x̂, the feature vector of example i: row i of the matrix, as a vector
            y = labels[i]; # the label of example i, -1 or 1

            # add the finite-difference gradient of this example's loss (.+ adds entry by entry) -
            ∇L = ∇L .+ ∇f(L, x, y, T, λ, βᵢ, h);
        end # end training loop for

        # step 2: take a gradient descent step, β ← β − α⋅∇L (.- subtracts entry by entry) -
        βᵢ = βᵢ .- α*∇L;

        # step 3: should we stay in the loop? we stop when the length of the gradient is at most ϵ -
        error = norm(∇L); # ‖∇L‖₂, the Euclidean length of the gradient
        if (error ≤ ϵ)
            is_ok_to_continue = false; # we are done!
        else
            is_ok_to_continue = true; # we are not done yet!
            loop_counter+=1; # count the next iteration (x += y means x = x + y)
        end
    end

    # print the results if verbose is true -
    if (verbose == true)
        println("Stopped after number of iterations: ", loop_counter, ". We have error: ", error); # error is the last gradient length
    end

    # update the algorithm -
    algorithm.β = βᵢ; # store the learned parameters in the model

    # return the model, which now holds the learned parameters -
    return algorithm;
end

"""
    _classify(features::Array{<:Number,2}, algorithm::MyPerceptronClassificationModel) -> Array{<:Number,1}

Label each example with the Perceptron rule `ŷ = sign(x̂ᵀθ)`, using the parameters `θ = algorithm.β`.

Julia's `sign` returns 1 for a positive score, -1 for a negative score, and 0 for a score of exactly
0. The lecture's sign function returns 1 at 0, so the notebooks replace each 0 with 1 after the call.

### Arguments
- `features::Array{<:Number,2}`: the feature matrix, one example `x̂` per row, with the same columns
  as the training data.
- `algorithm::MyPerceptronClassificationModel`: the trained model. We use its parameters `algorithm.β`.

### Returns
- `Array{<:Number,1}`: the label of each example, 1, -1, or 0. With `Float64` data or parameters,
  the labels are `Float64` numbers such as `1.0`.
"""
function _classify(features::Array{<:Number,2}, algorithm::MyPerceptronClassificationModel)

    # features*algorithm.β is the score x̂ᵀθ of every example. The dot in sign.(...) applies sign to each score -
    return sign.(features*algorithm.β);
end

"""
    _classify(features::Array{<:Number,2}, algorithm::MyLogisticRegressionClassificationModel) -> Array{Float64,2}

Compute the probability of each label for each example with the logistic model

`P(y = 1 | x̂) = 1 / (1 + exp(−2⋅x̂ᵀθ))` and `P(y = −1 | x̂) = 1 / (1 + exp(2⋅x̂ᵀθ))`,

where `θ = algorithm.β`. This is the L9c lecture's model with the inverse temperature fixed at 1.
The model's field `T` is not used here. The two probabilities of each example add up to 1.

### Arguments
- `features::Array{<:Number,2}`: the feature matrix, one example `x̂` per row, with the same columns
  as the training data.
- `algorithm::MyLogisticRegressionClassificationModel`: the trained model. We use its parameters
  `algorithm.β`.

### Returns
- `Array{Float64,2}`: an `n × 2` matrix with one row per example. Column 1 holds `P(y = 1 | x̂)`,
  and column 2 holds `P(y = −1 | x̂)`.
"""
function _classify(features::Array{<:Number,2}, algorithm::MyLogisticRegressionClassificationModel)

    # initialize -
    number_of_examples = size(features,1); # number of rows, one per example
    labels = zeros(number_of_examples,2); # labels[i, :]: the two probabilities of example i
    β = algorithm.β; # θ, the learned parameters

    # compute the two probabilities of each example -
    for i ∈ 1:number_of_examples
        x = features[i,:]; # x̂, the feature vector of example i
        labels[i,1] = (1)/(1+exp(-2*dot(x,β))); # probability y = 1: 1/(1 + exp(−2⋅x̂ᵀθ))
        labels[i,2] = (1)/(1+exp(2*dot(x,β))); # probability y = -1: 1/(1 + exp(2⋅x̂ᵀθ))
    end

    # return the n × 2 matrix of probabilities -
    return labels;
end

# --- PRIVATE API ABOVE HERE -------------------------------------------------------------------------------------- #

# --- PUBLIC API BELOW HERE --------------------------------------------------------------------------------------- #


"""
    learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::AbstractClassificationAlgorithm;
        maxiter::Int64 = 100, verbose::Bool = false, kwargs...) -> AbstractClassificationAlgorithm

Train a binary classifier on labeled examples. This function passes its arguments to the private
`_learn(...)` method for the type of `algorithm`:
- A `MyPerceptronClassificationModel` is trained with the online Perceptron algorithm, with an
  optional pocket rule.
- A `MyLogisticRegressionClassificationModel` is trained by gradient descent on its loss function.

The Perceptron passes through the training examples in row order. Each example with
`y⋅(x̂ᵀθ) ≤ 0` is a mistake and updates the parameters, `θ ← θ + y⋅x̂`. The training stops after a
pass with at most `M` mistakes, where `M` is the model's mistake threshold, or after `maxiter`
passes. There are no random draws.

### Arguments
- `features::Array{<:Number,2}`: the training feature matrix, one example `x̂` per row. Add a column
  of ones, so the last parameter acts as the bias.
- `labels::Array{<:Number,1}`: the label `y` of each training example, -1 or 1.
- `algorithm::AbstractClassificationAlgorithm`: the model, built with `build(...)`. Its field `β`
  holds the starting parameters (θ in the notebooks).
- `maxiter::Int64 = 100`: the largest number of passes (Perceptron) or iterations (logistic regression).
- `verbose::Bool = false`: `true` to print where the training stopped.
- `kwargs...`: any other keyword arguments, passed on to `_learn(...)` unchanged. The Perceptron
  accepts `pocket::Bool = false`. When `pocket = true`, the pocket algorithm counts the training
  mistakes of the parameters after each update, and returns the parameters with the fewest training
  mistakes instead of the parameters from the last update. The logistic regression method accepts no
  other keyword.

### Returns
- The same `algorithm` object that was passed in, with its field `β` replaced by the learned parameters.

### Example
```julia
X = [0.0 0.0 1.0; 0.0 1.0 1.0; 1.0 0.0 1.0; 1.0 1.0 1.0]; # four examples: two features and a 1 for the bias
y = [-1.0, -1.0, -1.0, 1.0]; # the labels of the AND pattern, which a line can separate
model = build(MyPerceptronClassificationModel, (parameters = zeros(3), mistakes = 0));
model = learn(X, y, model, maxiter = 100);
classify(X, model) # returns [-1.0, -1.0, -1.0, 1.0]
```
"""
function learn(features::Array{<:Number,2}, labels::Array{<:Number,1}, algorithm::AbstractClassificationAlgorithm;
    maxiter::Int64 = 100, verbose::Bool = false, kwargs...)

    # call the _learn(...) method for the type of algorithm, and return the updated model.
    # In a call, the `;` separates the positional arguments from the keyword arguments, and
    # `kwargs...` passes on every other keyword argument (such as pocket = true) unchanged -
    return _learn(features, labels, algorithm; maxiter = maxiter, verbose = verbose, kwargs...);
end


"""
    classify(features::Array{<:Number,2}, algorithm::AbstractClassificationAlgorithm) -> Array

Classify every example in a feature matrix with a trained model. This function passes its arguments
to the private `_classify(...)` method for the type of `algorithm`:
- For a `MyPerceptronClassificationModel`, it returns the vector of labels `sign(x̂ᵀθ)`, one per
  example. Julia's `sign` gives 0 for a score of exactly 0, so the notebooks replace each 0 with 1.
- For a `MyLogisticRegressionClassificationModel`, it returns an `n × 2` matrix of probabilities.
  Column 1 holds `P(y = 1 | x̂)`, and column 2 holds `P(y = −1 | x̂)`.

### Arguments
- `features::Array{<:Number,2}`: the feature matrix, one example `x̂` per row, with the same columns
  as the training data.
- `algorithm::AbstractClassificationAlgorithm`: the trained model.

### Returns
- A vector of labels (Perceptron), or an `n × 2` matrix of probabilities (logistic regression).
"""
function classify(features::Array{<:Number,2}, algorithm::AbstractClassificationAlgorithm)

    # call the _classify(...) method for the type of algorithm, and return its result -
    return _classify(features, algorithm);
end


"""
    classify(test::Array{<:Number,1}, algorithm::AbstractClassificationAlgorithm; reverse::Bool = false)

Classify one example given as a vector. This method passes `test`, `algorithm`, and the keyword
`reverse` to `_classify(...)`, but no `_classify(...)` method in this package accepts a vector and
the `reverse` keyword, so every call stops with a `MethodError`. To classify one example, pass it
as a one-row matrix to the matrix method, for example `classify(reshape(x, 1, length(x)), model)`.

The earlier documentation described `reverse` as the sort order of the distances in a
nearest-neighbor (KNN) classifier. This package does not include that classifier.

### Arguments
- `test::Array{<:Number,1}`: the feature vector of one example.
- `algorithm::AbstractClassificationAlgorithm`: the trained model.
- `reverse::Bool = false`: passed on to `_classify(...)`.

### Throws
- `MethodError` on every call, because no matching `_classify(...)` method exists.
"""
function classify(test::Array{<:Number,1}, algorithm::AbstractClassificationAlgorithm; reverse::Bool = false)

    # call _classify(...) with a vector and the reverse keyword (no such method exists, so this fails) -
    return _classify(test, algorithm, reverse = reverse);
end


"""
    confusion(actual::Array{<:Number,1}, model::Array{<:Number,1}) -> Array{Int64,2}

Compute the confusion matrix of a binary classifier, with the label 1 as the positive class and the
label -1 as the negative class.

The matrix counts the examples in each combination of actual and predicted label:

|            | predicted 1          | predicted -1         |
|------------|----------------------|----------------------|
| actual 1   | true positives (TP)  | false negatives (FN) |
| actual -1  | false positives (FP) | true negatives (TN)  |

An example whose actual or predicted label is neither 1 nor -1, such as a Perceptron label of 0, is
not counted anywhere.

### Arguments
- `actual::Array{<:Number,1}`: the actual label of each example. Pass it first.
- `model::Array{<:Number,1}`: the predicted label of each example, in the same order. Pass it second.

### Returns
- `Array{Int64,2}`: the `2 × 2` matrix `[TP FN; FP TN]`.

### Example
```julia
confusion([1, 1, 1, -1, -1], [1, 1, -1, 1, -1]) # returns [2 1; 1 1]
```
"""
function confusion(actual::Array{<:Number,1}, model::Array{<:Number,1})::Array{Int64,2}

    # initialize -
    number_of_test_examples = size(actual,1); # the number of examples
    confusion_matrix = zeros(Int64,2,2); # [TP FN; FP TN], filled in below
    y = actual; # the actual labels
    ŷ = model; # the predicted labels

    # count the true positives TP: actual 1, predicted 1 (&& means "and") -
    counter = 0;
    for i ∈ 1:number_of_test_examples
        if (y[i] == 1 && ŷ[i] == 1)
            counter+=1; # x += y means x = x + y
        end
    end
    confusion_matrix[1,1] = counter;

    # count the false negatives FN: actual 1, predicted -1 -
    counter = 0;
    for i ∈ 1:number_of_test_examples
        if (y[i] == 1 && ŷ[i] == -1)
            counter+=1;
        end
    end
    confusion_matrix[1,2] = counter;

    # count the false positives FP: actual -1, predicted 1 -
    counter = 0;
    for i ∈ 1:number_of_test_examples
        if (y[i] == -1 && ŷ[i] == 1)
            counter+=1;
        end
    end
    confusion_matrix[2,1] = counter;

    # count the true negatives TN: actual -1, predicted -1 -
    counter = 0;
    for i ∈ 1:number_of_test_examples
        if (y[i] == -1 && ŷ[i] == -1)
            counter+=1;
        end
    end
    confusion_matrix[2,2] = counter;

    # return the matrix: a function returns the value of its last line, here the confusion matrix -
    confusion_matrix
end
# --- PUBLIC API ABOVE HERE -------------------------------------------------------------------------------------- #
