# Local setup for CHEME 5800 L4a.

if !isdefined(@__MODULE__, :CHEME5800_L4A_ROOT)
    const CHEME5800_L4A_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L4A_DATA)
    const CHEME5800_L4A_DATA = joinpath(CHEME5800_L4A_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L4A_ROOT, "..", "..", "..", "Include.jl")))

using Test

if !isdefined(@__MODULE__, :L4aRepresentation)
    include(joinpath(CHEME5800_L4A_ROOT, "src", "Representation.jl"))
end

using .L4aRepresentation

