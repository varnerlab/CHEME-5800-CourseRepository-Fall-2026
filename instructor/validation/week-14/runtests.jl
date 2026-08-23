using LinearAlgebra
using Test

const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14"))
include(joinpath(WEEK_ROOT, "L14a", "Include.jl"))

@testset "L14 power iteration" begin
    A = [4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0]
    result = power_iteration(A, ones(3); tolerance = 1e-11)
    reference = eigen(Symmetric(A))

    @test result.converged
    @test result.iterations < 100
    @test result.residual_norm <= 1e-11
    @test isapprox(result.value, maximum(reference.values); atol = 1e-10)
    @test isapprox(norm(result.vector), 1.0; atol = 1e-12)
    @test isapprox(
        eigenpair_residual(A, result.value, result.vector),
        result.residual_norm;
        atol = 1e-14,
    )
end

@testset "L14 convergence and validation" begin
    fast = power_iteration(Diagonal([5.0, 1.0, 0.5]), ones(3); tolerance = 1e-9)
    slow = power_iteration(Diagonal([5.0, 4.9, 0.5]), ones(3); tolerance = 1e-9)
    @test fast.converged
    @test slow.converged
    @test fast.iterations < slow.iterations

    @test_throws ArgumentError power_iteration(ones(2, 3), ones(3))
    @test_throws DimensionMismatch power_iteration(Matrix{Float64}(I, 2, 2), ones(3))
    @test_throws ArgumentError power_iteration(Matrix{Float64}(I, 2, 2), zeros(2))
    @test_throws ArgumentError power_iteration(Matrix{Float64}(I, 2, 2), ones(2); tolerance = 0.0)
    @test_throws ArgumentError power_iteration(Matrix{Float64}(I, 2, 2), ones(2); max_iterations = 0)
end

@testset "L14 long-run behavior and stability" begin
    transition = [0.85 0.25; 0.15 0.75]
    stationary = power_iteration(transition, [0.5, 0.5]; tolerance = 1e-12)
    probability = stationary.vector ./ sum(stationary.vector)

    @test stationary.converged
    @test isapprox(stationary.value, 1.0; atol = 1e-11)
    @test isapprox(transition * probability, probability; atol = 1e-11)
    @test isapprox(sum(probability), 1.0; atol = 1e-12)

    @test explicit_euler_stable(-2.0, 0.25)
    @test explicit_euler_stable(-2.0, 1.0)
    @test !explicit_euler_stable(-2.0, 1.1)
    @test_throws ArgumentError explicit_euler_stable(-2.0, 0.0)
end
