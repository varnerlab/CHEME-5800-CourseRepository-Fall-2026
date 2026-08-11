if !isdefined(@__MODULE__, :CHEME5800_L7B_ROOT)
    const CHEME5800_L7B_ROOT = @__DIR__
end
if !isdefined(@__MODULE__, :CHEME5800_L7B_DATA)
    const CHEME5800_L7B_DATA = joinpath(CHEME5800_L7B_ROOT, "data")
end
include(normpath(joinpath(CHEME5800_L7B_ROOT, "..", "..", "..", "Include.jl")))
using CSV
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Statistics
using Test
if !isdefined(@__MODULE__, :Week07Core)
    include(normpath(joinpath(CHEME5800_L7B_ROOT, "..", "src", "Week07Core.jl")))
end
using .Week07Core
