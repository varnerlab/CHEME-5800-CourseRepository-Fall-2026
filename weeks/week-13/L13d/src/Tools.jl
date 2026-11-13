# =============================================================================
# CHEME 5800 | L13d FRED server: the tools
# =============================================================================
# You edit this file in this lab. The search_series and get_series_info tools
# are complete. Complete the get_series_observations tool: its input schema in
# build_fred_server(...) at the bottom of the file (TODO 1), and its handler,
# get_series_observations(...) (TODO 2 and TODO 3).
#
# After each edit: save this file, and run the notebook again from the cell that
# starts the server. The server loads this file each time it starts.
# =============================================================================

# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
# Read the base URL and the API key from the configuration of the server. When the server could not read its
# configuration file, the configuration holds the reason under the key setup_error, and each FRED tool reports it.
function _read_fred_settings(configuration::AbstractDict)::Tuple{String,String}

    # the server started without a key: report the reason as a tool execution error -
    if (haskey(configuration, "setup_error") == true)
        throw(ArgumentError(configuration["setup_error"]));
    end

    # return the base URL and the key -
    baseurl = configuration["baseurl"];
    apikey = configuration["apikey"];
    return (baseurl, apikey);
end

# Read a text argument, and check that it is there and is not empty -
function _read_text_argument(arguments::AbstractDict, key::String)::String

    # the argument must be there -
    if (haskey(arguments, key) == false)
        throw(ArgumentError("missing argument: $(key)"));
    end

    # the argument must be text, and must not be empty -
    value = arguments[key];
    if (isa(value, AbstractString) == false)
        throw(ArgumentError("the $(key) must be text"));
    end
    if (isempty(value) == true)
        throw(ArgumentError("the $(key) must not be empty"));
    end

    # return the text -
    return String(value);
end

# Read a series identifier. The identifier goes into a URL, so we accept only letters, digits, and underscores.
# This check stops an argument such as "DHHNGSP&api_key=..." from changing the query string of the request -
function _read_series_id(arguments::AbstractDict)::String

    # read the text, then check each character. The regular expression matches letters, digits, and underscores
    # from the start (\A) to the very end (\z) of the text, so a trailing newline does not slip through -
    series_id = _read_text_argument(arguments, "series_id");
    if (occursin(r"\A[A-Za-z0-9_]+\z", series_id) == false)
        throw(ArgumentError("the series_id must hold only letters, digits, and underscores, e.g., DHHNGSP"));
    end

    # return the identifier -
    return series_id;
end

# Read a date argument, written as YYYY-MM-DD, and check that it is a real date -
function _read_date_argument(arguments::AbstractDict, key::String)::String

    # read the text. The Date(...) constructor throws an error for text that is not a real date, e.g., "2025-13-01" -
    text = _read_text_argument(arguments, key);
    date = nothing;
    try
        date = Date(text);
    catch
        throw(ArgumentError("the $(key) must be a date written as YYYY-MM-DD, e.g., 2025-01-01"));
    end

    # the date, written back as text, must match the argument. This rules out other forms, e.g., "2025-1-001" -
    if (string(date) != text)
        throw(ArgumentError("the $(key) must be a date written as YYYY-MM-DD, e.g., 2025-01-01"));
    end

    # return the text -
    return text;
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    search_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `search_series` tool. Search FRED for the data series that match a search text.

### Arguments
- `arguments::AbstractDict`: the arguments of the call, with the key `search_text`, and the optional key `limit`,
  the largest number of series to return, from `1` to `20` (default: `5`).
- `configuration::AbstractDict`: the configuration of the server, with the keys `baseurl` and `apikey`.

### Returns
- `Dict{String,Any}`: the result, with the keys `search_text` and `series`. The `series` key holds one dictionary
  for each series, with the keys `series_id`, `title`, `frequency`, `units`, `observation_start`, and `observation_end`.

