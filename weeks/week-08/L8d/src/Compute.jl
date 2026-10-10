# L8d ridge regression helpers and the student cross-validation implementation.
# Students complete my_cross_validation(...) below; everything else matches
# Compute-solution.jl.
module L8dRidgeCV

import LinearAlgebra: I # the identity matrix
import Random # seeded, reproducible shuffles
import Statistics: mean, std # column means and standard deviations

export scale_features, ridge_fit, ridge_predict, my_cross_validation

"""
    scale_features(X_train::Matrix{Float64}, X_other::Matrix{Float64})

Put every feature (column) on a common scale, using statistics from the training
rows only. Each column of `X_train` is shifted by its mean and divided by its
standard deviation. The same training mean and standard deviation are then
applied to `X_other`.

# Arguments
- `X_train::Matrix{Float64}`: training features, one row per house and one column
  per feature.
- `X_other::Matrix{Float64}`: features of houses that play no part in computing
  the scale, for example a validation fold or the testing set. It must have the
  same columns as `X_train`.

# Returns
A tuple `(Z_train, Z_other)`:
- `Z_train::Matrix{Float64}`: the scaled training features. Every column has mean
  zero and standard deviation one.
- `Z_other::Matrix{Float64}`: `X_other` scaled with the *training* mean and
  standard deviation, so its columns need not have mean zero.

# Errors
Throw a `DimensionMismatch` if the two matrices have different numbers of columns,
and an `ArgumentError` if a training column is constant (zero standard deviation).

# Example
```julia
Z_train, Z_test = L8dRidgeCV.scale_features(X_train, X_test);
```
"""
function scale_features(X_train::Matrix{Float64}, X_other::Matrix{Float64})

    # Check the arguments -
    if size(X_train, 2) != size(X_other, 2)
        throw(DimensionMismatch("X_train and X_other must have the same number of columns"))
    end

    # Compute the mean and the standard deviation of each training column -
    column_mean = mean(X_train, dims = 1); # 1 × m row: the mean of each column
    column_std = std(X_train, dims = 1); # 1 × m row: the standard deviation of each column
    if any(iszero, column_std)
        throw(ArgumentError("every training column must vary; found a constant column"))
    end

    # Shift and divide; the dots apply the 1 × m rows to every row of the matrix -
    Z_train = (X_train .- column_mean) ./ column_std;
    Z_other = (X_other .- column_mean) ./ column_std; # the training statistics, not those of X_other

    return Z_train, Z_other
end

"""
    ridge_fit(Z::Matrix{Float64}, y::Vector{Float64}, δ::Real) -> Vector{Float64}

Estimate the parameters of a ridge regression model that leaves the intercept out
of the penalty. The function appends a column of ones to `Z` (as the last column,
following the L7c and L8c lectures) to form the augmented data matrix `X̂`, and
solves:

    θ̂ = (X̂ᵀX̂ + δJ)⁻¹ X̂ᵀy

where `J` is the identity matrix with a zero in its last diagonal entry, so the
penalty skips the intercept.

# Arguments
- `Z::Matrix{Float64}`: scaled features, one row per house, for example from
  `scale_features`.
- `y::Vector{Float64}`: observed responses, one per row of `Z` (house prices, in
  millions).
- `δ::Real`: regularization parameter, finite and nonnegative. `δ = 0` gives the
  ordinary least-squares estimate, which requires `Z` to have full column rank.

# Returns
- `θ̂::Vector{Float64}`: one parameter per column of `Z`, followed by the
  intercept as the last entry.

# Errors
Throw a `DimensionMismatch` if `y` does not have one entry per row of `Z`, and an
`ArgumentError` if `δ` is negative or not finite.

# Example
```julia
θ̂ = L8dRidgeCV.ridge_fit(Z_train, y_train, 100.0);
```
"""
function ridge_fit(Z::Matrix{Float64}, y::Vector{Float64}, δ::Real)

    # Check the arguments -
    if size(Z, 1) != length(y)
        throw(DimensionMismatch("y must have one entry per row of Z"))
    end
    if !isfinite(δ) || δ < 0
        throw(ArgumentError("δ must be finite and nonnegative"))
    end

    # Build the augmented data matrix: the features, then a column of ones for the intercept -
    X̂ = hcat(Z, ones(size(Z, 1))); # hcat joins matrices side by side
    p = size(X̂, 2); # number of parameters, including the intercept

    # Build the penalty matrix: the identity, without a penalty on the intercept -
    J = Matrix{Float64}(I, p, p); # p × p identity matrix
    J[p, p] = 0.0; # the intercept is the last parameter

    # Solve the regularized normal equations -
    θ̂ = inv(transpose(X̂)*X̂ + δ*J)*transpose(X̂)*y;

    return θ̂
end

"""
    ridge_predict(θ̂::Vector{Float64}, Z::Matrix{Float64}) -> Vector{Float64}

Compute the predicted responses `ŷ = X̂θ̂` of a model estimated by `ridge_fit`,
where `X̂` is `Z` with a column of ones appended as its last column.

# Arguments
- `θ̂::Vector{Float64}`: one parameter per column of `Z`, followed by the
  intercept, as returned by `ridge_fit`.
- `Z::Matrix{Float64}`: scaled features of the houses to predict, scaled with the
  same training statistics used to fit `θ̂`.

# Returns
- `ŷ::Vector{Float64}`: one predicted response per row of `Z`.

# Errors
Throw a `DimensionMismatch` if `θ̂` does not have one more entry than `Z` has
columns.
"""
function ridge_predict(θ̂::Vector{Float64}, Z::Matrix{Float64})

    # Check the arguments -
    if length(θ̂) != size(Z, 2) + 1
        throw(DimensionMismatch("θ̂ must have one entry per column of Z, plus the intercept"))
    end

    # Append the column of ones and multiply -
    X̂ = hcat(Z, ones(size(Z, 1))); # the same augmented data matrix as ridge_fit
    ŷ = X̂*θ̂;

    return ŷ
end

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
