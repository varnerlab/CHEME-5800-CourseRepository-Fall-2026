# Local setup for CHEME 5800 L3d.

if !isdefined(@__MODULE__, :CHEME5800_L3D_ROOT)
    const CHEME5800_L3D_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L3D_ROOT, "..", "..", "..", "Include.jl")))

using BenchmarkTools
using DataFrames
using Plots
using Random
using Statistics
using Test

if !isdefined(@__MODULE__, :L3dSorting)
    include(joinpath(CHEME5800_L3D_ROOT, "src", "Compute.jl"))
end

using .L3dSorting
