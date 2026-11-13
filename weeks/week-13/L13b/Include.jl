# =============================================================================
# CHEME 5800 | L13b local setup
# =============================================================================
# Every class-meeting folder carries one of these, and running it from the first
# cell of the notebook is the only setup a student performs.
#
# The file is in three sections, in this order:
#
#   1. PATHS   locate this folder, so nothing depends on the working directory
#   2. CODE    load the root bootstrap and any source this meeting needs
#   3. IMPORTS every `using` for this meeting, in one block
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
if !isdefined(@__MODULE__, :CHEME5800_L13B_ROOT)
    const CHEME5800_L13B_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L13B_CONFIG)
    const CHEME5800_L13B_CONFIG = joinpath(CHEME5800_L13B_ROOT, "conf") # the configuration file with your FRED API key
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end

# The FRED code is wrapped in the `L13bFRED` module. The module imports its
# dependencies, and the guard supports rerunning the notebook setup cell.
#   src/Types.jl     the endpoint models
#   src/Factory.jl   the build methods for the request URLs (you complete one)
#   src/Network.jl   the HTTP calls
#   src/Handler.jl   the functions that process the responses (you complete one)
# The guard loads the module once. After you edit Factory.jl or Handler.jl,
# restart the kernel and run the notebook from the top to load your edits.
if !isdefined(@__MODULE__, :L13bFRED)
    include(joinpath(CHEME5800_L13B_ROOT, "src", "FRED.jl"))
end

# Supplied helpers, loaded once: reading the configuration file and hiding the
# API key in a printed URL.
if !isdefined(@__MODULE__, :L13bUtility)
    include(joinpath(CHEME5800_L13B_ROOT, "src", "Utility.jl"))
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
using Dates          # the Date type of the observation dates
using Statistics     # mean, for the average price
using Test           # @test / @testset for the check in the notebook
#
# Packages:
using DataFrames     # the tables of series and observations
using JSON           # parsing JSON text
using Plots          # figures
using PrettyTables   # formatted table output in the notebook
#
# This meeting's code (section 2). The leading dot means "a module defined
# here", as opposed to an installed package of the same name:
using .L13bFRED      # the endpoint models, the handlers, and the FRED interface
using .L13bUtility   # read_configuration and hidekey
