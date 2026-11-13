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
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
