# Shared bootstrap for CHEME 4800/5800 Fall 2026.
#
# Weekly Include.jl files delegate here so the cloned repository and an
# extracted weekly bundle use the same root Project.toml and Manifest.toml.

import Pkg

if !isdefined(@__MODULE__, :CHEME5800_ROOT)
    const CHEME5800_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_PROJECT)
    const CHEME5800_PROJECT = joinpath(CHEME5800_ROOT, "Project.toml")
end

let active_project = Base.active_project()
    if isnothing(active_project) || normpath(active_project) != normpath(CHEME5800_PROJECT)
        Pkg.activate(CHEME5800_ROOT)
    end
end

using VLDataScienceMachineLearningPackage
