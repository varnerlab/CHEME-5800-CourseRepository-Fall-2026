if !isdefined(@__MODULE__, :CHEME5800_L7A_ROOT)
    const CHEME5800_L7A_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L7A_ROOT, "..", "..", "..", "Include.jl")))
using CSV
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Statistics
using Test
if !isdefined(@__MODULE__, :Week07Core)
    include(normpath(joinpath(CHEME5800_L7A_ROOT, "..", "src", "Week07Core.jl")))
end
using .Week07Core
