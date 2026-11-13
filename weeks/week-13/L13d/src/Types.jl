# --- FRED TYPES BELOW HERE ------------------------------------------------------------------------------------ #
"""
    AbstractFredEndpointModel

Abstract base type for all FRED (Federal Reserve Economic Data) API endpoint models.
Each subtype represents one endpoint of the API and holds the data needed to call it.
"""
abstract type AbstractFredEndpointModel end

"""
    mutable struct MyFredSeriesSearchEndpointModel <: AbstractFredEndpointModel

Endpoint model for the FRED `fred/series/search` endpoint.
This endpoint returns the economic data series that match a search text.

### Fields
- `apikey::String`: the FRED API key of the client, a 32 character string of lowercase letters and digits.
- `search_text::String`: the words to search for, e.g., `"natural gas spot price"`.
- `limit::Int64`: the largest number of series to return, between `1` and `1000`.

### Constructors
- `MyFredSeriesSearchEndpointModel(; apikey::String = "", search_text::String = "", limit::Int64 = 10)`: returns a new `MyFredSeriesSearchEndpointModel` instance.
"""
mutable struct MyFredSeriesSearchEndpointModel <: AbstractFredEndpointModel

    # data -
    apikey::String
    search_text::String
    limit::Int64

    # methods -
    MyFredSeriesSearchEndpointModel(;
        apikey::String = "", search_text::String = "", limit::Int64 = 10) = new(apikey, search_text, limit);
end

"""
    mutable struct MyFredSeriesEndpointModel <: AbstractFredEndpointModel

Endpoint model for the FRED `fred/series` endpoint.
This endpoint returns the description of one economic data series: its title, units, frequency, and date range.

### Fields
- `apikey::String`: the FRED API key of the client, a 32 character string of lowercase letters and digits.
- `series_id::String`: the identifier of the series, e.g., `"DHHNGSP"` for the Henry Hub natural gas spot price.

### Constructors
- `MyFredSeriesEndpointModel(; apikey::String = "", series_id::String = "")`: returns a new `MyFredSeriesEndpointModel` instance.
"""
mutable struct MyFredSeriesEndpointModel <: AbstractFredEndpointModel

    # data -
    apikey::String
    series_id::String

    # methods -
    MyFredSeriesEndpointModel(;
        apikey::String = "", series_id::String = "") = new(apikey, series_id);
end

"""
    mutable struct MyFredSeriesObservationsEndpointModel <: AbstractFredEndpointModel

Endpoint model for the FRED `fred/series/observations` endpoint.
This endpoint returns the observations (the data values) of one economic data series.

### Fields
- `apikey::String`: the FRED API key of the client, a 32 character string of lowercase letters and digits.
- `series_id::String`: the identifier of the series, e.g., `"DHHNGSP"` for the Henry Hub natural gas spot price.
- `observation_start::String`: the first date that we want, written as `"YYYY-MM-DD"`.
- `observation_end::String`: the last date that we want, written as `"YYYY-MM-DD"`.
- `frequency::String`: the frequency of the observations that FRED returns: `"d"` (daily), `"w"` (weekly), `"m"` (monthly),
  `"q"` (quarterly), or `"a"` (annual). FRED averages the observations of a series to reach a lower frequency. FRED returns
  an error when the frequency that we ask for is higher than the frequency of the series.
- `units::String`: the transformation that FRED applies to the values: `"lin"` (none), `"chg"` (change from the previous
  observation), `"pch"` (percent change from the previous observation), or `"pc1"` (percent change from one year ago).

### Constructors
- `MyFredSeriesObservationsEndpointModel(; apikey::String = "", series_id::String = "", observation_start::String = "1776-07-04",
  observation_end::String = "9999-12-31", frequency::String = "m", units::String = "lin")`: returns a new
  `MyFredSeriesObservationsEndpointModel` instance. The default dates are the defaults of FRED, which select every observation.
"""
mutable struct MyFredSeriesObservationsEndpointModel <: AbstractFredEndpointModel

    # data -
    apikey::String
    series_id::String
    observation_start::String
    observation_end::String
    frequency::String
    units::String

    # methods -
    MyFredSeriesObservationsEndpointModel(;
        apikey::String = "", series_id::String = "", observation_start::String = "1776-07-04",
        observation_end::String = "9999-12-31", frequency::String = "m", units::String = "lin") = new(
            apikey, series_id, observation_start, observation_end, frequency, units);
end
# --- FRED TYPES ABOVE HERE ------------------------------------------------------------------------------------ #

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
