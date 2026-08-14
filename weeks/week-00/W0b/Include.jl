# Local setup for the optional CHEME 5800 Week 0 engineering bridge.

if !isdefined(@__MODULE__, :CHEME5800_W0B_ROOT)
    const CHEME5800_W0B_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_W0B_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :Week00Bridge)
    include(joinpath(CHEME5800_W0B_ROOT, "src", "Compute.jl"))
end

using .Week00Bridge
