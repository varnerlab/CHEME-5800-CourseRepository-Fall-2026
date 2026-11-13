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
        "User-Agent" => "CHEME-5800-L13a-Example", # the weather service asks every client to identify itself
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

# This function calls the HTTP GET call, and then processes the response.
# We use a default handler, but you can pass in your own if you want to process the response differently.
function _api(model::Type{T}, complete_url_string::String;
    handler::Function = _default_handler_process_weather_response) where T <: AbstractWeatherEndpointModel

    # execute the HTTP GET call, the body of the response comes back as a String -
    result_string = _http_get_call_with_url(complete_url_string);

    # process and return -
    return handler(model, result_string)
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #

# New pattern: This makes it look we are calling a method on an struct, but we are not!
# We are using the Julia type system (and something called multiple dispatch) to call the correct method.
# For more information on multiple dispatch, see: https://docs.julialang.org/en/v1/manual/methods/#Defining-Methods
(endpoint::Type{T})(url::String; handler::Function = _default_handler_process_weather_response) where T <: AbstractWeatherEndpointModel = _api(endpoint, url, handler = handler)
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
