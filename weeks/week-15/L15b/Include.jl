if !isdefined(@__MODULE__, :CHEME5800_L15B_ROOT)
    const CHEME5800_L15B_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L15B_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using LinearAlgebra
using OrdinaryDiffEq
using Plots
using PrettyTables
using Statistics
using Test
if !isdefined(@__MODULE__, :Week15Core)
    include(normpath(joinpath(CHEME5800_L15B_ROOT, "..", "src", "Week15Core.jl")))
end
using .Week15Core
