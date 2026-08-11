# Local setup for CHEME 5800 L1a.

if !isdefined(@__MODULE__, :CHEME5800_L1A_ROOT)
    const CHEME5800_L1A_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L1A_ROOT, "..", "..", "..", "Include.jl")))

using Random

