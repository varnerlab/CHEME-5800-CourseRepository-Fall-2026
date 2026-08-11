const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09"))
include(joinpath(WEEK_ROOT, "L9a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L9b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L9c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L9d", "Include.jl"))

@testset "L9b XOR representation" begin
    X = [0.0 0.0; 0.0 1.0; 1.0 0.0; 1.0 1.0]
    y = [0, 1, 1, 0]
    linear = fit_perceptron(X, y; epochs = 40, learning_rate = 0.1)
    interaction = fit_perceptron(hcat(X, X[:, 1] .* X[:, 2]), y; epochs = 80, learning_rate = 0.1)
    @test classification_metrics(y, predict_perceptron(linear, X)).accuracy < 1.0
    @test classification_metrics(y, predict_perceptron(interaction, hcat(X, X[:, 1] .* X[:, 2]))).accuracy == 1.0
end

@testset "L9 AI4I data contract" begin
    path = joinpath(WEEK_ROOT, "L9d", "data", "ai4i2020.csv")
    frame = load_ai4i(path)
    data = prepare_ai4i(frame)
    @test size(data.X) == (10_000, 7)
    @test sum(data.y) == 339
    @test data.feature_names == ["air_temperature", "process_temperature", "rotational_speed",
        "torque", "tool_wear", "type_M", "type_H"]
    @test !any(name -> name in data.feature_names, ["TWF", "HDF", "PWF", "OSF", "RNF"])
    split = stratified_split(data.y; seed = 5800)
    @test isempty(intersect(split.train, split.test))
    @test sort(vcat(split.train, split.test)) == collect(1:10_000)
    @test split == stratified_split(data.y; seed = 5800)
    scaled = standardize_from_training(data.X[split.train, :], data.X[split.test, :])
    @test maximum(abs, mean(scaled.train; dims = 1)) < 1e-10
    @test_throws ArgumentError load_ai4i(joinpath(WEEK_ROOT, "missing.csv"))
end

@testset "L9 classifier comparison" begin
    frame = load_ai4i(joinpath(WEEK_ROOT, "L9d", "data", "ai4i2020.csv"))
    data = prepare_ai4i(frame)
    split = stratified_split(data.y; seed = 5800)
    scaled = standardize_from_training(data.X[split.train, :], data.X[split.test, :])
    y_train, y_test = data.y[split.train], data.y[split.test]
    perceptron = fit_perceptron(scaled.train, y_train)
    logistic = fit_logistic(scaled.train, y_train)
    perceptron_metrics = classification_metrics(y_test, predict_perceptron(perceptron, scaled.test))
    logistic_metrics = classification_metrics(y_test, predict_logistic(logistic, scaled.test).labels)
    baseline = classification_metrics(y_test, zeros(Int, length(y_test)))
    @test baseline.accuracy > logistic_metrics.accuracy
    @test baseline.recall == 0.0
    @test perceptron_metrics.recall > 0.70
    @test logistic_metrics.recall > 0.70
    @test last(logistic.losses) < first(logistic.losses)
    @test_throws DimensionMismatch classification_metrics(y_test, y_test[1:end-1])
end
