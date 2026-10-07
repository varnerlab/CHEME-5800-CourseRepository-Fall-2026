module L7dOLS

import LinearAlgebra: diag, norm # diagonal entries and vector length
import Statistics: mean # averages in the accuracy report

export ols_fit, regression_report

"""
    ols_fit(X̂, y) -> NamedTuple

Estimate the parameters of the linear model `y = X̂θ + ϵ` by ordinary least squares,
following the overdetermined case of the L7c lecture. The estimate solves the normal
equations:

    θ̂ = (X̂ᵀX̂)⁻¹ X̂ᵀ y

The function then estimates the error variance from the residuals `r = y - X̂θ̂`, and
the standard error of each parameter from the diagonal of `σ̂² (X̂ᵀX̂)⁻¹`.

# Arguments
- `X̂::Matrix{Float64}`: the augmented data matrix, with `n` rows (observations)
  and `p` columns (parameters). Row `i` holds the features of observation `i`
  followed by a `1` for the intercept, as in the lecture.
- `y::Vector{Float64}`: the observed responses, one per row of `X̂`.

# Returns
A `NamedTuple` with the fields:
- `θ̂::Vector{Float64}`: the least-squares estimate, one parameter per column of `X̂`,
  with the intercept last. Each feature parameter is in the units of `y` per unit
  of its feature; the intercept is in the units of `y`.
- `residuals::Vector{Float64}`: the observed minus the predicted responses,
  `y - X̂θ̂`, in the units of `y`.
- `σ̂²::Float64`: the estimated error variance `‖r‖² / (n - p)`, in the squared
  units of `y`.
- `SE::Vector{Float64}`: the standard error of each parameter, in the units of
  that parameter.

The lecture's assumptions apply: `X̂` has full column rank, so `X̂ᵀX̂` can be
inverted, and the errors are independent and normal with zero mean and the same
variance. The function does not check the rank. If the columns of `X̂` are linearly
dependent, or nearly so, the inversion may throw an error or return an inaccurate
estimate.

# Throws
- `DimensionMismatch` if the number of rows of `X̂` differs from the length of `y`.
- `ArgumentError` unless there are more observations than parameters (`n > p`).
"""
function ols_fit(X̂::Matrix{Float64}, y::Vector{Float64})

    # check the inputs -
    n = size(X̂, 1) # number of observations (rows of X̂)
    p = size(X̂, 2) # number of parameters (columns of X̂)
    if n != length(y)
        throw(DimensionMismatch("X̂ has $(n) rows, but y has $(length(y)) entries"))
    end
    if n <= p
        throw(ArgumentError("ols_fit needs more observations than parameters (n > p) to estimate σ̂² and SE, but n = $(n) and p = $(p)"))
    end

    # solve the normal equations -
    XtX_inv = inv(transpose(X̂) * X̂) # (X̂ᵀX̂)⁻¹
    θ̂ = XtX_inv * transpose(X̂) * y # least-squares estimate

    # estimate the error variance from the residuals -
    r = y - X̂ * θ̂ # residuals: observed minus predicted
    σ̂² = norm(r)^2 / (n - p) # divide by n - p, the degrees of freedom left after fitting p parameters

    # compute the standard error of each parameter -
    SE = sqrt.(σ̂² * diag(XtX_inv)) # the dot applies sqrt to every entry

    return (θ̂ = θ̂, residuals = r, σ̂² = σ̂², SE = SE)
end

"""
    regression_report(y, predictions) -> NamedTuple

Measure how closely the model `predictions` match the observed values `y`.

# Arguments
- `y::AbstractVector{<:Real}`: the observed values.
- `predictions::AbstractVector{<:Real}`: the model predictions, one per observed value.

# Returns
A `NamedTuple` with the fields:
- `rmse::Float64`: the root-mean-square error, in the units of `y`.
- `mae::Float64`: the mean absolute error, in the units of `y`.
- `r2::Float64`: the coefficient of determination, one minus `sse` divided by the
  sum of squared deviations of `y` from its mean. It is `NaN` when that computed
  sum is exactly zero.
- `sse::Float64`: the sum of squared errors, in the squared units of `y`.

# Throws
- `DimensionMismatch` if the two vectors differ in length.
"""
function regression_report(y::AbstractVector{<:Real}, predictions::AbstractVector{<:Real})

    # check the inputs -
    if length(y) != length(predictions)
        throw(DimensionMismatch("y has $(length(y)) entries, but predictions has $(length(predictions))"))
    end

    # compute the errors -
    observed = Vector{Float64}(y) # the observed values, as floating-point numbers
    fitted = Vector{Float64}(predictions) # the predictions, as floating-point numbers
    residuals = observed - fitted # observed minus predicted, one per observation
    sse = sum(residuals .^ 2) # sum of squared errors

    # compute the spread of y about its mean -
    average = mean(observed) # mean of the observed values
    total = sum((observed .- average) .^ 2) # sum of squared deviations from the mean

    # compute the accuracy measures -
    rmse = sqrt(mean(residuals .^ 2)) # root-mean-square error
    mae = mean(abs.(residuals)) # mean absolute error
    if total == 0
        r2 = NaN # the computed total is zero, so the ratio below is undefined
    else
        r2 = 1 - sse / total # 1 is a perfect fit; 0 is no better than predicting the mean
    end

    return (rmse = rmse, mae = mae, r2 = r2, sse = sse)
end

end
