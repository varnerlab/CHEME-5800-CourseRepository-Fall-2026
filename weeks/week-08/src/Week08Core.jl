module Week08Core

import LinearAlgebra: Diagonal
import Random
import Statistics: mean, std

export cross_validate_ridge, kfold_indices, model_metrics, ridge_fit, standardize_train_test

function ridge_fit(X::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lambda::Real; intercept::Bool = true)
    size(X, 1) == length(y) || throw(DimensionMismatch("X rows must match y"))
    isfinite(lambda) && lambda >= 0 || throw(ArgumentError("lambda must be finite and nonnegative"))
    design = intercept ? hcat(ones(size(X, 1)), Float64.(X)) : Float64.(X)
    penalty = Diagonal(fill(Float64(lambda), size(design, 2)))
    intercept && (penalty[1, 1] = 0.0)
    coefficients = (transpose(design) * design + penalty) \ (transpose(design) * Float64.(y))
    predictions = design * coefficients
    return (coefficients = coefficients, predictions = predictions, design = design)
end

function model_metrics(observed::AbstractVector{<:Real}, predicted::AbstractVector{<:Real})
    length(observed) == length(predicted) || throw(DimensionMismatch("observed and predicted vectors must match"))
    y, yhat = Float64.(observed), Float64.(predicted)
    residual = y - yhat
    total = sum(abs2, y .- mean(y))
    return (rmse = sqrt(mean(abs2, residual)), mae = mean(abs.(residual)),
        r2 = total == 0 ? NaN : 1 - sum(abs2, residual) / total)
end

function kfold_indices(n::Integer, k::Integer; seed::Integer = 5800)
    n >= 2 || throw(ArgumentError("at least two observations are required"))
    2 <= k <= n || throw(ArgumentError("k must lie between 2 and n"))
    order = Random.randperm(Random.MersenneTwister(seed), n)
    folds = [Int[] for _ in 1:k]
    for (position, index) in enumerate(order)
        push!(folds[mod1(position, k)], index)
    end
    return folds
end

function standardize_train_test(train::AbstractMatrix{<:Real}, test::AbstractMatrix{<:Real})
    size(train, 2) == size(test, 2) || throw(DimensionMismatch("train and test feature counts must match"))
    center = vec(mean(train; dims = 1))
    scale = vec(std(train; dims = 1, corrected = false))
    all(>(0), scale) || throw(ArgumentError("training features must have nonzero variance"))
    return (train = (Float64.(train) .- transpose(center)) ./ transpose(scale),
        test = (Float64.(test) .- transpose(center)) ./ transpose(scale), center = center, scale = scale)
end

function cross_validate_ridge(X::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lambdas;
    k::Integer = 5, seed::Integer = 5800)
    size(X, 1) == length(y) || throw(DimensionMismatch("X rows must match y"))
    candidates = Float64.(collect(lambdas))
    isempty(candidates) && throw(ArgumentError("at least one lambda is required"))
    all(x -> isfinite(x) && x >= 0, candidates) || throw(ArgumentError("lambdas must be finite and nonnegative"))
    folds = kfold_indices(length(y), k; seed = seed)
    scores = zeros(length(candidates), k)
    all_indices = collect(eachindex(y))
    for (fold_index, validation) in enumerate(folds)
        training = setdiff(all_indices, validation)
        scaled = standardize_train_test(X[training, :], X[validation, :])
        for (candidate_index, lambda) in enumerate(candidates)
            fit = ridge_fit(scaled.train, y[training], lambda)
            validation_design = hcat(ones(length(validation)), scaled.test)
            predictions = validation_design * fit.coefficients
            scores[candidate_index, fold_index] = model_metrics(y[validation], predictions).rmse
        end
    end
    means = vec(mean(scores; dims = 2))
    best = argmin(means)
    return (lambdas = candidates, fold_rmse = scores, mean_rmse = means,
        best_lambda = candidates[best], best_index = best, folds = folds)
end

end
