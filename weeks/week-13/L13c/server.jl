# =============================================================================
# CHEME 5800 | L13c weather server: the program that a host starts
# =============================================================================
# A host starts this file as a subprocess, e.g.,
#
#   julia --startup-file=no /path/to/L13c/server.jl
#
# and then talks to it over the standard input and output of the subprocess.
# The standard output is reserved for MCP messages. Julia and Pkg write their
# own messages, e.g., "Activating project ...", to the standard error stream.
# =============================================================================

# activate the course environment, and load the course package -
include(joinpath(@__DIR__, "..", "..", "..", "Include.jl"));

# load the weather server code -
include(joinpath(@__DIR__, "src", "WeatherMCP.jl"));
using .L13cWeatherMCP

# build the server, and run its loop until the client closes the connection -
server = build_weather_server();
serve(server; input = stdin, output = stdout);
