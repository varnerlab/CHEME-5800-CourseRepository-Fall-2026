if !isdefined(@__MODULE__, :CHEME5800_L8A_ROOT)
    const CHEME5800_L8A_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L8A_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Random
using Statistics
using Test
if !isdefined(@__MODULE__, :Week08Core)
    include(normpath(joinpath(CHEME5800_L8A_ROOT, "..", "src", "Week08Core.jl")))
end
using .Week08Core
