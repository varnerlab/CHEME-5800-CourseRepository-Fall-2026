# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
# This function makes a HTTP GET call with the URL that was passed in.
# We check for a non 200 status code, and throw an exception if we get one.
# Otherwise, we return the body of the response as a String
function _http_get_call_with_url(url::String)::String

    # should we check if this string is formatted as a URL?
    # The URL holds the API key, so the error message does not show the URL -
    if !startswith(url, "http://") && !startswith(url, "https://")
        throw(ArgumentError("the url is not properly formatted: it must start with http:// or https://"))
    end

    # The request headers tell the server who is calling, and which format we want back -
    headers = [
        "User-Agent" => "CHEME-5800-L13b-Lab", # identifies the client
        "Accept" => "application/json" # the format (media type) that we want for the response body
    ];

    # ok, so we are going to make a HTTP GET call with the URL that was passed in -
    # This is a blocking call, it uses the HTTP.jl package. The first argument is the HTTP method.
    # we want to handle a failed status code on our own, so HTTP.jl does NOT throw an exception for it -
    # For more information on the HTTP.jl package, see: https://github.com/JuliaWeb/HTTP.jl
    response = nothing;
    try
        response = HTTP.request("GET", url, headers; status_exception = false)
    catch
        # HTTP.jl could not reach the server, e.g., there is no network connection. The error of HTTP.jl
        # shows the URL, which holds the API key, so we throw our own error in its place -
        throw(ArgumentError("HTTP GET call failed: we could not connect to the server. Check the base URL and your network connection."))
    end
    body = response.body |> String; # the body of the response as a String

    # a status code of 200 means OK. Any other status code is a failed call -
    if (response.status != 200)

        # start the error message with the status code -
        message = "HTTP GET call failed with status code $(response.status)";

        # FRED describes the problem in the body of an error response, as JSON text like
        # {"error_code": 400, "error_message": "Bad Request. ..."}. We add that description to our message -
        if (startswith(body, "{") == true)
            error_dictionary = JSON.parse(body);
            if (haskey(error_dictionary, "error_message") == true)
                message = message * ": " * error_dictionary["error_message"];
            end
        end

        throw(ArgumentError(message))
    end

    # return the body of the response -
    return body;
end

# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    api(endpoint::Type{T}, request_url::String;
        handler::Function = _default_handler_process_fred_response) where T <: AbstractFredEndpointModel

Make an HTTP GET request to a FRED endpoint and process its response.

### Arguments
- `endpoint::Type{T}`: the FRED endpoint type that identifies the response to process.
- `request_url::String`: the complete URL returned by `url(...)`. It includes the API key and should not be printed.
- `handler::Function`: the function that receives the endpoint type and the response body as a `String`.
  The default handler parses the JSON text into a dictionary.

### Returns
- The result of the handler. The default is a parsed JSON dictionary. The table handlers return a `DataFrame`.

### Throws
- `ArgumentError`: when the URL is malformed, the connection fails, or the response status is not `200`.
  The HTTP error message includes FRED's error description when available.
"""
function api(endpoint::Type{T}, request_url::String;
    handler::Function = _default_handler_process_fred_response) where T <: AbstractFredEndpointModel

    # make the HTTP GET call and read the response body as a String -
    response_string = _http_get_call_with_url(request_url);

    # process the response and return the handler's result -
    return handler(endpoint, response_string);
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
