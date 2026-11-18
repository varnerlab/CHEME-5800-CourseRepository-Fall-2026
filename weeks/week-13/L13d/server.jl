# =============================================================================
# CHEME 5800 | L13d FRED server: the program that a host starts
# =============================================================================
# A host, e.g., Claude Code or the Codex command-line tool, starts this file as
# a subprocess, e.g.,
#
#   julia --startup-file=no server.jl
#
# and then talks to it over the standard input and output of the subprocess.
# The standard output is reserved for MCP messages. Julia and Pkg write their
# own messages, e.g., "Activating project ...", to the standard error stream.
# =============================================================================

# activate the course environment, and load the FRED server code -
include(joinpath(@__DIR__, "Include.jl"));

# read the API key from the configuration file. The key stays in this process -
configuration = load_server_configuration(joinpath(CHEME5800_L13D_CONFIG, "Configuration.toml"));

# build the server, and run its loop until the client closes the connection -
server = build_fred_server(configuration);
serve(server; input = stdin, output = stdout);
