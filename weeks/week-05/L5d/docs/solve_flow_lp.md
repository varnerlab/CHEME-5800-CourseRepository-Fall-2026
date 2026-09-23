# solve_flow_lp(...)

```julia
solve_flow_lp(network, A, b, w, lower, capacity)
```

Solve the minimum-cost flow linear program with JuMP and GLPK:

$$
\min_{\mathbf{f}}\ \sum_{j\in\mathcal{E}} w_j f_j\quad\text{subject to}\quad \mathbf{A}\mathbf{f}=\mathbf{b},\quad \ell_j\leq f_j\leq c_j\ \ \forall j\in\mathcal{E}.
$$

Pass the arrays assembled in Task 2 of the lab. `A` has one row per node (row `i` is node `i`) and one column per edge in `network.edges` order; `b` has one entry per node; `w` (the costs $w_j$), `lower` (the lower bounds $\ell_j$), and `capacity` (the capacities $c_j$) have one entry per edge in the same order. Flows and bounds are measured in assignments, and costs in survey-score points per assignment. `network` comes from [the `build_teaching_network(...)` function](build_teaching_network.md) and supplies the edge endpoints for the returned flow dictionary. Mismatched sizes raise a `DimensionMismatch`.

The returned named tuple contains `status` (the solver's termination status), `optimal`, `flow` (a dictionary from `(source, target)` pairs to flows), `vector` (flows in edge order), `cost` (the solver-reported objective), and `formulation` (the arrays, with `vertices`). When the status is not `OPTIMAL`, for example `INFEASIBLE`, the flow fields and the cost are `nothing`, because there is no schedule to read. Check the status first. The returned flows still require independent checks of feasibility and cost.

See the docstring in [Compute.jl](../src/Compute.jl), loaded by [Include.jl](../Include.jl), and Task 2 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
