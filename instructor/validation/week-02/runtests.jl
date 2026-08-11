include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2a", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2c", "Include.jl"))

# L2b and L2d ship deliberately unimplemented stubs that students complete in class,
# so validation runs against the reference solutions rather than the student-facing
# files. We do not load their Include.jl, because the stubs define the same modules.
const WEEK02 = joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02")
include(joinpath(WEEK02, "L2b", "src", "Compute-solution.jl"))
include(joinpath(WEEK02, "L2d", "src", "Compute-solution.jl"))
using .L2bDebugging
using .L2dFibonacci

@testset "Week 2 errors and numerical contracts" begin
    @test cargo_loading_time_minutes(2.0, 250.0) == 8.0
    @test cargo_loading_time_minutes(0.5, 100) == 5.0
    @test_throws ArgumentError cargo_loading_time_minutes(0, 100)
    @test_throws ArgumentError cargo_loading_time_minutes(1, -2)
    @test_throws ArgumentError cargo_loading_time_minutes(1, Inf)
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

@testset "Week 2 labs ship unimplemented stubs" begin
    # Guards against a reference solution being copied into the student tree.
    # Each marker must appear in the solution but NOT in the stub's hint comments.
    for (lab, leaked) in (("L2b", "1000.0 * cargo_tonnes"), ("L2d", "sequence[index - 1]"))
        stub = read(joinpath(WEEK02, lab, "src", "Compute.jl"), String)
        @test occursin("TODO 1", stub)
        @test occursin("Oooops!", stub)
        @test occursin("implemented yet", stub)
        @test !occursin(leaked, stub)
    end
end
