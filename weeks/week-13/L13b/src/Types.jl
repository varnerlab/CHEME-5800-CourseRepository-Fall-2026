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
