# plot_cost_flow(...)

```julia
plot_cost_flow(edges, result, coordinates;
    title = "Minimum-cost assignment flow", atol::Real = 1e-8)
```

Draw the L5d assignment network from directed edge records, their solved flows, and a finite 13-by-2 coordinate matrix. Row `i` holds the position of node `i`; coordinates control the drawing only. Use the lab's node identifiers (source 1, workers 2–4, tasks 5–8, completion nodes 9–12, sink 13) and layered positions increasing from left to right.

The result is a `Plots.Plot`. Blue arrows show flow greater than `atol` (assignments), thin gray arrows show available unused edges, and dashed gray arrows show capacities at or below the threshold. Labels on positive-flow edges show unit cost `w`, in cost units per assignment. The heading reports required flow and solver cost from `result`. All labels use up to four decimal places; model values are unchanged. Arrow width distinguishes selected edges and does not encode flow magnitude. `atol` must be finite and nonnegative.

Pass a result solved for the supplied edge list and check feasibility before interpreting the figure. Only positive-flow edges receive cost labels; all edge costs remain available in the input data. The drawing assumes the lab's node roles and layered layout.

See [FlowPlots.jl](../src/FlowPlots.jl), loaded by [Include.jl](../Include.jl), and [Task 2 of the lab](../CHEME-5800-L5d-Lab-MinimumCostAssignmentFlow-Fall-2026.ipynb).
