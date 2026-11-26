# ================================================================================================ #
# FixedStepMethods.jl
#
# Fixed-step methods for the initial value problem
#
#   dx/dt = f(x, p, t),   x(t_start) = x₀
#
# (week 15, L15a). The right-hand side is a function f!(dx, x, p, t) that writes the derivative
# into dx, the form ODEProblem(...) expects. The package function balances! has this form.
#
# Functions in this file:
#   advance(...)    one step of size Δt from (t, x), by explicit Euler or the fourth-order Runge-Kutta method
#   integrate(...)  a run of equal steps from t_start to t_final, with the state at every step
#   evaluations_per_step(...)  the number of calls of f! in one step of a method
# ================================================================================================ #

"""
    advance(f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64;
        algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod()) -> Vector{Float64}

Take one step of size `Δt` from the state `x` at time `t`, and return the state at `t + Δt`.
The argument `x` is not changed.

### Arguments
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`; it writes `dx/dt` into `dx`.
- `x::Vector{Float64}`: the state at time `t`.
- `p`: the parameters, passed to `f!` unchanged (for the gene networks, the network model).
- `t::Float64`: the time at the start of the step.
- `Δt::Float64`: the step size.
- `algorithm::AbstractFixedStepAlgorithm`: [`ExplicitEulerMethod`](@ref) (default) or [`RungeKutta4Method`](@ref).

### Returns
A new `Vector{Float64}`: `x + Δt ⋅ k₁` for explicit Euler, and `x + Δt ⋅ (k₁ + 2k₂ + 2k₃ + k₄)/6`
for RK4. The slopes `k₁` through `k₄` are taken at `t`, `t + Δt/2`, `t + Δt/2`, and `t + Δt`.

### Example
```julia
x₁ = advance(balances!, x₀, network, 0.0, 0.1; algorithm = RungeKutta4Method());
```
"""
function advance(f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64;
    algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod())::Vector{Float64}
    return _advance(algorithm, f!, x, p, t, Δt)
end

# explicit Euler: one slope at the start of the step -
function _advance(algorithm::ExplicitEulerMethod, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}

    # the slope k₁ at the start of the step -
    k₁ = zeros(length(x));
    f!(k₁, x, p, t);

    # move along that slope for the whole step -
    return x + Δt * k₁;
end

# classical fourth-order Runge-Kutta: four slopes per step -
function _advance(algorithm::RungeKutta4Method, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}

    # the four slopes, one scratch vector for each -
    k₁ = zeros(length(x));
    k₂ = zeros(length(x));
    k₃ = zeros(length(x));
    k₄ = zeros(length(x));

    # k₁ at the start of the step -
    f!(k₁, x, p, t);

    # k₂ at the midpoint, using k₁ -
    f!(k₂, x + (Δt / 2) * k₁, p, t + Δt / 2);

    # k₃ at the midpoint again, using k₂ -
    f!(k₃, x + (Δt / 2) * k₂, p, t + Δt / 2);

    # k₄ at the end of the step, using k₃ -
    f!(k₄, x + Δt * k₃, p, t + Δt);

    # weight the four slopes 1, 2, 2, 1 -
    return x + (Δt / 6) * (k₁ + 2 * k₂ + 2 * k₃ + k₄);
end

"""
    evaluations_per_step(algorithm::AbstractFixedStepAlgorithm) -> Int64

The number of calls of `f!` in one step of the method: `1` for [`ExplicitEulerMethod`](@ref) and
`4` for [`RungeKutta4Method`](@ref). A tag without a method here throws a `MethodError`.
"""
function evaluations_per_step(algorithm::ExplicitEulerMethod)::Int64
    return 1;
end

function evaluations_per_step(algorithm::RungeKutta4Method)::Int64
    return 4;
end

"""
    integrate(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64,
        algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod()) -> NamedTuple

Integrate `dx/dt = f(x, p, t)` from `t_start` to `t_final` in equal steps of size `Δt`, by calling
[`advance`](@ref) once per step.

### Arguments
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`.
- `x₀::Vector{Float64}`: the state at `t_start`.
- `p`: the parameters, passed to `f!` unchanged.
- `t_start::Float64`, `t_final::Float64`: the first and last times; `t_final` must be larger.
- `Δt::Float64`: the step size; it must be positive, and `(t_final − t_start)/Δt` must be a whole number.
- `algorithm::AbstractFixedStepAlgorithm`: [`ExplicitEulerMethod`](@ref) (default) or [`RungeKutta4Method`](@ref).

### Returns
A `NamedTuple` `(t, x, evaluations)`. The vector `t` holds the times `t_start + (k − 1)Δt`. Row `k`
of the matrix `x` is the state at `t[k]`. The integer `evaluations` is the number of steps times
[`evaluations_per_step`](@ref) of the method.

Throws an `ArgumentError` when the step or time bounds are nonfinite, the step or interval is
nonpositive, or the interval does not contain a whole number of steps.

### Order and input jumps
The order of RK4 holds when `f!` is smooth. When the stages of a step sample both sides of an
input jump, the step can lose its order. For a right-continuous input, the last stage can sample
the new value even when the jump falls exactly at the end of the step.
"""
function integrate(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64,
    algorithm::AbstractFixedStepAlgorithm = ExplicitEulerMethod())::NamedTuple

    # the step size must be positive -
    if !isfinite(Δt) || Δt <= 0.0
        throw(ArgumentError("the step size Δt must be finite and positive"))
    end

    # the run must move forward in time -
    if !isfinite(t_start) || !isfinite(t_final) || t_final <= t_start
        throw(ArgumentError("the time bounds must be finite and t_final must be larger than t_start"))
    end

    # the run must be a whole number of steps -
    steps_real = (t_final - t_start) / Δt;
    nearest_step_count = round(steps_real);
    if !(1 <= nearest_step_count < typemax(Int)) || abs(steps_real - nearest_step_count) > 1e-9
        throw(ArgumentError("(t_final − t_start)/Δt must be a positive whole number of steps"))
    end
    number_of_steps = Int(nearest_step_count);

    # the number of calls of f! per step, from the method -
    calls_per_step = evaluations_per_step(algorithm);

    # allocate the times and the states; row 1 holds the initial state -
    number_of_states = length(x₀);
    t = zeros(number_of_steps + 1);
    x = zeros(number_of_steps + 1, number_of_states);
    t[1] = t_start;
    x[1, :] = x₀;

    # take the steps; each time is computed from its index, so rounding errors do not add up -
    for k in 1:number_of_steps
        t[k+1] = t_start + k * Δt;
        x[k+1, :] = advance(f!, x[k, :], p, t[k], Δt; algorithm = algorithm);
    end

    # report the run, with the number of calls of f! -
    return (t = t, x = x, evaluations = calls_per_step * number_of_steps);
end