### Throws
- `ArgumentError`: when an argument is missing or wrong, or when FRED answers with an error.
"""
function search_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # read and check the arguments. The limit is optional -
    (baseurl, apikey) = _read_fred_settings(configuration);
    search_text = _read_text_argument(arguments, "search_text");
    limit = 5; # the default limit
    if (haskey(arguments, "limit") == true)
        limit = arguments["limit"];
        if (isa(limit, Integer) == false || isa(limit, Bool) == true) # Julia counts true and false as whole numbers
            throw(ArgumentError("the limit must be a whole number"));
        end
        if (limit < 1 || limit > 20)
            throw(ArgumentError("the limit must be between 1 and 20"));
        end
    end

    # call FRED in three steps: the endpoint model, its URL, and the call with a handler that returns a table -
    model = MyFredSeriesSearchEndpointModel(apikey = apikey, search_text = search_text, limit = limit);
    url = build(baseurl, model);
    table = MyFredSeriesSearchEndpointModel(url; handler = process_search_response_dataframe);

    # put each row of the table into a dictionary -
    series = Array{Dict{String,Any},1}();
    for i ∈ 1:nrow(table)
        entry = Dict{String,Any}();
        entry["series_id"] = table[i, :id];
        entry["title"] = table[i, :title];
        entry["frequency"] = table[i, :frequency];
        entry["units"] = table[i, :units];
        entry["observation_start"] = table[i, :observation_start];
        entry["observation_end"] = table[i, :observation_end];
        push!(series, entry);
    end

    # return the result -
    result = Dict{String,Any}();
    result["search_text"] = search_text;
    result["series"] = series;
    return result;
end

"""
    get_series_info(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_info` tool. Download the description of one FRED series.

### Arguments
- `arguments::AbstractDict`: the arguments of the call, with the key `series_id`, e.g., `"DHHNGSP"`.
- `configuration::AbstractDict`: the configuration of the server, with the keys `baseurl` and `apikey`.

### Returns
- `Dict{String,Any}`: the result, with the keys `series_id`, `title`, `units`, `frequency`, `seasonal_adjustment`,
  `observation_start`, and `observation_end`.

### Throws
- `ArgumentError`: when the argument is missing or wrong, or when FRED answers with an error, e.g., for a series that does not exist.
"""
function get_series_info(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # read and check the argument -
    (baseurl, apikey) = _read_fred_settings(configuration);
    series_id = _read_series_id(arguments);

    # call FRED: the endpoint model, its URL, and the call. The default handler parses the JSON text -
    model = MyFredSeriesEndpointModel(apikey = apikey, series_id = series_id);
    url = build(baseurl, model);
    response = MyFredSeriesEndpointModel(url);
    description = response["seriess"][1]; # the first, and only, entry of the list

    # select the fields that a language model needs -
    result = Dict{String,Any}();
    result["series_id"] = description["id"];
    result["title"] = description["title"];
    result["units"] = description["units"];
    result["frequency"] = description["frequency"];
    result["seasonal_adjustment"] = description["seasonal_adjustment"];
    result["observation_start"] = description["observation_start"];
    result["observation_end"] = description["observation_end"];
    return result;
end

"""
    get_series_observations(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_observations` tool. Download the observations (the data values) of one FRED series
between two dates.

The handler has three parts:
1. It reads and checks the arguments. This part is complete.
2. It downloads the observations as a table with the SDK. Writing this part is TODO 2.
3. It puts each row of the table into a dictionary with the keys `"date"` and `"value"`. Writing this part is TODO 3.

### Arguments
- `arguments::AbstractDict`: the arguments of the call, with the keys `series_id`, `observation_start`, and
  `observation_end` (dates written as `"YYYY-MM-DD"`), and the optional key `frequency`: `"d"` (daily), `"w"` (weekly),
  `"m"` (monthly), `"q"` (quarterly), or `"a"` (annual). The default frequency is `"m"`.
- `configuration::AbstractDict`: the configuration of the server, with the keys `baseurl` and `apikey`.

### Returns
- `Dict{String,Any}`: the result, with the keys `series_id`, `frequency`, and `observations`. The `observations` key
  holds one dictionary for each observation, with the keys `date` (text, e.g., `"2025-01-01"`) and `value`
  (a number, or `missing` when FRED has no value for the date; `missing` becomes `null` in the JSON text).

### Throws
- `ArgumentError`: when an argument is missing or wrong, when FRED answers with an error, or when the request
  would return more than 400 observations.
- `ErrorException`: when TODO 2 or TODO 3 is not complete.
"""
function get_series_observations(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # initialize; this part is complete -
    message = "Oooops! The `get_series_observations(...)` tool is not implemented yet - " *
        "we'd better fix that. Complete TODO 2 and TODO 3 in src/Tools.jl.";

    # read and check the arguments. The frequency is optional. This part is complete -
    (baseurl, apikey) = _read_fred_settings(configuration);
    series_id = _read_series_id(arguments);
    observation_start = _read_date_argument(arguments, "observation_start");
    observation_end = _read_date_argument(arguments, "observation_end");
    frequency = "m"; # the default: monthly averages
    if (haskey(arguments, "frequency") == true)
        frequency = _read_text_argument(arguments, "frequency");
        if ((frequency in ["d", "w", "m", "q", "a"]) == false)
            throw(ArgumentError("the frequency must be one of d, w, m, q, or a"));
        end
    end

    # TODO 2: download the observations as a table. Replace nothing with three lines: build the endpoint model
    # from the checked arguments above (with units = "lin"), build its URL with baseurl, and call FRED with the
    # process_observations_response_dataframe handler.
    # Hint: the search_series(...) tool above follows the same three steps for the search endpoint.
    table = nothing;
    if (isnothing(table) == true) # this part is complete: a blank TODO 2 leaves nothing behind
        throw(ErrorException(message));
    end

    # A language model reads the whole result, so the tool keeps the result short. This part is complete -
    if (nrow(table) > 400)
        throw(ArgumentError("the request returns $(nrow(table)) observations, and this tool returns at most 400. " *
            "Choose a shorter date range or a lower frequency."));
    end

    # put each row of the table into a dictionary with two keys, the date and the value -
    observations = Array{Dict{String,Any},1}();
    for i ∈ 1:nrow(table)

        # TODO 3: one observation. Replace nothing with a Dict{String,Any} that holds the date of row i as text
        # under the key "date", and the value of row i under the key "value".
        # Hint: string(d) writes the Date d as text, e.g., "2025-01-01". Store the value as it is: a missing value
        # becomes null in the JSON text.
        observation = nothing;
        if (isnothing(observation) == true) # this part is complete: a blank TODO 3 leaves nothing behind
            throw(ErrorException(message));
        end
        push!(observations, observation);
    end

    # return the result. This part is complete -
    result = Dict{String,Any}();
    result["series_id"] = series_id;
    result["frequency"] = frequency;
    result["observations"] = observations;
    return result;
end

"""
    build_fred_server(configuration::Dict{String,Any}) -> MyMCPServerModel

Build the FRED server: its identity, its three tools, and its configuration.

Each tool gets a name, a description, an input schema, and a handler. The input schema of the observations
tool is TODO 1.

### Arguments
- `configuration::Dict{String,Any}`: the configuration of the server, with the keys `baseurl` and `apikey`, or the
  key `setup_error` when the server could not read its configuration file.

### Returns
- `MyMCPServerModel`: the server, with the tools `search_series`, `get_series_info`, and `get_series_observations`.
"""
function build_fred_server(configuration::Dict{String,Any})::MyMCPServerModel

    # the search_series tool. This part is complete -
    search_schema = Dict{String,Any}(
        "type" => "object",
        "properties" => Dict{String,Any}(
            "search_text" => Dict{String,Any}("type" => "string",
                "description" => "Words to search for, e.g., Henry Hub natural gas spot price"),
            "limit" => Dict{String,Any}("type" => "integer", "minimum" => 1, "maximum" => 20,
                "description" => "Largest number of series to return (default: 5)")),
        "required" => ["search_text"]);
    search_tool = build(MyMCPToolModel, (
        name = "search_series",
        description = "Search FRED (Federal Reserve Economic Data) for the data series that match a search text. " *
            "Returns the identifier, title, frequency, units, and date range of each series.",
        inputschema = search_schema,
        handler = search_series));

    # the get_series_info tool. This part is complete -
    info_schema = Dict{String,Any}(
        "type" => "object",
        "properties" => Dict{String,Any}(
            "series_id" => Dict{String,Any}("type" => "string",
                "description" => "FRED series identifier, e.g., DHHNGSP for the Henry Hub natural gas spot price")),
        "required" => ["series_id"]);
    info_tool = build(MyMCPToolModel, (
        name = "get_series_info",
        description = "Get the description of one FRED series: its title, units, frequency, seasonal adjustment, and date range.",
        inputschema = info_schema,
        handler = get_series_info));

    # TODO 1: the input schema of the get_series_observations tool. Fill in the properties dictionary and the
    # required list. The tool has four arguments, each of type "string": series_id, observation_start,
    # observation_end, and frequency. The first three are required. Give each one a description.
    # Hint: copy the shape of the two schemas above. Each property is a Dict{String,Any} with the keys "type" and "description".
    observations_schema = Dict{String,Any}(
        "type" => "object",
        "properties" => Dict{String,Any}(),
        "required" => String[]);
    observations_tool = build(MyMCPToolModel, (
        name = "get_series_observations",
        description = "Get the observations (dates and values) of one FRED series between two dates. " *
            "FRED averages the values to a lower frequency on request. Returns at most 400 observations.",
        inputschema = observations_schema,
        handler = get_series_observations));

    # the server. This part is complete -
    server = build(MyMCPServerModel, (
        name = "cheme-5800-fred",
        version = "1.0.0",
        instructions = "Economic data from FRED (Federal Reserve Economic Data). Use search_series to find the " *
            "identifier of a series, then get_series_observations to download its values.",
        tools = [search_tool, info_tool, observations_tool],
        configuration = configuration));
    return server;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
