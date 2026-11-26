using LinearAlgebra
using Test
using TOML
import JSON # read the notebook with its cell ids
import REPL # apply the notebook's soft-scope rules

const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-15"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))

# Plot rendering runs in CI without a window server.
get!(ENV, "GKSwstype", "100")

released("L15a") && include(joinpath(WEEK_ROOT, "L15a", "Include.jl"))

# the test equation dx/dt = p ⋅ x, in the form f!(dx, x, p, t) -
function decay!(dx, x, p, t)
    dx[1] = p * x[1]
    return nothing
end

# a right-hand side that counts its own calls: dx/dt = λ ⋅ x -
mutable struct CountingDecay
    λ::Float64
    calls::Int64
end

function counting_decay!(dx, x, p, t)
    p.calls += 1
    dx[1] = p.λ * x[1]
    return nothing
end

@meeting "L15a" begin
    @testset "fixed-step reference methods" begin
        # the inputs of the run, named once -
        λ = -0.3
        t_start = 0.0
        t_final = 10.0
        Δt = 0.5
        Δt_fine = Δt / 2                                   # the halved step for the order test
        z = λ * Δt
        number_of_steps = round(Int, (t_final - t_start) / Δt)
        expected_orders = Dict(ExplicitEulerMethod() => 1, RungeKutta4Method() => 4) # theory, not data
        order_tolerance = 0.15

        # one step matches the Taylor polynomial of exp(z) of the method's order -
        @test advance(decay!, [1.0], λ, t_start, Δt; algorithm = ExplicitEulerMethod())[1] ≈ 1 + z
        @test advance(decay!, [1.0], λ, t_start, Δt; algorithm = RungeKutta4Method())[1] ≈ 1 + z + z^2/2 + z^3/6 + z^4/24

        # advance does not change its input -
        x = [1.0]
        advance(decay!, x, λ, t_start, Δt)
        @test x == [1.0]

        # the shape of a run -
        result = integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = Δt, algorithm = RungeKutta4Method())
        @test length(result.t) == number_of_steps + 1
        @test result.t[1] == t_start && result.t[end] == t_final
        @test size(result.x) == (number_of_steps + 1, 1)
        @test result.t[3] == t_start + 2 * Δt

        # evaluations equals the number of calls of f! that the right-hand side counted -
        for algorithm in (ExplicitEulerMethod(), RungeKutta4Method())
            counter = CountingDecay(λ, 0)
            counted = integrate(counting_decay!, [1.0], counter; t_start = t_start, t_final = t_final, Δt = Δt, algorithm = algorithm)
            @test counted.evaluations == counter.calls
            @test counter.calls > 0
        end

        # measured order from step halving: log2(e(Δt)/e(Δt/2)) is near the method's order -
        for (algorithm, order) in expected_orders
            e1 = abs(integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = Δt, algorithm = algorithm).x[end, 1] - exp(λ * (t_final - t_start)))
            e2 = abs(integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = Δt_fine, algorithm = algorithm).x[end, 1] - exp(λ * (t_final - t_start)))
            @test abs(log2(e1 / e2) - order) < order_tolerance
        end

        # Euler above its limit 2/|λ| grows; below it decays -
        t_long = 10 * t_final
        @test abs(integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_long, Δt = 2.5 / abs(λ)).x[end, 1]) > 1
        @test abs(integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_long, Δt = 1.5 / abs(λ)).x[end, 1]) < 1

        # bad arguments: a step that does not divide the interval, a zero step, and an empty interval -
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = 0.3)
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = 0.0)
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = Inf)
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_start, t_final = Inf, Δt = Δt)
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_start, t_final = t_final, Δt = t_final / eps())
        @test_throws ArgumentError integrate(decay!, [1.0], λ; t_start = t_final, t_final = t_final, Δt = Δt)

        # the names resolve to the course package in a notebook session (OrdinaryDiffEq and Plots are loaded) -
        for name in (:advance, :integrate, :ExplicitEulerMethod, :RungeKutta4Method)
            @test parentmodule(getfield(Main, name)) === VLDataScienceMachineLearningPackage
        end

        # RK4 on a gene circuit matches Tsit5 at tight tolerances, from the zero state -
        network = build(MyGeneNetworkModel, motif_path("negative-feedback-loop"))
        x₀ = zeros(2 * length(network.genes))
        t_gene = 6 * t_final
        Δt_gene = Δt / 50
        reference_reltol = 1e-10                           # the Tsit5 reference tolerances
        reference_abstol = 1e-12
        accuracy_tolerance = 1e-6                          # the relative error RK4 must reach
        mine = integrate(balances!, x₀, network; t_start = t_start, t_final = t_gene, Δt = Δt_gene, algorithm = RungeKutta4Method())
        problem = ODEProblem(balances!, x₀, (t_start, t_gene), network)
        reference = OrdinaryDiffEq.solve(problem, Tsit5(); reltol = reference_reltol, abstol = reference_abstol, saveat = [t_gene])
        @test norm(mine.x[end, :] - reference.u[end]) / norm(reference.u[end]) < accuracy_tolerance
        @test norm(reference.u[end]) > 0
    end
