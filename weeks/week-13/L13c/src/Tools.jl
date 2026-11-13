# =============================================================================
# The tools of the weather server. Each tool is a handler function, plus the
# name, description, and input schema that tell a client how to call it. The
# handlers call the National Weather Service API through the endpoint models
# and build methods of this folder.
# =============================================================================

# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
# Read the latitude and the longitude from the arguments of a call, and check them.
# A missing or wrong argument throws an ArgumentError, which the server reports as a tool execution error.
function _read_coordinates(arguments::AbstractDict)::Tuple{Float64,Float64}

    # each coordinate must be there, and must be a number -
    for key ∈ ("latitude", "longitude")
        if (haskey(arguments, key) == false)
            throw(ArgumentError("missing argument: $(key)"));
        end
        if (isa(arguments[key], Real) == false || isa(arguments[key], Bool) == true) # Julia counts true and false as numbers
            throw(ArgumentError("the $(key) must be a number of decimal degrees"));
        end
    end

    # JSON numbers can arrive as integers, e.g., 42, so we convert both coordinates to Float64 -
    latitude = Float64(arguments["latitude"]);
    longitude = Float64(arguments["longitude"]);

    # check the ranges of the coordinates -
    if (latitude < -90.0 || latitude > 90.0)
        throw(ArgumentError("the latitude must be between -90 and 90 degrees"));
    end
    if (longitude < -180.0 || longitude > 180.0)
        throw(ArgumentError("the longitude must be between -180 and 180 degrees"));
    end

    # return the coordinates -
    return (latitude, longitude);
end

