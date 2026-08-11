# Local setup for CHEME 5800 L3b.

if !isdefined(@__MODULE__, :CHEME5800_L3B_ROOT)
    const CHEME5800_L3B_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L3B_ROOT, "..", "..", "..", "Include.jl")))

using CSV
using DataFrames
using JSON
using SHA
using Test

if !isdefined(@__MODULE__, :L3bData)
    include(joinpath(CHEME5800_L3B_ROOT, "src", "Data.jl"))
end

using .L3bData
