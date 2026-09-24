# =============================================================================
# CHEME 5800 | L5d local setup
# =============================================================================
# Every class-meeting folder carries one of these, and running it from the first
# cell of the notebook is the only setup a student performs.
#
# The file is in four sections, in this order:
#
#   1. PATHS     locate this folder, so nothing depends on the working directory
#   2. BOOTSTRAP load the root setup and activate the course environment
#   3. IMPORTS   every `using` for this meeting, in one block
#   4. CODE      load this lab's types and functions
#
# Section 3 is deliberately the only place a `using` appears. The local source
# follows it because the function signatures and solver macros need those
# packages to be available when Julia reads the files.
#
# The root bootstrap in section 2 activates the single pinned course environment
# (root Project.toml and Manifest.toml). That is why no weekly folder carries a
# Project.toml of its own: a cloned repository and an extracted weekly bundle
# resolve to the same package versions the material was written against.
# =============================================================================


# --- 1. PATHS ----------------------------------------------------------------
# `@__DIR__` is the folder holding *this* file, not `pwd()`, so the joins below
# hold whether the notebook was launched from here or from the repository root.
# The guards keep the path constants in place when the setup cell is rerun.
if !isdefined(@__MODULE__, :CHEME5800_L5D_ROOT)
    const CHEME5800_L5D_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L5D_DATA)
    const CHEME5800_L5D_DATA = joinpath(CHEME5800_L5D_ROOT, "data")
end


# --- 2. BOOTSTRAP ------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end


# --- 3. IMPORTS --------------------------------------------------------------
# Everything this meeting imports from packages. One `using` per line so each
# can be annotated and each shows up on its own line in a diff.
#
# Already imported by the root bootstrap above, listed so this block is the
# whole picture rather than most of it:
#   VLDataScienceMachineLearningPackage   the course package
#
# Standard library:
using LinearAlgebra: dot   # independently recompute cost from edge costs and flows
using Test                # @test / @testset for the checks in the notebook
#
# Packages:
using CSV                 # read the department input tables
using Colors              # choose contrasting colors for the network figures
using DataFrames          # tabular records held as columns
using GLPK                # the LP/MILP solver backend
using JuMP                # the optimization modeling layer
using MathOptInterface    # solver status codes and attributes
using Plots               # figures
using PrettyTables        # formatted table output in the notebook


# --- 4. CODE -----------------------------------------------------------------
# These files define the lab's edge record and plain functions in the notebook's
# scope. The guards load each file once per session, so rerunning setup preserves
# the existing definitions. Restart the kernel after editing source files.
#
# `Types.jl` defines FlowEdge, shared by the student and reference implementations.
# Load it before the functions whose signatures use that type.
if !isdefined(@__MODULE__, :FlowEdge)
    include(joinpath(@__DIR__, "src", "Types.jl"))
end

# `Compute.jl` reads the department data, builds and solves the flow model, and
# checks the resulting schedule. `Compute-solution.jl` is the reference version.
if !isdefined(@__MODULE__, :build_teaching_network)
    include(joinpath(@__DIR__, "src", "Compute.jl"))
end

# The figure helper is separate from model assembly and solution checks.
if !isdefined(@__MODULE__, :plot_teaching_flow)
    include(joinpath(@__DIR__, "src", "FlowPlots.jl"))
end
