# ================================================================================================ #
# Indifference.jl
#
# Linear utility functions and their indifference curves. A linear utility function scores a bundle
# of goods x = (x₁, x₂, …) as U(x) = Σᵢ αᵢ⋅xᵢ, where xᵢ is the quantity of good i and αᵢ is its
# weight: how much one unit of good i is worth to the consumer. An indifference curve is the set of
# bundles that all have the same utility, so the consumer likes each of them equally. The week 5
# (L5c) fruit problem uses a linear utility of this kind as its objective; the course notebooks do
# not call these functions.
#
# Functions in this file:
#   evaluate(...)        the utility U(x) = Σᵢ αᵢ⋅xᵢ of a bundle x
#   _obj_function(...)   (private) the squared error (U(x) − target)², which indifference(...) minimizes
#   indifference(...)    points (x₁, x₂, …) on the indifference curve U(x) = target
#
# A leading underscore in a name marks a private helper, which the package does not export.
# optimize, NelderMead, Fminbox, and Optim.Options come from the Optim package, which the package
# module loads with `using Optim`.
# ================================================================================================ #

### ===== PRIVATE METHODS BELOW HERE ============================================================================================= ###
"""
    evaluate(model::VLLinearUtilityFunction, dependent::Array{T,1}) where T <: Real -> Float64

Evaluate the linear utility function `U(x) = Σᵢ αᵢ⋅xᵢ` at the bundle `x`, where `α = model.α`.

### Arguments
- `model::VLLinearUtilityFunction`: the utility function; its field `α` holds the weight `αᵢ` of
  each good.
- `dependent::Array{T,1}`: the bundle `x`, one quantity per good, in the same order as `α`.
  `where T <: Real` means the entries can be any real number type.

### Returns
- `Float64`: the utility `U(x)`.

### Example
```julia
model = build(VLLinearUtilityFunction, (α = [0.55, 0.45],));
evaluate(model, [2.0, 4.0]) # 0.55*2 + 0.45*4 ≈ 2.9
```
"""
function evaluate(model::VLLinearUtilityFunction, dependent::Array{T,1})::Float64 where T <: Real

    # get the weights α from the model -
    α = model.α;

    # dot product: α.*dependent multiplies the two vectors entry by entry, and sum(...) adds the products -
    return sum(α.*dependent);
end

"""
    _obj_function(x, utility, model) -> Float64

Compute the squared error between the utility of the bundle `x` and the target utility:
`(U(x) − utility)²`.

The error is zero exactly when `x` lies on the indifference curve `U(x) = utility`.
`indifference(...)` minimizes this error to find points on the curve.

### Arguments
- `x`: the bundle, a vector with one quantity per good.
- `utility`: the target utility.
- `model`: the utility function, a `VLLinearUtilityFunction`.

### Returns
- `Float64`: the squared error `(U(x) − utility)²`.
"""
function _obj_function(x, utility, model)::Float64

    # evaluate the utility model at x -
    U_model = evaluate(model, x);

    # compute the squared error. Both sides are numbers, so .^2 is the ordinary square -
    error = (U_model - utility).^2;

    # return -
    return error;
end
### ===== PRIVATE METHODS ABOVE HERE ============================================================================================= ###


### ===== PUBLIC METHODS BELOW HERE ============================================================================================= ###
"""
    indifference(model::VLLinearUtilityFunction; utility::Float64 = 1.0,
        bounds::Array{T,2}, ϵ::Float64 = 0.01) where T <: Real -> Array{Float64,2}

Trace an indifference curve of a linear utility function: find bundles `x = (x₁, x₂, …)` whose
utility `U(x) = Σᵢ αᵢ⋅xᵢ` equals the target `utility`.

We march across the range of the first good, `bounds[1,1]` to `bounds[1,2]`, in steps of width `ϵ`.
In step `i`, the first good may take any value in the small interval `[base, base + ϵ]`, where
`base = bounds[1,1] + (i − 1)⋅ϵ`, and every other good may take any value within its bounds. Within
this box, we minimize the squared error `(U(x) − utility)²` with the Optim package. `Fminbox` is
Optim's method for a search with lower and upper bounds, and `NelderMead` does the search with
function values only, no derivatives. The search starts from the center of the box. The bundle
the search returns becomes row `i` of the result.

The function does not check the bundles it returns. A row is off the curve when no bundle in its
box reaches the target utility. A row can also lie outside its box: in a test with Optim 1.13,
`Fminbox` with `NelderMead` returned first-good values above `base + ϵ`, with utilities that missed
the target. Check the rows with `evaluate(...)`. With three or more goods, many bundles in a box
reach the target, and the search returns one of them.

### Arguments
- `model::VLLinearUtilityFunction`: the utility function; its field `α` holds the weight of each good.
- `utility::Float64 = 1.0`: the target utility of the indifference curve.
- `bounds::Array{T,2}`: the bounds of each good, one row per good: column 1 is the lower bound and
  column 2 is the upper bound. This keyword argument has no default.
- `ϵ::Float64 = 0.01`: the step width across the range of the first good.

### Returns
- `Array{Float64,2}`: the points on the curve, one row per step and one column per good. The number
  of rows is `floor((bounds[1,2] − bounds[1,1])/ϵ)`.
"""
function indifference(model::VLLinearUtilityFunction;
    utility::Float64=1.0, bounds::Array{T,2}, ϵ::Float64 = 0.01) where T <: Real # where T <: Real: the bounds can have any real number type

    # how many steps are we going to take? floor(...) rounds down, and Int(...) makes the result an integer -
    number_of_steps = Int(floor((bounds[1,end] - bounds[1,1])/ϵ)); # bounds[1,end] is the last column of row 1: the upper bound of the first good
    number_of_features = size(bounds, 1); # the number of goods: one row of bounds per good
    solution = zeros(number_of_steps, number_of_features); # one row per step, one column per good

    # set up the optimizer. obj_function is a one-line function defined inside this function: it
    # takes only the bundle x, which is what optimize(...) needs, and passes the target utility
    # and the model on to _obj_function(...) -
    inner_optimizer = NelderMead()
    obj_function(x) =  _obj_function(x, utility, model)

    # main loop: one step across the range of the first good each pass -
    base = bounds[1,1]; # the lower end of the first good's interval in this step
    for i ∈ 1:number_of_steps

        # formulate the bounds of this step: the first good in [base, base + ϵ], the others in their full range -
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

        # set up the initial condition: the center of the box. L holds the lower bounds and U the
        # upper bounds (here U is not the utility). (L .+ U)./2.0 averages them entry by entry -
        L = tmp_bounds[:,1];
        U = tmp_bounds[:,2];
        xₒ = (L .+ U)./2.0;

        # minimize the squared error, passing the box bounds L and U through Fminbox(...).
        # Optim.Options(...) sets a time limit of 600 seconds, turns off the progress printout,
        # and sets iterations = 100 -
        results = optimize(obj_function, L, U, xₒ, Fminbox(inner_optimizer),
            Optim.Options(time_limit = 600, show_trace = false, iterations=100))

        # grab the best bundle the search found -
        x_best = Optim.minimizer(results)

        # add the bundle to the solution as row i. .= copies the entries into the row -
        solution[i,:] .= x_best;

        # move the first good's interval up by one step. base += ϵ means base = base + ϵ -
        base += ϵ;
    end

    # return the points on the curve -
    return solution
end
### ===== PUBLIC METHODS ABOVE HERE ============================================================================================= ###
