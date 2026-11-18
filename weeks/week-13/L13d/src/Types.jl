# =============================================================================
# CHEME 5800 | L13d FRED server: the MCP models
# =============================================================================
# The models of a tool, a server, and a client. The FRED endpoint models are in
# the FredAPI package, e.g., FredAPI.MyFredSeriesEndpointModel.
# =============================================================================

# --- MCP TYPES BELOW HERE ------------------------------------------------------------------------------------- #
"""
    AbstractMCPModel

Abstract base type for the Model Context Protocol (MCP) models: a tool, a server, and a client.
"""
abstract type AbstractMCPModel end

"""
    mutable struct MyMCPToolModel <: AbstractMCPModel

A tool that an MCP server offers to its clients. The server sends the name, the description, and the
input schema of each tool in its answer to a `tools/list` request. The server runs the handler when a
client sends a `tools/call` request that names the tool.

### Fields
- `name::String`: the name that a client uses to call the tool, e.g., `"search_series"`.
- `description::String`: what the tool does, in plain English. A host passes this text to its language model.
- `inputschema::Dict{String,Any}`: a JSON Schema that describes the arguments of the tool: their names, their types, and which ones are required.
- `handler::Function`: the function that runs the tool. It takes two dictionaries, the arguments of the call and the
  configuration of the server, and returns the result as a dictionary. It throws an error when the tool fails.

### Constructors
- `MyMCPToolModel()`: returns an empty instance. Use the `build(MyMCPToolModel, data::NamedTuple)` method in
  [src/Factory.jl](Factory.jl) to fill in the fields.
"""
mutable struct MyMCPToolModel <: AbstractMCPModel

    # data -
    name::String
    description::String
    inputschema::Dict{String,Any}
    handler::Function

    # methods -
    MyMCPToolModel() = new(); # empty, the build method sets the fields
end

"""
    mutable struct MyMCPServerModel <: AbstractMCPModel

An MCP server: its identity, the tools that it offers, and the settings that its tools need.

### Fields
- `name::String`: the name of the server, which the server sends in every result.
- `version::String`: the version of the server software.
- `instructions::String`: a short guide to the server, in plain English. A host can pass this text to its language model.
- `tools::Dict{String,MyMCPToolModel}`: the tools of the server, keyed by the tool name.
- `configuration::Dict{String,Any}`: the settings that the tool handlers need, e.g., the base URL of a web API and an API key.
  The server passes this dictionary to each handler. It never sends it to a client.

### Constructors
- `MyMCPServerModel()`: returns an empty instance. Use the `build(MyMCPServerModel, data::NamedTuple)` method in
  [src/Factory.jl](Factory.jl) to fill in the fields.
"""
mutable struct MyMCPServerModel <: AbstractMCPModel

    # data -
    name::String
    version::String
    instructions::String
    tools::Dict{String,MyMCPToolModel}
    configuration::Dict{String,Any}

    # methods -
    MyMCPServerModel() = new(); # empty, the build method sets the fields
end

"""
    mutable struct MyMCPClientModel <: AbstractMCPModel

A client's connection to an MCP server that runs as a subprocess. The client writes its requests to the standard
input of the subprocess, and reads the responses from the standard output of the subprocess.

### Fields
- `process::Base.Process`: the server subprocess.
- `requestid::Int64`: the id of the last request that the client sent. Each request gets the next id.
- `verbose::Bool`: when `true`, the client prints every message that it sends and receives.

### Constructors
- `MyMCPClientModel()`: returns an empty instance. Use the `connect(...)` function in [src/Client.jl](Client.jl)
  to start a server and fill in the fields.
"""
mutable struct MyMCPClientModel <: AbstractMCPModel

    # data -
    process::Base.Process
    requestid::Int64
    verbose::Bool

    # methods -
    MyMCPClientModel() = new(); # empty, the connect function sets the fields
end
# --- MCP TYPES ABOVE HERE ------------------------------------------------------------------------------------- #