end

@meeting "L15a" begin
    @testset "memory config and generic balances!" begin

        # the memory circuit: three genes X, Y, Z and the inducer I, read back from the TOML -
        memory_path = motif_path("memory")
        memory_config = TOML.parsefile(memory_path)
        memory = build(MyGeneNetworkModel, memory_path)
        expected_names = [gene["name"] for gene in memory_config["genes"]]
        @test [gene.name for gene in memory.genes] == expected_names
        @test expected_names == ["X", "Y", "Z"]
        @test collect(keys(memory.inputs)) == collect(keys(memory_config["inputs"]))
        @test memory.inputs["I"].initial == memory_config["inputs"]["I"]["initial"]

        # the circuit, the interval, and the inducer pulse (two schedule times) -
        network = build(MyGeneNetworkModel, motif_path("negative-feedback-loop"))
        x₀ = zeros(2 * length(network.genes))
        t_span = (0.0, 3000.0)
        t_on = 600.0                                       # the inducer turns on
        t_off = 1800.0                                     # the inducer turns off
        I_baseline = network.inputs["I"].initial
        I_pulse = 5 * I_baseline
        solver_reltol = 1e-8                               # the solver tolerances for every solve
        solver_abstol = 1e-10
        solver_tolerance = 1e-5                            # agreement with finite differences

        # each method with ForwardDiff, against the same method with finite differences -
        methods = Dict("Rodas5P" => Rodas5P(), "FBDF" => FBDF())
        methods_fd = Dict("Rodas5P" => Rodas5P(autodiff = OrdinaryDiffEq.AutoFiniteDiff()), "FBDF" => FBDF(autodiff = OrdinaryDiffEq.AutoFiniteDiff()))
        for pulsed in (false, true)
            if pulsed == true
                set_input!(network, "I", [t_on, t_off], [I_pulse, I_baseline])
            end
            problem = ODEProblem(balances!, x₀, t_span, network)

            # the default solver picks its own method and differentiates with ForwardDiff; it has no autodiff option,
            # so the reference is Rodas5P with finite differences -
            default_dual = OrdinaryDiffEq.solve(problem; reltol = solver_reltol, abstol = solver_abstol)
            default_fd = OrdinaryDiffEq.solve(problem, Rodas5P(autodiff = OrdinaryDiffEq.AutoFiniteDiff()); reltol = solver_reltol, abstol = solver_abstol)
            @test string(default_dual.retcode) == "Success"
            @test norm(default_dual.u[end] - default_fd.u[end]) / norm(default_fd.u[end]) < solver_tolerance

            for (label, method) in methods
                method_fd = methods_fd[label]
                with_dual = OrdinaryDiffEq.solve(problem, method; reltol = solver_reltol, abstol = solver_abstol)
                with_fd = OrdinaryDiffEq.solve(problem, method_fd; reltol = solver_reltol, abstol = solver_abstol)
                @test string(with_dual.retcode) == "Success"
                @test norm(with_dual.u[end] - with_fd.u[end]) / norm(with_fd.u[end]) < solver_tolerance
            end
        end
    end
