include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-01", "L1b", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-01", "L1c", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-01", "L1d", "Include.jl"))

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

@testset "Week 1 floating-point inspection" begin
    report = float64_report(-0.1)
    @test report.sign_bit == '1'
    @test length(report.exponent_bits) == 11
    @test length(report.fraction_bits) == 52
    @test report.spacing > 0
    @test 0.1 + 0.2 != 0.3
    @test isapprox(0.1 + 0.2, 0.3)
end

