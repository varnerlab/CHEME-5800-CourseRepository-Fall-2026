# Local setup for CHEME 5800 L4b.

if !isdefined(@__MODULE__, :CHEME5800_L4B_ROOT)
    const CHEME5800_L4B_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L4B_DATA)
    const CHEME5800_L4B_DATA = joinpath(CHEME5800_L4B_ROOT, "data")
end

include(normpath(joinpath(CHEME5800_L4B_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using PrettyTables
using Test

if !isdefined(@__MODULE__, :L4bTraversal)
    include(joinpath(CHEME5800_L4B_ROOT, "src", "Traversal.jl"))
end

using .L4bTraversal

