const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the fixtures and the notebooks whose links the suite checks
import HTTP  # the local server that stands in for FRED in the L13b tests
import Dates  # Dates.Day, for the long request of the L13d tests
import Dates: Date  # the dates of the L13b and L13d observations
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

# The L13a tests run without the network: the handlers are tested on the committed fixtures.
# The example notebook calls the live National Weather Service API, so the suite does not run it.
@meeting "L13a" begin
    @testset "L13a weather service code" begin
        # the endpoint model and its URL -
        model = MyWeatherGridPointEndpointModel(latitude = 42.443961, longitude = -76.501881)
        @test model isa L13aNWS.AbstractWeatherEndpointModel
        @test build("https://api.weather.gov", model) == "https://api.weather.gov/points/42.443961,-76.501881"
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
        @test_throws ArgumentError MyWeatherGridPointEndpointModel("api.weather.gov/points/42,-76")
        @test_throws ArgumentError L13aNWS._http_get_call_with_url("not a url")
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
            @test build(base, search_model) ==
                "$(base)/fred/series/search?search_text=natural%20gas&limit=5&api_key=$(demo_key)&file_type=json"
            series_model = MyFredSeriesEndpointModel(apikey = demo_key, series_id = "DHHNGSP")
            @test build(base, series_model) == "$(base)/fred/series?series_id=DHHNGSP&api_key=$(demo_key)&file_type=json"
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
            # the student edits two files of the SDK; each has a reference solution beside it -
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
                solution_text = read(joinpath(L13B_ROOT, "src", solution), String)
                @test code_lines(student_text) == code_lines(solution_text) # the same code outside the TODO lines
            end
            factory_text = read(joinpath(L13B_ROOT, "src", "Factory.jl"), String)
            handler_text = read(joinpath(L13B_ROOT, "src", "Handler.jl"), String)
            @test occursin("TODO 1", factory_text) && count("Hint:", factory_text) == 1
            @test occursin("TODO 2", handler_text) && occursin("TODO 3", handler_text) && count("Hint:", handler_text) == 2
            for (answer, student, solution) in (("observations?series_id=", "Factory.jl", "Factory-solution.jl"),
                    ("Date(date_string)", "Handler.jl", "Handler-solution.jl"), ("parse(Float64, value_string)", "Handler.jl", "Handler-solution.jl"))
                @test !occursin(answer, read(joinpath(L13B_ROOT, "src", student), String)) # the student file omits the answer
                @test occursin(answer, read(joinpath(L13B_ROOT, "src", solution), String))
            end
            @test :process_observations_response_dataframe in names(L13bFRED)

            # the setup file loaded the untouched student files: both functions throw the house error -
            @test_throws ErrorException build(base, observations_model)
            @test_throws ErrorException process_observations_response_dataframe(MyFredSeriesObservationsEndpointModel, observations_body)

            # the reference solutions, loaded into the module in place of the student files -
            for (student, solution) in pairs
                Base.include(L13bFRED, joinpath(L13B_ROOT, "src", solution))
            end
            url = Base.invokelatest(build, base, observations_model)
            @test url == "$(base)/fred/series/observations?series_id=DHHNGSP&observation_start=2025-01-01" *
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
                description = MyFredSeriesEndpointModel(build(local_base, MyFredSeriesEndpointModel(apikey = demo_key, series_id = "DHHNGSP")))
                @test description["seriess"][1]["id"] == "DHHNGSP"
                found = MyFredSeriesSearchEndpointModel(build(local_base, MyFredSeriesSearchEndpointModel(apikey = demo_key,
                    search_text = "natural gas", limit = 5)); handler = process_search_response_dataframe)
                @test found.id == ["DHHNGSP", "MHHNGSP"]
                live_table = Base.invokelatest(MyFredSeriesObservationsEndpointModel, Base.invokelatest(build, local_base, observations_model);
                    handler = handler)
                @test isequal(live_table.value, [missing, 3.65, 3.40, 4.05, 3.80, 3.75])

                # a failed call: the message has the status code and the description from FRED, and never the key -
                wrong_key = "00000000000000000000000000000000"
                failure = try
                    MyFredSeriesEndpointModel(build(local_base, MyFredSeriesEndpointModel(apikey = wrong_key, series_id = "DHHNGSP")))
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
                MyFredSeriesEndpointModel("http://127.0.0.1:9/fred/series?api_key=$(demo_key)")
                nothing
            catch exception
                exception
            end
            @test unreachable isa ArgumentError && !occursin(demo_key, unreachable.msg)
            malformed = try
                MyFredSeriesEndpointModel("api.stlouisfed.org/fred/series?api_key=$(demo_key)")
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
            append!(shipped, [joinpath(L13B_ROOT, "src", file) for file in readdir(joinpath(L13B_ROOT, "src"))])
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
                @test null_meta["error"]["code"] == -32022 && null_meta["id"] == 14 # the id survives
                text_arguments = replace(mcp_call_line(15, "get_location", ithaca), r"\"arguments\":\{[^}]*\}" => "\"arguments\":\"Ithaca\"")
                @test ask(text_arguments)["error"]["code"] == -32602 # the arguments must be a JSON object
                @test ask("{\"jsonrpc\": \"2.0\", \"id\": 10, \"method\": \"tools/list\", \"params\": 3}")["error"]["code"] == -32602
                @test ask("{\"jsonrpc\": \"2.0\", \"method\": \"notifications/cancelled\", \"params\": {}}") === nothing
                old = ask(mcp_line(11, "tools/list"; version = "2025-06-18"))
                @test old["error"]["code"] == -32022
                @test old["error"]["data"]["supported"] == [MCP_VERSION] && old["error"]["data"]["requested"] == "2025-06-18"
                @test ask(mcp_line(12, "tools/list"; version = nothing))["error"]["code"] == -32022 # no _meta
                initialize = JSON.json(Dict("jsonrpc" => "2.0", "id" => 13, "method" => "initialize",
                    "params" => Dict("protocolVersion" => "2025-06-18", "capabilities" => Dict())))
                @test ask(initialize)["error"]["code"] == -32022 # the handshake of earlier versions
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
            for figure in ("Fig-MCP-Architecture", "Fig-MCP-ToolCall")
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
            @test count(cell -> !isempty(cell["outputs"]), code_cells) >= 8
            @test all(output["output_type"] != "error" for cell in code_cells for output in cell["outputs"])
            outputs_text = JSON.json([cell["outputs"] for cell in code_cells])
            @test !occursin("/Users/", outputs_text) && !occursin(homedir(), outputs_text)
            @test occursin("Weather server", outputs_text) && occursin("Pass", outputs_text) # the check cell ran and passed
        end
    end
