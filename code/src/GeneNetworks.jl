# ================================================================================================ #
# GeneNetworks.jl
#
# Gene network models read from TOML config files (week 14, L14a). Each gene j has an mRNA
# level m_j and a protein level p_j inside the cell (nmol/gDW, nanomoles per gram of dry cell
# weight). Inducers are concentrations in the medium (µM), and time is in minutes. The balances are
#
#   dm_j/dt = r_X,j ⋅ u_j − (θ_m,j + μ) ⋅ m_j + λ_j
#   dp_j/dt = r_L,j ⋅ w_j − (θ_p,j + μ) ⋅ p_j
#
# with the kinetic limits of CHEME 5450 (L6b): the transcription rate
#
#   r_X,j = Vmax_X,j ⋅ G_j / (τ_X,j ⋅ K_X,j + (1 + τ_X,j) ⋅ G_j + O_X,j),   Vmax_X,j = R_X,T ⋅ v̇_X / l_G,j
#
# and the translation rate
#
#   r_L,j = Vmax_L,j ⋅ m_j / (τ_L,j ⋅ K_L,j + (1 + τ_L,j) ⋅ m_j + O_L,j),   Vmax_L,j = K_P ⋅ R_L,T ⋅ v̇_L / l_P,j
#
# The terms O_X,j and O_L,j describe the competition of the other genes for RNA polymerase and ribosomes:
#
#   O_X,j = Σ_{i≠j} (K_X,j τ_X,j) / (K_X,i τ_X,i) ⋅ (1 + τ_X,i) ⋅ G_i
#   O_L,j = Σ_{i≠j} (K_L,j τ_L,j) / (K_L,i τ_L,i) ⋅ (1 + τ_L,i) ⋅ m_i
#
# build(...) computes Vmax, τ, K, and G from the cell, polymerase, and ribosome values of the config
# (Factory.jl). The controls come from the gene's promoter and translation
# states by the Boltzmann (active-state) rule. Each state s has the weight ω_s = W_s ⋅ (the bound
# fraction of each regulator bound in s), with the Boltzmann factor W_s = exp(−ΔG_s / RT) of the
# state's Gibbs energy ΔG_s relative to the reference state. For transcription, the reference
# state is the empty promoter, with weight 1. build(...) computes each W_s from the state's dG
# (kJ/mol) and the config's temperature (K). The probability of state s is ω_s / Z, where the partition function Z is
# the sum of the weights of all the states.
#
# The regulated control u_j is the probability of the states with regulated transcription. The
# leak is λ_j = r_X,j ⋅ u†_j, where u†_j is the probability of the states with unregulated
# transcription (RNA polymerase bound alone, in an activated gene). The code sums the weights of
# all the active states and divides by Z. That gives ū_j = u_j + u†_j, the probability of every
# state that transcribes, and r_X,j ⋅ ū_j = r_X,j ⋅ u_j + λ_j.
#
# Functions in this file:
#   motif_path(...)             the path of a motif config file that ships with the package
#   set_input!(...)             set a piecewise-constant inducer schedule
#   input_value(...)            the value of an inducer at time t
#   bound_fraction(...)         the bound fraction of one regulator in one state
#   control(...)                the Boltzmann (active-state) control of a list of states
#   transcription_control(...)  the total transcriptional control ū_j = u_j + u†_j of gene j
#   translation_control(...)    the translational control w_j of gene j
#   transcription_rate(...)     the transcription kinetic limit r_X,j of gene j
#   translation_rate(...)       the translation kinetic limit r_L,j of gene j
#   balances!(...)              the right-hand side of the mRNA and protein balances
#   equations(...)              the balances and controls of a network, as text
#   jacobian(...)               the state Jacobian (the A matrix of the linearized model)
#   input_jacobian(...)         the derivative of the balances with respect to one inducer, through the controls
#   steady_state(...)           a steady state, by Newton's method
#   discretize(...)             the bilinear or zero-order hold discretization of ẋ = A x + B u
#
# The type definitions are in Types.jl, and build(MyGeneNetworkModel, path) is in Factory.jl.
# ================================================================================================ #

