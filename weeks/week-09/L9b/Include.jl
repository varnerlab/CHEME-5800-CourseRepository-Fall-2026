if !isdefined(@__MODULE__, :CHEME5800_L9B_ROOT)
    const CHEME5800_L9B_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L9B_ROOT, "..", "..", "..", "Include.jl")))
using CSV
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Random
using Statistics
using Test
if !isdefined(@__MODULE__, :Week09Core)
    include(normpath(joinpath(CHEME5800_L9B_ROOT, "..", "src", "Week09Core.jl")))
end
using .Week09Core
