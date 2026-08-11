# Local setup for CHEME 5800 L2b.

if !isdefined(@__MODULE__, :CHEME5800_L2B_ROOT)
    const CHEME5800_L2B_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L2B_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :L2bDebugging)
    include(joinpath(CHEME5800_L2B_ROOT, "src", "Compute.jl"))
end

using .L2bDebugging

