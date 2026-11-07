# ------------------------------------------------------------------------------------------------ #
# Solvers.jl
#
# Two kinds of solvers share the name `solve` in this file:
#
# 1. Iterative solvers for a square linear system A⋅x = b: the Jacobi, Gauss-Seidel, and successive
#    over-relaxation (SOR) methods. They are the methods of the week-06 L6c notebooks (the general
#    iterative method lecture, the Jacobi, Gauss-Seidel, and SOR algorithm notebooks, and the
#    iterative solvers example). The week-06 L6d lab calls them to solve the oxygen
#    diffusion-reaction system, and compares them with the student's own Jacobi function.
#    Each method starts from a guess x⁽⁰⁾ and repeats a residual correction:
#        r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾,    M⋅d⁽ᵏ⁾ = r⁽ᵏ⁾,    x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾,
#    where A = D + L + U (D the diagonal of A, L the entries below the diagonal, U the entries
#    above it) and the matrix M sets the method: M = D (Jacobi), M = D + L (Gauss-Seidel), or
#    M = D/ω + L (SOR, with relaxation factor ω).
#
# 2. A linear-programming solver, used by the week-05 L5c fruit-problem example. It maximizes
#    cᵀx subject to linear constraints and bounds on x, with the JuMP modeling package and the
#    GLPK solver.
#
# Public functions:
#   solve(A, b, xₒ; algorithm, ϵ, maxiterations, ω)   solves A⋅x = b iteratively and returns every
#                                                     iterate, in a dictionary called the archive
#   solve(problem::MyLinearProgrammingProblemModel; constraints)
#                                                     solves a linear program and returns the
#                                                     optimal x, objective value, and solver status
#
# Private functions (the leading underscore marks a function for use inside this package only):
#   _solve(..., algorithm::JacobiMethod; ...)                     the Jacobi method
#   _solve(..., algorithm::GaussSeidelMethod; ...)                the Gauss-Seidel method
#   _solve(..., algorithm::SuccessiveOverRelaxationMethod; ...)   the SOR method
#
# One function name with several methods: Julia picks the method whose argument types match the
# call. This is called multiple dispatch. The types JacobiMethod, GaussSeidelMethod, and
# SuccessiveOverRelaxationMethod (in Types.jl) hold no data; they only select the method.
#
# The functions diag, Diagonal, LowerTriangular, tril, and norm come from the LinearAlgebra
# standard library. Model, @variable, @objective, @constraints, optimize!, is_solved_and_feasible,
# value, objective_value, and termination_status come from JuMP, and GLPK.Optimizer from GLPK.
# VLDataScienceMachineLearningPackage.jl loads all three packages.
# ------------------------------------------------------------------------------------------------ #

