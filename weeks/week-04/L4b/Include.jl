# =============================================================================
# CHEME 5800 | L4b local setup
# =============================================================================
# Run this file from the notebook's setup cell to load the course environment,
# the student traversal functions, and the packages used for tables and checks.


# --- 1. PATHS ----------------------------------------------------------------
# Resolve paths from this file, not the notebook's working directory.
# Guards keep these constants available when the setup cell runs again.
if !isdefined(@__MODULE__, :CHEME5800_L4B_ROOT)
    const CHEME5800_L4B_ROOT = @__DIR__ # folder containing this setup file
end

if !isdefined(@__MODULE__, :CHEME5800_L4B_DATA)
    const CHEME5800_L4B_DATA = joinpath(CHEME5800_L4B_ROOT, "data") # local graph data
end


# --- 2. CODE -----------------------------------------------------------------
# The root bootstrap activates the pinned course environment and imports the
# course package for both repository checkouts and extracted weekly bundles.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end

# Reload edited student functions on every setup run; do not guard this include.
# Notebook calls remain qualified (L4bTraversal.depth_first_order(...)) so they
# use the replacement module rather than a function imported from an older copy.
include(joinpath(@__DIR__, "src", "Compute-solution.jl"))


# --- 3. IMPORTS --------------------------------------------------------------
# The root bootstrap already imports VLDataScienceMachineLearningPackage;
# local traversal functions remain accessed through the L4bTraversal module.
using Test           # @test and @testset for the notebook's checks
using DataFrames     # adjacency and traversal-comparison tables
using PrettyTables   # formatted display of those tables
