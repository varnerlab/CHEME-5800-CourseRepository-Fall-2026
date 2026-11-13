"""
    AbstractWeatherEndpointModel

Abstract base type for all National Weather Service (NWS) API endpoint models.
Each subtype represents one endpoint of the API and holds the data needed to call it.
"""
abstract type AbstractWeatherEndpointModel end

"""
    mutable struct MyWeatherGridPointEndpointModel <: AbstractWeatherEndpointModel

Endpoint model for the NWS `/points/{latitude},{longitude}` endpoint.
This endpoint returns information about a location, including the URLs of its forecasts.

### Fields
- `latitude::Float64`: the latitude of the location (units: decimal degrees, north is positive).
- `longitude::Float64`: the longitude of the location (units: decimal degrees, east is positive).

### Constructors
- `MyWeatherGridPointEndpointModel(; latitude::Float64 = 0.0, longitude::Float64 = 0.0)`: returns a new `MyWeatherGridPointEndpointModel` instance.
"""
mutable struct MyWeatherGridPointEndpointModel <: AbstractWeatherEndpointModel

    # data -
    latitude::Float64
    longitude::Float64

    # methods -
    MyWeatherGridPointEndpointModel(;
        latitude::Float64 = 0.0, longitude::Float64 = 0.0) = new(latitude, longitude);
end

"""
    mutable struct MyWeatherForecastEndpointModel <: AbstractWeatherEndpointModel

Endpoint model for the NWS forecast endpoints, e.g., `/gridpoints/{office}/{x},{y}/forecast/hourly`.
The points endpoint returns the complete forecast URL, so this type has no fields.
Instantiate with `MyWeatherForecastEndpointModel()`.
"""
mutable struct MyWeatherForecastEndpointModel <: AbstractWeatherEndpointModel

    # methods -
    MyWeatherForecastEndpointModel() = new(); # empty
end
