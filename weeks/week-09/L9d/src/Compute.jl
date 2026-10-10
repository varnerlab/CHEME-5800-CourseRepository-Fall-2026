# =============================================================================
# CHEME 5800 | L9d student work: logistic regression with gradient descent
# =============================================================================
# This is the file you edit in this lab. Complete my_logistic_regression(...)
# below by filling in the three lines marked TODO 1, TODO 2, and TODO 3;
# everything else is already written. Each TODO is one step of the L9c gradient
# descent algorithm.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the result cell and the check cell.
# You are done when every test in the check cell passes.
#
# The figure is in Visualize.jl.
# =============================================================================
module L9dLogistic

import LinearAlgebra: dot, norm # dot(a, b) is the inner product aᵀb; norm(a) is the length of a

export my_logistic_regression

"""
    σ(z::Real) -> Float64

The logistic function, `σ(z) = 1/(1 + exp(-z))`, from the L9c lecture. It maps any real
number to the interval `(0, 1)`; in floating point, a large enough `|z|` rounds the result to
exactly `0` or `1`.
"""
σ(z::Real) = 1/(1 + exp(-z))

"""
    regularized_loss(X::Array{<:Number,2}, y::Array{<:Number,1}, θ::Array{Float64,1};
        β::Float64 = 1.0, δ::Float64 = 0.0) -> Float64

The regularized cross-entropy loss from the L9c lecture,
`J_δ(θ) = Σᵢ log(1 + exp(-2β yᵢ x̂ᵢᵀθ)) + (δ/2)‖θ‖²`, summed over the rows of `X`.
"""
function regularized_loss(X::Array{<:Number,2}, y::Array{<:Number,1}, θ::Array{Float64,1};
    β::Float64 = 1.0, δ::Float64 = 0.0)::Float64
    u = 2*β .* y .* (X*θ); # uᵢ = 2β yᵢ x̂ᵢᵀθ, for every example at once
    return sum(log1p.(exp.(-u))) + (δ/2)*dot(θ, θ); # log1p(a) is log(1 + a)
end

