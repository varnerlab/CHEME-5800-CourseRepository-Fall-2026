"""
    plot_flow_network(graph, coordinates; flow = nothing, title = "Flow network")

Draw the 13-node worker–task network used in the L5a worked example.

# Arguments
- `graph`: A flow graph with nodes `1:13`, source `1`, sink `13`, and edge
  capacities measured in assignments. Nodes `2:4` are workers, `5:8` are tasks,
  and `9:12` are the corresponding task-completion nodes.
- `coordinates`: A `13 × 2` matrix. Row `v` gives the horizontal and vertical
  drawing coordinates of node `v`; these coordinates have no physical units.
  The five node groups should occupy separate columns in source-to-sink order.
- `flow`: Optional dictionary mapping `(u, v)` edges to flow in assignments.
  Missing entries represent zero flow. With `nothing`, draw the capacities
  without displaying a computed flow. This function does not validate a flow.
- `title`: Text displayed above the network.

# Returns
A `Plots.Plot` object. If all capacities agree, state the common capacity once.
When a flow is supplied, draw positive-flow edges in red and label them with
`flow / capacity`; gray edges carry zero flow. For unequal capacities, label
every edge. The graph, coordinates, and flow dictionary are not modified.
"""
function plot_flow_network(graph, coordinates; flow = nothing, title = "Flow network")
    # Initialize -
    size(coordinates) == (13, 2) || throw(DimensionMismatch("expected 13 × 2 node coordinates"))
    sort(collect(keys(graph.nodes))) == collect(1:13) ||
        throw(ArgumentError("this drawing uses the L5a node identifiers 1:13"))
    edges = sort(collect(keys(graph.capacity)))
    capacities = [graph.capacity[edge][2] for edge in edges]
    common_capacity = all(==(first(capacities)), capacities)
    show_flow = !isnothing(flow)
    atol = 1e-8 # flow below this plotting threshold is shown as zero
    y_min, y_max = extrema(coordinates[:, 2])
    x_min, x_max = extrema(coordinates[:, 1])
    figure = plot(; axis = nothing, border = :none, legend = false, title = title,
        titlefontsize = 15, xlim = (x_min - 0.55, x_max + 0.55),
        ylim = (y_min - 0.65, y_max + 0.85), size = (1100, 580))

    # Draw edges; place positive flow last so it remains visible at crossings -
    if show_flow
        sort!(edges; by = edge -> (get(flow, edge, 0.0) > atol, edge))
    end
    for edge in edges
        u, v = edge
        value = show_flow ? get(flow, edge, 0.0) : 0.0
        active = show_flow && value > atol
        color = active ? :crimson : :gray55
        width = active ? 3.2 : 1.5
        x, y = coordinates[u, :]
        dx, dy = coordinates[v, :] - coordinates[u, :]
        # Stop at the marker boundary so arrowheads remain visible -
        trim = min(0.35, inv(hypot(dx / 0.10, dy / 0.17)))
        plot!(figure, [x + trim * dx, x + (1 - trim) * dx],
            [y + trim * dy, y + (1 - trim) * dy];
            arrow = true, color = color, lw = width, label = "")
        if !common_capacity || active
            upper = graph.capacity[edge][2]
            capacity_label = isinteger(upper) ? string(Int(upper)) : string(round(upper; digits = 2))
            flow_label = isinteger(value) ? string(Int(value)) : string(round(value; digits = 2))
            label = show_flow ? flow_label * " / " * capacity_label : capacity_label
            annotate!(figure, x + 0.35 * dx, y + 0.35 * dy + 0.14, text(label, 10, color))
        end
    end

    # Identify the node groups and their original numerical IDs -
    groups = [(1:1, "Source"), (2:4, "Workers"), (5:8, "Tasks"),
        (9:12, "Task completion"), (13:13, "Sink")]
    for (vertices, label) in groups
        group_x = sum(coordinates[v, 1] for v in vertices) / length(vertices)
        annotate!(figure, group_x, y_max + 0.57, text(label, 12, :gray20))
    end
    for vertex in 1:13
        color = vertex == graph.source ? :seagreen : vertex == graph.sink ? :firebrick : :slategray
        scatter!(figure, [coordinates[vertex, 1]], [coordinates[vertex, 2]];
            c = color, ms = 13, markerstrokecolor = :white, markerstrokewidth = 1, label = "")
        annotate!(figure, coordinates[vertex, 1], coordinates[vertex, 2], text(string(vertex), 10, :white))
    end

    # Explain units and the displayed edge labels -
    if common_capacity
        upper = first(capacities)
        capacity_label = isinteger(upper) ? string(Int(upper)) : string(round(upper; digits = 2))
        unit_label = upper == 1 ? "assignment" : "assignments"
        caption = "Every edge has a capacity of " * capacity_label * " " * unit_label * "."
    else
        caption = "Edge capacities are measured in assignments."
    end
    if show_flow
        caption *= "  Red: positive flow (flow / capacity). Gray: zero flow."
    end
    annotate!(figure, (x_min + x_max) / 2, y_min - 0.43, text(caption, 10, :gray20))
    return figure
end
