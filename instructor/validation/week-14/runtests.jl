using LinearAlgebra
using Test
using TOML

const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
released("L14a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14", "L14a", "Include.jl"))

# -- test helpers: small TOML configs written to a temporary folder ----------------------------- #
const L14A_TMP = mktempdir()

"""Write `text` to a new TOML file in the temporary folder and return its path."""
function write_config(name::String, text::String)::String
    path = joinpath(L14A_TMP, name * ".toml")
    write(path, text)
    return path
end

"""One gene block with a leak state, for building small test networks."""
function gene_block(name::String)::String
    return """
    [[genes]]
    name = "$(name)"
    G = 0.005
    Vmax_X = 0.04
    K_X = 0.005
    Vmax_L = 0.05
    K_L = 0.05

      [[genes.promoter]]
      W = 0.01
      active = true
    """
end

const TEST_PARAMETERS = """
[parameters]
mRNA_half_life = 2.5
protein_half_life = 35.0
doubling_time = 60.0
"""

"""A network of genes with only leak states, listed in the order given."""
function two_gene_config(names::Vector{String})::String
    text = TEST_PARAMETERS
    for name in names
        text = text * gene_block(name)
    end
    return write_config("order-" * join(names, "-"), text)
end

"""One gene whose second promoter state binds the regulator `regulator`."""
function config_with_regulator(regulator::String)::String
    text = TEST_PARAMETERS * gene_block("X") * """
      [[genes.promoter]]
      W = 10.0
      active = true

        [[genes.promoter.bound]]
        regulator = "$(regulator)"
        K = 1.0
        n = 2
    """
    return write_config("regulator-" * regulator, text)
end

"""One gene whose bound regulator names the inducer `inducer`, with no matching input table."""
function config_with_inducer(inducer::String)::String
    text = TEST_PARAMETERS * gene_block("X") * """
      [[genes.promoter]]
      W = 10.0
      active = true

        [[genes.promoter.bound]]
        regulator = "X"
        K = 1.0
        n = 2
        inducer = "$(inducer)"
        inducer_effect = "activates"
    """
    return write_config("inducer-" * inducer, text)
end

@meeting "L14a" begin
    @testset "L14a build from TOML" begin
        model = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
        @test length(model.genes) == 1
        @test model.genes[1].name == "X"
        @test length(model.genes[1].promoter) == 2
        @test model.genes[1].promoter[2].bound[1].regulator == "X"
        @test model.genes[1].promoter[2].bound[1].inducer == "I"
        @test isapprox(model.genes[1].θ_m, log(2) / 2.5)
        @test isapprox(model.μ, log(2) / 60.0)
        @test model.inputs["I"].initial == 1.0
        @test isempty(model.genes[1].translation)

        # gene order follows the [[genes]] array, not alphabetical order
        ordered = build(MyGeneNetworkModel, two_gene_config(["Zeta", "Alpha"]))
        @test [gene.name for gene in ordered.genes] == ["Zeta", "Alpha"]
        @test ordered.index["Alpha"] == 2

        # names that do not exist are rejected
        @test_throws ArgumentError build(MyGeneNetworkModel, config_with_regulator("Q"))
        @test_throws ArgumentError build(MyGeneNetworkModel, config_with_inducer("J"))
    end
end

# -- helpers for the control and balance tests --------------------------------------------------- #

"""Genes X and Y with leak states, and gene Z whose active state binds both X and Y (AND logic)."""
function and_gate_config()::String
    text = TEST_PARAMETERS * gene_block("X") * gene_block("Y") * gene_block("Z") * """
      [[genes.promoter]]
      W = 100.0
      active = true

        [[genes.promoter.bound]]
        regulator = "X"
        K = 1.0
        n = 2

        [[genes.promoter.bound]]
        regulator = "Y"
        K = 1.0
        n = 2
    """
    return write_config("and-gate", text)
end

"""The state vector of the three-gene AND network with the given protein levels and no mRNA."""
function x_with(; pX::Float64, pY::Float64)::Vector{Float64}
    return [0.0, 0.0, 0.0, pX, pY, 0.0]
