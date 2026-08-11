# Local setup for CHEME 5800 L5d.

if !isdefined(@__MODULE__, :CHEME5800_L5D_ROOT)
    const CHEME5800_L5D_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L5D_DATA)
    const CHEME5800_L5D_DATA = joinpath(CHEME5800_L5D_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L5D_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using GLPK
using JuMP
using MathOptInterface
using Plots
using PrettyTables
using Test

if !isdefined(@__MODULE__, :L5dMinCostFlow)
    include(joinpath(CHEME5800_L5D_ROOT, "src", "MinCostFlow.jl"))
end

using .L5dMinCostFlow
