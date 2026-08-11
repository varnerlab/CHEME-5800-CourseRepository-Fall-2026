if !isdefined(@__MODULE__, :CHEME5800_L6C_ROOT)
    const CHEME5800_L6C_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L6C_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Test
if !isdefined(@__MODULE__, :Week06Core)
    include(normpath(joinpath(CHEME5800_L6C_ROOT, "..", "src", "Week06Core.jl")))
end
using .Week06Core
