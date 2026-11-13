# =============================================================================
# CHEME 5800 | L13b reference solution: the FRED observations endpoint
# =============================================================================
# The completed build(...) method and process_observations_response_dataframe(...)
# handler. Apart from this header, the TODO comments, and the completed lines, it
# matches the student file, Compute.jl, and it uses the same module name, so either
# file can be loaded in place of the other. The notebook has no other exercise answers.
# =============================================================================
module L13bObservations

import JSON # parse the JSON text that FRED returns
import Dates: Date # the type of a calendar date
import DataFrames: DataFrame # table for the observations
import VLDataScienceMachineLearningPackage: build # extend the course factory interface
import ..L13bFRED: AbstractFredEndpointModel # the base type of the endpoint models, from src/Types.jl
import ..L13bFRED: MyFredSeriesObservationsEndpointModel # the model of the observations endpoint, from src/Types.jl

export process_observations_response_dataframe

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

FRED reads each parameter by its key, so the order of the parameters does not matter. Writing the URL string is TODO 1.

### Arguments
- `base::String`: the base URL of the FRED API, i.e., `"https://api.stlouisfed.org"`.
- `model::MyFredSeriesObservationsEndpointModel`: the endpoint model that holds the API key, the series identifier,
  the first and last date, the frequency, and the units.

### Returns
- `String`: the complete URL string. The URL holds the API key, so do not print it or share it.

### Throws
- `ErrorException`: when TODO 1 is not complete.

### Example
```julia
model = MyFredSeriesObservationsEndpointModel(apikey = apikey, series_id = "DHHNGSP",
    observation_start = "2025-01-01", observation_end = "2025-12-31", frequency = "m", units = "lin");
url = build("https://api.stlouisfed.org", model);
```
"""
function build(base::String, model::MyFredSeriesObservationsEndpointModel)::String

    # get data from the model; this part is complete -
    apikey = model.apikey;
    series_id = model.series_id;
    observation_start = model.observation_start;
    observation_end = model.observation_end;
    frequency = model.frequency;
    units = model.units;
    message = "Oooops! The `build(...)` method for the observations endpoint is not implemented yet - " *
        "we'd better fix that. Complete TODO 1.";

    # TODO 1: the URL string: base + path + ? + query string -
    url_string = "$(base)/fred/series/observations?series_id=$(series_id)&observation_start=$(observation_start)&observation_end=$(observation_end)&frequency=$(frequency)&units=$(units)&api_key=$(apikey)&file_type=json";
    if (isempty(url_string) == true) # this part is complete: a blank TODO 1 leaves "" behind
        throw(ErrorException(message));
    end

    # return the URL string -
    return url_string;
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
table = MyFredSeriesObservationsEndpointModel(url; handler = L13bObservations.process_observations_response_dataframe);
```
"""
function process_observations_response_dataframe(model::Type{T}, response::String)::DataFrame where T <: AbstractFredEndpointModel

    # initialize; this part is complete -
    dates = Array{Date,1}(); # the date of each observation
    observation_values = Array{Union{Missing,Float64},1}(); # the value of each observation: a number, or missing
    message = "Oooops! The `process_observations_response_dataframe(...)` function is not implemented yet - " *
        "we'd better fix that. Complete TODO 2 and TODO 3.";

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

end # module L13bObservations
