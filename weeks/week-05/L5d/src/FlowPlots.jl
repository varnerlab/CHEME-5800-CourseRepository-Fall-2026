module L5dFlowPlots

import Plots # draw the assignment network and returned flows

export plot_cost_flow

# Test whether a line segment enters a padded label rectangle in screen pixels.
function _crosses_label(a, b, center, halfwidth, halfheight)
    low, high = 0.0, 1.0
    for (start, stop, middle, radius) in zip(a, b, center, (halfwidth, halfheight))
        delta = stop - start
        if abs(delta) < 1e-12
            abs(start-middle) > radius && return false
        else
            t1, t2 = minmax((middle-radius-start)/delta, (middle+radius-start)/delta)
            low, high = max(low, t1), min(high, t2)
            low > high && return false
        end
    end
    return true
end

# Place labels near their edges while avoiding all edges, nodes, and earlier labels.
function _cost_label_positions(edges, result, coordinates, atol)
    xmin, xmax = extrema(coordinates[:,1])
    ymin, ymax = extrema(coordinates[:,2])
    # Approximate the drawing area of the fixed 1000-by-480 canvas, excluding margins.
    sx, sy = 835/(xmax-xmin), 285/(ymax-ymin)
    points = [((coordinates[i,1]-xmin)*sx, (coordinates[i,2]-ymin)*sy) for i in 1:13]
    placed = Tuple{Float64,Float64,Float64}[]
    labels = Tuple{Float64,Float64,String}[]
    for edge in edges
        result.flow[(edge.source,edge.target)] > atol || continue
        label = "w=$(round(edge.cost; digits=4))"
        halfwidth, halfheight = 3.6length(label)+5, 11.0
        start, stop = points[edge.source], points[edge.target]
        vx, vy = stop[1]-start[1], stop[2]-start[2]
        distance = hypot(vx,vy)
        best_score, best = Inf, (0.5(start[1]+stop[1]), 0.5(start[2]+stop[2])+25)
        for offset in 17:47, side in (1,-1), fraction in 0.2:0.05:0.8
            x = start[1]+fraction*vx-side*offset*vy/distance
            y = start[2]+fraction*vy+side*offset*vx/distance
            crossings = count(e -> _crosses_label(points[e.source],points[e.target],
                (x,y),halfwidth,halfheight), edges)
            nodes = count(p -> abs(x-p[1]) < halfwidth+15 &&
                abs(y-p[2]) < halfheight+15, points)
            overlaps = count(p -> abs(x-p[1]) < halfwidth+p[3]+4 &&
                abs(y-p[2]) < 2halfheight+4, placed)
            score = 1000(crossings+nodes+overlaps) + offset +
                20abs(fraction-0.5) + (side < 0 ? 3 : 0)
            if score < best_score
                best_score, best = score, (x,y)
            end
        end
        push!(placed, (best[1],best[2],halfwidth))
        push!(labels, (xmin+best[1]/sx, ymin+best[2]/sy, label))
    end
    return labels
end

