"""
    _rref!(A::AbstractMatrix, eps_val=nothing)

Compute the reduced row echelon form (RREF) of a matrix in-place using
partial pivoting. Operates on floating-point or rational element types.

### Arguments
- `A::AbstractMatrix{T}`: the matrix to reduce in-place. Element type must be `AbstractFloat` or `Rational`.
- `eps_val`: pivot tolerance. Defaults to `eps(norm(A, Inf))` for floating-point types and `zero(T)` for rational types.

### Returns
- `A`: the same matrix, reduced in-place to RREF form.

Integer matrices raise `ArgumentError`; convert to floating-point or rational
entries first. Use a nonnegative absolute pivot tolerance. Small entries in a
skipped pivot column are set to zero when the tolerance is positive.
"""
function _rref!(A::AbstractMatrix{T}, eps_val=nothing) where {T<:Union{AbstractFloat,Rational}}
    if eps_val === nothing
        eps_val = T <: Rational ? zero(T) : eps(norm(A, Inf))
    end
    nr, nc = size(A)
    i = j = 1 # next pivot row and candidate pivot column
    while i <= nr && j <= nc
        (m, mi) = findmax(abs.(A[i:nr,j]))
        mi = mi+i - 1 # convert the slice position to a matrix row
        if m <= eps_val
            if eps_val > 0
                A[i:nr,j] .= zero(T)
            end
            j += 1
        else
            # Move the largest remaining column entry into the pivot row -
            for k=j:nc
                A[i, k], A[mi, k] = A[mi, k], A[i, k]
            end
            # Normalize the pivot, then eliminate its column in all other rows -
            d = A[i,j]
            for k = j:nc
                A[i,k] /= d
            end
            for k = 1:nr
                if k != i
                    d = A[k,j]
                    for l = j:nc
                        A[k,l] -= d*A[i,l]
                    end
                end
            end
            i += 1
            j += 1
        end
    end
    A
end

# Overload for integer element types — always throws, since RREF requires floating or rational types.
# Convert first with float.(A) or rationalize.(A).
function _rref!(A::AbstractMatrix{T}, eps_val=nothing) where {T<:Integer}
    throw(ArgumentError("_rref! requires floating or rational element types; convert with float.(A) or rationalize.(A)."))
end

"""
    _upper_triangular(matrix::Matrix) -> Matrix

Compute the upper triangular form of a matrix using Gaussian elimination
(without pivoting). Returns a copy; the input is not modified.

### Arguments
- `matrix::Matrix`: matrix with floating-point or rational entries and nonzero
  elimination pivots. No pivot checks are made: a zero pivot can cause division
  by zero, and integer storage can fail when an update is nonintegral.

### Returns
- `Matrix`: the upper triangular form of the input matrix.
"""
function _upper_triangular(matrix::Matrix)
    A = copy(matrix)
    (n, m) = size(A)
    for k = 1:min(n,m)
        for i = k+1:n
            l = A[i,k] / A[k,k]
            for j = k:m
                A[i,j] = A[i,j] - l*A[k,j]
            end
        end
    end
    return A
end

"""
    _smallest_singular_vector(A::Matrix{Float64}) -> Vector{Float64}

Return the unit right singular vector in the last row of the thin SVD's `Vt`.
`A` must be a nonempty matrix and is not modified. The vector has length
`size(A, 2)` and minimizes the residual norm among the returned right singular
vectors. A nonzero smallest singular value gives a nonzero residual; this is
not necessarily a nullspace vector. For a wide matrix, the thin SVD omits the
additional right-nullspace directions.
"""
function _smallest_singular_vector(A::Matrix{Float64})::Array{Float64,1}
    F = svd(A)
    return F.Vt[end, :]
end

