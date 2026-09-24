# plot_teaching_flow(...)

```julia
plot_teaching_flow(department::NamedTuple, network::NamedTuple,
    result::Union{Nothing,NamedTuple} = nothing;
    title::AbstractString = "Teaching-assignment network",
    atol::Real = 1e-8, theme::Symbol = :auto)
```

Draw the teaching-assignment network in five columns: the source, the faculty (circles labeled A–J), the courses (boxes labeled with their codes), the course completion nodes (small unlabeled circles beside their courses), and the sink. `network` must come from [the `build_teaching_network(...)` function](build_teaching_network.md) for the same `department`.

Without a `result`, the figure shows the network before solving. Every gray faculty → course arrow is an available assignment. Unspecified preferences have the default score and remain available.

With an optimal `result` from [the `solve_flow_lp(...)` function](solve_flow_lp.md) or [the `solve_min_cost_flow(...)` function](solve_min_cost_flow.md), red arrows carry flow and thin gray arrows carry no flow. Each faculty → course arrow in the schedule is labeled with its cost `w` (the survey score, or a value set with [the `with_cost(...)` function](scenario_helpers.md)), and the required flow and total cost appear below the title. Arrow width marks the schedule; it does not scale with flow. `atol` is the flow threshold, in assignments, for drawing an arrow as part of the schedule. For an infeasible result, the network is drawn in gray, and the line below the title reports that no feasible schedule exists; any other unsuccessful status is reported as it is.

`theme = :auto` follows the current Plots theme selected in the setup cell. `:light` (alias `:default`) or `:dark` draws one figure on that background without changing the global theme. Returns a `Plots.Plot`.

The helper is in [FlowPlots.jl](../src/FlowPlots.jl), loaded by [Include.jl](../Include.jl). See Tasks 1–3 of [the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