end

"""The two balances of the positive autoregulation config, written out from the file's numbers."""
function hand_balances(path::String, x::Vector{Float64}, I::Float64)::Vector{Float64}
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    leak = gene["promoter"][1]
    active = gene["promoter"][2]
    b = active["bound"][1]
    θ_m = log(2) / config["parameters"]["mRNA_half_life"]
    θ_p = log(2) / config["parameters"]["protein_half_life"]
    μ = log(2) / config["parameters"]["doubling_time"]
    m = x[1]
    p = x[2]
    f_I = I^b["n_I"] / (b["K_I"]^b["n_I"] + I^b["n_I"])
    available = p * f_I
    f = available^b["n"] / (b["K"]^b["n"] + available^b["n"])
    ubar = (leak["W"] + active["W"] * f) / (1 + leak["W"] + active["W"] * f)
    r_X = gene["Vmax_X"] * gene["G"] / (gene["K_X"] + gene["G"])
    r_L = gene["Vmax_L"] * m / (gene["K_L"] + m)
    return [r_X * ubar - (θ_m + μ) * m, r_L - (θ_p + μ) * p]
end

@meeting "L14a" begin
    @testset "L14a Boltzmann control and balances" begin
        par = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
        levels = [0.0, 0.01, 0.1, 1.0, 10.0, 100.0]
        u = [transcription_control(par, 1, [0.0, p], 0.0) for p in levels]
        @test all(0.0 .<= u .<= 1.0)
        @test issorted(u)                                   # an activator raises the control
        @test u[end] > 10 * u[1]
        W1 = par.genes[1].promoter[1].W
        @test isapprox(u[1], W1 / (1 + W1))                 # no protein: only the leak state
        @test translation_control(par, 1, [0.0, 1.0], 0.0) == 1.0

        # the inducer raises the control at a fixed protein level
        u_at_baseline = transcription_control(par, 1, [0.0, 0.5], 1.0)
        set_input!(par, "I", [0.0], [10.0])
        @test transcription_control(par, 1, [0.0, 0.5], 1.0) > u_at_baseline

        # AND state: both regulators are needed
        andnet = build(MyGeneNetworkModel, and_gate_config())
        neither = transcription_control(andnet, 3, x_with(pX = 0.0, pY = 0.0), 0.0)
        only_x = transcription_control(andnet, 3, x_with(pX = 10.0, pY = 0.0), 0.0)
        both = transcription_control(andnet, 3, x_with(pX = 10.0, pY = 10.0), 0.0)
        @test isapprox(only_x, neither)
        @test both > 10 * only_x

        # schedule edges
        set_input!(par, "I", [5.0, 10.0], [3.0, 1.0])
        @test input_value(par, "I", 4.9) == 1.0             # before the first time: the initial value
        @test input_value(par, "I", 5.0) == 3.0             # at a breakpoint: the new value
        @test input_value(par, "I", 7.0) == 3.0
        @test input_value(par, "I", 12.0) == 1.0
        @test_throws ArgumentError input_value(par, "J", 0.0)

        # balances at a hand-computed state
        path = motif_path("positive-autoregulation")
        fresh_par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        dx = zeros(2)
        balances!(dx, x, fresh_par, 0.0)
        @test isapprox(dx, hand_balances(path, x, 1.0); rtol = 1e-12)
    end
end

# -- helpers for the Jacobian tests -------------------------------------------------------------- #

