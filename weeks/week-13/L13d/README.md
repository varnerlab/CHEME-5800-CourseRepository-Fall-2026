# L13d Lab: An MCP Server for the FRED API

In L13b, we built a software development kit (SDK) for three endpoints of the FRED (Federal Reserve Economic Data) API. The [FredAPI package](https://github.com/varnerlab/fred-sdk) covers all 36 endpoints. In this lab, we use a Model Context Protocol (MCP) server that calls FredAPI and offers one tool for each endpoint.

We'll spend the first 25 to 30 minutes touring the server code. In the last 20 minutes, you will connect the server to a host, either [Claude Code](https://code.claude.com/docs/en/overview) or the [Codex command-line tool](https://developers.openai.com/codex/cli), and ask questions about FRED data.

## Before class

Do these three steps before class.

1. __Add your FRED API key.__ Copy `conf/Configuration-template.toml` to `conf/Configuration.toml`, and paste your key between the quotes on the `apikey` line. You can also copy `conf/Configuration.toml` from L13b. Git does not track this file. The server sends your key only to FRED, and the language model never sees it.
2. __Install a host.__ Install [Claude Code](https://code.claude.com/docs/en/overview) or [Codex](https://developers.openai.com/codex/cli). Claude Code needs a Claude plan or a Claude Console account. Codex needs a ChatGPT plan or an OpenAI API key. If you have neither, work with a classmate who has one.
3. __Install FredAPI.__ Open a terminal in this folder, and run these two commands. The first command installs the FredAPI package. The second command loads the server code once, so that the server starts quickly in class:

    ```sh
    julia --startup-file=no --project=../../.. -e "import Pkg; Pkg.instantiate()"
    julia --startup-file=no Include.jl
    ```

    Neither command should print an error. Status lines such as `Activating project` are normal.

## Part 1: A tour of the code

Claude Code and Codex start the server with the same command, `julia --startup-file=no server.jl`. Claude Code reads this command from [.mcp.json](.mcp.json), and Codex reads it from [.codex/config.toml](.codex/config.toml). We'll follow the command through the code:

1. The [server.jl](server.jl) file loads the code, reads your API key, builds the server, and runs the server loop.
2. [The `build_fred_server(...)` function](src/Catalog.jl) at the bottom of `src/Catalog.jl` lists the 36 tools. Each entry gives a tool's name, description, endpoint model, required arguments, and handler. We'll look at the `get_series_observations` entry.
3. The handlers are at the top of `src/Catalog.jl`. Most handlers are one line that passes an endpoint model to [the `_call_fred(...)` function](src/Tools.jl).
4. [The `_fetch(...)` function](src/Tools.jl) calls FRED in the same three steps as L13b. It builds an endpoint model, builds the URL with `FredAPI.url(...)`, and makes the call with `FredAPI.api(...)`.
5. [The `_copy_arguments!(...)` function](src/Tools.jl) copies the arguments from the language model into the endpoint model. It checks the name and type of each argument.
6. [The `_input_schema(...)` function](src/Tools.jl) builds a tool's input schema from the fields of its endpoint model. The language model reads the schema to write the arguments of a call.
7. [The `_check_length(...)` function](src/Tools.jl) and [the `get_maps_shapes(...)` handler](src/Catalog.jl) keep results short, because the language model reads the whole result.
8. The server loop in [src/Server.jl](src/Server.jl) is the same as in the L13c weather server. It answers the `initialize` request from Codex and the `server/discover` request from Claude Code.

__Questions to discuss during the tour:__

* Where does the API key go in the request? Why can't a tool call set the `apikey` field?
* If FredAPI adds an endpoint, what do we add to the server to offer it as a tool?
* What does the host see when an argument is wrong? What does it see when FRED returns an error?

## Part 2: Experiments with a host

Open a terminal in this folder, and start your host:

* __Claude Code:__ Run `claude`. Claude Code finds the `fred` server in [.mcp.json](.mcp.json) and asks whether to use it. Approve it. Type `/mcp` to check that the server is connected.
* __Codex:__ Run `codex`. If Codex asks whether to trust this folder, answer yes, so that Codex reads [.codex/config.toml](.codex/config.toml). Type `/mcp` to check that the server is connected.

Before each tool call, the host shows the tool and its arguments and asks for your approval. Approve one call at a time, so that you see the arguments of every call. If the server fails to start in Claude Code, quit and restart Claude Code with a longer startup timeout: `MCP_TIMEOUT=120000 claude` on macOS or Linux, or `$env:MCP_TIMEOUT=120000; claude` in Windows PowerShell.

Type each prompt into the host, then answer the question below it.

__Experiment 1: List the tools.__

> What tools does the fred server offer? Group them by what they return.

How does the host know the tools before it calls any of them?

__Experiment 2: The natural gas question.__ A process engineer wants to know whether furnace fuel got cheaper.

> Was natural gas cheaper in 2025 than in 2024? Use FRED.

Which tools did the language model call, and in what order? What `frequency` did it choose for `get_series_observations`?

__Experiment 3: A question that takes several tools.__

> Which release of economic data publishes the US unemployment rate, and when is the next release date?

How did the language model get from the unemployment rate to a release date? Which arguments of `get_release_dates` did it need?

__Experiment 4: A wrong series identifier.__

> Get the observations of the FRED series NOTASERIES.

Is the error a protocol error or a tool execution error? What did the language model do next?

__Experiment 5: A result that is too long.__

> Get every daily observation of the Henry Hub natural gas spot price, DHHNGSP.

What does the error message tell the language model? How did the model change its next call?

__Experiment 6: The same question without the server.__ Quit the host. Start it again from the `week-13` folder, where it cannot find the server, and ask the Experiment 2 question again.

How does this answer differ from the answer in Experiment 2? Where does it come from?

## Call the server from Julia

You can also call the tools from Julia, without a host, with the client from the L13c example. Start Julia in this folder, and run:

```julia
include("Include.jl");
client = connect(`julia --startup-file=no $(CHEME5800_L13D_SERVER)`);
response = calltool(client, "search_series", Dict{String,Any}("search_text" => "Henry Hub", "limit" => 3));
println(response["result"]["content"][1]["text"]);
close(client);
```

The FRED server and the FredAPI package use the FRED® API, but they are not endorsed or certified by the Federal Reserve Bank of St. Louis. By using them, you agree to the [FRED® API Terms of Use](https://fred.stlouisfed.org/docs/api/terms_of_use.html).
