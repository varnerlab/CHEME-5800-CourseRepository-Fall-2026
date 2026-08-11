module Week13Client

import Downloads
import JSON

export HTTPResponse,
    build_points_url,
    default_get,
    fetch_hourly_forecast,
    parse_forecast_response,
    parse_points_response,
    request_json

const NWS_BASE_URL = "https://api.weather.gov"
const REQUIRED_PERIOD_FIELDS = (
    "startTime",
    "endTime",
    "isDaytime",
    "temperature",
    "temperatureUnit",
    "windSpeed",
    "windDirection",
    "shortForecast",
)

"""A deliberately small HTTP response type that is easy to replace in tests."""
struct HTTPResponse
    status::Int
    body::String
end

"""Build the National Weather Service points endpoint for a latitude/longitude."""
function build_points_url(latitude::Real, longitude::Real; base_url::String = NWS_BASE_URL)::String
    (-90 <= latitude <= 90) || throw(ArgumentError("latitude must be between -90 and 90"))
    (-180 <= longitude <= 180) || throw(ArgumentError("longitude must be between -180 and 180"))
    startswith(base_url, "https://") || throw(ArgumentError("base_url must use HTTPS"))
    return "$(rstrip(base_url, '/'))/points/$(latitude),$(longitude)"
end

"""Perform an optional live GET request. Tests inject a fixture-backed replacement."""
function default_get(url::String; user_agent::String)::HTTPResponse
    isempty(strip(user_agent)) && throw(ArgumentError("user_agent must identify the application"))
    startswith(url, "https://") || throw(ArgumentError("NWS requests must use HTTPS"))
    output = IOBuffer()
    response = Downloads.request(
        url;
        headers = ["Accept" => "application/geo+json", "User-Agent" => user_agent],
        output = output,
    )
    return HTTPResponse(response.status, String(take!(output)))
end

"""Request and parse one JSON document, with explicit transport and parsing errors."""
function request_json(
    url::String;
    user_agent::String,
    getter::Function = default_get,
)::Dict{String,Any}
    isempty(strip(user_agent)) && throw(ArgumentError("user_agent must identify the application"))
    response = getter(url; user_agent = user_agent)
    response isa HTTPResponse || throw(ArgumentError("getter must return HTTPResponse"))
    (200 <= response.status < 300) || throw(ArgumentError(
        "HTTP GET failed with status $(response.status) for $(url)",
    ))
    parsed = try
        JSON.parse(response.body)
    catch error
        throw(ArgumentError(
            "response from $(url) was not valid JSON: $(sprint(showerror, error))",
        ))
    end
    parsed isa AbstractDict || throw(ArgumentError("response from $(url) must be a JSON object"))
    return Dict{String,Any}(parsed)
end

"""Extract the linked hourly-forecast URL from a points response."""
function parse_points_response(payload::AbstractDict{String,<:Any})::String
    properties = get(payload, "properties", nothing)
    properties isa AbstractDict || throw(ArgumentError(
        "points response is missing object field properties",
    ))
    forecast_url = get(properties, "forecastHourly", nothing)
    forecast_url isa String || throw(ArgumentError(
        "points response is missing string field properties.forecastHourly",
    ))
    startswith(forecast_url, "https://api.weather.gov/") || throw(ArgumentError(
        "properties.forecastHourly must be an api.weather.gov HTTPS URL",
    ))
    return forecast_url
end

"""Validate and select the fields used by the course from an hourly forecast."""
function parse_forecast_response(payload::AbstractDict{String,<:Any})::Vector{Dict{String,Any}}
    properties = get(payload, "properties", nothing)
    properties isa AbstractDict || throw(ArgumentError(
        "forecast response is missing object field properties",
    ))
    periods = get(properties, "periods", nothing)
    periods isa AbstractVector || throw(ArgumentError(
        "forecast response is missing array field properties.periods",
    ))
    isempty(periods) && throw(ArgumentError("forecast response contains no periods"))

    selected = Dict{String,Any}[]
    for (index, period) in enumerate(periods)
        period isa AbstractDict || throw(ArgumentError(
            "forecast period $(index) must be a JSON object",
        ))
        missing_fields = [field for field in REQUIRED_PERIOD_FIELDS if !haskey(period, field)]
        isempty(missing_fields) || throw(ArgumentError(
            "forecast period $(index) is missing required fields: $(join(missing_fields, ", "))",
        ))
        push!(selected, Dict(field => period[field] for field in REQUIRED_PERIOD_FIELDS))
    end
    return selected
end

"""Follow the NWS points link and return a validated hourly forecast."""
function fetch_hourly_forecast(
    latitude::Real,
    longitude::Real;
    user_agent::String,
    getter::Function = default_get,
)::Vector{Dict{String,Any}}
    points_url = build_points_url(latitude, longitude)
    points = request_json(points_url; user_agent = user_agent, getter = getter)
    forecast_url = parse_points_response(points)
    forecast = request_json(forecast_url; user_agent = user_agent, getter = getter)
    return parse_forecast_response(forecast)
end

end