"""
    motif_path(name::String) -> String

Return the path of the motif config file `name.toml` in the package's `data/motifs` folder.

### Example
```julia
path = motif_path("positive-autoregulation");
network = build(MyGeneNetworkModel, path);
```
"""
function motif_path(name::String)::String
    return joinpath(_PATH_TO_DATA, "motifs", name * ".toml")
end

"""
    set_input!(model::MyGeneNetworkModel, name::String, times::Vector{Float64}, values::Vector{Float64}) -> Nothing

Set the schedule of the inducer `name`. From `times[k]` until the next time, the inducer has the
value `values[k]`. Before `times[1]` it keeps its initial value from the config file. The `!` at
the end of the name is a Julia convention: the function changes its argument (`model`).

### Example
```julia
set_input!(network, "I", [100.0, 130.0], [5.0, 1.0]); # raise I to 5 µM at t = 100 min, back to 1 µM at t = 130 min
```
"""
function set_input!(model::MyGeneNetworkModel, name::String, times::Vector{Float64}, values::Vector{Float64})::Nothing

    # the inducer must exist, and every time needs a value -
    if haskey(model.inputs, name) == false
        throw(ArgumentError("the network has no inducer named $(name)"))
    end
    if length(times) != length(values)
        throw(ArgumentError("times and values must have the same length"))
    end

    # store copies, so that later changes to the caller's vectors do not change the schedule -
    model.inputs[name].times = copy(times)
    model.inputs[name].values = copy(values)
    return nothing
end

"""
    input_value(model::MyGeneNetworkModel, name::String, t::Float64) -> Float64

Return the concentration of the inducer `name` at time `t`. The value is the one set at the last
schedule time at or before `t`, or the initial value when `t` is before the first schedule time.
"""
function input_value(model::MyGeneNetworkModel, name::String, t::Float64)::Float64

    # the inducer must exist -
    if haskey(model.inputs, name) == false
        throw(ArgumentError("the network has no inducer named $(name)"))
    end
    schedule = model.inputs[name]

    # walk through the schedule and keep the last value whose time has been reached -
    value = schedule.initial
    for k in 1:length(schedule.times)
        if schedule.times[k] <= t
            value = schedule.values[k]
        end
    end
    return value
end

"""
    bound_fraction(model::MyGeneNetworkModel, b::MyBoundRegulatorModel, x::AbstractVector, t::Float64) -> Float64

Return the bound fraction `f = aⁿ / (Kⁿ + aⁿ)` of the regulator `b`, where `a` is the regulator's
available level. Without an inducer, `a` is the regulator's protein level `p`.
With an inducer `I`, whose own bound fraction is `f_I = I^n_I / (K_I^n_I + I^n_I)`, `a = p ⋅ f_I`
when the inducer activates the regulator, and `a = p ⋅ (1 − f_I)` when it inactivates it.
"""
function bound_fraction(model::MyGeneNetworkModel, b::MyBoundRegulatorModel, x::AbstractVector, t::Float64)::Float64

    # the regulator's protein level. Proteins follow the N mRNA entries in x -
    N = length(model.genes)
    p = x[N + model.index[b.regulator]]

    # the available level, changed by the inducer when the regulator has one -
    available = p
    if b.inducer != ""
        I = input_value(model, b.inducer, t)
        f_I = I^b.n_I / (b.K_I^b.n_I + I^b.n_I)
        if b.inducer_effect == "activates"
            available = p * f_I
        else
            available = p * (1.0 - f_I)
        end
    end

    # a numerical solver can step slightly below zero; a negative level binds nothing -
    if available < 0.0
        available = 0.0
    end

    # the bound fraction -
    return available^b.n / (b.K^b.n + available^b.n)
end

