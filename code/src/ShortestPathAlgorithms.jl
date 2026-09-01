# ------------------------------------------------------------------------------------------------ #
# ShortestPathAlgorithms.jl
#
# Dijkstra and Bellman-Ford implementations used by the week-04 L4c lecture.
# ------------------------------------------------------------------------------------------------ #

import DataStructures: PriorityQueue, dequeue!


struct WeightedEdge
    source::Int64
    target::Int64
    weight::Float64

    function WeightedEdge(source::Integer, target::Integer, weight::Real)
        source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
        target isa Bool && throw(ArgumentError("target must be a vertex identifier"))
        isfinite(weight) || throw(ArgumentError("edge weight must be finite"))
        return new(Int64(source), Int64(target), Float64(weight))
    end
end

weighted_edges(records) = [WeightedEdge(record...) for record in records]

function _vertices(edges::AbstractVector{WeightedEdge})::Vector{Int64}
    isempty(edges) && throw(ArgumentError("edges may not be empty"))
    vertices = Set{Int64}()
    for edge in edges
        push!(vertices, edge.source, edge.target)
    end
    return sort!(collect(vertices))
end

function _initialize(edges::AbstractVector{WeightedEdge}, source::Integer)
    source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
    source_id = Int64(source)
    vertices = _vertices(edges)
    source_id in vertices || throw(ArgumentError("source vertex is not in the graph"))
    distances = Dict(vertex => Inf for vertex in vertices)
    previous = Dict{Int64, Union{Nothing, Int64}}(vertex => nothing for vertex in vertices)
    distances[source_id] = 0.0
    return source_id, vertices, distances, previous
end

"""Compute single-source shortest paths for a graph with nonnegative weights."""
function dijkstra(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple
    any(edge -> edge.weight < 0, edges) && throw(ArgumentError("Dijkstra requires nonnegative edge weights"))
    source_id, vertices, distances, previous = _initialize(edges, source)
    adjacency = Dict(vertex => WeightedEdge[] for vertex in vertices)
    for edge in edges
        push!(adjacency[edge.source], edge)
    end

    queue = PriorityQueue{Int64, Float64}()
    queue[source_id] = 0.0
    visited = Set{Int64}()
    while !isempty(queue)
        vertex = dequeue!(queue)
        vertex in visited && continue
        push!(visited, vertex)
        for edge in adjacency[vertex]
            alternative = distances[vertex] + edge.weight
            if alternative < distances[edge.target]
                distances[edge.target] = alternative
                previous[edge.target] = vertex
                queue[edge.target] = alternative
            end
        end
    end
    return (distances = distances, previous = previous)
end

"""Compute single-source shortest paths and reject reachable negative cycles."""
function bellman_ford(edges::AbstractVector{WeightedEdge}, source::Integer)::NamedTuple
    _, vertices, distances, previous = _initialize(edges, source)
    for _ in 1:(length(vertices) - 1)
        changed = false
        for edge in edges
            isfinite(distances[edge.source]) || continue
            alternative = distances[edge.source] + edge.weight
            if alternative < distances[edge.target]
                distances[edge.target] = alternative
                previous[edge.target] = edge.source
                changed = true
            end
        end
        changed || break
    end
    for edge in edges
        if isfinite(distances[edge.source]) && distances[edge.source] + edge.weight < distances[edge.target]
            throw(ArgumentError("graph contains a reachable negative-weight cycle"))
        end
    end
    return (distances = distances, previous = previous)
end

"""Reconstruct a source-to-target path, returning an empty vector when unreachable."""
function reconstruct_path(previous::AbstractDict, source::Integer, target::Integer)::Vector{Int64}
    source_id, target_id = Int64(source), Int64(target)
    haskey(previous, source_id) || throw(ArgumentError("source vertex is not in the predecessor map"))
    haskey(previous, target_id) || throw(ArgumentError("target vertex is not in the predecessor map"))
    source_id == target_id && return Int64[source_id]
    path = Int64[]
    current = target_id
    while current != source_id
        push!(path, current)
        parent = previous[current]
        isnothing(parent) && return Int64[]
        current = parent
    end
    push!(path, source_id)
    reverse!(path)
    return path
end

"""Sum the weights along a validated path."""
function path_cost(edges::AbstractVector{WeightedEdge}, path::AbstractVector{<:Integer})::Float64
    length(path) <= 1 && return 0.0
    weights = Dict((edge.source, edge.target) => edge.weight for edge in edges)
    total = 0.0
    for index in 1:(length(path) - 1)
        key = (Int64(path[index]), Int64(path[index + 1]))
        haskey(weights, key) || throw(ArgumentError("path contains missing edge $(key)"))
        total += weights[key]
    end
    return total
end
