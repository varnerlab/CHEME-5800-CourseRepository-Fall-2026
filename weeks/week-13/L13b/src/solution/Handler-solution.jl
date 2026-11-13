# =============================================================================
# CHEME 5800 | L13b reference solution: the functions that process the responses
# =============================================================================
# The completed observations handler. Apart from this header, the TODO comments,
# and the completed lines, it matches the student file, Handler.jl, so either file
# can be loaded into the L13bFRED module in place of the other.
# =============================================================================
# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
"""
Private default handler that parses the JSON response string from the FRED API.
Looks up the function that processes the response for the endpoint model type, and calls that function.
Returns the parsed response (a dictionary), or `nothing` if the model type is unrecognized.
"""
function _default_handler_process_fred_response(model::Type{T},
    response::String) where T <: AbstractFredEndpointModel

    # initialize -
    type_handler_dict = Dict{Any,Function}()

    # hardcode the response handler -
    type_handler_dict[MyFredSeriesSearchEndpointModel] = (x::String) -> JSON.parse(x) # default handler
    type_handler_dict[MyFredSeriesEndpointModel] = (x::String) -> JSON.parse(x) # default handler
    type_handler_dict[MyFredSeriesObservationsEndpointModel] = (x::String) -> JSON.parse(x) # default handler

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
    process_search_response_dataframe(model::Type{T}, response::String) -> DataFrame where T <: AbstractFredEndpointModel

Process the JSON response string from the `fred/series/search` endpoint of the FRED API.
We parse the response string, select six fields from each series, and return them as a `DataFrame`.

### Arguments
- `model::Type{T}`: the endpoint model type. Must be a subtype of `AbstractFredEndpointModel`.
- `response::String`: the JSON response string from the `fred/series/search` endpoint.

### Returns
- `DataFrame`: a table with one row for each series. The columns are `id`, `title`, `frequency`, `units`,
  `observation_start`, and `observation_end`. If the search matched no series, the table is empty.
"""
function process_search_response_dataframe(model::Type{T}, response::String)::DataFrame where T <: AbstractFredEndpointModel

    # initialize: one array for each column of the table -
    ids = Array{String,1}();
    titles = Array{String,1}();
    frequencies = Array{String,1}();
    units = Array{String,1}();
    observation_starts = Array{String,1}();
    observation_ends = Array{String,1}();

    # parse the response. FRED spells the key of the list of series with a double s: "seriess" -
    response_dict = JSON.parse(response);
    for data ∈ response_dict["seriess"]

        # Notice: we are selecting the keys we want from the JSON response, and returning them in the order we want.
        # This is a form of data transformation and cleaning. We only give the user the data they need.
        push!(ids, data["id"]);
        push!(titles, data["title"]);
        push!(frequencies, data["frequency"]);
        push!(units, data["units"]);
        push!(observation_starts, data["observation_start"]);
        push!(observation_ends, data["observation_end"]);
    end

    # put the six columns into a table, and return it -
    dataframe = DataFrame(id = ids, title = titles, frequency = frequencies, units = units,
        observation_start = observation_starts, observation_end = observation_ends);
    return dataframe
end

"""
    process_observations_response_dataframe(model::Type{T}, response::String) -> DataFrame where T <: AbstractFredEndpointModel

Process the JSON response string from the `fred/series/observations` endpoint of the FRED API.
We parse the response string, convert the date and the value of each observation, and return them as a `DataFrame`.

The response is a JSON object. Its `"observations"` key holds an array with one object for each observation.
FRED sends the date and the value of an observation as text:
- The `"date"` key holds the date as text, e.g., `"2025-01-02"`. Converting this text to a `Date` is TODO 2.
- The `"value"` key holds the value as text, e.g., `"3.65"`. Converting this text to a `Float64` is TODO 3.
- When FRED has no value for a date, e.g., a holiday in a daily series, the `"value"` key holds a period, `"."`.
  We store `missing` for that observation.

### Arguments
- `model::Type{T}`: the endpoint model type. Must be a subtype of `AbstractFredEndpointModel`.
- `response::String`: the JSON response string from the `fred/series/observations` endpoint.

### Returns
- `DataFrame`: a table with one row for each observation, in the order of the response. The columns are:
    - `date::Date`: the date of the observation.
    - `value::Union{Missing,Float64}`: the value of the observation, or `missing` when FRED has no value for the date.

  If the response has no observations, the table is empty.

### Throws
- `ErrorException`: when TODO 2 or TODO 3 is not complete.

### Example
```julia
url = build("https://api.stlouisfed.org", model);
table = MyFredSeriesObservationsEndpointModel(url; handler = process_observations_response_dataframe);
```
"""
function process_observations_response_dataframe(model::Type{T}, response::String)::DataFrame where T <: AbstractFredEndpointModel

    # initialize; this part is complete -
    dates = Array{Date,1}(); # the date of each observation
    observation_values = Array{Union{Missing,Float64},1}(); # the value of each observation: a number, or missing
    message = "Oooops! The `process_observations_response_dataframe(...)` function is not implemented yet - " *
        "we'd better fix that. Complete TODO 2 and TODO 3 in src/Handler.jl.";

    # parse the response, and visit the observations one at a time. This part is complete -
    response_dict = JSON.parse(response);
    for data ∈ response_dict["observations"]

        # get the date and the value of this observation as text. This part is complete -
        date_string = data["date"]; # e.g., "2025-01-02"
        value_string = data["value"]; # e.g., "3.65", or "." when FRED has no value for this date

        # TODO 2: the date as a Date -
        date = Date(date_string);
        if (isnothing(date) == true) # this part is complete: a blank TODO 2 leaves nothing behind
            throw(ErrorException(message));
        end

        # The value starts as missing, and stays missing when FRED sent a period. This part is complete -
        value = missing;
        if (value_string != ".")
            # TODO 3: the value as a Float64 -
            value = parse(Float64, value_string);
        end
        if (isnothing(value) == true) # this part is complete: a blank TODO 3 leaves nothing behind
            throw(ErrorException(message));
        end

        # store the date and the value of this observation. This part is complete -
        push!(dates, date);
        push!(observation_values, value);
    end

    # put the two columns into a table, and return it -
    dataframe = DataFrame(date = dates, value = observation_values);
    return dataframe
end

# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
