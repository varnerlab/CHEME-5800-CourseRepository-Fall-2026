const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-04"))

include(joinpath(WEEK_ROOT, "L4a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L4b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L4c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L4d", "Include.jl"))

@testset "L4a graph representations" begin
    path = joinpath(WEEK_ROOT, "L4a", "data", "SimpleGraph.txt")
    edges = read_weighted_edges(path)
    report = representation_report(edges)
    adjacency = adjacency_list(edges)
    matrix = adjacency_matrix(edges)
    @test report.vertices == 6
    @test report.edges == 7
    @test report.density ≈ 7 / 30
    @test adjacency[1] == [2, 3]
    @test adjacency[6] == Int64[]
    @test matrix.vertex_ids == collect(1:6)
    @test matrix.matrix[1, 3] == 100.0
    @test report.matrix_entries == 36
    @test report.adjacency_list_entries == 13
    @test_throws ArgumentError read_weighted_edges(joinpath(WEEK_ROOT, "missing.txt"))
end

@testset "L4b deterministic traversal" begin
    adjacency = adjacency_from_edges([
        (1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (5, 4), (4, 6),
    ])
    @test depth_first_order(adjacency, 1) == [1, 2, 3, 5, 4, 6]
    @test breadth_first_order(adjacency, 1) == [1, 2, 3, 4, 5, 6]
    @test depth_first_order(adjacency, 3) == [3, 5, 4, 6]
    @test breadth_first_order(adjacency, 3) == [3, 5, 4, 6]
    @test_throws ArgumentError depth_first_order(adjacency, 99)
    @test_throws ArgumentError breadth_first_order(adjacency, true)
end

@testset "L4c shortest-path contracts" begin
    edges = weighted_edges([
        (1, 2, 4.0), (1, 3, 1.0), (3, 2, 2.0), (2, 4, 1.0), (3, 4, 5.0),
    ])
    dijkstra_result = dijkstra(edges, 1)
    bellman_result = bellman_ford(edges, 1)
    @test dijkstra_result.distances == bellman_result.distances
    @test reconstruct_path(dijkstra_result.previous, 1, 4) == [1, 3, 2, 4]
    @test path_cost(edges, [1, 3, 2, 4]) == 4.0

    negative_edges = weighted_edges([(1, 2, 4.0), (1, 3, 5.0), (2, 3, -2.0), (3, 4, 3.0)])
    negative_result = bellman_ford(negative_edges, 1)
    @test negative_result.distances[4] == 5.0
    @test_throws ArgumentError dijkstra(negative_edges, 1)

    reverse_chain = weighted_edges([(3, 4, 1.0), (2, 3, 1.0), (1, 2, 1.0)])
    @test bellman_ford(reverse_chain, 1).distances[4] == 3.0
    disconnected = weighted_edges([(1, 2, 1.0), (3, 4, 1.0)])
    disconnected_result = bellman_ford(disconnected, 1)
    @test reconstruct_path(disconnected_result.previous, 1, 4) == Int64[]

    cycle = weighted_edges([(1, 2, 1.0), (2, 3, -2.0), (3, 1, 0.0)])
    @test_throws ArgumentError bellman_ford(cycle, 1)
    @test_throws ArgumentError path_cost(edges, [1, 4])
end

function parse_production_edge(record::String, delimiter::Char = ',')
    fields = split(record, delimiter)
    return (parse(Int, fields[1]), parse(Int, fields[2]), parse(Float64, fields[3]))
end

function predecessor_path(previous, target)
    path = Int[]
    current = target
    while !isnothing(current)
        push!(path, current)
        current = get(previous, current, nothing)
    end
    reverse!(path)
    return path
end

@testset "L4d production-planning route" begin
    path = joinpath(WEEK_ROOT, "L4d", "data", "Production-Process.edgelist")
    edge_models = MyGraphEdgeModels(path, parse_production_edge; delim = ',', comment = '#')
    graph = build(MySimpleDirectedGraphModel, edge_models)
    dijkstra_distances, dijkstra_previous = findshortestpath(
        graph,
        graph.nodes[1];
        algorithm = DijkstraAlgorithm(),
    )
    bellman_distances, bellman_previous = findshortestpath(
        graph,
        graph.nodes[1];
        algorithm = BellmanFordAlgorithm(),
    )
    @test dijkstra_distances[9] == 10.0
    @test predecessor_path(dijkstra_previous, 9) == [1, 2, 6, 7, 8, 5, 9]
    @test bellman_distances[9] == dijkstra_distances[9]
    @test predecessor_path(bellman_previous, 9) == predecessor_path(dijkstra_previous, 9)

    discounted = deepcopy(graph)
    discounted.edges[(3, 4)] = 0.0
    discounted_distances, discounted_previous = findshortestpath(
        discounted,
        discounted.nodes[1];
        algorithm = DijkstraAlgorithm(),
    )
    @test discounted_distances[9] == 8.0
    @test predecessor_path(discounted_previous, 9) == [1, 2, 3, 4, 5, 9]
    @test graph.edges[(3, 4)] == 8.0
end
