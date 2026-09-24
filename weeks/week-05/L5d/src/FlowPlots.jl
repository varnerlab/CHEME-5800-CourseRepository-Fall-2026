# Figures for the L5d teaching-assignment lab. Load them through Include.jl.

# Canvas colors for an explicit figure theme. The dark values match Plots' own
# `theme(:dark)`, so a per-figure choice looks the same as the global setting.
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
    _figure_theme_attributes(theme::Symbol)

Return the `Plots.plot(...)` keyword attributes for `theme`: nothing for `:auto`,
so the figure inherits the current Plots theme, or an explicit canvas for
`:light` (alias `:default`) and `:dark`.
"""
function _figure_theme_attributes(theme::Symbol)
    theme === :auto && return NamedTuple()
    theme === :default && (theme = :light)
    haskey(_FIGURE_THEMES, theme) ||
        throw(ArgumentError("theme must be :auto, :light, :default, or :dark; got :$(theme)"))
    return _FIGURE_THEMES[theme]
end

# Test whether a line segment enters a padded label rectangle in screen pixels.
function _crosses_label(
    a::NTuple{2,Real},
    b::NTuple{2,Real},
    center::NTuple{2,Real},
    halfwidth::Real,
    halfheight::Real,
)
    low, high = 0.0, 1.0

    for (start, stop, middle, radius) in zip(a, b, center, (halfwidth, halfheight))
        delta = stop - start
        if abs(delta) < 1e-12
            abs(start - middle) > radius && return false
        else
            t1, t2 = minmax((middle - radius - start) / delta, (middle + radius - start) / delta)
            low, high = max(low, t1), min(high, t2)
            low > high && return false
        end
    end
    return true
end

# Place each cost label on its own edge, near the faculty end, where the edges
# leaving one faculty member are still easy to tell apart. The label sits on a
# patch of background color, so it cannot be read as belonging to a neighbor.
# Covering another highlighted edge, a node, or another label is ruled out;
# covering a gray edge is tolerated. Positions are searched in screen pixels.
function _label_positions(
    segments::AbstractVector,
    highlighted::AbstractVector{Bool},
    obstacles::AbstractVector,
    requests::AbstractVector,
    to_pixels::Function,
    to_data::Function,
    halfsize::NTuple{2,Real},
)
    placed = Tuple{Float64,Float64}[]
    positions = Tuple{Float64,Float64,String,Int}[]
    pixel_segments = [(to_pixels(a), to_pixels(b)) for (a, b) in segments]
    halfwidth, halfheight = halfsize

    for (index, label) in requests
        start, stop = pixel_segments[index]
        best_score, best = Inf, start

        for fraction in 0.1:0.01:0.5
            x = start[1] + fraction * (stop[1] - start[1])
            y = start[2] + fraction * (stop[2] - start[2])
            strong = count(j -> j != index && highlighted[j] &&
                _crosses_label(pixel_segments[j]..., (x, y), halfwidth, halfheight), eachindex(pixel_segments))
            weak = count(j -> !highlighted[j] &&
                _crosses_label(pixel_segments[j]..., (x, y), halfwidth, halfheight), eachindex(pixel_segments))
            nodes = count(o -> abs(x - o[1]) < halfwidth + o[3] && abs(y - o[2]) < halfheight + o[4], obstacles)
            overlaps = count(p -> abs(x - p[1]) < 2halfwidth + 3 && abs(y - p[2]) < 2halfheight + 3, placed)
            # Penalize overlap first, then prefer a location near the faculty end of the edge.
            score = 1000(strong + nodes + overlaps) + 10weak + 40fraction
            if score < best_score
                best_score, best = score, (x, y)
            end
        end
        # Retain the selected location as an obstacle for the next cost label -
        push!(placed, best)
        push!(positions, (to_data(best)..., label, index))
    end

    return positions
end

"""
    plot_teaching_flow(department::NamedTuple, network::NamedTuple,
        result::Union{Nothing,NamedTuple} = nothing;
        title::AbstractString = "Teaching-assignment network",
        atol::Real = 1e-8, theme::Symbol = :auto)

Draw the teaching-assignment network in layers: source, faculty, courses,
course completion nodes, and sink.

# Arguments
- `department`, `network`: The department tables and the network built from
  them by `build_teaching_network(...)`.
- `result`: A result from `solve_flow_lp(...)` or `solve_min_cost_flow(network)`,
  or `nothing` to draw the network before solving. An infeasible result draws
  the network in gray and says below the title that no schedule exists.
- `title`: Figure heading. With an optimal result, the required flow and the
  total cost in score points are added below it.
- `atol`: Flow threshold in assignments; edges carrying more are highlighted.
- `theme`: `:auto` (default) follows the current Plots theme. `:light` or
  `:dark` draws this figure on that background without changing the global
  theme; `:default` is an alias for `:light`.

