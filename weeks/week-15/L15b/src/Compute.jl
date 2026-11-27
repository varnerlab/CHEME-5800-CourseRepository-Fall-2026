# L15b: the library solve, explicit Euler, RK4, and a fixed-step loop.
#
# Students complete the TODOs in src/Compute.jl. The reference implementation, with every TODO
# answered, is src/Compute-solution.jl. Each TODO says what to write, and the Hint under
# it gives the syntax to use.
#
# After you change this file, save it and rerun the setup cell of the notebook. The notebook calls
# each function by its full name, for example L15bMethods.mysolve(...), so the rerun picks up your
# changes.
module L15bMethods

# the method tags of the course package. Julia picks a method of mystep by the type of the tag -
using VLDataScienceMachineLearningPackage: ExplicitEulerMethod # the tag of explicit Euler
using VLDataScienceMachineLearningPackage: RungeKutta4Method # the tag of classical fourth-order Runge-Kutta
using VLDataScienceMachineLearningPackage: AbstractFixedStepAlgorithm # the type that both tags belong to
using VLDataScienceMachineLearningPackage: evaluations_per_step # the number of calls of f! in one step of a method
import OrdinaryDiffEq # the library solver; we call ODEProblem, Tsit5, and solve by their full names

# the three functions that the notebook calls -
export mysolve, mystep, myintegrate;

