const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06"))
include(joinpath(WEEK_ROOT, "L6a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L6b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L6c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L6d", "Include.jl"))

@testset "L6a dual sensitivity" begin
    baseline = solve_resource_lp([100.0, 90.0])
    @test baseline.decisions ≈ [42.0, 16.0]
    @test baseline.objective ≈ 206.0
    @test baseline.shadow_prices ≈ [0.8, 1.4]
    @test solve_resource_lp([101.0, 90.0]).objective - baseline.objective ≈ 0.8
    @test solve_resource_lp([100.0, 91.0]).objective - baseline.objective ≈ 1.4
    @test_throws DimensionMismatch solve_resource_lp([1.0])
    @test_throws ArgumentError solve_resource_lp([-1.0, 2.0])
end

@testset "L6b urea-cycle FBA" begin
    path = joinpath(WEEK_ROOT, "L6b", "data", "Network.net")
    reactions = parse_reaction_file(path)
    form = build_stoichiometric_matrix(reactions)
    @test length(reactions) == 19
    @test size(form.S) == (18, 19)
    @test form.names[1:5] == ["v1", "v2", "v3", "v4", "v5"]
    result = solve_urea_fba(reactions)
    @test result.objective ≈ 0.0328
    @test norm(result.residual, Inf) < 1e-10
    @test all(result.lower .- 1e-10 .<= result.flux .<= result.upper .+ 1e-10)
    @test_throws ArgumentError parse_reaction_file(joinpath(WEEK_ROOT, "missing.net"))
end

@testset "L6c/L6d stationary iterations" begin
    A = [4.0 -1.0 0.0; -1.0 4.0 -1.0; 0.0 -1.0 3.0]
    b = [15.0, 10.0, 10.0]
    direct = A \ b
    results = (
        stationary_solve(A, b; method = :jacobi),
        stationary_solve(A, b; method = :gauss_seidel),
        stationary_solve(A, b; method = :sor, omega = 1.1),
    )
    @test all(result.converged for result in results)
    @test all(result.solution ≈ direct for result in results)
    @test all(last(result.residuals) <= 1e-10 for result in results)
    @test results[3].iterations < results[1].iterations
    D = Diagonal(diag(A))
    @test spectral_radius(Matrix(I, 3, 3) - D \ A) < 1
    @test_throws ArgumentError stationary_solve(A, b; method = :unknown)
    @test_throws ArgumentError stationary_solve(A, b; method = :sor, omega = 2.0)
end
