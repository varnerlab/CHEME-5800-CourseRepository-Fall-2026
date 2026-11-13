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
        "User-Agent" => "CHEME-5800-L13d-Lab", # identifies the client
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

# This function calls the HTTP GET call, and then processes the response.
# We use a default handler, but you can pass in your own if you want to process the response differently.
function _api(model::Type{T}, complete_url_string::String;
    handler::Function = _default_handler_process_fred_response) where T <: AbstractFredEndpointModel

    # execute the HTTP GET call, the body of the response comes back as a String -
    result_string = _http_get_call_with_url(complete_url_string);

    # process and return -
    return handler(model, result_string)
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #

# This makes it look we are calling a method on a struct, but we are not!
# We are using the Julia type system (and something called multiple dispatch) to call the correct method.
# For more information on multiple dispatch, see: https://docs.julialang.org/en/v1/manual/methods/#Defining-Methods
(endpoint::Type{T})(url::String; handler::Function = _default_handler_process_fred_response) where T <: AbstractFredEndpointModel = _api(endpoint, url, handler = handler)
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