"""The 2 × 2 Jacobian of the positive autoregulation balances, from the derivative of the Boltzmann control."""
function hand_jacobian(path::String, x::Vector{Float64}, I::Float64)::Matrix{Float64}
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    W1 = gene["promoter"][1]["W"]
    W2 = gene["promoter"][2]["W"]
    b = gene["promoter"][2]["bound"][1]
    θ_m = log(2) / config["parameters"]["mRNA_half_life"]
    θ_p = log(2) / config["parameters"]["protein_half_life"]
    μ = log(2) / config["parameters"]["doubling_time"]
    m = x[1]
    p = x[2]
    s = I^b["n_I"] / (b["K_I"]^b["n_I"] + I^b["n_I"])     # the inducer-bound fraction
    a = s * p                                             # the available activator
    K = b["K"]
    n = b["n"]
    f = a^n / (K^n + a^n)
    df_dp = s * n * K^n * a^(n - 1) / (K^n + a^n)^2       # chain rule through a = s ⋅ p
    du_df = W2 / (1 + W1 + W2 * f)^2                      # quotient rule on (W1 + W2 f)/(1 + W1 + W2 f)
    r_X = gene["Vmax_X"] * gene["G"] / (gene["K_X"] + gene["G"])
    J = zeros(2, 2)
    J[1, 1] = -(θ_m + μ)
    J[1, 2] = r_X * du_df * df_dp
    J[2, 1] = gene["Vmax_L"] * gene["K_L"] / (gene["K_L"] + m)^2
    J[2, 2] = -(θ_p + μ)
    return J
end

@meeting "L14a" begin
    @testset "L14a Jacobians and steady states" begin
        path = motif_path("positive-autoregulation")
        par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        J = jacobian(par, x, 0.0)
        @test isapprox(J, hand_jacobian(path, x, 1.0); rtol = 1e-6)

        B = input_jacobian(par, x, 0.0, "I")
        @test B[2] == 0.0
        @test B[1] > 0.0
        @test input_value(par, "I", 0.0) == 1.0          # the caller's model is not changed

        text = equations(par)
        @test occursin("dm_X/dt", text)
        @test occursin("dp_X/dt", text)
        @test occursin("ū_X = (0.005 + 10.0 f₁) / (1 + 0.005 + 10.0 f₁)", text)

        # a steady state found by Newton's method has zero balances
        result = steady_state(par; guess = [0.0005, 0.01])
        @test result.converged
        dx = zeros(2)
        balances!(dx, result.x, par, 0.0)
        @test norm(dx) < 1e-10

        # running out of iterations reports failure instead of throwing
        bad = steady_state(par; guess = [1.0e6, 1.0e6], maxiter = 1)
        @test bad.converged == false
        @test bad.iterations == 1
    end
end

@meeting "L14a" begin
    @testset "L14a discretization and eigenvalue algorithms" begin
        # the bilinear recursion approaches the exact solution for a constant input u = 1
        A = [-1.0 0.5; -0.5 -2.0]
        B = [1.0, 0.0]
        x0 = [1.0, -1.0]
        T = 4.0
        exact = exp(A * T) * x0 + A \ ((exp(A * T) - I) * B)
        errors = Float64[]
        for Δt in [0.1, 0.05]
            Ā, B̄ = discretize(A, B; Δt = Δt)
            x = copy(x0)
            for k in 1:round(Int, T / Δt)
                x = Ā * x + B̄ * 1.0
            end
            push!(errors, norm(x - exact))
        end
        @test errors[2] < errors[1] / 3                           # second order in Δt
        @test errors[2] < 1e-3

        # B̄ keeps the shape of B
        _, B̄column = discretize(A, B; Δt = 0.1)
        @test B̄column isa Vector{Float64}
        _, B̄matrix = discretize(A, reshape(B, 2, 1); Δt = 0.1)
        @test size(B̄matrix) == (2, 1)

        # a stable A stays stable at a large step, and an unstable A stays unstable
        Ā, _ = discretize(A, B; Δt = 10.0)
        @test all(abs.(eigvals(Ā)) .< 1.0)
        Āunstable, _ = discretize([0.2 0.0; 0.0 -1.0], B; Δt = 0.5)
        @test maximum(abs.(eigvals(Āunstable))) > 1.0

        # QR iteration: eigenvalues and eigenvector residuals agree with eigen
        S = [4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0]
        λ, V = qriteration(S; maxiter = 200)
        @test isapprox(sort(λ), sort(eigvals(Symmetric(S))); atol = 1e-6)
        for i in 1:3
            @test isapprox(norm(V[i]), 1.0; atol = 1e-12)
            @test norm(S * V[i] - λ[i] * V[i]) < 1e-5
        end

        # the matrix from the old docstring, where the old eigenvector step failed
        D = [2.0 1.0 0.0; 1.0 3.0 0.0; 0.0 0.0 10.0]
        λD, VD = qriteration(D; maxiter = 200)
        for i in 1:3
            @test all(isfinite.(VD[i]))
            @test norm(D * VD[i] - λD[i] * VD[i]) < 1e-5
        end

        # power iteration: the dominant eigenvalue
        result = poweriteration(S, ones(3); maxiter = 500, ϵ = 1e-14)
        @test isapprox(result.value, maximum(eigvals(Symmetric(S))); atol = 1e-6)
        @test norm(S * result.vector - result.value * result.vector) < 1e-5
    end