"""
    control(model::MyGeneNetworkModel, states::Vector{MyControlStateModel}, x::AbstractVector, t::Float64) -> Float64

Return the Boltzmann (active-state) control of a list of promoter or translation states. The
weight of a state is its `W` times the bound fraction of each regulator bound in it, where
`W = exp(−ΔG/RT)` is the Boltzmann factor of the state's Gibbs energy `ΔG` relative to the
reference state. The control is

    (sum of the weights of the active states) / (1 + sum of the weights of all the listed states),

where the 1 is the weight of the reference state (the empty promoter, for transcription). The control lies between
0 and 1. An empty list of states means the process is not regulated, and the control is 1.
"""
function control(model::MyGeneNetworkModel, states::Vector{MyControlStateModel}, x::AbstractVector, t::Float64)::Float64

    # no states: the process is not regulated -
    if isempty(states) == true
        return 1.0
    end

    # add up the weights of the active states and of all states -
    active_sum = 0.0
    total_sum = 1.0 # the reference state has weight 1
    for state in states

        # the weight of this state: W times the bound fraction of each bound regulator -
        weight = state.W
        for b in state.bound
            weight = weight * bound_fraction(model, b, x, t)
        end

        # active states count in the numerator and the denominator; inactive ones only in the denominator -
        if state.active == true
            active_sum = active_sum + weight
        end
        total_sum = total_sum + weight
    end

    # the probability of the active states -
    return active_sum / total_sum
end

"""
    transcription_control(model::MyGeneNetworkModel, j::Int64, x::AbstractVector, t::Float64) -> Float64

Return the total transcriptional control ū_j = u_j + u†_j of gene `j`: the probability of every
promoter state that transcribes, at the network state `x` and time `t`. Here u_j is the regulated
control, and u†_j is the probability of the states with unregulated transcription, which gives the
leak λ_j = r_X,j ⋅ u†_j.
"""
function transcription_control(model::MyGeneNetworkModel, j::Int64, x::AbstractVector, t::Float64)::Float64
    return control(model, model.genes[j].promoter, x, t)
end

"""
    translation_control(model::MyGeneNetworkModel, j::Int64, x::AbstractVector, t::Float64) -> Float64

Return the translational control w_j of gene `j`: the Boltzmann control of the gene's translation
states, or 1 when the gene has none.
"""
function translation_control(model::MyGeneNetworkModel, j::Int64, x::AbstractVector, t::Float64)::Float64
    return control(model, model.genes[j].translation, x, t)
end

"""
    transcription_rate(model::MyGeneNetworkModel, j::Int64) -> Float64

Return the transcription kinetic limit of gene `j` (nmol/gDW/min), from CHEME 5450 (L6b):

    r_X,j = Vmax_X,j ⋅ G_j / (τ_X,j ⋅ K_X,j + (1 + τ_X,j) ⋅ G_j + O_X,j)
    O_X,j = Σ_{i≠j} (K_X,j τ_X,j) / (K_X,i τ_X,i) ⋅ (1 + τ_X,i) ⋅ G_i

The term O_X,j describes the competition of the other genes for RNA polymerase. The rate does not
depend on the state, because the gene levels are constant.
"""
function transcription_rate(model::MyGeneNetworkModel, j::Int64)::Float64

    # the gene, and the competition of every other gene for RNA polymerase -
    gene = model.genes[j]
    O_X = 0.0
    for i in 1:length(model.genes)
        if i != j
            other = model.genes[i]
            O_X = O_X + (gene.K_X * gene.τ_X) / (other.K_X * other.τ_X) * (1.0 + other.τ_X) * other.G
        end
    end

    # the kinetic limit -
    return gene.Vmax_X * gene.G / (gene.τ_X * gene.K_X + (1.0 + gene.τ_X) * gene.G + O_X)
end

