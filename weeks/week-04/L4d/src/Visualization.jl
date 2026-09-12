"""
    plotroute(graphmodel::MySimpleDirectedGraphModel, route::Vector{Int64}, coordinates::Matrix{Float64};
        start::Int64 = start_vertex, finish::Int64 = finish_vertex)

Draw the graph on the given layout, label every edge with its cost, and highlight `route` in red.
Returns the current figure.
"""
function plotroute(graphmodel::MySimpleDirectedGraphModel, route::Vector{Int64}, coordinates::Matrix{Float64};
    start::Int64 = start_vertex, finish::Int64 = finish_vertex)

    # Initialize -
    route_edges = Set((route[i], route[i + 1]) for i in 1:(length(route) - 1));
    node_gap = 0.20; # leave space for the vertex markers at both ends of each edge
    plot();

    # Draw each directed step and place its cost beside the line.
    for ((s, t), w) in graphmodel.edges
        x₁, y₁ = coordinates[s, 1], coordinates[s, 2];
        x₂, y₂ = coordinates[t, 1], coordinates[t, 2];
        dx, dy = x₂ - x₁, y₂ - y₁;
        edge_length = hypot(dx, dy); # geometric length used only to position the arrows
        xs = [x₁ + node_gap * dx / edge_length, x₂ - node_gap * dx / edge_length];
        ys = [y₁ + node_gap * dy / edge_length, y₂ - node_gap * dy / edge_length];
        selected = (s, t) in route_edges;
        edge_color = selected ? :red : :gray55;
        label_color = selected ? :red : :black;
        plot!(xs, ys, arrow = arrow(:closed, :head, 0.15, 0.12), color = edge_color, lw = 2, label = "")

        # Put horizontal-edge labels above the line and vertical-edge labels to its right.
        label_x, label_y = (x₁ + x₂) / 2, (y₁ + y₂) / 2;
        if abs(dx) >= abs(dy)
            label_y += 0.16;
        else
            label_x += 0.18;
        end
        annotate!(label_x, label_y, text(string(round(w, digits = 2)), 8, label_color))
    end

    # Draw the numbered vertices: gray by default, green at the start, and red at the finish.
    scatter!(coordinates[:, 1], coordinates[:, 2], c = :gray, ms = 16, label = "")
    scatter!([coordinates[start, 1]], [coordinates[start, 2]], c = :green, ms = 16,
        markerstrokewidth = 2, markerstrokecolor = :darkgreen, label = "Start")
    scatter!([coordinates[finish, 1]], [coordinates[finish, 2]], c = :red, ms = 16,
        markerstrokewidth = 2, markerstrokecolor = :darkred, label = "Finish")
    for i in 1:size(coordinates, 1)
        color = (i == start || i == finish) ? :white : :black
        annotate!(coordinates[i, 1], coordinates[i, 2], text(string(i), 9, color))
    end

    plot!(axis = nothing, border = :none, legend = :outertopright, legendfontsize = 8,
        background_color = :white, xlim = (9.5, 14.5), ylim = (8.5, 11.5))
    return current()
end;
