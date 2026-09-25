# -- PRIVATE METHODS BELOW HERE ------------------------------------------------------------------------------- #


"""
    _flux(problem::MyPrimalFluxBalanceAnalysisCalculationModel) -> Dict{String,Any}

Build and solve the steady-state linear program with GLPK. Maximize `c' * x`
subject to `S*x == 0` and the supplied lower/upper flux bounds. The input model
is not modified. See `solve` for dimensions, result keys, and failure behavior.
"""
function _flux(problem::MyPrimalFluxBalanceAnalysisCalculationModel)

    # initialize -
    results = Dict{String,Any}()
    c = problem.objective; # objective function coefficients

    # bounds -
    fluxbounds = problem.fluxbounds;
    lb = fluxbounds[:, 1]; # lower bounds
    ub = fluxbounds[:, 2]; # upper bounds
        
    # Steady-state species balances -
    A = problem.S; # species rows × reaction columns

    # how many variables do we have?
    d = length(c);

    # Setup the problem -
    model = Model(GLPK.Optimizer)
    @variable(model, lb[i,1] <= x[i=1:d] <= ub[i,1], start=0.0) # we have d variables
    
    # Maximize the weighted signed fluxes -
    @objective(model, Max, transpose(c)*x);
    @constraints(model, 
        begin
            A*x == 0 # zero net production of every balanced species
        end
    );

    # run the optimization -
    optimize!(model)

    # check: was the optimization successful?
    @assert is_solved_and_feasible(model)

    # populate -
    x_opt = value.(x);
    results["argmax"] = x_opt
    results["objective_value"] = objective_value(model);

    # return -
    return results
end
# -- PRIVATE METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# -- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    softmax(x::Array{Float64,1})::Array{Float64,1}

Compute the softmax of a vector. 
This function takes a vector of real numbers and returns a vector of the same size with the softmax of the input vector, 
i.e., the exponential of the input vector divided by the sum of the exponential of the input vector.


This direct exponential implementation does not shift the input for numerical
stability. Use values for which the exponentials and their sum are finite and
nonzero; extreme inputs can overflow or underflow. The input is not modified.

### Arguments
- `x::Array{Float64,1}`: a nonempty vector of dimensionless real values.

### Returns
- `::Array{Float64,1}`: a vector of the same size as the input vector with the softmax of the input vector.
"""
function softmax(x::Array{Float64,1})::Array{Float64,1}
    
    # compute the exponential of the vector
    y = exp.(x);
    
    # compute the sum of the exponential
    s = sum(y);
    
    # compute the softmax
    return y / s;
end

"""
    binary(S::Array{Float64,2})::Array{Int64,2}

Convert a matrix of floats to a matrix of binary values. 
Each non-zero element in the input matrix is converted to 1, and each zero element is converted to 0.

### Arguments
- `S::Array{Float64,2}`: a matrix of floats.

### Returns
- `::Array{Int64,2}`: a matrix of binary values.
"""
function binary(S::Array{Float64,2})::Array{Int64,2}
    
    # initialize -
    number_of_rows = size(S, 1);
    number_of_columns = size(S, 2);
    B = zeros(Int64, number_of_rows, number_of_columns);

    # main -
    for i ∈ 1:number_of_rows
        for j ∈ 1:number_of_columns
            if (S[i, j] != 0.0) # if the value is not zero, then B[i,j] = 1
                B[i, j] = 1;
            end
        end
    end

    # return -
    return B;
end

"""
    solve(model::AbstractFluxCalculationModel) -> Dict{String,Any}

Maximize `model.objective' * flux` subject to `model.S * flux == 0` and the
flux bounds. The local implementation supports `MyPrimalFluxBalanceAnalysisCalculationModel`.

### Arguments
- `model`: populated model with `S` of size `m × n`, `fluxbounds` of size
  `n × 2` (lower, upper), and `objective` of length `n`. All reaction-indexed
  entries follow `model.reactions`; species follow the rows of `S`.
  Fluxes and bounds must use consistent units (mmol/gDW/h in the urea example).
  Positive flux follows the written reaction; uptake-positive exchanges
  therefore require a negative objective coefficient to maximize export.

### Returns
- `"argmax"`: optimal flux vector, length `n`, in reaction order and the units
  of the supplied bounds. An optimum need not be unique.
- `"objective_value"`: scalar `model.objective' * result["argmax"]`.

The input model is not mutated. An `AssertionError` is raised if JuMP does not
report a solved, feasible problem, including an infeasible or unbounded problem.
Model construction and solver errors propagate to the caller. Array dimensions
and units are the caller's responsibility; this wrapper does not validate them.
"""
function solve(model::AbstractFluxCalculationModel)
    return _flux(model);
end


"""
    enumerate_binary_variable_cases(number_of_variables::Int) -> Array{Int,2}

Enumerate all possible cases of `n` binary variables

### Arguments
- `number_of_variables::Int`: number of binary variables, from 0 through 8.
  The implementation converts row indices to `UInt8`, so larger cases are unsupported.

### Returns
- `Array{Int,2}`: a `2^n × n` matrix. Row `i` contains the bits of `i-1`,
  most significant bit first; columns identify the binary variables.
"""
function enumerate_binary_variable_cases(number_of_variables::Int)

	# how many binary variables are we going to have?
	number_of_rows = 2^number_of_variables	
	
	# initialize -
	tmp_array = Array{Int,2}(undef, number_of_rows, number_of_variables)

	# main -
	for i ∈ 1:number_of_rows

		# generate a row -
		tmp_row = parse.(Int,Base.bin(UInt8(i-1), number_of_variables ,false) |> collect)

		# add the row to the tmp_array =
		for j ∈ 1:number_of_variables
			tmp_array[i,j] = tmp_row[j]
		end
	end

	return tmp_array
end

# -- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------------------- #