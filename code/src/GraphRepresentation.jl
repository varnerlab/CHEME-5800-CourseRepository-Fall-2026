# ------------------------------------------------------------------------------------------------ #
# GraphRepresentation.jl
#
# Edge-list, adjacency-list and adjacency-matrix representations used by the week-04 L4a lecture.
#
# The L4a worked example reads the seven weighted edges in data/SimpleGraph.txt, builds an
# adjacency list and an adjacency matrix from them, and compares how much each one stores.
#
# - An edge list stores one record per edge: the source vertex, the target vertex, and the weight.
# - An adjacency list stores, for each vertex, the vertices that its outgoing edges point to.
# - An adjacency matrix A has one row and one column per vertex; entry A[i,j] holds the weight
#   of the edge from vertex i to vertex j, and 0.0 when there is no such edge.
#
# Public type alias and functions:
#
#   WeightedEdgeRecord             the type of one edge record: (source, target, weight)
#   read_weighted_edges(path)      reads a source,target,weight text file into edge records
#   vertex_ids(edges)              returns the sorted ids of every vertex that appears in an edge
#   adjacency_list(edges)          builds the outgoing-neighbor list of each vertex
#   adjacency_matrix(edges)        builds the weighted adjacency matrix and its vertex ordering
#   directed_density(n, m)         the fraction of the n(n-1) possible directed edges that are present
#   representation_report(edges)   counts the vertices, edges, density, and storage entries
#
# The functions after read_weighted_edges accept any collection of records that have the
# fields `source` and `target` (and `weight`, for adjacency_matrix), so they also work on the
# `WeightedEdge` objects of ShortestPathAlgorithms.jl.
# ------------------------------------------------------------------------------------------------ #

# WeightedEdgeRecord is a type alias: a short name for a longer type. The longer type is a
# NamedTuple, a tuple whose entries have names. A record of this type has three fields:
# `source::Int64` (the start vertex), `target::Int64` (the end vertex), and `weight::Float64`.
# For example, (source = 1, target = 2, weight = 10.0) is a WeightedEdgeRecord, and
# record.weight gives 10.0 -
const WeightedEdgeRecord = NamedTuple{(:source, :target, :weight), Tuple{Int64, Int64, Float64}}

"""
    read_weighted_edges(path::AbstractString; delimiter::Char = ',') -> Vector{WeightedEdgeRecord}

Read `source,target,weight` records while ignoring blank and comment lines.

Each data line of the file holds one directed edge: the source vertex id, the target vertex
id, and the edge weight, separated by `delimiter`. A line that is empty, or that starts with
`#` after leading spaces are removed, is skipped. The L4a lecture reads
`data/SimpleGraph.txt` with this function.

### Arguments
- `path::AbstractString`: the path to the edge-list text file.
- `delimiter::Char = ','`: the character that separates the three fields of a line (keyword
  argument).

### Returns
- `Vector{WeightedEdgeRecord}`: one record `(source = …, target = …, weight = …)` per data line,
  in file order. The ids are `Int64` and the weight is `Float64`.

### Throws
- `ArgumentError`: the file does not exist; a data line does not have exactly three fields;
  the source or target is not an integer; the weight is not a number; the weight is `Inf` or
  `NaN`; or the file has no data lines. The message names the line number where it applies.

### Example
```julia
records = read_weighted_edges(joinpath(CHEME5800_L4A_DATA, "SimpleGraph.txt"));
records[1]   # (source = 1, target = 2, weight = 10.0)
```
"""
function read_weighted_edges(path::AbstractString; delimiter::Char = ',')::Vector{WeightedEdgeRecord}

    # check that the file exists -
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)")) # if the file does not exist, stop with an error

    # initialize: an empty vector of edge records -
    edges = WeightedEdgeRecord[] # T[] makes an empty vector that holds items of type T

    # main loop: read the file one line at a time. eachline(path) gives the lines in order,
    # and enumerate(...) pairs each line with its number 1, 2, 3, ... -
    for (line_number, raw_line) in enumerate(eachline(path))

        # remove leading and trailing spaces, then skip blank and comment lines -
        line = strip(raw_line)
        (isempty(line) || startswith(line, '#')) && continue # if the line is empty or starts with #, skip to the next line

        # split the line at each delimiter, and remove the spaces around each piece. The dot in
        # strip.(...) applies strip to every piece; this is called broadcasting -
        fields = strip.(split(line, delimiter))
        length(fields) == 3 || throw(ArgumentError("line $(line_number) must contain three fields")) # if the line does not have three fields, stop with an error

        # convert the three text fields to numbers. tryparse returns `nothing`, instead of
        # throwing an error, when the text is not a valid number -
        source = tryparse(Int64, fields[1])
        target = tryparse(Int64, fields[2])
        weight = tryparse(Float64, fields[3])

        # check each converted field: isnothing(x) is true when x is `nothing`, i.e., the conversion failed -
        isnothing(source) && throw(ArgumentError("invalid source on line $(line_number)")) # if source is nothing, stop with an error
        isnothing(target) && throw(ArgumentError("invalid target on line $(line_number)")) # if target is nothing, stop with an error
        isnothing(weight) && throw(ArgumentError("invalid weight on line $(line_number)")) # if weight is nothing, stop with an error
        isfinite(weight) || throw(ArgumentError("weight on line $(line_number) must be finite")) # if the weight is Inf or NaN, stop with an error

        # store the record. (source = source, ...) builds a NamedTuple with the three fields -
        push!(edges, (source = source, target = target, weight = weight))
    end

    # an edge list with no edges is an error -
    isempty(edges) && throw(ArgumentError("edge list may not be empty")) # if we found no data lines, stop with an error

    # return the records in file order -
    return edges
