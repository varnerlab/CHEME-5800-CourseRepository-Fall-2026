function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::JacobiMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # retain the initial guess and every iterate
    archive[0] = copy(xₒ);

    # Prepare the correction matrix -
    D = diag(A) |> a-> diagm(a);
    if (any(diag(A) .== 0.0))
        error("Matrix A has zero(s) on the diagonal, cannot proceed with Jacobi Method.")
    end
    DI = inv(D); # inverse of the diagonal correction matrix

    # Iterate -
    while true
        x = archive[k]; # read the current iterate without changing the archive
        r = b - A*x;
        current_residual = norm(r);

        # Test convergence before the limit so the last allowed correction can succeed -
        if (current_residual < ϵ)
            return archive;
        elseif (k >= maxiterations)
            @warn "Jacobi method did not converge within $maxiterations iterations. Final residual: $current_residual"
            return archive;
        elseif (current_residual > 1e10) # existing large-residual safeguard
            @warn "Jacobi method appears to be diverging. Residual: $current_residual"
            return archive;
        end

        # Compute and store a correction only when continuing -
        d = DI * r;
        k += 1;
        archive[k] = x + d; # key k records exactly k completed corrections
    end
end

function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::GaussSeidelMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # retain the initial guess and every iterate
    archive[0] = copy(xₒ);

    # Prepare the correction matrix -
    D = diag(A) |> a-> diagm(a);
    L = tril(A,-1);
    if (det(D+L) == 0.0)
        error("Matrix D+L is not invertible, cannot proceed with Gauss-Seidel Method.")
    end
    C = inv(D + L); # inverse of the lower triangular correction matrix

    # Iterate -
    while true
        x = archive[k]; # read the current iterate without changing the archive
        r = b - A*x;
        current_residual = norm(r);

        # Test convergence before the limit so the last allowed correction can succeed -
        if (current_residual < ϵ)
            return archive;
        elseif (k >= maxiterations)
            @warn "Gauss-Seidel method did not converge within $maxiterations iterations. Final residual: $current_residual"
            return archive;
        elseif (current_residual > 1e10) # existing large-residual safeguard
            @warn "Gauss-Seidel method appears to be diverging. Residual: $current_residual"
            return archive;
        end

        # Compute and store a correction only when continuing -
        d = C * r;
        k += 1;
        archive[k] = x + d; # key k records exactly k completed corrections
    end
end

function _solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}, algorithm::SuccessiveOverRelaxationMethod;
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

    # Initialize -
    k = 0; # number of completed corrections
    archive = Dict{Int, Array{Float64,1}}(); # retain the initial guess and every iterate
    archive[0] = copy(xₒ);

    # Prepare the correction matrix -
    D = diag(A) |> a-> diagm(a);
    L = tril(A,-1);
    if (det(D + ω*L) == 0.0)
        error("Matrix D + ω*L is not invertible, cannot proceed with Successive Over-Relaxation Method.")
    end
    C = inv(D + ω*L); # inverse of the relaxed lower triangular correction matrix

    # Iterate -
    while true
        x = archive[k]; # read the current iterate without changing the archive
        r = b - A*x;
        current_residual = norm(r);

        # Test convergence before the limit so the last allowed correction can succeed -
        if (current_residual < ϵ)
            return archive;
        elseif (k >= maxiterations)
            @warn "SOR method did not converge within $maxiterations iterations. Final residual: $current_residual"
            return archive;
        elseif (current_residual > 1e10) # existing large-residual safeguard
            @warn "SOR method appears to be diverging. Residual: $current_residual"
            return archive;
        end

        # Compute and store a correction only when continuing -
        d = ω * C * r;
        k += 1;
        archive[k] = x + d; # key k records exactly k completed corrections
    end
end

# -- PUBLIC METHODS BELOW HERE ---------------------------------------------------------------------------------------------------------------------------------------- #

