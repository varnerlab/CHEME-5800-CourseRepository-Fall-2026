# L15b figures. The notebook calls these three functions to draw the runs of each task. Every run
# uses the layout of mysolve and myintegrate: the times in a vector t, and the states in a matrix x
# with one column per time.
module L15bPlots

using Plots # plot, plot!, and the layout of the panels
using Colors: RGBA # a see-through panel color that reads on the light and the dark theme

# the three figure functions that the notebook calls -
export plot_stops, plot_pulse_runs, plot_error_against_step;

"""
    inducer_panel(pulse::NamedTuple, t_final::Float64) -> Plots.Plot

Draw the inducer concentration of one pulse, from time zero to `t_final`, as a dashed step line.

### Arguments
- `pulse::NamedTuple`: the pulse, `(start = …, stop = …, concentration = …, baseline = …)`. The
  times are in min, and the concentrations are in µM.
- `t_final::Float64`: the last time of the run (min).

### Returns
A panel with the inducer axis and no time ticks, to stack above a panel of concentrations. The line
takes the color of the legend text, black on the light theme and white on the dark theme.
"""
function inducer_panel(pulse::NamedTuple, t_final::Float64)::Plots.Plot

    # an empty panel for the inducer -
    panel = RGBA(0.5, 0.5, 0.5, 0.12); # a see-through panel, for the light and the dark theme
    top = plot(framestyle = :box, background_color_inside = panel, legend = false, xticks = false); # the inducer panel
    line_color = top[1][:legend_font_color]; # black on the light theme, white on the dark theme

    # the inducer before, during, and after the pulse. Each value holds until the next time -
    times = [0.0, pulse.start, pulse.stop, t_final]; # the times at which the inducer changes, and the end of the run (min)
    values = [pulse.baseline, pulse.concentration, pulse.baseline, pulse.baseline]; # the inducer from each time on (µM)
    plot!(top, times, values, seriestype = :steppost, lw = 2, ls = :dash, c = line_color); # the dashed step line
    ylabel!(top, "Inducer (µM)"); # the inducer axis

    return top;
end

"""
    plot_stops(with_stops::NamedTuple, without_stops::NamedTuple, model, pulse::NamedTuple) -> Plots.Plot

Draw protein Y from two library solves of the same pulse, one with the pulse edges as stops and one
without, below the inducer.

### Arguments
- `with_stops::NamedTuple`, `without_stops::NamedTuple`: the two runs, each with the times `t` and
  the states `x`, one column per time (nmol/gDW).
- `model`: the circuit model. The figure reads the number of genes and the index of gene Y from it.
- `pulse::NamedTuple`: the pulse, `(start = …, stop = …, concentration = …, baseline = …)`.

### Returns
The figure: the inducer panel above the protein Y panel, with a shared time axis.
"""
function plot_stops(with_stops::NamedTuple, without_stops::NamedTuple, model, pulse::NamedTuple)::Plots.Plot

    # initialize -
    y = length(model.genes) + model.index["Y"]; # the entry of protein Y in the state: the mRNA entries come first
    panel = RGBA(0.5, 0.5, 0.5, 0.12); # a see-through panel, for the light and the dark theme
    top = inducer_panel(pulse, with_stops.t[end]); # the inducer, above the protein panel

    # bottom panel: protein Y from both runs -
    bottom = plot(framestyle = :box, background_color_inside = panel, fg_legend = :transparent,
        legend = :outerbottom, legend_column = 2); # an empty panel, with the legend below it
    plot!(bottom, with_stops.t, with_stops.x[y, :], lw = 3, c = :dodgerblue3, label = "Y, with the stops"); # the run that ends a step at each pulse edge
    plot!(bottom, without_stops.t, without_stops.x[y, :], lw = 3, ls = :dash, c = :firebrick2,
        label = "Y, without the stops"); # the run that picks every step freely
    xlabel!(bottom, "Time (min)"); # the time axis
    ylabel!(bottom, "Protein Y (nmol/gDW)"); # the protein axis

    # stack the two panels, with a shared time axis -
    return plot(top, bottom, layout = grid(2, 1, heights = [0.25, 0.75]), link = :x, size = (800, 520),
        margin = 4 * Plots.mm);
end

