module L11aMarkov

using LinearAlgebra: norm # the 1-norm of the distribution update

export stationary_distribution

"""
    stationary_distribution(P::Array{Float64,2}; maxcount::Int = 100, ϵ::Float64 = 0.1) -> Array{Float64,2}

Estimate the stationary distribution of a finite ergodic Markov chain by power iteration.
Start from the uniform distribution and repeatedly compute `π′ = π * P`.

### Arguments
- `P::Array{Float64,2}`: the `N × N` row-stochastic transition matrix. Entries are
  nonnegative probabilities, each row sums to one, and the chain is irreducible
  and aperiodic. Row `i` describes the next state given current state `i`.
- `maxcount::Int = 100`: the maximum number of updates, at least one.
- `ϵ::Float64 = 0.1`: a positive tolerance on `norm(π′ - π, 1)`; probabilities and
  the tolerance are dimensionless.

### Returns
A `1 × N` matrix containing the distribution after the last update. Stop when the
change is at most `ϵ`, or after `maxcount` updates. If the iteration limit is reached
before the tolerance is met, log a warning and return the last estimate.
"""
function stationary_distribution(P::Array{Float64,2};
        maxcount::Int = 100,
        ϵ::Float64 = 0.1)::Array{Float64,2}

    # Initialize -
    counter = 1;
    is_ok_to_stop = false;
    N = size(P, 1); # number of states
    π₀ = ones(Float64, N) ./ N;
    π = reshape(π₀, 1, N); # the current distribution is a row vector

    # Update until ||π′ - π||₁ ≤ ϵ or the iteration limit is reached -
    while is_ok_to_stop == false
        π′ = π * P;
        change = norm(π′ - π, 1);
        if change <= ϵ || counter >= maxcount
            is_ok_to_stop = true;
            if change > ϵ
                @warn "Maximum iteration count reached before convergence."
            end
        end
        π = π′;
        counter += 1;
    end

    return π;
end

end # module L11aMarkov
