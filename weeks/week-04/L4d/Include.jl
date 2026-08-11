# Local setup for CHEME 5800 L4d.

if !isdefined(@__MODULE__, :CHEME5800_L4D_ROOT)
    const CHEME5800_L4D_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L4D_DATA)
    const CHEME5800_L4D_DATA = joinpath(CHEME5800_L4D_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L4D_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using Plots
using PrettyTables
using Test
