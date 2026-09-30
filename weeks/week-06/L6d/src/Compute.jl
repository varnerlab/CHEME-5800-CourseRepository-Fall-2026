# L6d model assembly and the student Jacobi implementation. Students complete
# my_jacobi(...) below; everything else matches Compute-solution.jl.
module L6dOxygen

import LinearAlgebra: norm, diag # residual norm and the diagonal of A

export build_tissue_system, tissue_field, summarize_archive, my_jacobi

"""
    build_tissue_system(n::Integer, phi::Real; boundary::Real = 1.0)

Build the dimensionless steady oxygen balance on a square, -1 < ξ, η < 1:
`-∇²θ + phi^2*θ = 0`, with `θ = boundary` on all four edges.

# Arguments
- `n::Integer`: number of interior nodes in each direction, at least one.
- `phi::Real`: finite, nonnegative Thiele modulus based on the half-width.
- `boundary::Real = 1.0`: finite, nonnegative edge concentration divided by
  the fixed reference concentration; the same value is used on all four edges.

# Returns
A NamedTuple containing:
- `A::Matrix{Float64}`: dense `n^2 × n^2` coefficient matrix.
- `b::Vector{Float64}`: `n^2` known boundary contributions.
- `n::Int`: interior grid size in each direction.
- `h::Float64`: dimensionless grid spacing, `2/(n+1)`.
- `phi::Float64` and `boundary::Float64`: the supplied model parameters.
- `coordinates::Vector{Float64}`: `n+2` coordinates from -1 to 1, including
  both edges; the same vector gives the ξ and η coordinates.

Row `p = i + (j-1)*n` represents interior node `(i,j)`. Each equation is
multiplied by `h^2`, so the diagonal is `4 + phi^2*h^2`, interior neighbors
have coefficient `-1`, and each boundary neighbor adds `boundary` to `b[p]`.
All entries and unknowns are dimensionless. We use a dense matrix for the
small teaching grids; each row has at most five nonzero entries.

# Errors
Throw `ArgumentError` if `n < 1`, or if `phi` or `boundary` is negative or nonfinite.

# Example
```julia
model = L6dOxygen.build_tissue_system(15, 2.0; boundary = 1.0);
theta = model.A \\ model.b; # solve the assembled steady balances
```
"""
function build_tissue_system(n::Integer, phi::Real; boundary::Real = 1.0)
    # Check the grid and physical parameters before allocating the system -
    if n < 1
        throw(ArgumentError("n must be at least one"))
    end
    if !isfinite(phi) || phi < 0
        throw(ArgumentError("phi must be finite and nonnegative"))
    end
    if !isfinite(boundary) || boundary < 0
        throw(ArgumentError("boundary must be finite and nonnegative"))
    end
    # Compact alternatives: || evaluates the error only when the check fails.
    # n >= 1 || throw(ArgumentError("n must be at least one"))
    # isfinite(phi) && phi >= 0 || throw(ArgumentError("phi must be finite and nonnegative"))
    # isfinite(boundary) && boundary >= 0 || throw(ArgumentError("boundary must be finite and nonnegative"))

    # Initialize the grid and the linear system -
    h = 2.0 / (n + 1); # dimensionless distance between neighboring nodes
    grid = range(-1.0, 1.0; length = n + 2); # n interior points plus two edge points
    coordinates = collect(grid); # store the equally spaced coordinates in a vector
    # Compact alternative: coordinates = collect(range(-1.0, 1.0; length = n + 2));
    number_of_unknowns = n * n; # every interior (i,j) pair has one concentration
    A = zeros(Float64, number_of_unknowns, number_of_unknowns);
    b = zeros(Float64, number_of_unknowns); # known edge concentrations enter here

    # Write the balance at each interior node -
    # Each row represents (4 + phi^2*h^2)*theta[p] minus its neighbors.
    # A known edge value moves to b with a positive sign.
    for j ∈ 1:n # vertical grid index, η
        for i ∈ 1:n # horizontal grid index, ξ
            p = i + (j - 1)*n; # ξ changes first when we number the unknowns
            A[p, p] = 4.0 + (phi*h)^2; # diffusion to four neighbors plus consumption

            # Left and right neighbors -
            if i > 1
                A[p, p - 1] = -1.0; # one column left in the same grid row
            else
                b[p] += boundary; # the left edge has a prescribed concentration
            end
            if i < n
                A[p, p + 1] = -1.0; # one column right in the same grid row
            else
                b[p] += boundary; # prescribed right edge
            end

            # Bottom and top neighbors -
            if j > 1
                A[p, p - n] = -1.0; # one grid row below: skip n unknowns
            else
                b[p] += boundary; # prescribed bottom edge
            end
            if j < n
                A[p, p + n] = -1.0; # one grid row above: skip n unknowns
            else
                b[p] += boundary; # prescribed top edge
            end
        end
    end

    # Bundle the balances and grid information so callers can use model.A, etc. -
    return (A = A, b = b, n = Int(n), h = h, phi = Float64(phi),
        boundary = Float64(boundary), coordinates = coordinates)
