# Local setup for CHEME 5800 L5b.

if !isdefined(@__MODULE__, :CHEME5800_L5B_ROOT)
    const CHEME5800_L5B_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L5B_DATA)
    const CHEME5800_L5B_DATA = joinpath(CHEME5800_L5B_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L5B_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using Plots
using PrettyTables
using Test

if !isdefined(@__MODULE__, :L5bFlowValidation)
    include(joinpath(CHEME5800_L5B_ROOT, "src", "FlowValidation.jl"))
end

using .L5bFlowValidation