end

# -- Run the L15a example through the same cells a student runs ------------------------------- #

const L15A_EXAMPLE = joinpath(WEEK_ROOT, "L15a", "CHEME-5800-L15a-Example-ExplicitMethods-Fall-2026.ipynb")
const L15A_CONFIG = joinpath(dirname(L15A_EXAMPLE), "config")

"""Return the cells of the L15a example, read from the notebook file."""
example_cells() = JSON.parsefile(L15A_EXAMPLE)["cells"]

"""Return the source of the example cell with this id."""
cell_source(id::String) = join(only(filter(cell -> cell["id"] == id, example_cells()))["source"])

"""
Run L15a in a fresh module. Replace named settings before evaluation. Render plots on request
to catch failures hidden by lazy drawing.
"""
function run_example(; settings = (;), render = false)
    workspace = Module(:L15aExampleValidation)
    Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
    for (i, cell) in enumerate(example_cells())
        cell["cell_type"] == "code" || continue
        source = join(cell["source"])
        id = cell["id"]
        if id == "settings"
            for (name, value) in pairs(settings)
                pattern = Regex("^$(name) = [^;]*;", "m")
                @assert occursin(pattern, source) "unknown example setting: $(name)"
                source = replace(source, pattern => "$(name) = $(repr(value));"; count = 1)
            end
        end
        result = Base.include_string(REPL.softscope, workspace, source, joinpath(dirname(L15A_EXAMPLE), "validation-cell-$(i).jl"))
        if render && endswith(id, "-plot")
            svg = Base.invokelatest(repr, MIME("image/svg+xml"), result)
            @test occursin("<svg", svg)
        end
    end
    return workspace
end

"""Read a global set by the notebook's code cells."""
nbvar(ws::Module, name::Symbol) = Core.eval(ws, name)

"""Read the value of `name = value;`, a constant local to the example cell `id`."""
function cell_constant(id::String, name::String)
    found = match(Regex("\\b$(name) = ([^;]*);"), cell_source(id))
    @assert found !== nothing "no constant $(name) in cell $(id)"
    return eval(Meta.parse(found.captures[1]))
end

"""Return the Euler step limit at the baseline steady state of a model: the smallest limit of any mode."""
function euler_limit(model, x_steady, t)
    modes = eigvals(jacobian(model, x_steady, t))
    @test all(real.(modes) .< 0)
    return minimum(-2 .* real.(modes) ./ abs2.(modes))
end

"""Check that both methods reach their orders after the pulse, and that RK4 errors clear the reference tolerance."""
function check_order(ws::Module)
    model = nbvar(ws, :model)
    window_start = nbvar(ws, :window_start)
    window_length = nbvar(ws, :window_end) - window_start
    @test window_start == nbvar(ws, :pulse_end)
    @test all(model.inputs["I"].times .<= window_start)
    steps = nbvar(ws, :step_sizes)
    @test all(steps[1:end-1] ./ steps[2:end] .≈ 2)
    runs = nbvar(ws, :window_runs)
    curves = nbvar(ws, :error_curves)
    reference = nbvar(ws, :window_reference)
    y = nbvar(ws, :protein_y)
    @test size(runs) == size(curves) == (length(steps), 2)
    for run in runs
        @test first(run.t) == window_start && last(run.t) ≈ window_start + window_length
        @test run.x[1, :] == nbvar(ws, :x_window)
    end
    for k in eachindex(runs)
        @test curves[k] ≈ abs.(runs[k].x[:, y] - reference(runs[k].t; idxs = y).u)
    end
    errors = maximum.(curves)
    algorithms = (ExplicitEulerMethod(), RungeKutta4Method())
    theory_orders = (1, 4)
    order_tolerances = (0.15, 0.3)
    for j in eachindex(algorithms)
        measured = log2.(errors[1:end-1, j] ./ errors[2:end, j])
        @test all(abs.(measured .- theory_orders[j]) .< order_tolerances[j])
        per_step = VLDataScienceMachineLearningPackage.evaluations_per_step(algorithms[j])
        @test [run.evaluations for run in runs[:, j]] == round.(Int, window_length ./ steps) .* per_step
    end
    largest_reference = maximum(reference[y, :])
    relative_reference_margin = 100
    @test minimum(errors[:, 2]) / largest_reference > relative_reference_margin * cell_constant("order-reference", "relative_tolerance")
