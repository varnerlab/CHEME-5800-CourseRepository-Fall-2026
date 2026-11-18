# =============================================================================
# CHEME 5800 | L13d FRED server: how a FRED tool works
# =============================================================================
# The server offers one tool for each of the 36 endpoints of the FRED API. The
# FredAPI package holds one endpoint model for each endpoint, and every tool
# calls FRED in the same three steps:
#
#   1. copy the arguments of the call into the fields of the endpoint model,
#   2. build the URL of the request with FredAPI.url(...), and
#   3. call FRED with FredAPI.api(...), which returns the JSON response of FRED
#      as a dictionary.
#
# The _call_fred(...) function in this file carries out the three steps. The
# input schema of each tool comes from the fields of its endpoint model, in
# _input_schema(...). The 36 tools themselves are in src/Catalog.jl.
# =============================================================================

# a language model reads the whole result of a tool, so the server keeps each result short -
const MAX_RESULT_CHARACTERS = 40000;

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

# The names of the arguments of an endpoint: every field of the endpoint model except apikey, in the order of the fields -
function _argument_names(endpoint::Type{T})::Array{String,1} where T <: FredAPI.AbstractFredEndpointModel

    names = Array{String,1}();
    for field ∈ fieldnames(endpoint)
        if (field != :apikey) # the key comes from the configuration of the server, never from a call
            push!(names, String(field));
        end
    end
    return names;
end

# Copy the arguments of a call into the fields of an endpoint model. Each argument must name a field of the model,
# and its value must have the type of that field: text for a String, a whole number for an Int64, and true or
# false for a Bool. A wrong argument is a tool execution error, and the language model can read the message -
function _copy_arguments!(model::FredAPI.AbstractFredEndpointModel, arguments::AbstractDict)::Nothing

    # the names of the arguments that this endpoint takes -
    endpoint = typeof(model);
    allowed = _argument_names(endpoint);

    # copy each argument into the field of the same name -
    for (key, value) ∈ arguments

        # the argument must name a field of the model. This check also stops a call from setting the apikey field -
        if ((key in allowed) == false)
            throw(ArgumentError("unknown argument: $(key). The arguments of this tool are: $(join(allowed, ", "))"));
        end
        field = Symbol(key);
        field_type = fieldtype(endpoint, field);

        # the value must have the type of the field. Julia counts true and false as whole numbers, so an Int64 field
        # rules out a Bool value -
        if (field_type == String)
            if (isa(value, AbstractString) == false)
                throw(ArgumentError("the $(key) must be text"));
            end
            setfield!(model, field, String(value));
        elseif (field_type == Int64)
            if (isa(value, Integer) == false || isa(value, Bool) == true)
                throw(ArgumentError("the $(key) must be a whole number"));
            end
            setfield!(model, field, Int64(value));
        elseif (field_type == Bool)
            if (isa(value, Bool) == false)
                throw(ArgumentError("the $(key) must be true or false"));
            end
            setfield!(model, field, value);
        end
    end

    return nothing;
end

# Check the length of a result. The server returns a result of at most MAX_RESULT_CHARACTERS characters of JSON text.
# A longer result is a tool execution error, and the message tells the language model how to ask for less -
function _check_length(result::Dict{String,Any})::Dict{String,Any}

    characters = length(JSON.json(result));
    if (characters > MAX_RESULT_CHARACTERS)
        throw(ArgumentError("the result holds $(characters) characters of JSON text, and this server returns at most " *
            "$(MAX_RESULT_CHARACTERS). Ask for fewer results, e.g., with a smaller limit, a shorter date range, or a lower frequency."));
    end
    return result;
end

