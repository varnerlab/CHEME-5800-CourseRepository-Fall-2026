module Week09Core

import CSV
import DataFrames
import LinearAlgebra: dot
import Random
import Statistics: mean, std

export classification_metrics, fit_logistic, fit_perceptron, load_predictive_maintenance,
    predict_logistic, predict_perceptron, prepare_predictive_maintenance, standardize_from_training,
    stratified_split

function load_predictive_maintenance(path::AbstractString)
    isfile(path) || throw(ArgumentError("predictive-maintenance file does not exist: $(path)"))
    frame = CSV.read(path, DataFrames.DataFrame)
    DataFrames.nrow(frame) == 10_000 || throw(ArgumentError("expected 10,000 predictive-maintenance observations"))
    return frame
end

function prepare_predictive_maintenance(frame::DataFrames.AbstractDataFrame)
    required = ["Type", "Air temperature [K]", "Process temperature [K]",
        "Rotational speed [rpm]", "Torque [Nm]", "Tool wear [min]", "Machine failure"]
    all(name -> name in DataFrames.names(frame), required) || throw(ArgumentError("predictive-maintenance columns are incomplete"))
    type = String.(frame[!, "Type"])
    all(value -> value in ("L", "M", "H"), type) || throw(ArgumentError("unexpected product type"))
    X = hcat(
        Float64.(frame[!, "Air temperature [K]"]),
        Float64.(frame[!, "Process temperature [K]"]),
        Float64.(frame[!, "Rotational speed [rpm]"]),
        Float64.(frame[!, "Torque [Nm]"]),
        Float64.(frame[!, "Tool wear [min]"]),
        Float64.(type .== "M"),
        Float64.(type .== "H"),
    )
    y = Int.(frame[!, "Machine failure"])
    all(value -> value in (0, 1), y) || throw(ArgumentError("machine-failure target must be binary"))
    names = ["air_temperature", "process_temperature", "rotational_speed", "torque",
        "tool_wear", "type_M", "type_H"]
    return (X = X, y = y, feature_names = names)
end

function stratified_split(y::AbstractVector{<:Integer}; train_fraction::Real = 0.8, seed::Integer = 5800)
    0 < train_fraction < 1 || throw(ArgumentError("train_fraction must lie in (0,1)"))
    classes = sort(unique(y))
    classes == [0, 1] || throw(ArgumentError("binary classes 0 and 1 are required"))
    rng = Random.MersenneTwister(seed)
    training, testing = Int[], Int[]
    for class in classes
        indices = Random.shuffle(rng, findall(==(class), y))
        count = clamp(floor(Int, train_fraction * length(indices)), 1, length(indices) - 1)
        append!(training, indices[1:count])
        append!(testing, indices[(count + 1):end])
    end
    Random.shuffle!(rng, training)
    Random.shuffle!(rng, testing)
    return (train = training, test = testing)
end

function standardize_from_training(train::AbstractMatrix{<:Real}, test::AbstractMatrix{<:Real})
    size(train, 2) == size(test, 2) || throw(DimensionMismatch("train and test feature counts must match"))
    center = vec(mean(train; dims = 1))
    scale = vec(std(train; dims = 1, corrected = false))
    scale[scale .== 0] .= 1.0
    return (train = (Float64.(train) .- transpose(center)) ./ transpose(scale),
        test = (Float64.(test) .- transpose(center)) ./ transpose(scale), center = center, scale = scale)
end