end

# The L13d tests need no FRED API key and no outside network. The FRED server runs in this process
# against a small server on this machine that answers like FRED, with the committed fixtures.
@meeting "L13d" begin
    @testset "L13d FRED MCP lab" begin
        D = L13dFredMCP
        L13D_ROOT = joinpath(WEEK_ROOT, "L13d")
        demo_key = "abcdefghijklmnopqrstuvwxyz123456" # the example key of the FRED documentation, not a registered key
        search_body = read(joinpath(DATA_DIR, "fred-series-search.fixture.json"), String)
        series_body = read(joinpath(DATA_DIR, "fred-series.fixture.json"), String)
        observations_body = read(joinpath(DATA_DIR, "fred-series-observations.fixture.json"), String)
        error_body = read(joinpath(DATA_DIR, "fred-error.fixture.json"), String)

        @testset "student file and reference solution" begin
            student_text = read(joinpath(L13D_ROOT, "src", "Tools.jl"), String)
            solution_text = read(joinpath(L13D_ROOT, "src", "Tools-solution.jl"), String)
            # cut each TODO region, from its comment to the first complete line after it, then compare the code -
            function without_todos(text)
                text = replace(text, r"# TODO 1.*?(?=\n\s*observations_tool = build)"s => "# TODO 1")
                text = replace(text, r"# TODO 2.*?(?=\n\s*if \(isnothing\(table\))"s => "# TODO 2")
                text = replace(text, r"# TODO 3.*?(?=\n\s*if \(isnothing\(observation\))"s => "# TODO 3")
                return [String(line) for line in split(text, '\n') if !isempty(strip(line)) && !startswith(strip(line), "#")]
            end
            @test without_todos(student_text) == without_todos(solution_text)
            @test length(without_todos(student_text)) > 150 # the cut regions are small
            for todo in ("TODO 1", "TODO 2", "TODO 3")
                @test occursin(todo, student_text) && occursin(todo, solution_text)
            end
            @test count("Hint:", student_text) == 3 && count("Hint:", solution_text) == 0
            @test occursin("table = nothing;", student_text) && occursin("observation = nothing;", student_text)
            @test !occursin("process_observations_response_dataframe);", student_text) # the student file omits the answer
            @test occursin("handler = process_observations_response_dataframe);", solution_text)

            # the module loaded the untouched student file: the observations tool throws the house error,
            # and its input schema is empty -
            configuration = Dict{String,Any}("baseurl" => "http://127.0.0.1:9", "apikey" => demo_key) # no server answers here
            arguments = Dict{String,Any}("series_id" => "DHHNGSP", "observation_start" => "2025-01-01", "observation_end" => "2025-01-08")
            house = try
                D.get_series_observations(arguments, configuration)
                nothing
            catch exception
                exception
            end
            @test house isa ErrorException && startswith(house.msg, "Oooops!")
            student_server = D.build_fred_server(configuration)
            response = D.process_message(student_server, mcp_call_line(1, "get_series_observations", arguments))
            @test response["result"]["isError"] == true && startswith(result_text(response), "Oooops!")
            schema = student_server.tools["get_series_observations"].inputschema
            @test isempty(schema["properties"]) && isempty(schema["required"])

            # the supplied argument checks: a trailing newline, a date in another form, and a boolean limit -
            for (key, value) in (("series_id", "DHHNGSP\n"), ("observation_start", "2025-1-001"), ("observation_end", "20250108"))
                @test_throws ArgumentError D.get_series_observations(merge(arguments, Dict{String,Any}(key => value)), configuration)
            end
            @test_throws ArgumentError D.search_series(Dict{String,Any}("search_text" => "gas", "limit" => true), configuration)
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
                @test length(D.process_message(server, mcp_line(2, "tools/list"))["result"]["tools"]) == 3
                response = D.process_message(server, mcp_call_line(3, "search_series", Dict{String,Any}("search_text" => "gas")))
                @test response["result"]["isError"] == true && occursin("configuration file", result_text(response))
            end
            @test occursin("Configuration.toml", read(joinpath(L13D_ROOT, "conf", ".gitignore"), String))
            @test !isfile(joinpath(L13D_ROOT, "conf", "Configuration.toml")) ||
                !success(pipeline(`git -C $(L13D_ROOT) ls-files --error-unmatch conf/Configuration.toml`; stdout = devnull, stderr = devnull))
        end

        @testset "reference solution against a local FRED" begin
            # load the reference solution into the module in place of the student file -
            Base.include(D, joinpath(L13D_ROOT, "src", "Tools-solution.jl"))
            requests = String[] # every request that reaches the local FRED
            function local_fred(request)
                push!(requests, request.target)
                uri = HTTP.URI(request.target)
                query = HTTP.queryparams(uri)
                json_type = ["Content-Type" => "application/json; charset=UTF-8"]
                if get(query, "api_key", "") != demo_key || get(query, "file_type", "") != "json"
                    return HTTP.Response(400, json_type, error_body)
                end
                if uri.path == "/fred/series/search"
                    return HTTP.Response(200, json_type, search_body)
                elseif uri.path == "/fred/series" && get(query, "series_id", "") == "DHHNGSP"
                    return HTTP.Response(200, json_type, series_body)
                elseif uri.path == "/fred/series" && get(query, "series_id", "") == "ECHO"
                    # a careless upstream that repeats the request, with its key, in its error message -
                    echo = JSON.json(Dict("error_code" => 400, "error_message" => "Bad Request for $(request.target)"))
                    return HTTP.Response(400, json_type, echo)
                elseif uri.path == "/fred/series/observations" && get(query, "series_id", "") == "DHHNGSP"
                    if get(query, "units", "") != "lin"
                        return HTTP.Response(400, json_type, error_body)
                    end
                    if get(query, "observation_start", "") == "2010-01-01" # a long request: 500 observations
                        rows = [Dict("date" => string(Date(2010, 1, 1) + Dates.Day(i)), "value" => "3.00") for i in 0:499]
                        return HTTP.Response(200, json_type, JSON.json(Dict("observations" => rows)))
                    end
                    return HTTP.Response(200, json_type, observations_body)
                end
                return HTTP.Response(400, json_type, error_body)
            end
            fred = HTTP.serve!(local_fred, "127.0.0.1", 8716; listenany = true)
            try
                configuration = Dict{String,Any}("baseurl" => "http://127.0.0.1:$(HTTP.port(fred))", "apikey" => demo_key)
                server = Base.invokelatest(D.build_fred_server, configuration)
                ask(line) = Base.invokelatest(D.process_message, server, line)
                answers = String[] # every message that the server writes, to check that none holds the key

                listed = ask(mcp_line(1, "tools/list"))
                push!(answers, JSON.json(listed))
                tools = listed["result"]["tools"]
                @test [tool["name"] for tool in tools] == ["get_series_info", "get_series_observations", "search_series"]
                @test listed["result"]["ttlMs"] == 3600000 && listed["result"]["cacheScope"] == "public"
                schema = tools[2]["inputSchema"]
                @test Set(keys(schema["properties"])) == Set(["series_id", "observation_start", "observation_end", "frequency"])
                @test Set(schema["required"]) == Set(["series_id", "observation_start", "observation_end"])

                found = ask(mcp_call_line(2, "search_series", Dict{String,Any}("search_text" => "Henry Hub", "limit" => 5)))
                push!(answers, JSON.json(found))
                @test [entry["series_id"] for entry in found["result"]["structuredContent"]["series"]] == ["DHHNGSP", "MHHNGSP"]
                search_query = HTTP.queryparams(HTTP.URI(requests[end]))
                @test search_query["search_text"] == "Henry Hub" && search_query["limit"] == "5"
                info = ask(mcp_call_line(3, "get_series_info", Dict{String,Any}("series_id" => "DHHNGSP")))
                push!(answers, JSON.json(info))
                @test info["result"]["structuredContent"]["units"] == "Dollars per Million BTU"

                daily = Dict{String,Any}("series_id" => "DHHNGSP", "observation_start" => "2025-01-01",
                    "observation_end" => "2025-01-08", "frequency" => "d")
                observed = ask(mcp_call_line(4, "get_series_observations", daily))
                push!(answers, JSON.json(observed))
                result = observed["result"]
                @test result["isError"] == false
                @test result["structuredContent"]["series_id"] == "DHHNGSP" && result["structuredContent"]["frequency"] == "d"
                observations = result["structuredContent"]["observations"]
                @test [o["date"] for o in observations] == ["2025-01-01", "2025-01-02", "2025-01-03", "2025-01-06", "2025-01-07", "2025-01-08"]
                @test ismissing(observations[1]["value"]) # FRED has no value for January 1
                @test occursin("{\"date\":\"2025-01-01\",\"value\":null}", result_text(observed)) # missing becomes null in the text
                @test [o["value"] for o in observations[2:end]] == [3.65, 3.40, 4.05, 3.80, 3.75]
                @test Dict(HTTP.queryparams(HTTP.URI(requests[end]))) == Dict("series_id" => "DHHNGSP", "observation_start" => "2025-01-01",
                    "observation_end" => "2025-01-08", "frequency" => "d", "units" => "lin", "api_key" => demo_key, "file_type" => "json")
                monthly = ask(mcp_call_line(5, "get_series_observations", delete!(copy(daily), "frequency")))
                @test monthly["result"]["structuredContent"]["frequency"] == "m" # the default frequency
                @test occursin("frequency=m", requests[end])

                # wrong arguments are tool execution errors; the ones that would change the URL never reach FRED -
                number_of_requests = length(requests)
                for arguments in (merge(daily, Dict{String,Any}("series_id" => "DHHNGSP&units=pch")),
                        merge(daily, Dict{String,Any}("observation_start" => "2025-13-01")),
                        merge(daily, Dict{String,Any}("observation_end" => "Jan 8")),
                        merge(daily, Dict{String,Any}("frequency" => "x")),
                        delete!(copy(daily), "series_id"))
                    response = ask(mcp_call_line(6, "get_series_observations", arguments))
                    push!(answers, JSON.json(response))
                    @test response["result"]["isError"] == true && startswith(result_text(response), "ArgumentError")
                end
                limit = ask(mcp_call_line(7, "search_series", Dict{String,Any}("search_text" => "gas", "limit" => 0)))
                @test limit["result"]["isError"] == true
                @test length(requests) == number_of_requests
                long = ask(mcp_call_line(8, "get_series_observations", merge(daily, Dict{String,Any}("observation_start" => "2010-01-01"))))
                push!(answers, JSON.json(long))
                @test long["result"]["isError"] == true && occursin("at most 400", result_text(long))
                unknown = ask(mcp_call_line(9, "get_series_info", Dict{String,Any}("series_id" => "NOTASERIES")))
                push!(answers, JSON.json(unknown))
                echoed = ask(mcp_call_line(10, "get_series_info", Dict{String,Any}("series_id" => "ECHO")))
                push!(answers, JSON.json(echoed))
                @test echoed["result"]["isError"] == true && occursin("<your API key>", result_text(echoed))
                @test unknown["result"]["isError"] == true && occursin("400", result_text(unknown))

                # the key went to FRED in every request, and never into an MCP message -
                @test all(target -> occursin("api_key=$(demo_key)", target), requests)
                @test all(answer -> !occursin(demo_key, answer), answers)
            finally
                close(fred)
            end
        end

        @testset "server.jl as a subprocess" begin
            # the command of the notebook. With no configuration file, the server still discovers and lists -
            command = `$(joinpath(Sys.BINDIR, "julia")) --startup-file=no --project=$(normpath(joinpath(WEEK_ROOT, "..", ".."))) $(joinpath(L13D_ROOT, "server.jl"))`
            client = D.connect(command)
            try
                @test D.discover(client)["result"]["_meta"]["io.modelcontextprotocol/serverInfo"]["name"] == "cheme-5800-fred"
                @test length(D.listtools(client)["result"]["tools"]) == 3
                close(client)
                @test success(client.process)
            finally
                process_running(client.process) && kill(client.process) # never leave a server behind
            end
        end

        @testset "L13d lab notebook" begin
            notebook = "CHEME-5800-L13d-Lab-MCP-FRED-Fall-2026.ipynb"
            text = check_notebook_frame("L13d", notebook)
            @test occursin("__TODO 1:__", text) && occursin("__TODO 2:__", text) && occursin("__TODO 3:__", text)
            cells = JSON.parsefile(joinpath(L13D_ROOT, notebook))["cells"]
            code_cells = [cell for cell in cells if cell["cell_type"] == "code"]
            @test length(code_cells) >= 10
            @test all(isempty(cell["outputs"]) for cell in code_cells) # the lab ships without outputs
            for cell in code_cells
                parsed = Meta.parseall(join(cell["source"]))
                @test !(parsed.args[end] isa Expr && parsed.args[end].head in (:error, :incomplete)) # every cell parses
            end
            notebook_code = join([join(cell["source"]) for cell in code_cells], "\n")
            @test occursin("connect(server_command)", notebook_code)
            @test !occursin("read_configuration", notebook_code) # the notebook never reads the key

            # no file that ships holds a key: the only 32 character key-like text is the example key of the documentation -
            shipped = [joinpath(L13D_ROOT, notebook), joinpath(L13D_ROOT, "Include.jl"), joinpath(L13D_ROOT, "server.jl"),
                joinpath(L13D_ROOT, "conf", "Configuration-template.toml")]
            append!(shipped, [joinpath(L13D_ROOT, "src", file) for file in readdir(joinpath(L13D_ROOT, "src"))])
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
