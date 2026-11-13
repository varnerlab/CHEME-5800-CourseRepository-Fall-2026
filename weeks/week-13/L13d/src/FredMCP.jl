module L13dFredMCP

    # load external packages -
    import HTTP # make the HTTP calls to FRED, and encode text for a URL
    import JSON # parse and write JSON text: the FRED responses, and the MCP messages
    import TOML # read the configuration file that holds the API key
    import Dates: Date # the type of a calendar date, for the observation dates
    import DataFrames: DataFrame, nrow # tables for the search results and the observations
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    # what do we want to export?
    export AbstractFredEndpointModel
    export MyFredSeriesSearchEndpointModel, MyFredSeriesEndpointModel, MyFredSeriesObservationsEndpointModel
    export process_search_response_dataframe, process_observations_response_dataframe
    export MyMCPToolModel, MyMCPServerModel, MyMCPClientModel
    export read_configuration, load_server_configuration
    export process_message, serve, build_fred_server
    export connect, send_request, discover, listtools, calltool

    # load my codes. In this lab, you complete one tool in Tools.jl -
    include("Types.jl")   # the FRED endpoint models, and the MCP tool, server, and client models
    include("Factory.jl") # the build methods: request URLs, tools, and servers
    include("Network.jl") # the HTTP calls to FRED
    include("Handler.jl") # the functions that process the FRED responses
    include("Utility.jl") # read the configuration file that holds the API key
    include("Tools.jl")   # the three tools of the FRED server (you complete one)
    include("Server.jl")  # the MCP server: process one message, and the server loop
    include("Client.jl")  # the MCP client: start a server, and send it requests
end
