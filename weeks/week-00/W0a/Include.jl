# Local setup for the CHEME 5800 Week 0 system check.

if !isdefined(@__MODULE__, :CHEME5800_W0A_ROOT)
    const CHEME5800_W0A_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_W0A_ROOT, "..", "..", "..", "Include.jl")))

using Random
using Statistics
using Test
using UnicodePlots

if !isdefined(@__MODULE__, :Week00Toolchain)
    include(joinpath(CHEME5800_W0A_ROOT, "src", "HelloWorld.jl"))
end

using .Week00Toolchain
