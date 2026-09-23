# =============================================================================
# CHEME 5800 | L6a local setup
# =============================================================================
# Every class-meeting folder carries one of these, and running it from the first
# cell of the notebook is the only setup a student performs.
#
# The file is in four sections, in this order:
#
#   1. PATHS   locate this folder, so nothing depends on the working directory
#   2. CODE    load the root bootstrap
#   3. IMPORTS every `using` for this meeting, in one block
#   4. SOURCE  this meeting's own code in src/, which needs the imports first
#
# Section 3 is deliberately the only place a `using` appears. To see what a
# notebook can call, read that block and nothing else.
#
# The root bootstrap in section 2 activates the single pinned course environment
# (root Project.toml and Manifest.toml). That is why no weekly folder carries a
# Project.toml of its own: a cloned repository and an extracted weekly bundle
# resolve to the same package versions the material was written against.
# =============================================================================


# --- 1. PATHS ----------------------------------------------------------------
# `@__DIR__` is the folder holding *this* file, not `pwd()`, so the joins below
# hold whether the notebook was launched from here or from the repository root.
# The guard makes re-running the setup cell harmless, which matters because a
# `const` may not be rebound once it is set.
if !isdefined(@__MODULE__, :CHEME5800_L6A_ROOT)
    const CHEME5800_L6A_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L6A_DATA)
    const CHEME5800_L6A_DATA = joinpath(CHEME5800_L6A_ROOT, "data")
end

# The names the L6a notebooks and src/ files use for the same folders -
if !isdefined(@__MODULE__, :_PATH_TO_SRC)
    const _ROOT = CHEME5800_L6A_ROOT
    const _PATH_TO_SRC = joinpath(_ROOT, "src")
    const _PATH_TO_DATA = joinpath(_ROOT, "data")
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end


# --- 3. IMPORTS --------------------------------------------------------------
# Everything this meeting brings into scope. One `using` per line so each can
# be annotated and each shows up on its own line in a diff.
#
# Already imported by the root bootstrap above, listed so this block is the
# whole picture rather than most of it:
#   VLDataScienceMachineLearningPackage   the course package
#
# Standard library:
using LinearAlgebra     # factorizations, SVD, norms, and matrix operations
using Statistics        # means and other summaries
using Test              # @test / @testset for the checks in the notebooks
#
# Packages:
using CSV               # delimited text files
using Colors            # colors for figures
using DataFrames        # tabular records held as columns
using FileIO            # save / load for the saved BiGG model
using GLPK              # linear programming solver
using Images            # Gray images in the SVD example
using JLD2              # the .jld2 format behind save / load
using JSON              # BiGG model records
using JuMP              # linear programming models
using Plots             # figures
using PrettyTables      # formatted table output in the notebooks


# --- 4. THIS MEETING'S SOURCE --------------------------------------------------
# The L6a code in src/ is loaded after the imports because it uses JuMP macros and
# the packages above at the top level.
include(joinpath(_PATH_TO_SRC, "Types.jl"))
include(joinpath(_PATH_TO_SRC, "Factory.jl"))
include(joinpath(_PATH_TO_SRC, "Parser.jl"))
include(joinpath(_PATH_TO_SRC, "Network.jl"))
include(joinpath(_PATH_TO_SRC, "Handler.jl"))
include(joinpath(_PATH_TO_SRC, "Compute.jl"))
include(joinpath(_PATH_TO_SRC, "Eigendecomposition.jl"))
include(joinpath(_PATH_TO_SRC, "Stoichiometric.jl"))
