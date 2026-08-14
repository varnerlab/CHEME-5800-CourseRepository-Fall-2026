const WEEK01 = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-01"))

include(joinpath(WEEK01, "L1c", "Include.jl"))

# L1b and L1d ship deliberately unimplemented stubs that students complete in class,
# so validation runs against the reference solutions rather than the student-facing
# files. We do not load their Include.jl, because the stubs define the same modules.
include(joinpath(WEEK01, "L1b", "src", "HelloWorld.jl"))
include(joinpath(WEEK01, "L1b", "src", "Compute-solution.jl"))
include(joinpath(WEEK01, "L1d", "src", "Compute-solution.jl"))
using .L1bToolchain
using .L1bCalculation
using .L1dFloatingPoint
using Random, Statistics

@testset "Week 1 toolchain" begin
    @test printgreeting() == "Hello World!"
    samples = randn(10_000)
    @test length(samples) == 10_000
    @test abs(mean(samples)) < 0.1
    @test abs(std(samples) - 1.0) < 0.1
end

@testset "Week 1 engineering calculation" begin
    pressure = ideal_gas_pressure(1.0, 273.15, 0.02241396954)
    @test isapprox(pressure, 101_325.0; rtol = 1e-8)
    @test ideal_gas_pressure(2, 300, 0.05) isa Float64
    @test_throws ArgumentError ideal_gas_pressure(0, 300, 0.05)
    @test_throws ArgumentError ideal_gas_pressure(1, -1, 0.05)
    @test_throws ArgumentError ideal_gas_pressure(1, 300, Inf)
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

@testset "Week 1 labs ship unimplemented stubs" begin
    # Guards against a reference solution being copied into the student tree.
    # Each marker must appear in the solution but NOT in the stub's hint comments.
    for (lab, leaked) in (("L1b", "amount_mol * gas_constant"), ("L1d", "bits[13:64]"))
        stub = read(joinpath(WEEK01, lab, "src", "Compute.jl"), String)
        @test occursin("TODO 1", stub)
        @test occursin("Oooops!", stub)
        @test occursin("implemented yet", stub)
        @test !occursin(leaked, stub)
    end
end
