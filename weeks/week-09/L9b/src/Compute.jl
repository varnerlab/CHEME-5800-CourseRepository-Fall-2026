# =============================================================================
# CHEME 5800 | L9b student work: the Perceptron training loop
# =============================================================================
# This is the file you edit in this lab. Complete my_perceptron(...) below by
# filling in the three lines marked TODO 1, TODO 2, and TODO 3; everything else
# is already written. Each TODO is one line of the L9a Perceptron pseudocode.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the my_results cell and the check cell.
# You are done when every test in the check cell passes.
#
# The data generator is in Utility.jl, and the figures are in Visualize.jl.
# =============================================================================
module L9bXOR

import LinearAlgebra: dot # dot(a, b) is the inner product aᵀb of two vectors

export my_perceptron

"""
    my_perceptron(X::Array{Float64,2}, y::Array{Float64,1};
        maxiter::Int64 = 1000, mistakes::Int64 = 0) -> NamedTuple

Learn the parameters `θ` of a linear classifier with the online Perceptron algorithm
from the L9a lecture.

The classifier gives example `i` the label of the sign of its score, `x̂ᵢᵀθ`. Training
starts from `θ = 0` and passes through the examples in row order, one at a time.
Example `i` is a mistake when `yᵢ x̂ᵢᵀθ ≤ 0`, that is, when its score has the wrong
sign or is zero; after each mistake, the parameters are updated before the next
example is visited. Training stops after the first pass with at most `mistakes`
mistakes, or after `maxiter` passes, whichever comes first.

On data that are not linearly separable, every pass makes at least one mistake, so
with `mistakes = 0` the loop runs all `maxiter` passes.

### Arguments
- `X::Array{Float64,2}`: the augmented features, one row per example: the features
  (in this lab, the two coordinates of a point, in arbitrary units), followed by a 1
  for the bias. For `n` examples with `m` features, `X` is `n × (m+1)`.
- `y::Array{Float64,1}`: the label of each example, `1` or `-1`, in the same order as
  the rows of `X`.
- `maxiter::Int64 = 1000`: the maximum number of passes through the training data,
  `T` in L9a. At least 1.
- `mistakes::Int64 = 0`: the mistake threshold, `M` in L9a. Training stops after the
  first pass with at most this many mistakes.

### Returns
A `NamedTuple` with the fields:
- `θ::Array{Float64,1}`: the learned parameters, one per column of `X`: the feature
  weights, followed by the bias.
- `passes::Int64`: the number of passes made, at most `maxiter`.
- `mistakes::Int64`: the number of mistakes in the last pass.

### Errors
Throws an `ArgumentError` if `X` has no rows, a label is not `1` or `-1`, or
`maxiter < 1`, and a `DimensionMismatch` if `y` does not have one entry per row of `X`.

### Example
```julia
D = training["half circle"]; # the features in columns 1 and 2, the label in column 3
X = [D[:,1:end-1] ones(size(D,1))]; # the augmented features: append a column of ones
result = L9bXOR.my_perceptron(X, D[:,end], maxiter = 1000, mistakes = 0);
result.θ, result.passes, result.mistakes
```
"""
function my_perceptron(X::Array{Float64,2}, y::Array{Float64,1};
    maxiter::Int64 = 1000, mistakes::Int64 = 0)::NamedTuple

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
    if maxiter < 1
        throw(ArgumentError("maxiter must be at least 1"))
    end

    # Initialize, with the names from L9a; this part is complete -
    T = maxiter; # the maximum number of passes through the training data
    M = mistakes; # the mistake threshold: stop after a pass with at most M mistakes
    θ = zeros(size(X,2)); # the parameters (w₁, w₂, b), starting from zero

    # Main loop: one pass through the training data for each value of t -
    for t ∈ 1:T

        # Step 1: start the pass with no mistakes; this part is complete -
        number_of_mistakes = 0; # the number of mistakes in this pass so far

        # Step 2: visit the training examples in order, one at a time -
        for i ∈ 1:number_of_examples
            x̂ = X[i,:]; # the augmented features of example i: row i of X, as a vector

            # TODO 1: the mistake test. Replace false with the L9a test for a mistake,
            # yᵢ x̂ᵢᵀθ ≤ 0. In this code, yᵢ is y[i] and x̂ᵢ is x̂.
            # Hint: dot(x̂, θ) computes x̂ᵀθ, and ≤ can also be typed as <=.
            if false

                # TODO 2: the update. Replace the right-hand side, θ, with the L9a
                # update θ + yᵢ x̂ᵢ, which moves the score of example i toward the
                # correct sign. Hint: * multiplies a vector by a number, and + adds two
                # vectors entry by entry.
                θ = θ;
                number_of_mistakes += 1; # count the mistake; this line is complete
            end
        end

        # Step 3 of L9a, t ← t + 1, is done by the for loop: t already counts this pass.

        # TODO 3: the stopping test, step 4 of L9a. Replace false with a test that is
        # true when this pass made at most M mistakes or t has reached T. The mistakes
        # in this pass are in number_of_mistakes.
        # Hint: a || b is true when a or b is true.
        if false
            return (θ = θ, passes = t, mistakes = number_of_mistakes); # this line is complete
        end
    end

    # We get here only while TODO 3 is incomplete: once it is done, the stopping test
    # is true on the last pass, t = T, at the latest. This part is complete -
    throw(ErrorException("Oooops! The `my_perceptron(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 through TODO 3."))
end

end # module L9bXOR
