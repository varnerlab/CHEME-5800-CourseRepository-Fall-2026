const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-08"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
released("L8c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-08", "L8c", "Include.jl"))
released("L8d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-08", "L8d", "Include.jl"))

# L8d's reference implementation; the notebook setup loads the student file.
released("L8d") && include(joinpath(WEEK_ROOT, "L8d", "src", "Compute-solution.jl"))

@meeting "L8d" begin
    include(joinpath(@__DIR__, "l8d_cross_validation.jl"))
end