# Call the points endpoint of the weather service for a location, and return the parsed response -
function _call_points_endpoint(baseurl::String, latitude::Float64, longitude::Float64)

    # build the endpoint model and the URL, then make the call. The default handler parses the JSON text -
    model = MyWeatherGridPointEndpointModel(latitude = latitude, longitude = longitude);
    url = build(baseurl, model);
    return MyWeatherGridPointEndpointModel(url);
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    get_location(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_location` tool. Find the place, the forecast office, and the forecast grid square of a location.
The weather service covers the United States and its territories.

### Arguments
- `arguments::AbstractDict`: the arguments of the call, with the keys `latitude` and `longitude` (units: decimal degrees).
- `configuration::AbstractDict`: the configuration of the server, with the key `baseurl`, the base URL of the weather service API.

### Returns
- `Dict{String,Any}`: the result, with the keys `city`, `state`, `forecast_office`, `grid_x`, `grid_y`, and `time_zone`.

### Throws
- `ArgumentError`: when an argument is missing or out of range, or when the weather service answers with an error,
  e.g., status code `404` for a location outside the United States.
"""
function get_location(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # check the arguments, then call the points endpoint -
    (latitude, longitude) = _read_coordinates(arguments);
    points = _call_points_endpoint(configuration["baseurl"], latitude, longitude);
    properties = points["properties"];
    place = properties["relativeLocation"]["properties"]; # the nearest city, and its state

    # select the fields that a language model needs, and give them plain names -
    result = Dict{String,Any}();
    result["city"] = place["city"];
    result["state"] = place["state"];
    result["forecast_office"] = properties["gridId"];
    result["grid_x"] = properties["gridX"];
    result["grid_y"] = properties["gridY"];
    result["time_zone"] = properties["timeZone"];

    # return the result -
    return result;
end

"""
    get_hourly_forecast(arguments::AbstractDict, configuration::AbstractDict) -> Dict{String,Any}

Handler of the `get_hourly_forecast` tool. Download the hourly weather forecast for a location.

### Arguments
- `arguments::AbstractDict`: the arguments of the call, with the keys `latitude` and `longitude` (units: decimal degrees),
  and the optional key `hours`, the number of hours to return, from `1` to `48` (default: `12`).
- `configuration::AbstractDict`: the configuration of the server, with the key `baseurl`, the base URL of the weather service API.

### Returns
- `Dict{String,Any}`: the result, with the keys `latitude`, `longitude`, and `periods`. The `periods` key holds one
  dictionary for each hour, with the keys `start_time`, `temperature`, `temperature_unit`, `wind_speed`,
  `wind_direction`, and `short_forecast`.

### Throws
- `ArgumentError`: when an argument is missing or out of range, or when the weather service answers with an error.
"""
function get_hourly_forecast(arguments::AbstractDict, configuration::AbstractDict)::Dict{String,Any}

    # check the arguments. The number of hours is optional -
    (latitude, longitude) = _read_coordinates(arguments);
    hours = 12; # the default number of hours
    if (haskey(arguments, "hours") == true)
        hours = arguments["hours"];
        if (isa(hours, Integer) == false || isa(hours, Bool) == true) # Julia counts true and false as whole numbers
            throw(ArgumentError("the number of hours must be a whole number"));
        end
        if (hours < 1 || hours > 48)
            throw(ArgumentError("the number of hours must be between 1 and 48"));
        end
    end

    # call the points endpoint, and read the URL of the hourly forecast from its response -
    points = _call_points_endpoint(configuration["baseurl"], latitude, longitude);
    forecast_url = points["properties"]["forecastHourly"];

    # call the forecast endpoint. The handler returns the forecast as a table with one row per hour -
    table = MyWeatherForecastEndpointModel(forecast_url; handler = process_forecast_response_dataframe);

    # put the first rows of the table into a list of dictionaries, one per hour -
    periods = Array{Dict{String,Any},1}();
    number_of_rows = min(hours, nrow(table));
    for i ∈ 1:number_of_rows
        period = Dict{String,Any}();
        period["start_time"] = table[i, :startTime];
        period["temperature"] = table[i, :temperature];
        period["temperature_unit"] = table[i, :temperatureUnit];
        period["wind_speed"] = table[i, :windSpeed];
        period["wind_direction"] = table[i, :windDirection];
        period["short_forecast"] = table[i, :shortForecast];
        push!(periods, period);
    end

    # return the result -
    result = Dict{String,Any}();
    result["latitude"] = latitude;
    result["longitude"] = longitude;
    result["periods"] = periods;
    return result;
end

"""
    build_weather_server(; baseurl::String = "https://api.weather.gov") -> MyMCPServerModel

Build the weather server: its identity, its two tools, and its configuration.

### Arguments
- `baseurl::String = "https://api.weather.gov"`: the base URL of the National Weather Service API.

### Returns
- `MyMCPServerModel`: the server, with the tools `get_location` and `get_hourly_forecast`.
"""
function build_weather_server(; baseurl::String = "https://api.weather.gov")::MyMCPServerModel

    # the input schema of both tools starts with the two coordinates -
    latitude_schema = Dict{String,Any}("type" => "number", "minimum" => -90, "maximum" => 90,
        "description" => "Latitude in decimal degrees, north is positive, e.g., 42.444 for Ithaca, NY");
    longitude_schema = Dict{String,Any}("type" => "number", "minimum" => -180, "maximum" => 180,
        "description" => "Longitude in decimal degrees, east is positive, e.g., -76.502 for Ithaca, NY");

    # the get_location tool -
    location_schema = Dict{String,Any}(
        "type" => "object",
        "properties" => Dict{String,Any}("latitude" => latitude_schema, "longitude" => longitude_schema),
        "required" => ["latitude", "longitude"]);
    location_tool = build(MyMCPToolModel, (
        name = "get_location",
        description = "Find the nearest city, the state, and the National Weather Service forecast office of a location in the United States.",
        inputschema = location_schema,
        handler = get_location));

    # the get_hourly_forecast tool. The number of hours is optional, so it is not in the required list -
    hours_schema = Dict{String,Any}("type" => "integer", "minimum" => 1, "maximum" => 48,
        "description" => "Number of hours to return, starting now (default: 12)");
    forecast_schema = Dict{String,Any}(
        "type" => "object",
        "properties" => Dict{String,Any}("latitude" => latitude_schema, "longitude" => longitude_schema, "hours" => hours_schema),
        "required" => ["latitude", "longitude"]);
    forecast_tool = build(MyMCPToolModel, (
        name = "get_hourly_forecast",
        description = "Get the hourly weather forecast for a location in the United States from the National Weather Service: temperature, wind, and a short forecast for each hour.",
        inputschema = forecast_schema,
        handler = get_hourly_forecast));

    # the server -
    server = build(MyMCPServerModel, (
        name = "cheme-5800-weather",
        version = "1.0.0",
        instructions = "Weather data for locations in the United States from the National Weather Service. " *
            "Give each location as a latitude and a longitude in decimal degrees.",
        tools = [location_tool, forecast_tool],
        configuration = Dict{String,Any}("baseurl" => baseurl)));
    return server;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
