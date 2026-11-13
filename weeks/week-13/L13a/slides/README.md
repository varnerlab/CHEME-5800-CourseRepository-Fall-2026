# L13a lecture slides

[PDF deck](CHEME-5800-L13a-Slides-Fall-2026.pdf) · [Editable LaTeX source](CHEME-5800-L13a-Slides-Fall-2026.tex)

The 19-slide deck follows the [RESTful Web Services and APIs lecture](../CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb) in its order. It opens with web services, the client and the server, and APIs, then shows a request to the National Weather Service API and its response, and covers the parts of an HTTP request, the pieces of a URL, the parts of an HTTP response with the status code classes, and JSON. It then defines REST and resources, shows the request-response cycle and its four steps, maps the CRUD operations onto the HTTP methods, and gives the three principles that explain why RESTful web services are popular. It closes with the example and the Summary. Its three learning objectives align with its three closing takeaways.

**Review status:** Written with the lecture on November 12, 2026, and synced the same day after one external review pass and after the lecture gained four figures. On November 13, 2026 the deck gained the client and server figure, and the web services slide was split in two to make room for it. The build has no overfull or underfull boxes. Not yet reviewed by the instructor.

The style files and Cornell seal are copied unchanged from L12c (identical to L12a, L10c, L10a, L9c, and L9a, which match the approved L6a deck). The deck keeps their 16:9 format, typography, palette, title page, and footer. Text and tables are editable in the LaTeX source.

## Build

From this directory:

```sh
make
```

Requirements: XeLaTeX and `latexmk`. The style uses Helvetica Neue when available and includes font fallbacks. The PDF is written here; intermediate files go to the repository's ignored `build/slides/L13a/` directory.

`make figures` copies the six lecture figures into `assets/`, which the deck includes. Each figure is the light TikZ PDF in its [figure folder](../figs/), copied unchanged.

`make clean` removes intermediate LaTeX files. `make distclean` also removes the generated deck PDF. Both preserve the source, figure, and seal assets.

## Lecture coverage

| Slides | Lecture material |
|---|---|
| 1–3 | Title, three learning objectives, and the lecture and example |
| 4 | Web services: the definitions of web service, client, and server, and the client and server figure |
| 5 | APIs and communication protocols: the API, the API specification, the communication protocol, and TCP and HTTPS |
| 6 | A request to the National Weather Service API and its response (figure) |
| 7–8 | The HTTP request: its four parts, and the four pieces of a URL (figure) |
| 9 | The HTTP response: its three parts and the status code classes |
| 10–11 | JSON: objects, arrays, values, parsing, and serialization, and JSON text as a tree of data (figure) |
| 12–13 | RESTful web services: REST, resources, the request-response figure, and the four steps of the cycle |
| 14–16 | HTTP methods and CRUD: the CRUD figure, the table of operations, safe and idempotent methods, and the `HTTP.jl` functions |
| 17 | Why RESTful web services are popular: statelessness, the uniform interface, and the layered system |
| 18 | Example: a software development kit for the National Weather Service API |
| 19 | Summary: three key takeaways |

## Sources and scope

Notebook-section mappings appear in Beamer source notes, omitted from the projected PDF. Notebook hyperlinks point to their repository locations on the main branch.

The deck uses the lecture's terms: web service, API, client, server, endpoint, method, URL, headers, body, status code, JSON object, array, and value, resource, CRUD, and safe and idempotent methods. The objectives and takeaways are shortened from the lecture's to fit the slide format; they make the same claims. The six figures are the lecture's figures.

Source notebook snapshots (SHA-256):

| Notebook | SHA-256 |
|---|---|
| CHEME-5800-L13a-Lecture-RESTJSONAndSchemas-Fall-2026.ipynb | `45cdaa74160817ce4d5a964c1d296a1c5c5fbd94d5386e316ab679477381d7eb` |
| CHEME-5800-L13a-Example-RESTful-NWS-Fall-2026.ipynb | `17d53fe2a34b1746e658cd77f87a543c580f39ee8ec31ae47fcd88b982e3cd30` |
