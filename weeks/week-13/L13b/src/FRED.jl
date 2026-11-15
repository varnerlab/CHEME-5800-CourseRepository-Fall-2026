module L13bFRED

    # load external packages -
    import HTTP # make the HTTP calls to FRED, and encode text for a URL
    import JSON # parse the JSON text that FRED returns
    import Dates: Date # the type of a calendar date, for the observation dates
    import DataFrames: DataFrame # table for the search results

    # what do we want to export?
    export url, api
    export AbstractFredEndpointModel
    export MyFredSeriesSearchEndpointModel, MyFredSeriesEndpointModel, MyFredSeriesObservationsEndpointModel
    export process_search_response_dataframe, process_observations_response_dataframe

    # load my codes. In this lab, you complete one url(...) method in Factory.jl and one handler in Handler.jl -
    include("Types.jl")   # the endpoint models
    include("Network.jl") # the HTTP calls

    # These call the student versions, comment out these lines, and load the solution versions to see how they work.
    include("Factory.jl") # the url(...) methods for the request URLs
    include("Handler.jl") # the functions that process the responses

    # uncomment the next two lines to load the solutions for Factory.jl and Handler.jl. The solution code is in the `solution` subdirectory.
    # include(joinpath(@__DIR__, "solution", "Factory-solution.jl")) # the url(...) methods for the request URLs
    # include(joinpath(@__DIR__, "solution", "Handler-solution.jl")) # the functions that process the responses
end
