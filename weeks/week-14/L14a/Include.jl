if !isdefined(@__MODULE__, :CHEME5800_L14A_ROOT)
    const CHEME5800_L14A_ROOT = @__DIR__
end
include(normpath(joinpath(CHEME5800_L14A_ROOT, "..", "..", "..", "Include.jl")))
using DataFrames
using PrettyTables
using SHA
using Test
if !isdefined(@__MODULE__, :Week14Core)
    include(normpath(joinpath(CHEME5800_L14A_ROOT, "..", "src", "Week14Core.jl")))
end
using .Week14Core
