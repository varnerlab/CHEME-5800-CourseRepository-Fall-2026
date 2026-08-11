# Week 13 — REST clients and MCP servers

Week 13 connects two ways of exposing computational capabilities. Students first
consume a documented REST service from Julia, then expose a previously validated
course computation through a local Python MCP server.

## Session sequence

| Session | Topic | Language | Notebook |
|---|---|---|---|
| L13a | HTTP, JSON, REST, linked requests, and schemas | Julia | [Lecture](L13a/CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb) |
| L13b | Defensive National Weather Service client | Julia | [Lab](L13b/CHEME-5800-L13b-Lab-NWSClient-Fall-2026.ipynb) |
| L13c | MCP tools, resources, discovery, and trust boundaries | Python | [Lecture](L13c/CHEME-5800-L13c-Lecture-MCPToolsResourcesAndTrust-Fall-2026.ipynb) |
| L13d | Inspect the local urea-cycle MCP server | Python | [Lab](L13d/CHEME-5800-L13d-Lab-UreaCycleMCP-Fall-2026.ipynb) |

## Data and execution contracts

- The NWS client is tested against committed fixtures; the live service is optional.
- The Python server is local, read-only, and uses standard input/output.
- The MCP lab requires no model account, API key, remote deployment, or paid service.
- Numerical tests are separate from protocol tests.
- The server uses the official Python MCP SDK 2.x and the `2026-07-28` protocol.

Set up the Python environment once from the repository root:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r weeks/week-13/python/requirements.txt
```

The requirements include `ipykernel`, so VS Code/Jupyter can select the
repository-local `.venv` interpreter for L13c and L13d.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-13/runtests.jl
PYTHONPATH=weeks/week-13/python/src \
  .venv/bin/python -m unittest discover -s weeks/week-13/python/test -v
```

The MCP SDK and Inspector workflow are temporally sensitive and must be rechecked
shortly before the November release. The durable learning targets are schemas,
capability discovery, computation/protocol separation, and trust boundaries.
