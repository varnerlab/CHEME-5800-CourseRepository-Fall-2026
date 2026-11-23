using LinearAlgebra
using Test
using TOML
import JSON  # reads the example notebook whose cells the suite runs
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells

const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
released("L14a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-14", "L14a", "Include.jl"))

# -- test helpers: small TOML configs written to a temporary folder ----------------------------- #
const L14A_TMP = mktempdir()
const R_GAS = 8.314462618e-3 # the gas constant (kJ/mol/K)
const TEST_T = 310.15        # the temperature of the test configs (K)

"""The Gibbs energy (kJ/mol) that gives the weight `W` at the test temperature: ΔG = −RT ln W."""
dG_for(W::Float64)::Float64 = -R_GAS * TEST_T * log(W)

"""The weight W = exp(−ΔG/RT) of a promoter or translation state of a parsed config file."""
config_weight(config::Dict, state::Dict)::Float64 = exp(-state["dG"] / (R_GAS * config["parameters"]["temperature"]))

"""The baseline inducer concentration of a parsed config file (µM)."""
config_baseline(config::Dict)::Float64 = config["inputs"]["I"]["initial"]

"""The index of the promoter state of the first gene with RNA polymerase bound alone: active, and no bound regulator."""
function leak_state_index(config::Dict)::Int
    promoter = config["genes"][1]["promoter"]
    for k in 1:length(promoter)
        if promoter[k]["active"] && !haskey(promoter[k], "bound")
            return k
        end
    end
    error("the first gene has no state with RNA polymerase bound alone")
end

const AVOGADRO = 6.02214076e23 # Avogadro's number (1/mol)

"""
The kinetic constants of a parsed config, computed by hand as CHEME 5450 does (L6b and L8c): the
RNA polymerase and ribosome levels, and for each gene its level G, Vmax_X, τ_X, K_X, Vmax_L, τ_L, K_L.
"""
function hand_constants(config::Dict)
    P = config["parameters"]
    per_copy = 1e9 / (AVOGADRO * P["mass_of_single_cell"])                          # nmol/gDW of one copy per cell
    per_µM = 1e-6 * P["volume_of_single_cell"] / P["mass_of_single_cell"] * 1e9     # nmol/gDW of 1 µM in the cell
    R_X = P["copies_of_rnap_per_cell"] * per_copy
    R_L = P["copies_of_ribosome_per_cell"] * per_copy
    genes = []
    for gene in config["genes"]
        l_G = gene["length_of_gene_in_nt"]
        l_P = gene["length_of_protein_in_aa"]
        push!(genes, (G = gene["gene_copy_number"] * per_copy,
            Vmax_X = R_X * 60 * P["transcription_elongation_rate"] / l_G,
            τ_X = P["transcription_elongation_rate"] / l_G * P["transcription_initiation_time_constant"],
            K_X = P["transcription_saturation_constant"] * per_µM,
            Vmax_L = P["average_polysome_number"] * R_L * 60 * P["translation_elongation_rate"] / l_P,
            τ_L = P["translation_elongation_rate"] / l_P * P["translation_initiation_time_constant"],
            K_L = P["translation_saturation_factor"] * P["transcription_saturation_constant"] * per_µM))
    end
    return (R_X = R_X, R_L = R_L, genes = genes)
end

"""The transcription kinetic limit r_X of gene `j` from the hand constants `c`, with the RNA polymerase competition O_X."""
function hand_r_X(c, j::Int)::Float64
    g = c.genes[j]
    O = 0.0
    for i in 1:length(c.genes)
        if i != j
            h = c.genes[i]
            O += (g.K_X * g.τ_X) / (h.K_X * h.τ_X) * (1 + h.τ_X) * h.G
        end
    end
    return g.Vmax_X * g.G / (g.τ_X * g.K_X + (1 + g.τ_X) * g.G + O)
end

"""The translation kinetic limit r_L of gene `j` from the hand constants `c` and the mRNA levels `m`, with the ribosome competition O_L."""
function hand_r_L(c, j::Int, m::Vector{Float64})::Float64
    g = c.genes[j]
    O = 0.0
    for i in 1:length(c.genes)
        if i != j
            h = c.genes[i]
            O += (g.K_L * g.τ_L) / (h.K_L * h.τ_L) * (1 + h.τ_L) * m[i]
        end
    end
    return g.Vmax_L * m[j] / (g.τ_L * g.K_L + (1 + g.τ_L) * m[j] + O)