"""
    plot_pulse_runs(euler::NamedTuple, reference::NamedTuple, model, pulse::NamedTuple) -> Plots.Plot

Draw every protein from an explicit Euler run and from a library reference, below the inducer.

### Arguments
- `euler::NamedTuple`, `reference::NamedTuple`: the two runs, each with the times `t` and the states
  `x`, one column per time (nmol/gDW).
- `model`: the circuit model. The figure reads the genes and their names from it.
- `pulse::NamedTuple`: the pulse, `(start = …, stop = …, concentration = …, baseline = …)`.

### Returns
The figure: the inducer panel above the protein panel, with a shared time axis. The reference is a
wide pale line, and Euler is a dashed line in the same color. The protein axis covers the range of
the reference, so that an Euler run that grows without bound leaves the panel.
"""
function plot_pulse_runs(euler::NamedTuple, reference::NamedTuple, model, pulse::NamedTuple)::Plots.Plot

    # initialize -
    N = length(model.genes); # the number of genes; protein j is entry N + j of the state
    colors = [:dodgerblue3, :firebrick2, :darkorange2]; # the color of the protein of gene 1, gene 2, and gene 3
    panel = RGBA(0.5, 0.5, 0.5, 0.12); # a see-through panel, for the light and the dark theme
    headroom = 1.1; # the top of the protein axis, as a multiple of the largest reference concentration
    largest = 0.0; # the largest reference concentration of any protein (nmol/gDW), found below
    top = inducer_panel(pulse, reference.t[end]); # the inducer, above the protein panel

    # bottom panel: each protein from the reference and from Euler, in the color of its gene -
    bottom = plot(framestyle = :box, background_color_inside = panel, fg_legend = :transparent,
        legend = :outerbottom, legend_column = 2); # an empty panel, with the legend below it: one row per protein
    for j ∈ 1:N # each gene
        name = model.genes[j].name; # the name of gene j
        color = :gray; # the color of a fourth or later gene
        if j <= length(colors) # one of the first three genes
            color = colors[j]; # its own color
        end
        largest = max(largest, maximum(reference.x[N + j, :])); # the largest reference concentration so far
        plot!(bottom, reference.t, reference.x[N + j, :], lw = 6, linealpha = 0.35, c = color,
            label = name * ", library"); # the reference, as a wide pale line
        plot!(bottom, euler.t, euler.x[N + j, :], lw = 2, ls = :dash, c = color, label = name * ", Euler"); # explicit Euler
    end
    ylims!(bottom, (0.0, headroom * largest)); # the range of the reference
    xlabel!(bottom, "Time (min)"); # the time axis
    ylabel!(bottom, "Protein (nmol/gDW)"); # the protein axis

    # stack the two panels, with a shared time axis -
    return plot(top, bottom, layout = grid(2, 1, heights = [0.25, 0.75]), link = :x, size = (800, 560),
        margin = 4 * Plots.mm);
end

"""
    plot_error_against_step(step_sizes::Vector{Float64}, euler_errors::Vector{Float64},
        rk4_errors::Vector{Float64}) -> Plots.Plot

Draw the largest error of each run against its step on log–log axes, with guide lines of order one
and order four.

### Arguments
- `step_sizes::Vector{Float64}`: the step of each grid (min).
- `euler_errors::Vector{Float64}`, `rk4_errors::Vector{Float64}`: the largest error of the Euler run
  and of the RK4 run on each grid (nmol/gDW).

### Returns
The figure. The order-one guide line runs below the Euler errors, and the order-four guide line runs
below the RK4 errors, each a factor of four below the error at the smallest step. A guide line of
order `p` rises by a factor of `2^p` each time the step doubles, so an error curve parallel to it
falls by that factor each time the step halves. The step axis is labeled at each step.
"""
function plot_error_against_step(step_sizes::Vector{Float64}, euler_errors::Vector{Float64},
    rk4_errors::Vector{Float64})::Plots.Plot

    # initialize -
    panel = RGBA(0.5, 0.5, 0.5, 0.12); # a see-through panel, for the light and the dark theme
    smallest = argmin(step_sizes); # the grid with the smallest step
    offset = 4.0; # how far below each error curve its guide line runs, as a factor
    guide_one = zeros(length(step_sizes)); # the order-one guide line at each step (nmol/gDW)
    guide_four = zeros(length(step_sizes)); # the order-four guide line at each step (nmol/gDW)
    tick_labels = String[]; # the label of each step on the step axis

    # the guide lines, below the errors at the smallest step, and the step labels -
    for i ∈ 1:length(step_sizes) # each grid
        ratio = step_sizes[i] / step_sizes[smallest]; # this step, as a multiple of the smallest step
        guide_one[i] = (euler_errors[smallest] / offset) * ratio; # order one: the error grows with the step
        guide_four[i] = (rk4_errors[smallest] / offset) * ratio^4; # order four: the error grows with the fourth power of the step
        push!(tick_labels, string(round(step_sizes[i]; sigdigits = 3))); # the step, to three significant digits
    end

    # the errors and the guide lines on log-log axes -
    figure = plot(framestyle = :box, background_color_inside = panel, fg_legend = :transparent,
        legend = :bottomright, xscale = :log10, yscale = :log10, xticks = (step_sizes, tick_labels),
        size = (800, 450), margin = 4 * Plots.mm); # an empty panel, with a tick at each step
    plot!(figure, step_sizes, guide_one, lw = 2, ls = :dash, c = :gray, label = "order one"); # the order-one guide
    plot!(figure, step_sizes, guide_four, lw = 2, ls = :dot, c = :gray, label = "order four"); # the order-four guide
    plot!(figure, step_sizes, euler_errors, lw = 3, marker = :circle, ms = 5, c = :dodgerblue3, label = "Euler"); # explicit Euler
    plot!(figure, step_sizes, rk4_errors, lw = 3, marker = :square, ms = 5, c = :firebrick2, label = "RK4"); # RK4
    xlabel!(figure, "Step Δt (min)"); # the step axis
    ylabel!(figure, "Largest error in protein Y (nmol/gDW)"); # the error axis

    return figure;
end

end # module L15bPlots