"""
    mysolve(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64,
        stops::Vector{Float64}, Δt_save::Float64, reltol::Float64, abstol::Float64) -> NamedTuple

Solve `dx/dt = f(x, p, t)` from `t_start` to `t_final` with the `Tsit5` method of the
OrdinaryDiffEq package, and save the state every `Δt_save`.

### What the library solver does
The solver starts from `x₀` at `t_start` and takes steps forward in time. It picks the size of each
step itself, so that the estimated error of each step stays below the tolerances. Where the
solution changes slowly, the steps grow long. A long step can step over a jump in the input, such
as an edge of an inducer pulse. Each time in `stops` makes the solver end a step exactly at that
time.

### Arguments
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`. It stores the rate of change of
  each entry of the state in `dx`.
- `x₀::Vector{Float64}`: the state at `t_start`.
- `p`: the parameters, which the solver passes to `f!` as its third argument.
- `t_start::Float64`, `t_final::Float64`: the first and the last time. `t_final` must be larger.
- `stops::Vector{Float64}`: the times at which a step must end, such as the edges of a pulse. Only
  the stops strictly between `t_start` and `t_final` are used.
- `Δt_save::Float64`: the time between saved states. `(t_final − t_start)/Δt_save` must be a whole
  number.
- `reltol::Float64`, `abstol::Float64`: the largest error allowed in each step, relative to each
  entry of the state (`reltol`), and in the units of the state (`abstol`).

### Returns
The named tuple `(t = t, x = x, evaluations = evaluations)`:
- `t::Vector{Float64}`: the saved times `t_start`, `t_start + Δt_save`, …, `t_final`.
- `x::Matrix{Float64}`: the saved states, one column per saved time, of size
  `length(x₀) × length(t)`. Column `k` is the state at `t[k]`, so `x[i, :]` is entry `i` of the
  state at every saved time.
- `evaluations::Int64`: the number of calls of `f!` that the solver made.

### Errors
Throws an `ArgumentError` if a time bound is not finite, if `t_final` is not larger than
`t_start`, or if `Δt_save` is not positive or does not divide the span into a whole number of
saves. Throws an `ErrorException` if the solver stops before `t_final`. The vector `x₀` is not
changed.

### Steps
1. Check the arguments, and list the save times (supplied).
2. Keep the stops that lie strictly inside the span (TODO).
3. Describe the problem for the solver (TODO).
4. Solve the problem with `Tsit5` (TODO).
5. Stop with an error if the solver did not reach `t_final` (TODO).
6. Copy the saved times and states into `t` and `x` (TODO).
7. Return the times, the states, and the number of calls of `f!` (TODO).

### Example
```julia
run = L15bMethods.mysolve(balances!, x₀, model; t_start = 0.0, t_final = 240.0,
    stops = [40.0, 52.0], Δt_save = 1.0, reltol = 1e-8, abstol = 1e-12);
run.x[:, end] # the state at 240 min
```
"""
function mysolve(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64,
    stops::Vector{Float64}, Δt_save::Float64, reltol::Float64, abstol::Float64)::NamedTuple

    # Step 1: check the arguments (supplied) -
    # the time bounds must be finite numbers -
    if isfinite(t_start) == false || isfinite(t_final) == false
        throw(ArgumentError("the time bounds t_start and t_final must be finite"));
    end

    # the run must move forward in time -
    if t_final <= t_start
        throw(ArgumentError("t_final must be larger than t_start"));
    end

    # the save step must be a positive number -
    if isfinite(Δt_save) == false || Δt_save <= 0.0
        throw(ArgumentError("the save step Δt_save must be finite and positive"));
    end

    # the save step must divide the span into a whole number of saves, at least one -
    number_of_saves = (t_final - t_start) / Δt_save; # the number of save steps, as a real number
    if round(number_of_saves) < 1 || abs(number_of_saves - round(number_of_saves)) > 1e-9
        throw(ArgumentError("(t_final − t_start)/Δt_save must be a positive whole number"));
    end

    # the save times. Each time comes from its index, so rounding errors do not add up, and the
    # last save time is exactly t_final -
    number_of_steps_saved = Int(round(number_of_saves)); # the number of save steps
    save_times = zeros(number_of_steps_saved + 1); # the save times, filled below
    for k ∈ 0:number_of_steps_saved # each save time
        save_times[k + 1] = t_start + k * Δt_save; # the k-th save time after t_start
    end
    save_times[end] = t_final; # the last save time is the end of the run

    # Step 2: keep the stops that lie strictly inside the span. A stop at t_start or t_final, or
    # outside the span, would add nothing to the solve -
    inside_stops = Float64[]; # the stops strictly between t_start and t_final, filled below
    for k ∈ 1:length(stops) # each stop
        # TODO: if stops[k] is larger than t_start and smaller than t_final, add it to inside_stops.
        # Hint: write an if-block whose condition joins two comparisons with &&. Inside it, call push!(inside_stops, stops[k]).
    end

    # Step 3: describe the problem: the right-hand side, the starting state, the time span, and the
    # parameters that the solver passes to f! -
    # TODO: store the problem in problem, made with OrdinaryDiffEq.ODEProblem.
    # Hint: ODEProblem takes four arguments in this order: f!, the starting state, the time span as the tuple (t_start, t_final), and p. Pass copy(x₀), so that the solver cannot change x₀.

    # Step 4: solve the problem with the Tsit5 method. The solver ends a step at each stop, saves the
    # state at each save time, and keeps the error of each step below the tolerances -
    # TODO: store the result in solution, from OrdinaryDiffEq.solve with problem and the method OrdinaryDiffEq.Tsit5().
    # Hint: the settings are keyword arguments after a semicolon: tstops (the stops to land on), saveat (the list of save times, save_times), reltol, and abstol.

    # Step 5: stop with an error if the solver did not reach t_final -
    # TODO: if solution.retcode is not OrdinaryDiffEq.ReturnCode.Success, call error("the ODE solver stopped early").
    # Hint: compare the two with != in the condition of an if-block.

    # Step 6: copy the saved times and states into t and x. solution.t[k] is the k-th saved time,
    # and solution.u[k] is the state at that time, a vector with one entry per entry of x₀ -
    # TODO: make t, a vector of zeros with one entry per saved time, and x, a matrix of zeros with one row per entry of the state and one column per saved time.
    # Hint: length(solution.t) is the number of saved times. zeros(n) makes a vector of n zeros, and zeros(m, n) makes an m × n matrix of zeros.

    # TODO: for each saved time k, store solution.t[k] in t[k], and copy solution.u[k] into column k of x.
    # Hint: inside the loop over k ∈ 1:number_of_times, write a second loop over the entries i ∈ 1:number_of_states, and set x[i, k] to entry i of solution.u[k].

    # Step 7: return the times, the states, and the number of calls of f! -
    # TODO: replace the error(...) line at the end of the function with a return of the named tuple (t = t, x = x, evaluations = ...).
    # Hint: the solver counts its calls of f! in solution.stats.nf.
    error("Complete mysolve in src/Compute.jl");