# Call FRED in three steps: the endpoint model, its URL, and the call. The api(...) function of FredAPI throws an
# ArgumentError when FRED answers with an error, and its messages never show the URL or the API key -
function _fetch(endpoint::Type{T}, arguments::AbstractDict,
    configuration::AbstractDict)::Dict{String,Any} where T <: FredAPI.AbstractFredEndpointModel

    # read the settings of the server -
    (baseurl, apikey) = _read_fred_settings(configuration);

    # step 1: an endpoint model that holds the key, with the arguments of the call in its other fields. A field that
    # the call leaves out stays at its empty value, and FRED uses its own default for it -
    model = endpoint(apikey = apikey);
    _copy_arguments!(model, arguments);

    # step 2: the URL of the request. FredAPI encodes each value for a URL, so no argument can change the query -
    request_url = FredAPI.url(baseurl, model);

    # step 3: the call. The default handler of FredAPI parses the JSON text of the response into a dictionary -
    response = FredAPI.api(endpoint, request_url);

    # FRED does not repeat the key in a response. If a response holds the key, the server does not return it -
    if (occursin(apikey, JSON.json(response)) == true)
        throw(ArgumentError("the response of FRED holds the API key, so the server does not return the response"));
    end
    return response;
end

# Call FRED, and check the length of the result. This is the handler of 35 of the 36 tools -
function _call_fred(endpoint::Type{T}, arguments::AbstractDict,
    configuration::AbstractDict)::Dict{String,Any} where T <: FredAPI.AbstractFredEndpointModel

    response = _fetch(endpoint, arguments, configuration);
    return _check_length(response);
end

# The description of the order_by argument. The attributes that FRED sorts by depend on what the endpoint returns -
function _order_by_description(endpoint::Type{T})::String where T <: FredAPI.AbstractFredEndpointModel

    # the attributes of a series, for the endpoints that return series -
    series_attributes = "series_id, title, units, frequency, seasonal_adjustment, realtime_start, realtime_end, " *
        "last_updated, observation_start, observation_end, popularity, or group_popularity";
    if (endpoint == FredAPI.MyFredSeriesSearchEndpointModel)
        return "Attribute that FRED sorts the series by: search_rank (default for a full_text search), " * series_attributes;
    elseif (endpoint == FredAPI.MyFredCategorySeriesEndpointModel || endpoint == FredAPI.MyFredReleaseSeriesEndpointModel ||
        endpoint == FredAPI.MyFredTagsSeriesEndpointModel)
        return "Attribute that FRED sorts the series by: " * series_attributes * " (default: series_id)";
    end

    # the endpoints that return releases, release dates, or sources -
    if (endpoint == FredAPI.MyFredReleasesEndpointModel || endpoint == FredAPI.MyFredSourceReleasesEndpointModel)
        return "Attribute that FRED sorts the releases by: release_id (default), name, press_release, realtime_start, or realtime_end";
    elseif (endpoint == FredAPI.MyFredReleasesDatesEndpointModel)
        return "Attribute that FRED sorts the release dates by: release_date (default), release_id, or release_name";
    elseif (endpoint == FredAPI.MyFredSourcesEndpointModel)
        return "Attribute that FRED sorts the sources by: source_id (default), name, realtime_start, or realtime_end";
    end

    # every other endpoint with an order_by argument returns tags -
    return "Attribute that FRED sorts the tags by: series_count (default), popularity, created, name, or group_id";
end

