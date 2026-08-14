# Local setup for CHEME 5800 L1b.

if !isdefined(@__MODULE__, :CHEME5800_L1B_ROOT)
    const CHEME5800_L1B_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L1B_ROOT, "..", "..", "..", "Include.jl")))

using Random
using Test