end

"""
    mystep(algorithm::ExplicitEulerMethod, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64) -> Vector{Float64}

Take one explicit Euler step of `dx/dt = f(x, p, t)` from the state `x` at the time `t`.

### The method
Explicit Euler moves along the slope at the start of the step for the whole step. The slope is
the rate vector `k₁` that `f!` computes at the state `x` and the time `t`. The next state is the
current state plus the step size times that slope.

### Arguments
- `algorithm::ExplicitEulerMethod`: the method tag. Julia runs this method of `mystep` when the
  tag is `ExplicitEulerMethod()`.
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`. It stores the rate of change of
  each entry of the state in `dx`.
- `x::Vector{Float64}`: the state at the start of the step.
- `p`: the parameters, passed to `f!` unchanged.
- `t::Float64`: the time at the start of the step.
- `Δt::Float64`: the step size.

### Returns
The state at `t + Δt`, a new vector with the same length as `x`. The vector `x` is not changed.

### Steps
1. Compute the slope `k₁` at the start of the step (TODO).
2. Return the state after one step along `k₁` (TODO).

### Example
On the test equation `dx/dt = λx` with `λ = -0.5`, the state `x = [1.0]`, and the step
`Δt = 0.1`, the slope is `k₁ = [-0.5]`, and the step returns `[0.95]`.
"""
function mystep(algorithm::ExplicitEulerMethod, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}

    # Step 1: the slope k₁ at the start of the step. f! stores the rates in its first argument -
    k₁ = zeros(length(x)); # the slope at the start of the step, filled by f!
    # TODO: call f! so that it stores the rates at the state x and the time t in k₁.
    # Hint: f! takes its arguments in the order (dx, x, p, t), and it returns nothing.

    # Step 2: move along that slope for the whole step -
    # TODO: replace the error(...) line at the end of the function with a return of the next state.
    # Hint: the next state is x plus Δt times k₁. Julia adds two vectors with +, and multiplies a vector by a number with *.
    error("Complete mystep for ExplicitEulerMethod in src/Compute.jl");
end