end

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
    gene_copy_number = 1.0
    length_of_gene_in_nt = 1000.0
    length_of_protein_in_aa = 330.0

      [[genes.promoter]]
      dG = $(dG_for(0.01))
      active = true
    """
end

const TEST_PARAMETERS_NO_T = """
[parameters]
mass_of_single_cell = 2.8e-13
volume_of_single_cell = 6.7e-16
copies_of_rnap_per_cell = 4600.0
transcription_elongation_rate = 60.0
transcription_initiation_time_constant = 42.0
transcription_saturation_constant = 0.3
copies_of_ribosome_per_cell = 50000.0
translation_elongation_rate = 16.5
translation_initiation_time_constant = 15.0
translation_saturation_factor = 190.0
average_polysome_number = 4.0
mRNA_half_life = 5.0
protein_half_life = 4200.0
doubling_time = 60.0
"""
const TEST_PARAMETERS = TEST_PARAMETERS_NO_T * "temperature = $(TEST_T)\n"

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
      dG = $(dG_for(10.0))
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
      dG = $(dG_for(10.0))
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
        path = motif_path("positive-autoregulation")
        config = TOML.parsefile(path)
        gene = config["genes"][1]
        model = build(MyGeneNetworkModel, path)
        @test length(model.genes) == length(config["genes"])
        @test model.genes[1].name == gene["name"]
        @test length(model.genes[1].promoter) == length(gene["promoter"])
        @test model.genes[1].promoter[2].bound[1].regulator == gene["promoter"][2]["bound"][1]["regulator"]
        @test model.genes[1].promoter[2].bound[1].inducer == gene["promoter"][2]["bound"][1]["inducer"]
        @test isapprox(model.genes[1].θ_m, log(2) / config["parameters"]["mRNA_half_life"])
        @test isapprox(model.genes[1].θ_p, log(2) / config["parameters"]["protein_half_life"])
        @test isapprox(model.μ, log(2) / config["parameters"]["doubling_time"])
        @test model.inputs["I"].initial == config_baseline(config)
        @test length(model.genes[1].translation) == length(get(gene, "translation", []))

        # the kinetic limits follow CHEME 5450: every constant the builder computes matches the hand formula from the file
        hand = hand_constants(config)
        @test isapprox(model.R_X, hand.R_X; rtol = 1e-12)
        @test isapprox(model.R_L, hand.R_L; rtol = 1e-12)
        for field in (:G, :Vmax_X, :τ_X, :K_X, :Vmax_L, :τ_L, :K_L)
            @test isapprox(getfield(model.genes[1], field), getfield(hand.genes[1], field); rtol = 1e-12)
        end
        @test isapprox(transcription_rate(model, 1), hand_r_X(hand, 1); rtol = 1e-12)

        # two genes compete for RNA polymerase and ribosomes: the rates match the hand formulas with O_X and O_L,
        # and each rate is below the rate of the same gene alone
        two_text = TEST_PARAMETERS * gene_block("P") * replace(gene_block("Q"),   # Q has its own lengths, so the competition ratios are not 1
            "length_of_gene_in_nt = 1000.0" => "length_of_gene_in_nt = 1500.0",
            "length_of_protein_in_aa = 330.0" => "length_of_protein_in_aa = 500.0")
        two_path = write_config("competition", two_text)
        two = build(MyGeneNetworkModel, two_path)
        two_hand = hand_constants(TOML.parsefile(two_path))
        m_test = [0.01, 0.03]                                 # mRNA levels of P and Q in the test (nmol/gDW)
        x_test = vcat(m_test, [1.0, 1.0])
        for j in 1:2
            @test isapprox(transcription_rate(two, j), hand_r_X(two_hand, j); rtol = 1e-12)
            @test isapprox(translation_rate(two, j, x_test), hand_r_L(two_hand, j, m_test); rtol = 1e-12)
            g = two_hand.genes[j]
            @test transcription_rate(two, j) < g.Vmax_X * g.G / (g.τ_X * g.K_X + (1 + g.τ_X) * g.G)   # the same gene alone, O_X = 0
        end

        # a missing or nonpositive value of the cell, the polymerase, the ribosomes, or a gene is rejected
        for key in ["mass_of_single_cell", "volume_of_single_cell", "copies_of_rnap_per_cell", "transcription_elongation_rate",
                "transcription_initiation_time_constant", "transcription_saturation_constant", "copies_of_ribosome_per_cell",
                "translation_elongation_rate", "translation_initiation_time_constant", "translation_saturation_factor",
                "average_polysome_number"]
            missing_text = replace(TEST_PARAMETERS, Regex("(?m)^" * key * " = .*\\n") => "")
            @test_throws ArgumentError build(MyGeneNetworkModel, write_config("missing-" * key, missing_text * gene_block("X")))
            zero_text = replace(TEST_PARAMETERS, Regex("(?m)^" * key * " = .*\$") => key * " = 0.0")
            @test_throws ArgumentError build(MyGeneNetworkModel, write_config("zero-" * key, zero_text * gene_block("X")))
        end
        for key in ["gene_copy_number", "length_of_gene_in_nt", "length_of_protein_in_aa"]
            zero_gene = replace(gene_block("X"), Regex("(?m)^(\\s*)" * key * " = .*\$") => SubstitutionString("\\1" * key * " = 0.0"))
            @test_throws ArgumentError build(MyGeneNetworkModel, write_config("zero-gene-" * key, TEST_PARAMETERS * zero_gene))
        end

        # gene order follows the [[genes]] array, not alphabetical order
        names = ["Zeta", "Alpha"]
        ordered_path = two_gene_config(names)
        ordered = build(MyGeneNetworkModel, ordered_path)
        @test [gene.name for gene in ordered.genes] == names
        @test ordered.index["Alpha"] == findfirst(==("Alpha"), names)

        # names that do not exist are rejected
        @test_throws ArgumentError build(MyGeneNetworkModel, config_with_regulator("Q"))
        @test_throws ArgumentError build(MyGeneNetworkModel, config_with_inducer("J"))

        # each weight is the Boltzmann factor of the state's Gibbs energy, W = exp(−ΔG/RT)
        for k in 1:length(gene["promoter"])
            @test isapprox(model.genes[1].promoter[k].W, config_weight(config, gene["promoter"][k]); rtol = 1e-12)
        end
        ordered_config = TOML.parsefile(ordered_path)
        @test isapprox(ordered.genes[1].promoter[1].W, config_weight(ordered_config, ordered_config["genes"][1]["promoter"][1]); rtol = 1e-12)

        # the same Gibbs energy at another temperature gives another weight
        hot_path = write_config("hot", replace(TEST_PARAMETERS, "temperature = $(TEST_T)" => "temperature = $(2 * TEST_T)") * gene_block("X"))
        hot_config = TOML.parsefile(hot_path)
        hot = build(MyGeneNetworkModel, hot_path)
        @test isapprox(hot.genes[1].promoter[1].W, config_weight(hot_config, hot_config["genes"][1]["promoter"][1]); rtol = 1e-12)
        @test hot.genes[1].promoter[1].W != ordered.genes[1].promoter[1].W

        # a config without a temperature, or a state with a weight W instead of a Gibbs energy dG, is rejected
        @test_throws ArgumentError build(MyGeneNetworkModel, write_config("no-temperature", TEST_PARAMETERS_NO_T * gene_block("X")))
        @test_throws ArgumentError build(MyGeneNetworkModel, write_config("zero-temperature", TEST_PARAMETERS_NO_T * "temperature = 0.0\n" * gene_block("X")))
        @test_throws ArgumentError build(MyGeneNetworkModel, write_config("infinite-temperature", TEST_PARAMETERS_NO_T * "temperature = inf\n" * gene_block("X")))
        @test_throws ArgumentError build(MyGeneNetworkModel, write_config("weight-not-energy", TEST_PARAMETERS * replace(gene_block("X"), "dG = $(dG_for(0.01))" => "W = 0.01")))
    end
end

# -- helpers for the control and balance tests --------------------------------------------------- #

"""Genes X and Y with leak states, and gene Z whose active state binds both X and Y (AND logic)."""
function and_gate_config()::String
    text = TEST_PARAMETERS * gene_block("X") * gene_block("Y") * gene_block("Z") * """
      [[genes.promoter]]
      dG = $(dG_for(100.0))
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
    W_leak = config_weight(config, leak)
    W_active = config_weight(config, active)
    ubar = (W_leak + W_active * f) / (1 + W_leak + W_active * f)
    c = hand_constants(config)
    r_X = hand_r_X(c, 1)
    r_L = hand_r_L(c, 1, [m])
    return [r_X * ubar - (θ_m + μ) * m, r_L - (θ_p + μ) * p]
