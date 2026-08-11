if !isdefined(@__MODULE__, :CHEME5800_L10C_ROOT)
    const CHEME5800_L10C_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L10C_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using Distributions
using Plots
using PrettyTables
using Random
using Statistics
using Test
if !isdefined(@__MODULE__, :Week10Core)
    include(normpath(joinpath(CHEME5800_L10C_ROOT, "..", "src", "Week10Core.jl")))
end
using .Week10Core