"""
    _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::JacobiMethod;
        ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number
        -> Dict{Int,Array{Float64,1}}

Solve the linear system `A⋅x = b` with the Jacobi method, and keep every iterate. The public
`solve` function calls this method when `algorithm = JacobiMethod()`.

We write `A = D + L + U`, where `D` holds the diagonal entries of `A`, `L` the entries below the
diagonal, and `U` the entries above it. At iteration `k`, we compute the residual
`r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾`. If we continue, we compute the correction `d⁽ᵏ⁾` from `D⋅d⁽ᵏ⁾ = r⁽ᵏ⁾`, that is,
`dᵢ⁽ᵏ⁾ = rᵢ⁽ᵏ⁾/aᵢᵢ` for each row `i`, where `aᵢᵢ` is the diagonal entry of row `i`. The next iterate
is `x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾`. Every new component uses only values from the previous iterate.

At each iteration we check three stopping tests, in this order:
1. the residual norm `‖r⁽ᵏ⁾‖₂` is below `ϵ`: the method has converged;
2. we have made `maxiterations` corrections: we print a warning that the tolerance was not met;
3. the residual norm is above `10¹⁰`: we print a warning that the iteration appears to diverge.
We test convergence first. So an initial guess that already meets the tolerance needs no
correction, and an iterate that meets the tolerance after the last allowed correction counts as
converged.

### Arguments
- `A::AbstractMatrix{T}`: the `n × n` system matrix. Every diagonal entry must be nonzero.
- `b::AbstractVector{T}`: the right-hand side, a vector of length `n`.
- `xₒ::AbstractVector{T}`: the initial guess `x⁽⁰⁾`, a vector of length `n`.
- `algorithm::JacobiMethod`: selects this method. The value `JacobiMethod()` holds no data.
- `ϵ::Float64 = 1e-6`: the residual tolerance: we stop when `‖r⁽ᵏ⁾‖₂ < ϵ`.
- `maxiterations::Int64 = 1000`: the correction limit, the most corrections we make.
- `ω::Float64 = 1.0`: not used by the Jacobi method. It is here so the three methods accept the
  same keyword arguments.

`where T <: Number` means that `T` stands for one number type, such as `Float64`, and that `A`,
`b`, and `xₒ` must all have that same element type.

### Returns
- `Dict{Int,Array{Float64,1}}`: the archive of iterates. Key `0` holds the initial guess, and key
  `k` holds the iterate after `k` corrections. The largest key is the number of corrections made,
  and it is never larger than `maxiterations`.

### Throws
- an `ErrorException` if a diagonal entry of `A` is zero, because the correction divides by each
  diagonal entry.
"""
function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::JacobiMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # the correction counter: the number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # archive[k] holds the iterate x⁽ᵏ⁾; we keep the initial guess and every iterate
    archive[0] = copy(xₒ); # key 0 holds a copy of the initial guess, so the caller's vector is never changed

    # Prepare the correction matrix. The Jacobi correction divides by each diagonal entry, so we
    # stop with an error if any diagonal entry is zero -
    if (any(diag(A) .== 0.0)) # diag(A) is the vector of diagonal entries; .== compares each entry with zero (the dot applies == entry by entry); any(...) is true if at least one comparison is true
        error("Matrix A has zero(s) on the diagonal, cannot proceed with Jacobi Method.")
    end
    D = Diagonal(diag(A)); # D: the diagonal part of A, stored as a Diagonal matrix (only the diagonal entries are kept)

    # Iterate: one correction each pass. The loop has no end condition of its own; it ends only
    # at one of the return statements below -
    while true
        x = archive[k]; # the current iterate x⁽ᵏ⁾; we read it without changing the archive
        r = b - A*x; # the residual r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾
        current_residual = norm(r); # the Euclidean norm ‖r⁽ᵏ⁾‖₂, the square root of the sum of squared entries

        # Check the three stopping tests. We test convergence before the correction limit, so an
        # iterate that meets the tolerance after the last allowed correction counts as converged -
        if (current_residual < ϵ)
            return archive; # converged: return every iterate
        elseif (k >= maxiterations)
            @warn "Jacobi method did not converge within $maxiterations iterations. Final residual: $current_residual" # @warn prints a warning; $name inside the string inserts the value of name
            return archive; # correction limit reached: return the iterates so far
        elseif (current_residual > 1e10) # divergence safeguard: we treat a residual above 10¹⁰ as a sign that the iteration diverges
            @warn "Jacobi method appears to be diverging. Residual: $current_residual"
            return archive; # diverging: return the iterates so far
        end

        # Compute the correction d⁽ᵏ⁾ and store the next iterate x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾ -
        d = D \ r; # the backslash solves D⋅d = r; for a diagonal D this divides each rᵢ by aᵢᵢ, without forming an inverse
        k += 1; # one more completed correction (k += 1 means k = k + 1)
        archive[k] = x + d; # key k records the iterate after exactly k corrections
    end
end