end

@meeting "L14a" begin
    @testset "L14a Boltzmann control and balances" begin
        path = motif_path("positive-autoregulation")
        config = TOML.parsefile(path)
        baseline = config_baseline(config)
        bound = config["genes"][1]["promoter"][2]["bound"][1]
        par = build(MyGeneNetworkModel, path)
        levels = bound["K"] .* [0.0, 0.1, 1.0, 10.0, 100.0, 1000.0]   # protein levels from zero to far above the half-binding level
        u = [transcription_control(par, 1, [0.0, p], 0.0) for p in levels]
        @test all(0.0 .<= u .<= 1.0)
        @test issorted(u)                                   # an activator raises the control
        @test u[end] > u[1]
        W1 = par.genes[1].promoter[1].W
        @test isapprox(u[1], W1 / (1 + W1))                 # no protein: only the leak state
        @test translation_control(par, 1, [0.0, bound["K"]], 0.0) == 1.0   # no translation states: w = 1 by definition

        # the inducer raises the control at a fixed protein level
        u_at_baseline = transcription_control(par, 1, [0.0, bound["K"]], 0.0)
        set_input!(par, "I", [0.0], [baseline + bound["K_I"]])
        @test transcription_control(par, 1, [0.0, bound["K"]], 0.0) > u_at_baseline

        # AND state: both regulators are needed, and the control matches the weights of the file
        and_path = and_gate_config()
        and_config = TOML.parsefile(and_path)
        andnet = build(MyGeneNetworkModel, and_path)
        p_high = 10.0                                       # a protein level of X and Y in the test (nmol/gDW)
        neither = transcription_control(andnet, 3, x_with(pX = 0.0, pY = 0.0), 0.0)
        only_x = transcription_control(andnet, 3, x_with(pX = p_high, pY = 0.0), 0.0)
        both = transcription_control(andnet, 3, x_with(pX = p_high, pY = p_high), 0.0)
        @test isapprox(only_x, neither)
        z = and_config["genes"][3]
        W_leak = config_weight(and_config, z["promoter"][1])
        W_and = config_weight(and_config, z["promoter"][2])
        f = prod([p_high^b["n"] / (b["K"]^b["n"] + p_high^b["n"]) for b in z["promoter"][2]["bound"]])
        @test isapprox(both, (W_leak + W_and * f) / (1 + W_leak + W_and * f); rtol = 1e-12)

        # schedule edges
        schedule_times = [5.0, 10.0]                        # the times at which the test schedule changes the inducer (min)
        schedule_values = [baseline + bound["K_I"], baseline]   # the inducer after each time (µM)
        set_input!(par, "I", schedule_times, schedule_values)
        @test input_value(par, "I", schedule_times[1] / 2) == baseline                              # before the first time: the baseline
        @test input_value(par, "I", schedule_times[1]) == schedule_values[1]                        # at a breakpoint: the new value
        @test input_value(par, "I", (schedule_times[1] + schedule_times[2]) / 2) == schedule_values[1]
        @test input_value(par, "I", 2 * schedule_times[2]) == schedule_values[2]
        @test_throws ArgumentError input_value(par, "J", 0.0)

        # balances at a hand-computed state
        fresh_par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        dx = zeros(2)
        balances!(dx, x, fresh_par, 0.0)
        @test isapprox(dx, hand_balances(path, x, baseline); rtol = 1e-12)
    end
end

# -- helpers for the Jacobian tests -------------------------------------------------------------- #

"""The 2 × 2 Jacobian of the positive autoregulation balances, from the derivative of the Boltzmann control."""
function hand_jacobian(path::String, x::Vector{Float64}, I::Float64)::Matrix{Float64}
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    W1 = config_weight(config, gene["promoter"][1])
    W2 = config_weight(config, gene["promoter"][2])
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
    c = hand_constants(config)
    r_X = hand_r_X(c, 1)
    g = c.genes[1]
    J = zeros(2, 2)
    J[1, 1] = -(θ_m + μ)
    J[1, 2] = r_X * du_df * df_dp
    J[2, 1] = g.Vmax_L * g.τ_L * g.K_L / (g.τ_L * g.K_L + (1 + g.τ_L) * m)^2   # the derivative of r_L with respect to m
    J[2, 2] = -(θ_p + μ)
    return J
end

