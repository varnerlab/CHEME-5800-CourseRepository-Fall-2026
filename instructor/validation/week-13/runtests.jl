const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13"))
include(joinpath(WEEK_ROOT, "L13a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L13b", "Include.jl"))

const DATA_DIR = joinpath(WEEK_ROOT, "data")
const POINTS_BODY = read(joinpath(DATA_DIR, "nws-points-ithaca.fixture.json"), String)
const FORECAST_BODY = read(joinpath(DATA_DIR, "nws-forecast-hourly-ithaca.fixture.json"), String)
const USER_AGENT = "CHEME-4800-5800-Fall-2026 course@example.edu"

@testset "L13 NWS URL and fixture contracts" begin
    @test build_points_url(42.443961, -76.501881) ==
        "https://api.weather.gov/points/42.443961,-76.501881"
    @test_throws ArgumentError build_points_url(91, 0)
    @test_throws ArgumentError build_points_url(42, -181)
    @test_throws ArgumentError build_points_url(42, -76; base_url = "http://api.weather.gov")

    points = JSON.parse(POINTS_BODY)
    forecast = JSON.parse(FORECAST_BODY)
    @test parse_points_response(points) ==
        "https://api.weather.gov/gridpoints/BGM/52,99/forecast/hourly"
    periods = parse_forecast_response(forecast)
    @test length(periods) == 2
    @test periods[1]["temperature"] == 72
    @test periods[2]["shortForecast"] == "Partly Cloudy"
end

@testset "L13 linked request and failure paths" begin
    calls = String[]
    function fixture_get(url::String; user_agent::String)
        push!(calls, url)
        @test user_agent == USER_AGENT
        return occursin("/points/", url) ?
            HTTPResponse(200, POINTS_BODY) : HTTPResponse(200, FORECAST_BODY)
    end

    periods = fetch_hourly_forecast(
        42.443961,
        -76.501881;
        user_agent = USER_AGENT,
        getter = fixture_get,
    )
    @test length(calls) == 2
    @test length(periods) == 2

    failing_get(url::String; user_agent::String) = HTTPResponse(503, "unavailable")
    malformed_get(url::String; user_agent::String) = HTTPResponse(200, "{not-json")
    @test_throws ArgumentError request_json(
        "https://api.weather.gov/points/0,0";
        user_agent = USER_AGENT,
        getter = failing_get,
    )
    @test_throws ArgumentError request_json(
        "https://api.weather.gov/points/0,0";
        user_agent = USER_AGENT,
        getter = malformed_get,
    )
    @test_throws ArgumentError parse_points_response(Dict("properties" => Dict()))
    @test_throws ArgumentError parse_forecast_response(
        Dict("properties" => Dict("periods" => [Dict("temperature" => 72)])),
    )
end

@testset "L13 cross-language urea-cycle fixture" begin
    payload = JSON.parsefile(joinpath(DATA_DIR, "urea-cycle-network.json"))
    rows = payload["stoichiometric_matrix"]
    S = reduce(vcat, [permutedims(Float64.(row)) for row in rows])
    balanced = Float64.(payload["reference_fluxes"]["balanced"])
    imbalanced = Float64.(payload["reference_fluxes"]["imbalanced"])
    @test size(S) == (18, 19)
    @test norm(S * balanced, Inf) <= 1e-12
    @test norm(S * imbalanced, Inf) == 1.0
    @test payload["network_id"] == "urea-cycle"
end