"""
    _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::GaussSeidelMethod;
        ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number
        -> Dict{Int,Array{Float64,1}}

Solve the linear system `A⋅x = b` with the Gauss-Seidel method, and keep every iterate. The
public `solve` function calls this method when `algorithm = GaussSeidelMethod()`.

We write `A = D + L + U`, where `D` holds the diagonal entries of `A`, `L` the entries below the
diagonal, and `U` the entries above it. At iteration `k`, we compute the residual
`r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾`. If we continue, we compute the correction `d⁽ᵏ⁾` from
`(D + L)⋅d⁽ᵏ⁾ = r⁽ᵏ⁾`, and set `x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾`. Because `D + L` is lower triangular, we
solve for `d⁽ᵏ⁾` by forward substitution: row 1 gives `d₁`, row 2 then gives `d₂` using `d₁`, and so
on. This is the same as updating the components in order and using each new value as soon as it
is available.

At each iteration we check three stopping tests, in this order:
1. the residual norm `‖r⁽ᵏ⁾‖₂` is below `ϵ`: the method has converged;
2. we have made `maxiterations` corrections: we print a warning that the tolerance was not met;
3. the residual norm is above `10¹⁰`: we print a warning that the iteration appears to diverge.

### Arguments
- `A::AbstractMatrix{T}`: the `n × n` system matrix. Every diagonal entry must be nonzero.
- `b::AbstractVector{T}`: the right-hand side, a vector of length `n`.
- `xₒ::AbstractVector{T}`: the initial guess `x⁽⁰⁾`, a vector of length `n`.
- `algorithm::GaussSeidelMethod`: selects this method. The value `GaussSeidelMethod()` holds no
  data.
- `ϵ::Float64 = 1e-6`: the residual tolerance: we stop when `‖r⁽ᵏ⁾‖₂ < ϵ`.
- `maxiterations::Int64 = 1000`: the correction limit, the most corrections we make.
- `ω::Float64 = 1.0`: not used by the Gauss-Seidel method. It is here so the three methods accept
  the same keyword arguments.

### Returns
- `Dict{Int,Array{Float64,1}}`: the archive of iterates. Key `0` holds the initial guess, and key
  `k` holds the iterate after `k` corrections. The largest key is the number of corrections made,
  and it is never larger than `maxiterations`.

### Throws
- an `ErrorException` if a diagonal entry of `A` is zero. A lower triangular matrix such as
  `D + L` can be solved exactly when its diagonal has no zeros.
"""
function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::GaussSeidelMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # the correction counter: the number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # archive[k] holds the iterate x⁽ᵏ⁾; we keep the initial guess and every iterate
    archive[0] = copy(xₒ); # key 0 holds a copy of the initial guess, so the caller's vector is never changed

    # Prepare the correction matrix D + L. We stop with an error if any diagonal entry is zero -
    if (any(diag(A) .== 0.0)) # a triangular matrix is invertible exactly when its diagonal has no zeros; .== compares each diagonal entry with zero, and any(...) is true if one of them is zero
        error("Matrix D+L is not invertible, cannot proceed with Gauss-Seidel Method.")
    end
    C = LowerTriangular(A); # C = D + L, the diagonal and strictly lower triangular entries of A; LowerTriangular ignores the entries above the diagonal

    # Iterate: one correction each pass. The loop has no end condition of its own; it ends only
    # at one of the return statements below -
    while true
        x = archive[k]; # the current iterate x⁽ᵏ⁾; we read it without changing the archive
        r = b - A*x; # the residual r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾
        current_residual = norm(r); # the Euclidean norm ‖r⁽ᵏ⁾‖₂, the square root of the sum of squared entries

        # Check the three stopping tests. We test convergence before the correction limit, so an
        # iterate that meets the tolerance after the last allowed correction counts as converged -
        if (current_residual < ϵ)
            return archive; # converged: return every iterate
        elseif (k >= maxiterations)
            @warn "Gauss-Seidel method did not converge within $maxiterations iterations. Final residual: $current_residual" # @warn prints a warning; $name inside the string inserts the value of name
            return archive; # correction limit reached: return the iterates so far
        elseif (current_residual > 1e10) # divergence safeguard: we treat a residual above 10¹⁰ as a sign that the iteration diverges
            @warn "Gauss-Seidel method appears to be diverging. Residual: $current_residual"
            return archive; # diverging: return the iterates so far
        end

        # Compute the correction d⁽ᵏ⁾ and store the next iterate x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾ -
        d = C \ r; # the backslash solves (D + L)⋅d = r by forward substitution, without forming an inverse
        k += 1; # one more completed correction (k += 1 means k = k + 1)
        archive[k] = x + d; # key k records the iterate after exactly k corrections
    end