"""
    mystep(algorithm::RungeKutta4Method, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64) -> Vector{Float64}

Take one step of the classical fourth-order Runge–Kutta method (RK4) of `dx/dt = f(x, p, t)` from
the state `x` at the time `t`.

### The method
RK4 evaluates the slope four times in each step:
- `k₁` at the start of the step: the state `x` and the time `t`.
- `k₂` at the midpoint time `t + Δt/2`, at the trial state half a step from `x` along `k₁`.
- `k₃` at the midpoint time again, at the trial state half a step from `x` along `k₂`.
- `k₄` at the end time `t + Δt`, at the trial state a whole step from `x` along `k₃`.

The next state is a whole step from `x` along the weighted average of the four slopes. The weights
of `k₁`, `k₂`, `k₃`, and `k₄` are 1, 2, 2, and 1, and the average divides their weighted sum by 6.

### Arguments
- `algorithm::RungeKutta4Method`: the method tag. Julia runs this method of `mystep` when the tag
  is `RungeKutta4Method()`.
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`. It stores the rate of change of
  each entry of the state in `dx`.
- `x::Vector{Float64}`: the state at the start of the step.
- `p`: the parameters, passed to `f!` unchanged.
- `t::Float64`: the time at the start of the step.
- `Δt::Float64`: the step size.

### Returns
The state at `t + Δt`, a new vector with the same length as `x`. The vector `x` is not changed.

### Steps
1. Compute `k₁` at the start of the step (TODO).
2. Compute `k₂` at the midpoint, from half a step along `k₁` (TODO).
3. Compute `k₃` at the midpoint, from half a step along `k₂` (TODO).
4. Compute `k₄` at the end of the step, from a whole step along `k₃` (TODO).
5. Return the state after one step along the weighted average of the slopes (TODO).

### Example
On the test equation `dx/dt = λx` with `λ = -0.5`, the state `x = [1.0]`, and the step
`Δt = 0.1`, the slopes are `k₁ = [-0.5]`, `k₂ = [-0.4875]`, `k₃ = [-0.4878125]`, and
`k₄ = [-0.475609375]`. The step returns `[0.951229427…]`, which matches the exact value
`exp(-0.05) = 0.951229424…` to eight digits.
"""
function mystep(algorithm::RungeKutta4Method, f!::Function, x::Vector{Float64}, p, t::Float64, Δt::Float64)::Vector{Float64}

    # the four slopes, one vector each, filled by f! -
    k₁ = zeros(length(x)); # the slope at the start of the step
    k₂ = zeros(length(x)); # the first slope at the midpoint
    k₃ = zeros(length(x)); # the second slope at the midpoint
    k₄ = zeros(length(x)); # the slope at the end of the step

    # Step 1: k₁ at the start of the step -
    # TODO: call f! so that it stores the rates at the state x and the time t in k₁.
    # Hint: this is the same call as in the Euler step.

    # Step 2: k₂ at the midpoint time, at the trial state half a step from x along k₁ -
    # TODO: call f! so that it stores in k₂ the rates at that trial state and the midpoint time.
    # Hint: half a step along k₁ is x + (Δt / 2) * k₁. Pass this expression to f! in place of x, and pass t + Δt / 2 in place of t.

    # Step 3: k₃ at the midpoint time again, at the trial state half a step from x along k₂ -
    # TODO: call f! so that it stores in k₃ the rates at that trial state and the midpoint time.
    # Hint: this call is the Step 2 call, with k₂ in place of k₁ in the trial state.

    # Step 4: k₄ at the end time, at the trial state a whole step from x along k₃ -
    # TODO: call f! so that it stores in k₄ the rates at that trial state and the end time.
    # Hint: a whole step along k₃ is x + Δt * k₃, and the end time is t + Δt.

    # Step 5: move a whole step along the weighted average of the four slopes -
    # TODO: replace the error(...) line at the end of the function with a return of the next state.
    # Hint: the weights of k₁, k₂, k₃, and k₄ are 1, 2, 2, and 1, and the weighted average divides their weighted sum by 6. The next state is x plus Δt times that average.
    error("Complete mystep for RungeKutta4Method in src/Compute.jl");
end

