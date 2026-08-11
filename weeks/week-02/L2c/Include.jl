# Local setup for CHEME 5800 L2c.

if !isdefined(@__MODULE__, :CHEME5800_L2C_ROOT)
    const CHEME5800_L2C_ROOT = @__DIR__
end

include(normpath(joinpath(CHEME5800_L2C_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using PrettyTables
using Statistics
using Test
using Unicode

if !isdefined(@__MODULE__, :L2cCollections)
    include(joinpath(CHEME5800_L2C_ROOT, "src", "Compute.jl"))
end

using .L2cCollections

