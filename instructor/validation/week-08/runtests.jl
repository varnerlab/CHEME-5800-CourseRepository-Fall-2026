const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-08"))
include(joinpath(WEEK_ROOT, "L8a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L8b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L8c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L8d", "Include.jl"))

@testset "L8a/L8b ridge contracts" begin
    x = collect(range(-2.0, 2.0; length = 60))
    X = hcat(x, x .+ 0.03 .* sin.(10 .* x))
    y = 1.5 .+ 2.0 .* x
    ols = ridge_fit(X, y, 0.0)
    ridge = ridge_fit(X, y, 100.0)
    @test norm(ridge.coefficients[2:end]) < norm(ols.coefficients[2:end])
    @test abs(ridge.coefficients[1] - mean(y)) < 1e-10
    @test_throws ArgumentError ridge_fit(X, y, -1.0)
    @test_throws DimensionMismatch ridge_fit(X, y[1:end-1], 1.0)
end

@testset "L8c residual model checking" begin
    x = collect(range(-3.0, 3.0; length = 80))
    y = 2.0 .+ 1.5 .* x .+ 0.8 .* x.^2 .+ 0.25 .* sin.(11 .* x)
    linear = ridge_fit(reshape(x, :, 1), y, 0.0)
    quadratic = ridge_fit(hcat(x, x.^2), y, 0.0)
    linear_metrics = model_metrics(y, linear.predictions)
    quadratic_metrics = model_metrics(y, quadratic.predictions)
    @test quadratic_metrics.rmse < 0.25 * linear_metrics.rmse
    @test quadratic_metrics.r2 > 0.99
    @test_throws DimensionMismatch model_metrics(y, y[1:end-1])
end

@testset "L8d cross-validation contracts" begin
    rng = MersenneTwister(5800)
    X = randn(rng, 60, 6)
    y = 2.0 .+ X[:, 1] .- 0.5 .* X[:, 2] .+ randn(rng, 60)
    folds = kfold_indices(60, 6; seed = 5800)
    @test sort(vcat(folds...)) == collect(1:60)
    @test length(unique(vcat(folds...))) == 60
    @test folds == kfold_indices(60, 6; seed = 5800)
    cv = cross_validate_ridge(X, y, [0.0, 0.1, 1.0, 10.0]; k = 6, seed = 5800)
    @test cv.best_lambda in cv.lambdas
    @test size(cv.fold_rmse) == (4, 6)
    scaled = standardize_train_test(X[1:40, :], X[41:end, :])
    @test maximum(abs, mean(scaled.train; dims = 1)) < 1e-12
    @test_throws ArgumentError kfold_indices(10, 1)
end
