# Local setup for CHEME 5800 L1d.

if !isdefined(@__MODULE__, :CHEME5800_L1D_ROOT)
    const CHEME5800_L1D_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L1D_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :L1dFloatingPoint)
    include(joinpath(CHEME5800_L1D_ROOT, "src", "Compute.jl"))
end

using .L1dFloatingPoint
