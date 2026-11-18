const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the fixtures and the notebooks whose links the suite checks
import HTTP  # the local server that stands in for FRED in the L13b tests
import Dates: Date  # the dates of the L13b observations
import TOML  # reads the Codex configuration of the L13d lab
import InteractiveUtils: subtypes  # counts the endpoint models of the FredAPI package
using Test   # @testset must be defined when the file is parsed, even if no meeting that loads it is released
released("L13a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13a", "Include.jl"))
released("L13b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13b", "Include.jl"))
# The L13c and L13d modules export the same MCP names, so the suite loads both without `using`, and
# calls their functions with qualified names, e.g., L13cWeatherMCP.process_message(...).
released("L13c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13c", "src", "WeatherMCP.jl"))
released("L13d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13d", "src", "FredMCP.jl"))

const DATA_DIR = joinpath(WEEK_ROOT, "data")
const POINTS_BODY = read(joinpath(DATA_DIR, "nws-points-ithaca.fixture.json"), String)
const FORECAST_BODY = read(joinpath(DATA_DIR, "nws-forecast-hourly-ithaca.fixture.json"), String)

# Check that every local file a notebook links or shows (figures, examples, source) exists, and
# that nothing links out of the week. Returns the markdown text of the notebook.
function check_local_links(meeting::AbstractString, notebook::AbstractString)
    path = joinpath(WEEK_ROOT, meeting, notebook)
    cells = JSON.parsefile(path)["cells"]
    text = join((join(cell["source"]) for cell in cells if cell["cell_type"] == "markdown"), "\n")
    targets = vcat([m.captures[1] for m in eachmatch(r"\]\(([^)\s]+)\)", text)],
        [m.captures[1] for m in eachmatch(r"src=\"([^\"]+)\"", text)])
    local_targets = filter(t -> !startswith(t, "http") && !startswith(t, "#"), targets)
    for target in local_targets
        @test ispath(normpath(joinpath(dirname(path), target)))
        @test startswith(normpath(joinpath(dirname(path), target)), joinpath(WEEK_ROOT, "")) # no links into other weeks
    end
    return text
end

# The L13a tests use committed fixtures and a local HTTP server; no outside network is needed.
# The example notebook calls the live National Weather Service API, so the suite does not run it.
@meeting "L13a" begin
    @testset "L13a weather service code" begin
        # the endpoint model and its URL -
        model = MyWeatherGridPointEndpointModel(latitude = 42.443961, longitude = -76.501881)
        @test model isa L13aNWS.AbstractWeatherEndpointModel
        @test L13aNWS.url("https://api.weather.gov", model) == "https://api.weather.gov/points/42.443961,-76.501881"
        @test MyWeatherForecastEndpointModel() isa L13aNWS.AbstractWeatherEndpointModel

        # the default handler parses the JSON text of each endpoint -
        points = L13aNWS._default_handler_process_weather_response(MyWeatherGridPointEndpointModel, POINTS_BODY)
        @test points["properties"]["forecastHourly"] == "https://api.weather.gov/gridpoints/BGM/52,99/forecast/hourly"
        forecast = L13aNWS._default_handler_process_weather_response(MyWeatherForecastEndpointModel, FORECAST_BODY)
        @test length(forecast["properties"]["periods"]) == 2

        # the DataFrame handler selects eight fields from each forecast period, in order -
        table = process_forecast_response_dataframe(MyWeatherForecastEndpointModel, FORECAST_BODY)
        @test table isa DataFrame
        @test size(table) == (2, 8)
        @test names(table) == ["startTime", "endTime", "isDayTime", "temperature", "temperatureUnit",
            "windSpeed", "windDirection", "shortForecast"]
        @test table.temperature == [72, 74]
        @test table.shortForecast[2] == "Partly Cloudy"

        # a string that is not a URL is rejected before any network call -
        @test_throws ArgumentError L13aNWS.api(MyWeatherGridPointEndpointModel, "api.weather.gov/points/42,-76")
        @test_throws ArgumentError L13aNWS._http_get_call_with_url("not a url")
    end

    @testset "L13a public API" begin
        request_headers = Tuple{String,String}[]
        function fixture_nws(request)
            push!(request_headers, (HTTP.header(request, "User-Agent"), HTTP.header(request, "Accept")))
            path = HTTP.URI(request.target).path
            headers = ["Content-Type" => "application/geo+json"]
            if startswith(path, "/points/")
                return HTTP.Response(200, headers, POINTS_BODY)
            elseif path == "/forecast"
                return HTTP.Response(200, headers, FORECAST_BODY)
            end
            return HTTP.Response(404, headers, "{\"status\": 404}")
        end
        nws = HTTP.serve!(fixture_nws, "127.0.0.1", 8714; listenany = true)
        try
            base = "http://127.0.0.1:$(HTTP.port(nws))"
            model = MyWeatherGridPointEndpointModel(latitude = 42.443961, longitude = -76.501881)
            points = L13aNWS.api(MyWeatherGridPointEndpointModel, L13aNWS.url(base, model))
            @test points["properties"]["gridId"] == "BGM"
            forecast = L13aNWS.api(MyWeatherForecastEndpointModel, base * "/forecast")
            @test length(forecast["properties"]["periods"]) == 2
            table = L13aNWS.api(MyWeatherForecastEndpointModel, base * "/forecast";
                handler = process_forecast_response_dataframe)
            @test table isa DataFrame
            @test table.temperature == [72, 74]
            @test_throws ArgumentError L13aNWS.api(MyWeatherForecastEndpointModel, base * "/missing")
            @test all(headers == ("CHEME-5800-L13a-Example", "application/geo+json") for headers in request_headers)
        finally
            close(nws)
        end
    end

    @testset "L13a notebooks" begin
        lecture = "CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb"
        example = "CHEME-5800-L13a-Example-RESTful-NWS-Fall-2026.ipynb"

        # the lecture is markdown only, and both notebooks link only files in this week -
        lecture_cells = JSON.parsefile(joinpath(WEEK_ROOT, "L13a", lecture))["cells"]
        @test all(cell["cell_type"] == "markdown" for cell in lecture_cells)
        for notebook in (lecture, example)
            text = check_local_links("L13a", notebook)
            @test occursin("__Learning Objectives:__", text)
            @test occursin("__Key Takeaways:__", text)
            @test endswith(rstrip(text), "___")
        end
        @test occursin(example, check_local_links("L13a", lecture)) # the lecture links the example

        # the example ships with its outputs, and no cell ended in an error -
        example_cells = JSON.parsefile(joinpath(WEEK_ROOT, "L13a", example))["cells"]
        code_cells = [cell for cell in example_cells if cell["cell_type"] == "code"]
        @test !isempty(code_cells)
        @test count(cell -> !isempty(cell["outputs"]), code_cells) >= 8 # the calls and the check show their results
        @test all(output["output_type"] != "error" for cell in code_cells for output in cell["outputs"])

        # the lecture shows its five figures, and the figures and the deck are in place -
        lecture_text = join(join(cell["source"]) for cell in lecture_cells)
        for figure in ("Fig-HTTP-Messages", "Fig-URL-Anatomy", "Fig-JSON-Tree", "Fig-REST-Cycle", "Fig-CRUD-Methods")
            @test occursin("figs/$(figure)/$(figure).svg", lecture_text)
            @test isfile(joinpath(WEEK_ROOT, "L13a", "figs", figure, "$(figure).svg"))
        end
        @test isfile(joinpath(WEEK_ROOT, "L13a", "slides", "CHEME-5800-L13a-Slides-Fall-2026.pdf"))
    end
