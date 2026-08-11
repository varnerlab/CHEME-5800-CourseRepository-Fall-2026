const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07"))
include(joinpath(WEEK_ROOT, "L7a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L7b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L7c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L7d", "Include.jl"))

@testset "L7a SVD contracts" begin
    A = [3.0 2.0 2.0; 2.0 3.0 -2.0]
    rank_one = truncated_svd(A, 1)
    rank_two = truncated_svd(A, 2)
    @test rank_two.approximation ≈ A
    @test rank_two.relative_error < 1e-12
    @test rank_one.relative_error > rank_two.relative_error
    @test issorted(rank_two.explained)
    @test rank_two.explained[end] ≈ 1.0
    @test_throws ArgumentError truncated_svd(A, 0)
end

@testset "L7b reduced market data" begin
    path = joinpath(WEEK_ROOT, "L7b", "data", "SP500-Reduced-LogReturns-2024.csv")
    market = load_return_matrix(path)
    @test size(market.matrix) == (181, 6)
    @test market.tickers == ["AAPL", "AMD", "JPM", "LLY", "MSFT", "XOM"]
    centered = market.matrix .- mean(market.matrix; dims = 1)
    @test maximum(abs, mean(centered; dims = 1)) < 1e-15
    @test truncated_svd(centered, 3).relative_error < truncated_svd(centered, 1).relative_error
    @test_throws ArgumentError load_return_matrix(joinpath(WEEK_ROOT, "missing.csv"))
end

@testset "L7c/L7d OLS contracts" begin
    x = collect(1.0:20.0)
    X = reshape(x, :, 1)
    y = 2.0 .+ 3.0 .* x
    fit = ols_fit(X, y)
    report = regression_report(y, fit.predictions)
    @test fit.coefficients ≈ [2.0, 3.0]
    @test report.rmse < 1e-12
    @test report.r2 ≈ 1.0
    @test norm(transpose(fit.design) * fit.residuals) < 1e-10
    @test_throws DimensionMismatch ols_fit(X, y[1:end-1])
    @test_throws DimensionMismatch regression_report(y, y[1:end-1])
end
