if !isdefined(@__MODULE__, :CHEME5800_L11D_ROOT)
    const CHEME5800_L11D_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L11D_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using LinearAlgebra
using Plots
using PrettyTables
using Random
using Statistics
using Test
if !isdefined(@__MODULE__, :Week11Core)
    include(normpath(joinpath(CHEME5800_L11D_ROOT, "..", "src", "Week11Core.jl")))
end
using .Week11Core
