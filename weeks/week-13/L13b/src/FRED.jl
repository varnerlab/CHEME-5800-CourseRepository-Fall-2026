module L13bFRED

    # load external packages -
    import HTTP # make the HTTP calls to FRED, and encode text for a URL
    import JSON # parse the JSON text that FRED returns
    import DataFrames: DataFrame # table for the search results
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    # what do we want to export?
    export AbstractFredEndpointModel
    export MyFredSeriesSearchEndpointModel, MyFredSeriesEndpointModel, MyFredSeriesObservationsEndpointModel
    export process_search_response_dataframe

    # load my codes -
    include("Types.jl")   # the endpoint models
    include("Factory.jl") # the build methods for the request URLs
    include("Handler.jl") # the functions that process the responses
    include("Network.jl") # the HTTP calls
end
