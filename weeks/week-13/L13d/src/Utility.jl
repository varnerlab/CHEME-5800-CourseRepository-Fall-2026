# =============================================================================
# CHEME 5800 | L13d supplied helper: read the configuration file
# =============================================================================
# The server reads your FRED API key from conf/Configuration.toml when it starts.
# The key stays in the server: it is never part of an MCP message. You do not
# need to edit this file.
# =============================================================================

# --- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    read_configuration(path::String) -> Dict{String,Any}

Read the configuration file of the lab, and check that it holds a FRED API key.

The file is written in the TOML format. Its `[connection]` section has two entries:
`apikey`, your FRED API key, and `baseurl`, the base URL of the FRED API.

### Arguments
- `path::String`: the path to the configuration file, e.g., `joinpath(CHEME5800_L13D_CONFIG, "Configuration.toml")`.

### Returns
- `Dict{String,Any}`: the `[connection]` section as a dictionary with the keys `"apikey"` and `"baseurl"`.

### Throws
- `ArgumentError`: when the file does not exist or cannot be read, when an entry is not there, or when the key is not
  32 characters long. The messages never show the contents of the file.

### Example
```julia
connection = read_configuration(joinpath(CHEME5800_L13D_CONFIG, "Configuration.toml"));
baseurl = connection["baseurl"];
apikey = connection["apikey"];
```
"""
function read_configuration(path::String)::Dict{String,Any}

    # check: does the file exist?
    if (isfile(path) == false)
        throw(ArgumentError("We cannot find the configuration file. Copy conf/Configuration-template.toml " *
            "to conf/Configuration.toml, and paste your FRED API key into the new file."));
    end

    # read the file: each [section] of a TOML file becomes a dictionary. The error of the TOML
    # reader shows the line that it could not read, which may hold the key, so we throw our own error -
    configuration = nothing;
    try
        configuration = TOML.parsefile(path);
    catch
        throw(ArgumentError("We cannot read the configuration file. Check that the key is between the quotes " *
            "on the apikey line, and compare the file with conf/Configuration-template.toml."));
    end

    # check: does the file have a [connection] section with the two entries?
    if (haskey(configuration, "connection") == false)
        throw(ArgumentError("The configuration file has no [connection] section. Compare it with conf/Configuration-template.toml."));
    end
    connection = configuration["connection"];
    if (haskey(connection, "apikey") == false)
        throw(ArgumentError("The [connection] section has no apikey entry. Compare the file with conf/Configuration-template.toml."));
    end
    if (haskey(connection, "baseurl") == false)
        throw(ArgumentError("The [connection] section has no baseurl entry. Compare the file with conf/Configuration-template.toml."));
    end

    # check: a FRED API key has 32 characters. The message does not show the key -
    apikey = connection["apikey"];
    if (isa(apikey, String) == false)
        throw(ArgumentError("The apikey entry is not text. Paste your key between the quotes on the apikey line of conf/Configuration.toml."));
    end
    if (length(apikey) != 32)
        throw(ArgumentError("The apikey entry is not a FRED API key: a key has 32 characters, and this entry has $(length(apikey)). " *
            "Paste your key between the quotes on the apikey line of conf/Configuration.toml."));
    end

    # return the connection settings -
    return connection;
end
"""
    load_server_configuration(path::String) -> Dict{String,Any}

Read the configuration file of the server, and return the configuration that the tool handlers need.

When the file is missing or wrong, the server still starts: the configuration then holds the reason under the key
`setup_error`, and each FRED tool reports the reason as a tool execution error. The client can still discover the
server and list its tools.

### Arguments
- `path::String`: the path to the configuration file, i.e., `conf/Configuration.toml` in this folder.

### Returns
- `Dict{String,Any}`: the configuration, with the keys `baseurl` and `apikey`, or with the key `setup_error`.
"""
function load_server_configuration(path::String)::Dict{String,Any}

    # initialize -
    configuration = Dict{String,Any}();

    # read the file. The messages of read_configuration(...) never show the key -
    try
        connection = read_configuration(path);
        configuration["baseurl"] = connection["baseurl"];
        configuration["apikey"] = connection["apikey"];
    catch exception
        if (isa(exception, ArgumentError) == true)
            configuration["setup_error"] = exception.msg; # the message of read_configuration(...)
        else
            configuration["setup_error"] = "We cannot read the configuration file. Compare it with conf/Configuration-template.toml.";
        end
    end

    # return the configuration -
    return configuration;
end
# --- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #
