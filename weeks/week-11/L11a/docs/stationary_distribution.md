# `stationary_distribution(...)`

```julia
L11aMarkov.stationary_distribution(P::Array{Float64,2};
    maxcount::Int = 100, ϵ::Float64 = 0.1) -> Array{Float64,2}
```

Compute a stationary-distribution estimate by repeatedly multiplying a row
distribution by `P`, starting from the uniform distribution.

- `P`: a square row-stochastic matrix for a finite irreducible, aperiodic chain.
  Entries are probabilities; row `i` describes the next state given state `i`.
- `maxcount`: maximum number of updates, at least one.
- `ϵ`: positive, dimensionless tolerance on the 1-norm of the change.

Return a `1 × N` matrix with the last distribution. Stop when the change is at most
`ϵ` or the update limit is reached. Reaching the limit before meeting the tolerance
logs a warning and returns the last estimate.

See the docstring and implementation in [src/Markov.jl](../src/Markov.jl), and the
calculation in the [Markov-model example](../CHEME-5800-L11a-Example-MarkovModels-Fall-2026.ipynb).
