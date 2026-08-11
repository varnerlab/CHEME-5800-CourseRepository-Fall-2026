# Local setup for CHEME 5800 L5a.

if !isdefined(@__MODULE__, :CHEME5800_L5A_ROOT)
    const CHEME5800_L5A_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L5A_DATA)
    const CHEME5800_L5A_DATA = joinpath(CHEME5800_L5A_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L5A_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using Plots
using PrettyTables
using Test

if !isdefined(@__MODULE__, :L5aFlowValidation)
    include(joinpath(CHEME5800_L5A_ROOT, "src", "FlowValidation.jl"))
end

using .L5aFlowValidation
