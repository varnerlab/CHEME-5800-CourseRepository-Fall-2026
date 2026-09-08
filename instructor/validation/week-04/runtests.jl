const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-04"))

include(joinpath(WEEK_ROOT, "L4a", "Include.jl"))
include(joinpath(WEEK_ROOT, "L4c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L4d", "Include.jl"))

# L4b ships deliberately incomplete traversal functions. Validation loads the
# instructor solution directly instead of `L4b/Include.jl`, which loads the
# student module with the same name.
include(joinpath(WEEK_ROOT, "L4b", "src", "Compute-solution.jl"))
using .L4bTraversal

# L4d likewise ships a stub in `src/Compute.jl`; its `Include.jl` above loaded
# that stub, and the solution below replaces the module. Calls stay qualified so
# they resolve against the replacement.
include(joinpath(WEEK_ROOT, "L4d", "src", "Compute-solution.jl"))

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

    # Verify deterministic traversal of the lab graph from two starting nodes.
    @test depth_first_order(adjacency, 1) == [1, 2, 3, 5, 4, 6]
    @test breadth_first_order(adjacency, 1) == [1, 2, 3, 4, 5, 6]
    @test depth_first_order(adjacency, 3) == [3, 5, 4, 6]
    @test breadth_first_order(adjacency, 3) == [3, 5, 4, 6]

    # Verify that cycles terminate, duplicate edges are normalized, and neither
    # traversal mutates the caller's adjacency list.
    cyclic = adjacency_from_edges([(1, 2), (1, 2), (2, 3), (3, 1), (2, 4)])
    snapshot = deepcopy(cyclic)
    @test depth_first_order(cyclic, 1) == [1, 2, 3, 4]
    @test breadth_first_order(cyclic, 1) == [1, 2, 3, 4]
    @test cyclic == snapshot

    # Verify the documented invalid-start behavior.
    @test_throws ArgumentError depth_first_order(adjacency, 99)
    @test_throws ArgumentError breadth_first_order(adjacency, true)
end

@testset "L4b lab ships incomplete student traversals" begin
    stub_path = joinpath(WEEK_ROOT, "L4b", "src", "Compute.jl")
    stub = read(stub_path, String)

    # The release must retain every implementation task and omit distinctive
    # expressions from the reference solution.
    for todo in 1:6
        @test occursin("TODO $(todo)", stub)
    end
    @test occursin("not implemented yet", stub)
    @test !occursin("while head <= length(queue)", stub)
    @test !occursin("visit(start_id)", stub)

    # The scaffold must parse, retain its completed adjacency helper, and fail
    # directly when either unfinished traversal is called.
    sandbox = Module(:L4bStubSandbox)
    Base.include(sandbox, stub_path)
    stub_adjacency = sandbox.L4bTraversal.adjacency_from_edges([(1, 2), (2, 3)])
    @test stub_adjacency == Dict(1 => [2], 2 => [3], 3 => Int64[])
    @test_throws ErrorException sandbox.L4bTraversal.depth_first_order(stub_adjacency, 1)
    @test_throws ErrorException sandbox.L4bTraversal.breadth_first_order(stub_adjacency, 1)
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

