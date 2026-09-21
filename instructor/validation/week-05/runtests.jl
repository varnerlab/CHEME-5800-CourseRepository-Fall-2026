const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-05"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))

released("L5a") && include(joinpath(WEEK_ROOT, "L5a", "Include.jl"))
# Validate the reference implementations; notebook setup loads student scaffolds.
released("L5b") && include(joinpath(WEEK_ROOT, "L5b", "src", "Compute-solution.jl"))
released("L5d") && include(joinpath(WEEK_ROOT, "L5d", "src", "Compute-solution.jl"))
released("L5b") && include(joinpath(WEEK_ROOT, "L5b", "Include.jl"))
released("L5c") && include(joinpath(WEEK_ROOT, "L5c", "Include.jl"))
released("L5d") && include(joinpath(WEEK_ROOT, "L5d", "Include.jl"))

@meeting "L5a" begin
    @testset "L5a maximum-flow contracts" begin
        path = joinpath(WEEK_ROOT, "L5a", "data", "Workers-Tasks-Bipartite.edgelist")
        graph = build_flow_graph(path)
        @test length(graph.nodes) == 13
        @test length(graph.capacity) == 23
        @test parse_constrained_edge("1,2,0,0,1") == (1, 2, 0.0, 0.0, 1.0)
        @test_throws ArgumentError parse_constrained_edge("1,2,1")

        ford_value, ford_flow = maximumflow(
            graph, graph.nodes[1], graph.nodes[13]; algorithm = FordFulkersonAlgorithm(),
        )
        edmonds_value, edmonds_flow = maximumflow(
            graph, graph.nodes[1], graph.nodes[13]; algorithm = EdmondsKarpAlgorithm(),
        )
        @test ford_value == edmonds_value == 3.0
        @test validate_flow(graph, ford_flow, 1, 13).valid
        @test validate_flow(graph, edmonds_flow, 1, 13).valid

        invalid_flow = copy(edmonds_flow)
        invalid_flow[(1, 2)] = 2.0
        @test !validate_flow(graph, invalid_flow, 1, 13).valid
        @test_throws ArgumentError build_flow_graph(joinpath(WEEK_ROOT, "missing.edgelist"))
    end
end

# Load the default notebook setups in separate modules to check the student path.
module L5bStudentSetup
Main.released("L5b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-05", "L5b", "Include.jl"))
end

module L5dStudentSetup
Main.released("L5d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-05", "L5d", "Include.jl"))
end

@testset "Week 5 student scaffolds and reference files" begin
    for meeting in filter(released, ("L5b", "L5d"))
        student_path = joinpath(WEEK_ROOT, meeting, "src", "Compute.jl")
        reference_path = joinpath(WEEK_ROOT, meeting, "src", "Compute-solution.jl")
        @test isfile(student_path)
        @test isfile(reference_path)
    end
    released("L5d") && @test occursin("# TODO 1:", read(joinpath(WEEK_ROOT, "L5d", "src", "Compute.jl"), String))

    # L5b is walked through in class, so its student file ships the working
    # implementation: the student setup must validate a flow, not throw.
    @meeting "L5b" begin
        graph = build_sensitivity_graph(joinpath(WEEK_ROOT, "L5b", "data", "Workers-Tasks-Bipartite.edgelist"))
        _, flow = maximumflow(graph, graph.nodes[1], graph.nodes[13]; algorithm = EdmondsKarpAlgorithm())
        @test L5bStudentSetup.validate_sensitivity_flow(graph, flow, 1, 13).valid
        @test L5bStudentSetup.cut_capacity(graph, [1]) == 3.0
        @test !occursin("# TODO 1:", read(joinpath(WEEK_ROOT, "L5b", "src", "Compute.jl"), String))
    end

    @meeting "L5d" begin
        edges = L5dStudentSetup.read_flow_edges(joinpath(WEEK_ROOT, "L5d", "data", "Workers-Tasks-MCMF-Bipartite.edgelist"))
        @test_throws ErrorException L5dStudentSetup.flow_formulation(edges, 1, 13, 3.0)
        @test !occursin("A[row[edge.source], j] = -1.0",
            read(joinpath(WEEK_ROOT, "L5d", "src", "Compute.jl"), String))
    end
end

