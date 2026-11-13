# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
"""
Private default handler that parses the JSON response string from the National Weather Service (NWS) API.
Looks up the function that processes the response for the endpoint model type, and calls that function.
Returns the parsed response (a dictionary), or `nothing` if the model type is unrecognized.
"""
function _default_handler_process_weather_response(model::Type{T},
    response::String) where T <: AbstractWeatherEndpointModel

    # initialize -
    type_handler_dict = Dict{Any,Function}()

    # hardcode the response handler -
    type_handler_dict[MyWeatherGridPointEndpointModel] = (x::String) -> JSON.parse(x) # default handler
    type_handler_dict[MyWeatherForecastEndpointModel] = (x::String) -> JSON.parse(x) # default handler

    # lookup the function to handle the response -
    if (haskey(type_handler_dict, model) == true)
        handler_function = type_handler_dict[model]
        return handler_function(response);
    end

    # default: return nothing
    return nothing
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    process_forecast_response_dataframe(model::Type{T}, response::String) -> DataFrame where T <: AbstractWeatherEndpointModel

Process the JSON response string from a forecast endpoint of the National Weather Service (NWS) API.
We parse the response string, select eight fields from each forecast period, and return them as a `DataFrame`.

### Arguments
- `model::Type{T}`: the endpoint model type. Must be a subtype of `AbstractWeatherEndpointModel`.
- `response::String`: the JSON response string from a forecast endpoint of the NWS API.

### Returns
- `DataFrame`: a table with one row for each forecast period. The columns are `startTime`, `endTime`, `isDayTime`,
  `temperature`, `temperatureUnit`, `windSpeed`, `windDirection`, and `shortForecast`. If the response has no forecast periods,
  the table is empty.
"""
function process_forecast_response_dataframe(model::Type{T}, response::String)::DataFrame where T <: AbstractWeatherEndpointModel

    # initialize -
    dataframe = DataFrame();

    # parse the response -
    response_dict = JSON.parse(response);
    for data ∈ response_dict["properties"]["periods"]

        # put data into a row. This is an example of a NamedTuple
        # Notice: we are selecting the keys we want from the JSON response, and returning them in the order we want.
        # This is a form of data transformation and cleaning. We only give the user the data they need.
        row = (
            startTime = data["startTime"],
            endTime = data["endTime"],
            isDayTime = data["isDaytime"],
            temperature = data["temperature"],
            temperatureUnit = data["temperatureUnit"],
            windSpeed = data["windSpeed"],
            windDirection = data["windDirection"],
            shortForecast = data["shortForecast"]
        );
        push!(dataframe, row);
    end

    # return the dataframe -
    return dataframe
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
