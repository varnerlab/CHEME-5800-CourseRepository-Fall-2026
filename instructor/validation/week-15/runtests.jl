using LinearAlgebra
using Test
using TOML
import JSON # read the notebook with its cell ids
import REPL # apply the notebook's soft-scope rules
import Random # seeded random states for the L15b step checks

const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-15"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))

# Plot rendering runs in CI without a window server.
get!(ENV, "GKSwstype", "100")

released("L15a") && include(joinpath(WEEK_ROOT, "L15a", "Include.jl"))
# a release of L15b alone loads the course environment through the L15b setup -
released("L15b") && !released("L15a") && include(joinpath(WEEK_ROOT, "L15b", "Include.jl"))

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

# -- L15b: the student functions, loaded from the starter and the solution ------------------- #

const L15B_ROOT = joinpath(WEEK_ROOT, "L15b")
const L15B_SOLUTION = joinpath(L15B_ROOT, "src", "Compute-solution.jl")
const L15B_STARTER = joinpath(L15B_ROOT, "src", "Compute.jl")
const L15B_CONFIG = joinpath(L15B_ROOT, "config", "memory.toml")

# code that only the solution may hold: each marker sits on an answer line -
const L15B_ANSWER_MARKERS = ["ODEProblem(", "OrdinaryDiffEq.solve(", "f!(k₁", "f!(k₄", "mystep(algorithm, "]

"""Include a lab source file into a fresh module, and return that module's `L15bMethods`."""
function load_lab(path::String)::Module
    workspace = Module(:L15bLabValidation)
    Base.include(workspace, path)
    return Base.invokelatest(getproperty, workspace, :L15bMethods)
end

"""A right-hand side that blows up at t = 1 from x = 1: dx/dt = x²."""
function blowup!(dx, x, p, t)
    dx[1] = x[1]^2
    return nothing
end

"""Return the non-blank lines of a source file, stripped."""
nonblank_lines(text::String) = [String(strip(line)) for line in split(text, '\n') if !isempty(strip(line))]

"""Return the code lines of a source file: non-blank lines outside docstrings that do not start with `#`."""
function code_lines_outside_docstrings(text::String)
    lines = String[]
    inside = false
    for line in split(text, '\n')
        stripped = strip(line)
        if occursin("\"\"\"", stripped)
            isodd(count("\"\"\"", stripped)) && (inside = !inside) # a delimiter that opens or closes a docstring
            continue
        end
        (inside || isempty(stripped) || startswith(stripped, "#")) && continue
        push!(lines, String(stripped))
    end
    return lines
end

"""True when every entry of `short` appears in `long`, in order."""
function is_subsequence(short::Vector{String}, long::Vector{String})
    j = 1
    for line in long
        j <= length(short) && line == short[j] && (j += 1)
    end
    return j > length(short)
end

"""The memory circuit at its low steady state, with one pulse set from test constants."""
function l15b_memory_setup(; on = 40.0, off = 52.0, concentration = 4.0)
    model = build(MyGeneNetworkModel, L15B_CONFIG)
    N = length(model.genes)
    x₀ = steady_state(model; guess = zeros(2 * N), t = 0.0).x
    set_input!(model, "I", [on, off], [concentration, model.inputs["I"].initial])
    return (model = model, x₀ = x₀, on = on, off = off)
end

