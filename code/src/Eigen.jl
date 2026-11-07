# ================================================================================================ #
# Eigen.jl
#
# The QR iteration method for the eigenvalues and eigenvectors of a real square matrix. An
# eigenvector v of a matrix A is a vector that A only stretches: A⋅v = λ⋅v, where the number λ is
# the eigenvalue that goes with v. The package exports qriteration(...); no course notebook calls it.
#
# Functions in this file:
#   _rref!(...)             (private) put a matrix in reduced row echelon form, in place
#   _upper_triangular(...)  (private) Gaussian elimination to an upper triangular matrix, with no row swaps
#   qriteration(...)        the eigenvalues and eigenvectors of a real square matrix, by QR iteration
#
# A leading underscore in a name marks a private helper, which the package does not export.
# The functions use qr, diag, norm, and I (the identity matrix) from the LinearAlgebra package,
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

Phase 2 estimates one eigenvector for each eigenvalue estimate `λᵢ`. We row-reduce the augmented
matrix `[A − λᵢI  b]`, where `I` is the identity matrix and `b` is zero except for its last entry.
That entry is the last diagonal entry of the upper triangular form of `A − λᵢI`, or 1 when that
entry is exactly zero. We take the last column `x` of the reduced matrix and divide it by its
length. When the row reduction finds a pivot in every column of `A − λᵢI`, the reduced matrix is
`[I x]`, so `x` solves `(A − λᵢI)⋅x = b`. This is one step of the inverse iteration method.
When `λᵢ` is close to an eigenvalue, the step usually turns `x` toward that eigenvalue's
eigenvector. It does not always do so, because the result also depends on the right-hand side `b`.
For `A = [2.0 1 0; 1 3 0; 0 0 10]`, the first two vectors returned are eigenvectors of the
eigenvalue `10`. The function does not check its vectors. Before you use a returned vector `x`,
compare `A⋅x` with `λᵢ⋅x`.
Last, we multiply the eigenvector by `(−1)^(i+1)`, which flips the sign of every second
eigenvector. An eigenvector times −1 is still an eigenvector; the code does not record why it
flips these signs.

### Arguments
- `A::Array{Float64,2}`: a real square matrix of size `n × n`. It is not changed.
- `maxiter::Int64 = 10`: the most QR iterations in phase 1.
- `tolerance::Float64 = 1e-9`: phase 1 stops when the norm of the change in the diagonal is
  less than this value.

### Returns
A tuple `(λ, eigenvectors)`:
- `λ::Array{Float64,1}`: the eigenvalue estimates, sorted from smallest to largest.
- `eigenvectors::Dict{Int64,Array{Float64,1}}`: `eigenvectors[i]` is a unit-length eigenvector
  estimate for `λ[i]`. When the row reduction treats `A − λᵢI` as singular, the last column of the
  reduced matrix can come out all zeros, and `eigenvectors[i]` is then all `NaN` ("not a number").
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

        # use Gaussian elimination to get the last pivot of A − λᵢI; we use 1.0 if that pivot is exactly zero -
        pivot_value = 1.0
        U = _upper_triangular(AH)
        if (U[end,end] != 0.0) # U[end,end] is the entry in the last row and last column
            pivot_value = U[end,end];
        end

        # create the augmented system [A − λᵢI  b], where b is zero except for its last entry -
        b = zeros(number_of_rows);
        b[number_of_rows] = pivot_value # the last entry of b is the pivot value
        AM = [AH b]; # [AH b] puts the column b to the right of AH

        # compute the unscaled eigenvector: the last column of the reduced row echelon form.
        # [:,end] picks every row (:) of the last column (end) -
        EVUS = _rref!(AM)[:,end];

        # compute the length of the unscaled eigenvector -
        d = norm(EVUS);

        # scale the eigenvector to unit length, and multiply it by (-1)^(i+1): +1 for odd i and
        # -1 for even i. The code does not record why it flips the sign of every second eigenvector -
        eigenvectors[i] = ((-1)^(i+1))*(1/d)*EVUS
    end

    # return the sorted eigenvalues and the dictionary of eigenvectors -
    return (λ, eigenvectors)
end

# -- PUBLIC METHODS ABOVE HERE ---------------------------------------------------------------------------------------------------------------------------------------- #