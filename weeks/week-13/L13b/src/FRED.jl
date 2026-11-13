module L13bFRED

    # load external packages -
    import HTTP # make the HTTP calls to FRED, and encode text for a URL
    import JSON # parse the JSON text that FRED returns
    import Dates: Date # the type of a calendar date, for the observation dates
    import DataFrames: DataFrame # table for the search results
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    # what do we want to export?
    export AbstractFredEndpointModel
    export MyFredSeriesSearchEndpointModel, MyFredSeriesEndpointModel, MyFredSeriesObservationsEndpointModel
    export process_search_response_dataframe, process_observations_response_dataframe

    # load my codes. In this lab, you complete one build method in Factory.jl and one handler in Handler.jl -
    include("Types.jl")   # the endpoint models
    include("Factory.jl") # the build methods for the request URLs
    include("Handler.jl") # the functions that process the responses
    include("Network.jl") # the HTTP calls
end