"""
    translation_rate(model::MyGeneNetworkModel, j::Int64, x::AbstractVector) -> Float64

Return the translation kinetic limit of gene `j` at the state `x` (nmol/gDW/min), from CHEME 5450 (L6b):

    r_L,j = Vmax_L,j ⋅ m_j / (τ_L,j ⋅ K_L,j + (1 + τ_L,j) ⋅ m_j + O_L,j)
    O_L,j = Σ_{i≠j} (K_L,j τ_L,j) / (K_L,i τ_L,i) ⋅ (1 + τ_L,i) ⋅ m_i

The term O_L,j describes the competition of the other mRNAs for ribosomes. The mRNA levels are the
first N entries of `x`.
"""
function translation_rate(model::MyGeneNetworkModel, j::Int64, x::AbstractVector)::Float64

    # the gene, and the competition of every other mRNA for ribosomes -
    gene = model.genes[j]
    O_L = 0.0
    for i in 1:length(model.genes)
        if i != j
            other = model.genes[i]
            O_L = O_L + (gene.K_L * gene.τ_L) / (other.K_L * other.τ_L) * (1.0 + other.τ_L) * x[i]
        end
    end

    # the kinetic limit -
    m_j = x[j]
    return gene.Vmax_L * m_j / (gene.τ_L * gene.K_L + (1.0 + gene.τ_L) * m_j + O_L)
end

"""
    balances!(dx::AbstractVector, x::AbstractVector, model::MyGeneNetworkModel, t) -> Nothing

Compute the right-hand side of the mRNA and protein balances of every gene and store it in `dx`:

    dm_j/dt = r_X,j ⋅ u_j − (θ_m,j + μ) ⋅ m_j + λ_j
    dp_j/dt = r_L,j ⋅ w_j − (θ_p,j + μ) ⋅ p_j

The kinetic limits r_X,j and r_L,j come from `transcription_rate(...)` and `translation_rate(...)`.

The leak is λ_j = r_X,j ⋅ u†_j. The code computes the total control ū_j = u_j + u†_j, the
probability of every promoter state that transcribes, and uses r_X,j ⋅ ū_j = r_X,j ⋅ u_j + λ_j.

The state vector is `x = [m_1, …, m_N, p_1, …, p_N]`. The argument order (`dx`, `x`, parameters,
`t`) is the one `ODEProblem(...)` in OrdinaryDiffEq expects, so the function can be passed to it
directly with the network as the parameters.
"""
function balances!(dx::AbstractVector, x::AbstractVector, model::MyGeneNetworkModel, t)::Nothing

    # the number of genes; mRNA entries come first, then protein entries -
    N = length(model.genes)
    time = Float64(t) # the solver may pass t as another number type

    # one pair of balances per gene -
    for j in 1:N
        gene = model.genes[j]
        m_j = x[j] # mRNA of gene j
        p_j = x[N + j] # protein of gene j

        # the kinetic limits of transcription and translation -
        r_X = transcription_rate(model, j)
        r_L = translation_rate(model, j, x)

        # the controls -
        ū_j = transcription_control(model, j, x, time) # ū_j = u_j + u†_j: regulated and unregulated transcription
        w_j = translation_control(model, j, x, time)

        # the balances. The transcription r_X ⋅ ū_j is the regulated transcription r_X ⋅ u_j plus the leak λ_j -
        dx[j] = r_X * ū_j - (gene.θ_m + model.μ) * m_j
        dx[N + j] = r_L * w_j - (gene.θ_p + model.μ) * p_j
    end
    return nothing
end

"""
    _short(value::Float64) -> String

Return `value` rounded to four significant digits, as text, for `equations(...)`.
"""
function _short(value::Float64)::String
    return string(round(value; sigdigits = 4))
end