end

"""
    _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::SuccessiveOverRelaxationMethod;
        ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number
        -> Dict{Int,Array{Float64,1}}

Solve the linear system `A⋅x = b` with the successive over-relaxation (SOR) method, and keep every
iterate. The public `solve` function calls this method when
`algorithm = SuccessiveOverRelaxationMethod()`.

SOR adds a relaxation factor `ω` to the Gauss-Seidel method. We write `A = D + L + U`, where `D`
holds the diagonal entries of `A`, `L` the entries below the diagonal, and `U` the entries above it.
At iteration `k`, we compute the residual `r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾`. If we continue, we compute the
correction `d⁽ᵏ⁾` from `(D + ω⋅L)⋅d⁽ᵏ⁾ = ω⋅r⁽ᵏ⁾` by forward substitution, and set
`x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾`. This is the splitting matrix `M_ω = D/ω + L` of the L6c SOR notebook.
Written one component at a time, as in the L6c SOR notebook, each sweep updates the components in
order. With `0 < ω < 1` each component takes a partial step toward the value from its row equation
(under-relaxation). `ω = 1` gives the Gauss-Seidel method. With `1 < ω < 2` each component moves
beyond that value (over-relaxation).

At each iteration we check three stopping tests, in this order:
1. the residual norm `‖r⁽ᵏ⁾‖₂` is below `ϵ`: the method has converged;
2. we have made `maxiterations` corrections: we print a warning that the tolerance was not met;
3. the residual norm is above `10¹⁰`: we print a warning that the iteration appears to diverge.

### Arguments
- `A::AbstractMatrix{T}`: the `n × n` system matrix. Every diagonal entry must be nonzero.
- `b::AbstractVector{T}`: the right-hand side, a vector of length `n`.
- `xₒ::AbstractVector{T}`: the initial guess `x⁽⁰⁾`, a vector of length `n`.
- `algorithm::SuccessiveOverRelaxationMethod`: selects this method. The value
  `SuccessiveOverRelaxationMethod()` holds no data.
- `ϵ::Float64 = 1e-6`: the residual tolerance: we stop when `‖r⁽ᵏ⁾‖₂ < ϵ`.
- `maxiterations::Int64 = 1000`: the correction limit, the most corrections we make.
- `ω::Float64 = 1.0`: the relaxation factor. The L6c notebooks choose it between 0 and 2; this
  function does not check the value.

### Returns
- `Dict{Int,Array{Float64,1}}`: the archive of iterates. Key `0` holds the initial guess, and key
  `k` holds the iterate after `k` corrections. The largest key is the number of corrections made,
  and it is never larger than `maxiterations`.

### Throws
- an `ErrorException` if a diagonal entry of `A` is zero. The matrix `D + ω⋅L` has the diagonal of
  `A`, so it can be solved exactly when that diagonal has no zeros.
"""
function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::SuccessiveOverRelaxationMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # the correction counter: the number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # archive[k] holds the iterate x⁽ᵏ⁾; we keep the initial guess and every iterate
    archive[0] = copy(xₒ); # key 0 holds a copy of the initial guess, so the caller's vector is never changed

    # Prepare the correction matrix D + ω⋅L. We stop with an error if any diagonal entry is zero -
    if (any(diag(A) .== 0.0)) # D + ω*L has the diagonal of A, so it is invertible exactly when that diagonal has no zeros; .== compares each diagonal entry with zero, and any(...) is true if one of them is zero
        error("Matrix D + ω*L is not invertible, cannot proceed with Successive Over-Relaxation Method.")
    end
    D = Diagonal(diag(A)); # D: the diagonal part of A, stored as a Diagonal matrix
    L = tril(A,-1); # L: the entries of A strictly below the diagonal (tril keeps the lower triangle; the -1 also drops the diagonal)
    C = LowerTriangular(D + ω*L); # C = D + ω⋅L, the relaxed lower triangular correction matrix

    # Iterate: one correction each pass. The loop has no end condition of its own; it ends only
    # at one of the return statements below -
    while true
        x = archive[k]; # the current iterate x⁽ᵏ⁾; we read it without changing the archive
        r = b - A*x; # the residual r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾
        current_residual = norm(r); # the Euclidean norm ‖r⁽ᵏ⁾‖₂, the square root of the sum of squared entries

        # Check the three stopping tests. We test convergence before the correction limit, so an
        # iterate that meets the tolerance after the last allowed correction counts as converged -
        if (current_residual < ϵ)
            return archive; # converged: return every iterate
        elseif (k >= maxiterations)
            @warn "SOR method did not converge within $maxiterations iterations. Final residual: $current_residual" # @warn prints a warning; $name inside the string inserts the value of name
            return archive; # correction limit reached: return the iterates so far
        elseif (current_residual > 1e10) # divergence safeguard: we treat a residual above 10¹⁰ as a sign that the iteration diverges
            @warn "SOR method appears to be diverging. Residual: $current_residual"
            return archive; # diverging: return the iterates so far
        end

        # Compute the correction d⁽ᵏ⁾ and store the next iterate x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾ -
        d = ω * (C \ r); # the backslash solves (D + ω⋅L)⋅y = r by forward substitution; then d = ω⋅y solves (D + ω⋅L)⋅d = ω⋅r, which matches M_ω = D/ω + L
        k += 1; # one more completed correction (k += 1 means k = k + 1)
        archive[k] = x + d; # key k records the iterate after exactly k corrections
    end
