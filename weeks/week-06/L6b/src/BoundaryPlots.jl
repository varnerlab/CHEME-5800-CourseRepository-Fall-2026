module L6bBoundaryPlots

import Plots # draw what crosses the cell boundary
import Colors # detect a dark canvas so muted colors stay visible

export plot_exchange_flows

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

function _figure_theme_attributes(theme::Symbol)
    theme === :auto && return NamedTuple()
    theme === :default && (theme = :light)
    haskey(_FIGURE_THEMES, theme) ||
        throw(ArgumentError("theme must be :auto, :light, :default, or :dark; got :$(theme)"))
    return _FIGURE_THEMES[theme]
end

# The exchanges drawn on each side, with display names. Water and protons are left out.
const _INPUTS = [("EX_glc__D_e", "glucose"), ("EX_o2_e", "oxygen"), ("EX_nh4_e", "ammonium"),
    ("EX_pi_e", "phosphate")]
const _OUTPUTS = [("EX_co2_e", "CO₂"), ("EX_ac_e", "acetate"), ("EX_etoh_e", "ethanol"),
    ("EX_for_e", "formate"), ("EX_lac__D_e", "lactate"), ("EX_succ_e", "succinate")]

"""
    plot_exchange_flows(model, result; title = "What crosses the cell boundary",
        atol::Real = 1e-6, theme = :auto)

Draw the cell as a box with the main exchange fluxes of an optimal `result` crossing
its boundary: nutrients (glucose, oxygen, ammonium, phosphate) on the left and
products (CO₂, acetate, ethanol, formate, lactate, succinate) on the right, with
biomass leaving at the bottom. Arrow width grows with the flux, arrows point in the
direction material moves, and each label gives the flux in mmol/gDW/h. Exchanges
with no flux are drawn as dashed gray lines. Water and protons are left out.

`model` and `result` come from `load_core_model(...)` and `solve_growth(...)`. A
result without an optimal solution, such as an infeasible one, draws the cell with
unlabeled gray exchanges and reports the solver status below the title. `theme` is `:auto` (follow the current Plots theme), `:light` (alias
`:default`), or `:dark`. Returns a `Plots.Plot`.
"""
function plot_exchange_flows(model, result; title = "What crosses the cell boundary",
        atol::Real = 1e-6, theme = :auto)
    canvas = _figure_theme_attributes(theme)
    solved = result.optimal
    flux_of(id) = solved ? result.flux[findfirst(==(id), model.reactions)] : 0.0
    number(x) = string(round(x; digits = 2))
    heading = solved ? title * "\nGrowth rate = $(number(result.growth)) 1/h" :
        title * "\nNo optimal solution: the solver reports $(result.status)"

    xlims, ylims = (0.0, 10.0), (-1.3, 7.6)
    figure = Plots.plot(; axis = false, ticks = false, grid = false, framestyle = :none,
        legend = false, title = heading, titlefontsize = 12, xlims = xlims, ylims = ylims,
        size = (900, 560), margin = 3Plots.mm, canvas...)
    background = figure[:background_color]
    dark_background = (Colors.red(background) + Colors.green(background) + Colors.blue(background)) < 1.5
    label_color = figure[1][:foreground_color_subplot]
    active_color = dark_background ? "#ff786e" : "#DC143C" # crimson, as in the flow networks of week 5
    biomass_color = dark_background ? "#70c5f3" : "#0072B2"
    muted_color = dark_background ? "#6f7a86" : "#C8CDD2" # zero-flux stubs
    muted_text = dark_background ? "#9AA3AD" : "#6B747D" # their labels, readable when projected
    cell_fill = dark_background ? "#3D4550" : "#F2F4F7"

    # Screen scale, so arrowheads keep their shape -
    sx, sy = 860 / (xlims[2] - xlims[1]), 470 / (ylims[2] - ylims[1])
    function arrow!(x1, y1, x2, y2, color, width)
        dx, dy = (x2 - x1) * sx, (y2 - y1) * sy
        len = hypot(dx, dy)
        ux, uy = dx / len, dy / len
        head, half = 6.0 + 1.5width, 2.5 + 0.9width # arrowhead length and half-width, px
        bx, by = x2 - head * ux / sx, y2 - head * uy / sy
        Plots.plot!(figure, [x1, bx], [y1, by]; color = color, linewidth = width, label = "")
        px, py = -uy * half / sx, ux * half / sy
        Plots.plot!(figure, Plots.Shape([x2, bx + px, bx - px], [y2, by + py, by - py]);
            fillcolor = color, linecolor = color, linewidth = 0.5, label = "")
    end

    # The cell -
    left, right, bottom, top = 3.3, 6.7, 0.2, 7.0
    Plots.plot!(figure, Plots.Shape([left, right, right, left], [bottom, bottom, top, top]);
        fillcolor = cell_fill, linecolor = label_color, linewidth = 1.2, label = "")
    Plots.annotate!(figure, (left + right) / 2, (bottom + top) / 2 + 0.3,
        Plots.text("E. coli\ncore metabolism", 11, label_color))

    # Arrow widths scale with the largest displayed flux -
    ids = vcat(first.(_INPUTS), first.(_OUTPUTS))
    largest = maximum(abs(flux_of(id)) for id in ids; init = 0.0)
    width_of(v) = largest > 0 ? 1.5 + 6.5 * abs(v) / largest : 1.5

    # Lift each label clear of its arrowhead, whose half-width grows with the line width -
    label_offset(width) = (11.5 + 0.9width) / sy

    function draw_side!(entries, x_outer, x_edge, label_x, halign)
        for (k, (id, name)) in enumerate(entries)
            y = top - 0.55 - (k - 1) * (top - bottom - 1.1) / max(length(entries) - 1, 1)
            v = flux_of(id)
            if abs(v) <= atol
                Plots.plot!(figure, [x_outer, x_edge], [y, y]; color = muted_color, linewidth = 1.0,
                    linestyle = :dash, label = "")
                Plots.annotate!(figure, label_x, y + label_offset(1.0), Plots.text(solved ? "$(name) 0" : name, 9, muted_text, halign))
                continue
            end
            # Uptake is a negative exchange flux: material moves into the cell.
            into_cell = v < 0
            from_x, to_x = into_cell ? (x_outer, x_edge) : (x_edge, x_outer)
            width = width_of(v)
            arrow!(from_x, y, to_x, y, active_color, width)
            Plots.annotate!(figure, label_x, y + label_offset(width),
                Plots.text("$(name) $(number(abs(v)))", 9, label_color, halign))
        end
    end
    draw_side!(_INPUTS, 0.9, left - 0.05, 0.9, :left)
    draw_side!(_OUTPUTS, 9.1, right + 0.05, 9.1, :right)

    # Biomass leaves through the bottom; its units differ, so its width is fixed -
    if solved && result.growth > atol
        arrow!(5.0, bottom - 0.02, 5.0, -0.9, biomass_color, 3.0)
        Plots.annotate!(figure, 5.25, -0.55, Plots.text("biomass $(number(result.growth)) 1/h", 9, label_color, :left))
    end
    Plots.annotate!(figure, 0.1, -1.1, Plots.text("Fluxes in mmol/gDW/h; arrow width grows with flux; water and protons not shown",
        8, label_color, :left))
    return figure
end

end