end

# The L13b tests need no FRED API key and no outside network. The handlers are tested on the
# committed fixtures, and the HTTP calls are tested against a small server on this machine.
# The lab notebook calls the live FRED API with a student's key, so the suite does not run it.
@meeting "L13b" begin
    @testset "L13b FRED lab code" begin
        L13B_ROOT = joinpath(WEEK_ROOT, "L13b")
        base = "https://api.stlouisfed.org"
        demo_key = "abcdefghijklmnopqrstuvwxyz123456" # the example key of the FRED documentation, not a registered key
        search_body = read(joinpath(DATA_DIR, "fred-series-search.fixture.json"), String)
        series_body = read(joinpath(DATA_DIR, "fred-series.fixture.json"), String)
        observations_body = read(joinpath(DATA_DIR, "fred-series-observations.fixture.json"), String)
        error_body = read(joinpath(DATA_DIR, "fred-error.fixture.json"), String)
        observations_model = MyFredSeriesObservationsEndpointModel(apikey = demo_key, series_id = "DHHNGSP",
            observation_start = "2025-01-01", observation_end = "2025-01-08", frequency = "d", units = "lin")

        @testset "supplied endpoint models and URLs" begin
            search_model = MyFredSeriesSearchEndpointModel(apikey = demo_key, search_text = "natural gas", limit = 5)
            @test search_model isa AbstractFredEndpointModel
            @test L13bFRED.url(base, search_model) ==
                "$(base)/fred/series/search?search_text=natural%20gas&limit=5&api_key=$(demo_key)&file_type=json"
            series_model = MyFredSeriesEndpointModel(apikey = demo_key, series_id = "DHHNGSP")
            @test L13bFRED.url(base, series_model) == "$(base)/fred/series?series_id=DHHNGSP&api_key=$(demo_key)&file_type=json"
            defaults = MyFredSeriesObservationsEndpointModel()
            @test (defaults.observation_start, defaults.observation_end, defaults.frequency, defaults.units) ==
                ("1776-07-04", "9999-12-31", "m", "lin")
        end

        @testset "supplied handlers" begin
            parsed = L13bFRED._default_handler_process_fred_response(MyFredSeriesEndpointModel, series_body)
            @test parsed["seriess"][1]["units"] == "Dollars per Million BTU"
            table = process_search_response_dataframe(MyFredSeriesSearchEndpointModel, search_body)
            @test names(table) == ["id", "title", "frequency", "units", "observation_start", "observation_end"]
            @test table.id == ["DHHNGSP", "MHHNGSP"]
            @test table.frequency == ["Daily", "Monthly"]
            no_match = process_search_response_dataframe(MyFredSeriesSearchEndpointModel, "{\"seriess\": []}")
            @test size(no_match) == (0, 6) # a search that matches nothing keeps the six columns
            @test names(no_match) == names(table)
        end

        @testset "configuration file and key helpers" begin
            @test hidekey("$(base)/fred/series?api_key=$(demo_key)&file_type=json", demo_key) ==
                "$(base)/fred/series?api_key=<your key>&file_type=json"
            @test hidekey("$(base)/fred/series", "") == "$(base)/fred/series"
            mktempdir() do folder
                @test_throws ArgumentError read_configuration(joinpath(folder, "Configuration.toml")) # no file yet
                template = read(joinpath(L13B_ROOT, "conf", "Configuration-template.toml"), String)
                path = joinpath(folder, "Configuration.toml")
                write(path, template)
                @test_throws ArgumentError read_configuration(path) # the template holds no key
                write(path, replace(template, "paste-your-FRED-API-key-here" => demo_key))
                connection = read_configuration(path)
                @test connection["apikey"] == demo_key
                @test connection["baseurl"] == base
                write(path, "[other]\nvalue = 1\n")
                @test_throws ArgumentError read_configuration(path)
                # a file that is not valid TOML: the message never shows the line that holds the key -
                write(path, "[connection]\napikey = \"$(demo_key)\"oops\nbaseurl = \"$(base)\"\n")
                unreadable = try
                    read_configuration(path)
                    nothing
                catch exception
                    exception
                end
                @test unreadable isa ArgumentError && !occursin(demo_key, unreadable.msg)
                write(path, "[connection]\napikey = 12345\nbaseurl = \"$(base)\"\n")
                @test_throws ArgumentError read_configuration(path)
            end
            # git never tracks the file that holds a key -
            @test occursin("Configuration.toml", read(joinpath(L13B_ROOT, "conf", ".gitignore"), String))
            @test !isfile(joinpath(L13B_ROOT, "conf", "Configuration.toml")) ||
                !success(pipeline(`git -C $(L13B_ROOT) ls-files --error-unmatch conf/Configuration.toml`; stdout = devnull, stderr = devnull))
        end

        @testset "student files and reference solutions" begin
            # the student edits two SDK files; their reference solutions are in src/solution -
            pairs = [("Factory.jl", "Factory-solution.jl"), ("Handler.jl", "Handler-solution.jl")]
            function code_lines(text)
                lines = String[]
                for line in split(text, '\n')
                    stripped = strip(line)
                    (isempty(stripped) || startswith(stripped, "#")) && continue
                    any(startswith(stripped, start) for start in ("url_string = ", "date = ", "value = nothing", "value = parse")) && continue
                    push!(lines, String(line))
                end
                return lines
            end
            for (student, solution) in pairs
                student_text = read(joinpath(L13B_ROOT, "src", student), String)
                solution_text = read(joinpath(L13B_ROOT, "src", "solution", solution), String)
                @test code_lines(student_text) == code_lines(solution_text) # the same code outside the TODO lines
            end
            factory_text = read(joinpath(L13B_ROOT, "src", "Factory.jl"), String)
            handler_text = read(joinpath(L13B_ROOT, "src", "Handler.jl"), String)
            @test occursin("TODO 1", factory_text) && count("Hint:", factory_text) == 1
            @test occursin("TODO 2", handler_text) && occursin("TODO 3", handler_text) && count("Hint:", handler_text) == 2
            for (answer, student, solution) in (("observations?series_id=", "Factory.jl", "Factory-solution.jl"),
                    ("Date(date_string)", "Handler.jl", "Handler-solution.jl"), ("parse(Float64, value_string)", "Handler.jl", "Handler-solution.jl"))
                @test !occursin(answer, read(joinpath(L13B_ROOT, "src", student), String)) # the student file omits the answer
                @test occursin(answer, read(joinpath(L13B_ROOT, "src", "solution", solution), String))
            end
            @test :process_observations_response_dataframe in names(L13bFRED)

            # the setup file loaded the untouched student files: both functions throw the house error -
            @test_throws ErrorException L13bFRED.url(base, observations_model)
            @test_throws ErrorException process_observations_response_dataframe(MyFredSeriesObservationsEndpointModel, observations_body)

            # the reference solutions, loaded into the module in place of the student files -
            for (student, solution) in pairs
                Base.include(L13bFRED, joinpath(L13B_ROOT, "src", "solution", solution))
            end
            observations_url = Base.invokelatest(L13bFRED.url, base, observations_model)
            @test observations_url == "$(base)/fred/series/observations?series_id=DHHNGSP&observation_start=2025-01-01" *
                "&observation_end=2025-01-08&frequency=d&units=lin&api_key=$(demo_key)&file_type=json"
            handler = process_observations_response_dataframe
            table = Base.invokelatest(handler, MyFredSeriesObservationsEndpointModel, observations_body)
            @test names(table) == ["date", "value"]
            @test eltype(table.date) == Date
            @test eltype(table.value) == Union{Missing,Float64}
            @test table.date[1] == Date(2025, 1, 1) && table.date[end] == Date(2025, 1, 8)
            @test isequal(table.value, [missing, 3.65, 3.40, 4.05, 3.80, 3.75])
            empty_table = Base.invokelatest(handler, MyFredSeriesObservationsEndpointModel, "{\"observations\": []}")
            @test size(empty_table) == (0, 2)

            # the HTTP calls, against a server on this machine that answers like FRED -
            function local_fred(request)
                query = HTTP.queryparams(HTTP.URI(request.target))
                path = HTTP.URI(request.target).path
                json_type = ["Content-Type" => "application/json; charset=UTF-8"]
                if get(query, "api_key", "") != demo_key || get(query, "file_type", "") != "json"
                    return HTTP.Response(400, json_type, error_body)
                end
                if path == "/fred/series/search" && get(query, "search_text", "") == "natural gas" && get(query, "limit", "") == "5"
                    return HTTP.Response(200, json_type, search_body) # the server decoded %20 back to a space
                end
                if path == "/fred/series" && get(query, "series_id", "") == "DHHNGSP"
                    return HTTP.Response(200, json_type, series_body)
                end
                expected = Dict("series_id" => "DHHNGSP", "observation_start" => "2025-01-01", "observation_end" => "2025-01-08",
                    "frequency" => "d", "units" => "lin", "api_key" => demo_key, "file_type" => "json")
                if path == "/fred/series/observations" && Dict(query) == expected
                    return HTTP.Response(200, json_type, observations_body)
                end
                return HTTP.Response(400, json_type, error_body)
            end
            server = HTTP.serve!(local_fred, "127.0.0.1", 8713; listenany = true) # the first free port from 8713 up
            try
                local_base = "http://127.0.0.1:$(HTTP.port(server))"
                description = L13bFRED.api(MyFredSeriesEndpointModel, L13bFRED.url(local_base, MyFredSeriesEndpointModel(apikey = demo_key, series_id = "DHHNGSP")))
                @test description["seriess"][1]["id"] == "DHHNGSP"
                found = L13bFRED.api(MyFredSeriesSearchEndpointModel, L13bFRED.url(local_base, MyFredSeriesSearchEndpointModel(apikey = demo_key,
                    search_text = "natural gas", limit = 5)); handler = process_search_response_dataframe)
                @test found.id == ["DHHNGSP", "MHHNGSP"]
                live_table = Base.invokelatest(L13bFRED.api, MyFredSeriesObservationsEndpointModel, Base.invokelatest(L13bFRED.url, local_base, observations_model);
                    handler = handler)
                @test isequal(live_table.value, [missing, 3.65, 3.40, 4.05, 3.80, 3.75])

                # a failed call: the message has the status code and the description from FRED, and never the key -
                wrong_key = "00000000000000000000000000000000"
                failure = try
                    L13bFRED.api(MyFredSeriesEndpointModel, L13bFRED.url(local_base, MyFredSeriesEndpointModel(apikey = wrong_key, series_id = "DHHNGSP")))
                    nothing
                catch exception
                    exception
                end
                @test failure isa ArgumentError
                @test occursin("status code 400", failure.msg)
                @test occursin("api_key is not registered", failure.msg)
                @test !occursin(wrong_key, failure.msg)
            finally
                close(server)
            end
            # no server at this address: the message of our error does not show the URL or its key -
            unreachable = try
                L13bFRED.api(MyFredSeriesEndpointModel, "http://127.0.0.1:9/fred/series?api_key=$(demo_key)")
                nothing
            catch exception
                exception
            end
            @test unreachable isa ArgumentError && !occursin(demo_key, unreachable.msg)
            malformed = try
                L13bFRED.api(MyFredSeriesEndpointModel, "api.stlouisfed.org/fred/series?api_key=$(demo_key)")
                nothing
            catch exception
                exception
            end
            @test malformed isa ArgumentError && !occursin(demo_key, malformed.msg) # the URL, and its key, stay out of the message
        end

        @testset "L13b lab notebook" begin
            notebook = "CHEME-5800-L13b-Lab-RESTful-FRED-Fall-2026.ipynb"
            text = check_local_links("L13b", notebook)
            @test occursin("__Learning Objectives:__", text)
            @test occursin("__Key Takeaways:__", text)
            @test endswith(rstrip(text), "___")
            @test occursin("__TODO 1:__", text) && occursin("__TODO 2:__", text) && occursin("__TODO 3:__", text)
            cells = JSON.parsefile(joinpath(L13B_ROOT, notebook))["cells"]
            code_cells = [join(cell["source"]) for cell in cells if cell["cell_type"] == "code"]
            @test length(code_cells) ≥ 10
            for code in code_cells
                @test !(Meta.parseall(code).args[end] isa Expr && Meta.parseall(code).args[end].head in (:error, :incomplete)) # every cell parses
            end
            # the notebook passes the student's handler to the calls, and reads the key from the file -
            notebook_code = join(code_cells, "\n")
            @test occursin("handler = process_observations_response_dataframe", notebook_code)
            @test occursin("read_configuration(joinpath(CHEME5800_L13B_CONFIG, \"Configuration.toml\"))", notebook_code)

            # no file that ships holds a key: the only 32 character key-like text is the example key of the documentation -
            shipped = [joinpath(L13B_ROOT, notebook), joinpath(L13B_ROOT, "Include.jl"),
                joinpath(L13B_ROOT, "conf", "Configuration-template.toml")]
            append!(shipped, [joinpath(folder, file) for (folder, _, files) in walkdir(joinpath(L13B_ROOT, "src")) for file in files if endswith(file, ".jl")])
            append!(shipped, [joinpath(DATA_DIR, file) for file in readdir(DATA_DIR) if startswith(file, "fred-")])
            for path in shipped
                keys_found = [m.match for m in eachmatch(r"(?<![a-z0-9])[a-z0-9]{32}(?![a-z0-9])", read(path, String))]
                @test all(key -> key == demo_key, keys_found)
            end
        end
    end
