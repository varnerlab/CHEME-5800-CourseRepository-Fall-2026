# =============================================================================
# CHEME 5800 | L8d supplied helpers: feature scaling and ridge regression
# =============================================================================
# scale_features(...), ridge_fit(...), and ridge_predict(...) are the pieces your
# my_cross_validation(...) in Compute.jl puts together. You do not need to edit
# this file; your work is in Compute.jl. Include.jl loads this file once, so
# after an edit here, restart the kernel.
# =============================================================================
module L8dUtility

import LinearAlgebra: I # the identity matrix
import Statistics: mean, std # column means and standard deviations

export scale_features, ridge_fit, ridge_predict

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
Z_train, Z_test = scale_features(X_train, X_test);
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
θ̂ = ridge_fit(Z_train, y_train, 100.0);
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

end