"""
    my_logistic_regression(X::Array{<:Number,2}, y::Array{<:Number,1}; α::Float64,
        β::Float64 = 1.0, δ::Float64 = 0.0, ϵ::Float64 = 1e-6,
        maxiter::Int64 = 50_000) -> NamedTuple

Estimate the parameters `θ` of a logistic regression classifier by minimizing the
regularized cross-entropy loss from the L9c lecture with gradient descent.

The loss is `J_δ(θ) = Σᵢ log(1 + exp(-uᵢ)) + (δ/2)‖θ‖²`, where `uᵢ = 2β yᵢ x̂ᵢᵀθ`, and its
gradient is `∇J_δ(θ) = -2β Σᵢ (1 - σ(uᵢ)) yᵢ x̂ᵢ + δθ`, where `σ` is the logistic
function. Training starts from `θ = 0` and takes the step `θ ← θ - α∇J_δ(θ)` with a
constant learning rate `α`. It stops when a step changes `θ` by at most `ϵ`, measured
with the Euclidean norm, or after `maxiter` steps, whichever comes first.

A learning rate `α ≤ 1/(L + δ)`, where `L = β²‖X‖₂²` and `‖X‖₂` is the largest singular
value of `X`, guarantees that no step increases the loss.

### Arguments
- `X::Array{<:Number,2}`: the augmented features, one row per example: the features,
  followed by a 1 for the bias. For `n` examples with `m` features, `X` is `n × (m+1)`.
- `y::Array{<:Number,1}`: the label of each example, `1` or `-1`, in the same order as
  the rows of `X`.
- `α::Float64`: the learning rate, a positive number. Required.
- `β::Float64 = 1.0`: the inverse temperature, a positive number.
- `δ::Float64 = 0.0`: the regularization parameter, at least zero.
- `ϵ::Float64 = 1e-6`: the stopping tolerance on the change in `θ`, a positive number.
- `maxiter::Int64 = 50_000`: the maximum number of gradient descent steps. At least 1.

### Returns
A `NamedTuple` with the fields:
- `θ::Array{Float64,1}`: the estimated parameters, one per column of `X`: the feature
  weights, followed by the bias.
- `iterations::Int64`: the number of steps taken, at most `maxiter`.
- `converged::Bool`: `true` when the last step changed `θ` by at most `ϵ`.
- `losses::Array{Float64,1}`: the regularized loss before the first step and after each
  step, so it has `iterations + 1` entries.

### Errors
Throws an `ArgumentError` if `X` has no rows, a label is not `1` or `-1`, `α`, `β`, or
`ϵ` is not positive, `δ` is negative, or `maxiter < 1`, and a `DimensionMismatch` if `y`
does not have one entry per row of `X`.

### Example
```julia
L = opnorm(training.X)^2; # β = 1, so L = ‖X‖₂²
result = L9dLogistic.my_logistic_regression(training.X, training.y, α = 1/L);
result.θ, result.iterations, result.converged
```
"""
function my_logistic_regression(X::Array{<:Number,2}, y::Array{<:Number,1}; α::Float64,
    β::Float64 = 1.0, δ::Float64 = 0.0, ϵ::Float64 = 1e-6,
    maxiter::Int64 = 50_000)::NamedTuple

    # Check the arguments; this part is complete -
    number_of_examples = size(X,1); # the number of training examples, one per row of X
    if number_of_examples < 1
        throw(ArgumentError("X must have at least one row"))
    end
    if length(y) != number_of_examples
        throw(DimensionMismatch("y must have one entry per row of X"))
    end
    if !all((y .== 1) .| (y .== -1)) # .| is "or", applied entry by entry
        throw(ArgumentError("every label in y must be 1 or -1"))
    end
    if !(α > 0 && β > 0 && ϵ > 0)
        throw(ArgumentError("α, β, and ϵ must be positive"))
    end
    if δ < 0
        throw(ArgumentError("δ must be at least zero"))
    end
    if maxiter < 1
        throw(ArgumentError("maxiter must be at least 1"))
    end

    # Initialize; this part is complete -
    θ = zeros(size(X,2)); # the initial guess θ⁽⁰⁾ = 0: the four weights, then the bias
    losses = [regularized_loss(X, y, θ, β = β, δ = δ)]; # the loss before the first step

    # Main loop: one gradient descent step for each value of k -
    for k ∈ 1:maxiter

        # Step 1: the gradient of the regularized loss at θ. Start from the gradient of
        # the penalty, δθ, then add one term for each training example -
        ∇J = δ*θ; # this line is complete
        for i ∈ 1:number_of_examples
            x̂ = X[i,:]; # the augmented features of example i: row i of X, as a vector
            u = 2*β*y[i]*dot(x̂, θ); # uᵢ = 2β yᵢ x̂ᵢᵀθ; this line is complete

            # TODO 1: term i of the gradient. Replace the right-hand side, ∇J, with ∇J plus
            # term i of the L9c gradient, -2β(1 - σ(uᵢ)) yᵢ x̂ᵢ. In this code, uᵢ is u, yᵢ is
            # y[i], and x̂ᵢ is x̂. Hint: σ(u) is the logistic function, defined at the top of
            # this file, and * multiplies a vector by a number.
            ∇J = ∇J;
        end

        # TODO 2: the update, step 2 of the L9c algorithm. Replace the right-hand side, θ,
        # with θ - α∇J, which steps against the gradient with the learning rate α.
        θ_new = θ;
        push!(losses, regularized_loss(X, y, θ_new, β = β, δ = δ)); # this line is complete

        # Step 3: how far did the parameters move? This part is complete -
        change = norm(θ_new - θ); # the Euclidean norm of the step
        θ = θ_new; # carry the new parameters into the next step

        # TODO 3: the stopping test, step 3 of the L9c algorithm. Replace false with a test
        # that is true when this step changed θ by at most ϵ, or k has reached maxiter. The
        # length of this step is in change. Hint: a || b is true when a or b is true.
        if false
            return (θ = θ, iterations = k, converged = (change ≤ ϵ), losses = losses); # this line is complete
        end
    end

    # We get here only while TODO 3 is incomplete: once it is done, the stopping test
    # is true at k = maxiter at the latest. This part is complete -
    throw(ErrorException("Oooops! The `my_logistic_regression(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 through TODO 3."))
end

end # module L9dLogistic
