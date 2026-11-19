# ================================================================================================ #
# Eigen.jl
#
# The QR iteration and power iteration methods for the eigenvalues and eigenvectors of a real
# square matrix. An eigenvector v of a matrix A is a vector that A only stretches: A⋅v = λ⋅v, where
# the number λ is the eigenvalue that goes with v. The week 14 advanced notebook (L14a) calls
# qriteration(...) and poweriteration(...). Both follow the CHEME 5820 (Spring 2026) versions.
#
# Functions in this file:
#   _rref!(...)                     (private) put a matrix in reduced row echelon form, in place
#   _upper_triangular(...)          (private) Gaussian elimination to an upper triangular matrix, with no row swaps
#   _smallest_singular_vector(...)  (private) the right singular vector of the smallest singular value
#   _nullspace_vector(...)          (private) one vector v with A⋅v = 0, from the reduced row echelon form
#   qriteration(...)                the eigenvalues and eigenvectors of a real square matrix, by QR iteration
#   poweriteration(...)             the dominant eigenvalue and eigenvector, by power iteration
#
# A leading underscore in a name marks a private helper, which the package does not export.
# The functions use qr, svd, diag, dot, norm, and I (the identity matrix) from the LinearAlgebra package,
# which the package module loads with `using LinearAlgebra`.
# ================================================================================================ #

"""
    _rref!(A::Matrix{T}, ɛ = (default below)) where T -> Matrix{T}

Put the matrix `A` in reduced row echelon form, in place, by Gauss-Jordan elimination with partial
pivoting, and return `A`. The `!` at the end of the name is a Julia convention: the function
changes its argument.

In reduced row echelon form, the first nonzero entry of each row (its pivot) is 1, each pivot is
to the right of the pivot in the row above, and every other entry in a pivot's column is 0. We
work column by column. In the current column, we find the entry of largest absolute value at or
below the current row; choosing the largest entry (partial pivoting) keeps the rounding errors
small. We swap that entry's row up to the current row, divide the row by the pivot so the pivot
becomes 1, and subtract multiples of the row from every other row so the rest of the column
becomes 0. When every candidate entry in a column is at most `ɛ` in absolute value, the column
has no pivot: we set those entries to zero and move on to the next column.

### Arguments
- `A::Matrix{T}`: the matrix, with `nr` rows and `nc` columns, whose entries have the number type
  `T`. It is overwritten.
- `ɛ`: the size below which an entry counts as zero. The default is `0` when `T` is a `Rational`
  or `Integer` type. Pass a `Float64` or `Rational` matrix: the row operations divide, an
  `Integer` matrix cannot store the fractions, and the function stops with an `InexactError`. Otherwise it is `eps(norm(A,Inf))`: `norm(A,Inf)`
  is the largest absolute entry of `A`, and `eps(x)` is the gap between `x` and the next larger
  floating point number.

### Returns
- `Matrix{T}`: the same matrix `A`, now in reduced row echelon form.
"""
function _rref!(A::Matrix{T}, ɛ=T <: Union{Rational,Integer} ? 0 : eps(norm(A,Inf))) where T # the ɛ default: if T is Rational or Integer, use 0; otherwise use eps(norm(A,Inf))

    # initialize: i is the current row and j is the current column. The line i = j = 1 sets both to 1 -
    nr, nc = size(A) # the number of rows nr and the number of columns nc
    i = j = 1

    # main loop: one column each pass, until we run out of rows or columns -
    while i <= nr && j <= nc

        # find the candidate pivot: the largest absolute value in column j, at or below row i.
        # abs.(...) takes the absolute value of every entry, and findmax returns the largest value m
        # and its position mi within the slice A[i:nr,j] -
        (m, mi) = findmax(abs.(A[i:nr,j]))
        mi = mi+i - 1 # convert the position within the slice to a row number of A

        # no usable pivot in this column: set the small entries to zero, and move to the next column -
        if m <= ɛ
            if ɛ > 0
                A[i:nr,j] .= zero(T) # .= writes zero into every entry of the slice
            end
            j += 1 # j += 1 means j = j + 1

        # otherwise, use the entry in row mi as the pivot -
        else

            # swap rows i and mi, from column j to the end. Entries to the left of column j are
            # already zero in both rows. The one-line swap assigns both entries at once -
            for k=j:nc
                A[i, k], A[mi, k] = A[mi, k], A[i, k]
            end

            # divide row i by the pivot, so the pivot becomes 1. A[i,k] /= d means A[i,k] = A[i,k]/d -
            d = A[i,j]
            for k = j:nc
                A[i,k] /= d
            end

            # subtract a multiple of row i from every other row, so column j is zero outside row i -
            for k = 1:nr
                if k != i
                    d = A[k,j] # the multiple: the entry of row k in the pivot column
                    for l = j:nc
                        A[k,l] -= d*A[i,l] # A[k,l] -= x means A[k,l] = A[k,l] - x
                    end
                end
            end

            # move to the next row and the next column -
            i += 1
            j += 1
        end
    end

    # return the reduced matrix: a bare A on the last line of a function is its return value -
    A
