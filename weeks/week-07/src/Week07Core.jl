module Week07Core

import CSV
import DataFrames
import LinearAlgebra: Diagonal, dot, svd
import Statistics: mean

export explained_energy, load_return_matrix, ols_fit, regression_report, truncated_svd

function load_return_matrix(path::AbstractString)
    isfile(path) || throw(ArgumentError("return-matrix file does not exist: $(path)"))
    frame = CSV.read(path, DataFrames.DataFrame)
    DataFrames.ncol(frame) >= 2 || throw(ArgumentError("return matrix requires a date and at least one series"))
    matrix = Matrix{Float64}(frame[:, DataFrames.Not(:date)])
    all(isfinite, matrix) || throw(ArgumentError("return matrix contains non-finite values"))
    return (dates = frame.date, tickers = String.(DataFrames.names(frame, DataFrames.Not(:date))), matrix = matrix, frame = frame)
end

function explained_energy(values::AbstractVector{<:Real})
    all(>=(0), values) || throw(ArgumentError("singular values must be nonnegative"))
    total = sum(abs2, values)
    total > 0 || throw(ArgumentError("at least one singular value must be positive"))
    return cumsum(abs2.(values)) ./ total
end

function truncated_svd(matrix::AbstractMatrix{<:Real}, rank::Integer)
    1 <= rank <= min(size(matrix)...) || throw(ArgumentError("rank is outside the matrix dimensions"))
    factorization = svd(Float64.(matrix))
    approximation = factorization.U[:, 1:rank] * Diagonal(factorization.S[1:rank]) *
        factorization.Vt[1:rank, :]
    relative_error = sqrt(sum(abs2, Float64.(matrix) - approximation) / sum(abs2, Float64.(matrix)))
    return (approximation = approximation, singular_values = factorization.S,
        explained = explained_energy(factorization.S), relative_error = relative_error)
end

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
