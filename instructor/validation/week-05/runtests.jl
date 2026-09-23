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
    # L5b and L5d are walked through in class, so their student files ship the
    # working implementation: the student setups must solve and validate, not throw.
    @meeting "L5b" begin
        graph = build_sensitivity_graph(joinpath(WEEK_ROOT, "L5b", "data", "Workers-Tasks-Bipartite.edgelist"))
        _, flow = maximumflow(graph, graph.nodes[1], graph.nodes[13]; algorithm = EdmondsKarpAlgorithm())
        @test L5bStudentSetup.validate_sensitivity_flow(graph, flow, 1, 13).valid
        @test L5bStudentSetup.cut_capacity(graph, [1]) == 3.0
        @test !occursin("# TODO 1:", read(joinpath(WEEK_ROOT, "L5b", "src", "Compute.jl"), String))
    end

    @meeting "L5d" begin
        department = L5dStudentSetup.read_department(joinpath(WEEK_ROOT, "L5d", "data"))
        network = L5dStudentSetup.build_teaching_network(department)
        result = L5dStudentSetup.solve_min_cost_flow(network)
        @test result.cost == 5.0
        @test L5dStudentSetup.validate_flow_solution(network.edges, result).valid
        @test !occursin("# TODO 1:", read(joinpath(WEEK_ROOT, "L5d", "src", "Compute.jl"), String))
        # The student file matches the reference apart from its header comment.
        student_body = split(read(joinpath(WEEK_ROOT, "L5d", "src", "Compute.jl"), String), "module L5dMinCostFlow"; limit = 2)[2]
        reference_body = split(read(joinpath(WEEK_ROOT, "L5d", "src", "Compute-solution.jl"), String), "module L5dMinCostFlow"; limit = 2)[2]
        @test student_body == reference_body
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
    @testset "L5d teaching-assignment flow" begin
        department = read_department(joinpath(WEEK_ROOT, "L5d", "data"))
        @test (nrow(department.faculty), nrow(department.courses)) == (10, 12)
        @test department.fixed == [("A", "CHEME-4320")]
        @test staffing_totals(department) == (total_load = 13, total_min = 11, total_max = 15, totals_ok = true)

        # Network: 36 nodes; 10 load, 42 option, 12 staffing, and 12 completion edges.
        network = build_teaching_network(department)
        @test length(network.labels) == 36
        @test length(network.edges) == 76
        capstone_staffing = only(filter(e -> e.source == network.course_node["CHEME-4320"], network.edges))
        @test capstone_staffing.target == network.completion_node["CHEME-4320"]
        @test (capstone_staffing.lower, capstone_staffing.upper) == (3.0, 3.0)
        @test count(e -> e.target == network.sink, network.edges) == 12
        @test network.required_flow == 13.0
        load_edges = filter(e -> e.source == network.source, network.edges)
        @test all(e -> e.lower == e.upper, load_edges)
        fixed_edge = only(filter(e -> (e.source, e.target) ==
            (network.faculty_node["A"], network.course_node["CHEME-4320"]), network.edges))
        @test (fixed_edge.lower, fixed_edge.upper) == (1.0, 1.0)
        @test !any(e -> (e.source, e.target) ==
            (network.faculty_node["C"], network.course_node["CHEME-2880"]), network.edges) # blank: no edge

        form = flow_formulation(network.edges, network.source, network.sink, network.required_flow)
        @test size(form.A) == (36, 76)
        @test all(sum(form.A; dims = 1) .== 0.0)
        @test sum(form.b) == 0.0

        # Baseline schedule, solved from the arrays the notebook assembles by hand.
        lp = solve_flow_lp(network, form.A, form.b, form.w, form.lower, form.capacity)
        @test lp.cost == 5.0
        @test_throws DimensionMismatch solve_flow_lp(network, form.A[:, 1:end-1], form.b, form.w, form.lower, form.capacity)
        result = solve_min_cost_flow(network)
        @test result.vector == lp.vector
        @test result.status == MathOptInterface.OPTIMAL
        @test result.cost == 5.0
        @test validate_flow_solution(network.edges, result).valid
        @test all(v -> v == round(v), result.vector)
        schedule = teaching_schedule(department, network, result)
        @test schedule_checks(department, schedule).all_ok
        @test sort(schedule.name[schedule.course .== "CHEME-4320"]) == ["A", "E", "H"]
        published = assignments_by_faculty(department, schedule)
        @test published.courses[published.name .== "A"] == ["ENGRD-2190, CHEME-4320"]
        @test published.scores[published.name .== "J"] == ["2"]
        @test sort(unique(schedule.course[schedule.course .∈ Ref(["CHEME-5310", "CHEME-6310", "CHEME-6440", "CHEME-6800"])])) ==
            ["CHEME-6310", "CHEME-6800"]

        # Sabbatical: the totals check passes but no schedule exists.
        sabbatical = with_load(department, "B", 0)
        @test department.faculty.load[2] == 1 # the input is unchanged
        @test staffing_totals(sabbatical).totals_ok
        sabbatical_result = solve_min_cost_flow(build_teaching_network(sabbatical))
        @test sabbatical_result.status == MathOptInterface.INFEASIBLE
        @test isnothing(sabbatical_result.cost)
        @test_throws ArgumentError teaching_schedule(sabbatical, build_teaching_network(sabbatical), sabbatical_result)

        # Scenarios the notebook runs live or lists as questions. Several schedules can
        # tie, so these pin the ones the notebook and the answer sheet describe.
        function scenario(d)
            n = build_teaching_network(d)
            r = solve_min_cost_flow(n)
            r.optimal || return (result = r, pairs = Set{Tuple{String,String}}())
            @test validate_flow_solution(n.edges, r).valid
            sched = teaching_schedule(d, n, r)
            @test schedule_checks(d, sched).all_ok
            return (result = r, pairs = Set(zip(sched.name, sched.course)))
        end
        base_pairs = Set(zip(schedule.name, schedule.course))
        c3 = scenario(with_preference(department, "C", "CHEME-3130", 3)) # live demo: C and E swap
        @test c3.result.cost == 7.0
        @test setdiff(c3.pairs, base_pairs) == Set([("E", "CHEME-3130"), ("C", "CHEME-4320")])
        c1 = scenario(with_preference(department, "C", "CHEME-3130", 1)) # nothing moves
        @test c1.result.cost == 6.0
        @test c1.pairs == base_pairs
        mandate = scenario(with_fixed(department, "J", "CHEME-3130"))
        @test mandate.result.cost == 7.0
        @test ("J", "CHEME-3130") in mandate.pairs
        @test length(department.fixed) == 1 # the input is unchanged
        bonus = scenario(with_cost(department, "J", "CHEME-3130", -1.0)) # a bonus of 3 points
        @test bonus.result.cost == 4.0
        @test ("J", "CHEME-3130") in bonus.pairs
        tie = scenario(with_cost(department, "J", "CHEME-3130", 0.0)) # a bonus of exactly 2: a tie
        @test tie.result.cost == 5.0
        follow_up = scenario(with_preference(sabbatical, "G", "CHEME-2880", 2))
        @test follow_up.result.cost == 8.0
        @test setdiff(base_pairs, follow_up.pairs) == Set([("B", "CHEME-2880"), ("G", "ENGRI-1120"), ("I", "CHEME-6310")])
        flexible = scenario(with_staffing(department, "CHEME-4320", 2, 4))
        @test flexible.result.cost == 4.0
        @test department.courses.min_faculty[department.courses.course .== "CHEME-4320"] == [3] # unchanged

        # Input checks.
        @test_throws ArgumentError with_fixed(department, "C", "CHEME-2880") # blank pairing
        @test_throws ArgumentError with_preference(department, "A", "CHEME-2880", 4)
        @test_throws ArgumentError with_load(department, "Z", 1)
        @test_throws ArgumentError with_cost(department, "C", "CHEME-2880", -1.0) # blank pairing
        @test_throws ArgumentError with_cost(department, "C", "CHEME-3130", Inf)
        # A new score, or a blank, replaces an earlier cost change for the same pairing.
        rescored = with_preference(with_cost(department, "J", "CHEME-3130", -1.0), "J", "CHEME-3130", 1)
        @test isempty(rescored.costs)
        @test with_preference(with_cost(department, "J", "CHEME-3130", -1.0), "J", "CHEME-3130", missing) isa NamedTuple
        half = with_cost(department, "J", "CHEME-3130", -0.5)
        half_network = build_teaching_network(half)
        @test solve_min_cost_flow(half_network).cost == 4.5
        @test plot_teaching_flow(half, half_network, solve_min_cost_flow(half_network)) isa Plots.Plot
        @test_throws ArgumentError with_staffing(department, "CHEME-4320", 4, 2)
        @test_throws ArgumentError read_department(joinpath(WEEK_ROOT, "missing"))
        @test_throws ArgumentError FlowEdge(1, 2, 1.0, 2.0, 1.0)

        # The figure helper draws the network before and after solving, in both themes,
        # and draws an infeasible scenario instead of failing.
        @test plot_teaching_flow(department, network) isa Plots.Plot
        @test plot_teaching_flow(department, network, result; theme = :dark) isa Plots.Plot
        @test plot_teaching_flow(sabbatical, build_teaching_network(sabbatical), sabbatical_result) isa Plots.Plot
    end
end