"""
    solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T};
    algorithm::AbstractLinearSolverAlgorithm = JacobiMethod(), ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number

The `solve` function solves the linear system of equations `Ax = b` using the specified algorithm.
The function returns an archive of iterates, including the initial guess at key zero.
Each later key counts completed corrections. The residual is checked before the correction limit,
so a satisfactory initial guess takes zero corrections and convergence on the final allowed
correction succeeds. A warning reports an unmet limit or the large-residual safeguard;
the current archive is returned without another correction. Check the final residual to
distinguish convergence from a warning return.

### Arguments
- `A::AbstractMatrix{T}`: The system matrix `A` in the linear system of equations `Ax = b`.
- `b::AbstractVector{T}`: The right-hand side vector `b` in the linear system of equations `Ax = b`.
- `xₒ::AbstractVector{T}`: The initial guess for the solution vector `x`.
- `algorithm::AbstractLinearSolverAlgorithm`: The algorithm to use to solve the linear system of equations. The default algorithm is `JacobiMethod()`.
- `ϵ::Float64`: The error tolerance for the iterative method. The default value is `1e-6`.
- `maxiterations::Int64`: The maximum number of corrections, which must be nonnegative. The default value is `1000`.
- `ω::Float64`: The relaxation factor for the Successive Over-Relaxation method. The default value is `1.0`. This parameter is only used if the `SuccessiveOverRelaxationMethod` algorithm is selected.

### Returns
- `d::Dict{Int,Array{Float64,1}}`: The initial guess at key `0` and the solution vectors after each completed correction. The largest key never exceeds `maxiterations`; the archive contains one more entry than the correction count.
"""
function solve(A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T};
    algorithm::AbstractLinearSolverAlgorithm = JacobiMethod(),
    ϵ::Float64 = 1e-6, maxiterations::Int64 = 1000, ω::Float64 = 1.0) where T <: Number


    maxiterations >= 0 || throw(ArgumentError("maxiterations must be nonnegative"));

    # return -
    return _solve(A, b, xₒ, algorithm, ϵ = ϵ, maxiterations = maxiterations, ω = ω);
end

"""
    solve(problem::MyLinearProgrammingProblemModel) -> Dict{String,Any}

Solves a linear programming problem defined by the `MyLinearProgrammingProblemModel` instance using the GLPK solver.

### Arguments
- problem::MyLinearProgrammingProblemModel: An instance of MyLinearProgrammingProblemModel holding the data for the problem.
- constraints::Symbol: The type of constraints to apply. Options are :leq (less than or equal to), :geq (greater than or equal to), or :eq (equal to). Default is :leq.

### Returns
- Dict{String,Any}: A dictionary with the following keys:
    - "argmax": The optimal choice.
    - "budget": The budget at the optimal choice.
    - "objective_value": The value of the objective function at the optimal choice.
"""
function solve(problem::MyLinearProgrammingProblemModel; constraints::Symbol = :leq)::Dict{String,Any}

    # initialize -
    results = Dict{String,Any}()
    c = problem.c; # objective function coefficients
    lb = problem.lb; # lower bounds
    ub = problem.ub; # upper bounds
    A = problem.A; # constraint matrix
    b = problem.b; # right-hand side vector

    # how many variables do we have?
    d = length(c);

    # Setup the problem -
    model = Model(GLPK.Optimizer)
    @variable(model, lb[i,1] <= x[i=1:d] <= ub[i,1], start=0.0) # we have d variables

    # set objective function -
    @objective(model, Max, transpose(c)*x);

    if (constraints == :leq)
        @constraints(model,
            begin
                A*x <= b # my material balance constraints
            end
    );
    elseif (constraints == :geq)
        @constraints(model,
            begin
                A*x >= b # my material balance constraints
            end
        );
    elseif (constraints == :eq)
        @constraints(model,
            begin
                A*x == b # my material balance constraints
            end
        );
    else
        error("Invalid constraints type. Must be :leq, :geq, or :eq.")
    end

    # run the optimization -
    optimize!(model)

    # check: was the optimization successful?
    @assert is_solved_and_feasible(model)

    # populate -
    x_opt = value.(x);
    results["argmax"] = x_opt
    results["objective_value"] = objective_value(model);
    results["status"] = termination_status(model);

    # return -
    return results
end

# -- PUBLIC METHODS ABOVE HERE ---------------------------------------------------------------------------------------------------------------------------------------- #