@meeting "L14a" begin
    @testset "L14a Jacobians and steady states" begin
        path = motif_path("positive-autoregulation")
        config = TOML.parsefile(path)
        baseline = config_baseline(config)
        name = config["genes"][1]["name"]
        par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        J = jacobian(par, x, 0.0)
        @test isapprox(J, hand_jacobian(path, x, baseline); rtol = 1e-6)

        B = input_jacobian(par, x, 0.0, "I")
        @test B[2] == 0.0                                    # the inducer enters only the mRNA balance
        @test B[1] > 0.0
        @test input_value(par, "I", 0.0) == baseline         # the caller's model is not changed

        # the printer shows the weights from dG, rounded to 4 significant digits, in both places
        text = equations(par)
        @test occursin("dm_$(name)/dt", text)
        @test occursin("dp_$(name)/dt", text)
        printed = match(Regex("ū_$(name) = \\(([0-9.e+-]+) \\+ ([0-9.e+-]+) f₁\\) / \\(1 \\+ \\1 \\+ \\2 f₁\\)"), text)
        @test printed !== nothing
        if printed !== nothing
            @test parse(Float64, printed.captures[1]) == round(par.genes[1].promoter[1].W; sigdigits = 4)
            @test parse(Float64, printed.captures[2]) == round(par.genes[1].promoter[2].W; sigdigits = 4)
        end

        # a steady state found by Newton's method, from near the state that DynamicSS reaches, has zero balances
        settled = SteadyStateDiffEq.solve(SteadyStateProblem(balances!, zeros(2), par), DynamicSS(Tsit5()))
        result = steady_state(par; guess = 1.1 .* Vector(settled.u))
        @test result.converged
        dx = zeros(2)
        balances!(dx, result.x, par, 0.0)
        @test norm(dx) < 1e-10

        # running out of iterations reports failure instead of throwing
        few = 1                                              # the number of Newton iterations allowed
        bad = steady_state(par; guess = [1.0e6, 1.0e6], maxiter = few)
        @test bad.converged == false
        @test bad.iterations == few
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
        step_sizes = [0.1, 0.05]
        for Δt in step_sizes
            Ā, B̄ = discretize(A, B; Δt = Δt)
            x = copy(x0)
            for k in 1:round(Int, T / Δt)
                x = Ā * x + B̄ * 1.0
            end
            push!(errors, norm(x - exact))
        end
        @test isapprox(errors[1] / errors[2], (step_sizes[1] / step_sizes[2])^2; rtol = 0.1)   # second order in Δt

        # B̄ keeps the shape of B
        _, B̄column = discretize(A, B; Δt = 0.1)
        @test B̄column isa Vector{Float64}
        Bmatrix = reshape(B, length(B), 1)
        _, B̄matrix = discretize(A, Bmatrix; Δt = 0.1)
        @test size(B̄matrix) == size(Bmatrix)

        # the method flag: the default is the bilinear discretization, and the zero-order hold matches the
        # exponential of the augmented matrix [A B; 0 0], solves the model exactly for a constant input,
        # keeps the shape of B, and stops with an ArgumentError for a singular A or an unknown method
        @test discretize(A, B; Δt = step_sizes[1]) == discretize(A, B; Δt = step_sizes[1], method = :bilinear)
        n = size(A, 1)
        for Δt in step_sizes
            Āzoh, B̄zoh = discretize(A, B; Δt = Δt, method = :zoh)
            augmented = exp([A B; zeros(1, n + 1)] * Δt)
            @test isapprox(Āzoh, augmented[1:n, 1:n]; rtol = 1e-12)
            @test isapprox(B̄zoh, augmented[1:n, n + 1]; rtol = 1e-12)
            x = copy(x0)
            for k in 1:round(Int, T / Δt)
                x = Āzoh * x + B̄zoh * 1.0
            end
            @test norm(x - exact) <= sqrt(eps()) * norm(exact)
        end
        B2 = hcat(B, reverse(B))                             # two inputs, one in each state
        _, B̄zoh2 = discretize(A, B2; Δt = step_sizes[1], method = :zoh)
        augmented2 = exp([A B2; zeros(size(B2, 2), n + size(B2, 2))] * step_sizes[1])
        @test size(B̄zoh2) == size(B2)
        @test isapprox(B̄zoh2, augmented2[1:n, (n + 1):end]; rtol = 1e-12)
        singular = [0.0 0.0; 0.0 -1.0]
        @test_throws ArgumentError discretize(singular, B; Δt = step_sizes[1], method = :zoh)
        @test_throws ArgumentError discretize(A, B; Δt = step_sizes[1], method = :unknown)

        # a stable A stays stable at a large step, and an unstable A stays unstable
        Ā, _ = discretize(A, B; Δt = 10.0)
        @test all(abs.(eigvals(Ā)) .< 1.0)
        Āunstable, _ = discretize([0.2 0.0; 0.0 -1.0], B; Δt = 0.5)
        @test maximum(abs.(eigvals(Āunstable))) > 1.0

        # QR iteration: eigenvalues and eigenvector residuals agree with eigen
        S = [4.0 1.0 0.0; 1.0 3.0 1.0; 0.0 1.0 2.0]
        λ, V = qriteration(S; maxiter = 200)
        @test isapprox(sort(λ), sort(eigvals(Symmetric(S))); atol = 1e-6)
        for i in 1:length(λ)
            @test isapprox(norm(V[i]), 1.0; atol = 1e-12)
            @test norm(S * V[i] - λ[i] * V[i]) < 1e-5
        end

        # the matrix from the old docstring, where the old eigenvector step failed
        D = [2.0 1.0 0.0; 1.0 3.0 0.0; 0.0 0.0 10.0]
        λD, VD = qriteration(D; maxiter = 200)
        for i in 1:length(λD)
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
    r_X = transcription_rate(model, 1)
    a = gene.θ_m + model.μ
    b = gene.θ_p + model.μ
    p_max = translation_rate(model, 1, [r_X / a, 0.0]) / b  # the largest protein level the balances allow, since ū ≤ 1 and w ≤ 1
    grid = p_max .* 10.0 .^ range(-8, 0; length = 8001)  # protein levels up to p_max, on a log grid
    g = Float64[]
    for p in grid
        m = r_X * transcription_control(model, 1, [0.0, p], t) / a
        r_L = translation_rate(model, 1, [m, p])
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

# -- helpers for the L14a circuit configs ------------------------------------------------------- #

"""The folder of the example's circuit configs."""
const L14A_CONFIG_DIR = joinpath(WEEK_ROOT, "L14a", "config")

"""The circuits of the example: one for each config file in L14a/config."""
const L14A_CIRCUITS = [splitext(file)[1] for file in readdir(L14A_CONFIG_DIR) if endswith(file, ".toml")]

"""The circuit that the example calls the self-activating gene."""
const SELF_ACTIVATING = "positive-autoregulation"

"""The path of the example's copy of the config file `name` in L14a/config."""
function l14a_config(name::AbstractString)::String
    return joinpath(L14A_CONFIG_DIR, name * ".toml")
end

"""Run `model` with DynamicSS from `x0` and return the solution (inducer at its baseline)."""
function settle(model::MyGeneNetworkModel, x0::Vector{Float64})
    problem = SteadyStateProblem(balances!, x0, model)
    return SteadyStateDiffEq.solve(problem, DynamicSS(Tsit5()); verbose = false)
end

"""Every bound regulator of `model`, as a list of MyBoundRegulatorModel."""
function bound_regulators(model::MyGeneNetworkModel)
    list = []
    for gene in model.genes
        for state in gene.promoter
            for b in state.bound
                push!(list, b)
            end
        end
    end
    return list
end

