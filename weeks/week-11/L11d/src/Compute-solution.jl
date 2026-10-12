# =============================================================================
# CHEME 5800 | L11d reference solution: value iteration
# =============================================================================
# The completed mysolve(...). Apart from this header, the TODO comments, and
# the completed lines, it matches the student file, Compute.jl, and it uses the
# same module name, so either file can be loaded in place of the other. The
# notebook has no other exercise answers.
# =============================================================================
module L11dValueIteration

import VLDataScienceMachineLearningPackage: MyMDPProblemModel, MyValueIterationModel, lookahead

export mysolve

"""
    mysolve(model::MyValueIterationModel, problem::MyMDPProblemModel; ϵ::Float64 = 1e-6) -> NamedTuple

Solve the MDP `problem` by value iteration with a convergence check, the algorithm from the
L11c lecture.

Each pass over the states, a sweep, replaces the value of every state `s` with its Bellman
backup, the largest value of `R(s,a) + γ⋅Σ T(s′|s,a)⋅U(s′)` over the actions `a`. The loop
stops at the first sweep that changes no value by more than `ϵ`, or after `model.k_max`
sweeps, whichever comes first; in the second case it also logs a warning. The states of
`problem` are numbered `1, 2, …, |𝒮|`.

### Arguments
- `model::MyValueIterationModel`: the value iteration model. Its field `k_max` is the
  maximum number of sweeps, at least 1.
- `problem::MyMDPProblemModel`: the MDP, with state space `𝒮`, action space `𝒜`,
  transition array `T`, reward matrix `R`, and discount factor `γ`.
- `ϵ::Float64 = 1e-6`: the convergence tolerance, positive.

### Returns
A `NamedTuple` with the fields:
- `U::Array{Float64,1}`: the value of each state after the last sweep, `|𝒮|` entries.
- `iterations::Int64`: the number of sweeps, `k + 1` for the iteration counter `k` of the
  L11c algorithm when the loop stops.
- `converged::Bool`: `true` if the last sweep changed no value by more than `ϵ`; `false` if
  the loop stopped because it reached `k_max` sweeps without meeting the tolerance.

### Errors
Throws an `ArgumentError` if `model.k_max` is less than 1 or `ϵ` is not positive.

### Example
```julia
value_iteration_model = MyValueIterationModel(1000); # at most 1000 sweeps
solution = L11dValueIteration.mysolve(value_iteration_model, m, ϵ = 1e-6);
solution.U, solution.iterations, solution.converged
```
"""
function mysolve(model::MyValueIterationModel, problem::MyMDPProblemModel; ϵ::Float64 = 1e-6)::NamedTuple

    # Check the arguments; this part is complete -
    if model.k_max < 1 || ϵ <= 0
        throw(ArgumentError("k_max must be at least 1, and ϵ must be positive"))
    end

    # Initialize; this part is complete -
    k_max = model.k_max; # the maximum number of sweeps
    number_of_states = length(problem.𝒮);
    U = zeros(number_of_states); # Uₖ(s), the values before this sweep: U₀(s) = 0 for every state
    U_new = zeros(number_of_states); # Uₖ₊₁(s), the values after this sweep
    k = 0; # the iteration counter
    converged = false;

    # Main loop: one sweep over all the states each pass -
    while (converged == false)

        # Step 1: the Bellman backup of every state -
        for s ∈ problem.𝒮
            # TODO 1: the Bellman backup of state s -
            U_new[s] = maximum(lookahead(problem, U, s, a) for a ∈ problem.𝒜);
        end

        # Step 2: check whether to stop -
        # TODO 2: the largest change in any value during this sweep -
        Δ = maximum(abs.(U_new .- U));
        if isnan(Δ) # this part is complete: a blank TODO leaves NaN, "not a number", behind
            throw(ErrorException("Oooops! The `mysolve(...)` function is not implemented yet - " *
                                 "we'd better fix that. Complete TODO 1 through TODO 3."))
        end
        if (Δ ≤ ϵ)
            converged = true; # the tolerance is met: stop, and return Uₖ₊₁
        elseif (k + 1 ≥ k_max)
            @warn "Value iteration stopped after k_max = $(k_max) sweeps without meeting the tolerance ϵ = $(ϵ)."
            break; # the iteration limit: stop, and return Uₖ₊₁ with converged = false
        else
            # Step 3: increment the iteration counter, so the next sweep starts from Uₖ₊₁ -
            k = k + 1;
            # TODO 3: copy the new values into U -
            U .= U_new;
        end
    end

    # We get here when the loop stops, after k + 1 sweeps. This part is complete -
    return (U = U_new, iterations = k + 1, converged = converged);
end

end # module L11dValueIteration
