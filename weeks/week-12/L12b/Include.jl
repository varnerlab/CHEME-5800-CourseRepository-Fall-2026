# =============================================================================
# CHEME 5800 | L12b local setup
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
if !isdefined(@__MODULE__, :CHEME5800_L12B_ROOT)
    const CHEME5800_L12B_ROOT = @__DIR__
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end

# `L12bQLearning` holds the student's `myqlearning(...)`. It is included on
# every run, with no guard, so re-running the setup cell picks up the student's
# edits; the notebook calls it by qualified name (`L12bQLearning.myqlearning(...)`)
# for the same reason.
include(joinpath(CHEME5800_L12B_ROOT, "src", "Compute-solution.jl"))

# Supplied helpers, loaded once: the dosing model, value iteration, and the policy
# simulator.
if !isdefined(@__MODULE__, :L12bUtility)
    include(joinpath(CHEME5800_L12B_ROOT, "src", "Utility.jl"))
end


# --- 3. IMPORTS --------------------------------------------------------------
# Everything this meeting brings into scope. One `using` per line so each can
# be annotated and each shows up on its own line in a diff.
#
# Already imported by the root bootstrap above, listed so this block is the
# whole picture rather than most of it:
#   VLDataScienceMachineLearningPackage   the course package: the MDP and
#                                         Q-learning agent models, build, and policy
#
# Packages:
using Plots          # figures
using DataFrames     # tables of results
using PrettyTables   # printing those tables
#
# This meeting's supplied helpers (section 2):
using .L12bUtility   # MyAdaptiveDosingModel, stateindex, decode, isterminal,
                     # world, simulate, and mdpworld; build and solve gain dosing methods
#
# There is deliberately no `using .L12bQLearning`. Re-running this file
# replaces that module, and on Julia 1.12 a second `using` of the replacement
# makes every exported name ambiguous. The notebook calls
# L12bQLearning.myqlearning(...) instead.
