module L7dOLS

import LinearAlgebra # methods behind the backslash least-squares solve
import Statistics: mean # averages in the accuracy report

export ols_fit, regression_report

function ols_fit(X::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}; intercept::Bool = true)
    size(X, 1) == length(y) || throw(DimensionMismatch("X rows must match y"))
    size(X, 1) > size(X, 2) || throw(ArgumentError("OLS requires more observations than supplied features"))
    design = intercept ? hcat(ones(size(X, 1)), Float64.(X)) : Float64.(X)
    response = Float64.(y)
    coefficients = design \ response
    predictions = design * coefficients
    residuals = response - predictions
    return (coefficients = coefficients, predictions = predictions, residuals = residuals,
        design = design, intercept = intercept)
end

function regression_report(y::AbstractVector{<:Real}, predictions::AbstractVector{<:Real})
    length(y) == length(predictions) || throw(DimensionMismatch("observed and predicted vectors must match"))
    observed, fitted = Float64.(y), Float64.(predictions)
    residuals = observed - fitted
    sse = sum(abs2, residuals)
    total = sum(abs2, observed .- mean(observed))
    return (rmse = sqrt(mean(abs2, residuals)), mae = mean(abs.(residuals)),
        r2 = total == 0 ? NaN : 1 - sse / total, sse = sse)
end

end