"""
    plot_cost_flow(edges, result, coordinates;
        title = "Minimum-cost assignment flow", atol::Real = 1e-8)

Draw the L5d network with selected flows and their costs per assignment.

# Arguments
- `edges`: Directed edge records with `source`, `target`, `cost`, and `upper`.
- `result`: A solution with `flow`, `cost`, and `formulation.b`. Use a result
  solved for the supplied edges; feasibility is checked separately.
- `coordinates`: A finite 13-by-2 matrix; row i holds node i's drawing position.
  Coordinates are dimensionless and do not affect the optimization.
- `title`: Figure heading.
- `atol`: Finite, nonnegative flow threshold in assignments. Flows above it
  are highlighted; capacities at or below it are displayed as unavailable.

# Returns and scope
Returns a `Plots.Plot` for the lab's source 1, workers 2–4, tasks 5–8,
completion nodes 9–12, and sink 13. Node groups are labeled above their positions.
Blue arrows show positive flow; thin gray arrows show available unused edges;
unavailable edges are dashed. Only positive-flow edges receive cost labels.
The legend distinguishes positive flow from unit cost w (cost units per
assignment). Numbers display up to four decimal places; no rounding is applied
in the optimization or validation. This helper assumes the lab's layered layout,
with increasing horizontal positions from source to sink.
"""
function plot_cost_flow(edges, result, coordinates;
        title = "Minimum-cost assignment flow", atol::Real = 1e-8)
    size(coordinates) == (13, 2) || throw(DimensionMismatch("expected 13 node positions with two coordinates each"))
    all(isfinite, coordinates) || throw(ArgumentError("node coordinates must be finite"))
    isfinite(atol) && atol >= 0 || throw(ArgumentError("atol must be finite and nonnegative"))
    number(value) = string(round(value; digits = 4))

    # Initialize the canvas from the supplied drawing positions -
    xmin, xmax = extrema(coordinates[:, 1])
    ymin, ymax = extrema(coordinates[:, 2])
    dx, dy = xmax - xmin, ymax - ymin
    dx > 0 && dy > 0 || throw(ArgumentError("the layered layout must span both axes"))
    active_color, muted_color = "#0072B2", "#D0D5DA"
    delivered_flow = sum(value for value in result.formulation.b if value > 0)
    heading = title * "\nFlow = $(number(delivered_flow)) assignments   |   Total cost = $(number(result.cost))"
    figure = Plots.plot(; axis = false, ticks = false, grid = false,
        framestyle = :none, legend = false, title = heading, titlefontsize = 12,
        xlims = (xmin - 0.075dx, xmax + 0.075dx),
        ylims = (ymin - 0.22dy, ymax + 0.25dy), size = (1000, 480),
        margin = 3Plots.mm, background_color = :white)

    # Draw unused edges first so they cannot obscure selected routes -
    ordered = sort(collect(edges); by = e -> result.flow[(e.source, e.target)] > atol)
    for edge in ordered
        flow = result.flow[(edge.source, edge.target)]
        selected = flow > atol
        unavailable = edge.upper <= atol
        color = selected ? active_color : muted_color
        width = selected ? 2.8 : 1.0
        x1, y1 = coordinates[edge.source, :]
        x2, y2 = coordinates[edge.target, :]
        distance = hypot((x2-x1)/dx, (y2-y1)/dy)
        distance > 0 || throw(ArgumentError("connected nodes must have distinct drawing positions"))
        inset = min(0.023/distance, 0.2) # stop arrowheads before the node markers
        Plots.plot!(figure, [x1+inset*(x2-x1), x2-inset*(x2-x1)],
            [y1+inset*(y2-y1), y2-inset*(y2-y1)];
            arrow = Plots.arrow(:closed, 0.22, 0.18), color = color,
            linewidth = width, linestyle = unavailable ? :dash : :solid, label = "")
    end

    # Offset labels from the lines; keep every network edge visible and continuous.
    for (x, y, label) in _cost_label_positions(edges, result, coordinates, atol)
        Plots.annotate!(figure, x, y, Plots.text(label, 9, active_color))
    end

    # Label the same node identifiers and roles used in the formulation -
    for vertex in 1:13
        color = vertex == 1 ? "#28785C" : vertex == 13 ? "#9C4D36" : "#475569"
        Plots.scatter!(figure, [coordinates[vertex,1]], [coordinates[vertex,2]];
            markercolor = color, markerstrokecolor = :white,
            markerstrokewidth = 1, markersize = 12, label = "")
        Plots.annotate!(figure, coordinates[vertex,1], coordinates[vertex,2],
            Plots.text(string(vertex), 9, :white))
    end
    groups = [(1:1,"Source"),(2:4,"Workers"),(5:8,"Tasks"),
        (9:12,"Completion"),(13:13,"Sink")]
    for (vertices, name) in groups
        x = sum(coordinates[vertices,1])/length(vertices)
        Plots.annotate!(figure, x, ymax+0.17dy, Plots.text(name, 10, "#334155"))
    end

    # Keep the meaning of color and edge labels inside the exported figure -
    legend_y = ymin - 0.15dy
    for (offset, color, width, label) in [(0.03, active_color, 2.8, "Positive flow"),
            (0.34, muted_color, 1.2, "Available, zero flow")]
        x = xmin + offset*dx
        Plots.plot!(figure, [x, x+0.06dx], [legend_y,legend_y]; color = color,
            linewidth = width, label = "")
        Plots.annotate!(figure, x+0.08dx, legend_y, Plots.text(label, 9, "#334155", :left))
    end
    Plots.annotate!(figure, xmin+0.77dx, legend_y,
        Plots.text("w: cost / assignment", 9, "#334155", :left))
    if any(edge.upper <= atol for edge in edges)
        Plots.annotate!(figure, (xmin+xmax)/2, ymin-0.22dy,
            Plots.text("Dashed edges: unavailable", 9, "#64748B"))
    end
    return figure
end

end