end

# MCP helpers for the L13c and L13d tests. A request carries the _meta object of protocol version 2026-07-28.
const MCP_VERSION = "2026-07-28"
function mcp_line(id, method::String, params::Dict{String,Any} = Dict{String,Any}(); version = MCP_VERSION)
    params = copy(params)
    if version !== nothing
        params["_meta"] = Dict{String,Any}("io.modelcontextprotocol/protocolVersion" => version,
            "io.modelcontextprotocol/clientCapabilities" => Dict{String,Any}(),
            "io.modelcontextprotocol/clientInfo" => Dict{String,Any}("name" => "week-13-suite", "version" => "1.0.0"))
    end
    return JSON.json(Dict{String,Any}("jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params))
end
mcp_call_line(id, name::String, arguments::Dict{String,Any}) =
    mcp_line(id, "tools/call", Dict{String,Any}("name" => name, "arguments" => arguments))
# the text that a host gives its model, for a tools/call result -
result_text(response) = response["result"]["content"][1]["text"]

# Check the shared parts of a notebook: objectives, takeaways, the closing rule, and links that stay in the week.
function check_notebook_frame(meeting::AbstractString, notebook::AbstractString)
    text = check_local_links(meeting, notebook)
    @test occursin("__Learning Objectives:__", text)
    @test occursin("__Key Takeaways:__", text)
    @test endswith(rstrip(text), "___")
    return text
end

# The L13c tests need no outside network. The weather server runs in this process against a small
# server on this machine that answers like the National Weather Service. A second test starts
# server.jl as a subprocess, the way a host does, and discovers it.
@meeting "L13c" begin
    @testset "L13c weather MCP server" begin
        W = L13cWeatherMCP
        L13C_ROOT = joinpath(WEEK_ROOT, "L13c")
        live_hourly = "https://api.weather.gov/gridpoints/BGM/52,99/forecast/hourly"
        port = Ref(0)
        function local_nws(request)
            path = HTTP.URI(request.target).path
            json_type = ["Content-Type" => "application/geo+json"]
            if path == "/points/42.443961,-76.501881"
                local_hourly = "http://127.0.0.1:$(port[])/gridpoints/BGM/52,99/forecast/hourly"
                return HTTP.Response(200, json_type, replace(POINTS_BODY, live_hourly => local_hourly))
            elseif path == "/gridpoints/BGM/52,99/forecast/hourly"
                return HTTP.Response(200, json_type, FORECAST_BODY)
            end
            return HTTP.Response(404, json_type, "{\"title\": \"Data Unavailable For Requested Point\", \"status\": 404}")
        end
        nws = HTTP.serve!(local_nws, "127.0.0.1", 8715; listenany = true)
        try
            port[] = HTTP.port(nws)
            server = W.build_weather_server(baseurl = "http://127.0.0.1:$(port[])")
            ask(line) = W.process_message(server, line)
            ithaca = Dict{String,Any}("latitude" => 42.443961, "longitude" => -76.501881)

            @testset "discover and list" begin
                found = ask(mcp_line(1, "server/discover"))
                @test found["id"] == 1 && found["jsonrpc"] == "2.0"
                @test found["result"]["supportedVersions"] == [MCP_VERSION]
                @test haskey(found["result"]["capabilities"], "tools")
                @test found["result"]["resultType"] == "complete"
                @test found["result"]["_meta"]["io.modelcontextprotocol/serverInfo"]["name"] == "cheme-5800-weather"
                @test found["result"]["ttlMs"] == 3600000 && found["result"]["cacheScope"] == "public"
                listed = ask(mcp_line("list-1", "tools/list")) # a string id comes back unchanged
                @test listed["id"] == "list-1"
                @test listed["result"]["ttlMs"] == 3600000 && listed["result"]["cacheScope"] == "public"
                @test listed["result"]["resultType"] == "complete"
                tools = listed["result"]["tools"]
                @test [tool["name"] for tool in tools] == ["get_hourly_forecast", "get_location"]
                for tool in tools
                    @test tool["inputSchema"]["type"] == "object"
                    @test Set(tool["inputSchema"]["required"]) == Set(["latitude", "longitude"])
                    @test !isempty(tool["description"])
                end
            end

            @testset "tool calls" begin
                place = ask(mcp_call_line(2, "get_location", ithaca))["result"]
                @test place["isError"] == false
                @test place["structuredContent"] == Dict("city" => "Ithaca", "state" => "NY", "forecast_office" => "BGM",
                    "grid_x" => 52, "grid_y" => 99, "time_zone" => "America/New_York")
                @test JSON.parse(place["content"][1]["text"]) == place["structuredContent"] # the text holds the same result
                one_hour = ask(mcp_call_line(3, "get_hourly_forecast", merge(ithaca, Dict{String,Any}("hours" => 1))))["result"]
                @test one_hour["isError"] == false
                @test length(one_hour["structuredContent"]["periods"]) == 1
                @test one_hour["structuredContent"]["periods"][1]["temperature"] == 72
                every_hour = ask(mcp_call_line(4, "get_hourly_forecast", ithaca))["result"] # the default is 12 hours; the fixture has 2
                @test length(every_hour["structuredContent"]["periods"]) == 2
            end

            @testset "tool execution errors" begin
                paris_response = ask(mcp_call_line(5, "get_hourly_forecast", Dict{String,Any}("latitude" => 48.8566, "longitude" => 2.3522)))
                paris = paris_response["result"]
                @test paris["isError"] == true && occursin("404", result_text(paris_response))
                @test !haskey(paris, "structuredContent")
                @test paris["resultType"] == "complete" # a tool execution error is still a complete result
                for arguments in (Dict{String,Any}("latitude" => 42.4), # no longitude
                        Dict{String,Any}("latitude" => "42.4", "longitude" => -76.5), # text, not a number
                        Dict{String,Any}("latitude" => 91, "longitude" => -76.5), # out of range
                        Dict{String,Any}("latitude" => true, "longitude" => false), # JSON booleans are not numbers
                        merge(ithaca, Dict{String,Any}("hours" => 0)), merge(ithaca, Dict{String,Any}("hours" => 2.5)),
                        merge(ithaca, Dict{String,Any}("hours" => true)))
                    response = ask(mcp_call_line(6, "get_hourly_forecast", arguments))
                    @test response["result"]["isError"] == true
                    @test startswith(result_text(response), "ArgumentError")
                end
            end

            @testset "protocol errors" begin
                @test ask(mcp_call_line(7, "get_snowfall", ithaca))["error"]["code"] == -32602
                @test ask(mcp_line(8, "tools/call"))["error"]["code"] == -32602 # no tool name
                @test ask(mcp_line(9, "resources/list"))["error"]["code"] == -32601
                parse_error = ask("{not json")
                @test parse_error["error"]["code"] == -32700 && parse_error["id"] === nothing
                @test ask("[1, 2]")["error"]["code"] == -32600
                @test ask("{\"id\": 1, \"method\": \"tools/list\", \"params\": {}}")["error"]["code"] == -32600 # no jsonrpc field
                @test ask("{\"jsonrpc\": \"1.0\", \"id\": 1, \"method\": \"tools/list\"}")["error"]["code"] == -32600
                @test ask(replace(mcp_line(1, "tools/list"), "\"id\":1" => "\"id\":true"))["error"]["code"] == -32600 # a boolean id
                null_meta = ask("{\"jsonrpc\": \"2.0\", \"id\": 14, \"method\": \"tools/list\", \"params\": {\"_meta\": null}}")
                @test haskey(null_meta, "result") && null_meta["id"] == 14 # no version: a request of the older version
                text_arguments = replace(mcp_call_line(15, "get_location", ithaca), r"\"arguments\":\{[^}]*\}" => "\"arguments\":\"Ithaca\"")
                @test ask(text_arguments)["error"]["code"] == -32602 # the arguments must be a JSON object
                @test ask("{\"jsonrpc\": \"2.0\", \"id\": 10, \"method\": \"tools/list\", \"params\": 3}")["error"]["code"] == -32602
                @test ask("{\"jsonrpc\": \"2.0\", \"method\": \"notifications/cancelled\", \"params\": {}}") === nothing
                old = ask(mcp_line(11, "tools/list"; version = "2025-06-18"))
                @test old["error"]["code"] == -32022
                @test old["error"]["data"]["supported"] == [MCP_VERSION] && old["error"]["data"]["requested"] == "2025-06-18"
                @test length(ask(mcp_line(12, "tools/list"; version = nothing))["result"]["tools"]) == 2 # no _meta: older version
                # the handshake of the older version 2025-06-18, as the Codex command-line tool sends it -
                initialize = JSON.json(Dict("jsonrpc" => "2.0", "id" => 13, "method" => "initialize",
                    "params" => Dict("protocolVersion" => "2025-06-18", "capabilities" => Dict(),
                        "clientInfo" => Dict("name" => "codex-mcp-client", "version" => "0.169.0"))))
                handshake = ask(initialize)
                @test handshake["id"] == 13 && handshake["result"]["protocolVersion"] == "2025-06-18"
                @test haskey(handshake["result"]["capabilities"], "tools")
                @test handshake["result"]["serverInfo"]["name"] == "cheme-5800-weather"
                @test ask("{\"jsonrpc\": \"2.0\", \"method\": \"notifications/initialized\"}") === nothing
                older_call = mcp_line(16, "tools/call", Dict{String,Any}("name" => "get_location", "arguments" => ithaca); version = nothing)
                @test ask(older_call)["result"]["structuredContent"]["forecast_office"] == "BGM" # an older-version call runs the tool
            end

            @testset "server loop" begin
                lines = [mcp_line(1, "server/discover"), "", "{\"jsonrpc\": \"2.0\", \"method\": \"notifications/cancelled\"}",
                    "{not json", mcp_call_line(2, "get_location", ithaca)]
                output = IOBuffer()
                W.serve(server; input = IOBuffer(join(lines, "\n") * "\n"), output = output)
                written = split(strip(String(take!(output))), "\n")
                @test length(written) == 3 # no answer to the blank line or the notification
                responses = [JSON.parse(line) for line in written] # every line of the output is one JSON message
                @test responses[1]["id"] == 1 && responses[2]["error"]["code"] == -32700 && responses[3]["id"] == 2
            end
        finally
            close(nws)
        end

        @testset "server.jl as a subprocess" begin
            # the command that the notebooks give for a host, without --project: server.jl activates the environment.
            # The first response parses, so nothing but protocol messages reaches the standard output -
            command = `$(joinpath(Sys.BINDIR, "julia")) --startup-file=no $(joinpath(L13C_ROOT, "server.jl"))`
            client = W.connect(command)
            try
                found = W.discover(client)
                @test found["result"]["_meta"]["io.modelcontextprotocol/serverInfo"]["name"] == "cheme-5800-weather"
                @test length(W.listtools(client)["result"]["tools"]) == 2
                close(client)
                @test success(client.process)
            finally
                process_running(client.process) && kill(client.process) # never leave a server behind
            end

            # the client rejects a response that does not carry the id of its request -
            wrong_id = `$(joinpath(Sys.BINDIR, "julia")) --startup-file=no -e 'readline(); println("{\"jsonrpc\":\"2.0\",\"id\":999,\"result\":{}}")'`
            stray = W.connect(wrong_id)
            try
                @test_throws ErrorException W.discover(stray)
            finally
                process_running(stray.process) && kill(stray.process)
            end
        end

        @testset "L13c notebooks" begin
            lecture = "CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb"
            example = "CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb"
            lecture_text = check_notebook_frame("L13c", lecture)
            check_notebook_frame("L13c", example)
            @test occursin(example, lecture_text) # the lecture links the example
            lecture_cells = JSON.parsefile(joinpath(L13C_ROOT, lecture))["cells"]
            @test all(cell["cell_type"] == "markdown" for cell in lecture_cells)
            for figure in ("Fig-MCP-Architecture", "Fig-MCP-Connections", "Fig-MCP-RunsWhere", "Fig-MCP-ToolCall")
                @test occursin("figs/$(figure)/$(figure).svg", lecture_text)
            end
            # the lecture links the recorded messages instead of showing them. Each pair is one exchange:
            # the request names our protocol version, and the response answers it with the same id -
            @test !occursin("```json", lecture_text)
            exchanges = ["1-discover", "2-list", "3-call", "4-unknown-tool", "5-paris"]
            for exchange in exchanges, kind in ("request", "response")
                @test occursin("](messages/$(exchange)-$(kind).json)", lecture_text)
            end
            @test sort(readdir(joinpath(L13C_ROOT, "messages"))) == sort(["$(e)-$(k).json" for e in exchanges for k in ("request", "response")])
            for exchange in exchanges
                request_text = read(joinpath(L13C_ROOT, "messages", "$(exchange)-request.json"), String)
                request = JSON.parse(request_text)
                response = JSON.parse(read(joinpath(L13C_ROOT, "messages", "$(exchange)-response.json"), String))
                @test request["jsonrpc"] == "2.0" && response["jsonrpc"] == "2.0"
                @test request["params"]["_meta"]["io.modelcontextprotocol/protocolVersion"] == MCP_VERSION
                @test response["id"] == request["id"]
                if exchange in ("1-discover", "2-list", "4-unknown-tool") # no web call: the current server gives the same answer
                    @test JSON.parse(JSON.json(L13cWeatherMCP.process_message(L13cWeatherMCP.build_weather_server(), request_text))) == response
                end
            end
            @test JSON.parse(read(joinpath(L13C_ROOT, "messages", "3-call-response.json"), String))["result"]["isError"] == false
            @test JSON.parse(read(joinpath(L13C_ROOT, "messages", "5-paris-response.json"), String))["result"]["isError"] == true

            # the example ships with its outputs, no cell ended in an error, and no output shows a local path -
            example_cells = JSON.parsefile(joinpath(L13C_ROOT, example))["cells"]
            code_cells = [cell for cell in example_cells if cell["cell_type"] == "code"]
            # Discovery, tool list, schema, location, forecast, and the two error examples show outputs.
            @test count(cell -> !isempty(cell["outputs"]), code_cells) >= 7
            @test all(output["output_type"] != "error" for cell in code_cells for output in cell["outputs"])
            outputs_text = JSON.json([cell["outputs"] for cell in code_cells])
            @test !occursin("/Users/", outputs_text) && !occursin(homedir(), outputs_text)
            @test occursin("cheme-5800-weather", outputs_text)
            @test occursin("get_location", outputs_text) && occursin("get_hourly_forecast", outputs_text)
            function saved_stdout(source_fragment)
                cell = only(filter(cell -> occursin(source_fragment, join(cell["source"])), code_cells))
                return join(join(output["text"]) for output in cell["outputs"]
                    if output["output_type"] == "stream" && output["name"] == "stdout")
            end
            location = JSON.parse(saved_stdout("location_response = calltool("))["result"]
            @test location["isError"] == false && location["structuredContent"]["forecast_office"] == "BGM"
            @test JSON.parse(saved_stdout("unknown_response = calltool("))["error"]["code"] == -32602
            @test JSON.parse(saved_stdout("paris_response = calltool("))["result"]["isError"] == true
            forecast_text = saved_stdout("forecast_response = calltool(")
            @test length(collect(eachmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", forecast_text))) == 6
        end
    end
end

# The L13d tests need no FRED API key and no outside network. The FRED server runs in this process
# against a small server on this machine that answers like FRED, with the test fixtures of the FredAPI
# package: one trimmed FRED response for each endpoint path.
@meeting "L13d" begin
    @testset "L13d FRED MCP lab" begin
        D = L13dFredMCP
        L13D_ROOT = joinpath(WEEK_ROOT, "L13d")
        demo_key = "abcdefghijklmnopqrstuvwxyz123456" # the example key of the FRED documentation, not a registered key
        fixtures = joinpath(pkgdir(D.FredAPI), "test", "fixtures")
        fixture_path(path) = joinpath(fixtures, replace(lstrip(path, '/'), "/" => "_") * ".json")

        # each tool, the endpoint path that it calls, and arguments that hold its required arguments -
        series = Dict{String,Any}("series_id" => "GNPCA")
        expected = [
            ("get_series", "/fred/series", series),
            ("get_series_categories", "/fred/series/categories", series),
            ("get_series_observations", "/fred/series/observations", series),
            ("get_series_release", "/fred/series/release", series),
            ("search_series", "/fred/series/search", Dict{String,Any}("search_text" => "natural gas")),
            ("search_series_tags", "/fred/series/search/tags", Dict{String,Any}("series_search_text" => "natural gas")),
            ("search_series_related_tags", "/fred/series/search/related_tags",
                Dict{String,Any}("series_search_text" => "natural gas", "tag_names" => "monthly;usa")),
            ("get_series_tags", "/fred/series/tags", series),
            ("get_series_updates", "/fred/series/updates", Dict{String,Any}()),
            ("get_series_vintage_dates", "/fred/series/vintagedates", series),
            ("get_category", "/fred/category", Dict{String,Any}()),
            ("get_category_children", "/fred/category/children", Dict{String,Any}("category_id" => 13)),
            ("get_category_related", "/fred/category/related", Dict{String,Any}("category_id" => 32073)),
            ("get_category_series", "/fred/category/series", Dict{String,Any}("category_id" => 125)),
            ("get_category_tags", "/fred/category/tags", Dict{String,Any}("category_id" => 125)),
            ("get_category_related_tags", "/fred/category/related_tags", Dict{String,Any}("category_id" => 125, "tag_names" => "services;quarterly")),
            ("get_releases", "/fred/releases", Dict{String,Any}()),
            ("get_releases_dates", "/fred/releases/dates", Dict{String,Any}("include_release_dates_with_no_data" => true)),
            ("get_release", "/fred/release", Dict{String,Any}("release_id" => 53)),
            ("get_release_dates", "/fred/release/dates", Dict{String,Any}("release_id" => 82)),
            ("get_release_series", "/fred/release/series", Dict{String,Any}("release_id" => 51)),
            ("get_release_sources", "/fred/release/sources", Dict{String,Any}("release_id" => 51)),
            ("get_release_tags", "/fred/release/tags", Dict{String,Any}("release_id" => 86)),
            ("get_release_related_tags", "/fred/release/related_tags", Dict{String,Any}("release_id" => 86, "tag_names" => "sa;foreign")),
            ("get_release_tables", "/fred/release/tables", Dict{String,Any}("release_id" => 53)),
            ("get_sources", "/fred/sources", Dict{String,Any}()),
            ("get_source", "/fred/source", Dict{String,Any}("source_id" => 1)),
            ("get_source_releases", "/fred/source/releases", Dict{String,Any}("source_id" => 1)),
            ("get_tags", "/fred/tags", Dict{String,Any}()),
            ("get_related_tags", "/fred/related_tags", Dict{String,Any}("tag_names" => "monetary aggregates;weekly")),
            ("get_tags_series", "/fred/tags/series", Dict{String,Any}("tag_names" => "slovenia;food")),
            ("get_maps_shapes", "/geofred/shapes/file", Dict{String,Any}("shape" => "state")),
            ("get_maps_series_group", "/geofred/series/group", Dict{String,Any}("series_id" => "SMU56000000500000001a")),
            ("get_maps_series_data", "/geofred/series/data", Dict{String,Any}("series_id" => "WIPCPI")),
            ("get_maps_regional_data", "/geofred/regional/data", Dict{String,Any}("series_group" => "882", "region_type" => "state",
                "date" => "2013-01-01", "season" => "NSA", "units" => "Dollars")),
            ("get_release_observations", "/fred/v2/release/observations", Dict{String,Any}("release_id" => 52, "limit" => 2)),
        ]

        @testset "one tool for each FredAPI endpoint" begin
            @test length(expected) == 36 && length(unique(first.(expected))) == 36
            paths = [entry[2] for entry in expected]
            @test length(unique(paths)) == 36
            # the FredAPI fixtures hold one response for each endpoint path of the package -
            @test Set(fixture_path(path) for path in paths) == Set(joinpath(fixtures, file) for file in readdir(fixtures))
            @test length(subtypes(D.FredAPI.AbstractFredEndpointModel)) == 36

            server = D.build_fred_server(Dict{String,Any}("baseurl" => "http://127.0.0.1:9", "apikey" => demo_key))
            @test sort(collect(keys(server.tools))) == sort(first.(expected))
            for (name, tool) in server.tools
                schema = tool.inputschema
                @test schema["type"] == "object" && schema["additionalProperties"] == false
                @test !haskey(schema["properties"], "apikey") # a call never sets the key
                @test issubset(schema["required"], keys(schema["properties"]))
                @test !isempty(tool.description)
                for (argument, property) in schema["properties"]
                    @test property["type"] in ("string", "integer", "boolean") && !isempty(property["description"])
                end
            end
            # the input schema follows the fields of the endpoint model -
            observations = server.tools["get_series_observations"].inputschema
            @test Set(keys(observations["properties"])) ==
                Set(String(f) for f in fieldnames(D.FredAPI.MyFredSeriesObservationsEndpointModel) if f != :apikey)
            @test observations["required"] == ["series_id"]
            @test observations["properties"]["limit"]["type"] == "integer"
            @test server.tools["get_release_tables"].inputschema["properties"]["include_observation_values"]["type"] == "boolean"
            @test server.tools["get_maps_regional_data"].inputschema["required"] == ["series_group", "region_type", "date", "season", "units"]
            @test occursin("search_rank", server.tools["search_series"].inputschema["properties"]["order_by"]["description"])
            @test occursin("series_count", server.tools["get_tags"].inputschema["properties"]["order_by"]["description"])
            @test server.tools["get_maps_regional_data"].inputschema["properties"]["units"]["description"] != observations["properties"]["units"]["description"]
            # tag_names selects the tags that a tags endpoint returns, and the series that a series endpoint returns -
            @test startswith(server.tools["get_tags"].inputschema["properties"]["tag_names"]["description"], "Tag names to return")
            @test startswith(server.tools["get_category_series"].inputschema["properties"]["tag_names"]["description"], "Tag names that every series")
            @test occursin("WIPCPI", server.tools["get_maps_series_data"].inputschema["properties"]["series_id"]["description"])
        end

        @testset "configuration" begin
            mktempdir() do folder
                path = joinpath(folder, "Configuration.toml")
                missing_file = D.load_server_configuration(path)
                @test haskey(missing_file, "setup_error") && !haskey(missing_file, "apikey")
                template = read(joinpath(L13D_ROOT, "conf", "Configuration-template.toml"), String)
                write(path, template)
                @test haskey(D.load_server_configuration(path), "setup_error") # the template holds no key
                write(path, replace(template, "paste-your-FRED-API-key-here" => demo_key))
                ready = D.load_server_configuration(path)
                @test ready == Dict("baseurl" => "https://api.stlouisfed.org", "apikey" => demo_key)
                write(path, "[connection]\napikey = \"$(demo_key)\"oops\n")
                broken = D.load_server_configuration(path)
                @test haskey(broken, "setup_error") && !occursin(demo_key, broken["setup_error"])

                # a server with no configuration still answers discover and list, and each tool reports the reason -
                server = D.build_fred_server(missing_file)
                @test D.process_message(server, mcp_line(1, "server/discover"))["result"]["supportedVersions"] == [MCP_VERSION]
                @test length(D.process_message(server, mcp_line(2, "tools/list"))["result"]["tools"]) == 36
                response = D.process_message(server, mcp_call_line(3, "search_series", Dict{String,Any}("search_text" => "gas")))
                @test response["result"]["isError"] == true && occursin("configuration file", result_text(response))
            end
            @test occursin("Configuration.toml", read(joinpath(L13D_ROOT, "conf", ".gitignore"), String))
            @test !isfile(joinpath(L13D_ROOT, "conf", "Configuration.toml")) ||
                !success(pipeline(`git -C $(L13D_ROOT) ls-files --error-unmatch conf/Configuration.toml`; stdout = devnull, stderr = devnull))
        end

        @testset "every tool against a local FRED" begin
            requests = Dict{String,String}[] # the path, the query without the key, and the key of each request
            long_rows = JSON.json(Dict("observations" => [Dict("date" => "2010-01-01", "value" => "3.00") for i in 1:2000]))
            function local_fred(request)
                uri = HTTP.URI(request.target)
                query = HTTP.queryparams(uri)
                key = get(query, "api_key", "")
                if uri.path == "/fred/v2/release/observations" # version 2 takes the key in the Authorization header
                    key = replace(HTTP.header(request, "Authorization"), "Bearer " => "")
                end
                push!(requests, Dict("path" => uri.path, "target" => request.target, "key" => key))
                json_type = ["Content-Type" => "application/json; charset=UTF-8"]
                if key != demo_key
                    return HTTP.Response(400, json_type, "{\"error_code\": 400, \"error_message\": \"Bad Request.  The api_key is not registered.\"}")
                end
                series_id = get(query, "series_id", "")
                if series_id == "NOTASERIES"
                    return HTTP.Response(400, json_type, "{\"error_code\": 400, \"error_message\": \"Bad Request.  The series does not exist.\"}")
                elseif series_id == "ECHO" # a careless upstream that repeats the request, with its key, in its error message
                    return HTTP.Response(400, json_type, JSON.json(Dict("error_code" => 400, "error_message" => "Bad Request for $(request.target)")))
                elseif series_id == "ECHO200" # a successful response that repeats the request, with its key
                    return HTTP.Response(200, json_type, JSON.json(Dict("request" => request.target)))
                elseif series_id == "LONG"
                    return HTTP.Response(200, json_type, long_rows)
                end
                if isfile(fixture_path(uri.path)) == false
                    return HTTP.Response(404, json_type, "{}")
                end
                return HTTP.Response(200, json_type, read(fixture_path(uri.path), String))
            end
            fred = HTTP.serve!(local_fred, "127.0.0.1", 8716; listenany = true, verbose = -1)
            try
                configuration = Dict{String,Any}("baseurl" => "http://127.0.0.1:$(HTTP.port(fred))", "apikey" => demo_key)
                server = D.build_fred_server(configuration)
                ask(line) = D.process_message(server, line)
                answers = String[] # every message that the server writes, to check that none holds the key

                # each tool calls its endpoint, and returns the JSON response of FRED -
                for (index, (name, path, arguments)) in enumerate(expected)
                    response = ask(mcp_call_line(index, name, arguments))
                    push!(answers, JSON.json(response))
                    @test response["result"]["isError"] == false
                    @test requests[end]["path"] == path
                    if name != "get_maps_shapes"
                        @test response["result"]["structuredContent"] == JSON.parse(read(fixture_path(path), String))
                    end
                end
                @test length(requests) == 36

                # the arguments of a call go into the query, encoded for a URL -
                ask(mcp_call_line(40, "search_series", Dict{String,Any}("search_text" => "natural gas&api_key=other", "limit" => 3)))
                query = HTTP.queryparams(HTTP.URI(requests[end]["target"]))
                @test query["search_text"] == "natural gas&api_key=other" && query["limit"] == "3" && query["api_key"] == demo_key
                ask(mcp_call_line(41, "get_releases_dates", Dict{String,Any}("include_release_dates_with_no_data" => true)))
                @test HTTP.queryparams(HTTP.URI(requests[end]["target"]))["include_release_dates_with_no_data"] == "true"

                # the shapes tool keeps the properties of each region, and leaves out the boundaries -
                shapes = ask(mcp_call_line(42, "get_maps_shapes", Dict{String,Any}("shape" => "state")))
                fixture = JSON.parse(read(fixture_path("/geofred/shapes/file"), String))
                @test shapes["result"]["structuredContent"]["regions"] == [feature["properties"] for feature in fixture["features"]]
                @test !occursin("coordinates", result_text(shapes))

                # version 2 sends the key in the Authorization header, not in the URL -
                ask(mcp_call_line(43, "get_release_observations", Dict{String,Any}("release_id" => 52, "limit" => 2)))
                @test requests[end]["key"] == demo_key && !occursin(demo_key, requests[end]["target"])

                # wrong arguments are tool execution errors, and they never reach FRED -
                number_of_requests = length(requests)
                for (name, arguments) in (("get_series", Dict{String,Any}("series_id" => "GNPCA", "apikey" => "x" ^ 32)),
                        ("get_series", Dict{String,Any}("series" => "GNPCA")),
                        ("get_series", Dict{String,Any}("series_id" => 42)),
                        ("get_release", Dict{String,Any}("release_id" => "53")),
                        ("get_release", Dict{String,Any}("release_id" => true)),
                        ("get_release", Dict{String,Any}("release_id" => 53.5)),
                        ("get_release_tables", Dict{String,Any}("release_id" => 53, "include_observation_values" => 1)))
                    response = ask(mcp_call_line(50, name, arguments))
                    push!(answers, JSON.json(response))
                    @test response["result"]["isError"] == true && startswith(result_text(response), "ArgumentError")
                end
                unknown = ask(mcp_call_line(51, "get_series", Dict{String,Any}("series" => "GNPCA")))
                @test occursin("unknown argument: series", result_text(unknown)) && occursin("series_id", result_text(unknown))
                @test length(requests) == number_of_requests

                # errors of FRED are tool execution errors with the message of FRED, and never show the key -
                missing_series = ask(mcp_call_line(52, "get_series", Dict{String,Any}("series_id" => "NOTASERIES")))
                push!(answers, JSON.json(missing_series))
                @test missing_series["result"]["isError"] == true && occursin("The series does not exist", result_text(missing_series))
                echoed = ask(mcp_call_line(53, "get_series", Dict{String,Any}("series_id" => "ECHO")))
                push!(answers, JSON.json(echoed))
                @test echoed["result"]["isError"] == true && occursin("<your API key>", result_text(echoed))
                echoed_success = ask(mcp_call_line(55, "get_series", Dict{String,Any}("series_id" => "ECHO200")))
                push!(answers, JSON.json(echoed_success))
                @test echoed_success["result"]["isError"] == true && occursin("holds the API key", result_text(echoed_success))

                # a result that is too long is a tool execution error that tells the model how to ask for less -
                long = ask(mcp_call_line(54, "get_series_observations", Dict{String,Any}("series_id" => "LONG")))
                push!(answers, JSON.json(long))
                @test long["result"]["isError"] == true && occursin("at most $(D.MAX_RESULT_CHARACTERS)", result_text(long))

                # the key went to FRED with every request, and never into an MCP message -
                @test all(request -> request["key"] == demo_key, requests)
                @test all(answer -> !occursin(demo_key, answer), answers)
            finally
                close(fred)
            end
        end

        @testset "server.jl as a subprocess" begin
            # the command of .mcp.json and .codex/config.toml. With no configuration file, the server still discovers and lists -
            command = `$(joinpath(Sys.BINDIR, "julia")) --startup-file=no $(joinpath(L13D_ROOT, "server.jl"))`
            client = D.connect(command)
            try
                @test D.discover(client)["result"]["_meta"]["io.modelcontextprotocol/serverInfo"]["name"] == "cheme-5800-fred"
                @test length(D.listtools(client)["result"]["tools"]) == 36
                close(client)
                @test success(client.process)
            finally
                process_running(client.process) && kill(client.process) # never leave a server behind
            end
        end

        @testset "host configuration and README" begin
            # Claude Code reads .mcp.json, and the Codex command-line tool reads .codex/config.toml -
            claude = JSON.parsefile(joinpath(L13D_ROOT, ".mcp.json"))["mcpServers"]["fred"]
            codex = TOML.parsefile(joinpath(L13D_ROOT, ".codex", "config.toml"))["mcp_servers"]["fred"]
            for entry in (claude, codex)
                @test entry["command"] == "julia" && entry["args"] == ["--startup-file=no", "server.jl"]
            end
            @test codex["startup_timeout_sec"] >= 60 && codex["default_tools_approval_mode"] == "prompt"

            # the lab has a README of experiments, no notebook, and no student TODOs -
            readme_path = joinpath(L13D_ROOT, "README.md")
            readme = read(readme_path, String)
            @test isempty(filter(file -> endswith(file, ".ipynb"), readdir(L13D_ROOT)))
            for target in [m.captures[1] for m in eachmatch(r"\]\(([^)\s]+)\)", readme)]
                startswith(target, "http") && continue
                @test ispath(joinpath(L13D_ROOT, target))
            end
            for experiment in 1:6
                @test occursin("__Experiment $(experiment):", readme)
            end
            sources = [joinpath(folder, file) for (folder, _, files) in walkdir(joinpath(L13D_ROOT, "src")) for file in files if endswith(file, ".jl")]
            @test all(path -> !occursin("TODO", read(path, String)), sources)
            @test !isdir(joinpath(L13D_ROOT, "src", "solution"))

            # no file that ships holds a key: the only 32 character key-like text is the example key of the documentation -
            shipped = vcat([readme_path, joinpath(L13D_ROOT, "Include.jl"), joinpath(L13D_ROOT, "server.jl"), joinpath(L13D_ROOT, ".mcp.json"),
                joinpath(L13D_ROOT, ".codex", "config.toml"), joinpath(L13D_ROOT, "conf", "Configuration-template.toml")], sources)
            for path in shipped
                keys_found = [m.match for m in eachmatch(r"(?<![a-z0-9])[a-z0-9]{32}(?![a-z0-9])", read(path, String))]
                @test all(key -> key == demo_key, keys_found)
            end
        end
    end
end

@meeting "L13c" "L13d" begin
    @testset "L13c and L13d share the MCP server and client" begin
        for file in ("Server.jl", "Client.jl")
            @test read(joinpath(WEEK_ROOT, "L13c", "src", file), String) == read(joinpath(WEEK_ROOT, "L13d", "src", file), String)
        end
    end
end
