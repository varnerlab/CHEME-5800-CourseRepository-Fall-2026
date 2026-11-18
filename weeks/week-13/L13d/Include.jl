# =============================================================================
# CHEME 5800 | L13d local setup
# =============================================================================
# Every class-meeting folder carries one of these. In this lab, server.jl runs
# it when a host starts the server, and a Julia REPL can run it to call the
# server from Julia.
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
if !isdefined(@__MODULE__, :CHEME5800_L13D_ROOT)
    const CHEME5800_L13D_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L13D_SERVER)
    const CHEME5800_L13D_SERVER = joinpath(CHEME5800_L13D_ROOT, "server.jl") # the program that a host starts
end

if !isdefined(@__MODULE__, :CHEME5800_L13D_CONFIG)
    const CHEME5800_L13D_CONFIG = joinpath(CHEME5800_L13D_ROOT, "conf") # the configuration file with your FRED API key
end


# --- 2. CODE -----------------------------------------------------------------
# The repository root `Include.jl` activates the course environment and imports
# the course package. It is the only place environment handling lives.
# Reuse a completed bootstrap; reload it if the active project has changed.
if !isdefined(@__MODULE__, :CHEME5800_BOOTSTRAP_LOADED) ||
        Base.active_project() != CHEME5800_PROJECT
    include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"))
end

# The FRED server code is wrapped in the `L13dFredMCP` module. The module imports
# its dependencies, and the guard supports running this file again.
#   src/Types.jl     the MCP tool, server, and client models
#   src/Factory.jl   build(...) for the tools and the server
#   src/Utility.jl   read the configuration file that holds the API key
#   src/Tools.jl     how a FRED tool works: arguments, input schema, and the call
#   src/Catalog.jl   the 36 tools, one for each endpoint of the FRED API
#   src/Server.jl    the MCP server
#   src/Client.jl    the MCP client, which starts a server and sends it requests
# The FRED calls go through the FredAPI package, the FRED SDK. A host such as
# Claude Code or the Codex command-line tool starts server.jl, which loads this
# file and runs the server.
if !isdefined(@__MODULE__, :L13dFredMCP)
    include(joinpath(CHEME5800_L13D_ROOT, "src", "FredMCP.jl"))
end


# --- 3. IMPORTS --------------------------------------------------------------
# Everything this meeting brings into scope. One `using` per line so each can
# be annotated and each shows up on its own line in a diff.
#
# Already imported by the root bootstrap above, listed so this block is the
# whole picture rather than most of it:
#   VLDataScienceMachineLearningPackage   the course package
#
# Packages:
import FredAPI       # the FRED SDK, e.g., FredAPI.MyFredSeriesEndpointModel
using JSON           # parsing and printing JSON text
#
# This meeting's code (section 2). The leading dot means "a module defined
# here", as opposed to an installed package of the same name:
using .L13dFredMCP      # the FRED server, and the client that talks to it
