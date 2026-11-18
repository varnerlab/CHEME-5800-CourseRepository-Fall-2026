# =============================================================================
# CHEME 5800 | L13d FRED server: the 36 tools
# =============================================================================
# One tool for each endpoint of the FRED API, in the order of the FRED
# documentation: series, categories, releases, sources, tags, maps, and
# version 2. Each tool has a handler in this file and one entry in
# build_fred_server(...) at the bottom of the file.
#
# Every handler takes the same two arguments and returns the same kind of result:
#   - arguments::AbstractDict, the arguments of the call, named after the fields
#     of the endpoint model, e.g., "series_id" for MyFredSeriesEndpointModel.
#   - configuration::AbstractDict, the configuration of the server, with the
#     keys baseurl and apikey.
#   - It returns the JSON response of FRED as a Dict{String,Any}, and it throws
#     an ArgumentError when an argument is wrong, when FRED answers with an
#     error, or when the result is longer than the server returns.
# =============================================================================

# --- SERIES TOOLS BELOW HERE ---------------------------------------------------------------------------------- #
"""
    get_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series` tool, for the `fred/series` endpoint: the description of one series.
"""
function get_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesEndpointModel, arguments, configuration);
end

"""
    get_series_categories(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_categories` tool, for the `fred/series/categories` endpoint: the categories of one series.
"""
function get_series_categories(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesCategoriesEndpointModel, arguments, configuration);
end

"""
    get_series_observations(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_observations` tool, for the `fred/series/observations` endpoint: the observations
(the dates and values) of one series.
"""
function get_series_observations(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesObservationsEndpointModel, arguments, configuration);
end

"""
    get_series_release(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_release` tool, for the `fred/series/release` endpoint: the release that publishes one series.
"""
function get_series_release(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesReleaseEndpointModel, arguments, configuration);
end

"""
    search_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `search_series` tool, for the `fred/series/search` endpoint: the series that match a search text.
"""
function search_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesSearchEndpointModel, arguments, configuration);
end

"""
    search_series_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `search_series_tags` tool, for the `fred/series/search/tags` endpoint: the tags of the series that
match a search text.
"""
function search_series_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesSearchTagsEndpointModel, arguments, configuration);
end

"""
    search_series_related_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `search_series_related_tags` tool, for the `fred/series/search/related_tags` endpoint: the tags that
are related to a set of tags, among the series that match a search text.
"""
function search_series_related_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesSearchRelatedTagsEndpointModel, arguments, configuration);
end

"""
    get_series_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_tags` tool, for the `fred/series/tags` endpoint: the tags of one series.
"""
function get_series_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesTagsEndpointModel, arguments, configuration);
end

"""
    get_series_updates(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_updates` tool, for the `fred/series/updates` endpoint: the series that FRED updated most
recently.
"""
function get_series_updates(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesUpdatesEndpointModel, arguments, configuration);
end

"""
    get_series_vintage_dates(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_series_vintage_dates` tool, for the `fred/series/vintagedates` endpoint: the dates on which FRED
revised the data of one series, or added data to it.
"""
function get_series_vintage_dates(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSeriesVintageDatesEndpointModel, arguments, configuration);
end
# --- SERIES TOOLS ABOVE HERE ---------------------------------------------------------------------------------- #

# --- CATEGORY TOOLS BELOW HERE -------------------------------------------------------------------------------- #
"""
    get_category(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category` tool, for the `fred/category` endpoint: one category.
"""
function get_category(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategoryEndpointModel, arguments, configuration);
end

"""
    get_category_children(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category_children` tool, for the `fred/category/children` endpoint: the child categories of
one category.
"""
function get_category_children(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategoryChildrenEndpointModel, arguments, configuration);
end

"""
    get_category_related(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category_related` tool, for the `fred/category/related` endpoint: the categories that are
related to one category.
"""
function get_category_related(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategoryRelatedEndpointModel, arguments, configuration);
end

"""
    get_category_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category_series` tool, for the `fred/category/series` endpoint: the series of one category.
"""
function get_category_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategorySeriesEndpointModel, arguments, configuration);
end