"""The L15b mysolve checks, run in the latest world so the loaded modules' methods are visible."""
function check_l15b_mysolve(sol::Module, starter::Module)
    @test sort(names(sol)) == sort([:L15bMethods, :myintegrate, :mysolve, :mystep])
    @test sort(names(starter)) == sort(names(sol))
    @test read(L15B_CONFIG) == read(joinpath(WEEK_ROOT, "L15a", "config", "memory.toml"))

    (model, x₀, on, off) = l15b_memory_setup()
    T = 240.0
    Δs = 1.0
    rt = 1e-8
    at = 1e-12
    x₀_copy = copy(x₀)
    kw = (t_start = 0.0, t_final = T, stops = [on, off], Δt_save = Δs, reltol = rt, abstol = at)

    @test_throws ErrorException starter.mysolve(balances!, x₀, model; kw...)
    run = sol.mysolve(balances!, x₀, model; kw...)
    save_times = [0.0 + k * Δs for k in 0:round(Int, T / Δs)] # each save time from its index
    save_times[end] = T
    direct = OrdinaryDiffEq.solve(ODEProblem(balances!, copy(x₀), (0.0, T), model), Tsit5();
        tstops = [on, off], saveat = save_times, reltol = rt, abstol = at)
    @test run.t == direct.t
    @test run.x == reduce(hcat, direct.u)
    @test size(run.x) == (length(x₀), length(run.t))
    @test run.evaluations == direct.stats.nf
    @test x₀ == x₀_copy

    # stops at the ends and past the end are dropped (Review Focus 2) -
    @test sol.mysolve(balances!, x₀, model; kw..., stops = [0.0, on, off, T, T + Δs]).x == run.x
    # a save step that does not divide the span (Review Focus 4) -
    @test_throws ArgumentError sol.mysolve(balances!, x₀, model; kw..., Δt_save = T / (round(T / Δs) + 0.5))
    @test_throws ArgumentError sol.mysolve(balances!, x₀, model; kw..., t_final = 0.0)
    # a save step longer than the span rounds to zero saves (codex finding 4) -
    @test_throws ArgumentError sol.mysolve(balances!, x₀, model; kw..., Δt_save = 1e10 * T)
    # a save step with no exact binary form: one save per step, and the last save at t_final (codex finding 1) -
    T_odd = 32.4
    Δs_odd = T_odd / 15 # computed as the lab computes each window step
    t_odd = 112.0 # a start after zero, like the window of the lab
    odd = sol.mysolve(balances!, x₀, model; kw..., t_start = t_odd, t_final = t_odd + T_odd, Δt_save = Δs_odd)
    @test length(odd.t) == round(Int, T_odd / Δs_odd) + 1
    @test odd.t[end] == t_odd + T_odd
    # a solve that stops early (Review Focus 3) -
    @test_throws ErrorException sol.mysolve(blowup!, [1.0], nothing; t_start = 0.0, t_final = 2.0,
        stops = Float64[], Δt_save = 0.5, reltol = rt, abstol = at)

    # edit, save, re-run: including the file twice replaces the module (Review Focus 5) -
    ws = Module(:L15bReload)
    Base.include(ws, L15B_SOLUTION)
    Base.include(ws, L15B_SOLUTION)
    again = Base.invokelatest(getproperty, ws, :L15bMethods)
    @test Base.invokelatest(again.mysolve, balances!, x₀, model; kw...).x == run.x

    # the starter is the solution without its answer lines -
    starter_text = read(L15B_STARTER, String)
    solution_text = read(L15B_SOLUTION, String)
    starter_lines = filter(line -> !startswith(line, "error("), nonblank_lines(starter_text))
    solution_lines = nonblank_lines(solution_text)
    @test is_subsequence(starter_lines, solution_lines)
    @test length(starter_lines) < length(solution_lines)
    starter_code = code_lines_outside_docstrings(starter_text)
    solution_code = code_lines_outside_docstrings(solution_text)
    for marker in L15B_ANSWER_MARKERS
        @test any(line -> occursin(marker, line), solution_code)
        @test !any(line -> occursin(marker, line), starter_code)
    end
end

@meeting "L15b" begin
    @testset "L15b mysolve" begin
        sol = load_lab(L15B_SOLUTION)
        starter = load_lab(L15B_STARTER)
        Base.invokelatest(check_l15b_mysolve, sol, starter)
    end
end

"""The L15b mystep and myintegrate checks, run in the latest world."""
function check_l15b_steps(sol::Module, starter::Module)
    (model, x₀, on, off) = l15b_memory_setup()
    T = 120.0
    Δt = 1.0
    λ = -0.3
    z = Δt * λ
    rng = Random.Xoshiro(5800)

    # the states of the step checks: the start, a state inside the pulse, and a random positive state -
    pkg_run = integrate(balances!, x₀, model; t_start = 0.0, t_final = T, Δt = Δt, algorithm = ExplicitEulerMethod())
    k_inside = round(Int, ((on + off) / 2) / Δt) + 1
    states = [(x₀, 0.0), (pkg_run.x[k_inside, :], pkg_run.t[k_inside]), (x₀ .* (0.5 .+ rand(rng, length(x₀))), 0.0)]

    for alg in (ExplicitEulerMethod(), RungeKutta4Method())
        @test_throws ErrorException starter.mystep(alg, balances!, x₀, model, 0.0, Δt)
        @test_throws ErrorException starter.myintegrate(balances!, x₀, model; t_start = 0.0, t_final = T, Δt = Δt, algorithm = alg)
        for (x, t) in states
            x_copy = copy(x)
            @test isapprox(sol.mystep(alg, balances!, x, model, t, Δt), advance(balances!, x, model, t, Δt; algorithm = alg); rtol = 1e-12)
            @test x == x_copy
        end
        for step in (Δt, Δt / 2)
            mine = sol.myintegrate(balances!, x₀, model; t_start = 0.0, t_final = T, Δt = step, algorithm = alg)
            pkg = integrate(balances!, x₀, model; t_start = 0.0, t_final = T, Δt = step, algorithm = alg)
            @test mine.t == pkg.t
            @test size(mine.x) == (length(x₀), length(mine.t))
            @test isapprox(mine.x, permutedims(pkg.x); rtol = 1e-12)
            @test mine.evaluations == pkg.evaluations
        end
        # a step that does not divide the span (Review Focus 4) -
        @test_throws ArgumentError sol.myintegrate(balances!, x₀, model; t_start = 0.0, t_final = T,
            Δt = T / (round(T / Δt) + 0.5), algorithm = alg)
        @test_throws ArgumentError sol.myintegrate(balances!, x₀, model; t_start = 0.0, t_final = T, Δt = 0.0, algorithm = alg)
    end

    # one step on the test equation dx/dt = λx matches the Taylor polynomial of exp(z) of each order -
    @test sol.mystep(ExplicitEulerMethod(), decay!, [1.0], λ, 0.0, Δt)[1] ≈ 1 + z
    @test sol.mystep(RungeKutta4Method(), decay!, [1.0], λ, 0.0, Δt)[1] ≈ 1 + z + z^2/2 + z^3/6 + z^4/24