@meeting "L5b" begin
    @testset "L5b capacity sensitivity" begin
        path = joinpath(WEEK_ROOT, "L5b", "data", "Workers-Tasks-Bipartite.edgelist")
        baseline = build_sensitivity_graph(path)
        baseline_value, baseline_flow = maximumflow(
            baseline, baseline.nodes[1], baseline.nodes[13]; algorithm = EdmondsKarpAlgorithm(),
        )
        @test baseline_value == 3.0
        @test validate_sensitivity_flow(baseline, baseline_flow, 1, 13).valid

        expanded = deepcopy(baseline)
        expanded.capacity[(1, 3)] = (0.0, 2.0)
        expanded_value, expanded_flow = maximumflow(
            expanded, expanded.nodes[1], expanded.nodes[13]; algorithm = EdmondsKarpAlgorithm(),
        )
        @test expanded_value == 4.0
        @test validate_sensitivity_flow(expanded, expanded_flow, 1, 13).valid
        @test baseline.capacity[(1, 3)] == (0.0, 1.0)

        outage = deepcopy(baseline)
        for edge in keys(outage.capacity)
            edge[1] == 3 && (outage.capacity[edge] = (0.0, 0.0))
        end
        outage_value, outage_flow = maximumflow(
            outage, outage.nodes[1], outage.nodes[13]; algorithm = EdmondsKarpAlgorithm(),
        )
        @test outage_value == 2.0
        @test validate_sensitivity_flow(outage, outage_flow, 1, 13).valid

        # Cut capacities: every cut bounds the flow, and the binding cut moves.
        @test cut_capacity(baseline, [1]) == 3.0
        @test cut_capacity(baseline, 1:12) == 4.0
        @test cut_capacity(baseline, [1, 2, 3, 4]) == 12.0
        @test cut_capacity(expanded, [1]) == 4.0
        @test cut_capacity(expanded, 1:8) == 4.0
        @test cut_capacity(outage, [1]) == 3.0
        @test cut_capacity(outage, [1, 3]) == 2.0
        @test cut_capacity(outage, [1, 3, 5]) == 3.0 # (1,2), (1,4), (5,9) cross; (2,5) and (4,5) enter S and do not count
        # A third slot for worker 3 does not raise the flow past the task-completion cut.
        saturated = deepcopy(baseline)
        saturated.capacity[(1, 3)] = (0.0, 3.0)
        saturated_value, saturated_flow = maximumflow(
            saturated, saturated.nodes[1], saturated.nodes[13]; algorithm = EdmondsKarpAlgorithm(),
        )
        @test saturated_value == 4.0
        @test validate_sensitivity_flow(saturated, saturated_flow, 1, 13).valid
        @test cut_capacity(saturated, [1]) == 5.0
        @test cut_capacity(saturated, 1:8) == 4.0
    end
end

@meeting "L5c" begin
    @testset "L5c resource-allocation LP" begin
        prices, budget = [2.0, 4.0], 100.0
        apples = solve_fruit_problem([0.55, 0.45], prices, budget)
        oranges = solve_fruit_problem([0.15, 0.55], prices, budget)
        alternate = solve_fruit_problem([2.0, 4.0], prices, budget)
        @test apples.quantities ≈ [50.0, 0.0]
        @test oranges.quantities ≈ [0.0, 25.0]
        @test apples.expenditure ≈ budget
        @test oranges.expenditure ≈ budget
        @test alternate.utility ≈ 100.0
        @test alternate.expenditure ≈ budget
        @test_throws DimensionMismatch solve_fruit_problem([1.0], prices, budget)
        @test_throws ArgumentError solve_fruit_problem([1.0, 2.0], [1.0, 0.0], budget)
        @test_throws ArgumentError solve_fruit_problem([1.0, 2.0], prices, -1.0)
    end
end

@meeting "L5d" begin
    @testset "L5d minimum-cost assignment flow" begin
        path = joinpath(WEEK_ROOT, "L5d", "data", "Workers-Tasks-MCMF-Bipartite.edgelist")
        edges = read_flow_edges(path)
        form = flow_formulation(edges, 1, 13, 3.0)
        @test size(form.A) == (13, 23)
        @test all(sum(form.A; dims = 1) .== 0.0)
        @test sum(form.b) == 0.0

        result = solve_min_cost_flow(edges, 1, 13, 3.0)
        assignments = selected_assignments(result)
        @test result.cost == 6.0
        @test validate_flow_solution(edges, result).valid
        @test [(item.worker, item.task) for item in assignments] == [(2, 5), (3, 6), (4, 7)]

        disrupted = [
            edge.source == 4 && edge.target == 7 ?
                FlowEdge(edge.source, edge.target, edge.cost, 0.0, 0.0) : edge
            for edge in edges
        ]
        disrupted_result = solve_min_cost_flow(disrupted, 1, 13, 3.0)
        @test disrupted_result.cost == 9.0
        @test validate_flow_solution(disrupted, disrupted_result).valid
        @test_throws ErrorException solve_min_cost_flow(edges, 1, 13, 4.0)
        @test_throws ArgumentError FlowEdge(1, 2, 1.0, 2.0, 1.0)
        @test_throws ArgumentError read_flow_edges(joinpath(WEEK_ROOT, "missing.edgelist"))
    end
end
