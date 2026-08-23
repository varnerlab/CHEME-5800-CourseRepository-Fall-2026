module Week14Core

using LinearAlgebra

export eigenpair_residual, explicit_euler_stable, power_iteration

"""Return ``||A * v - lambda * v||_2`` for a proposed eigenpair."""
function eigenpair_residual(
    A::AbstractMatrix,
    value::Number,
    vector::AbstractVector,
)::Float64
    size(A, 1) == size(A, 2) || throw(ArgumentError("A must be square"))
    length(vector) == size(A, 2) || throw(DimensionMismatch("vector length must match A"))
    return Float64(norm(A * vector - value * vector))
end

"""
    power_iteration(A, initial; tolerance=1e-10, max_iterations=1_000)

Estimate the dominant right eigenpair of a real square matrix by repeated matrix-vector
multiplication. The result reports the Rayleigh-quotient eigenvalue estimate, a unit-norm
eigenvector, its residual, the iteration count, and whether the requested tolerance was met.
"""
function power_iteration(
    A::AbstractMatrix{<:Real},
    initial::AbstractVector{<:Real};
    tolerance::Real = 1e-10,
    max_iterations::Integer = 1_000,
)
    size(A, 1) == size(A, 2) || throw(ArgumentError("A must be square"))
    length(initial) == size(A, 2) || throw(DimensionMismatch("initial length must match A"))
    isempty(initial) && throw(ArgumentError("initial must not be empty"))
    all(isfinite, A) || throw(ArgumentError("A must contain only finite values"))
    all(isfinite, initial) || throw(ArgumentError("initial must contain only finite values"))
    tolerance > 0 || throw(ArgumentError("tolerance must be positive"))
    max_iterations > 0 || throw(ArgumentError("max_iterations must be positive"))

    matrix = Matrix{Float64}(A)
    vector = Vector{Float64}(initial)
    initial_norm = norm(vector)
    initial_norm > 0 || throw(ArgumentError("initial must have nonzero norm"))
    vector ./= initial_norm

    value = dot(vector, matrix * vector)
    residual = eigenpair_residual(matrix, value, vector)

    for iteration in 1:max_iterations
        candidate = matrix * vector
        candidate_norm = norm(candidate)
        candidate_norm > eps(Float64) || throw(ArgumentError("A maps the iterate to zero"))
        vector = candidate ./ candidate_norm
        value = dot(vector, matrix * vector)
        residual = eigenpair_residual(matrix, value, vector)

        if residual <= tolerance
            return (
                value = value,
                vector = vector,
                residual_norm = residual,
                iterations = iteration,
                converged = true,
            )
        end
    end

    return (
        value = value,
        vector = vector,
        residual_norm = residual,
        iterations = Int(max_iterations),
        converged = false,
    )
end

"""Return whether explicit Euler's amplification factor satisfies `abs(1 + step * value) <= 1`."""
function explicit_euler_stable(value::Number, step::Real)::Bool
    step > 0 || throw(ArgumentError("step must be positive"))
    isfinite(step) || throw(ArgumentError("step must be finite"))
    isfinite(value) || throw(ArgumentError("value must be finite"))
    return abs(1 + step * value) <= 1
end

end
