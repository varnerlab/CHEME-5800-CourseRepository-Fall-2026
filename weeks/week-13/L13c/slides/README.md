# L13c lecture slides

[PDF deck](CHEME-5800-L13c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L13c-Slides-Fall-2026.tex)

The 24-slide deck follows [The Model Context Protocol lecture](../CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb) in its order. It introduces language models and tools, explains the integration count, and defines hosts, clients, servers, and transports. It shows what runs on the user's computer and what runs on remote servers, the permissions of a stdio server, and prompt injection. It then follows JSON-RPC messages through server discovery, tool listing, and a tool call.

The deck covers protocol errors and tool execution errors, and the server loop. It closes with the NWS example, the FRED lab, and three key takeaways aligned with the three opening learning objectives.

**Review status:** Created November 15, 2026. All 23 rendered slides were checked against the L13a visual reference. The final build has no overfull or underfull boxes. Not yet reviewed by the instructor. On November 18, 2026, slides 18–19 were rewritten to show the lecture's restyled server-loop pseudocode instead of two tables, and the wording of the other slides was synced to the plain-English pass on the lecture and example. The same day, slides 8–10 and 16–17 were reordered to follow the restructured MCP Messages section. Slide text is shortened where a slide would overflow; the meaning matches the notebooks. Later that day, the two Trust and Security slides were removed with the lecture section, the third objective and takeaway became the server loop, and a Lab slide for L13d was added.

The three style files and Cornell seal assets are copied unchanged from L13a. The deck keeps its 16:9 format, typography, palette, title page, and footer. Text, JSON excerpts, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX, `latexmk`, and the standard LaTeX packages used by the L13a deck, plus `fancyvrb` for JSON excerpts. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L13c/` directory.

`make figures` copies the lecture's four light TikZ PDFs into `assets/` unchanged. Their editable sources remain in the [connection-code figure folder](../figs/Fig-MCP-Connections/), the [architecture figure folder](../figs/Fig-MCP-Architecture/), the [what-runs-where figure folder](../figs/Fig-MCP-RunsWhere/), and the [tool-call figure folder](../figs/Fig-MCP-ToolCall/).

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4 | Language Models and Tools: the LLM, tools, and the steps of a tool call |
| 5 | The Model Context Protocol: the MCP definition, and the connection-code figure (3 × 4 = 12 pieces of connection code without a standard versus 3 + 4 = 7 pieces of MCP code) |
| 6 | Hosts, Clients, and Servers: the architecture figure and three role definitions |
| 7 | Transports: standard input, standard output, standard error, one line of JSON per message, and Streamable HTTP |
| 8 | What Runs Where: the user's computer runs the host and our MCP servers over stdio; the LLM, the NWS API, and the FRED API run on remote servers reached over HTTPS |
| 9 | Permissions and Prompt Injection: by default, a stdio server runs with the same permissions as the host, and user approval of each tool call can stop an injected instruction from running a tool |
| 10 | MCP Messages: the sequence figure of one tool call, with its four phases (discover and list, choose a tool, run the tool, write the answer) |
| 11 | The Message Format: JSON-RPC requests, responses, and notifications, and the comparison with REST |
| 12 | Stateless protocol version `2026-07-28`: the protocol version, client, and client features that each request carries; hosts of the older version `2025-06-18`, such as the Codex command-line tool, and their `initialize` request |
| 13 | Discover a Server: supported versions, capabilities, instructions, and reuse of the response |
| 14–15 | List the Tools: the two weather tools, their descriptions, JSON Schema, required arguments, and the range of `hours` |
| 16–17 | Call a Tool: the Ithaca forecast request, response identifier, text content, structured content, and `isError` set to `false` |
| 18 | Two Kinds of Errors: unknown `get_snowfall` tool versus a forecast failure for Paris, France |
| 19 | The six JSON-RPC error codes used by our servers, including a request that names a protocol version other than `2026-07-28` |
| 20–21 | The Server Loop: the lecture's pseudocode, with Initialize and the Read and Check steps on slide 20, and the Route and Write steps and Output on slide 21 |
| 22 | Companion example: start and discover the server, list the tools, call them, cause a protocol error and a tool execution error, and close the connection |
| 23 | Lab: the L13d MCP server for the FRED API, with one tool for each of the 36 endpoints of the FredAPI package, the code tour, and the experiments with Claude Code or the Codex command-line tool |
| 24 | Summary: introductory sentence, exactly three key takeaways, and the closing connection to our computational code |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Hyperlinks point to the lecture, example, lab, saved messages, and server code on the repository's main branch. The protocol-version link points to the official MCP specification, and the JSON-RPC 2.0 link points to the JSON-RPC specification.

The JSON excerpts come from the lecture's [saved messages](../messages/). Selected fields and omitted request metadata are labeled on their slides. The input-schema excerpt omits descriptions and coordinate bounds while retaining the argument types, required fields, and limits on `hours`.

The forecast is the saved November 12, 2026 response, identified as such on the slide. It is not a current forecast. The unknown-tool response is shown in full; the Paris response shows selected fields that distinguish a tool execution error from a protocol error.

Validation checked that all seven displayed JSON blocks parse and match the corresponding source fields. It also checked PDF page count, hyperlink destinations, annotation bounds, and exact copies of the style, seal, and figure assets. No notebook, server, message, or original figure was edited while creating the deck.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb | `17f66f1d80e621a20fd4c1f50babbedf6345d9bf119fc24f5fc03755d583cc48` |
| CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb | `002d522c662c9f81c3b58a8b6620a5a64cc4a74c94284e1e4470b63778b416f2` |
