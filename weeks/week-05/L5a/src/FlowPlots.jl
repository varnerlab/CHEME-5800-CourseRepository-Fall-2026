# =============================================================================
# CHEME 5800 | L5a plotting helper
# =============================================================================
# Draws the worker–task flow network for the L5a worked example. The meeting's
# Include.jl loads this file, so the notebook calls plot_flow_network(...) directly.
# Plots and Colors are already in scope from Include.jl.
# =============================================================================

# Canvas colors for an explicit figure theme. Each entry sets every color
# attribute that Plots' own `theme(:dark)` sets, so an explicit choice overrides
# the global theme completely in either direction, and the dark values are
# copied from that theme so a per-figure choice looks the same as the global one.
const _FIGURE_THEMES = Dict(
    :light => (background_color = :white, background_color_inside = :white,
        foreground_color = :black, foreground_color_text = :black,
        foreground_color_guide = :black, foreground_color_legend = :black,
        legendfontcolor = :black, legendtitlefontcolor = :black, titlefontcolor = :black),
    :dark => (background_color = "#363D46", background_color_inside = "#30343B",
        foreground_color = "#ADB2B7", foreground_color_text = "#FFFFFF",
        foreground_color_guide = "#FFFFFF", foreground_color_legend = "#FFFFFF",
        legendfontcolor = "#FFFFFF", legendtitlefontcolor = "#FFFFFF", titlefontcolor = "#FFFFFF"),
)

"""
    _figure_theme_attributes(theme)

Return the `plot(...)` keyword attributes for `theme`: nothing for `:auto`, so the
figure inherits the current Plots theme, or an explicit canvas for `:light`
(alias `:default`) and `:dark`.
"""
function _figure_theme_attributes(theme::Symbol)
    theme === :auto && return NamedTuple()
    theme === :default && (theme = :light)
    haskey(_FIGURE_THEMES, theme) ||
        throw(ArgumentError("theme must be :auto, :light, :default, or :dark; got :$(theme)"))
    return _FIGURE_THEMES[theme]
end

"""
    plot_flow_network(graph, coordinates; flow = nothing, title = "Flow network", theme = :auto)

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
- `theme`: `:auto` (default) follows the current Plots theme selected with
  `theme(:default)` or `theme(:dark)`. `:light` or `:dark` draws this figure on
  that background regardless of the global setting; `:default` is accepted as
  an alias for `:light`. The global theme is not changed.

# Returns
A `Plots.Plot` object. If all capacities agree, state the common capacity once.
When a flow is supplied, draw positive-flow edges in red and label them with
`flow / capacity`; gray edges carry zero flow. For unequal capacities, label
every edge. The graph, coordinates, and flow dictionary are not modified.
The canvas and annotations follow the current Plots theme unless `theme` selects
one explicitly.
"""
function plot_flow_network(graph, coordinates; flow = nothing, title = "Flow network", theme = :auto)
    # Check the inputs; this drawing is specific to the 13-node example layout -
    size(coordinates) == (13, 2) || throw(DimensionMismatch("expected 13 × 2 node coordinates"))
    sort(collect(keys(graph.nodes))) == collect(1:13) ||
        throw(ArgumentError("this drawing uses the L5a node identifiers 1:13"))
    canvas = _figure_theme_attributes(theme) # empty for :auto, explicit colors otherwise

    # Collect the edges and decide how much labeling the figure needs -
    edges = sort(collect(keys(graph.capacity)))
    capacities = [graph.capacity[edge][2] for edge in edges]
    common_capacity = all(==(first(capacities)), capacities)
    show_flow = !isnothing(flow)
    atol = 1e-8 # flow below this plotting threshold is shown as zero

    # Open the canvas with room above for group labels and below for the caption -
    y_min, y_max = extrema(coordinates[:, 2])
    x_min, x_max = extrema(coordinates[:, 1])
    figure = plot(; axis = nothing, border = :none, legend = false, title = title,
        titlefontsize = 15, xlim = (x_min - 0.55, x_max + 0.55),
        ylim = (y_min - 0.65, y_max + 0.85), size = (1100, 580), canvas...)

    # Read the resolved colors back from the figure, so :auto and an explicit
    # theme take the same path. A background whose RGB components sum to less
    # than 1.5 (of 3) counts as dark; red keeps its meaning on either background.
    background = figure[:background_color]
    dark_background = (red(background) + green(background) + blue(background)) < 1.5
    label_color = figure[1][:foreground_color_subplot]
    active_color = dark_background ? "#ff786e" : :crimson
    inactive_color = dark_background ? "#aeb7c3" : :gray55

    # Draw edges; place positive flow last so it remains visible at crossings -
    if show_flow
        sort!(edges; by = edge -> (get(flow, edge, 0.0) > atol, edge))
    end
    for edge in edges
        u, v = edge
        value = show_flow ? get(flow, edge, 0.0) : 0.0
        active = show_flow && value > atol
        color = active ? active_color : inactive_color
        width = active ? 3.2 : 1.5
        x, y = coordinates[u, :]
        dx, dy = coordinates[v, :] - coordinates[u, :]
        # Shorten each end so arrowheads stop at the marker boundary; 0.10 and
        # 0.17 are the marker's half-widths in data units, capped at 35% of the edge -
        trim = min(0.35, inv(hypot(dx / 0.10, dy / 0.17)))
        plot!(figure, [x + trim * dx, x + (1 - trim) * dx],
            [y + trim * dy, y + (1 - trim) * dy];
            arrow = true, color = color, lw = width, label = "")
        if !common_capacity || active
            upper = graph.capacity[edge][2]
            capacity_label = isinteger(upper) ? string(Int(upper)) : string(round(upper; digits = 2))
            flow_label = isinteger(value) ? string(Int(value)) : string(round(value; digits = 2))
            label = show_flow ? flow_label * " / " * capacity_label : capacity_label
            # Place the label just above the edge, a third of the way along it -
            annotate!(figure, x + 0.35 * dx, y + 0.35 * dy + 0.14, text(label, 10, color))
        end
    end

    # Label the node groups above their columns, then draw the numbered nodes -
    groups = [(1:1, "Source"), (2:4, "Workers"), (5:8, "Tasks"),
        (9:12, "Task completion"), (13:13, "Sink")]
    for (vertices, label) in groups
        group_x = sum(coordinates[v, 1] for v in vertices) / length(vertices)
        annotate!(figure, group_x, y_max + 0.57, text(label, 12, label_color))
    end
    for vertex in 1:13
        # Source green, sink red, everything else gray; white numerals read on all three -
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
    annotate!(figure, (x_min + x_max) / 2, y_min - 0.43, text(caption, 10, label_color))
    return figure
end