function fit_perceptron(X::AbstractMatrix{<:Real}, y::AbstractVector{<:Integer};
    epochs::Integer = 30, learning_rate::Real = 0.02, seed::Integer = 5800)
    size(X, 1) == length(y) || throw(DimensionMismatch("X rows must match y"))
    epochs > 0 || throw(ArgumentError("epochs must be positive"))
    all(value -> value in (0, 1), y) || throw(ArgumentError("targets must be 0/1"))
    design = hcat(ones(size(X, 1)), Float64.(X))
    weights = zeros(size(design, 2))
    positives = count(==(1), y)
    positive_weight = (length(y) - positives) / positives
    rng = Random.MersenneTwister(seed)
    mistakes = Int[]
    for _ in 1:epochs
        epoch_mistakes = 0
        for index in Random.randperm(rng, length(y))
            prediction = dot(view(design, index, :), weights) >= 0 ? 1 : 0
            error = y[index] - prediction
            if error != 0
                weight = y[index] == 1 ? positive_weight : 1.0
                weights .+= learning_rate * weight * error .* view(design, index, :)
                epoch_mistakes += 1
            end
        end
        push!(mistakes, epoch_mistakes)
    end
    return (weights = weights, mistakes = mistakes)
end

predict_perceptron(model, X::AbstractMatrix{<:Real}) = Int.(hcat(ones(size(X, 1)), Float64.(X)) * model.weights .>= 0)

_sigmoid(value::Real) = value >= 0 ? 1 / (1 + exp(-value)) : exp(value) / (1 + exp(value))

function fit_logistic(X::AbstractMatrix{<:Real}, y::AbstractVector{<:Integer};
    iterations::Integer = 1200, learning_rate::Real = 0.08, lambda::Real = 1e-3)
    size(X, 1) == length(y) || throw(DimensionMismatch("X rows must match y"))
    iterations > 0 || throw(ArgumentError("iterations must be positive"))
    all(value -> value in (0, 1), y) || throw(ArgumentError("targets must be 0/1"))
    design = hcat(ones(size(X, 1)), Float64.(X))
    weights = zeros(size(design, 2))
    positives = count(==(1), y)
    positive_weight = (length(y) - positives) / positives
    sample_weights = [value == 1 ? positive_weight : 1.0 for value in y]
    losses = Float64[]
    for iteration in 1:iterations
        probabilities = _sigmoid.(design * weights)
        gradient = transpose(design) * (sample_weights .* (probabilities .- y)) / sum(sample_weights)
        gradient[2:end] .+= lambda .* weights[2:end]
        weights .-= learning_rate .* gradient
        if iteration == 1 || iteration % 100 == 0 || iteration == iterations
            clipped = clamp.(probabilities, 1e-12, 1 - 1e-12)
            push!(losses, -sum(sample_weights .* (y .* log.(clipped) .+ (1 .- y) .* log.(1 .- clipped))) / sum(sample_weights))
        end
    end
    return (weights = weights, losses = losses)
end

function predict_logistic(model, X::AbstractMatrix{<:Real}; threshold::Real = 0.5)
    0 < threshold < 1 || throw(ArgumentError("threshold must lie in (0,1)"))
    probabilities = _sigmoid.(hcat(ones(size(X, 1)), Float64.(X)) * model.weights)
    return (probabilities = probabilities, labels = Int.(probabilities .>= threshold))
end

function classification_metrics(y::AbstractVector{<:Integer}, predicted::AbstractVector{<:Integer})
    length(y) == length(predicted) || throw(DimensionMismatch("targets and predictions must match"))
    tp = count(i -> y[i] == 1 && predicted[i] == 1, eachindex(y))
    tn = count(i -> y[i] == 0 && predicted[i] == 0, eachindex(y))
    fp = count(i -> y[i] == 0 && predicted[i] == 1, eachindex(y))
    fn = count(i -> y[i] == 1 && predicted[i] == 0, eachindex(y))
    precision = tp + fp == 0 ? 0.0 : tp / (tp + fp)
    recall = tp + fn == 0 ? 0.0 : tp / (tp + fn)
    return (accuracy = (tp + tn) / length(y), precision = precision, recall = recall,
        specificity = tn + fp == 0 ? 0.0 : tn / (tn + fp), tp = tp, tn = tn, fp = fp, fn = fn)
end

end
