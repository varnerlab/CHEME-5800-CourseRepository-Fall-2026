module Week15Core

import LinearAlgebra
import OrdinaryDiffEq

export decay_rhs,
    euler_stability_factor,
    explicit_euler,
    fermentation_parameters,
    fermentation_rhs,
    library_integrate,
    linear_discretization,
    linear_rollout,
    three_gene_parameters,
    three_gene_rhs

"""Integrate `du/dt = f(u,t,p)` on a uniform grid with explicit Euler."""
function explicit_euler(
    f::Function,
    u0::AbstractVector,
    tspan::Tuple{<:Real,<:Real},
    dt::Real;
    p = nothing,
)
    t0, tf = Float64.(tspan)
    dt > 0 || throw(ArgumentError("dt must be positive"))
    tf > t0 || throw(ArgumentError("the final time must exceed the initial time"))
    steps_float = (tf - t0) / dt
    steps = round(Int, steps_float)
    isapprox(steps_float, steps; atol = 1e-10) || throw(ArgumentError(
        "dt must partition the time interval exactly",
    ))

    times = collect(range(t0, tf; length = steps + 1))
    states = Matrix{Float64}(undef, steps + 1, length(u0))
    states[1, :] .= Float64.(u0)
    for index in 1:steps
        derivative = f(view(states, index, :), times[index], p)
        length(derivative) == length(u0) || throw(DimensionMismatch(
            "the derivative must have the same dimension as u0",
        ))
        states[index + 1, :] .= states[index, :] .+ dt .* derivative
    end
    return (t = times, u = states)
end

"""Integrate the same RHS with the maintained OrdinaryDiffEq Tsit5 solver."""
function library_integrate(
    f::Function,
    u0::AbstractVector,
    tspan::Tuple{<:Real,<:Real};
    p = nothing,
    saveat::Real = 0.1,
)
    saveat > 0 || throw(ArgumentError("saveat must be positive"))
    rhs!(du, u, parameters, t) = (du .= f(u, t, parameters))
    problem = OrdinaryDiffEq.ODEProblem(rhs!, Float64.(u0), Float64.(tspan), p)
    solution = OrdinaryDiffEq.solve(
        problem,
        OrdinaryDiffEq.Tsit5();
        saveat = saveat,
        abstol = 1e-10,
        reltol = 1e-10,
    )
    states = reduce(vcat, permutedims.(solution.u))
    return (t = Float64.(solution.t), u = states)
end

decay_rhs(u, t, rate) = -rate .* u
euler_stability_factor(eigenvalue::Number, dt::Real) = 1 + dt * eigenvalue

"""Parameters for the adapted three-gene memory-network example."""
function three_gene_parameters(; activator::Real = 1.0)
    alpha = zeros(4, 4)
    alpha[4, 1] = 0.25
    alpha[1, 2] = 0.25
    alpha[1, 3] = 0.25
    alpha[2, 3] = 0.50
    alpha[3, 2] = 0.25

    saturation = zeros(4, 4)
    saturation[4, 1] = 0.10
    saturation[1, 2] = 0.10
    saturation[1, 3] = 0.50
    saturation[2, 3] = 0.10
    saturation[3, 2] = 0.40

    hill = zeros(4, 4)
    hill[4, 1] = 1.0
    hill[1, 2] = 2.0
    hill[1, 3] = 2.0
    hill[2, 3] = 2.5
    hill[3, 2] = 2.0

    return (
        alpha = alpha,
        saturation = saturation,
        hill = hill,
        degradation = fill(0.01, 3),
        activator = Float64(activator),
    )
end

function hill_activation(level, alpha, saturation, exponent)
    numerator = alpha * level^exponent
    return numerator / (saturation^exponent + level^exponent)
end

"""Three-gene production-minus-degradation balance adapted from the 2024 lab."""
function three_gene_rhs(state, t, p)
    length(state) == 3 || throw(DimensionMismatch("the three-gene model has three states"))
    a, k, n = p.alpha, p.saturation, p.hill
    production = zeros(3)
    production[1] = hill_activation(p.activator, a[4, 1], k[4, 1], n[4, 1])
    production[2] = max(
        hill_activation(state[1], a[1, 2], k[1, 2], n[1, 2]),
        hill_activation(state[3], a[3, 2], k[3, 2], n[3, 2]),
    )
    production[3] = max(
        hill_activation(state[1], a[1, 3], k[1, 3], n[1, 3]),
        hill_activation(state[2], a[2, 3], k[2, 3], n[2, 3]),
    )
    return production .- p.degradation .* state
end

"""Parameters for the adapted Kompala mixed-sugar fermentation model."""
function fermentation_parameters()
    synthesis = [1e-3, 1e-3]
    decay = [0.05, 0.05]
    growth_saturation = [0.01, 0.20]
    synthesis_saturation = [0.01, 0.20]
    maximum_growth = [1.08, 0.82]
    yield = [0.52, 0.50]
    maximum_enzyme = synthesis ./ (maximum_growth .+ decay)
    return (
        synthesis = synthesis,
        decay = decay,
        growth_saturation = growth_saturation,
        synthesis_saturation = synthesis_saturation,
        maximum_growth = maximum_growth,
        yield = yield,
        maximum_enzyme = maximum_enzyme,
    )
end

"""Five-state mixed-sugar fermentation balance adapted from the 2024 lab."""
function fermentation_rhs(state, t, p)
    length(state) == 5 || throw(DimensionMismatch("the fermentation model has five states"))
    substrate = max.(Float64.(state[1:2]), 0.0)
    enzyme = max.(Float64.(state[3:4]), 0.0)
    biomass = max(Float64(state[5]), 0.0)

    enzyme_synthesis = p.synthesis .* substrate ./ (p.synthesis_saturation .+ substrate)
    growth = p.maximum_growth .* (enzyme ./ p.maximum_enzyme) .* substrate ./
        (p.growth_saturation .+ substrate)
    growth_sum = sum(growth)
    growth_maximum = maximum(growth)
    allocation = growth_sum > 0 ? growth ./ growth_sum : zeros(2)
    activity = growth_maximum > 0 ? growth ./ growth_maximum : zeros(2)
    total_growth = sum(growth .* activity)

    derivative = zeros(5)
    derivative[1:2] .= -(growth .* activity .* biomass) ./ p.yield
    derivative[3:4] .= enzyme_synthesis .* allocation .-
        (total_growth .+ p.decay) .* enzyme
    derivative[5] = total_growth * biomass
    return derivative
end

"""First-order discrete state matrix generated by explicit Euler."""
function linear_discretization(A::AbstractMatrix, dt::Real)
    size(A, 1) == size(A, 2) || throw(DimensionMismatch("A must be square"))
    dt > 0 || throw(ArgumentError("dt must be positive"))
    return Matrix{Float64}(LinearAlgebra.I, size(A, 1), size(A, 2)) + dt .* A
end

"""Roll out x[k+1] = Ad*x[k] for a fixed number of steps."""
function linear_rollout(Ad::AbstractMatrix, x0::AbstractVector, steps::Integer)
    size(Ad, 1) == size(Ad, 2) == length(x0) || throw(DimensionMismatch(
        "Ad and x0 dimensions must agree",
    ))
    steps >= 0 || throw(ArgumentError("steps must be non-negative"))
    states = Matrix{Float64}(undef, steps + 1, length(x0))
    states[1, :] .= x0
    for index in 1:steps
        states[index + 1, :] .= Ad * view(states, index, :)
    end
    return states
end

end
