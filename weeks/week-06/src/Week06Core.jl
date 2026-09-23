module Week06Core

import LinearAlgebra: eigvals, norm

export spectral_radius, stationary_solve

function spectral_radius(matrix::AbstractMatrix{<:Real})::Float64
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch("matrix must be square"))
    return maximum(abs, eigvals(Float64.(matrix)); init = 0.0)
end

"""Run Jacobi, Gauss–Seidel, or SOR and retain residual history."""
function stationary_solve(A::AbstractMatrix{<:Real}, b::AbstractVector{<:Real};
    method::Symbol = :jacobi, omega::Real = 1.0, tolerance::Real = 1e-10,
    max_iterations::Integer = 10_000, initial = zeros(length(b)))
    n, m = size(A)
    n == m == length(b) || throw(DimensionMismatch("A must be square and match b"))
    length(initial) == n || throw(DimensionMismatch("initial guess must match b"))
    method in (:jacobi, :gauss_seidel, :sor) || throw(ArgumentError("unknown stationary method: $(method)"))
    0 < omega < 2 || throw(ArgumentError("omega must lie in (0,2)"))
    tolerance > 0 || throw(ArgumentError("tolerance must be positive"))
    max_iterations > 0 || throw(ArgumentError("max_iterations must be positive"))
    matrix, rhs = Float64.(A), Float64.(b)
    all(index -> matrix[index, index] != 0, 1:n) || throw(ArgumentError("diagonal entries must be nonzero"))
    x = Float64.(initial)
    residuals = Float64[norm(matrix * x - rhs)]
    for iteration in 1:max_iterations
        previous = copy(x)
        if method == :jacobi
            for i in 1:n
                x[i] = (rhs[i] - sum(matrix[i, j] * previous[j] for j in 1:n if j != i)) / matrix[i, i]
            end
        else
            for i in 1:n
                left = sum(matrix[i, j] * x[j] for j in 1:(i - 1); init = 0.0)
                right = sum(matrix[i, j] * previous[j] for j in (i + 1):n; init = 0.0)
                candidate = (rhs[i] - left - right) / matrix[i, i]
                x[i] = method == :sor ? (1 - omega) * previous[i] + omega * candidate : candidate
            end
        end
        push!(residuals, norm(matrix * x - rhs))
        residuals[end] <= tolerance && return (solution = x, residuals = residuals,
            iterations = iteration, converged = true)
    end
    return (solution = x, residuals = residuals, iterations = Int(max_iterations), converged = false)
end

end