end

"""
    _upper_triangular(matrix::Matrix) -> Matrix

Reduce a copy of `matrix` to upper triangular form by Gaussian elimination, with no row swaps.

For each column `k`, we subtract `l = A[i,k]/A[k,k]` times row `k` from every row `i` below row
`k`. This makes every entry below the diagonal in column `k` zero. Because the function never
swaps rows, a zero diagonal entry `A[k,k]` makes `l` infinite or `NaN` ("not a number"), and those
values spread into the rows below. `qriteration(...)` uses the last diagonal entry of the result.

### Arguments
- `matrix::Matrix`: the matrix, with `n` rows and `m` columns. It is not changed; we work on a copy.

### Returns
- `Matrix`: the upper triangular form, the same size as `matrix`.
"""
function _upper_triangular(matrix::Matrix)

    # initialize: work on a copy, so the caller's matrix is not changed -
    A = copy(matrix)
    (n, m) = size(A) # n rows, m columns

    # main loop: clear the entries below the diagonal, one column k at a time -
    for k = 1:min(n,m)
        for i = k+1:n # every row below row k
            l = A[i,k] / A[k,k] # the multiple of row k that clears A[i,k]
            for j = k:m
                A[i,j] = A[i,j] - l*A[k,j]
            end
        end
    end

    # return the upper triangular matrix -
    return A
end


"""
    _smallest_singular_vector(A::Matrix{Float64}) -> Array{Float64,1}

Return the right singular vector of `A` that goes with its smallest singular value. When `A` is
singular, this vector `v` solves `A⋅v = 0`; when `A` is nearly singular, `A⋅v` is as small as any
unit vector can make it. The singular value decomposition is `A = U⋅Σ⋅Vᵀ`, and `svd(A).Vt` holds
the rows of `Vᵀ`, sorted from the largest singular value to the smallest, so the last row is the one we want.
"""
function _smallest_singular_vector(A::Matrix{Float64})::Array{Float64,1}
    F = svd(A) # the singular value decomposition of A
    return F.Vt[end, :] # the last row of Vᵀ
end

"""
    _nullspace_vector(A::Matrix{Float64}; tol::Float64 = 1e-10) -> Array{Float64,1}

Return one nonzero vector `x` with `A⋅x = 0` (a null-space vector of `A`). We put `A` in reduced
row echelon form with `_rref!`, treating entries of size at most `tol` as zero. Each column without
a pivot is a free column. We set the last free entry of `x` to 1, the other free entries to 0, and
solve each pivot row for its pivot entry. When `A` has no free column, or the vector comes out too
short, we return `_smallest_singular_vector(A)` instead.
"""
function _nullspace_vector(A::Matrix{Float64}; tol::Float64 = 1e-10)::Array{Float64,1}

    # reduce a copy of A, so A itself is not changed -
    R = _rref!(copy(A), tol)
    number_of_rows = size(R, 1)
    number_of_columns = size(R, 2)

    # find the pivot of each row: the first entry larger than tol -
    pivot_columns = Int64[]
    pivot_rows = Int64[]
    for i in 1:number_of_rows
        pivot_column = 0
        for j in 1:number_of_columns
            if abs(R[i, j]) > tol
                pivot_column = j
                break
            end
        end
        if pivot_column != 0
            push!(pivot_columns, pivot_column)
            push!(pivot_rows, i)
        end
    end

    # the free columns are the ones without a pivot; with none, A has no exact null-space vector -
    free_columns = setdiff(collect(1:number_of_columns), pivot_columns)
    if isempty(free_columns) == true
        return _smallest_singular_vector(A)
    end

    # set the last free entry to 1, then solve each pivot row for its pivot entry -
    x = zeros(number_of_columns)
    x[free_columns[end]] = 1.0
    for k in 1:length(pivot_columns)
        row = pivot_rows[k]
        total = 0.0
        for j in free_columns
            total = total + R[row, j] * x[j]
        end
        x[pivot_columns[k]] = -total
    end

    # a vector that is too short is not useful; fall back to the singular vector -
    if norm(x) <= tol
        return _smallest_singular_vector(A)
    end
    return x