"""
    _state_text(model::MyGeneNetworkModel, state::MyControlStateModel, labels::Vector{String}) -> String

Return the weight of one control state as text, for example `10.0 f₁`. The function also adds a
definition line for each bound fraction to `labels`, for example
`f₁ = a^3.0 / (0.5^3.0 + a^3.0), a = p_X × I / (1.0 + I)`.
"""
function _state_text(model::MyGeneNetworkModel, state::MyControlStateModel, labels::Vector{String})::String

    # subscript digits for the names f₁, f₂, ... -
    subscripts = Dict('0' => '₀', '1' => '₁', '2' => '₂', '3' => '₃', '4' => '₄',
        '5' => '₅', '6' => '₆', '7' => '₇', '8' => '₈', '9' => '₉')

    # start with the weight W, then multiply by one bound fraction per bound regulator -
    text = _short(state.W)
    for b in state.bound

        # the next bound-fraction name -
        number = string(length(labels) + 1)
        name = "f"
        for digit in number
            name = name * string(subscripts[digit])
        end
        text = text * " " * name

        # the available regulator level, with the inducer factor when there is one -
        available = "p_" * b.regulator
        if b.inducer != ""
            f_I = b.inducer * "^" * _short(b.n_I) * " / (" * _short(b.K_I) * "^" * _short(b.n_I) * " + " * b.inducer * "^" * _short(b.n_I) * ")"
            if b.inducer_effect == "activates"
                available = "p_" * b.regulator * " × " * f_I
            else
                available = "p_" * b.regulator * " × (1 − " * f_I * ")"
            end
        end

        # the definition line of this bound fraction -
        line = "    " * name * " = a^" * _short(b.n) * " / (" * _short(b.K) * "^" * _short(b.n) * " + a^" * _short(b.n) * "),  a = " * available
        push!(labels, line)
    end
    return text
end

"""
    _control_text(model::MyGeneNetworkModel, symbol::String, states::Vector{MyControlStateModel}) -> String

Return the Boltzmann control of a list of states as text, for example
`ū_X = (0.005 + 10.0 f₁) / (1 + 0.005 + 10.0 f₁)`, followed by the definition of each bound fraction.
"""
function _control_text(model::MyGeneNetworkModel, symbol::String, states::Vector{MyControlStateModel})::String

    # an empty list: the process is not regulated -
    if isempty(states) == true
        return "  " * symbol * " = 1 (not regulated)\n"
    end

    # the weight of each state; active states go in the numerator, all states in the denominator -
    labels = String[]
    numerator = String[]
    denominator = ["1"]
    for state in states
        weight = _state_text(model, state, labels)
        if state.active == true
            push!(numerator, weight)
        end
        push!(denominator, weight)
    end

    # an empty numerator means no state is active, and the control is zero -
    top = "0"
    if isempty(numerator) == false
        top = join(numerator, " + ")
    end

    # the control line, then the bound-fraction lines -
    text = "  " * symbol * " = (" * top * ") / (" * join(denominator, " + ") * ")\n"
    for line in labels
        text = text * line * "\n"
    end
    return text
end

"""
    equations(model::MyGeneNetworkModel) -> String

Return the balances and controls of every gene of the network as text, with the numbers from the
config file. Print the result with `println(equations(model))`.

### Example
```julia
network = build(MyGeneNetworkModel, motif_path("positive-autoregulation"));
println(equations(network));
```
"""
function equations(model::MyGeneNetworkModel)::String

    # the description first -
    text = model.description * "\n"

    # one block per gene -
    for j in 1:length(model.genes)
        gene = model.genes[j]
        g = gene.name
        r_X = transcription_rate(model, j)
        O_L = "" # the competition of the other mRNAs for ribosomes, as text
        for i in 1:length(model.genes)
            if i != j
                other = model.genes[i]
                O_L = O_L * " + " * _short((gene.K_L * gene.τ_L) / (other.K_L * other.τ_L) * (1.0 + other.τ_L)) * " m_" * other.name
            end
        end
        text = text * "\n"
        text = text * "dm_" * g * "/dt = r_X," * g * " ū_" * g * " − (θ_m," * g * " + μ) m_" * g * "\n"
        text = text * "dp_" * g * "/dt = r_L," * g * " w_" * g * " − (θ_p," * g * " + μ) p_" * g * "\n"
        text = text * "  r_X," * g * " = " * _short(r_X) * " nmol/gDW/min  (Vmax_X = " * _short(gene.Vmax_X) * ", τ_X = " * _short(gene.τ_X) * ", K_X = " * _short(gene.K_X) * ", G = " * _short(gene.G) * ")\n"
        text = text * "  r_L," * g * " = " * _short(gene.Vmax_L) * " m_" * g * " / (" * _short(gene.τ_L * gene.K_L) * " + " * _short(1.0 + gene.τ_L) * " m_" * g * O_L * ")\n"
        text = text * "  θ_m," * g * " + μ = " * _short(gene.θ_m + model.μ) * " 1/min,  θ_p," * g * " + μ = " * _short(gene.θ_p + model.μ) * " 1/min\n"
        text = text * _control_text(model, "ū_" * g, gene.promoter)
        text = text * _control_text(model, "w_" * g, gene.translation)
    end
    return text