# The description of an argument, which the language model reads in the input schema. Most arguments mean the same
# thing at every endpoint. Some arguments mean different things at different endpoints, so they come first -
function _argument_description(name::String, endpoint::Type{T})::String where T <: FredAPI.AbstractFredEndpointModel

    # the endpoints that return tags, and the endpoints that return release dates -
    tag_endpoints = [FredAPI.MyFredSeriesSearchTagsEndpointModel, FredAPI.MyFredCategoryTagsEndpointModel,
        FredAPI.MyFredReleaseTagsEndpointModel, FredAPI.MyFredTagsEndpointModel];
    date_endpoints = [FredAPI.MyFredReleasesDatesEndpointModel, FredAPI.MyFredReleaseDatesEndpointModel];
    maps_endpoints = [FredAPI.MyFredMapsSeriesGroupEndpointModel, FredAPI.MyFredMapsSeriesDataEndpointModel];

    # the arguments whose meaning depends on the endpoint -
    if (name == "order_by")
        return _order_by_description(endpoint);
    elseif (name == "search_text" && endpoint != FredAPI.MyFredSeriesSearchEndpointModel)
        return "Words to match against the names and notes of the tags";
    elseif (name == "filter_value" && endpoint == FredAPI.MyFredSeriesUpdatesEndpointModel)
        return "Kind of series to return: macro (macroeconomic), regional, or all (default)";
    elseif (name == "units" && endpoint == FredAPI.MyFredMapsRegionalDataEndpointModel)
        return "Units of the data as text, e.g., Dollars";
    elseif (name == "tag_names" && (endpoint in tag_endpoints) == true)
        return "Tag names to return, separated by semicolons, e.g., monthly;usa. Leave it out to return every tag";
    elseif (name == "tag_group_id" && endpoint == FredAPI.MyFredTagsEndpointModel)
        return "Group of tags to return: freq (frequency), gen (general or concept), geo (geography), " *
            "geot (geography type), rls (release), seas (seasonal adjustment), src (source), or cc (citation and copyright)";
    elseif (name == "series_id" && (endpoint in maps_endpoints) == true)
        return "FRED identifier of a series with regional data, e.g., WIPCPI for the per capita personal income of Wisconsin";
    elseif (name == "realtime_start" && (endpoint in date_endpoints) == true)
        return "First day of the period of release dates to return, written as YYYY-MM-DD";
    elseif (name == "realtime_end" && (endpoint in date_endpoints) == true)
        return "Last day of the period of release dates to return, written as YYYY-MM-DD (default: 9999-12-31)";
    end

    # the arguments that mean the same thing at every endpoint -
    descriptions = Dict{String,String}();
    descriptions["series_id"] = "FRED series identifier, e.g., DHHNGSP for the Henry Hub natural gas spot price";
    descriptions["realtime_start"] = "First day of the real-time period, written as YYYY-MM-DD. The real-time period " *
        "selects the vintage of the data, i.e., the data as it stood on those days";
    descriptions["realtime_end"] = "Last day of the real-time period, written as YYYY-MM-DD";
    descriptions["limit"] = "Largest number of results to return";
    descriptions["offset"] = "Number of results to skip, to page through a long list (default: 0)";
    descriptions["sort_order"] = "Order of the results: asc (ascending) or desc (descending)";
    descriptions["observation_start"] = "First observation date, written as YYYY-MM-DD";
    descriptions["observation_end"] = "Last observation date, written as YYYY-MM-DD";
    descriptions["units"] = "Transformation of the values: lin (levels, default), chg (change), ch1 (change from a year ago), " *
        "pch (percent change), pc1 (percent change from a year ago), pca (compounded annual rate of change), " *
        "cch (continuously compounded rate of change), cca (continuously compounded annual rate of change), or log (natural log)";
    descriptions["frequency"] = "Frequency of the values: d (daily), w (weekly), bw (biweekly), m (monthly), q (quarterly), " *
        "sa (semiannual), or a (annual). FRED can lower the frequency of a series, but cannot raise it";
    descriptions["aggregation_method"] = "How FRED combines the values when it lowers the frequency: avg (average, default), " *
        "sum, or eop (end of period)";
    descriptions["output_type"] = "Layout of the observations: 1 (by real-time period, default), 2 (all observations by " *
        "vintage date), 3 (new and revised observations by vintage date), or 4 (initial release only)";
    descriptions["vintage_dates"] = "Vintage dates, written as YYYY-MM-DD and separated by commas, e.g., 2024-01-01,2024-06-01";
    descriptions["search_text"] = "Words to search for, e.g., Henry Hub natural gas spot price";
    descriptions["search_type"] = "What the search text matches: full_text (default) or series_id";
    descriptions["filter_variable"] = "Attribute of a series to filter by: frequency, units, or seasonal_adjustment. " *
        "Set it together with filter_value";
    descriptions["filter_value"] = "Value of filter_variable to keep, e.g., Monthly for the frequency";
    descriptions["tag_names"] = "Tag names that every series must carry, separated by semicolons, e.g., monthly;usa";
    descriptions["exclude_tag_names"] = "Tag names that no series may carry, separated by semicolons. Set it together with tag_names";
    descriptions["series_search_text"] = "Words that select the series, e.g., natural gas";
    descriptions["tag_group_id"] = "Group of tags to return: freq (frequency), gen (general or concept), geo (geography), " *
        "geot (geography type), rls (release), seas (seasonal adjustment), or src (source)";
    descriptions["tag_search_text"] = "Words to match against the names and notes of the tags";
    descriptions["start_time"] = "Start of the time window of the last update, written as YYYYMMDDHhmm. Set it together with end_time";
    descriptions["end_time"] = "End of the time window of the last update, written as YYYYMMDDHhmm. Set it together with start_time";
    descriptions["category_id"] = "FRED category identifier, e.g., 125. Category 0 is the root of the category tree";
    descriptions["include_release_dates_with_no_data"] = "Whether to include the release dates that have no data (default: false)";
    descriptions["release_id"] = "FRED release identifier, e.g., 53 for the Gross Domestic Product release";
    descriptions["element_id"] = "Element of the release table to start from, e.g., 12886. Leave it out for the whole table";
    descriptions["include_observation_values"] = "Whether to include the observation values of the series in the table (default: false)";
    descriptions["observation_date"] = "Date of the observation values, written as YYYY-MM-DD (default: the latest observation)";
    descriptions["source_id"] = "FRED source identifier, e.g., 1 for the Board of Governors of the Federal Reserve System";
    descriptions["shape"] = "Type of region: bea, msa, frb, necta, state, country, county, censusregion, or censusdivision";
    descriptions["date"] = "Date of the data, written as YYYY-MM-DD. With start_date, the last date of a range of dates";
    descriptions["start_date"] = "First date of a range of dates, written as YYYY-MM-DD. Set it together with date";
    descriptions["series_group"] = "Identifier of a series group, e.g., 882. The get_maps_series_group tool returns it";
    descriptions["region_type"] = "Type of region: bea, msa, frb, necta, state, country, county, or censusregion";
    descriptions["season"] = "Seasonal adjustment of the data: SA, NSA, SSA, SAAR, or NSAAR";
    descriptions["transformation"] = "Transformation of the data: lin (levels, default), chg, ch1, pch, pc1, pca, cch, cca, or log";
    descriptions["next_cursor"] = "The next_cursor value of the previous response, which selects the next page. " *
        "Leave it out on the first request";
    return descriptions[name];