"""
    myintegrate(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64,
        algorithm::AbstractFixedStepAlgorithm) -> NamedTuple

Solve `dx/dt = f(x, p, t)` from `t_start` to `t_final` in equal steps of size `Δt`, with one call of
`mystep` per step.

### How the loop works
The grid times are `t_start`, `t_start + Δt`, …, `t_final`. The loop stores `x₀` in column 1 of
`x`. Pass `k` takes one step from the state in column `k`, at the time `t[k]`, and stores the
result in column `k + 1`. Julia picks the method of `mystep` by the type of `algorithm`, so the same
loop runs explicit Euler and RK4.

### Arguments
- `f!::Function`: the right-hand side, called as `f!(dx, x, p, t)`.
- `x₀::Vector{Float64}`: the state at `t_start`.
- `p`: the parameters, passed to `f!` unchanged.
- `t_start::Float64`, `t_final::Float64`: the first and the last time. `t_final` must be larger.
- `Δt::Float64`: the step size. `(t_final − t_start)/Δt` must be a whole number.
- `algorithm::AbstractFixedStepAlgorithm`: the method tag, `ExplicitEulerMethod()` or
  `RungeKutta4Method()`.

### Returns
The named tuple `(t = t, x = x, evaluations = evaluations)`:
- `t::Vector{Float64}`: the grid times. `t[k]` is `t_start + (k − 1)Δt`.
- `x::Matrix{Float64}`: the states, one column per grid time, of size `length(x₀) × length(t)`.
  Column `k` is the state at `t[k]`, so `x[i, :]` is entry `i` of the state at every grid time.
- `evaluations::Int64`: the number of calls of `f!`, which is the number of steps times the calls
  in one step of the method (one for explicit Euler, four for RK4).

### Errors
Throws an `ArgumentError` if `Δt` is not positive, if a time bound is not finite, if `t_final` is
not larger than `t_start`, or if the span is not a whole number of steps. The vector `x₀` is not
changed.

### Steps
1. Check the arguments (supplied).
2. Make `t` and `x`, and store the starting time and state (TODO).
3. Take the steps (TODO).
4. Return the times, the states, and the number of calls of `f!` (TODO).

### Example
```julia
run = L15bMethods.myintegrate(balances!, x₀, model; t_start = 0.0, t_final = 120.0, Δt = 1.0,
    algorithm = ExplicitEulerMethod());
run.x[:, end] # the Euler state at 120 min
```
"""
function myintegrate(f!::Function, x₀::Vector{Float64}, p; t_start::Float64, t_final::Float64, Δt::Float64,
    algorithm::AbstractFixedStepAlgorithm)::NamedTuple

    # Step 1: check the arguments (supplied) -
    # the step size must be a positive number -
    if isfinite(Δt) == false || Δt <= 0.0
        throw(ArgumentError("the step size Δt must be finite and positive"));
    end

    # the time bounds must be finite numbers -
    if isfinite(t_start) == false || isfinite(t_final) == false
        throw(ArgumentError("the time bounds t_start and t_final must be finite"));
    end

    # the run must move forward in time -
    if t_final <= t_start
        throw(ArgumentError("t_final must be larger than t_start"));
    end

    # the step must divide the span into a whole number of steps, at least one -
    steps_real = (t_final - t_start) / Δt; # the number of steps, as a real number
    nearest_step_count = round(steps_real); # the nearest whole number of steps
    if nearest_step_count < 1 || abs(steps_real - nearest_step_count) > 1e-9
        throw(ArgumentError("(t_final − t_start)/Δt must be a positive whole number of steps"));
    end

    # the number of steps must fit in an integer -
    if nearest_step_count >= typemax(Int)
        throw(ArgumentError("the step size Δt is too small for this span"));
    end
    number_of_steps = Int(nearest_step_count); # the number of steps
    number_of_states = length(x₀); # the number of entries of the state

    # Step 2: make the times and the states, and store the starting time and state -
    # TODO: make t, a vector of zeros with one entry per grid time, and x, a matrix of zeros with one row per entry of the state and one column per grid time. Then store t_start in t[1], and x₀ in column 1 of x.
    # Hint: the grid has number_of_steps + 1 times. The assignment x[:, 1] = x₀ copies x₀ into column 1.

    # Step 3: take the steps. Each time comes from its index, so rounding errors do not add up -
    # TODO: for k ∈ 1:number_of_steps, store t_start + k * Δt in t[k + 1], and store in column k + 1 of x the state one step after column k.
    # Hint: mystep takes its arguments in the order (algorithm, f!, x, p, t, Δt). Pass column k of x, which is x[:, k], and the time t[k].

    # Step 4: return the times, the states, and the number of calls of f! -
    evaluations = number_of_steps * evaluations_per_step(algorithm); # one call per Euler step, four per RK4 step
    # TODO: replace the error(...) line at the end of the function with a return of the named tuple (t = t, x = x, evaluations = evaluations).
    # Hint: a named tuple is written (name = value, ...), with a comma between the entries.
    error("Complete myintegrate in src/Compute.jl");
end

end # module L15bMethods