end

# -- PUBLIC METHODS BELOW HERE ---------------------------------------------------------------------------------------------------------------------------------------- #

"""
    qriteration(A::Array{Float64,2}; maxiter::Int64 = 10,
        tolerance::Float64 = 1e-9) -> Tuple{Array{Float64,1}, Dict{Int64,Array{Float64,1}}}

Estimate the eigenvalues and eigenvectors of a real square matrix `A` with the QR iteration method.

Phase 1 estimates the eigenvalues. Each iteration factors the current matrix as `A_k = Q⋅R`, where
`Q` is orthogonal (its columns are perpendicular unit vectors, so `Qᵀ⋅Q = I`) and `R` is upper
triangular. It then forms `A_{k+1} = Qᵀ⋅A_k⋅Q`, which equals `R⋅Q` and has the same eigenvalues as
`A_k`. When the eigenvalues of `A` are real and have different absolute values, `A_k` approaches
an upper triangular matrix, and its diagonal approaches the eigenvalues. We stop when the diagonal
changes by less than `tolerance` (measured by the Euclidean norm of the change) between two
iterations, or after `maxiter` iterations, whichever comes first. The function does not report
which of the two happened.

Phase 2 estimates one eigenvector for each eigenvalue estimate `λᵢ`. The eigenvector `v` solves
`(A − λᵢI)⋅v = 0`, where `I` is the identity matrix, so it is a null-space vector of `A − λᵢI`.
We find one with `_nullspace_vector`, which row-reduces `A − λᵢI` and treats entries of size at
most `tolerance` as zero. When `λᵢ` is only an estimate, `A − λᵢI` has no exact null space, and
the function falls back to the right singular vector of the smallest singular value: the unit
vector that `A − λᵢI` shrinks the most. We then divide the vector by its length.

### Arguments
- `A::Array{Float64,2}`: a real square matrix of size `n × n`. It is not changed.
- `maxiter::Int64 = 10`: the most QR iterations in phase 1.
- `tolerance::Float64 = 1e-9`: phase 1 stops when the norm of the change in the diagonal is
  less than this value.

### Returns
A tuple `(λ, eigenvectors)`:
- `λ::Array{Float64,1}`: the eigenvalue estimates, sorted from smallest to largest.
- `eigenvectors::Dict{Int64,Array{Float64,1}}`: `eigenvectors[i]` is a unit-length eigenvector
  estimate for `λ[i]`. Check it before you use it: compare `A⋅v` with `λᵢ⋅v`.
"""
function qriteration(A::Array{Float64,2}; 
    maxiter::Int64 = 10, tolerance::Float64 = 1e-9)::Tuple{Array{Float64,1}, Dict{Int64,Array{Float64,1}}}

    # initialize -
    number_of_rows = size(A,1); # n, the size of the square matrix A
    AD = A; # the matrix A_k we iterate on. AD starts as the same array as A; the loop replaces AD with a new matrix, so A is never changed
    ϵ = Inf # the change in the diagonal between two iterations; Inf until we compute the first one
    eigenvectors = Dict{Int64,Array{Float64,1}}() # eigenvectors[i] will hold the eigenvector of the i-th eigenvalue

    # compute iteration zero: the starting λ that the first change is measured from. It is the
    # diagonal of the Q factor of A; only the first comparison in the loop uses it -
    Fₒ = qr(AD) # the QR factorization of A
    Qₒ = Matrix(Fₒ.Q); # Matrix(...) turns the factor Q, which qr(...) stores in a compact form, into an ordinary n×n matrix
    λ = diag(Qₒ) # diag(...) returns the diagonal entries as a vector

    # Phase 1: estimate the eigenvalues. One QR iteration each pass, at most maxiter passes -
    for _ ∈ 1:maxiter

        # factor the current matrix: A_k = Q*R -
        F = qr(AD)
        Q = Matrix(F.Q);

        # update: A_{k+1} = Qᵀ*A_k*Q, which has the same eigenvalues as A_k -
        AD = transpose(Q)*AD*Q

        # check: should we continue to iterate? We measure how much the diagonal changed -
        λ′ = diag(AD); # the new eigenvalue estimates
        ϵ = norm(λ - λ′) # the Euclidean length of the change
        if (ϵ < tolerance)

            # the change is below the tolerance: keep the new estimates -
            λ = λ′

            # we are done with phase 1 -
            break;
        else
            # we have not reached the tolerance: keep the new estimates, and iterate again -
            λ = λ′
        end
    end

    # sort the eigenvalues from smallest to largest. The ! means sort! sorts λ in place -
    sort!(λ)

    # Phase 2: estimate one eigenvector for each eigenvalue λ[i] -
    for i ∈ 1:number_of_rows

        # set up the matrix of the homogeneous system (A − λᵢI)⋅v = 0. Matrix{Float64}(I, n, n) is the n×n identity matrix -
        AH = A - λ[i]*Matrix{Float64}(I, number_of_rows, number_of_rows);

        # compute the unscaled eigenvector: a null-space vector of A − λᵢI -
        EVUS = _nullspace_vector(AH; tol = tolerance)

        # compute the length of the unscaled eigenvector; a length of zero (or not a finite
        # number) means the null-space step failed, so we use the singular vector instead -
        d = norm(EVUS);
        if isfinite(d) == false || d <= eps(Float64)
            EVUS = _smallest_singular_vector(AH)
            d = norm(EVUS)
        end

        # scale the eigenvector to unit length -
        if isfinite(d) == false || d <= eps(Float64)
            eigenvectors[i] = zeros(number_of_rows) # no usable vector: store zeros, not NaN
        else
            eigenvectors[i] = (1/d)*EVUS
        end
    end

    # return the sorted eigenvalues and the dictionary of eigenvectors -
    return (λ, eigenvectors)