end

"""
    tissue_field(model, theta::AbstractVector)

Place the `n^2` interior concentrations in a `(n+2) × (n+2)` array, with
the prescribed concentration on every edge.

# Arguments
- `model`: NamedTuple returned by `build_tissue_system`; uses `n` and `boundary`.
- `theta::AbstractVector`: `n^2` real, dimensionless interior concentrations,
  ordered by `p = i + (j-1)*n`. This may be a solver iterate or a final solution.

# Returns
A new `Matrix{Float64}` of dimensionless concentrations. Entry
`field[i+1, j+1]` holds interior value `theta[p]`; the outer rows and columns
hold `model.boundary`. The first index follows ξ and the second follows η.
Transpose the field for a heatmap whose rows represent vertical coordinates.
The input model and concentration vector are unchanged.

# Errors
Throw `DimensionMismatch` unless `length(theta) == model.n^2`.

# Example
```julia
model = L6dOxygen.build_tissue_system(15, 2.0);
theta = model.A \\ model.b;
field = L6dOxygen.tissue_field(model, theta);
center_concentration = field[9, 9]; # center of the 17 × 17 grid, including edges
```
"""
function tissue_field(model, theta::AbstractVector)
    # Check that every interior point has a value -
    if length(theta) != model.n^2
        throw(DimensionMismatch("theta must contain n^2 interior values"))
    end
    # Compact alternative:
    # length(theta) == model.n^2 || throw(DimensionMismatch("theta must contain n^2 interior values"))

    # Start with the prescribed concentration, then replace only the interior -
    field = fill(model.boundary, model.n + 2, model.n + 2);
    for j ∈ 1:model.n
        for i ∈ 1:model.n
            p = i + (j - 1)*model.n; # recover the vector position used in assembly
            field[i + 1, j + 1] = theta[p]; # +1 leaves room for the lower/left edges
        end
    end
    return field
end

"""
    summarize_archive(model, archive; tolerance::Real = 1e-8)

Read an iterate archive returned by the course `solve(...)` function or by
`my_jacobi(...)`: compute the residual norm of every stored iterate and report
whether the last one meets the tolerance.

# Arguments
- `model`: NamedTuple from `build_tissue_system`; uses the matrix `A` and vector `b`.
- `archive`: nonempty dictionary with consecutive integer keys `0:iterations`.
  Each value is a vector of `model.n^2` dimensionless concentrations. Key zero
  holds the initial guess; each later key counts completed solver corrections.
- `tolerance::Real = 1e-8`: finite, positive threshold for the Euclidean residual
  norm of the dimensionless equations scaled by `h^2`.

# Returns
A NamedTuple with `solution` (a copy of the last stored vector), `iterations`
(number of completed corrections), `residuals::Vector{Float64}`, and
`converged::Bool`. Entry `iteration+1` of `residuals` is the Euclidean norm of
`b - A*archive[iteration]`, so entry one measures the initial guess. Convergence
uses the strict inequality `last(residuals) < tolerance`, as in the course solver.
The input model and archive are unchanged.

# Errors
Throw `ArgumentError` if the tolerance is nonpositive or nonfinite. The archive
must follow the course solver's key and vector-size conventions described above.

# Example
```julia
model = L6dOxygen.build_tissue_system(3, 2.0);
initial = zeros(9);
archive = Dict(0 => initial); # an archive containing only the initial guess
result = L6dOxygen.summarize_archive(model, archive);
result.iterations # 0; result.residuals contains the initial residual norm
```
"""
function summarize_archive(model, archive; tolerance::Real = 1e-8)
    # Check the stopping threshold -
    if !isfinite(tolerance) || tolerance <= 0
        throw(ArgumentError("tolerance must be finite and positive"))
    end
    # Compact alternative:
    # isfinite(tolerance) && tolerance > 0 || throw(ArgumentError("tolerance must be finite and positive"))

    # Measure the imbalance for each stored iterate, in correction order -
    iterations = maximum(keys(archive)); # largest key counts completed corrections
    residuals = Float64[]; # append one residual norm per stored vector
    for iteration ∈ 0:iterations
        theta = archive[iteration];
        residual = model.b - model.A * theta; # one imbalance for each grid equation
        residual_norm = norm(residual); # combine all imbalances in a Euclidean norm
        push!(residuals, residual_norm); # vector position is iteration + 1
        # Compact alternative: push!(residuals, norm(model.b - model.A*theta));
    end

    # Copy the final vector so changing the result will preserve the archive -
    solution = copy(archive[iterations]);
    converged = last(residuals) < tolerance; # also detects stopping at the iteration limit
    return (solution = solution, iterations = iterations,
        residuals = residuals, converged = converged)