"""The steady states of the self-activating gene `model` with the lowest and the highest protein level, as (low, high)."""
function low_and_high(model::MyGeneNetworkModel)
    states = par_steady_states(model)
    levels = [state[2] for state in states]
    return (states[argmin(levels)], states[argmax(levels)])
end

# -- helpers that read the example notebook ------------------------------------------------------ #

const EXAMPLE_PATH = joinpath(WEEK_ROOT, "L14a", "CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb")

"""The source of the example cell whose id is `id`."""
function example_cell(id::String)::String
    for cell in JSON.parsefile(EXAMPLE_PATH)["cells"]
        if get(cell, "id", "") == id
            return join(cell["source"])
        end
    end
    error("the example has no cell $(id)")
end

"""The value of the line `name = value;` in the example cell `cell`, as written there."""
function setting_text(name::String; cell::String = "settings")::String
    found = match(Regex("(?m)^\\s*" * name * "\\s*=\\s*([^;\\n]+);"), example_cell(cell))
    if found === nothing
        error("no line $(name) = ...; in the cell $(cell)")
    end
    return String(strip(found.captures[1]))
end

"""The number on the line `name = value;` in the example cell `cell`."""
setting_value(name::String; cell::String = "settings")::Float64 = Float64(Core.eval(Main, Meta.parse(setting_text(name; cell = cell))))

"""The circuit that the settings cell chooses."""
settings_circuit()::String = String(strip(setting_text("circuit"), '"'))

"""A replacement for run_example that sets `name` to `value` on its own line, whatever value the cell holds now."""
function set_to(name::String, value)::Pair
    return Regex("(?m)^(\\s*)" * name * "\\s*=\\s*[^;\\n]+;") => SubstitutionString("\\1" * name * " = " * string(value) * ";")
end

"""The Things to Try bullet whose bold label is `label`."""
function things_bullet(label::String)::String
    for line in split(example_cell("things-to-try"), "\n")
        if startswith(line, "* __" * label * ":__")
            return String(line)
        end
    end
    error("Things to Try has no bullet $(label)")
end

"""The value that the Things to Try bullet `label` gives `name`, from "`name` to `value`" or "`name` still at `value`"."""
function things_value(label::String, name::String)::String
    found = match(Regex("`" * name * "` (?:to|still at) `([^`]+)`"), things_bullet(label))
    if found === nothing
        error("the bullet $(label) gives no value for $(name)")
    end
    return String(found.captures[1])
end

"""
The smallest whole binding order above the largest order in the config of the circuit `name` at
which the circuit, with that order on every regulator, does not settle. The search stops at twice
that largest order, and returns `nothing` when every order up to there settles.
"""
function unstable_order(name::AbstractString)
    top = 0.0
    for b in bound_regulators(build(MyGeneNetworkModel, l14a_config(name)))
        top = max(top, b.n)
    end
    for n in (floor(Int, top) + 1):floor(Int, 2 * top)
        model = build(MyGeneNetworkModel, l14a_config(name))
        for b in bound_regulators(model)
            b.n = n
        end
        if string(settle(model, zeros(2 * length(model.genes))).retcode) != "Success"
            return n
        end
    end
    return nothing
end

"""
Run the example's code cells in order in a fresh module, and return the module. Each pair in
`replacements` is applied to the source of the `settings` cell, and must match it. When
`after_build` is a model, it replaces `model` right after the cell `build-model`. The run stops
after the cell whose id is `stop_after`, when one is given. `cell_edits` maps the id of any other
code cell to its own vector of `pattern => value` replacements.
"""
function run_example(replacements::Vector; after_build = nothing, stop_after::String = "",
        cell_edits::Dict = Dict())::Module
    notebook = JSON.parsefile(EXAMPLE_PATH)
    workspace = Module(:L14aExampleValidation)
    Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
    for (index, cell) in enumerate(notebook["cells"])
        cell["cell_type"] == "code" || continue
        source = join(cell["source"])
        id = get(cell, "id", "")
        if id == "settings"
            for (pattern, value) in replacements
                @assert occursin(pattern, source) "not in the settings cell: $(pattern)"
                source = replace(source, pattern => value)
            end
        end
        if haskey(cell_edits, id)
            for (pattern, value) in cell_edits[id]
                @assert occursin(pattern, source) "not in the cell $(id): $(pattern)"
                source = replace(source, pattern => value)
            end
        end
        Base.include_string(REPL.softscope, workspace, source,
            joinpath(dirname(EXAMPLE_PATH), "validation-cell-$(index).jl"))
        if id == "build-model" && after_build !== nothing
            Core.eval(workspace, :(model = $(after_build)))
        end
        if id == stop_after
            break
        end
    end
    return workspace
end

"""A global of the notebook run `ws`, read in the newest world, because the cells defined it after this code was compiled."""
nbvar(ws::Module, name::Symbol) = Core.eval(ws, name)