end

# -- helpers for the motif tests ----------------------------------------------------------------- #

"""
The steady states of a one-gene network. A steady state has p = r_L(m) w / (θ_p + μ) with
m = r_X ū(p) / (θ_m + μ). We scan p on a log grid for sign changes of that condition, then refine
each bracket with steady_state(...).
"""
function par_steady_states(model::MyGeneNetworkModel; t::Float64 = 0.0)::Vector{Vector{Float64}}
    gene = model.genes[1]
    r_X = gene.Vmax_X * gene.G / (gene.K_X + gene.G)
    a = gene.θ_m + model.μ
    b = gene.θ_p + model.μ
    grid = 10.0 .^ range(-5, 1; length = 4001)
    g = Float64[]
    for p in grid
        m = r_X * transcription_control(model, 1, [0.0, p], t) / a
        r_L = gene.Vmax_L * m / (gene.K_L + m)
        push!(g, r_L / b - p)
    end
    states = Vector{Vector{Float64}}()
    for k in 1:(length(grid) - 1)
        if sign(g[k]) != sign(g[k + 1])
            p = grid[k]
            m = r_X * transcription_control(model, 1, [0.0, p], t) / a
            result = steady_state(model; guess = [m, p], t = t)
            push!(states, result.x)
        end
    end
    return states
end

"""The protein level at the end of a pulse experiment: inducer `level` from `t_on` to `t_off`, then back to baseline."""
function final_protein(model::MyGeneNetworkModel, x0::Vector{Float64}, pulse::NamedTuple; T::Float64 = 1500.0)::Float64
    trial = deepcopy(model)
    baseline = trial.inputs["I"].initial
    set_input!(trial, "I", [pulse.t_on, pulse.t_off], [pulse.level, baseline])
    problem = ODEProblem(balances!, x0, (0.0, T), trial)
    solution = OrdinaryDiffEq.solve(problem, Tsit5(); tstops = [pulse.t_on, pulse.t_off], reltol = 1e-8, abstol = 1e-12)
    return solution.u[end][2]
end

@meeting "L14a" begin
    @testset "L14a motif eigenvalues and pulses" begin
        par = build(MyGeneNetworkModel, motif_path("positive-autoregulation"))
        states = par_steady_states(par)
        @test length(states) == 3
        λ = [eigvals(jacobian(par, s, 0.0)) for s in states]
        @test all(real.(λ[1]) .< 0.0)
        @test all(real.(λ[3]) .< 0.0)
        @test count(real.(λ[2]) .> 0.0) == 1

        nar = build(MyGeneNetworkModel, motif_path("negative-autoregulation"))
        nar_state = steady_state(nar; guess = [0.01, 0.1])
        @test nar_state.converged
        λn = eigvals(jacobian(nar, nar_state.x, 0.0))
        @test all(imag.(λn) .== 0.0)
        @test all(real.(λn) .< 0.0)

        nfl = build(MyGeneNetworkModel, motif_path("negative-feedback-loop"))
        nfl_state = steady_state(nfl; guess = fill(0.05, 4))
        @test nfl_state.converged
        λf = eigvals(jacobian(nfl, nfl_state.x, 0.0))
        @test any(abs.(imag.(λf)) .> 1e-3)
        @test all(real.(λf) .< 0.0)

        # inducer pulses from the low state
        small_pulse = (t_on = 10.0, t_off = 70.0, level = 2.0)
        large_pulse = (t_on = 10.0, t_off = 70.0, level = 20.0)
        saddle_protein = states[2][2]
        @test final_protein(par, states[1], small_pulse) < saddle_protein
        @test isapprox(final_protein(par, states[1], small_pulse), states[1][2]; rtol = 1e-3)
        @test final_protein(par, states[1], large_pulse) > saddle_protein
        @test isapprox(final_protein(par, states[1], large_pulse), states[3][2]; rtol = 1e-3)
    end