@testset "L4d production-planning route" begin
    path = joinpath(WEEK_ROOT, "L4d", "data", "Production-Process.edgelist")
    edge_models = MyGraphEdgeModels(path, parse_production_edge; delim = ',', comment = '#')
    graph = build(MySimpleDirectedGraphModel, edge_models)
    upper_route = [1, 2, 3, 4, 5, 9]
    lower_route = [1, 2, 6, 7, 8, 5, 9]

    # Route-cost contract.
    @test L4dProductionPlanning.route_cost(graph.edges, upper_route) == 16.0
    @test L4dProductionPlanning.route_cost(graph.edges, lower_route) == 10.0
    @test L4dProductionPlanning.route_cost(graph.edges, [1]) == 0.0
    @test_throws ArgumentError L4dProductionPlanning.route_cost(graph.edges, Int64[])
    @test_throws ArgumentError L4dProductionPlanning.route_cost(graph.edges, [1, 3])

    # Dijkstra and Bellman–Ford agree on the baseline route.
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
    @test L4dProductionPlanning.reconstruct_route(dijkstra_previous, 9) == lower_route
    @test bellman_distances[9] == dijkstra_distances[9]
    @test L4dProductionPlanning.reconstruct_route(bellman_previous, 9) == lower_route
    @test L4dProductionPlanning.reconstruct_route(Dict{Int64, Union{Nothing, Int64}}(), 4) == [4]
    @test_throws ArgumentError L4dProductionPlanning.reconstruct_route(Dict(1 => 2, 2 => 1), 1)

    # The discount scenario changes the copy, not the baseline.
    discounted = deepcopy(graph)
    discounted.edges[(3, 4)] = 0.0
    discounted_distances, discounted_previous = findshortestpath(
        discounted,
        discounted.nodes[1];
        algorithm = DijkstraAlgorithm(),
    )
    @test discounted_distances[9] == 8.0
    @test L4dProductionPlanning.reconstruct_route(discounted_previous, 9) == upper_route
    @test graph.edges[(3, 4)] == 8.0

    # Break-even contract: the routes tie at 2, and the step must lie on the candidate route.
    @test L4dProductionPlanning.breakeven_weight(graph.edges, upper_route, lower_route, (3, 4)) == 2.0
    @test L4dProductionPlanning.breakeven_weight(graph.edges, lower_route, upper_route, (6, 7)) == 8.0
    @test_throws ArgumentError L4dProductionPlanning.breakeven_weight(graph.edges, upper_route, lower_route, (6, 7))
    @test_throws ArgumentError L4dProductionPlanning.breakeven_weight(graph.edges, upper_route, lower_route, (1, 2))
    @test_throws ArgumentError L4dProductionPlanning.breakeven_weight(graph.edges, [1, 2, 3, 4, 5, 9, 3, 4], lower_route, (3, 4))
end

@testset "graph-model shortest-path edge cases" begin
    # A two-vertex path needs the single relaxation pass allowed by |V|-1.
    positive_edge = build(MyGraphEdgeModel, (id = 0, source = 1, target = 2, weight = 1.0))
    positive_graph = build(MySimpleDirectedGraphModel, Dict(0 => positive_edge))
    distances, previous = findshortestpath(
        positive_graph,
        positive_graph.nodes[1];
        algorithm = BellmanFordAlgorithm(),
    )
    @test distances[2] == 1.0
    @test previous[2] == 1

    # The graph-model Dijkstra API must enforce the nonnegative-weight contract.
    negative_edge = build(MyGraphEdgeModel, (id = 0, source = 1, target = 2, weight = -1.0))
    negative_graph = build(MySimpleDirectedGraphModel, Dict(0 => negative_edge))
    @test_throws ArgumentError findshortestpath(
        negative_graph,
        negative_graph.nodes[1];
        algorithm = DijkstraAlgorithm(),
    )
end

@testset "L4d lab ships an incomplete break-even function" begin
    stub_path = joinpath(WEEK_ROOT, "L4d", "src", "Compute.jl")
    stub = read(stub_path, String)

    # The release must retain every task and omit distinctive solution expressions.
    for todo in 1:2
        @test occursin("TODO $(todo)", stub)
    end
    @test occursin("not implemented yet", stub)
    @test !occursin("count_on(", stub)
    @test !occursin("reference_cost - (candidate_cost", stub)

    # The scaffold must parse, keep its completed helpers, and fail directly when
    # the unfinished function is called.
    sandbox = Module(:L4dStubSandbox)
    Base.include(sandbox, stub_path)
    @test sandbox.L4dProductionPlanning.reconstruct_route(Dict(2 => 1), 2) == [1, 2]
    @test sandbox.L4dProductionPlanning.route_cost(Dict((1, 2) => 1.0), [1, 2]) == 1.0
    @test_throws ErrorException sandbox.L4dProductionPlanning.breakeven_weight(Dict((1, 2) => 1.0), [1, 2], [1, 2], (1, 2))
end
