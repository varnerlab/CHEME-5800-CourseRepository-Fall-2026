const WEEK00 = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-00"))

include(joinpath(WEEK00, "W0a", "Include.jl"))
include(joinpath(WEEK00, "W0b", "src", "Compute-solution.jl"))

using .Week00Toolchain
using .Week00Bridge
using Random, Statistics, Test

@testset "Week 0 required system check" begin
    @test printgreeting() == "Hello World!"
    samples = randn(10_000)
    @test samples isa Vector{Float64}
    @test length(samples) == 10_000
    @test all(isfinite, samples)
    @test abs(mean(samples)) < 0.1
    @test abs(std(samples) - 1.0) < 0.1
end

@testset "Week 0 optional engineering bridge" begin
    pressure = ideal_gas_pressure(1.0, 273.15, 0.02241396954)
    @test isapprox(pressure, 101_325.0; rtol = 1e-8)
    @test ideal_gas_pressure(2, 300, 0.05) isa Float64
    @test_throws ArgumentError ideal_gas_pressure(0, 300, 0.05)
    @test_throws ArgumentError ideal_gas_pressure(1, -10, 0.05)
    @test_throws ArgumentError ideal_gas_pressure(1, 300, Inf)
    @test_throws ArgumentError ideal_gas_pressure(1, 300, 0.05; gas_constant = -1)
end

@testset "Week 0 content boundary" begin
    required_notebook = read(
        joinpath(WEEK00, "W0a", "CHEME-5800-W0a-Onboarding-SystemCheck-Fall-2026.ipynb"),
        String,
    )
    optional_notebook = read(
        joinpath(WEEK00, "W0b", "CHEME-5800-W0b-Optional-FirstTestedCalculation-Fall-2026.ipynb"),
        String,
    )
    @test occursin("Course Setup and System Check", required_notebook)
    @test !occursin("ideal_gas_pressure", required_notebook)
    @test occursin("Optional Bridge", optional_notebook)

    stub = read(joinpath(WEEK00, "W0b", "src", "Compute.jl"), String)
    @test occursin("TODO 1", stub)
    @test occursin("Oooops!", stub)
    @test occursin("implemented yet", stub)
    @test !occursin("amount_mol * gas_constant", stub)
end