end

# power iteration edge cases, from the codex review of 2026-11-19 -
"""
    captured_poweriteration(A, v; maxiter)

Run `poweriteration` with its printed message captured, and return the result and the message.
"""
function captured_poweriteration(A::Matrix{Float64}, v::Vector{Float64}; maxiter::Int = 100)
    (path, io) = mktemp();
    result = redirect_stdout(io) do
        poweriteration(A, v; maxiter = maxiter)
    end
    close(io);
    return (result, read(path, String));
end

@testset "L14a power iteration edge cases" begin

    # the returned vector is the newest iterate, and the eigenvalue estimate comes from that vector -
    A = [5.0 0.0; 0.0 1.0];
    (result, message) = captured_poweriteration(A, [1.0, 1.0]; maxiter = 1);
    newest = [5.0, 1.0] / sqrt(26.0);
    @test isapprox(result.vector, newest; atol = 1e-12)
    @test isapprox(result.value, dot(A * newest, newest); atol = 1e-12)

    # a negative dominant eigenvalue flips the sign of the vector at each iteration; that still converges -
    A = [-5.0 0.0; 0.0 1.0];
    (result, message) = captured_poweriteration(A, [1.0, 1.0]; maxiter = 100);
    @test occursin("Converged", message)
    @test isapprox(result.value, -5.0; atol = 1e-3)
    @test norm(A * result.vector - result.value * result.vector) < 1e-2

    # a zero starting vector, or a starting vector that A sends to zero, is an error, not NaN -
    @test_throws ArgumentError poweriteration([1.0 0.0; 0.0 1.0], [0.0, 0.0])
    @test_throws ArgumentError poweriteration([1.0 0.0; 0.0 0.0], [0.0, 1.0])
end

# -- helpers for the final-review tests of 2026-11-19 -------------------------------------------- #

"""Two [[genes]] entries with the same name, which the builder must reject."""
function duplicate_gene_config()::String
    return write_config("duplicate-genes", TEST_PARAMETERS * gene_block("X") * gene_block("X"))
end

"""One gene X activated by its own protein through the inducer I, with I = 0 at baseline and n = 1."""
function zero_inducer_config(n_I::Float64)::String
    text = TEST_PARAMETERS * gene_block("X") * """
      [[genes.promoter]]
      W = 10.0
      active = true

        [[genes.promoter.bound]]
        regulator = "X"
        K = 0.5
        n = 1
        inducer = "I"
        inducer_effect = "activates"
        K_I = 2.0
        n_I = $(n_I)

    [inputs.I]
    initial = 0.0
    """
    return write_config("zero-inducer-$(n_I)", text)
end

"""One gene X whose repressor state is inactivated by the inducer I, and whose mRNA has two translation states."""
function translation_inactivates_config()::String
    text = TEST_PARAMETERS * gene_block("X") * """
      [[genes.promoter]]
      W = 5.0
      active = false

        [[genes.promoter.bound]]
        regulator = "X"
        K = 0.5
        n = 2
        inducer = "I"
        inducer_effect = "inactivates"
        K_I = 2.0
        n_I = 1

      [[genes.translation]]
      W = 2.0
      active = true

      [[genes.translation]]
      W = 3.0
      active = false

        [[genes.translation.bound]]
        regulator = "X"
        K = 0.4
        n = 1

    [inputs.I]
    initial = 1.5
    """
    return write_config("translation-inactivates", text)
end