"""
    get_category_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category_tags` tool, for the `fred/category/tags` endpoint: the tags of the series of one category.
"""
function get_category_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategoryTagsEndpointModel, arguments, configuration);
end

"""
    get_category_related_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_category_related_tags` tool, for the `fred/category/related_tags` endpoint: the tags that are
related to a set of tags, among the series of one category.
"""
function get_category_related_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredCategoryRelatedTagsEndpointModel, arguments, configuration);
end
# --- CATEGORY TOOLS ABOVE HERE -------------------------------------------------------------------------------- #

# --- RELEASE TOOLS BELOW HERE --------------------------------------------------------------------------------- #
"""
    get_releases(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_releases` tool, for the `fred/releases` endpoint: every release of economic data.
"""
function get_releases(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleasesEndpointModel, arguments, configuration);
end

"""
    get_releases_dates(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_releases_dates` tool, for the `fred/releases/dates` endpoint: the release dates of every release.
"""
function get_releases_dates(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleasesDatesEndpointModel, arguments, configuration);
end

"""
    get_release(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release` tool, for the `fred/release` endpoint: one release of economic data.
"""
function get_release(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseEndpointModel, arguments, configuration);
end

"""
    get_release_dates(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_dates` tool, for the `fred/release/dates` endpoint: the release dates of one release.
"""
function get_release_dates(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseDatesEndpointModel, arguments, configuration);
end

"""
    get_release_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_series` tool, for the `fred/release/series` endpoint: the series of one release.
"""
function get_release_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseSeriesEndpointModel, arguments, configuration);
end

"""
    get_release_sources(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_sources` tool, for the `fred/release/sources` endpoint: the sources of the data of
one release.
"""
function get_release_sources(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseSourcesEndpointModel, arguments, configuration);
end

"""
    get_release_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_tags` tool, for the `fred/release/tags` endpoint: the tags of the series of one release.
"""
function get_release_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseTagsEndpointModel, arguments, configuration);
end

"""
    get_release_related_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_related_tags` tool, for the `fred/release/related_tags` endpoint: the tags that are
related to a set of tags, among the series of one release.
"""
function get_release_related_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseRelatedTagsEndpointModel, arguments, configuration);
end

"""
    get_release_tables(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_tables` tool, for the `fred/release/tables` endpoint: the elements of the table of
one release.
"""
function get_release_tables(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredReleaseTablesEndpointModel, arguments, configuration);
end
# --- RELEASE TOOLS ABOVE HERE --------------------------------------------------------------------------------- #

# --- SOURCE TOOLS BELOW HERE ---------------------------------------------------------------------------------- #
"""
    get_sources(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_sources` tool, for the `fred/sources` endpoint: every source of economic data.
"""
function get_sources(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSourcesEndpointModel, arguments, configuration);
end

"""
    get_source(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_source` tool, for the `fred/source` endpoint: one source of economic data.
"""
function get_source(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSourceEndpointModel, arguments, configuration);
end

"""
    get_source_releases(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_source_releases` tool, for the `fred/source/releases` endpoint: the releases of one source.
"""
function get_source_releases(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredSourceReleasesEndpointModel, arguments, configuration);
end
# --- SOURCE TOOLS ABOVE HERE ---------------------------------------------------------------------------------- #

# --- TAG TOOLS BELOW HERE ------------------------------------------------------------------------------------- #
"""
    get_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_tags` tool, for the `fred/tags` endpoint: the tags of FRED.
"""
function get_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredTagsEndpointModel, arguments, configuration);
end

"""
    get_related_tags(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_related_tags` tool, for the `fred/related_tags` endpoint: the other tags of the series that carry
a set of tags.
"""
function get_related_tags(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredRelatedTagsEndpointModel, arguments, configuration);
end

"""
    get_tags_series(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_tags_series` tool, for the `fred/tags/series` endpoint: the series that carry every tag in a
set of tags.
"""
function get_tags_series(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredTagsSeriesEndpointModel, arguments, configuration);
end
# --- TAG TOOLS ABOVE HERE ------------------------------------------------------------------------------------- #