end

"""
    jacobian(model::MyGeneNetworkModel, x::Vector{Float64}, t::Float64) -> Matrix{Float64}

Return the Jacobian of the balances at the state `x` and time `t`: the entry `J[k, i]` is the
derivative of the k-th balance with respect to the i-th state. At a steady state, this matrix is
the `A` of the linearized model `ẋ = A Δx + B Δu`.

The derivatives are central differences: `(f(x + h eᵢ) − f(x − h eᵢ)) / 2h`, with the step
`h = 10⁻⁶ ⋅ max(|xᵢ|, 10⁻³)`.
"""
function jacobian(model::MyGeneNetworkModel, x::Vector{Float64}, t::Float64)::Matrix{Float64}

    # initialize -
    n = length(x)
    J = zeros(n, n)
    f_plus = zeros(n)
    f_minus = zeros(n)

    # one column per state -
    for i in 1:n

        # the step for this state -
        h = 1.0e-6 * max(abs(x[i]), 1.0e-3)

        # the balances a step above and a step below -
        x_plus = copy(x)
        x_plus[i] = x_plus[i] + h
        x_minus = copy(x)
        x_minus[i] = x_minus[i] - h
        balances!(f_plus, x_plus, model, t)
        balances!(f_minus, x_minus, model, t)

        # the central difference fills column i -
        for k in 1:n
            J[k, i] = (f_plus[k] - f_minus[k]) / (2.0 * h)
        end
    end
    return J
end

"""
    input_jacobian(model::MyGeneNetworkModel, x::Vector{Float64}, t::Float64, name::String) -> Vector{Float64}

Return the derivative of the balances with respect to the inducer `name`, at the state `x` and
time `t`. The inducer changes the balances only through the controls, so this vector is the input
matrix of the controls times the derivative of the controls with respect to the inducer.

The derivative is a central difference in the inducer concentration `I`, with the step
`h = 10⁻⁶ ⋅ max(|I|, 10⁻³)`. When `I < h`, the step `I − h` would be a negative concentration, and
the derivative is a forward difference from `I` instead. The function works on a copy of the
network, so `model` is not changed.
"""
function input_jacobian(model::MyGeneNetworkModel, x::Vector{Float64}, t::Float64, name::String)::Vector{Float64}

    # the inducer value and the step -
    I = input_value(model, name, t)
    h = 1.0e-6 * max(abs(I), 1.0e-3)

    # the lower point and the width of the difference: central, unless I − h would be negative -
    lower = I - h
    width = 2.0 * h
    if lower < 0.0
        lower = I # a forward difference from I
        width = h
    end

    # a copy of the network with the inducer held at I + h, then at the lower point -
    n = length(x)
    f_plus = zeros(n)
    f_minus = zeros(n)
    trial = deepcopy(model)
    trial.inputs[name].times = Float64[]
    trial.inputs[name].values = Float64[]
    trial.inputs[name].initial = I + h
    balances!(f_plus, x, trial, t)
    trial.inputs[name].initial = lower
    balances!(f_minus, x, trial, t)

    # the difference quotient -
    B = zeros(n)
    for k in 1:n
        B[k] = (f_plus[k] - f_minus[k]) / width
    end
    return B
end

