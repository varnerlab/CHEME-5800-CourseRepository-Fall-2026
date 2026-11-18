# Week 13 — REST clients and MCP servers

Week 13 connects two ways of exposing computational capabilities. Students first
call documented REST services from Julia, then wrap the same services in Julia
MCP servers that a language model application can call.

Release `week-13.0` includes all four sessions, both slide decks, and the lab reference solutions.

## Session sequence

| Session | Topic | Language | Notebook |
|---|---|---|---|
| L13a | RESTful web services, HTTP requests and responses, and the CRUD methods | Julia | [Lecture](L13a/CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb) and [example](L13a/CHEME-5800-L13a-Example-RESTful-NWS-Fall-2026.ipynb) |
| L13b | A software development kit for three endpoints of the FRED API | Julia | [Lab](L13b/CHEME-5800-L13b-Lab-RESTful-FRED-Fall-2026.ipynb) |
| L13c | The Model Context Protocol: hosts, clients, servers, tool calls, and the server loop | Julia | [Lecture](L13c/CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb) and [example](L13c/CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb) |
| L13d | An MCP server for the FRED API, with one tool for each endpoint, and a host: Claude Code or the Codex command-line tool | Julia | [Lab README](L13d/README.md) |

## Data and execution contracts

- The L13a example calls the live National Weather Service API with `HTTP.jl`. Its code is in `L13a/src`, and the validation suite tests it against committed fixtures without the network.
- The L13b lab calls the live FRED API. Each student needs their own free FRED API key, stored in `L13b/conf/Configuration.toml`, which git does not track. The validation suite tests the lab code against committed fixtures and a server on the local machine, without a key or the outside network.
- The L13c lecture links the JSON messages in `L13c/messages`, one file per message, recorded from the weather server on November 12, 2026. The call and Paris responses came from live National Weather Service calls. The validation suite checks that the discover, list, and unknown-tool responses still match what the server returns.
- The L13c example starts a local MCP server, `L13c/server.jl`, that calls the live National Weather Service API. The example ships with outputs. The validation suite tests the server against a server on the local machine that stands in for the weather service.
- The L13d lab has no notebook. Its [README](L13d/README.md) holds a code tour and six experiments with a host. A host, Claude Code or the Codex command-line tool, starts a local MCP server, `L13d/server.jl`, from `L13d/.mcp.json` or `L13d/.codex/config.toml`. The server calls the live FRED API with the student's key through the [FredAPI package](https://github.com/varnerlab/fred-sdk), which the course environment installs from GitHub. The key is in `L13d/conf/Configuration.toml`, which git does not track, and students can copy the file from L13b. The server sends the key only to FRED, and the key never appears in an MCP message. The validation suite tests all 36 tools against the test fixtures of the FredAPI package and a server on the local machine, without a key or the outside network.
- Both servers implement MCP protocol version `2026-07-28` over standard input and output, in plain Julia with `HTTP.jl` and `JSON.jl`, with no MCP SDK. The protocol version is stateless: each request carries its version in `_meta`. The servers answer `server/discover`, `tools/list`, and `tools/call`, and only read public data. They also answer the `initialize` request of the older version `2025-06-18`, which the Codex command-line tool sends.
- The L13c example acts as the host, and needs no model account. The L13d experiments need a host with a model account: a Claude plan or Claude Console account for Claude Code, or a ChatGPT plan or OpenAI API key for Codex. Students without one work with a classmate, or call the tools from Julia as the L13d README shows.

The L13a lecture and example are ported from the Fall 2025 CHEME 5800 networking lecture and
National Weather Service example, and from the CHEME 142 web services module. The L13a code follows
the layout of the week 7 BiGG download code. The L13a lecture has a slide deck in its `slides` folder.

The L13b lab is new for Fall 2026. Its code follows the layout of the L13a example, and its configuration file follows the Fall 2024 Polygon example. Students complete the `url(...)` method of the FRED observations endpoint in `L13b/src/Factory.jl` and its handler in `L13b/src/Handler.jl`. The reference solutions are [Factory-solution.jl](L13b/src/solution/Factory-solution.jl) and [Handler-solution.jl](L13b/src/solution/Handler-solution.jl) in `L13b/src/solution`.

The L13c lecture, the L13c example, and the L13d lab were rebuilt for Fall 2026 from the Julia MCP server of the CHEME 142 module, and updated to protocol version `2026-07-28`. The L13c weather server wraps the L13a SDK. On November 18, 2026, the L13d lab was rebuilt as a code tour and a README of experiments: its FRED server wraps the FredAPI package, with one tool for each of the 36 endpoints, and has no student TODOs.

The L13c lecture has a [slide deck](L13c/slides/CHEME-5800-L13c-Slides-Fall-2026.pdf) in its [slides folder](L13c/slides/README.md), with editable LaTeX source and build instructions.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-13/runtests.jl
```

Recheck the protocol version against the MCP specification and the current
Claude Code release shortly before the L13c release.
