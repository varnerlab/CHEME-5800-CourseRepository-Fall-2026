const WEEK01 = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-01"))

include(joinpath(WEEK01, "L1c", "Include.jl"))

# L1d ships with an unimplemented student stub, so validation uses the reference
# solution. L1b is a notebook-only guided lab and has no hidden implementation.
include(joinpath(WEEK01, "L1d", "src", "Compute-solution.jl"))
using .L1dFloatingPoint
using Random, Test

@testset "Week 1 primitive and collection representations" begin
    example_tuple = (18, 36.6)
    @test example_tuple isa Tuple{Int64,Float64}
    @test_throws MethodError setindex!(example_tuple, 6, 1)

    values = rand(10)
    values[3] = π
    @test values isa Vector{Float64}
    @test values[3] == Float64(π)

    lines = Dict(1 => "first", 2 => "second")
    flags = Set([:calibrated, :finite, :finite])
    @test lines[2] == "second"
    @test length(flags) == 2
end

@testset "Week 1 instructional boundary" begin
    l1a = read(
        joinpath(WEEK01, "L1a", "CHEME-5800-L1a-Lecture-WorkingWithTypes-Fall-2026.ipynb"),
        String,
    )
    l1b = read(
        joinpath(WEEK01, "L1b", "CHEME-5800-L1b-Lab-ChoosingDataRepresentations-Fall-2026.ipynb"),
        String,
    )
    @test occursin("Values and Primitive Data Types", l1a)
    @test !occursin("Collection Types", l1a)
    @test occursin("Choosing and Building Data Representations", l1b)
    @test occursin("Task 1: Tuples as fixed records", l1b)
    @test occursin("Task 3: Sets and dictionaries for membership and lookup", l1b)
    @test !occursin("Toolchain and Notebook Smoke Test", l1b)
    @test !occursin("ideal_gas_pressure", l1b)
end

@testset "Week 1 floating-point report" begin
    report = float64_report(-0.1)
    @test report.sign_bit == '1'
    @test length(report.exponent_bits) == 11
    @test length(report.fraction_bits) == 52
    @test report.spacing > 0
    for value in (1.0, -1.0, 0.1, -0.1, 3.1415926535897, -65.78912, 1234.5)
        @test float64_report(value).reconstructed == value
    end
    @test float64_report(1.0e12).spacing > float64_report(1.0).spacing
    @test 0.1 + 0.2 != 0.3
    @test isapprox(0.1 + 0.2, 0.3)
end

@testset "Week 1 lab ships an unimplemented stub" begin
    stub = read(joinpath(WEEK01, "L1d", "src", "Compute.jl"), String)
    @test occursin("TODO 1", stub)
    @test occursin("Oooops!", stub)
    @test occursin("implemented yet", stub)
    @test !occursin("bits[13:64]", stub)
end
