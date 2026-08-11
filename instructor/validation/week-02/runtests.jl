include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2a", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2b", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2c", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2d", "Include.jl"))

@testset "Week 2 errors and numerical contracts" begin
    @test residence_time_minutes(2.0, 250.0) == 8.0
    @test residence_time_minutes(0.5, 100) == 5.0
    @test_throws ArgumentError residence_time_minutes(0, 100)
    @test_throws ArgumentError residence_time_minutes(1, -2)
    @test_throws ArgumentError residence_time_minutes(1, Inf)
end

@testset "Week 2 collections" begin
    values = [0.71, 0.76, 0.81, 0.78]
    report = measurement_summary(values)
    @test report.count == 4
    @test report.minimum == 0.71
    @test report.maximum == 0.81
    @test report.mean ≈ 0.765
    @test values == [0.71, 0.76, 0.81, 0.78]
    @test_throws ArgumentError measurement_summary(Float64[])
    @test_throws ArgumentError measurement_summary([1.0, NaN])
    @test codepoint_hex('A') == "U+0041"
    @test codepoint_hex('Δ') == "U+0394"
    @test codepoint_hex('🍣') == "U+1F363"
end

@testset "Week 2 defensive Fibonacci" begin
    @test fibonacci_sequence(0) == [0]
    @test fibonacci_sequence(1) == [0, 1]
    @test fibonacci_sequence(10) == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
    @test last(fibonacci_sequence(92)) == 7_540_113_804_746_346_429
    @test_throws ArgumentError fibonacci_sequence(-1)
    @test_throws ArgumentError fibonacci_sequence(93)
    @test_throws ArgumentError fibonacci_sequence(3.5)
    @test_throws ArgumentError fibonacci_sequence(true)
end
