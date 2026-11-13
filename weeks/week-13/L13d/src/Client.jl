# =============================================================================
# The MCP client: start a server as a subprocess, send it requests, and read
# its responses. In this notebook, we play the host, so we use these functions
# to make the calls that a host would make for its language model.
# =============================================================================

# --- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #
# Print a message as indented JSON text, under a label that says which way it travels -
function _show_message(label::String, message::AbstractDict)
    println(label);
    println(JSON.json(message; pretty = true));
end
# --- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    connect(command::Cmd; verbose::Bool = false) -> MyMCPClientModel

Start an MCP server as a subprocess, and return a client that is connected to it.

### Arguments
- `command::Cmd`: the command that starts the server, e.g., `` `julia --project=... server.jl` ``.
- `verbose::Bool = false`: when `true`, the client prints every message that it sends and receives.

### Returns
- `MyMCPClientModel`: the client. Close it with `close(client)` when you are done.
"""
function connect(command::Cmd; verbose::Bool = false)::MyMCPClientModel

    # start the server. The "r+" mode connects to both the standard input and the standard output of the subprocess -
    client = MyMCPClientModel();
    client.process = open(command, "r+");
    client.requestid = 0;
    client.verbose = verbose;

    # return the client -
    return client;
end

"""
    send_request(client::MyMCPClientModel, method::String, params::Dict{String,Any}) -> Dict{String,Any}

Send one JSON-RPC request to the server, and return the response of the server.

The function adds the `_meta` field that protocol version 2026-07-28 requires on every request:
the protocol version, the capabilities of the client, and the name of the client.

### Arguments
- `client::MyMCPClientModel`: the client, connected to a server.
- `method::String`: the method of the request, e.g., `"tools/list"`.
- `params::Dict{String,Any}`: the parameters of the request. Use an empty dictionary when the method takes none.

### Returns
- `Dict{String,Any}`: the response message, with either a `result` field or an `error` field.
"""
function send_request(client::MyMCPClientModel, method::String, params::Dict{String,Any})::Dict{String,Any}

    # copy the parameters, so we do not change the dictionary of the caller -
    params = copy(params);

    # every request carries the protocol version, the client capabilities, and the client name in _meta -
    meta = Dict{String,Any}();
    meta["io.modelcontextprotocol/protocolVersion"] = "2026-07-28";
    meta["io.modelcontextprotocol/clientCapabilities"] = Dict{String,Any}(); # this client asks for no optional features
    meta["io.modelcontextprotocol/clientInfo"] = Dict{String,Any}("name" => "cheme-5800-notebook", "version" => "1.0.0");
    params["_meta"] = meta;

    # the request message. Each request gets a new id, and the response carries the same id -
    client.requestid = client.requestid + 1;
    request = Dict{String,Any}();
    request["jsonrpc"] = "2.0";
    request["id"] = client.requestid;
    request["method"] = method;
    request["params"] = params;

    # send the request as one line of JSON text -
    if (client.verbose == true)
        _show_message("Client → Server", request);
    end
    println(client.process, JSON.json(request));
    flush(client.process);

    # read one line from the server, and parse it -
    line = readline(client.process);
    if (isempty(line) == true)
        throw(ErrorException("the server closed the connection"));
    end
    response = JSON.parse(line);
    if (client.verbose == true)
        _show_message("Server → Client", response);
    end

    # the response must answer this request: it carries the same id -
    if (get(response, "id", nothing) != client.requestid)
        throw(ErrorException("the server answered with id $(get(response, "id", nothing)), not $(client.requestid)"));
    end

    # return the response -
    return response;
end

"""
    discover(client::MyMCPClientModel) -> Dict{String,Any}

Send a `server/discover` request: ask the server for its protocol versions, its capabilities, and its identity.
"""
function discover(client::MyMCPClientModel)::Dict{String,Any}
    return send_request(client, "server/discover", Dict{String,Any}());
end

"""
    listtools(client::MyMCPClientModel) -> Dict{String,Any}

Send a `tools/list` request: ask the server for the name, description, and input schema of each of its tools.
"""
function listtools(client::MyMCPClientModel)::Dict{String,Any}
    return send_request(client, "tools/list", Dict{String,Any}());
end

"""
    calltool(client::MyMCPClientModel, name::String, arguments::Dict{String,Any}) -> Dict{String,Any}

Send a `tools/call` request: ask the server to run the tool `name` with the `arguments`.
The arguments must match the input schema of the tool.
"""
function calltool(client::MyMCPClientModel, name::String, arguments::Dict{String,Any})::Dict{String,Any}

    # the parameters of a tools/call request: the name of the tool, and its arguments -
    params = Dict{String,Any}();
    params["name"] = name;
    params["arguments"] = arguments;
    return send_request(client, "tools/call", params);
end

"""
    close(client::MyMCPClientModel)

Close the connection: close the standard input of the server, and wait for the server to exit.
The server loop ends when its input reaches its end.
"""
function Base.close(client::MyMCPClientModel)
    close(client.process.in); # the server sees the end of its input, and its loop ends
    wait(client.process); # wait for the server to exit
    return nothing;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
