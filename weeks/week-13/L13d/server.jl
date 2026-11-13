# =============================================================================
# CHEME 5800 | L13d FRED server: the program that a host starts
# =============================================================================
# A host starts this file as a subprocess, e.g.,
#
#   julia --startup-file=no /path/to/L13d/server.jl
#
# and then talks to it over the standard input and output of the subprocess.
# The standard output is reserved for MCP messages. Julia and Pkg write their
# own messages, e.g., "Activating project ...", to the standard error stream.
# =============================================================================

# activate the course environment, and load the course package -
include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"));

# load the FRED server code. This loads your src/Tools.jl each time the server starts -
include(joinpath(@__DIR__, "src", "FredMCP.jl"));
using .L13dFredMCP

# read the API key from the configuration file. The key stays in this process -
configuration = load_server_configuration(joinpath(@__DIR__, "conf", "Configuration.toml"));

# build the server, and run its loop until the client closes the connection -
server = build_fred_server(configuration);
serve(server; input = stdin, output = stdout);