end

"""
    my_jacobi(A::AbstractMatrix, b::AbstractVector, theta_initial::AbstractVector;
        ϵ::Real = 1e-8, maxiterations::Integer = 1000)

Solve `A*θ = b` with the Jacobi method, following the five-step algorithm in
the L6c Jacobi notebook. Each correction divides the residual by the diagonal
of `A` and adds the result to the current iterate.

# Arguments
- `A::AbstractMatrix`: square coefficient matrix with nonzero diagonal entries.
- `b::AbstractVector`: right-hand side, one entry per row of `A`.
- `theta_initial::AbstractVector`: initial guess, one entry per unknown. It is
  copied, so the caller's vector is unchanged.
- `ϵ::Real = 1e-8`: finite, positive tolerance on the Euclidean norm of the
  residual `b - A*θ`.
- `maxiterations::Integer = 1000`: nonnegative limit on the number of corrections.

# Returns
A `Dict{Int, Vector{Float64}}` archive with the same convention as the course
`solve(...)` function: key zero holds a copy of the initial guess, and key `k`
holds the iterate after exactly `k` completed corrections. The largest key is
the number of corrections performed.

# Stopping
Before each correction, compute the residual of the current iterate. Return the
archive when its Euclidean norm is strictly less than `ϵ`. Otherwise, if
`k >= maxiterations`, print a warning and return the archive. Checking the
residual first means an acceptable initial guess needs no correction, and an
iterate that first meets tolerance after the last allowed correction still
counts as converged. The course solver uses the same rule for the systems in
this lab, so the two archives can be compared key by key. The course solver
also stops early when the residual norm exceeds `1e10`; this function does not.

# Errors
Throw `DimensionMismatch` if `A` is not square or if `b` or `theta_initial` do
not match its size. Throw `ArgumentError` if any diagonal entry of `A` is zero,
if `ϵ` is nonpositive or nonfinite, or if `maxiterations` is negative.

# Example
```julia
model = L6dOxygen.build_tissue_system(15, 2.0);
archive = L6dOxygen.my_jacobi(model.A, model.b, zeros(225); ϵ = 1e-8, maxiterations = 2000);
theta = archive[maximum(keys(archive))]; # the last stored iterate
```
"""
function my_jacobi(A::AbstractMatrix, b::AbstractVector, theta_initial::AbstractVector;
    ϵ::Real = 1e-8, maxiterations::Integer = 1000)

    # Check the arguments; this part is complete -
    number_of_equations = size(A, 1);
    if size(A, 2) != number_of_equations
        throw(DimensionMismatch("A must be square; received size $(size(A))"))
    end
    if length(b) != number_of_equations || length(theta_initial) != number_of_equations
        throw(DimensionMismatch("b and theta_initial must have one entry per row of A"))
    end
    if any(iszero, diag(A))
        throw(ArgumentError("every diagonal entry of A must be nonzero for Jacobi"))
    end
    if !isfinite(ϵ) || ϵ <= 0
        throw(ArgumentError("ϵ must be finite and positive"))
    end
    if maxiterations < 0
        throw(ArgumentError("maxiterations must be nonnegative"))
    end

    # Store the initial guess; key k will hold the iterate after k corrections -
    archive = Dict{Int, Vector{Float64}}();
    archive[0] = copy(theta_initial); # copy, so the caller's vector is unchanged
    diagonal = diag(A); # one divisor per equation
    k = 0; # number of completed corrections

    # TODO 1: Start a loop. Read the current iterate theta = archive[k] and
    # compute the residual r = b - A*theta before changing anything.

    # TODO 2: Stop when the residual is small or the limit is reached. If
    # norm(r) < ϵ, return archive. Otherwise, if k >= maxiterations, print a
    # warning with @warn and return archive.

    # TODO 3: Apply the correction. Store theta + r ./ diagonal as archive[k + 1],
    # then add one to k and continue the loop.

    throw(ErrorException("Oooops! The `my_jacobi(...)` function is not implemented yet - " *
                         "we'd better fix that. Complete TODO 1 through TODO 3."))
end

end
