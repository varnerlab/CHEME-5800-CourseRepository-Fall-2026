# L13c lecture slides

[PDF deck](CHEME-5800-L13c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L13c-Slides-Fall-2026.tex)

The 23-slide deck follows [The Model Context Protocol lecture](../CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb) in its order. It introduces language models and tools, explains the integration count, and defines hosts, clients, servers, and transports. It then follows JSON-RPC messages through server discovery, tool listing, and a tool call.

The deck covers both kinds of errors, the server loop, and the three trust boundaries. It closes with the NWS example and three key takeaways aligned with the three opening learning objectives.

**Review status:** Created November 15, 2026. All 23 rendered slides were checked against the L13a visual reference. The final build has no overfull or underfull boxes. Not yet reviewed by the instructor.

The three style files and Cornell seal assets are copied unchanged from L13a. The deck keeps its 16:9 format, typography, palette, title page, and footer. Text, JSON excerpts, equations, and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX, `latexmk`, and the standard LaTeX packages used by the L13a deck, plus `fancyvrb` for JSON excerpts. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L13c/` directory.

`make figures` copies the lecture's two light TikZ PDFs into `assets/` unchanged. Their editable sources remain in the [architecture figure folder](../figs/Fig-MCP-Architecture/) and the [tool-call figure folder](../figs/Fig-MCP-ToolCall/).

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4 | Language Models and Tools: the LLM, tools, and the steps of a tool call |
| 5 | The Model Context Protocol: custom integrations versus a common protocol, protocol history, and specification version |
| 6 | Hosts, Clients, and Servers: the architecture figure and three role definitions |
| 7 | Transports: standard input, standard output, standard error, one line of JSON per message, and Streamable HTTP |
| 8 | MCP Messages: JSON-RPC requests, responses, notifications, and request identifiers |
| 9 | Stateless protocol version `2026-07-28`: per-request metadata and our servers' rejection of the older `initialize` handshake |
| 10 | The six JSON-RPC error codes used by our servers |
| 11 | Discover a Server: supported versions, capabilities, instructions, identity, and reuse of the response |
| 12–13 | List the Tools: the two weather tools, their descriptions, JSON Schema, required arguments, and the range of `hours` |
| 14–15 | Call a Tool: the Ithaca forecast request, response identifier, text content, structured content, and success flag |
| 16 | One tool call: the sequence figure connecting the model, host, server, and web API |
| 17 | Two Kinds of Errors: unknown `get_snowfall` tool versus a forecast failure for Paris, France |
| 18–19 | The Server Loop: initialization, parsing, message checks, notifications, version checks, method routing, handler failures, output, and termination |
| 20–21 | Trust and Security: the three trust boundaries, prompt injection, and user approval for tools that change data |
| 22 | Companion example: start and discover the server, list the tools, call them, trigger both kinds of errors, and close the connection |
| 23 | Summary: introductory sentence, exactly three key takeaways, and the closing connection to our computational code |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Hyperlinks point to the lecture, example, saved messages, and server code on the repository's main branch. The protocol-version link points to the official MCP specification.

The JSON excerpts come from the lecture's [saved messages](../messages/). Selected fields and omitted request metadata are labeled on their slides. The input-schema excerpt omits descriptions and coordinate bounds while retaining the argument types, required fields, and limits on `hours`.

The forecast is the saved November 12, 2026 response, identified as such on the slide. It is not a current forecast. The unknown-tool response is shown in full; the Paris response shows selected fields that distinguish a tool execution error from a protocol error.

Validation checked that all seven displayed JSON blocks parse and match the corresponding source fields. It also checked PDF page count, hyperlink destinations, annotation bounds, and exact copies of the style, seal, and figure assets. No notebook, server, message, or original figure was edited while creating the deck.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb | `11ab3c57456cb7d0076210c238ac2deba6584a136e79c5957178d23a576c7579` |
| CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb | `2059c0e4d513dfeff4517ec43fbcd165c92c673064e801ed9cdb203c00fd4cb3` |
