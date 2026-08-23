const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-08"))
include(joinpath(WEEK_ROOT, "L8c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L8d", "Include.jl"))

@testset "L8c ridge contracts" begin
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

@testset "L8d cross-validation and residual-guided revision" begin
    rng = MersenneTwister(5800)
    n, p = 180, 8
    X = randn(rng, n, p)
    quadratic_feature = X[:, 4].^2
    y = 4.0 .+ 2.0 .* X[:, 1] .- 1.5 .* X[:, 2] .+ 0.8 .* X[:, 3] .+
        2.0 .* (quadratic_feature .- mean(quadratic_feature)) .+ 0.45 .* randn(rng, n)
    lambdas = vcat(0.0, 10.0 .^ range(-4, 3; length = 15))
    baseline_cv = cross_validate_ridge(X, y, lambdas; k = 6, seed = 5800)
    augmented_cv = cross_validate_ridge(hcat(X, quadratic_feature), y, lambdas; k = 6, seed = 5800)
    folds = baseline_cv.folds
    @test sort(vcat(folds...)) == collect(1:n)
    @test length(unique(vcat(folds...))) == n
    @test folds == kfold_indices(n, 6; seed = 5800)
    @test baseline_cv.best_lambda in baseline_cv.lambdas
    @test size(baseline_cv.fold_rmse) == (length(lambdas), 6)
    @test minimum(augmented_cv.mean_rmse) < 0.5 * minimum(baseline_cv.mean_rmse)
    scaled = standardize_train_test(X[1:120, :], X[121:end, :])
    @test maximum(abs, mean(scaled.train; dims = 1)) < 1e-12
    @test_throws DimensionMismatch model_metrics(y, y[1:end-1])
    @test_throws ArgumentError kfold_indices(10, 1)
end