"""
Check the pulse run of the notebook run `ws` against that run's own settings: the inducer follows
the schedule the settings give, rounded to whole steps; the run ends at the last whole step at or
before the final time; both models start at the steady state; and the linear trace is the
recursion of the run's own matrices, driven by that schedule.
"""
function check_pulse_run(ws::Module)
    model = nbvar(ws, :model)
    pulse = nbvar(ws, :pulse)
    x_steady = nbvar(ws, :x_steady)
    Δt = nbvar(ws, :Δt)
    N = length(model.genes)
    baseline = model.inputs["I"].initial
    level = nbvar(ws, :pulse_level)
    pulse_on = round(nbvar(ws, :pulse_start) / Δt) * Δt
    pulse_end = round((nbvar(ws, :pulse_start) + nbvar(ws, :pulse_length)) / Δt) * Δt

    # the schedule and the time grid -
    expected = [(pulse_on <= t < pulse_end) ? level : baseline for t in pulse.t]
    @test pulse.I == expected
    @test pulse.t[end] == floor(nbvar(ws, :final_time) / Δt) * Δt
    @test size(pulse.p_linear) == size(pulse.p_nonlinear) == (length(pulse.t), N)

    # both models start at the steady state -
    p_steady = x_steady[N+1:end]
    @test pulse.p_linear[1, :] == p_steady
    @test pulse.p_nonlinear[1, :] == p_steady

    # the input is the total control of each gene: B holds r_X,j in the row of m_j and the column of gene j -
    B = nbvar(ws, :B)
    hand = hand_constants(TOML.parsefile(l14a_config(nbvar(ws, :circuit))))
    expected_B = zeros(2 * N, N)
    for j in 1:N
        expected_B[j, j] = hand_r_X(hand, j)
    end
    @test isapprox(B, expected_B; rtol = 1e-12)

    # the inducer reaches the balances only through the controls: B times dū/dI is the inducer derivative -
    h = 1.0e-6 * max(abs(baseline), 1.0e-3)
    above = deepcopy(model)
    above.inputs["I"].initial = baseline + h
    below = deepcopy(model)
    below.inputs["I"].initial = max(baseline - h, 0.0)
    width = baseline + h - max(baseline - h, 0.0)
    dū_dI = [(transcription_control(above, j, x_steady, 0.0) - transcription_control(below, j, x_steady, 0.0)) / width for j in 1:N]
    B_I = input_jacobian(model, x_steady, 0.0, "I")
    @test isapprox(B * dū_dI, B_I; rtol = 1e-5, atol = 1e-6 * max(norm(B_I), eps()))

    # the linear trace is the recursion of the run's own matrices, driven by the change in each
    # control that the inducer causes, with every level at the steady state -
    Ā = nbvar(ws, :Ā)
    B̄ = nbvar(ws, :B̄)
    trial = nbvar(ws, :trial)
    ū_steady = [transcription_control(model, j, x_steady, 0.0) for j in 1:N]
    Δx = zeros(2 * N)
    recursion = zeros(length(pulse.t), N)
    recursion[1, :] = p_steady
    for k in 1:(length(pulse.t) - 1)
        Δū = [transcription_control(trial, j, x_steady, pulse.t[k]) for j in 1:N] .- ū_steady
        Δx = Ā * Δx + B̄ * Δū
        recursion[k + 1, :] = p_steady + Δx[N+1:end]
    end
    @test isapprox(pulse.p_linear, recursion; rtol = sqrt(eps()))
    return nothing
end

