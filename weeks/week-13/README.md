# Week 13 — REST clients and MCP servers

Week 13 connects two ways of exposing computational capabilities. Students first
call documented REST services from Julia, then wrap the same services in Julia
MCP servers that a language model application can call.

## Session sequence

| Session | Topic | Language | Notebook |
|---|---|---|---|
| L13a | RESTful web services, HTTP requests and responses, and the CRUD methods | Julia | [Lecture](L13a/CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb) and [example](L13a/CHEME-5800-L13a-Example-RESTful-NWS-Fall-2026.ipynb) |
| L13b | A software development kit for three endpoints of the FRED API | Julia | [Lab](L13b/CHEME-5800-L13b-Lab-RESTful-FRED-Fall-2026.ipynb) |
| L13c | The Model Context Protocol: hosts, clients, servers, tool calls, and trust boundaries | Julia | [Lecture](L13c/CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb) and [example](L13c/CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb) |
| L13d | An MCP server for the FRED API | Julia | [Lab](L13d/CHEME-5800-L13d-Lab-MCP-FRED-Fall-2026.ipynb) |

## Data and execution contracts

- The L13a example calls the live National Weather Service API with `HTTP.jl`. Its code is in `L13a/src`, and the validation suite tests it against committed fixtures without the network.
- The L13b lab calls the live FRED API. Each student needs their own free FRED API key, stored in `L13b/conf/Configuration.toml`, which git does not track. The validation suite tests the lab code against committed fixtures and a server on the local machine, without a key or the outside network.
- The L13c lecture links the JSON messages in `L13c/messages`, one file per message, recorded from the weather server on November 12, 2026. The call and Paris responses came from live National Weather Service calls. The validation suite checks that the discover, list, and unknown-tool responses still match what the server returns.
- The L13c example starts a local MCP server, `L13c/server.jl`, that calls the live National Weather Service API. The example ships with outputs. The validation suite tests the server against a server on the local machine that stands in for the weather service.
- The L13d lab starts a local MCP server, `L13d/server.jl`, that calls the live FRED API with the student's key. The key is in `L13d/conf/Configuration.toml`, which git does not track, and students can copy the file from L13b. The key stays in the server process and never appears in an MCP message. The validation suite tests the server against committed fixtures and a server on the local machine, without a key or the outside network.
- Both servers implement MCP protocol version `2026-07-28` over standard input and output, in plain Julia with `HTTP.jl` and `JSON.jl`, with no MCP SDK. The protocol version is stateless: there is no `initialize` handshake, and each request carries its version in `_meta`. The servers answer `server/discover`, `tools/list`, and `tools/call`, and only read public data.
- The notebooks act as the host. No model account or paid service is required. Connecting Claude Code to a server is optional, and the notebooks give the `claude mcp add` command.

The L13a lecture and example are ported from the Fall 2025 CHEME 5800 networking lecture and
National Weather Service example, and from the CHEME 142 web services module. The L13a code follows
the layout of the week 7 BiGG download code. The L13a lecture has a slide deck in its `slides` folder.

The L13b lab is new for Fall 2026. Its code follows the layout of the L13a example, and its configuration file follows the Fall 2024 Polygon example. Students complete the `build` method of the FRED observations endpoint in `L13b/src/Factory.jl` and its handler in `L13b/src/Handler.jl`. The reference solutions are `Factory-solution.jl` and `Handler-solution.jl` in the same folder.

The L13c lecture, the L13c example, and the L13d lab were rebuilt for Fall 2026 from the Julia MCP server of the CHEME 142 module, and updated to protocol version `2026-07-28`. The L13c weather server wraps the L13a SDK, and the L13d FRED server wraps the completed L13b SDK. Students complete the input schema and the handler of the `get_series_observations` tool in `L13d/src/Tools.jl`. The reference solution is `Tools-solution.jl` in the same folder.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-13/runtests.jl
```

Recheck the protocol version against the MCP specification and the current
Claude Code release shortly before the L13c release.
