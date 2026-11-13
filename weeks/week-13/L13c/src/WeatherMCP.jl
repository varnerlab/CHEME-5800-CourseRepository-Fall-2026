module L13cWeatherMCP

    # load external packages -
    import HTTP # make the HTTP calls to the weather service
    import JSON # parse and write JSON text: the weather service responses, and the MCP messages
    import DataFrames: DataFrame, nrow # table for the processed forecast
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    # what do we want to export?
    export MyWeatherGridPointEndpointModel, MyWeatherForecastEndpointModel, process_forecast_response_dataframe
    export MyMCPToolModel, MyMCPServerModel, MyMCPClientModel
    export process_message, serve, build_weather_server
    export connect, send_request, discover, listtools, calltool

    # load my codes -
    include("Types.jl")   # the weather service endpoint models, and the MCP tool, server, and client models
    include("Factory.jl") # the build methods: request URLs, tools, and servers
    include("Network.jl") # the HTTP calls to the weather service
    include("Handler.jl") # the functions that process the weather service responses
    include("Tools.jl")   # the two tools of the weather server
    include("Server.jl")  # the MCP server: process one message, and the server loop
    include("Client.jl")  # the MCP client: start a server, and send it requests
end
