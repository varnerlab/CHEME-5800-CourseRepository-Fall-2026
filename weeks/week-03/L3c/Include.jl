# Local setup for CHEME 5800 L3c.

if !isdefined(@__MODULE__, :CHEME5800_L3C_ROOT)
    const CHEME5800_L3C_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L3C_ROOT, "..", "..", "..", "Include.jl")))

using BenchmarkTools
using Test

if !isdefined(@__MODULE__, :L3cRecursion)
    include(joinpath(CHEME5800_L3C_ROOT, "src", "Compute.jl"))
end

using .L3cRecursion
