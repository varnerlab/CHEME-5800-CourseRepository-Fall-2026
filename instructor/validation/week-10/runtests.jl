const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-10"))
include(joinpath(WEEK_ROOT, "L10a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L10b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L10c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L10d", "Include.jl"))

@testset "L10 multiplicative weights" begin
    losses = [0.1 0.8; 0.2 0.7; 0.9 0.1; 0.8 0.2]
    result = weighted_majority(losses; eta = 0.5)
    @test size(result.probabilities) == size(losses)
    @test all(abs.(sum(result.probabilities; dims = 2) .- 1.0) .< 1e-12)
    @test result.expert_totals ≈ vec(sum(losses; dims = 1))
    @test result.regret == result.learner_total - minimum(result.expert_totals)
    @test_throws ArgumentError weighted_majority(losses; eta = 0.0)
    @test_throws ArgumentError weighted_majority([1.2 0.0])
end

@testset "L10 ordinary bandits" begin
    probabilities = [0.30, 0.45, 0.55, 0.70]
    ucb = run_bandit(probabilities, 2000; algorithm = :ucb1, seed = 5800)
    thompson = run_bandit(probabilities, 2000; algorithm = :thompson, seed = 5800)
    @test sum(ucb.counts) == 2000
    @test sum(thompson.counts) == 2000
    @test argmax(ucb.counts) == 4
    @test argmax(thompson.counts) == 4
    @test ucb == run_bandit(probabilities, 2000; algorithm = :ucb1, seed = 5800)
    @test thompson == run_bandit(probabilities, 2000; algorithm = :thompson, seed = 5800)
    @test ucb.expected_regret >= 0
    @test thompson.expected_regret >= 0
    @test_throws ArgumentError run_bandit([0.2, 1.2], 100)
    @test_throws ArgumentError run_bandit(probabilities, 100; algorithm = :unknown)
end
