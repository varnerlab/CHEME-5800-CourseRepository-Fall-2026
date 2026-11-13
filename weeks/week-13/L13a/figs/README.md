# L13a figures

The lecture has six figures. Each figure has its own folder with the TikZ source, the build
files, the light PDF for notes and slides, and the notebook SVG. All six use the palette,
Makefile, and theme script of the L12c figures.

## A client and a server

`Fig-Client-Server/` holds the first figure of the Web Services and APIs section. A desktop
computer is the client, a cloud is the Internet, and a tower computer is the server. Blue arrows
carry the request to the server, and dark arrows carry the response back.

## A request and its response

`Fig-HTTP-Messages/` holds the first figure of the HTTP Requests and Responses section. The left
panel is the request that asks the National Weather Service API for the data about Ithaca, NY:
the method and path, then three headers, and no body. The right panel is the response: the
status line, two headers, and a shortened JSON body. Blue marks the method `GET`, the status
code `200`, and the arrow from the request to the response.

## The pieces of a URL

`Fig-URL-Anatomy/` holds the figure in The Request. It shows the URL of the hourly forecast for
Ithaca, NY with a brace over each piece: the scheme, the host, the path, and the query string.
Each brace has the name of the piece in blue and its meaning in gray.

## JSON text is a tree of data

`Fig-JSON-Tree/` holds the figure in the JSON section. The left panel is part of the body of the
National Weather Service response. The right side draws the same data as a tree. Boxes with a
blue outline are the objects and the array, the other boxes are strings and numbers, and each
line carries the key of the value that it leads to.

## The request-response cycle

`Fig-REST-Cycle/` holds the figure in the lecture's RESTful Web Services section. Three boxes
show the client, the REST API, and the backend services. Blue arrows carry the HTTPS request
(method, URL, headers, body) and the query to the backend. Dark arrows carry the raw data and
the HTTPS response (status code, headers, body). The numbers 1 to 4 match the four steps of the
cycle in the lecture. It replaces the client, REST API, and server screenshot used with the
Fall 2025 lecture material.

## The CRUD operations

`Fig-CRUD-Methods/` holds the figure in HTTP Methods and CRUD. A client sends four requests to a
lab's web service for its experiment records. Each lane shows the operation, the request, and
what happens to the records: `POST` creates a new record, `GET` returns record `42` unchanged,
`PUT` or `PATCH` updates record `42`, and `DELETE` removes it.

## Files and build

Each folder has the same files, named after the folder:

| File | Role |
|---|---|
| `<name>.tex` | Standalone TikZ source (XeLaTeX) |
| `Makefile` | Builds the PDF, then the themed SVG |
| `theme_svg.py` | Adds the dark screen palette to the SVG |
| `<name>.pdf` | Light figure for notes and slides |
| `<name>.svg` | Notebook figure |

From a figure folder, run `make` to rebuild both outputs and `make clean` to remove the LaTeX
temporaries. The build needs XeLaTeX, `pdf2svg`, and Python 3 (standard library only). An
unmapped color stops the build, so a palette change in the source must be added to the script's
mapping.
