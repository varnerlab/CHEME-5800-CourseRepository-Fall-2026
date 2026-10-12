# L8d student cross-validation implementation. Complete my_cross_validation(...)
# below; the helpers it calls (scale_features, ridge_fit, ridge_predict) are in
# Utility.jl. Apart from the three TODO steps, this file matches Compute-solution.jl.
module L8dRidgeCV

import Random # seeded, reproducible shuffles
import Statistics: mean, std # averages and spreads of the fold errors
import ..L8dUtility: scale_features, ridge_fit, ridge_predict # the supplied helpers in Utility.jl

export my_cross_validation

"""
    my_cross_validation(X::Matrix{Float64}, y::Vector{Float64}, δ_values::Vector{Float64};
        k::Int = 10, seed::Int = 5800) -> NamedTuple

Estimate the validation error of a ridge regression model for each candidate
regularization parameter with k-fold cross-validation.

The rows are shuffled with a seeded random number generator and cut into `k`
folds. The first `k - 1` folds hold `div(n, k)` rows each, and the last fold also
takes the leftover rows. For each `δ` in `δ_values` and each fold `j`, the
model is trained on the other `k - 1` folds and validated on fold `j`:

1. Scale the features using the training rows only (`scale_features`).
2. Fit the ridge model to the training rows (`ridge_fit`).
3. Predict the validation responses (`ridge_predict`) and compute the mean
   squared error on fold `j`.

The validation error for `δ` is the average over the folds,
`CV_k(δ) = (1/k) Σⱼ MSEⱼ(δ)`.

# Arguments
- `X::Matrix{Float64}`: unscaled features, one row per house. The function scales
  them inside each fold.
- `y::Vector{Float64}`: observed responses, one per row of `X`.
- `δ_values::Vector{Float64}`: candidate regularization parameters, each finite and
  nonnegative.
- `k::Int = 10`: number of folds, between 2 and the number of rows.
- `seed::Int = 5800`: seed for the shuffle, so the folds are the same on every call.

# Returns
A NamedTuple with the fields:
- `δ_values::Vector{Float64}`: the candidate regularization parameters.
- `mean_errors::Vector{Float64}`: the average validation mean squared error over
  the folds, one per `δ`.
- `std_errors::Vector{Float64}`: the standard deviation of the fold errors, one
  per `δ`.
- `folds::Vector{Vector{Int}}`: the rows in each fold. Every row appears in
  exactly one fold.

# Errors
Throw a `DimensionMismatch` if `y` does not have one entry per row of `X`, and an
`ArgumentError` if `k` is out of range or a value of `δ` is negative or not finite.

# Example
```julia
δ_values = 10.0 .^ range(-3, 4, length = 71);
cv_results = L8dRidgeCV.my_cross_validation(X_train, y_train, δ_values; k = 10);
```
"""
function my_cross_validation(X::Matrix{Float64}, y::Vector{Float64}, δ_values::Vector{Float64};
    k::Int = 10, seed::Int = 5800)

    # Check the arguments; this part is complete -
    n = size(X, 1); # number of rows (houses)
    if length(y) != n
        throw(DimensionMismatch("y must have one entry per row of X"))
    end
    if k < 2 || k > n
        throw(ArgumentError("k must be between 2 and the number of rows of X"))
    end
    for δ ∈ δ_values
        if !isfinite(δ) || δ < 0
            throw(ArgumentError("every value of δ must be finite and nonnegative"))
        end
    end

    # Shuffle the rows and cut them into k folds; this part is complete -
    Random.seed!(seed); # fix the random numbers, so the folds are the same on every call
    shuffled_rows = Random.randperm(n); # the row numbers 1, 2, ..., n in a random order
    fold_size = div(n, k); # rows per fold, rounded down
    folds = Vector{Vector{Int}}(); # folds[j] holds the rows in fold j
    for j ∈ 1:k
        first_row = (j - 1)*fold_size + 1; # where fold j starts in shuffled_rows
        last_row = (j == k) ? n : j*fold_size; # the last fold also takes the leftover rows
        push!(folds, shuffled_rows[first_row:last_row]);
    end
    all_rows = collect(1:n); # every row number, used to find the training rows

    # Storage: fold_errors[i, j] is the validation error for δ_values[i] on fold j -
    fold_errors = fill(NaN, length(δ_values), k); # NaN marks an entry we have not computed yet

    # Main loop: for each δ, train on k - 1 folds and validate on the fold left out -
    for i ∈ eachindex(δ_values)
        δ = δ_values[i]; # the candidate regularization parameter
        for j ∈ 1:k
            validation_rows = folds[j]; # the houses we hold out

            # TODO 1: Find the training rows: every row that is not in fold j.
            # The setdiff(a, b) function returns the entries of a that are not in b.
            # Store the result in training_rows, using all_rows and validation_rows.

            # TODO 2: Scale the features with the training rows only, then fit the model.
            # Call scale_features(X[training_rows, :], X[validation_rows, :]), which
            # returns Z_train and Z_validation. Then store
            # ridge_fit(Z_train, y[training_rows], δ) in θ̂.

            # TODO 3: Predict the validation responses and store their error.
            # Store ridge_predict(θ̂, Z_validation) in ŷ, then store the mean squared
            # error, mean((y[validation_rows] .- ŷ).^2), in fold_errors[i, j].
        end
    end

    # Every entry should now hold a number; this part is complete -
    if any(isnan, fold_errors)
        throw(ErrorException("Oooops! The `my_cross_validation(...)` function is not finished yet - " *
                             "we'd better fix that. Complete TODO 1 through TODO 3."))
    end

    # Average over the folds: each row of fold_errors holds the k errors for one δ -
    mean_errors = vec(mean(fold_errors, dims = 2)); # CV_k(δ), one per δ
    std_errors = vec(std(fold_errors, dims = 2)); # spread of the fold errors, one per δ

    return (δ_values = δ_values, mean_errors = mean_errors, std_errors = std_errors, folds = folds)
end

end
