if !isdefined(@__MODULE__, :CHEME5800_L6B_ROOT)
    const CHEME5800_L6B_ROOT = @__DIR__
end
if !isdefined(@__MODULE__, :CHEME5800_L6B_DATA)
    const CHEME5800_L6B_DATA = joinpath(CHEME5800_L6B_ROOT, "data")
end
include(normpath(joinpath(CHEME5800_L6B_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using GLPK
using JuMP
using LinearAlgebra
using MathOptInterface
using Plots
using PrettyTables
using Test
if !isdefined(@__MODULE__, :Week06Core)
    include(normpath(joinpath(CHEME5800_L6B_ROOT, "..", "src", "Week06Core.jl")))
end
using .Week06Core