end

# -- PUBLIC METHODS ABOVE HERE ---------------------------------------------------------------------------------------------------------------------------------------- #

"""
    poweriteration(A::Array{<:Number,2}, v::Array{<:Number,1};
        maxiter::Int = 100, ϵ::Float64 = 0.0001) -> NamedTuple

Estimate the dominant eigenvalue (the one of largest absolute value) and its eigenvector with the
power iteration method. Each iteration multiplies the current vector by `A` and divides the result
by its length: `w = A⋅v / ‖A⋅v‖`. Unless the starting vector misses the dominant eigenvector
exactly, the vector turns toward that eigenvector. When the dominant eigenvalue is negative, the
vector also flips its sign at each iteration. We stop when the vector changes by less than `ϵ` up
to its sign, `min(‖w − v‖, ‖w + v‖)² ≤ ϵ`, or after `maxiter` iterations, and print which of the
two happened. The eigenvalue estimate is the Rayleigh quotient `λ = (A⋅w)⋅w / (w⋅w)` of the last
vector `w`.

### Arguments
- `A::Array{<:Number,2}`: a square matrix of real numbers.
- `v::Array{<:Number,1}`: the starting vector, which must not be zero.
- `maxiter::Int = 100`: the most iterations.
- `ϵ::Float64 = 0.0001`: the stopping tolerance on `min(‖w − v‖, ‖w + v‖)²`.

### Returns
- A `NamedTuple` with the fields `vector` (the eigenvector estimate, unit length) and `value`
  (the eigenvalue estimate).

### Throws
- `ArgumentError` when `v` is zero, or when `A⋅v` is zero at some iteration. A zero vector has no
  direction, and dividing it by its length would give `NaN`.
"""
function poweriteration(A::Array{<:Number,2}, v::Array{<:Number,1};
    maxiter::Int = 100, ϵ::Float64 = 0.0001)::NamedTuple

    # check: a zero starting vector has no direction -
    if (norm(v) == 0.0)
        throw(ArgumentError("the starting vector v must not be zero"));
    end

    # initialize -
    loopcount = 1;
    should_we_stop = false;

    while (should_we_stop == false)

        # compute the next iteration: multiply by A, then divide by the length -
        w = A * v;
        if (norm(w) == 0.0)
            throw(ArgumentError("A⋅v is zero at iteration $(loopcount); choose another starting vector"));
        end
        w = w / norm(w);

        # the change in the vector, up to its sign: a negative dominant eigenvalue flips the sign at each iteration -
        change = min(norm(w - v), norm(w + v))^2;
        v = w; # keep the newest vector

        # check: should we stop? Either the vector stopped changing, or we ran out of iterations -
        if (change ≤ ϵ)
            should_we_stop = true;
            println("Converged in $(loopcount) iterations"); # let the user know how many iterations it took
        elseif (loopcount ≥ maxiter)
            should_we_stop = true;
            println("Stopped after $(loopcount) iterations without converging"); # the tolerance was not reached
        else
            loopcount = loopcount + 1; # update the loop count
        end
    end

    # compute the eigenvalue estimate, the Rayleigh quotient -
    λ = dot(A * v, v) / dot(v, v);

    # return the result -
    return (vector = v, value = λ);
end
