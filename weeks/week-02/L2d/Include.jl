# Local setup for CHEME 5800 L2d.

if !isdefined(@__MODULE__, :CHEME5800_L2D_ROOT)
    const CHEME5800_L2D_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L2D_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :L2dFibonacci)
    include(joinpath(CHEME5800_L2D_ROOT, "src", "Compute.jl"))
end

using .L2dFibonacci