end

"""Return the range of a protein after the first three quarters, relative to its mean concentration."""
function relative_tail_range(t, protein, stop)
    tail_start = first(t) + 0.75 * (stop - first(t))
    tail = protein[searchsortedfirst(t, tail_start):searchsortedlast(t, stop)]
    return (maximum(tail) - minimum(tail)) / (sum(tail) / length(tail))
end

"""Check the stability prediction and the tail of each Euler trajectory."""
function check_stability(ws::Module)
    network = nbvar(ws, :feedback)
    stop = nbvar(ws, :stability_final_time)
    equilibrium = steady_state(network; guess = zeros(2 * length(network.genes)), t = 0.0)
    @test equilibrium.converged
    @test nbvar(ws, :x_steady) ≈ equilibrium.x
    limit = nbvar(ws, :Δt_limit)
    @test limit ≈ euler_limit(network, equilibrium.x, 0.0)
    y = length(network.genes) + network.index["Y"]
    factors = nbvar(ws, :stability_factors)
    runs = nbvar(ws, :stability_runs)
    @test length(runs) == length(factors)
    tolerances = (settles = 0.01, oscillates = 0.1)
    for (factor, run) in zip(factors, runs)
        @test run.t[2] - run.t[1] ≈ factor * limit
        @test abs(run.t[end] - stop) <= factor * limit / 2
        variation = relative_tail_range(run.t, run.x[:, y], stop)
        if factor < 1
            @test variation < tolerances.settles
            @test abs(run.x[end, y] - equilibrium.x[y]) / equilibrium.x[y] < tolerances.settles
        else
            @test variation > tolerances.oscillates
        end
    end
    reference = nbvar(ws, :stability_reference)
    @test string(reference.retcode) == "Success"
    @test reference.t[end] == stop
    @test relative_tail_range(reference.t, reference[y, :], stop) < tolerances.settles
end

"""Check the Task 1 runs: the grid, the pulse edges, the starting state, and the work of each method."""
function check_pulse(ws::Module)
    Δt = nbvar(ws, :Δt)
    stop = nbvar(ws, :t_final)
    @test abs(stop - nbvar(ws, :final_time)) <= Δt / 2
    pulse_on = nbvar(ws, :pulse_on)
    pulse_end = nbvar(ws, :pulse_end)
    @test abs(pulse_on - nbvar(ws, :pulse_start)) <= Δt / 2
    @test abs(pulse_end - (nbvar(ws, :pulse_start) + nbvar(ws, :pulse_length))) <= Δt / 2
    model = nbvar(ws, :model)
    x₀ = nbvar(ws, :x₀)
    rates = zeros(length(x₀))
    balances!(rates, x₀, model, 0.0)
    steady_tolerance = 1e-9
    @test maximum(abs.(rates)) < steady_tolerance
    @test input_value(model, "I", pulse_on) == nbvar(ws, :pulse_concentration)
    @test input_value(model, "I", pulse_end) == model.inputs["I"].initial
    reference = nbvar(ws, :reference)
    @test string(reference.retcode) == "Success"
    @test reference.t[end] == stop
    @test pulse_on in reference.t && pulse_end in reference.t
    for (name, algorithm) in ((:euler, ExplicitEulerMethod()), (:rk4, RungeKutta4Method()))
        run = nbvar(ws, name)
        @test first(run.t) == 0.0 && last(run.t) == stop
        @test pulse_on in run.t && pulse_end in run.t
        @test run.evaluations == (length(run.t) - 1) * VLDataScienceMachineLearningPackage.evaluations_per_step(algorithm)
    end