end

"""
    vertex_ids(edges) -> Vector{Int64}

Return sorted vertex identifiers appearing in an edge collection.

We collect the source and the target of every edge into a set, which keeps one copy of each
id, then sort the ids in increasing order. A vertex that is not an endpoint of any edge does
not appear, because an edge list does not record it.

### Arguments
- `edges`: a collection of edge records. Each record must have the fields `source` and
  `target`, holding integer vertex ids; for example, the output of `read_weighted_edges`.

### Returns
- `Vector{Int64}`: each vertex id once, in increasing order.

### Example
```julia
edges = [(source = 1, target = 2, weight = 10.0), (source = 2, target = 3, weight = 2.0)];
vertex_ids(edges)   # [1, 2, 3]
```
"""
function vertex_ids(edges)::Vector{Int64}

    # initialize: a set keeps one copy of each id, however many edges touch it -
    ids = Set{Int64}()

    # add both endpoints of every edge. push!(set, a, b) adds a and then b -
    for edge in edges
        push!(ids, Int64(edge.source), Int64(edge.target))
    end

    # convert the set to a vector with collect, and sort it in place with sort! -
    return sort!(collect(ids))
end

"""
    adjacency_list(edges) -> Dict{Int64, Vector{Int64}}

Build a deterministic outgoing-neighbor adjacency list.

For each vertex `u`, the list stores the targets of the edges that leave `u`, i.e., every `v`
with an edge `u → v`. Every vertex that appears in an edge gets a key, including a vertex with
no outgoing edges, whose list is empty. Each list is sorted in increasing order and has no
repeats, so the result does not depend on the order of the edge records ("deterministic").
The weights are not stored.

### Arguments
- `edges`: a collection of edge records with the fields `source` and `target`.

### Returns
- `Dict{Int64, Vector{Int64}}`: key `u` holds the sorted outgoing neighbors of vertex `u`.

### Example
```julia
edges = [(source = 1, target = 3, weight = 1.0), (source = 1, target = 2, weight = 4.0)];
adjacency_list(edges)   # Dict(1 => [2, 3], 2 => [], 3 => [])
```
"""
function adjacency_list(edges)::Dict{Int64, Vector{Int64}}

    # initialize: one empty neighbor vector per vertex. Dict(key => value for x in xs) builds
    # a dictionary with one entry per item of xs; here, key id holds a new empty vector -
    result = Dict(id => Int64[] for id in vertex_ids(edges))

    # add the target of each edge to the neighbor vector of its source -
    for edge in edges
        push!(result[Int64(edge.source)], Int64(edge.target))
    end

    # remove repeated neighbors, then sort each vector. unique! and sort! change the vector
    # in place, so the vectors stored in result change too -
    for neighbors in values(result)
        sort!(unique!(neighbors)) # first unique! removes repeats, then sort! puts the ids in increasing order
    end

    # return the adjacency list -
    return result
end

"""
    adjacency_matrix(edges) -> NamedTuple

Build a weighted adjacency matrix and return its vertex ordering.

The matrix `A` has one row and one column per vertex. Row and column `i` belong to the
vertex `vertex_ids[i]`, which need not equal `i` when the ids are not `1, 2, …, n`. Entry
`A[i,j]` holds the weight of the edge from `vertex_ids[i]` to `vertex_ids[j]`, and `0.0` when
there is no such edge. So an edge of weight zero cannot be told apart from a missing edge. If
the same `(source, target)` pair appears more than once, the last record's weight is kept.

### Arguments
- `edges`: a collection of edge records with the fields `source`, `target`, and `weight`.

### Returns
A `NamedTuple` with the fields:
- `matrix::Matrix{Float64}`: the `n × n` weighted adjacency matrix, where `n` is the number of
  vertices.
- `vertex_ids::Vector{Int64}`: the vertex of each row and column, in increasing order.

### Example
```julia
edges = [(source = 1, target = 2, weight = 10.0), (source = 2, target = 3, weight = 2.0)];
result = adjacency_matrix(edges);
result.matrix[1, 2]   # 10.0
result.vertex_ids     # [1, 2, 3]
```
"""
function adjacency_matrix(edges)::NamedTuple

    # get the sorted vertex ids; position i in this vector is row (and column) i of the matrix -
    ids = vertex_ids(edges)

    # map each vertex id to its row/column position. enumerate(ids) gives the pairs
    # (1, ids[1]), (2, ids[2]), ..., and the dictionary stores id => position -
    positions = Dict(id => index for (index, id) in enumerate(ids))

    # initialize: an n × n matrix of zeros, where n is the number of vertices -
    matrix = zeros(Float64, length(ids), length(ids))

    # store the weight of each edge in row (source position), column (target position) -
    for edge in edges
        matrix[positions[Int64(edge.source)], positions[Int64(edge.target)]] = Float64(edge.weight)
    end

    # return the matrix and the vertex of each row and column, as a NamedTuple -
    return (matrix = matrix, vertex_ids = ids)
