# Local setup for CHEME 5800 L1b.

if !isdefined(@__MODULE__, :CHEME5800_L1B_ROOT)
    const CHEME5800_L1B_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L1B_ROOT, "..", "..", "..", "Include.jl")))

using Random
using Statistics
using Test
using UnicodePlots

if !isdefined(@__MODULE__, :L1bToolchain)
    include(joinpath(CHEME5800_L1B_ROOT, "src", "HelloWorld.jl"))
end
if !isdefined(@__MODULE__, :L1bCalculation)
    include(joinpath(CHEME5800_L1B_ROOT, "src", "Compute.jl"))
end

using .L1bToolchain
using .L1bCalculation
