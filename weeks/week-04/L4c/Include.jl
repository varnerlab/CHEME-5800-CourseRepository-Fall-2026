# Local setup for CHEME 5800 L4c.

if !isdefined(@__MODULE__, :CHEME5800_L4C_ROOT)
    const CHEME5800_L4C_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L4C_ROOT, "..", "..", "..", "Include.jl")))

using DataStructures
using Test

if !isdefined(@__MODULE__, :L4cShortestPaths)
    include(joinpath(CHEME5800_L4C_ROOT, "src", "ShortestPaths.jl"))
end

using .L4cShortestPaths

