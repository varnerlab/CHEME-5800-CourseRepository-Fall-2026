if !isdefined(@__MODULE__, :CHEME5800_L12C_ROOT)
    const CHEME5800_L12C_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L12C_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Random
using Statistics
using Test
if !isdefined(@__MODULE__, :Week12Core)
    include(normpath(joinpath(CHEME5800_L12C_ROOT, "..", "src", "Week12Core.jl")))
end
using .Week12Core
