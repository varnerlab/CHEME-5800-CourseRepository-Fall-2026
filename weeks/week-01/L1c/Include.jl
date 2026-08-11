# Local setup for CHEME 5800 L1c.

if !isdefined(@__MODULE__, :CHEME5800_L1C_ROOT)
    const CHEME5800_L1C_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L1C_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :L1cCalculation)
    include(joinpath(CHEME5800_L1C_ROOT, "src", "Compute.jl"))
end

using .L1cCalculation