"""The two balances of the translation and inactivation config, written out by hand at the inducer level I."""
function hand_balances_translation(x::Vector{Float64}, I::Float64)::Vector{Float64}
    θ_m = log(2) / 2.5                         # the mRNA degradation constant (1/min)
    θ_p = log(2) / 35.0                        # the protein degradation constant (1/min)
    μ = log(2) / 60.0                          # the specific growth rate (1/min)
    m = x[1]
    p = x[2]
    f_I = I / (2.0 + I)                        # the fraction of X that carries the inducer
    a = p * (1.0 - f_I)                        # the inducer inactivates X, so only X without it binds
    f_repressor = a^2 / (0.5^2 + a^2)          # the bound fraction of the repressor state
    ubar = 0.01 / (1.0 + 0.01 + 5.0 * f_repressor)   # only the leak state is active
    g = p / (0.4 + p)                          # the bound fraction of X on the mRNA
    w = 2.0 / (1.0 + 2.0 + 3.0 * g)            # only the free translation state is active
    r_X = 0.04 * 0.005 / (0.005 + 0.005)       # the transcription rate (µM/min)
    r_L = 0.05 * m / (0.05 + m)                # the translation rate (µM/min)
    return [r_X * ubar - (θ_m + μ) * m, r_L * w - (θ_p + μ) * p]
end

"""The derivative of the positive autoregulation mRNA balance with respect to the inducer, by the chain rule."""
function hand_input_derivative(path::String, x::Vector{Float64}, I::Float64)::Float64
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    W1 = gene["promoter"][1]["W"]
    W2 = gene["promoter"][2]["W"]
    b = gene["promoter"][2]["bound"][1]
    p = x[2]
    s = I^b["n_I"] / (b["K_I"]^b["n_I"] + I^b["n_I"])                                 # the inducer-bound fraction
    ds_dI = b["n_I"] * b["K_I"]^b["n_I"] * I^(b["n_I"] - 1) / (b["K_I"]^b["n_I"] + I^b["n_I"])^2
    a = s * p                                                                         # the available activator
    f = a^b["n"] / (b["K"]^b["n"] + a^b["n"])
    df_da = b["n"] * b["K"]^b["n"] * a^(b["n"] - 1) / (b["K"]^b["n"] + a^b["n"])^2
    du_df = W2 / (1 + W1 + W2 * f)^2
    r_X = gene["Vmax_X"] * gene["G"] / (gene["K_X"] + gene["G"])
    return r_X * du_df * df_da * p * ds_dI
end

@meeting "L14a" begin
    @testset "L14a final review: duplicates, zero inducer, translation, inactivation, B" begin

        # two genes with the same name are rejected -
        @test_throws ArgumentError build(MyGeneNetworkModel, duplicate_gene_config())

        # an inducer that inactivates its regulator, and translation states, match the hand balances -
        model = build(MyGeneNetworkModel, translation_inactivates_config())
        for x in [[0.002, 0.3], [0.01, 1.2]]
            dx = zeros(2)
            balances!(dx, x, model, 0.0)
            @test isapprox(dx, hand_balances_translation(x, 1.5); rtol = 1e-12)
        end

        # the input matrix has the size of the analytic derivative, not only its sign -
        path = motif_path("positive-autoregulation")
        par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        B = input_jacobian(par, x, 0.0, "I")
        @test isapprox(B[1], hand_input_derivative(path, x, 1.0); rtol = 1e-5)

        # a zero baseline inducer: the derivative is one-sided, matches the analytic value, and never raises -
        zero_model = build(MyGeneNetworkModel, zero_inducer_config(1.0))
        B = input_jacobian(zero_model, x, 0.0, "I")
        expected = 0.02 * 10.0 / (1.0 + 0.01)^2 * (1.0 / 0.5) * (x[2] / 2.0)   # dū/df ⋅ df/da ⋅ da/dI at I = 0
        @test isapprox(B[1], expected; rtol = 1e-4)
        fractional = build(MyGeneNetworkModel, zero_inducer_config(1.5))
        @test all(isfinite.(input_jacobian(fractional, x, 0.0, "I")))
    end
end