"""
The largest gap between the linear trace of the notebook run `ws` and the exact solution of its
linear model, `dΔx/dt = A Δx + B Δū(t)`, solved by the ODE solver with the run's own schedule, as a
fraction of the largest deviation of the exact solution. Here Δū(t) is the change in each control
that the inducer causes at time t, with every level at the steady state.
"""
function linear_error(ws::Module)::Float64
    A = nbvar(ws, :A)
    B = nbvar(ws, :B)
    model = nbvar(ws, :model)
    trial = nbvar(ws, :trial)
    pulse = nbvar(ws, :pulse)
    x_steady = nbvar(ws, :x_steady)
    N = length(trial.genes)
    ū_steady = [transcription_control(model, j, x_steady, 0.0) for j in 1:N]
    Δū(s) = [transcription_control(trial, j, x_steady, s) for j in 1:N] .- ū_steady
    rates!(du, u, p, s) = (du .= A * u + B * Δū(s))
    edges = [time for time in trial.inputs["I"].times if time < pulse.t[end]]
    solution = OrdinaryDiffEq.solve(ODEProblem(rates!, zeros(2 * N), (0.0, pulse.t[end])), Tsit5();
        tstops = edges, saveat = pulse.t, reltol = 1e-12, abstol = 1e-14)
    @test solution.retcode == ReturnCode.Success
    exact = [x_steady[N + j] + solution.u[k][N + j] for k in 1:length(pulse.t), j in 1:N]
    gap = maximum(abs.(pulse.p_linear .- exact))
    deviation = maximum(abs.(exact .- x_steady[N+1:end]'))
    if deviation == 0.0 # a pulse that moves nothing: the absolute gap
        return gap
    end
    return gap / deviation
end

@meeting "L14a" begin
    @testset "L14a motif eigenvalues and pulses" begin
        # the L14a copies and the package copies are the same files -
        for name in L14A_CIRCUITS
            @test read(l14a_config(name), String) == read(motif_path(name), String)
        end

        # every circuit has the inducer I, which activates its regulator, at the baseline its config file sets -
        for name in L14A_CIRCUITS
            model = build(MyGeneNetworkModel, l14a_config(name))
            @test haskey(model.inputs, "I")
            @test model.inputs["I"].initial == config_baseline(TOML.parsefile(l14a_config(name)))
            effects = [b.inducer_effect for b in bound_regulators(model) if b.inducer == "I"]
            @test !isempty(effects) && all(effects .== "activates")
        end

        # the inducer table sits before the first gene in every file -
        for name in L14A_CIRCUITS
            text = read(l14a_config(name), String)
            @test findfirst("[inputs.I]", text).start < findfirst("[[genes]]", text).start
        end

        # negative autoregulation: one stable node with real, negative eigenvalues -
        nar = build(MyGeneNetworkModel, l14a_config("negative-autoregulation"))
        nar_ss = settle(nar, zeros(2 * length(nar.genes)))
        @test string(nar_ss.retcode) == "Success"
        λn = eigvals(jacobian(nar, Vector(nar_ss.u), 0.0))
        @test all(imag.(λn) .== 0.0)
        @test all(real.(λn) .< 0.0)

        # the self-activating gene: two stable steady states with a saddle between them, as Task 2 says.
        # From zero protein it settles in the low state; from above the high state, in the high state -
        par = build(MyGeneNetworkModel, l14a_config(SELF_ACTIVATING))
        @test length(par_steady_states(par)) == 3
        (low, high) = low_and_high(par)
        @test isapprox(Vector(settle(par, zeros(2)).u), low; rtol = 1e-4)
        @test isapprox(Vector(settle(par, 2 .* high).u), high; rtol = 1e-4)

        # the circuit that Things to Try names under "Another circuit": a complex pair of eigenvalues,
        # so the proteins oscillate as they settle -
        loop = strip(things_value("Another circuit", "circuit"), '"')
        nfl = build(MyGeneNetworkModel, l14a_config(loop))
        nfl_ss = settle(nfl, zeros(2 * length(nfl.genes)))
        @test string(nfl_ss.retcode) == "Success"
        λf = eigvals(jacobian(nfl, Vector(nfl_ss.u), 0.0))
        @test all(real.(λf) .< 0.0)
        @test any(abs.(imag.(λf)) .> sqrt(eps()) * maximum(abs.(λf)))

        # the inducer moves an mRNA balance in every circuit, from the starting protein of the settings -
        starting_protein = setting_value("starting_protein")
        for name in L14A_CIRCUITS
            model = build(MyGeneNetworkModel, l14a_config(name))
            N = length(model.genes)
            x = Vector(settle(model, vcat(zeros(N), fill(starting_protein, N))).u)
            B = input_jacobian(model, x, 0.0, "I")
            @test maximum(abs.(B[1:N])) > 0.0
        end

        # past the largest binding order of its config, the feedback loop stops settling -
        @test unstable_order(loop) !== nothing
    end
end

@meeting "L14a" begin
    @testset "L14a example runs for every circuit" begin
        loop = strip(things_value("Another circuit", "circuit"), '"') # the circuit that Things to Try names under "Another circuit"
        par = build(MyGeneNetworkModel, l14a_config(SELF_ACTIVATING))

        # every circuit runs with the settings in the notebook, and its pulse run matches those settings -
        for name in L14A_CIRCUITS
            ws = run_example([set_to("circuit", "\"$(name)\"")])
            @test nbvar(ws, :circuit) == name
            @test length(nbvar(ws, :x_steady)) == 2 * length(nbvar(ws, :model).genes)
            check_pulse_run(ws)
        end

        # pulse edge cases, each derived from the settings: a pulse of zero length, a pulse that starts
        # after the run ends, a pulse at the baseline, a pulse off the step grid, and a final time off the grid -
        final_time = setting_value("final_time")
        pulse_start = setting_value("pulse_start")
        Δt = setting_value("Δt"; cell = "linearize")
        baseline = config_baseline(TOML.parsefile(l14a_config(settings_circuit())))
        edge_cases = [
            [set_to("pulse_length", 0.0)],
            [set_to("pulse_start", 2 * final_time)],
            [set_to("pulse_level", baseline)],
            [set_to("pulse_start", round(pulse_start / Δt) * Δt + Δt / 4), set_to("pulse_length", Δt / 2)],
            [set_to("final_time", floor(final_time / Δt) * Δt + Δt / 2)],
        ]
        for changes in edge_cases
            check_pulse_run(run_example(changes))
        end

        # another time step: the pulse run follows the new step -
        Δt_other = Δt / 2
        ws = run_example([]; cell_edits = Dict("linearize" => [set_to("Δt", Δt_other)]))
        @test nbvar(ws, :Δt) == Δt_other
        check_pulse_run(ws)

        # Things to Try, the zero-order hold: at the step of the notebook and at twice that step, the
        # zero-order hold matches the exact solution of the linear model at each step, and the error of
        # the bilinear discretization grows with the step -
        zoh = things_value("The zero-order hold", "discretization")
        bilinear_errors = Float64[]
        for step in [Δt, 2 * Δt]
            errors = Dict{String, Float64}()
            for method in [":bilinear", zoh]
                ws = run_example([set_to("discretization", method)]; cell_edits = Dict("linearize" => [set_to("Δt", step)]))
                check_pulse_run(ws)
                errors[method] = linear_error(ws)
            end
            @test errors[zoh] <= sqrt(eps())
            push!(bilinear_errors, errors[":bilinear"])
        end
        @test bilinear_errors[1] < bilinear_errors[2]

        # the pulse result: in every circuit, the linear model follows the nonlinear model more closely
        # for a pulse one tenth the size of the removal that "A longer removal" names than for that removal -
        removal = things_value("A longer removal", "pulse_level")
        for name in L14A_CIRCUITS
            base = config_baseline(TOML.parsefile(l14a_config(name))) # the baseline inducer of this circuit (µM)
            small = base + (parse(Float64, removal) - base) / 10       # the same direction as the removal, one tenth the size
            relative_gap = Float64[]
            for level in [small, removal]
                ws = run_example([set_to("circuit", "\"$(name)\""), set_to("pulse_level", level)])
                N = length(nbvar(ws, :model).genes)
                pulse = nbvar(ws, :pulse)
                p_steady = nbvar(ws, :x_steady)[N+1:end]
                gap = maximum(abs.(pulse.p_linear .- pulse.p_nonlinear))
                response = maximum(abs.(pulse.p_nonlinear .- p_steady'))
                push!(relative_gap, gap / response)
            end
            @test relative_gap[1] < relative_gap[2]
        end

        # Things to Try, a longer removal: from the high state, the self-activating gene switches to its
        # low state and stays there, while the linear model returns to the high state -
        (low, high) = low_and_high(par)
        ws = run_example([set_to("circuit", "\"$(SELF_ACTIVATING)\""),
            set_to("starting_protein", 2 * high[2]), # above the high state, so that Task 2 finds the high state
            set_to("pulse_level", removal),
            set_to("pulse_length", things_value("A longer removal", "pulse_length"))])
        @test isapprox(nbvar(ws, :x_steady), high; rtol = 1e-4)
        pulse = nbvar(ws, :pulse)
        @test abs(pulse.p_nonlinear[end, 1] - low[2]) < abs(pulse.p_nonlinear[end, 1] - high[2])
        @test abs(pulse.p_linear[end, 1] - high[2]) < abs(pulse.p_linear[end, 1] - low[2])

        # from zero protein, Task 2 finds the low state of the self-activating gene -
        ws = run_example([set_to("circuit", "\"$(SELF_ACTIVATING)\""), set_to("starting_protein", 0.0)])
        @test isapprox(nbvar(ws, :x_steady), low; rtol = 1e-4)

        # a start exactly on an unstable steady state stops with the plain message. Without a leak and
        # with n = 1, the zero state of the self-activating gene is a steady state, and a saddle -
        par_config = TOML.parsefile(l14a_config(SELF_ACTIVATING))
        k_leak = leak_state_index(par_config)
        par0 = build(MyGeneNetworkModel, l14a_config(SELF_ACTIVATING))
        par0.genes[1].promoter[k_leak].W = 0.0
        for b in bound_regulators(par0)
            b.n = 1.0
        end
        err = try
            run_example([set_to("circuit", "\"$(SELF_ACTIVATING)\""), set_to("starting_protein", 0.0)];
                after_build = par0, stop_after = "steady-state")
            nothing
        catch e
            e
        end
        @test err !== nothing
        @test err !== nothing && occursin("no stable steady state", lowercase(sprint(showerror, err)))

        # the plain message for a circuit that does not settle: the feedback loop past the largest binding order of its config -
        n_unstable = unstable_order(loop)
        @test n_unstable !== nothing
        if n_unstable !== nothing
            nfl = build(MyGeneNetworkModel, l14a_config(loop))
            for b in bound_regulators(nfl)
                b.n = n_unstable
            end
            err = try
                run_example([set_to("circuit", "\"$(loop)\"")]; after_build = nfl, stop_after = "steady-state")
                nothing
            catch e
                e
            end
            @test err !== nothing
            @test err !== nothing && occursin("no stable steady state", lowercase(sprint(showerror, err)))
        end
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
    v = [1.0, 1.0];
    (result, message) = captured_poweriteration(A, v; maxiter = 1);
    newest = A * v / norm(A * v);   # one step of power iteration from v
    @test isapprox(result.vector, newest; atol = 1e-12)
    @test isapprox(result.value, dot(A * newest, newest); atol = 1e-12)

    # a negative dominant eigenvalue flips the sign of the vector at each iteration; that still converges -
    A = [-5.0 0.0; 0.0 1.0];
    (result, message) = captured_poweriteration(A, v; maxiter = 100);
    λ = eigvals(A);
    @test occursin("Converged", message)
    @test isapprox(result.value, λ[argmax(abs.(λ))]; atol = 1e-3)
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
      dG = $(dG_for(10.0))
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
      dG = $(dG_for(5.0))
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
      dG = $(dG_for(2.0))
      active = true

      [[genes.translation]]
      dG = $(dG_for(3.0))
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

"""The two balances of the translation and inactivation config, written out by hand from the file's numbers at the inducer level I."""
function hand_balances_translation(path::String, x::Vector{Float64}, I::Float64)::Vector{Float64}
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    leak = gene["promoter"][1]                 # the leak state, the only active promoter state
    repressor = gene["promoter"][2]            # the state with the repressor bound
    b = repressor["bound"][1]
    free_state = gene["translation"][1]        # the active translation state, with nothing bound
    bound_state = gene["translation"][2]       # the inactive translation state, with X bound
    c = bound_state["bound"][1]
    θ_m = log(2) / config["parameters"]["mRNA_half_life"]
    θ_p = log(2) / config["parameters"]["protein_half_life"]
    μ = log(2) / config["parameters"]["doubling_time"]
    m = x[1]
    p = x[2]
    f_I = I^b["n_I"] / (b["K_I"]^b["n_I"] + I^b["n_I"])          # the fraction of X that carries the inducer
    a = p * (1.0 - f_I)                                          # the inducer inactivates X, so only X without it binds
    f_repressor = a^b["n"] / (b["K"]^b["n"] + a^b["n"])
    W_leak = config_weight(config, leak)
    W_repressor = config_weight(config, repressor)
    ubar = W_leak / (1.0 + W_leak + W_repressor * f_repressor)
    g = p^c["n"] / (c["K"]^c["n"] + p^c["n"])                    # the bound fraction of X on the mRNA
    W_free = config_weight(config, free_state)
    W_bound = config_weight(config, bound_state)
    w = W_free / (1.0 + W_free + W_bound * g)
    c = hand_constants(config)
    r_X = hand_r_X(c, 1)
    r_L = hand_r_L(c, 1, [m])
    return [r_X * ubar - (θ_m + μ) * m, r_L * w - (θ_p + μ) * p]
end

"""The derivative of the positive autoregulation mRNA balance with respect to the inducer, by the chain rule."""
function hand_input_derivative(path::String, x::Vector{Float64}, I::Float64)::Float64
    config = TOML.parsefile(path)
    gene = config["genes"][1]
    W1 = config_weight(config, gene["promoter"][1])
    W2 = config_weight(config, gene["promoter"][2])
    b = gene["promoter"][2]["bound"][1]
    p = x[2]
    s = I^b["n_I"] / (b["K_I"]^b["n_I"] + I^b["n_I"])                                 # the inducer-bound fraction
    ds_dI = b["n_I"] * b["K_I"]^b["n_I"] * I^(b["n_I"] - 1) / (b["K_I"]^b["n_I"] + I^b["n_I"])^2
    a = s * p                                                                         # the available activator
    f = a^b["n"] / (b["K"]^b["n"] + a^b["n"])
    df_da = b["n"] * b["K"]^b["n"] * a^(b["n"] - 1) / (b["K"]^b["n"] + a^b["n"])^2
    du_df = W2 / (1 + W1 + W2 * f)^2
    r_X = hand_r_X(hand_constants(config), 1)
    return r_X * du_df * df_da * p * ds_dI
end

@meeting "L14a" begin
    @testset "L14a final review: duplicates, zero inducer, translation, inactivation, B" begin

        # two genes with the same name are rejected -
        @test_throws ArgumentError build(MyGeneNetworkModel, duplicate_gene_config())

        # an inducer that inactivates its regulator, and translation states, match the hand balances -
        translation_path = translation_inactivates_config()
        model = build(MyGeneNetworkModel, translation_path)
        for x in [[0.002, 0.3], [0.01, 1.2]]
            dx = zeros(2)
            balances!(dx, x, model, 0.0)
            @test isapprox(dx, hand_balances_translation(translation_path, x, config_baseline(TOML.parsefile(translation_path))); rtol = 1e-12)
        end

        # the input matrix has the size of the analytic derivative, not only its sign -
        path = motif_path("positive-autoregulation")
        par = build(MyGeneNetworkModel, path)
        x = [0.002, 0.3]
        B = input_jacobian(par, x, 0.0, "I")
        @test isapprox(B[1], hand_input_derivative(path, x, config_baseline(TOML.parsefile(path))); rtol = 1e-5)

        # a zero baseline inducer: the derivative is one-sided, matches the analytic value, and never raises -
        zero_path = zero_inducer_config(1.0)
        zero_config = TOML.parsefile(zero_path)
        zero_model = build(MyGeneNetworkModel, zero_path)
        B = input_jacobian(zero_model, x, 0.0, "I")
        @test isapprox(B[1], hand_input_derivative(zero_path, x, config_baseline(zero_config)); rtol = 1e-4)
        fractional = build(MyGeneNetworkModel, zero_inducer_config(1.5))
        @test all(isfinite.(input_jacobian(fractional, x, 0.0, "I")))
    end
end
