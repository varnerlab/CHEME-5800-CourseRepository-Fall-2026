const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-11"))
include(joinpath(WEEK_ROOT, "L11a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L11b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L11c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L11d", "Include.jl"))

@testset "L11 Markov contracts" begin
    P = [0.8 0.15 0.05; 0.2 0.6 0.2; 0.1 0.25 0.65]
    @test validate_transition_matrix(P)
    history = evolve_markov(P, [1.0, 0.0, 0.0], 30)
    @test size(history) == (3, 31)
    @test all(abs.(sum(history; dims = 1) .- 1.0) .< 1e-12)
    labels = ["a", "b", "c"]
    first_sequence = generate_markov_sequence(labels, P, 1, 20; seed = 5800)
    @test first_sequence == generate_markov_sequence(labels, P, 1, 20; seed = 5800)
    @test length(first_sequence) == 20
    @test_throws ArgumentError validate_transition_matrix([0.8 0.3; 0.2 0.8])
    @test_throws DimensionMismatch evolve_markov(P, [1.0, 0.0], 2)
end

@testset "L11 grid-world value iteration" begin
    world = classic_gridworld(slip = 0.1, gamma = 0.95)
    @test length(world.coordinates) == 11
    @test all(abs.(sum(world.P; dims = 3) .- 1.0) .< 1e-12)
    solution = value_iteration(world.P, world.rewards, world.gamma; terminal = world.terminal)
    @test solution.converged
    @test last(solution.residuals) <= 1e-10
    @test solution.values[world.index[(1, 4)]] == 1.0
    @test solution.values[world.index[(2, 4)]] == -1.0
    @test all(action -> action in 1:4, solution.policy[.!world.terminal])
    @test_throws ArgumentError classic_gridworld(slip = 0.5)
end
