# L13c lecture slides

[PDF deck](CHEME-5800-L13c-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L13c-Slides-Fall-2026.tex)

The 22-slide deck follows [The Model Context Protocol lecture](../CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb) in its order. It introduces language models and tools, explains the integration count, and defines hosts, clients, servers, and transports. It then follows JSON-RPC messages through server discovery, tool listing, and a tool call.

The deck covers protocol errors and tool execution errors, and the server loop. It closes with the NWS example, the FRED lab, and three key takeaways aligned with the three opening learning objectives.

**Review status:** Created November 15, 2026. All 23 rendered slides were checked against the L13a visual reference. The final build has no overfull or underfull boxes. Not yet reviewed by the instructor. On November 18, 2026, slides 18–19 were rewritten to show the lecture's restyled server-loop pseudocode instead of two tables, and the wording of the other slides was synced to the plain-English pass on the lecture and example. The same day, slides 8–10 and 16–17 were reordered to follow the restructured MCP Messages section. Slide text is shortened where a slide would overflow; the meaning matches the notebooks. Later that day, the two Trust and Security slides were removed with the lecture section, the third objective and takeaway became the server loop, and a Lab slide for L13d was added.

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
| 5 | The Model Context Protocol: connection code without a standard versus implementations with MCP, protocol history, and specification version |
| 6 | Hosts, Clients, and Servers: the architecture figure and three role definitions |
| 7 | Transports: standard input, standard output, standard error, one line of JSON per message, and Streamable HTTP |
| 8 | MCP Messages: the sequence figure of one tool call, with its four phases (discover and list, choose a tool, run the tool, write the answer) |
| 9 | The Message Format: JSON-RPC requests, responses, and notifications, and the comparison with REST |
| 10 | Stateless protocol version `2026-07-28`: the protocol version, client, and client features that each request carries |
| 11 | Discover a Server: supported versions, capabilities, instructions, and reuse of the response |
| 12–13 | List the Tools: the two weather tools, their descriptions, JSON Schema, required arguments, and the range of `hours` |
| 14–15 | Call a Tool: the Ithaca forecast request, response identifier, text content, structured content, and `isError` set to `false` |
| 16 | Two Kinds of Errors: unknown `get_snowfall` tool versus a forecast failure for Paris, France |
| 17 | The six JSON-RPC error codes used by our servers, including the rejection of an older `initialize` request |
| 18–19 | The Server Loop: the lecture's pseudocode, with Initialize and the Read and Check steps on slide 18, and the Route and Write steps and Output on slide 19 |
| 20 | Companion example: start and discover the server, list the tools, call them, cause a protocol error and a tool execution error, and close the connection |
| 21 | Lab: the L13d MCP server for the FRED API, the observations tool that students complete, and the natural gas question |
| 22 | Summary: introductory sentence, exactly three key takeaways, and the closing connection to our computational code |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Hyperlinks point to the lecture, example, lab, saved messages, and server code on the repository's main branch. The protocol-version link points to the official MCP specification, and the JSON-RPC 2.0 link points to the JSON-RPC specification.

The JSON excerpts come from the lecture's [saved messages](../messages/). Selected fields and omitted request metadata are labeled on their slides. The input-schema excerpt omits descriptions and coordinate bounds while retaining the argument types, required fields, and limits on `hours`.

The forecast is the saved November 12, 2026 response, identified as such on the slide. It is not a current forecast. The unknown-tool response is shown in full; the Paris response shows selected fields that distinguish a tool execution error from a protocol error.

Validation checked that all seven displayed JSON blocks parse and match the corresponding source fields. It also checked PDF page count, hyperlink destinations, annotation bounds, and exact copies of the style, seal, and figure assets. No notebook, server, message, or original figure was edited while creating the deck.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L13c-Lecture-ModelContextProtocol-Fall-2026.ipynb | `b50eb2902a0c4d5aa127cca683571b24d190347c616700d0e7806e3ee29119dd` |
| CHEME-5800-L13c-Example-MCP-NWS-Fall-2026.ipynb | `8d9bdb35c67f8c4773c2474944c46d999cb06a98d09cb4eb86ab4e09a71affdb` |