# --- MAPS TOOLS BELOW HERE ------------------------------------------------------------------------------------ #
"""
    get_maps_shapes(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_maps_shapes` tool, for the `geofred/shapes/file` endpoint: the regions of one shape type.

This is the one handler that changes the response of FRED. The response holds the boundary of each region as a
long list of coordinates, which a language model cannot use. The handler keeps the name and the codes of each region.
"""
function get_maps_shapes(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # call FRED. The response is GeoJSON text: a list of features, one for each region -
    response = _fetch(FredAPI.MyFredMapsShapesEndpointModel, arguments, configuration);

    # keep the properties of each region, i.e., its name and its codes, and leave out its boundary -
    regions = Array{Any,1}();
    for feature ∈ response["features"]
        push!(regions, feature["properties"]);
    end

    # the result, checked for its length -
    result = Dict{String,Any}();
    result["title"] = get(response, "title", "");
    result["regions"] = regions;
    return _check_length(result);
end

"""
    get_maps_series_group(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_maps_series_group` tool, for the `geofred/series/group` endpoint: the series group of a
regional series.
"""
function get_maps_series_group(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredMapsSeriesGroupEndpointModel, arguments, configuration);
end

"""
    get_maps_series_data(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_maps_series_data` tool, for the `geofred/series/data` endpoint: the value of a regional series
in each region.
"""
function get_maps_series_data(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredMapsSeriesDataEndpointModel, arguments, configuration);
end

"""
    get_maps_regional_data(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_maps_regional_data` tool, for the `geofred/regional/data` endpoint: the value of a series group
in each region of one region type.
"""
function get_maps_regional_data(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredMapsRegionalDataEndpointModel, arguments, configuration);
end
# --- MAPS TOOLS ABOVE HERE ------------------------------------------------------------------------------------ #

# --- VERSION 2 TOOLS BELOW HERE ------------------------------------------------------------------------------- #
"""
    get_release_observations(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_release_observations` tool, for the `fred/v2/release/observations` endpoint: the observations of
every series in one release, one page at a time.
"""
function get_release_observations(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}
    return _call_fred(FredAPI.MyFredV2ReleaseObservationsEndpointModel, arguments, configuration);
end
# --- VERSION 2 TOOLS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    build_fred_server(configuration::Dict{String,Any}) -> MyMCPServerModel

Build the FRED server: its identity, its 36 tools, and its configuration.

Each tool gets a name, a description, an endpoint model, the list of its required arguments, and a handler.
The `_fred_tool(...)` function in [src/Tools.jl](Tools.jl) builds the input schema of the tool from the fields of
the endpoint model.

### Arguments
- `configuration::Dict{String,Any}`: the configuration of the server, with the keys `baseurl` and `apikey`, or the
  key `setup_error` when the server could not read its configuration file.

### Returns
- `MyMCPServerModel`: the server, with one tool for each endpoint of the FRED API.
"""
function build_fred_server(configuration::Dict{String,Any})::MyMCPServerModel

    # initialize -
    tools = Array{MyMCPToolModel,1}();

    # the series tools -
    push!(tools, _fred_tool("get_series",
        "Get the description of one FRED series: its title, units, frequency, seasonal adjustment, and date range.",
        FredAPI.MyFredSeriesEndpointModel, ["series_id"], get_series));
    push!(tools, _fred_tool("get_series_categories",
        "Get the categories that hold one FRED series.",
        FredAPI.MyFredSeriesCategoriesEndpointModel, ["series_id"], get_series_categories));
    push!(tools, _fred_tool("get_series_observations",
        "Get the observations (the dates and values) of one FRED series. FRED can transform the values, e.g., to " *
        "percent change, and lower their frequency, e.g., from daily to monthly.",
        FredAPI.MyFredSeriesObservationsEndpointModel, ["series_id"], get_series_observations));
    push!(tools, _fred_tool("get_series_release",
        "Get the release of economic data that publishes one FRED series.",
        FredAPI.MyFredSeriesReleaseEndpointModel, ["series_id"], get_series_release));
    push!(tools, _fred_tool("search_series",
        "Search FRED for the series that match a search text. Use this tool first to find the identifier of a series.",
        FredAPI.MyFredSeriesSearchEndpointModel, ["search_text"], search_series));
    push!(tools, _fred_tool("search_series_tags",
        "Get the tags of the FRED series that match a search text.",
        FredAPI.MyFredSeriesSearchTagsEndpointModel, ["series_search_text"], search_series_tags));
    push!(tools, _fred_tool("search_series_related_tags",
        "Get the tags that are related to a set of tags, among the FRED series that match a search text.",
        FredAPI.MyFredSeriesSearchRelatedTagsEndpointModel, ["series_search_text", "tag_names"], search_series_related_tags));
    push!(tools, _fred_tool("get_series_tags",
        "Get the tags of one FRED series.",
        FredAPI.MyFredSeriesTagsEndpointModel, ["series_id"], get_series_tags));
    push!(tools, _fred_tool("get_series_updates",
        "Get the FRED series that FRED updated most recently, newest first.",
        FredAPI.MyFredSeriesUpdatesEndpointModel, String[], get_series_updates));
    push!(tools, _fred_tool("get_series_vintage_dates",
        "Get the dates on which FRED revised the data of one series, or added data to it.",
        FredAPI.MyFredSeriesVintageDatesEndpointModel, ["series_id"], get_series_vintage_dates));

    # the category tools -
    push!(tools, _fred_tool("get_category",
        "Get one FRED category: its identifier, name, and parent category.",
        FredAPI.MyFredCategoryEndpointModel, String[], get_category));
    push!(tools, _fred_tool("get_category_children",
        "Get the child categories of one FRED category. Start at category 0, the root, to browse the category tree.",
        FredAPI.MyFredCategoryChildrenEndpointModel, String[], get_category_children));
    push!(tools, _fred_tool("get_category_related",
        "Get the categories that are related to one FRED category. Most categories have no related categories.",
        FredAPI.MyFredCategoryRelatedEndpointModel, ["category_id"], get_category_related));
    push!(tools, _fred_tool("get_category_series",
        "Get the series that belong to one FRED category.",
        FredAPI.MyFredCategorySeriesEndpointModel, ["category_id"], get_category_series));
    push!(tools, _fred_tool("get_category_tags",
        "Get the tags of the series that belong to one FRED category.",
        FredAPI.MyFredCategoryTagsEndpointModel, ["category_id"], get_category_tags));
    push!(tools, _fred_tool("get_category_related_tags",
        "Get the tags that are related to a set of tags, among the series of one FRED category.",
        FredAPI.MyFredCategoryRelatedTagsEndpointModel, ["category_id", "tag_names"], get_category_related_tags));

    # the release tools -
    push!(tools, _fred_tool("get_releases",
        "Get every release of economic data in FRED: its identifier, its name, and whether it is a press release.",
        FredAPI.MyFredReleasesEndpointModel, String[], get_releases));
    push!(tools, _fred_tool("get_releases_dates",
        "Get the release dates of every release of economic data in FRED, newest first.",
        FredAPI.MyFredReleasesDatesEndpointModel, String[], get_releases_dates));
    push!(tools, _fred_tool("get_release",
        "Get one release of economic data: its identifier, its name, and whether it is a press release.",
        FredAPI.MyFredReleaseEndpointModel, ["release_id"], get_release));
    push!(tools, _fred_tool("get_release_dates",
        "Get the release dates of one release of economic data.",
        FredAPI.MyFredReleaseDatesEndpointModel, ["release_id"], get_release_dates));
    push!(tools, _fred_tool("get_release_series",
        "Get the series that belong to one release of economic data.",
        FredAPI.MyFredReleaseSeriesEndpointModel, ["release_id"], get_release_series));
    push!(tools, _fred_tool("get_release_sources",
        "Get the sources of the data of one release of economic data.",
        FredAPI.MyFredReleaseSourcesEndpointModel, ["release_id"], get_release_sources));
    push!(tools, _fred_tool("get_release_tags",
        "Get the tags of the series that belong to one release of economic data.",
        FredAPI.MyFredReleaseTagsEndpointModel, ["release_id"], get_release_tags));
    push!(tools, _fred_tool("get_release_related_tags",
        "Get the tags that are related to a set of tags, among the series of one release of economic data.",
        FredAPI.MyFredReleaseRelatedTagsEndpointModel, ["release_id", "tag_names"], get_release_related_tags));
    push!(tools, _fred_tool("get_release_tables",
        "Get the table of one release of economic data, e.g., the table of the Gross Domestic Product release. " *
        "Each element of the table is a section or a series, and an element can have children.",
        FredAPI.MyFredReleaseTablesEndpointModel, ["release_id"], get_release_tables));

    # the source tools -
    push!(tools, _fred_tool("get_sources",
        "Get every source of economic data in FRED, e.g., the Bureau of Labor Statistics.",
        FredAPI.MyFredSourcesEndpointModel, String[], get_sources));
    push!(tools, _fred_tool("get_source",
        "Get one source of economic data: its identifier, its name, and, when FRED has them, its link and notes.",
        FredAPI.MyFredSourceEndpointModel, ["source_id"], get_source));
    push!(tools, _fred_tool("get_source_releases",
        "Get the releases of economic data that one source publishes.",
        FredAPI.MyFredSourceReleasesEndpointModel, ["source_id"], get_source_releases));

    # the tag tools -
    push!(tools, _fred_tool("get_tags",
        "Get the tags of FRED. A tag is a word that describes a series, e.g., its frequency or its geography.",
        FredAPI.MyFredTagsEndpointModel, String[], get_tags));
    push!(tools, _fred_tool("get_related_tags",
        "Get the other tags that the FRED series with a set of tags also carry.",
        FredAPI.MyFredRelatedTagsEndpointModel, ["tag_names"], get_related_tags));
    push!(tools, _fred_tool("get_tags_series",
        "Get the FRED series that carry every tag in a set of tags.",
        FredAPI.MyFredTagsSeriesEndpointModel, ["tag_names"], get_tags_series));

    # the maps tools -
    push!(tools, _fred_tool("get_maps_shapes",
        "Get the regions of one shape type, e.g., the states, with the name and the codes of each region. " *
        "The tool leaves out the boundaries of the regions.",
        FredAPI.MyFredMapsShapesEndpointModel, ["shape"], get_maps_shapes));
    push!(tools, _fred_tool("get_maps_series_group",
        "Get the series group of a regional FRED series: its title, region type, seasonal adjustment, units, " *
        "frequency, and date range.",
        FredAPI.MyFredMapsSeriesGroupEndpointModel, ["series_id"], get_maps_series_group));
    push!(tools, _fred_tool("get_maps_series_data",
        "Get the value of a regional FRED series in each region, on one date or over a range of dates.",
        FredAPI.MyFredMapsSeriesDataEndpointModel, ["series_id"], get_maps_series_data));
    push!(tools, _fred_tool("get_maps_regional_data",
        "Get the value of a series group in each region of one region type, on one date or over a range of dates.",
        FredAPI.MyFredMapsRegionalDataEndpointModel, ["series_group", "region_type", "date", "season", "units"],
        get_maps_regional_data));

    # the version 2 tool -
    push!(tools, _fred_tool("get_release_observations",
        "Get the observations of every series in one release of economic data, one page at a time. Use a small " *
        "limit, and pass the next_cursor value of a response to get the next page.",
        FredAPI.MyFredV2ReleaseObservationsEndpointModel, ["release_id"], get_release_observations));

    # the server -
    server = build(MyMCPServerModel, (
        name = "cheme-5800-fred",
        version = "2.0.0",
        instructions = "Economic data from FRED (Federal Reserve Economic Data), with one tool for each endpoint " *
            "of the FRED API. Use search_series to find the identifier of a series, then get_series_observations " *
            "to download its values. To browse, start with get_category_children at category 0, get_releases, " *
            "get_sources, or get_tags. Each result is the JSON response of FRED, and the server returns at most " *
            "$(MAX_RESULT_CHARACTERS) characters: when a tool reports a longer result, ask for fewer results.",
        tools = tools,
        configuration = configuration));
    return server;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