end

# -- PUBLIC METHODS BELOW HERE ---------------------------------------------------------------------------------------------------------------------------------------- #

"""
    solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T};
        algorithm::AbstractLinearSolverAlgorithm = JacobiMethod(), ϵ::Float64 = 1e-6,
        maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number -> Dict{Int,Array{Float64,1}}

Solve the linear system `A⋅x = b` with an iterative method, and return every iterate.

Each method starts from the initial guess `x⁽⁰⁾ = xₒ` and repeats a residual correction. At
iteration `k`, we compute the residual `r⁽ᵏ⁾ = b − A⋅x⁽ᵏ⁾`, solve `M⋅d⁽ᵏ⁾ = r⁽ᵏ⁾` for the
correction `d⁽ᵏ⁾`, and set `x⁽ᵏ⁺¹⁾ = x⁽ᵏ⁾ + d⁽ᵏ⁾`. We write `A = D + L + U`, where `D` holds the
diagonal entries of `A`, `L` the entries below the diagonal, and `U` the entries above it. The
`algorithm` argument chooses the matrix `M`:
- `JacobiMethod()`: `M = D`;
- `GaussSeidelMethod()`: `M = D + L`;
- `SuccessiveOverRelaxationMethod()`: `M = D/ω + L`, with relaxation factor `ω`.

We check the residual before the correction limit. So an initial guess with `‖r⁽⁰⁾‖₂ < ϵ` takes
zero corrections, and an iterate that meets the tolerance after the last allowed correction counts
as converged. When we reach the correction limit, or the residual norm grows above `10¹⁰`, we
print a warning and return the iterates so far. Check the residual of the last iterate to tell
convergence apart from a warning return.

### Arguments
- `A::AbstractMatrix{T}`: the `n × n` system matrix. Every diagonal entry must be nonzero.
- `b::AbstractVector{T}`: the right-hand side, a vector of length `n`.
- `xₒ::AbstractVector{T}`: the initial guess `x⁽⁰⁾`, a vector of length `n`.
- `algorithm::AbstractLinearSolverAlgorithm = JacobiMethod()`: the method: `JacobiMethod()`,
  `GaussSeidelMethod()`, or `SuccessiveOverRelaxationMethod()`.
- `ϵ::Float64 = 1e-6`: the residual tolerance: we stop when `‖r⁽ᵏ⁾‖₂ < ϵ`.
- `maxiterations::Int64 = 1000`: the correction limit, the most corrections we make. It must be zero
  or larger.
- `ω::Float64 = 1.0`: the relaxation factor. Only `SuccessiveOverRelaxationMethod()` uses it.

`where T <: Number` means that `T` stands for one number type, such as `Float64`, and that `A`,
`b`, and `xₒ` must all have that same element type. For example, an integer matrix `A` with a
`Float64` vector `b` matches no method, and Julia stops with a `MethodError`.

### Returns
- `Dict{Int,Array{Float64,1}}`: the archive of iterates. Key `0` holds the initial guess, and key
  `k` holds the iterate after `k` corrections. The largest key is the number of corrections made,
  and it is never larger than `maxiterations`. The archive holds one more entry than the number of
  corrections.

### Throws
- an `ArgumentError` if `maxiterations` is negative.
- an `ErrorException` if a diagonal entry of `A` is zero.

### Example
```julia
A = [4.0 1.0; 1.0 3.0]; b = [1.0, 2.0]; xₒ = zeros(2);
archive = solve(A, b, xₒ; algorithm = GaussSeidelMethod(), ϵ = 1e-10);
x = archive[maximum(keys(archive))]; # the last iterate, close to [1/11, 7/11]
```
"""
function solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T};
    algorithm::AbstractLinearSolverAlgorithm = JacobiMethod(),
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number


    # check the correction limit: if maxiterations >= 0 is false, we stop with an ArgumentError.
    # (In a || b, Julia runs b only when a is false) -
    maxiterations >= 0 || throw(ArgumentError("maxiterations must be nonnegative"));

    # call the _solve method that matches the type of algorithm (JacobiMethod, GaussSeidelMethod,
    # or SuccessiveOverRelaxationMethod), and return its archive. The name = value arguments are
    # keyword arguments -
    return _solve(A, b, xₒ, algorithm, ϵ = ϵ, maxiterations = maxiterations, ω = ω);
