# =============================================================================
# CHEME 5800 | L3d local setup
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
if !isdefined(@__MODULE__, :CHEME5800_L3D_ROOT)
    const CHEME5800_L3D_ROOT = @__DIR__
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
include(normpath(joinpath(CHEME5800_L3D_ROOT, "..", "..", "..", "Include.jl")))

# `L3dSorting` holds this meeting's own source. It is wrapped in a module so that
# a student stub and a reference solution declaring the same module name stay
# drop-in interchangeable between the notebook and the validation suite. The
# include is deliberately unguarded: students edit `src/Compute.jl` during the
# lab, and re-running this file must reload those edits. Julia 1.12 replaces
# the module silently: the reload works even though nothing is printed.
include(joinpath(CHEME5800_L3D_ROOT, "src", "Compute.jl"))


# --- 3. IMPORTS --------------------------------------------------------------
# Everything this meeting brings into scope. One `using` per line so each can
# be annotated and each shows up on its own line in a diff.
#
# Already imported by the root bootstrap above, listed so this block is the
# whole picture rather than most of it:
#   VLDataScienceMachineLearningPackage   the course package
#
# Standard library:
using Random          # seeded random number generation
using Statistics      # mean, std, and friends
using Test            # @test / @testset for the checks in the notebook
#
# Packages:
using BenchmarkTools  # @benchmarkable timing measurements
using DataFrames      # tabular records held as columns
using Plots           # figures
#
# The L3dSorting module imports WAV internally for the optional bubble-sort
# sound playback; the notebook itself never calls WAV directly.
#
# This meeting's own source (the include in section 2) stays behind its module
# name: the notebook calls L3dSorting.bubblesort(...) and friends, qualified.
# There is deliberately no `using .L3dSorting` here. Re-running this file
# replaces the module, and on Julia 1.12 a second `using` of the replacement
# makes every exported name ambiguous in Main (UndefVarError: two modules
# export the name). Qualified lookup follows the replaced module, so the
# edit-save-rerun loop in the lab works without restarting the kernel.