end

# The input schema of a tool: one property for each argument of its endpoint, with the JSON type of the field -
function _input_schema(endpoint::Type{T}, required::Array{String,1})::Dict{String,Any} where T <: FredAPI.AbstractFredEndpointModel

    # one property for each argument. The JSON type follows the Julia type of the field -
    properties = Dict{String,Any}();
    for name ∈ _argument_names(endpoint)
        field_type = fieldtype(endpoint, Symbol(name));
        property = Dict{String,Any}();
        if (field_type == String)
            property["type"] = "string";
        elseif (field_type == Int64)
            property["type"] = "integer";
        elseif (field_type == Bool)
            property["type"] = "boolean";
        end
        property["description"] = _argument_description(name, endpoint);
        properties[name] = property;
    end

    # the schema. No other argument is allowed, and the required arguments must be there -
    schema = Dict{String,Any}();
    schema["type"] = "object";
    schema["properties"] = properties;
    schema["required"] = required;
    schema["additionalProperties"] = false;
    return schema;
end

# Build one FRED tool: its name, its description, its input schema, and its handler -
function _fred_tool(name::String, description::String, endpoint::Type{T}, required::Array{String,1},
    handler::Function)::MyMCPToolModel where T <: FredAPI.AbstractFredEndpointModel

    tool = build(MyMCPToolModel, (
        name = name,
        description = description,
        inputschema = _input_schema(endpoint, required),
        handler = handler));
    return tool;
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #
