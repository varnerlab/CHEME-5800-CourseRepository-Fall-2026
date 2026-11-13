# =============================================================================
# CHEME 5800 | L13b SDK: the build methods for the request URLs
# =============================================================================
# You edit this file in this lab. The build methods of the search and series
# endpoints are complete. Complete the build method of the observations endpoint,
# at the bottom of the file, by filling in the line marked TODO 1.
#
# After each edit: save this file, restart the kernel, and run the notebook
# from the top. You are done when the check cell of Task 3 passes.
# =============================================================================
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
        "we'd better fix that. Complete TODO 1 in src/Factory.jl.";

    # TODO 1: the URL string. Replace "" with one string: base + path + ? + query string. The path
    # is /fred/series/observations, and the query string holds the seven key=value parameters in
    # the table of the docstring, joined by &. Hint: put each variable into the string with
    # $(...), the way the two build methods above do. The key of the API key
    # parameter is api_key, with an underscore.
    url_string = "";
    if (isempty(url_string) == true) # this part is complete: a blank TODO 1 leaves "" behind
        throw(ErrorException(message));
    end

    # return the URL string -
    return url_string;
end

# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
