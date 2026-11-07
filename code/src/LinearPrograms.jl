# ------------------------------------------------------------------------------------------------ #
# LinearPrograms.jl
#
# The fruit-allocation linear program of the week 5 (L5c) linear programming material: a shopper
# with a fixed budget chooses how much of each fruit (each good) to buy, to get the most total
# utility. Utility is a number that scores how much the shopper values a purchase. The L5c
# fruit-problem example builds and solves this problem with the package's solve(...) function;
# solve_fruit_problem(...) solves the same problem in a single call.
#
# Functions in this file:
#   solve_fruit_problem(...)   the quantity of each good that gives the most utility within the budget
# ------------------------------------------------------------------------------------------------ #

import GLPK # the GLPK linear programming solver
import JuMP # JuMP builds optimization models and passes them to a solver
import LinearAlgebra: dot # dot(p, x) = Σᵢ pᵢ⋅xᵢ, the dot product of two vectors
const MOI = JuMP.MOI   # JuMP re-exports MathOptInterface, which is not a direct dependency


"""
    solve_fruit_problem(utilities::AbstractVector{<:Real}, prices::AbstractVector{<:Real},
        budget::Real) -> NamedTuple

Find how much of each good to buy to get the most total utility without exceeding the budget.

We solve the linear program

    maximize Σᵢ uᵢ⋅xᵢ   subject to   Σᵢ pᵢ⋅xᵢ ≤ B   and   xᵢ ≥ 0 for every good i

where `xᵢ` is the quantity of good `i` (for example, the number of apples), `uᵢ` is the utility
of one unit of good `i`, `pᵢ` is the price of one unit, and `B` is the budget. JuMP builds the
model, and the GLPK solver solves it. When some good has a positive utility, an optimal plan
spends the whole budget on the goods with the largest utility per dollar, `uᵢ/pᵢ`. The solver
returns one optimal plan; when several goods tie for the largest `uᵢ/pᵢ`, other plans are just as good.

### Arguments
- `utilities::AbstractVector{<:Real}`: the utility `uᵢ` of one unit of each good. Each must be
  finite and at least zero. `AbstractVector{<:Real}` means a vector of any real number type.
- `prices::AbstractVector{<:Real}`: the price `pᵢ` of one unit of each good, in the same order as
  `utilities`. Each must be finite and greater than zero.
- `budget::Real`: the budget `B`. It must be finite and at least zero.

### Returns
A `NamedTuple` with the fields:
- `quantities::Vector{Float64}`: the optimal quantity `xᵢ` of each good.
- `utility::Float64`: the total utility of that plan, `Σᵢ uᵢ⋅xᵢ`.
- `expenditure::Float64`: the money the plan spends, `Σᵢ pᵢ⋅xᵢ`.
- `status`: the solver's termination status, which is `OPTIMAL` here, because any other status
  throws an error.
- `utility_per_dollar::Vector{Float64}`: the utility per dollar `uᵢ/pᵢ` of each good.

### Throws
- `DimensionMismatch` if `utilities` and `prices` have different lengths.
- `ArgumentError` if there are no goods; if a utility or a price is not finite; if a utility is
  negative; if a price is zero or negative; or if the budget is negative or not finite.
- `ErrorException` if the solver does not report an optimal solution.

### Example
```julia
result = solve_fruit_problem([0.55, 0.45], [2.0, 4.0], 100.0);
result.quantities # [50.0, 0.0]: all apples, which give more utility per dollar than oranges
```
"""
function solve_fruit_problem(
    utilities::AbstractVector{<:Real},
    prices::AbstractVector{<:Real},
    budget::Real,
)
    # check the inputs. Each line reads "condition || throw(...)": if the condition is false,
    # stop with an error. The line "condition && throw(...)" stops with an error when the condition is true -
    length(utilities) == length(prices) || throw(DimensionMismatch("utilities and prices must have equal length"))
    isempty(utilities) && throw(ArgumentError("at least one good is required")) # stop if there are no goods
    all(isfinite, utilities) || throw(ArgumentError("utilities must be finite")) # all(f, x) is true when f is true for every entry of x
    all(isfinite, prices) || throw(ArgumentError("prices must be finite"))
    all(>=(0), utilities) || throw(ArgumentError("utilities must be nonnegative")) # >=(0) is the test "x >= 0"
    all(>(0), prices) || throw(ArgumentError("prices must be positive")) # >(0) is the test "x > 0"
    isfinite(budget) && budget >= 0 || throw(ArgumentError("budget must be finite and nonnegative")) # && is checked first: if the budget is not both finite and at least zero, stop

    # convert the inputs to Float64. Float64.(x) converts every entry (the dot applies the
    # conversion to each one), and the one line assigns all three names at once -
    u, p, available = Float64.(utilities), Float64.(prices), Float64(budget)

    # build the model: JuMP with the GLPK solver, and no solver printout -
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model)
    n = length(u) # the number of goods

    # the decision variables: n quantities x[1], …, x[n], each at least zero -
    x = JuMP.@variable(model, x[1:n] >= 0)

    # the budget constraint: Σᵢ pᵢ⋅xᵢ ≤ B. The generator inside sum(...) builds the terms p[i]*x[i] for i = 1, …, n -
    JuMP.@constraint(model, sum(p[i] * x[i] for i in 1:n) <= available)

    # the objective: maximize the total utility Σᵢ uᵢ⋅xᵢ -
    JuMP.@objective(model, Max, sum(u[i] * x[i] for i in 1:n))

    # solve, and check that the solver found an optimal solution -
    JuMP.optimize!(model)
    status = JuMP.termination_status(model) # why the solver stopped, e.g., OPTIMAL or INFEASIBLE
    status == MOI.OPTIMAL || throw(ErrorException("fruit LP did not solve to optimality: $(status)")) # if the status is not OPTIMAL, stop with an error

    # read the optimal quantities. JuMP.value.(x) applies JuMP.value to each variable -
    quantities = JuMP.value.(x)

    # return the plan, its utility and cost, the status, and the utility per dollar of each
    # good. u ./ p divides entry by entry: u[i]/p[i] -
    return (
        quantities = quantities,
        utility = JuMP.objective_value(model),
        expenditure = dot(p, quantities),
        status = status,
        utility_per_dollar = u ./ p,
    )
end
