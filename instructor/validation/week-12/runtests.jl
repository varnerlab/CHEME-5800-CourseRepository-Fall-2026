const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-12"))
include(joinpath(WEEK_ROOT, "L12a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L12b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L12c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L12d", "Include.jl"))

@testset "L12 grid-world and value reference" begin
    world = learning_gridworld(slip = 0.1, gamma = 0.95)
    @test length(world.coordinates) == 11
    @test all(abs.(sum(world.P; dims = 3) .- 1.0) .< 1e-12)
    reference = value_iteration_reference(world)
    @test reference.converged
    @test last(reference.residuals) <= 1e-12
    @test all(reference.policy[world.terminal] .== 0)
    @test_throws ArgumentError learning_gridworld(slip = 0.5)
end

@testset "L12 Q-learning contracts" begin
    world = learning_gridworld()
    first = q_learning(world; episodes = 20_000, seed = 5800)
    second = q_learning(world; episodes = 20_000, seed = 5800)
    reference = value_iteration_reference(world)
    @test first.Q == second.Q
    @test first.policy == second.policy
    @test first.final_epsilon ≈ 0.03
    @test all(first.policy[world.terminal] .== 0)
    @test policy_agreement(reference.policy, first.policy, world.terminal) >= 0.85
    learned_return = evaluate_policy(world, first.policy; episodes = 2000, seed = 5800)
    reference_return = evaluate_policy(world, reference.policy; episodes = 2000, seed = 5800)
    @test learned_return.mean_return > 0.45
    @test abs(learned_return.mean_return - reference_return.mean_return) < 0.05
    @test_throws ArgumentError q_learning(world; episodes = 0)
end

@testset "L12 exploration comparison" begin
    world = learning_gridworld()
    reference = value_iteration_reference(world)
    exploring = q_learning(world; episodes = 12_000, epsilon_start = 1.0,
        epsilon_min = 0.03, epsilon_decay = 0.9993, seed = 5800)
    premature = q_learning(world; episodes = 12_000, epsilon_start = 0.05,
        epsilon_min = 0.0, epsilon_decay = 0.99, seed = 5800)
    @test policy_agreement(reference.policy, exploring.policy, world.terminal) >=
        policy_agreement(reference.policy, premature.policy, world.terminal)
    @test_throws DimensionMismatch policy_agreement([1], [1, 2], [false])
end
