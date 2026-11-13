const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the fixtures and the notebooks whose links the suite checks
import LinearAlgebra: norm  # the residual check on the urea-cycle fixture
import HTTP  # the local server that stands in for FRED in the L13b tests
import Dates: Date  # the dates of the L13b observations
using Test   # @testset must be defined when the file is parsed, even if no meeting that loads it is released
released("L13a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13a", "Include.jl"))
released("L13b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-13", "L13b", "Include.jl"))

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

        @testset "student file and reference solution" begin
            student_path = joinpath(L13B_ROOT, "src", "Compute.jl")
            solution_path = joinpath(L13B_ROOT, "src", "Compute-solution.jl")
            student_text = read(student_path, String)
            solution_text = read(solution_path, String)

            # the two files hold the same code outside the three TODO lines -
            function code_lines(text)
                lines = String[]
                for line in split(split(text, "module L13bObservations"; limit = 2)[2], '\n')
                    stripped = strip(line)
                    (isempty(stripped) || startswith(stripped, "#")) && continue
                    any(startswith(stripped, start) for start in ("url_string = ", "date = ", "value = nothing", "value = parse")) && continue
                    push!(lines, String(line))
                end
                return lines
            end
            @test code_lines(student_text) == code_lines(solution_text)
            @test count("TODO 1", student_text) ≥ 1 && count("TODO 2", student_text) ≥ 1 && count("TODO 3", student_text) ≥ 1
            @test count("Hint:", student_text) == 3 # one hint per TODO
            for answer in ("observations?series_id=", "Date(date_string)", "parse(Float64, value_string)")
                @test !occursin(answer, student_text) # the student file omits the answers
                @test occursin(answer, solution_text)
            end

            # the untouched student file throws the house error from both functions -
            include(student_path)
            @test Set(names(Base.invokelatest(getglobal, Main, :L13bObservations))) ==
                Set([:L13bObservations, :process_observations_response_dataframe])
            @test_throws ErrorException Base.invokelatest(build, base, observations_model)
            stub_handler = Base.invokelatest(getglobal, Base.invokelatest(getglobal, Main, :L13bObservations),
                :process_observations_response_dataframe)
            @test_throws ErrorException Base.invokelatest(stub_handler, MyFredSeriesObservationsEndpointModel, observations_body)

            # the reference solution: the URL, then the table -
            include(solution_path)
            url = Base.invokelatest(build, base, observations_model)
            @test url == "$(base)/fred/series/observations?series_id=DHHNGSP&observation_start=2025-01-01" *
                "&observation_end=2025-01-08&frequency=d&units=lin&api_key=$(demo_key)&file_type=json"
            handler = Base.invokelatest(getglobal, Base.invokelatest(getglobal, Main, :L13bObservations),
                :process_observations_response_dataframe)
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
                live_table = MyFredSeriesObservationsEndpointModel(Base.invokelatest(build, local_base, observations_model); handler = handler)
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

            # running the setup file again replaces the student module, and nothing brings its names into Main -
            include(joinpath(L13B_ROOT, "Include.jl"))
            include(joinpath(L13B_ROOT, "Include.jl"))
            @test Base.invokelatest(getglobal, Main, :L13bObservations) isa Module
            @test !Base.invokelatest(isdefined, Main, :process_observations_response_dataframe)
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
            # the notebook calls the student's handler by its qualified name, and reads the key from the file -
            notebook_code = join(code_cells, "\n")
            @test occursin("L13bObservations.process_observations_response_dataframe", notebook_code)
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

@meeting "L13b" begin
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
end
