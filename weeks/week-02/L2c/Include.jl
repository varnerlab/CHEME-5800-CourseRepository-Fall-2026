# =============================================================================
# CHEME 5800 | L2c local setup
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
if !isdefined(@__MODULE__, :CHEME5800_L2C_ROOT)
    const CHEME5800_L2C_ROOT = @__DIR__
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
include(normpath(joinpath(CHEME5800_L2C_ROOT, "..", "..", "..", "Include.jl")))

# `L2cTextRepresentation` holds this meeting's local code-point formatter. The
# module keeps the helper name separate from notebook variables, and the guard
# makes re-running the setup cell safe.
if !isdefined(@__MODULE__, :L2cTextRepresentation)
    include(joinpath(CHEME5800_L2C_ROOT, "src", "Compute.jl"))
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
using Test             # @test / @testset for the checks in the notebook
using Unicode          # Unicode normalization utilities
#
# Packages:
using DataFrames       # tabular records held as columns
using PrettyTables     # formatted table output in the notebook
#
# This meeting's own source, included above. The leading dot means "a module
# defined here", as opposed to an installed package of the same name:
using .L2cTextRepresentation  # from the include in section 2
