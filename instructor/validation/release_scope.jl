# Gate a week's validation by the class meetings included in a release.
#
# The release workflow sets RELEASE_MEETINGS to the space-separated meeting
# folders in the bundle (for example "L6a L6b"). When the variable is unset or
# empty, as in a local run, every meeting is treated as released.
#
#     include(joinpath(@__DIR__, "..", "release_scope.jl"))
#     released("L6a") && include(joinpath(WEEK_ROOT, "L6a", "Include.jl"))
#     @meeting "L6a" begin
#         @testset "L6a ..." begin ... end
#     end
#
# `@meeting` accepts several folders and runs the block only when all of them
# are released; otherwise it prints one skip line.

const RELEASE_MEETINGS = let raw = strip(get(ENV, "RELEASE_MEETINGS", ""))
    isempty(raw) ? nothing : Set(String.(split(raw)))
end

released(meetings::AbstractString...) =
    RELEASE_MEETINGS === nothing || all(meeting -> meeting in RELEASE_MEETINGS, meetings)

macro meeting(args...)
    length(args) >= 2 || error("@meeting needs at least one meeting name and a block")
    meetings = args[1:end-1]
    block = args[end]
    quote
        if released($(meetings...))
            $(esc(block))
        else
            println("skipping ", join(($(meetings...),), ", "), ": not in this release")
        end
    end
end
