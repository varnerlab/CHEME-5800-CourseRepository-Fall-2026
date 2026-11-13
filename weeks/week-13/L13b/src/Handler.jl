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
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
