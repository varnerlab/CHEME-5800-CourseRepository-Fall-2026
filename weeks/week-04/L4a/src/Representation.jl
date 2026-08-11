module L4aRepresentation

export adjacency_list, adjacency_matrix, directed_density, read_weighted_edges,
       representation_report, vertex_ids

const WeightedEdgeRecord = NamedTuple{(:source, :target, :weight), Tuple{Int64, Int64, Float64}}

"""Read `source,target,weight` records while ignoring blank and comment lines."""
function read_weighted_edges(path::AbstractString; delimiter::Char = ',')::Vector{WeightedEdgeRecord}
    isfile(path) || throw(ArgumentError("edge-list path does not exist: $(path)"))
    edges = WeightedEdgeRecord[]
    for (line_number, raw_line) in enumerate(eachline(path))
        line = strip(raw_line)
        (isempty(line) || startswith(line, '#')) && continue
        fields = strip.(split(line, delimiter))
        length(fields) == 3 || throw(ArgumentError("line $(line_number) must contain three fields"))
        source = tryparse(Int64, fields[1])
        target = tryparse(Int64, fields[2])
        weight = tryparse(Float64, fields[3])
        isnothing(source) && throw(ArgumentError("invalid source on line $(line_number)"))
        isnothing(target) && throw(ArgumentError("invalid target on line $(line_number)"))
        isnothing(weight) && throw(ArgumentError("invalid weight on line $(line_number)"))
        isfinite(weight) || throw(ArgumentError("weight on line $(line_number) must be finite"))
        push!(edges, (source = source, target = target, weight = weight))
    end
    isempty(edges) && throw(ArgumentError("edge list may not be empty"))
    return edges
end

"""Return sorted vertex identifiers appearing in an edge collection."""
function vertex_ids(edges)::Vector{Int64}
    ids = Set{Int64}()
    for edge in edges
        push!(ids, Int64(edge.source), Int64(edge.target))
    end
    return sort!(collect(ids))
end

"""Build a deterministic outgoing-neighbor adjacency list."""
function adjacency_list(edges)::Dict{Int64, Vector{Int64}}
    result = Dict(id => Int64[] for id in vertex_ids(edges))
    for edge in edges
        push!(result[Int64(edge.source)], Int64(edge.target))
    end
    for neighbors in values(result)
        sort!(unique!(neighbors))
    end
    return result
end

"""Build a weighted adjacency matrix and return its vertex ordering."""
function adjacency_matrix(edges)::NamedTuple
    ids = vertex_ids(edges)
    positions = Dict(id => index for (index, id) in enumerate(ids))
    matrix = zeros(Float64, length(ids), length(ids))
    for edge in edges
        matrix[positions[Int64(edge.source)], positions[Int64(edge.target)]] = Float64(edge.weight)
    end
    return (matrix = matrix, vertex_ids = ids)
end

"""Compute density for a loop-free directed graph."""
function directed_density(number_of_vertices::Integer, number_of_edges::Integer)::Float64
    number_of_vertices >= 0 || throw(ArgumentError("number_of_vertices must be nonnegative"))
    number_of_edges >= 0 || throw(ArgumentError("number_of_edges must be nonnegative"))
    number_of_vertices <= 1 && return 0.0
    maximum_edges = number_of_vertices * (number_of_vertices - 1)
    number_of_edges <= maximum_edges || throw(ArgumentError("too many edges for a simple directed graph"))
    return number_of_edges / maximum_edges
end

"""Summarize the storage counts for matrix and adjacency-list representations."""
function representation_report(edges)::NamedTuple
    ids = vertex_ids(edges)
    n = length(ids)
    m = length(edges)
    return (
        vertices = n,
        edges = m,
        density = directed_density(n, m),
        matrix_entries = n^2,
        adjacency_list_entries = n + m,
    )
end

end