end

@meeting "L15b" begin
    @testset "L15b mystep and myintegrate" begin
        sol = load_lab(L15B_SOLUTION)
        starter = load_lab(L15B_STARTER)
        Base.invokelatest(check_l15b_steps, sol, starter)
    end
end

# -- Run the L15b lab through the same cells a student runs ---------------------------------- #

const L15B_LAB = joinpath(L15B_ROOT, "CHEME-5800-L15b-Lab-ExplicitMethods-Fall-2026.ipynb")

"""Return the cells of the L15b lab, read from the notebook file."""
lab_cells() = JSON.parsefile(L15B_LAB)["cells"]

"""
Run the L15b lab in a fresh module. Replace named settings before evaluation. With `solution`,
include the reference functions right after the setup cell, as a student's finished file would be.
Render plots on request.
"""
function run_lab(; settings = (;), solution = true, render = false)
    workspace = Module(:L15bLabValidation)
    Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
    for (i, cell) in enumerate(lab_cells())
        cell["cell_type"] == "code" || continue
        source = join(cell["source"])
        id = cell["id"]
        if id == "settings"
            for (name, value) in pairs(settings)
                pattern = Regex("^$(name) = [^;]*;", "m")
                @assert occursin(pattern, source) "unknown lab setting: $(name)"
                source = replace(source, pattern => "$(name) = $(repr(value));"; count = 1)
            end
        end
        result = Base.include_string(REPL.softscope, workspace, source, joinpath(L15B_ROOT, "validation-cell-$(i).jl"))
        if id == "include" && solution
            Base.include(workspace, L15B_SOLUTION)
        end
        if render && endswith(id, "-plot")
            svg = Base.invokelatest(repr, MIME("image/svg+xml"), result)
            @test occursin("<svg", svg)
        end
    end
    return workspace
end

"""Read the value of `name = value;` from the lab's settings cell."""
function lab_setting(name::String)
    cell = only(filter(c -> get(c, "id", "") == "settings", lab_cells()))
    found = match(Regex("^$(name) = ([^;]*);", "m"), join(cell["source"]))
    @assert found !== nothing "no setting $(name)"
    return eval(Meta.parse(found.captures[1]))
end