# Returns
A `Plots.Plot`. Every faculty → course edge is an available assignment;
unspecified preferences use the default score. Without a result, available edges
are gray. With a result, red edges carry flow and thin gray edges carry no flow. Each
faculty → course edge that carries flow is labeled with its cost `w`: the survey
score, or a `with_cost(...)` value. Arrow width distinguishes the schedule but does
not scale with flow.
"""
function plot_teaching_flow(
    department::NamedTuple,
    network::NamedTuple,
    result::Union{Nothing,NamedTuple} = nothing;
    title::AbstractString = "Teaching-assignment network",
    atol::Real = 1e-8,
    theme::Symbol = :auto,
)
    canvas = _figure_theme_attributes(theme)
    isfinite(atol) && atol >= 0 || throw(ArgumentError("atol must be finite and nonnegative"))
    solved = !isnothing(result) && result.optimal # draw flows only for an optimal result
    faculty, courses = department.faculty.name, department.courses.course
    nf, nc = length(faculty), length(courses)

    # Layered layout: courses one unit apart, faculty spread over the same height -
    top = nc - 1.0
    position = Dict{Int,Tuple{Float64,Float64}}()
    position[network.source] = (0.0, top / 2)
    position[network.sink] = (6.5, top / 2)
    for (i, name) in enumerate(faculty)
        position[network.faculty_node[name]] = (1.4, top - (i - 1) * top / max(nf - 1, 1))
    end
    for (k, course) in enumerate(courses)
        position[network.course_node[course]] = (4.2, top - (k - 1))
        position[network.completion_node[course]] = (5.3, top - (k - 1))
    end
    box_halfwidth, box_halfheight, radius_x = 0.36, 0.3, 0.1
    course_nodes = Set(values(network.course_node))
    completion_nodes = Set(values(network.completion_node))

    heading = title
    if !isnothing(result) && !solved
        heading *= string(result.status) == "INFEASIBLE" ?
            "\nNo feasible schedule: the solver reports INFEASIBLE" :
            "\nNo schedule returned: the solver reports $(result.status)"
    elseif solved
        number(value::Real) = isinteger(value) ? string(Int(value)) : string(round(value; digits = 4))
        heading *= "\nFlow = $(number(network.required_flow)) assignments   |   Total cost = $(number(result.cost)) score points"
    end
    xlims, ylims = (-0.35, 6.85), (-1.6, top + 1.1)
    figure = Plots.plot(; axis = false, ticks = false, grid = false, framestyle = :none,
        legend = false, title = heading, titlefontsize = 12, xlims = xlims, ylims = ylims,
        size = (1000, 760), margin = 3Plots.mm, canvas...)
    background = figure[:background_color]
    dark_background = (Colors.red(background) + Colors.green(background) + Colors.blue(background)) < 1.5
    label_color = figure[1][:foreground_color_subplot]
    plot_area = figure[1][:background_color_inside] # label patches match the drawing area
    active_color = dark_background ? "#ff786e" : "#DC143C" # crimson, as in the L5b flow figures
    muted_color = dark_background ? "#6f7a86" : "#D0D5DA"

    # Trim each edge so arrows start and stop at the node boundaries -
    function endpoints(edge::FlowEdge)
        (x1, y1), (x2, y2) = position[edge.source], position[edge.target]
        radius(v::Integer) = v in completion_nodes ? 0.5radius_x : radius_x # smaller completion markers
        x1 += edge.source in course_nodes ? box_halfwidth : radius(edge.source)
        x2 -= edge.target in course_nodes ? box_halfwidth : radius(edge.target)
        return (x1, y1), (x2, y2)
    end
    flow_on(edge::FlowEdge) = solved ? result.flow[(edge.source, edge.target)] : 0.0
    style(edge::FlowEdge) = flow_on(edge) > atol ? (active_color, 2.8) : (muted_color, 1.0)

    # Screen scale of the drawing area, used for arrowheads and labels -
    width_px, height_px = 940.0, 640.0
    sx, sy = width_px / (xlims[2] - xlims[1]), height_px / (ylims[2] - ylims[1])
    to_pixels(p::NTuple{2,Real}) = ((p[1] - xlims[1]) * sx, (p[2] - ylims[1]) * sy)
    to_data(p::NTuple{2,Real}) = (p[1] / sx + xlims[1], p[2] / sy + ylims[1])

    # Plots' GR backend ignores arrowhead sizes, so draw each head as a small
    # triangle, sized in pixels, and stop the line at the base of the head -
    function draw_edge!(
        start::NTuple{2,Real},
        stop::NTuple{2,Real},
        color::AbstractString,
        width::Real,
    )
        (px1, py1), (px2, py2) = to_pixels(start), to_pixels(stop)
        length_px = hypot(px2 - px1, py2 - py1)
        ux, uy = (px2 - px1) / length_px, (py2 - py1) / length_px
        head, half = width > 1.0 ? (9.0, 3.5) : (6.0, 2.2) # head length and half-width, px
        base = (px2 - head * ux, py2 - head * uy)
        Plots.plot!(figure, [start[1], to_data(base)[1]], [start[2], to_data(base)[2]];
            color = color, linewidth = width, label = "")
        corners = [to_data((px2, py2)), to_data((base[1] - half * uy, base[2] + half * ux)),
            to_data((base[1] + half * uy, base[2] - half * ux))]
        Plots.plot!(figure, Plots.Shape(first.(corners), last.(corners));
            fillcolor = color, linecolor = color, linewidth = 0.5, label = "")
    end

    # Draw unused edges first so they cannot hide the schedule -
    ordered = sort(collect(network.edges); by = edge -> style(edge)[2])
    segments = Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}}[]
    highlighted = Bool[]
    segment_colors = Any[]
    requests = Tuple{Int,String}[]
    for edge in ordered
        (x1, y1), (x2, y2) = endpoints(edge)
        color, width = style(edge)
        draw_edge!((x1, y1), (x2, y2), color, width)
        push!(segments, ((x1, y1), (x2, y2)))
        push!(highlighted, width > 1.0)
        push!(segment_colors, color)
        is_option = edge.target in course_nodes && edge.source != network.source
        if is_option && flow_on(edge) > atol
            cost_text = isinteger(edge.cost) ? string(Int(edge.cost)) : string(round(edge.cost; digits = 2))
            push!(requests, (length(segments), "w=$(cost_text)"))
        end
    end

    # Label the cost of each assignment in the schedule, in screen pixels -
    circle_px(v::Integer) = v in completion_nodes ? 9.0 : 13.0 # completion nodes are drawn smaller
    obstacles = [(to_pixels(p)..., (v in course_nodes ? box_halfwidth * sx : circle_px(v)) + 2,
        (v in course_nodes ? box_halfheight * sy : circle_px(v)) + 2) for (v, p) in position]
    halfsize = (15.0, 7.5) # label patch half-width and half-height, in pixels
    colors = Dict(i => color for (i, color) in enumerate(segment_colors))
    for (x, y, label, index) in _label_positions(segments, highlighted, obstacles, requests,
            to_pixels, to_data, halfsize)
        hx, hy = halfsize[1] / sx, halfsize[2] / sy
        patch = Plots.Shape([x - hx, x + hx, x + hx, x - hx], [y - hy, y - hy, y + hy, y + hy])
        Plots.plot!(figure, patch; fillcolor = plot_area, linecolor = colors[index],
            linewidth = 0.8, label = "")
        Plots.annotate!(figure, x, y, Plots.text(label, 8, colors[index]))
    end

    # Draw the nodes: circles for the source, faculty, and sink; boxes for courses -
    for (vertex, (x, y)) in position
        if vertex in course_nodes
            box = Plots.Shape([x - box_halfwidth, x + box_halfwidth, x + box_halfwidth, x - box_halfwidth],
                [y - box_halfheight, y - box_halfheight, y + box_halfheight, y + box_halfheight])
            Plots.plot!(figure, box; fillcolor = "#475569", linecolor = :white, linewidth = 1, label = "")
            Plots.annotate!(figure, x, y, Plots.text(network.labels[vertex], 8, :white))
        elseif vertex in completion_nodes # unlabeled; each sits beside its course
            Plots.scatter!(figure, [x], [y]; markercolor = "#475569", markerstrokecolor = :white,
                markerstrokewidth = 1, markersize = 8, label = "")
        else
            color = vertex == network.source ? "#28785C" : vertex == network.sink ? "#9C4D36" : "#475569"
            Plots.scatter!(figure, [x], [y]; markercolor = color, markerstrokecolor = :white,
                markerstrokewidth = 1, markersize = 13, label = "")
            name = vertex == network.source ? "s" : vertex == network.sink ? "t" : network.labels[vertex]
            Plots.annotate!(figure, x, y, Plots.text(name, 9, :white))
        end
    end
    for (x, name) in ((0.0, "Source"), (1.4, "Faculty"), (4.2, "Courses"), (5.3, "Completion"), (6.5, "Sink"))
        Plots.annotate!(figure, x, top + 0.8, Plots.text(name, 10, label_color))
    end

    # Keep the meaning of colors and labels inside the exported figure -
    legend = !solved ?
        [(muted_color, 1.2, "Available assignment", 2.3)] :
        [(active_color, 2.8, "In the schedule", 0.5),
            (muted_color, 1.2, "Available, not used", 2.7)]
    legend_y = -1.05
    for (color, width, text, x) in legend # x: left end of each legend line, in data units
        Plots.plot!(figure, [x, x + 0.35], [legend_y, legend_y]; color = color, linewidth = width, label = "")
        Plots.annotate!(figure, x + 0.45, legend_y, Plots.text(text, 9, label_color, :left))
    end
    solved && Plots.annotate!(figure, 5.45, legend_y,
        Plots.text("w: cost per assignment", 9, label_color, :left))
    return figure
end
