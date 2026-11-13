# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    build(base::String, model::MyFredSeriesSearchEndpointModel) -> String

Build the URL string for the `fred/series/search` endpoint of the FRED API.
An HTTP GET call to this URL returns the series that match the search text held by the model.

### Arguments
- `base::String`: the base URL of the FRED API, i.e., `"https://api.stlouisfed.org"`.
- `model::MyFredSeriesSearchEndpointModel`: the endpoint model that holds the API key, the search text, and the limit.

### Returns
- `String`: the complete URL string, e.g.,
  `"https://api.stlouisfed.org/fred/series/search?search_text=natural%20gas&limit=5&api_key=<your key>&file_type=json"`.
  The URL holds the API key, so do not print it or share it.
"""
function build(base::String, model::MyFredSeriesSearchEndpointModel)::String

    # get data from the model -
    apikey = model.apikey;
    limit = model.limit;

    # A URL cannot hold a space, so we encode the search text: each space becomes %20 -
    search_text = HTTP.escapeuri(model.search_text);

    # build the URL string: base + path + ? + query string.
    # The query string is a list of key=value parameters, joined by &.
    # The file_type=json parameter asks FRED for JSON text (the default of FRED is XML) -
    url_string = "$(base)/fred/series/search?search_text=$(search_text)&limit=$(limit)&api_key=$(apikey)&file_type=json";

    # return the URL string -
    return url_string;
end

"""
    build(base::String, model::MyFredSeriesEndpointModel) -> String

Build the URL string for the `fred/series` endpoint of the FRED API.
An HTTP GET call to this URL returns the description of the series held by the model.

### Arguments
- `base::String`: the base URL of the FRED API, i.e., `"https://api.stlouisfed.org"`.
- `model::MyFredSeriesEndpointModel`: the endpoint model that holds the API key and the series identifier.

### Returns
- `String`: the complete URL string, e.g.,
  `"https://api.stlouisfed.org/fred/series?series_id=DHHNGSP&api_key=<your key>&file_type=json"`.
  The URL holds the API key, so do not print it or share it.
"""
function build(base::String, model::MyFredSeriesEndpointModel)::String

    # get data from the model -
    apikey = model.apikey;
    series_id = model.series_id;

    # build the URL string: base + path + ? + query string -
    url_string = "$(base)/fred/series?series_id=$(series_id)&api_key=$(apikey)&file_type=json";

    # return the URL string -
    return url_string;
end

"""
    build(base::String, model::MyFredSeriesObservationsEndpointModel) -> String

Build the URL string for the `fred/series/observations` endpoint of the FRED API.
An HTTP GET call to this URL returns the observations of the series held by the model.

The URL has four pieces: the base, the path `/fred/series/observations`, a question mark `?`, and the query string.
The query string holds seven `key=value` parameters, joined by `&`:

| Key | Value |
|---|---|
| `series_id` | the `series_id` field of the model |
| `observation_start` | the `observation_start` field of the model |
| `observation_end` | the `observation_end` field of the model |
| `frequency` | the `frequency` field of the model |
| `units` | the `units` field of the model |
| `api_key` | the `apikey` field of the model |
| `file_type` | the text `json`, which asks FRED for JSON text |

FRED reads each parameter by its key, so the order of the parameters does not matter.

### Arguments
- `base::String`: the base URL of the FRED API, i.e., `"https://api.stlouisfed.org"`.
- `model::MyFredSeriesObservationsEndpointModel`: the endpoint model that holds the API key, the series identifier,
  the first and last date, the frequency, and the units.

### Returns
- `String`: the complete URL string. The URL holds the API key, so do not print it or share it.

### Example
```julia
model = MyFredSeriesObservationsEndpointModel(apikey = apikey, series_id = "DHHNGSP",
    observation_start = "2025-01-01", observation_end = "2025-12-31", frequency = "m", units = "lin");
url = build("https://api.stlouisfed.org", model);
```
"""
function build(base::String, model::MyFredSeriesObservationsEndpointModel)::String

    # get data from the model -
    apikey = model.apikey;
    series_id = model.series_id;
    observation_start = model.observation_start;
    observation_end = model.observation_end;
    frequency = model.frequency;
    units = model.units;

    # build the URL string: base + path + ? + query string -
    url_string = "$(base)/fred/series/observations?series_id=$(series_id)&observation_start=$(observation_start)&observation_end=$(observation_end)&frequency=$(frequency)&units=$(units)&api_key=$(apikey)&file_type=json";

    # return the URL string -
    return url_string;
end

"""
    build(model::Type{MyMCPToolModel}, data::NamedTuple) -> MyMCPToolModel

Build an MCP tool from its name, its description, its input schema, and its handler.

### Arguments
- `model::Type{MyMCPToolModel}`: the type of the model to build.
- `data::NamedTuple`: the data of the tool, with the keys `name::String`, `description::String`,
  `inputschema::Dict{String,Any}`, and `handler::Function`.

### Returns
- `MyMCPToolModel`: the tool. A server sends its name, description, and input schema to a client
  in the result of a `tools/list` request.
"""
function build(model::Type{MyMCPToolModel}, data::NamedTuple)::MyMCPToolModel

    # build an empty tool, and fill in its fields from the data -
    tool = model();
    tool.name = data.name;
    tool.description = data.description;
    tool.inputschema = data.inputschema;
    tool.handler = data.handler;

    # return the tool -
    return tool;
end

"""
    build(model::Type{MyMCPServerModel}, data::NamedTuple) -> MyMCPServerModel

Build an MCP server from its identity, its tools, and the configuration that its tools need.

### Arguments
- `model::Type{MyMCPServerModel}`: the type of the model to build.
- `data::NamedTuple`: the data of the server, with the keys `name::String`, `version::String`, `instructions::String`,
  `tools::Array{MyMCPToolModel,1}`, and `configuration::Dict{String,Any}`.

### Returns
- `MyMCPServerModel`: the server, with its tools stored in a dictionary keyed by the tool name.
"""
function build(model::Type{MyMCPServerModel}, data::NamedTuple)::MyMCPServerModel

    # build an empty server, and fill in its identity and configuration -
    server = model();
    server.name = data.name;
    server.version = data.version;
    server.instructions = data.instructions;
    server.configuration = data.configuration;

    # store the tools in a dictionary, so the server can look up a tool by its name -
    tools = Dict{String,MyMCPToolModel}();
    for tool ∈ data.tools
        tools[tool.name] = tool;
    end
    server.tools = tools;

    # return the server -
    return server;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