"""The L15b lab checks, run in the latest world."""
function check_l15b_lab()
    # the lab ships without outputs, and a markdown cell leads every code cell -
    cells = lab_cells()
    for k in 1:length(cells)
        if cells[k]["cell_type"] == "code"
            @test isempty(cells[k]["outputs"])
            @test cells[k]["execution_count"] === nothing
            @test k > 1 && cells[k-1]["cell_type"] == "markdown"
        end
    end

    # the starter stops at the first student function -
    failure = nothing
    try
        run_lab(solution = false)
    catch e
        failure = e
    end
    @test failure !== nothing
    @test occursin("mysolve", sprint(showerror, failure))

    # the default settings, with every figure rendered -
    ws = run_lab(render = true)
    y = nbvar(ws, :protein_y)
    model = nbvar(ws, :model)
    @test y == length(model.genes) + model.index["Y"]

    # without the stops, the solver steps over the short pulse -
    with_stops = nbvar(ws, :with_stops)
    without_stops = nbvar(ws, :without_stops)
    rise = maximum(with_stops.x[y, :]) - with_stops.x[y, 1]
    @test rise > 0
    @test maximum(abs.(without_stops.x[y, :] .- without_stops.x[y, 1])) < 0.01 * rise
    @test with_stops.t == without_stops.t

    # the measured orders, from successive largest errors on the window -
    euler_errors = nbvar(ws, :euler_errors)
    rk4_errors = nbvar(ws, :rk4_errors)
    step_sizes = nbvar(ws, :step_sizes)
    @test all(step_sizes[1:end-1] ./ step_sizes[2:end] .≈ 2)
    @test all(0.8 .<= log2.(euler_errors[1:end-1] ./ euler_errors[2:end]) .<= 1.2)
    @test all(3.5 .<= log2.(rk4_errors[1:end-1] ./ rk4_errors[2:end]) .<= 4.5)

    # the library reference is accurate enough: tightening both tolerances by 100 moves it far less than the RK4 error -
    long_pulse = nbvar(ws, :long_pulse)
    reference = nbvar(ws, :reference)
    Δt = lab_setting("Δt")
    window_start = long_pulse.stop
    window_end = window_start + lab_setting("window_length")
    x_window = reference.x[:, round(Int, window_start / Δt) + 1]
    @test reference.t[round(Int, window_start / Δt) + 1] ≈ window_start
    set_input!(model, "I", [long_pulse.start, long_pulse.stop], [long_pulse.concentration, long_pulse.baseline])
    rt = lab_setting("relative_tolerance")
    at = lab_setting("absolute_tolerance")
    solver = Base.invokelatest(getproperty, ws, :L15bMethods)
    base = Base.invokelatest(solver.mysolve, balances!, x_window, model; t_start = window_start, t_final = window_end,
        stops = Float64[], Δt_save = step_sizes[end], reltol = rt, abstol = at)
    tight = Base.invokelatest(solver.mysolve, balances!, x_window, model; t_start = window_start, t_final = window_end,
        stops = Float64[], Δt_save = step_sizes[end], reltol = rt / 100, abstol = at / 100)
    @test maximum(abs.(base.x[y, :] .- tight.x[y, :])) < 0.01 * minimum(rk4_errors)
    @test all(model.inputs["I"].times .<= window_start)

    # every setting changed, from the defaults -
    changed = (
        Δt = Δt / 2,
        final_time = lab_setting("final_time") + 4 * Δt,
        Δt_save = 2 * lab_setting("Δt_save"),
        pulse_concentration = 1.25 * lab_setting("pulse_concentration"),
        pulse_start = lab_setting("pulse_start") + Δt,
        pulse_length = lab_setting("pulse_length") + Δt,
        short_pulse_length = lab_setting("short_pulse_length") + lab_setting("Δt_save"),
        relative_tolerance = rt / 10,
        absolute_tolerance = at / 10,
        window_length = lab_setting("window_length") / 2,
        step_counts = 2 .* lab_setting("step_counts"),
    )
    ws_changed = run_lab(settings = changed)

    # a window grid whose step has no exact binary form (codex finding 1) -
    ws_odd = run_lab(settings = (window_length = 32.4, step_counts = [15, 30, 60]))
    @test length(nbvar(ws_odd, :rk4_errors)) == 3

    # Euler and RK4 runs that turn NaN before the middle of a very long pulse: the one-step checks still pass (codex finding 2) -
    ws_nan = run_lab(settings = (Δt = 40.0, pulse_length = 40000.0, final_time = 41000.0))
    @test any(isnan, nbvar(ws_nan, :euler).x)
    @test nbvar(ws_changed, :euler).t[end] == round(changed.final_time / changed.Δt) * changed.Δt

    # a step that divides neither the pulse start nor the save step: the pulse edges move onto its grid -
    Δt_off = 0.7 * Δt
    @test abs(lab_setting("pulse_start") / Δt_off - round(lab_setting("pulse_start") / Δt_off)) > 1e-6
    ws_off = run_lab(settings = (Δt = Δt_off,))
    off_pulse = nbvar(ws_off, :long_pulse)
    off_grid = nbvar(ws_off, :euler).t
    @test any(abs.(off_grid .- off_pulse.start) .< 1e-9)
    @test any(abs.(off_grid .- off_pulse.stop) .< 1e-9)

    # a step above the Euler limit of the memory circuit at its low steady state (Review Focus 1) -
    x₀ = nbvar(ws, :x₀)
    λ = eigvals(jacobian(model, x₀, 0.0))
    limits = Float64[]
    for k in 1:length(λ)
        if real(λ[k]) < 0
            push!(limits, -2 * real(λ[k]) / abs2(λ[k]))
        end
    end
    ws_big = run_lab(settings = (Δt = 1.2 * minimum(limits),), render = true)
    euler_big = nbvar(ws_big, :euler)
    @test !isapprox(euler_big.x[y, :], nbvar(ws_big, :reference).x[y, :]; rtol = 0.1) # false for a NaN run too
end

@meeting "L15b" begin
    @testset "L15b lab" begin
        Base.invokelatest(check_l15b_lab)
    end
end