"""
    steady_state(model::MyGeneNetworkModel; guess::Vector{Float64}, t::Float64 = 0.0,
        tolerance::Float64 = 1e-12, maxiter::Int64 = 100) -> NamedTuple

Find a steady state of the network (all balances zero) by Newton's method, starting from `guess`.
Each step solves `J ⋅ step = f` and moves to `x − step`. When the full step would make a
level negative, the step is halved until every level is zero or positive.

### Returns
- A `NamedTuple` with the fields `x` (the state), `converged` (`true` when the norm of the
  balances is at most `tolerance`), and `iterations` (the number of Newton steps taken). The
  function does not throw when Newton's method fails; it returns `converged = false`.
"""
function steady_state(model::MyGeneNetworkModel; guess::Vector{Float64}, t::Float64 = 0.0,
    tolerance::Float64 = 1.0e-12, maxiter::Int64 = 100)::NamedTuple

    # initialize -
    x = copy(guess)
    n = length(x)
    f = zeros(n)

    # Newton steps -
    for iteration in 1:maxiter

        # stop when the balances are zero to within the tolerance -
        balances!(f, x, model, t)
        if norm(f) <= tolerance
            return (x = x, converged = true, iterations = iteration - 1)
        end

        # the Newton step; a singular Jacobian ends the search -
        J = jacobian(model, x, t)
        step = zeros(n)
        try
            step = J \ f
        catch
            return (x = x, converged = false, iterations = iteration)
        end

        # halve the step while it would make a level negative -
        fraction = 1.0
        candidate = x - fraction * step
        while any(candidate .< 0.0) == true && fraction > 1.0e-10
            fraction = fraction / 2.0
            candidate = x - fraction * step
        end
        x = candidate
    end

    # out of iterations: report whether the last state is a steady state -
    balances!(f, x, model, t)
    return (x = x, converged = (norm(f) <= tolerance), iterations = maxiter)
end

"""
    discretize(A::Matrix{Float64}, B::AbstractVecOrMat{Float64}; Δt::Float64, method::Symbol = :bilinear) -> Tuple

Return the discretization `(Ā, B̄)` of the linear model `ẋ = A x + B u` with the step `Δt`. The
discrete model is the recursion `x_k = Ā x_{k−1} + B̄ u_k`, with the input held constant at `u_k`
over each step. The keyword `method` chooses the discretization:

- `:bilinear`, the default, is the bilinear discretization. It integrates the model over one step
  with the trapezoid rule:

      Ā = (I − Δt/2 ⋅ A)⁻¹ (I + Δt/2 ⋅ A)
      B̄ = (I − Δt/2 ⋅ A)⁻¹ Δt ⋅ B

  When every eigenvalue of `A` has a negative real part, every eigenvalue of `Ā` lies inside the
  unit circle, for any step `Δt`.

- `:zoh` is the zero-order hold. Because the input is constant over each step, it gives the state
  at the end of each step exactly:

      Ā = exp(A Δt)
      B̄ = A⁻¹ (exp(A Δt) − I) B

  Each eigenvalue `λ` of `A` gives the eigenvalue `exp(λ Δt)` of `Ā`. The zero-order hold needs the
  inverse of `A`, so it throws an `ArgumentError` when `A` is singular.

`B̄` has the shape of `B`: a vector for one input, a matrix for several. Any other `method` throws
an `ArgumentError`.
"""
function discretize(A::Matrix{Float64}, B::AbstractVecOrMat{Float64}; Δt::Float64, method::Symbol = :bilinear)::Tuple

    # the identity matrix of the size of A -
    n = size(A, 1)
    identity = Matrix{Float64}(I, n, n)

    # the bilinear discretization -
    if method == :bilinear

        # the two factors of the bilinear map -
        left = identity - (Δt / 2.0) * A
        right = identity + (Δt / 2.0) * A

        # solve with left instead of forming its inverse -
        Ā = left \ right
        B̄ = left \ (Δt * B)
        return (Ā, B̄)
    end

    # the zero-order hold -
    if method == :zoh

        # the zero-order hold needs the inverse of A: factor A, and stop when A is singular -
        factors = lu(A; check = false)
        if issuccess(factors) == false
            throw(ArgumentError("the zero-order hold needs the inverse of A, and this A is singular"))
        end

        # the matrix exponential, and a solve with the factors of A instead of forming its inverse -
        Ā = exp(A * Δt)
        B̄ = factors \ ((Ā - identity) * B)
        return (Ā, B̄)
    end

    # any other method -
    throw(ArgumentError("unknown discretization method $(method): use :bilinear or :zoh"))
end
