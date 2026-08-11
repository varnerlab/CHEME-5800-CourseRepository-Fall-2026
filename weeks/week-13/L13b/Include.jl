if !isdefined(@__MODULE__, :CHEME5800_L13B_ROOT)
    const CHEME5800_L13B_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L13B_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using JSON
using PrettyTables
using Test
if !isdefined(@__MODULE__, :Week13Client)
    include(normpath(joinpath(CHEME5800_L13B_ROOT, "..", "src", "Week13Client.jl")))
end
using .Week13Client