end

"""
    solve(problem::MyLinearProgrammingProblemModel; constraints::Symbol = :leq) -> Dict{String,Any}

Solve a linear program that maximizes a linear objective, with the GLPK solver.

With `d` decision variables `x = (x₁, …, x_d)`, the problem is:

    maximize    cᵀx
    subject to  A⋅x ≤ b     (or A⋅x ≥ b, or A⋅x = b; see the constraints argument)
                lbᵢ ≤ xᵢ ≤ ubᵢ   for i = 1, …, d

Here `c` holds one objective coefficient per variable, and `cᵀx = c₁x₁ + … + c_d x_d`. Each row of
`A`, with the matching entry of `b`, is one constraint. The vectors `lb` and `ub` hold the lower and
upper bound of each variable. We build the problem with the JuMP modeling package, and GLPK, a free
linear-programming solver, finds the optimal `x`.

The week-05 L5c fruit-problem example uses this function to choose how many apples and oranges to
buy within a budget.

### Arguments
- `problem::MyLinearProgrammingProblemModel`: the problem data, in the fields:
  - `c`: the objective coefficients, one per variable. The number of variables is `d = length(c)`.
  - `A::Array{Float64,2}`: the constraint matrix, one row per constraint and one column per variable.
  - `b::Array{Float64,1}`: the right-hand side, one entry per constraint.
  - `lb::Array{Float64,1}`: the lower bound of each variable.
  - `ub::Array{Float64,1}`: the upper bound of each variable.
- `constraints::Symbol = :leq`: the kind of constraint: `:leq` for `A⋅x ≤ b` (the default), `:geq`
  for `A⋅x ≥ b`, or `:eq` for `A⋅x = b`.

### Returns
- `Dict{String,Any}`: a dictionary with three keys:
  - `"argmax"`: the optimal values of the variables, a `Vector{Float64}` of length `d`;
  - `"objective_value"`: the value of `cᵀx` at the optimal `x`, a `Float64`;
  - `"status"`: the termination status the solver reports, such as `OPTIMAL`.

### Throws
- an `ErrorException` if `constraints` is not `:leq`, `:geq`, or `:eq`.
- an `AssertionError` if the solver does not report a solved and feasible problem, for example when
  no `x` satisfies every constraint (an infeasible problem) or the objective can grow without bound
  (an unbounded problem).
"""
function solve(problem::MyLinearProgrammingProblemModel; constraints::Symbol = :leq)::Dict{String,Any}

    # initialize: an empty results dictionary, and the problem data from the model -
    results = Dict{String,Any}()
    c = problem.c; # objective function coefficients, one per variable
    lb = problem.lb; # lower bound of each variable
    ub = problem.ub; # upper bound of each variable
    A = problem.A; # constraint matrix: one row per constraint, one column per variable
    b = problem.b; # right-hand side vector: one entry per constraint

    # the number of decision variables d: one per objective coefficient -
    d = length(c);

    # Set up the problem: an empty JuMP model that GLPK will solve, then the d variables -
    model = Model(GLPK.Optimizer) # an empty optimization model, with GLPK as its solver
    @variable(model, lb[i,1] <= x[i=1:d] <= ub[i,1], start=0.0) # the d variables x[1], ..., x[d], with lb[i] ≤ x[i] ≤ ub[i]; lb[i,1] is entry i of the vector lb (a trailing index 1 is allowed on a vector); start=0.0 suggests zero as a starting value

    # set the objective function: maximize cᵀx -
    @objective(model, Max, transpose(c)*x); # for a vector c, transpose(c)*x is the number c₁x₁ + c₂x₂ + ... + c_d x_d; an n × 1 matrix c gives a one-entry vector, which JuMP rejects as an objective

    # add the constraints of the chosen kind, one per row of A. The @constraints macro adds every
    # constraint listed between begin and end -
    if (constraints == :leq)
        @constraints(model,
            begin
                A*x <= b # row i: (A⋅x)ᵢ ≤ bᵢ, for example a budget in the L5c fruit problem
            end
    );
    elseif (constraints == :geq)
        @constraints(model,
            begin
                A*x >= b # row i: (A⋅x)ᵢ ≥ bᵢ
            end
        );
    elseif (constraints == :eq)
        @constraints(model,
            begin
                A*x == b # row i: (A⋅x)ᵢ = bᵢ
            end
        );
    else
        error("Invalid constraints type. Must be :leq, :geq, or :eq.") # any other symbol: stop with an ErrorException
    end

    # run the optimization -
    optimize!(model)

    # check: was the optimization successful? @assert stops with an AssertionError when the test
    # is false; is_solved_and_feasible is true when the solver found an optimal, feasible x -
    @assert is_solved_and_feasible(model)

    # store the optimal x, the optimal objective value, and the solver status -
    x_opt = value.(x); # value.(x) applies value to each variable (the dot broadcasts over the vector), giving the optimal values
    results["argmax"] = x_opt
    results["objective_value"] = objective_value(model);
    results["status"] = termination_status(model);

    # return the results dictionary -
    return results
end

# -- PUBLIC METHODS ABOVE HERE ---------------------------------------------------------------------------------------------------------------------------------------- #