end

@meeting "L15a" begin
    @testset "L15a example" begin
        for name in ("memory", "negative-feedback-loop")
            @test read(joinpath(L15A_CONFIG, name * ".toml")) == read(motif_path(name))
        end
        cells = example_cells()
        for k in 2:length(cells)
            if cells[k]["cell_type"] == "code"
                @test cells[k-1]["cell_type"] == "markdown"
            end
        end

        ws = run_example()
        check_pulse(ws)
        y = nbvar(ws, :protein_y)
        reference = nbvar(ws, :reference)
        @test reference.u[end][y] > reference(nbvar(ws, :pulse_end); idxs = y) > reference.u[1][y]
        check_order(ws)
        check_stability(ws)

        Δt = nbvar(ws, :Δt)
        pulse_start = nbvar(ws, :pulse_start)
        pulse_length = nbvar(ws, :pulse_length)
        factors = nbvar(ws, :stability_factors)
        stability_stop = nbvar(ws, :stability_final_time)

        @testset "Off-grid pulse edges snap to the grid" begin
            down = run_example(; settings = (pulse_start = pulse_start + Δt / 3, final_time = nbvar(ws, :final_time) + Δt / 3))
            check_pulse(down)
            @test nbvar(down, :pulse_on) == nbvar(ws, :pulse_on)
            up = run_example(; settings = (pulse_start = pulse_start + 2 * Δt / 3, final_time = nbvar(ws, :final_time) + 2 * Δt / 3))
            check_pulse(up)
            @test nbvar(up, :pulse_on) == nbvar(ws, :pulse_on) + Δt
            @test nbvar(up, :t_final) == nbvar(ws, :t_final) + Δt
        end

        @testset "Decimal and integer steps" begin
            decimal_fraction = 0.3
            check_pulse(run_example(; settings = (Δt = decimal_fraction * Δt,)))
            whole_step = 2 * round(Int, Δt)
            check_pulse(run_example(; settings = (Δt = whole_step,)))
        end

        @testset "A pulse that does not fit stops with a message" begin
            final_time = nbvar(ws, :final_time)
            @test_throws r"The pulse does not fit inside the runs" run_example(; settings = (pulse_length = final_time,))
            @test_throws r"The pulse does not fit inside the runs" run_example(; settings = (pulse_length = Δt / 3,))
        end

        @testset "Changed settings" begin
            other = run_example(; settings = (
                Δt = Δt / 2,
                final_time = nbvar(ws, :final_time) + pulse_length,
                pulse_concentration = 0.75 * nbvar(ws, :pulse_concentration),
                pulse_start = pulse_start * 1.25,
                pulse_length = pulse_length - pulse_start / 5,
                stability_factors = 1.1 .* factors,
                stability_final_time = stability_stop + 10 * pulse_length,
            ))
            check_pulse(other)
            check_order(other)
            check_stability(other)
        end

        @testset "Coarse pulse grid renders" begin
            limit = euler_limit(nbvar(ws, :model), nbvar(ws, :x₀), 0.0)
            coarse_step = pulse_start
            @test coarse_step > limit
            coarse = run_example(; settings = (Δt = coarse_step, pulse_length = 2 * coarse_step), render = true)
            euler = nbvar(coarse, :euler).x
            @test any(x -> x < 0 || !isfinite(x), euler)
        end

        @testset "Things to Try names real settings" begin
            settings = cell_source("settings")
            names = [found.captures[1] for found in eachmatch(r"`([^`]+)`", cell_source("things-to-try"))]
            @test !isempty(names)
            for name in names
                @test occursin(Regex("^$(name) = ", "m"), settings)
            end
        end
    end
end
