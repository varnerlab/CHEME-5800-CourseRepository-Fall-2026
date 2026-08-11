if !isdefined(@__MODULE__, :CHEME5800_L16A_ROOT)
    const CHEME5800_L16A_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L16A_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using PrettyTables
using Test
if !isdefined(@__MODULE__, :Week16Core)
    include(normpath(joinpath(CHEME5800_L16A_ROOT, "..", "src", "Week16Core.jl")))
end
using .Week16Core
