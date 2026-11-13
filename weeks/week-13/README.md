# Week 13 — REST clients and MCP servers

Week 13 connects two ways of exposing computational capabilities. Students first
consume a documented REST service from Julia, then expose a previously validated
course computation through a local Python MCP server.

## Session sequence

| Session | Topic | Language | Notebook |
|---|---|---|---|
| L13a | RESTful web services, HTTP requests and responses, and the CRUD methods | Julia | [Lecture](L13a/CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb) and [example](L13a/CHEME-5800-L13a-Example-RESTful-NWS-Fall-2026.ipynb) |
| L13b | A software development kit for three endpoints of the FRED API | Julia | [Lab](L13b/CHEME-5800-L13b-Lab-RESTful-FRED-Fall-2026.ipynb) |
| L13c | MCP tools, resources, discovery, and trust boundaries | Python | [Lecture](L13c/CHEME-5800-L13c-Lecture-MCPToolsResourcesAndTrust-Fall-2026.ipynb) |
| L13d | Inspect the local urea-cycle MCP server | Python | [Lab](L13d/CHEME-5800-L13d-Lab-UreaCycleMCP-Fall-2026.ipynb) |

## Data and execution contracts

- The L13a example calls the live National Weather Service API with `HTTP.jl`. Its code is in `L13a/src`, and the validation suite tests it against committed fixtures without the network.
- The L13b lab calls the live FRED API. Each student needs their own free FRED API key, stored in `L13b/conf/Configuration.toml`, which git does not track. The validation suite tests the lab code against committed fixtures and a server on the local machine, without a key or the outside network.
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

The L13a lecture and example are ported from the Fall 2025 CHEME 5800 networking lecture and
National Weather Service example, and from the CHEME 142 web services module. The L13a code follows
the layout of the week 7 BiGG download code. The L13a lecture has a slide deck in its `slides` folder.

The L13b lab is new for Fall 2026. Its code follows the layout of the L13a example, and its configuration file follows the Fall 2024 Polygon example. Students complete the `build` method and the handler of the FRED observations endpoint in `L13b/src/Compute.jl`.

## Instructor validation

```bash
julia --startup-file=no --project=. instructor/validation/week-13/runtests.jl
PYTHONPATH=weeks/week-13/python/src \
  .venv/bin/python -m unittest discover -s weeks/week-13/python/test -v
```

The MCP SDK and Inspector workflow are temporally sensitive and must be rechecked
shortly before the November release. The durable learning targets are schemas,
capability discovery, computation/protocol separation, and trust boundaries.