"""
    _nullspace_vector(A::Matrix{Float64}; tol::Float64=1e-10) -> Vector{Float64}

Find one nullspace candidate using RREF of a copy of `A`. The input is unchanged.
`tol` is an absolute pivot tolerance. If a free column exists, set its variable
to one, set other free variables to zero, and solve for the pivot variables.
This vector is not normalized; its norm need not be one.

If no free column exists, or the candidate norm is too small, return the unit
right singular vector for the smallest singular value in the thin SVD instead.
For a full-column-rank matrix this fallback has a nonzero residual and is not
an exact nullspace vector. Check `norm(A*x)` before interpreting the result.
Inputs must be nonempty; `tol` should be positive. These conditions are not validated.
"""
function _nullspace_vector(A::Matrix{Float64}; tol::Float64 = 1e-10)::Array{Float64,1}
    R = _rref!(copy(A), tol)
    n = size(R,2)
    nrows = size(R,1)
    pivot_cols = Int[]
    pivot_rows = Int[]
    for i in 1:nrows
        pivot_col = 0
        for j in 1:n
            if abs(R[i,j]) > tol
                pivot_col = j
                break
            end
        end
        if pivot_col != 0
            push!(pivot_cols, pivot_col)
            push!(pivot_rows, i)
        end
    end

    free_cols = setdiff(collect(1:n), pivot_cols)
    if isempty(free_cols)
        return _smallest_singular_vector(A)
    end

    x = zeros(n)
    free_col = free_cols[end] # choose one free variable; other free variables stay zero
    x[free_col] = 1.0
    for idx in eachindex(pivot_cols)
        row = pivot_rows[idx]
        pc = pivot_cols[idx]
        s = 0.0
        for j in free_cols
            s += R[row,j] * x[j]
        end
        x[pc] = -s
    end

    if norm(x) <= tol
        return _smallest_singular_vector(A)
    end

    return x
end


"""
    ⊗(a::Array{Float64,1},b::Array{Float64,1}) -> Array{Float64,2}

Compute the outer product of `a` and `b`, returning a new matrix without modifying either input.

### Arguments
- `a::Array{Float64,1}`: a vector of length `m`.
- `b::Array{Float64,1}`: a vector of length `n`.

### Returns
- `Y::Array{Float64,2}`: a matrix of size `m x n` such that `Y[i,j] = a[i]*b[j]`.
"""
function ⊗(a::Array{Float64,1},b::Array{Float64,1})::Array{Float64,2}

    # initialize -
    m = length(a)
    n = length(b)
    Y = zeros(m,n)

    # main loop 
    for i ∈ 1:m
        for j ∈ 1:n
            Y[i,j] = a[i]*b[j]
        end
    end

    # return 
    return Y
end

