### ===== PRIVATE METHODS BELOW HERE ============================================================================================= ###
"""
    evaluate(model::VLLinearUtilityFunction, dependent::Array{Float64,1}) -> Float64

Evaluate a linear utility function `U(x) = sum(α .* x)` at the point `dependent`, where `α = model.α`.
"""
function evaluate(model::VLLinearUtilityFunction, dependent::Array{T,1})::Float64 where T <: Real

    # get parameters from model -
    α = model.α;

    # dot product -
    return sum(α.*dependent);
end

function _obj_function(x, utility, model)::Float64

    # evaluate the utility model -
    U_model = evaluate(model, x);

    # compute the error -
    error = (U_model - utility).^2;

    # return -
    return error;
end
### ===== PRIVATE METHODS ABOVE HERE ============================================================================================= ###


### ===== PUBLIC METHODS BELOW HERE ============================================================================================= ###
"""
    indifference(model::VLLinearUtilityFunction;
        utility::Float64=1.0, bounds::Array{T,2}, ϵ::Float64 = 0.01) where T <: Real -> Array{Float64,2}

Trace an indifference curve for a linear utility function: for a sequence of values of the first good (stepped by
`ϵ` across `bounds[1,:]`), find the value of the remaining good(s) that keeps total utility equal to `utility`,
by minimizing the squared error between the model's utility and the target `utility` with `Optim.jl`
(`NelderMead` inside `Fminbox`).

### Arguments
- `model::VLLinearUtilityFunction`: the linear utility function model (holds the preference weights `α`).
- `utility::Float64`: the target utility level to trace the indifference curve for. Default is `1.0`.
- `bounds::Array{T,2}`: bounds on each good, one row per good, columns are `[lower upper]`.
- `ϵ::Float64`: the step size used to march across the first good's bounds. Default is `0.01`.

### Returns
- `Array{Float64,2}`: an array of points `(x₁, x₂, ...)` lying on the indifference curve.
"""
function indifference(model::VLLinearUtilityFunction;
    utility::Float64=1.0, bounds::Array{T,2}, ϵ::Float64 = 0.01) where T <: Real

    # how many steps are we going to take?
    number_of_steps = Int(floor((bounds[1,end] - bounds[1,1])/ϵ));
    number_of_features = size(bounds, 1);
    solution = zeros(number_of_steps, number_of_features);

    # setup the optimizer -
    inner_optimizer = NelderMead()
    obj_function(x) =  _obj_function(x, utility, model)

    base = bounds[1,1];
    for i ∈ 1:number_of_steps

        # formulate the bounds -
        tmp_bounds = zeros(number_of_features, 2);

        for j ∈ 1:number_of_features

            if (j == 1)
                tmp_bounds[j,1] = base;
                tmp_bounds[j,2] = base + ϵ;
            else
                tmp_bounds[j,1] = bounds[j,1];
                tmp_bounds[j,2] = bounds[j,2];
            end
        end

        # setup the IC -
        L = tmp_bounds[:,1];
        U = tmp_bounds[:,2];
        xₒ = (L .+ U)./2.0;

        # setup optimizer, objective function and solve -
        results = optimize(obj_function, L, U, xₒ, Fminbox(inner_optimizer),
            Optim.Options(time_limit = 600, show_trace = false, iterations=100))

        # grab the best parameters -
        x_best = Optim.minimizer(results)

        # add to solution -
        solution[i,:] .= x_best;

        # update the base -
        base += ϵ;
    end

    # return -
    return solution
end
### ===== PUBLIC METHODS ABOVE HERE ============================================================================================= ###
