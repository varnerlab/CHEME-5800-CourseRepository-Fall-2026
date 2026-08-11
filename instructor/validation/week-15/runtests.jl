const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-15"))
include(joinpath(WEEK_ROOT, "L15a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L15b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L15c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L15d", "Include.jl"))

@testset "L15 explicit Euler and stability" begin
    coarse = explicit_euler(decay_rhs, [1.0], (0.0, 2.0), 0.1; p = 1.0)
    fine = explicit_euler(decay_rhs, [1.0], (0.0, 2.0), 0.01; p = 1.0)
    exact = exp(-2.0)
    @test abs(fine.u[end, 1] - exact) < abs(coarse.u[end, 1] - exact)
    @test abs(fine.u[end, 1] - exact) < 0.002
    @test abs(euler_stability_factor(-1.0, 1.0)) < 1
    @test abs(euler_stability_factor(-1.0, 3.0)) > 1
    @test_throws ArgumentError explicit_euler(decay_rhs, [1.0], (0.0, 1.0), 0.3; p = 1.0)
end

@testset "L15 build versus buy" begin
    built = explicit_euler(decay_rhs, [1.0], (0.0, 2.0), 0.01; p = 1.0)
    bought = library_integrate(decay_rhs, [1.0], (0.0, 2.0); p = 1.0, saveat = 0.01)
    @test length(built.t) == length(bought.t)
    @test abs(bought.u[end, 1] - exp(-2.0)) < 1e-8
    @test maximum(abs.(built.u[:, 1] .- bought.u[:, 1])) < 0.003
end

@testset "L15 three-gene and state-space bridge" begin
    parameters = three_gene_parameters()
    simulation = library_integrate(
        three_gene_rhs,
        zeros(3),
        (0.0, 20.0);
        p = parameters,
        saveat = 0.5,
    )
    @test all(isfinite, simulation.u)
    @test all(simulation.u .>= 0)
    @test simulation.u[end, 1] > 0
    @test_throws DimensionMismatch three_gene_rhs(zeros(2), 0.0, parameters)

    A = [-0.4 1.0; -1.0 -0.4]
    Ad = linear_discretization(A, 0.05)
    @test maximum(abs.(eigvals(Ad))) < 1
    trajectory = linear_rollout(Ad, [1.0, 0.0], 100)
    @test size(trajectory) == (101, 2)
    @test norm(trajectory[end, :]) < norm(trajectory[1, :])
    @test_throws DimensionMismatch linear_discretization(zeros(2, 3), 0.1)
end

@testset "L15 mixed-sugar fermentation" begin
    parameters = fermentation_parameters()
    initial = [0.5, 2.5, 0.90 * parameters.maximum_enzyme[1],
        0.18 * parameters.maximum_enzyme[2], 4e-3]
    simulation = library_integrate(
        fermentation_rhs,
        initial,
        (0.0, 10.0);
        p = parameters,
        saveat = 0.1,
    )
    @test size(simulation.u) == (101, 5)
    @test all(isfinite, simulation.u)
    @test minimum(simulation.u) >= -1e-10
    @test simulation.u[end, 1] < initial[1]
    @test simulation.u[end, 2] < initial[2]
    @test simulation.u[end, 5] > initial[5]
    @test_throws DimensionMismatch fermentation_rhs(zeros(4), 0.0, parameters)
end
