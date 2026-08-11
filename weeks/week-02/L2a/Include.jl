# Local setup for CHEME 5800 L2a.

if !isdefined(@__MODULE__, :CHEME5800_L2A_ROOT)
    const CHEME5800_L2A_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L2A_ROOT, "..", "..", "..", "Include.jl")))

using Test

