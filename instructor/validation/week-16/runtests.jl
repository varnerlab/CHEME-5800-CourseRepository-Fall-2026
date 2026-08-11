const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-16"))
include(joinpath(WEEK_ROOT, "L16a", "Include.jl"))

@testset "L16 course and bridge maps" begin
    methods = course_method_map()
    bridges = bridge_map()
    @test length(methods) == 8
    @test first(methods).weeks == "1–3"
    @test last(methods).weeks == "15"
    @test length(unique(item.family for item in methods)) == length(methods)
    @test length(bridges) == 5
    @test any(occursin("Q-learning", item.fall) for item in bridges)
    @test any(occursin("state-space", item.spring) for item in bridges)
end

@testset "L16 computational contract" begin
    complete = (
        question = "Which policy maximizes expected return?",
        representation = "finite MDP",
        method = "value iteration",
        evidence = "Bellman residual and rollout evaluation",
        limitations = "transition model assumed known",
    )
    @test validate_computational_contract(complete).complete

    incomplete = (
        question = "Which policy is best?",
        representation = "grid world",
        method = "Q-learning",
        evidence = "",
        limitations = "",
    )
    result = validate_computational_contract(incomplete)
    @test !result.complete
    @test result.missing == ["evidence", "limitations"]
end