"""
    qriteration(A::Array{Float64,2}; maxiter::Int64 = 10, tolerance::Float64 = 1e-9) -> Tuple

Estimate real eigenpairs using unshifted QR iteration. This retained teaching
helper is not used by the urea notebook. Use a nonempty square matrix whose QR
iterates converge to a real diagonal form (for example, suitable symmetric
matrices); general real matrices with complex eigenpairs are not supported.
The input is not modified. Convergence and eigenpair residuals are not certified.

### Arguments
- `A::Array{Float64,2}`: a real matrix of size `n x n`.
- `maxiter::Int64`: positive maximum number of iterations (default `10`).
- `tolerance::Float64`: positive absolute tolerance on the 2-norm of successive
  diagonal estimates; also used for RREF pivots (default `1e-9`).

### Returns
- `(values, vectors)`: ascending eigenvalue estimates and a dictionary whose
  integer keys match their positions. Vectors are normalized unless both
  extraction attempts fail, in which case a zero vector is returned.

Reaching `maxiter` returns the current estimates without a convergence flag.
The first diagonal comparison uses `diag(Q)` from the initial factorization.
Check `norm(A*v - λ*v)` for each returned eigenpair before using it.
"""
function qriteration(A::Array{Float64,2}; 
    maxiter::Int64 = 10, tolerance::Float64 = 1e-9)::Tuple{Array{Float64,1}, Dict{Int64,Array{Float64,1}}}

    # initialize 
    number_of_rows = size(A,1);
    AD = A;
    ϵ = Inf
    eigenvectors = Dict{Int64,Array{Float64,1}}()

    # compute iteration zero -
    Fₒ = qr(AD)
    Qₒ = Matrix(Fₒ.Q);
    λ = diag(Qₒ)

    # Phase 1: compute eigenvalues
    for _ ∈ 1:maxiter
        
        # factor -
        F = qr(AD)
        Q = Matrix(F.Q);

        # update
        AD = transpose(Q)*AD*Q

        # Check the change in the diagonal estimates -
        λ′ = diag(AD);
        ϵ = norm(λ - λ′)
        if (ϵ < tolerance)
            
            # update the values
            λ = λ′
            
            # we are done with phase 1
            break;
        else
            # have not hit the tolerance - go around some more
            λ = λ′
        end
    end

    # sort the eigenvalues -
    sort!(λ)

    # Phase 2: compute the eigenvectors
    for i ∈ 1:number_of_rows
        
        # setup the homogenous system -
        AH = A - λ[i]*Matrix{Float64}(I, number_of_rows, number_of_rows);
        
        # compute the unscaled eigenvector from the nullspace -
        EVUS = _nullspace_vector(AH; tol = tolerance)

        # compute a scaling normalizing parameter
        d = norm(EVUS);

        # Normalize the vector; the alternating sign is arbitrary for an eigenvector -
        if !(isfinite(d)) || d <= eps(Float64)
            EVUS = _smallest_singular_vector(AH)
            d = norm(EVUS)
        end
        if !(isfinite(d)) || d <= eps(Float64)
            eigenvectors[i] = zeros(number_of_rows)
        else
            eigenvectors[i] = ((-1)^(i+1))*(1/d)*EVUS
        end
    end

    # return -
    return (λ, eigenvectors)
end


"""
    poweriteration(A::Array{<:Number,2}, v::Array{<:Number,1}; 
        maxiter::Int = 100, ϵ::Float64 = 0.0001)

Estimate a dominant eigenpair by normalized power iteration without modifying
the inputs. This retained helper is not used by the urea notebook. Convergence
requires a dominant eigenvalue separated in magnitude and an initial vector
with a component in its eigendirection. Zero iterates are not handled.

### Arguments
- `A::Array{<:Number,2}`: nonempty square numeric matrix.
- `v::Array{<:Number,1}`: nonzero initial vector of matching length, preferably unit norm.
- `maxiter::Int = 100`: The maximum number of iterations (optional).
- `ϵ::Float64 = 0.0001`: tolerance on the squared 2-norm of the change in
  successive vectors. Sign/phase changes can prevent this criterion from passing.

### Output
- `(vector=v, value=λ)`: the last accepted vector and its Rayleigh quotient.
  The newly computed `w` that triggers stopping is not copied into `v`.

The routine stops on the change criterion or iteration limit. Its legacy
"Converged" message is printed in either case, and the return value has no
convergence flag. Check the eigenpair residual; the message is not a certificate.
"""
function poweriteration(A::Array{<:Number,2}, v::Array{<:Number,1}; 
    maxiter::Int = 100, ϵ::Float64 = 0.0001)::NamedTuple

    # initialize
    loopcount = 1;
    should_we_stop = false;

    while (should_we_stop == false)
        
        # compute the next iteration
        w = A * v;
        w = w / norm(w);

        # check if we should stop
        if (norm(w - v)^2 ≤ ϵ || loopcount ≥ maxiter)
            should_we_stop = true;
            println("Converged in $(loopcount) iterations"); # legacy message also appears when the iteration limit is reached
        else
            v = w; # update the vector
            loopcount = loopcount + 1; # update the loop count
        end
    end
    
    # compute the eigenvalue -
    λ = dot(A * v, v) / dot(v, v);

    # return the result
    return (vector = v, value = λ);
end