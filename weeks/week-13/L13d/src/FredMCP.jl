module L13dFredMCP

    # load external packages -
    import FredAPI # the FRED SDK: one endpoint model for each endpoint, url(...) for the request URLs, and api(...) for the calls
    import JSON # write JSON text: the MCP messages, and the length check of a result
    import TOML # read the configuration file that holds the API key
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    # what do we want to export?
    export MyMCPToolModel, MyMCPServerModel, MyMCPClientModel
    export load_server_configuration
    export process_message, serve, build_fred_server
    export connect, send_request, discover, listtools, calltool

    # load my codes. The FRED calls go through the FredAPI package -
    include("Types.jl")   # the MCP tool, server, and client models
    include("Factory.jl") # build(...) for tools and servers
    include("Utility.jl") # read the configuration file that holds the API key
    include("Tools.jl")   # how a FRED tool works: the arguments, the input schema, and the call to FRED
    include("Catalog.jl") # the 36 tools of the FRED server, one for each endpoint of the FRED API
    include("Server.jl")  # the MCP server: process one message, and the server loop
    include("Client.jl")  # the MCP client: start a server, and send it requests
end
