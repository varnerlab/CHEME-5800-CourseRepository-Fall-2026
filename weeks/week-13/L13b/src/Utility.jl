# =============================================================================
# CHEME 5800 | L13b supplied helpers
# =============================================================================
# Two helpers for the API key: one reads the configuration file that holds the
# key, and one hides the key when we print a URL. You do not need to edit this file.
# =============================================================================
module L13bUtility

import TOML # read a configuration file written in the TOML format

export read_configuration, hidekey

"""
    read_configuration(path::String) -> Dict{String,Any}

Read the configuration file of the lab, and check that it holds a FRED API key.

The file is written in the TOML format. Its `[connection]` section has two entries:
`apikey`, your FRED API key, and `baseurl`, the base URL of the FRED API.

### Arguments
- `path::String`: the path to the configuration file, e.g., `joinpath(CHEME5800_L13B_CONFIG, "Configuration.toml")`.

### Returns
- `Dict{String,Any}`: the `[connection]` section as a dictionary with the keys `"apikey"` and `"baseurl"`.

### Throws
- `ArgumentError`: when the file does not exist or cannot be read, when an entry is not there, or when the key is not
  32 characters long. The messages never show the contents of the file.

### Example
```julia
connection = read_configuration(joinpath(CHEME5800_L13B_CONFIG, "Configuration.toml"));
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
    hidekey(url::String, apikey::String) -> String

Return a copy of a URL that shows the text `<your key>` in place of the API key.
Use this copy to print or share a URL. Use the original URL to call FRED.

### Arguments
- `url::String`: the URL string that a `build(...)` method returned.
- `apikey::String`: your FRED API key.

### Returns
- `String`: the URL with the key replaced, e.g.,
  `"https://api.stlouisfed.org/fred/series?series_id=DHHNGSP&api_key=<your key>&file_type=json"`.
"""
function hidekey(url::String, apikey::String)::String

    # an empty key matches everywhere in a String, so we return the URL unchanged -
    if (isempty(apikey) == true)
        return url;
    end

    # replace each copy of the key with the text <your key> -
    hidden_url = replace(url, apikey => "<your key>");
    return hidden_url;
end

end # module L13bUtility