end

"""
    directed_density(number_of_vertices::Integer, number_of_edges::Integer) -> Float64

Compute density for a loop-free directed graph.

A loop-free directed graph with `n` vertices has at most `n⋅(n − 1)` edges: each vertex can
point to each of the other `n − 1` vertices. The density is the fraction of those possible
edges that are present, `ρ = m / (n⋅(n − 1))`, where `m` is the number of edges. A density near
1 means a dense graph, and near 0 a sparse graph. When `n ≤ 1`, no loop-free edge is
possible, and we return 0 by convention, as in the L4a lecture.

### Arguments
- `number_of_vertices::Integer`: the number of vertices `n`; `n ≥ 0`.
- `number_of_edges::Integer`: the number of directed edges `m`; `0 ≤ m ≤ n⋅(n − 1)`.

### Returns
- `Float64`: the density `ρ`, between 0 and 1.

### Throws
- `ArgumentError`: `n` is negative or `m` is negative.
- `ArgumentError`: `n > 1` and `m` is larger than `n⋅(n − 1)`. When `n ≤ 1`, the function returns
  `0.0` for any `m ≥ 0` without this check.

### Example
```julia
directed_density(6, 7)   # 7/30 ≈ 0.2333
```
"""
function directed_density(number_of_vertices::Integer, number_of_edges::Integer)::Float64

    # check the inputs. The form `condition || throw(...)` means: if condition is false, stop with an error -
    number_of_vertices >= 0 || throw(ArgumentError("number_of_vertices must be nonnegative"))
    number_of_edges >= 0 || throw(ArgumentError("number_of_edges must be nonnegative"))

    # with 0 or 1 vertex no loop-free edge is possible, so the density is 0 by convention -
    number_of_vertices <= 1 && return 0.0 # if n ≤ 1, return 0.0 now

    # compute the largest possible number of edges, n(n - 1), and check that m does not exceed it -
    maximum_edges = number_of_vertices * (number_of_vertices - 1)
    number_of_edges <= maximum_edges || throw(ArgumentError("too many edges for a simple directed graph")) # if m > n(n - 1), stop with an error

    # return the fraction of possible edges that are present -
    return number_of_edges / maximum_edges
end

"""
    representation_report(edges) -> NamedTuple

Summarize the storage counts for matrix and adjacency-list representations.

For a graph with `n` vertices and `m` edges, a full adjacency matrix stores `n²` entries,
one per ordered pair of vertices, whether or not the edge exists. An adjacency list stores one
key per vertex plus one neighbor entry per edge, `n + m` entries. The L4a lecture uses this
report to compare the two for its six-vertex, seven-edge graph (36 against 13).

Here `n` is the number of distinct vertex ids in `edges`, and `m` is the number of records in
`edges`. A record that repeats an earlier `(source, target)` pair counts again in `m`, even
though `adjacency_list` would store it once.

### Arguments
- `edges`: a collection of edge records with the fields `source` and `target`.

### Returns
A `NamedTuple` with the fields:
- `vertices::Int`: the number of vertices `n`.
- `edges::Int`: the number of edge records `m`.
- `density::Float64`: the directed density `m / (n⋅(n − 1))`, from `directed_density`.
- `matrix_entries::Int`: `n²`, the entries of a full adjacency matrix.
- `adjacency_list_entries::Int`: `n + m`, the keys plus neighbor entries of an adjacency list.

### Throws
- `ArgumentError`: `m` is larger than `n⋅(n − 1)` (raised by `directed_density`).

### Example
```julia
records = read_weighted_edges(joinpath(CHEME5800_L4A_DATA, "SimpleGraph.txt"));
representation_report(records)
# (vertices = 6, edges = 7, density = 0.2333…, matrix_entries = 36, adjacency_list_entries = 13)
```
"""
function representation_report(edges)::NamedTuple

    # count the vertices n and the edge records m -
    ids = vertex_ids(edges)
    n = length(ids)
    m = length(edges)

    # return the counts as a NamedTuple. Each line `name = value` creates one field -
    return (
        vertices = n,
        edges = m,
        density = directed_density(n, m),
        matrix_entries = n^2, # one entry for every ordered pair of vertices
        adjacency_list_entries = n + m, # one key per vertex plus one neighbor entry per edge record
    )
end
