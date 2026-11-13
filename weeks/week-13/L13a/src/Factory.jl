# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    build(base::String, model::MyWeatherGridPointEndpointModel) -> String

Build the URL string for the points endpoint of the National Weather Service (NWS) API.
An HTTP GET call to this URL returns information about the location held by the model.

### Arguments
- `base::String`: the base URL of the NWS API, i.e., `"https://api.weather.gov"`.
- `model::MyWeatherGridPointEndpointModel`: the endpoint model that holds the latitude and longitude of the location.

### Returns
- `String`: the complete URL string for the points endpoint, e.g., `"https://api.weather.gov/points/42.4440,-76.5019"`.
"""
function build(base::String, model::MyWeatherGridPointEndpointModel)::String

    # get data from the model -
    latitude = model.latitude;
    longitude = model.longitude;

    # build the URL string: base + path. The path names the resource that we want -
    url_string = "$(base)/points/$(latitude),$(longitude)";

    # return the URL string -
    return url_string;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
