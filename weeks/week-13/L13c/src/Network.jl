# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
# This function makes a HTTP GET call with the URL that was passed in.
# We check for a non 200 status code, and throw an exception if we get one.
# Otherwise, we return the body of the response as a String
function _http_get_call_with_url(url::String)::String

    # should we check if this string is formatted as a URL?
    if !startswith(url, "http://") && !startswith(url, "https://")
        throw(ArgumentError("url $(url) is not properly formatted"))
    end

    # The request headers tell the server who is calling, and which format we want back -
    headers = [
        "User-Agent" => "CHEME-5800-L13c-Example", # the weather service asks every client to identify itself
        "Accept" => "application/geo+json" # the format (media type) that we want for the response body
    ];

    # ok, so we are going to make a HTTP GET call with the URL that was passed in -
    # This is a blocking call, it uses the HTTP.jl package. The first argument is the HTTP method.
    # we want to handle a failed status code on our own, so HTTP.jl does NOT throw an exception for it -
    # For more information on the HTTP.jl package, see: https://github.com/JuliaWeb/HTTP.jl
    response = HTTP.request("GET", url, headers; status_exception = false)
    if (response.status != 200) # a status code of 200 means OK
        throw(ArgumentError("HTTP GET call failed with status code $(response.status)"))
    end

    # return the body of the response as a String -
    return response.body |> String;
end

# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    api(endpoint::Type{T}, request_url::String;
        handler::Function = _default_handler_process_weather_response) where T <: AbstractWeatherEndpointModel

Make an HTTP GET request to a National Weather Service endpoint and process its response.

### Arguments
- `endpoint::Type{T}`: the endpoint type, either `MyWeatherGridPointEndpointModel` or `MyWeatherForecastEndpointModel`.
- `request_url::String`: the complete URL returned by `url(...)` or supplied in an NWS response.
- `handler::Function`: the function that receives the endpoint type and the response body as a `String`.
  The default handler parses the JSON text into a dictionary.

### Returns
- The result of the handler. The default is a parsed JSON dictionary. The forecast table handler returns a `DataFrame`.

### Throws
- `ArgumentError`: when the URL does not start with `http://` or `https://`, or the response status is not `200`.
  Connection failures are reported by HTTP.jl.
"""
function api(endpoint::Type{T}, request_url::String;
    handler::Function = _default_handler_process_weather_response) where T <: AbstractWeatherEndpointModel

    # make the HTTP GET call and read the response body as a String -
    response_string = _http_get_call_with_url(request_url);

    # process the response and return the handler's result -
    return handler(endpoint, response_string);
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
