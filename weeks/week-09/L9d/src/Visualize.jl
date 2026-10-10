# =============================================================================
# CHEME 5800 | L9d supplied figure
# =============================================================================
# plot_probabilities(...) draws the probability that each banknote is forged,
# with one row for each actual class. You do not need to edit this file; your
# work is in Compute.jl. Include.jl loads this file once, so after an edit here,
# restart the kernel.
#
# Names that start with an underscore (_figure_theme_attributes, ...) are
# internal helpers for the figure; they are not exported.
#
# Plots shorthand used below: c is the color, ms the marker size, msw the width
# of the marker outline (0 for none), lw the line width, and ls the line style.
# =============================================================================
module L9dVisualize

import Plots: plot, plot!, scatter!, vline!, Shape, mm # figures, a filled polygon, and millimeters for the margins
import Colors: red, green, blue # the red, green, and blue parts of a color, each 0 to 1

export plot_probabilities

# Label colors, as in the L9a lecture figure: orange for label 1 (forged), teal for label -1 (genuine) -
const _LABEL_COLORS = Dict(1 => "#FA6400", -1 => "#44D7B6")

# Canvas colors for an explicit figure theme. The dark values match Plots' own
# `theme(:dark)`, so a per-figure choice looks the same as the global setting -
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
    _figure_theme_attributes(theme::Symbol) -> NamedTuple

Return the `Plots.plot(...)` keyword attributes for `theme`: none for `:auto`, so the
figure inherits the current Plots theme, or an explicit canvas for `:light` (alias
`:default`) and `:dark`.

### Errors
Throws an `ArgumentError` for any other `theme`.
"""
function _figure_theme_attributes(theme::Symbol)
    theme === :auto && return NamedTuple(); # no attributes: use the current Plots theme
    theme === :default && (theme = :light); # :default is another name for :light
    haskey(_FIGURE_THEMES, theme) ||
        throw(ArgumentError("theme must be :auto, :light, :default, or :dark; got :$(theme)"))
    return _FIGURE_THEMES[theme]
end

"""
    plot_probabilities(P::Array{Float64,1}, y::Array{<:Number,1};
        band::Union{Nothing, Tuple{Float64,Float64}} = nothing, title::String = "",
        theme::Symbol = :auto) -> Plots.Plot

Draw the probability that each banknote is forged, `P[i]`, on the horizontal axis, with
the forged banknotes (`y[i] = 1`) in the upper row and the genuine banknotes
(`y[i] = -1`) in the lower row. Within each row, the points are spread up and down by a
fixed amount that depends only on their position in `P`, so points with nearly equal
probabilities do not hide each other and the figure is the same every time.

The classifier labels a banknote forged when its probability is at least `1/2`, drawn as
a dashed line. A banknote it labels correctly keeps its class color (orange for forged,
teal for genuine); a banknote it labels incorrectly is gray. When `band = (t_low, t_high)`
is given, the band of probabilities between them is shaded.

### Arguments
- `P::Array{Float64,1}`: the probability that each banknote is forged, each in `[0, 1]`.
- `y::Array{<:Number,1}`: the actual label of each banknote, `1` (forged) or `-1`
  (genuine), in the same order as `P`.
- `band::Union{Nothing, Tuple{Float64,Float64}} = nothing`: the inspector band
  `(t_low, t_high)` to shade, with `0 ≤ t_low < t_high ≤ 1`, or `nothing` for no band.
- `title::String = ""`: the figure title.
- `theme::Symbol = :auto`: `:auto` follows the current Plots theme. `:light` or `:dark`
  draws this figure on that background without changing the global theme; `:default`
  is another name for `:light`.

### Returns
- The figure, a `Plots.Plot`.

### Errors
Throws a `DimensionMismatch` if `P` and `y` have different lengths, and an
`ArgumentError` if a probability is outside `[0, 1]`, a label is not `1` or `-1`, or the
band is not ordered inside `[0, 1]`.

### Example
```julia
plot_probabilities(P_logistic, testing.y, band = (0.25, 0.75), title = "Inspector band")
```
"""
function plot_probabilities(P::Array{Float64,1}, y::Array{<:Number,1};
    band::Union{Nothing, Tuple{Float64,Float64}} = nothing, title::String = "",
    theme::Symbol = :auto)

    # checks -
    length(P) == length(y) || throw(DimensionMismatch("P and y must have the same length"))
    all(0 .≤ P .≤ 1) || throw(ArgumentError("every probability in P must be in [0, 1]"))
    all((y .== 1) .| (y .== -1)) || throw(ArgumentError("every label in y must be 1 or -1"))
    if band !== nothing && !(0 ≤ band[1] < band[2] ≤ 1)
        throw(ArgumentError("band must be (t_low, t_high) with 0 ≤ t_low < t_high ≤ 1"))
    end

    # initialize -
    figure = plot(; _figure_theme_attributes(theme)..., title = title, framestyle = :box,
        xlims = (-0.02, 1.02), ylims = (-0.6, 1.6), yticks = ([0, 1], ["Genuine", "Forged"]),
        xlabel = "Probability of forged", ylabel = "Actual class", legend = :outerbottom,
        legend_columns = 3, fg_legend = :transparent, bg_legend = :transparent, # legend below, three entries per row
        size = (800, 420), left_margin = 4mm, bottom_margin = 2mm);

    # pick a line color that stands out from the canvas: a dark canvas has a low total
    # of its red, green, and blue parts (at most 3, for white) -
    background = figure[:background_color]; # the canvas color, set by the theme
    dark_background = (red(background) + green(background) + blue(background)) < 1.5;
    line_color = dark_background ? "#F2F2F2" : "#000000"; # near-white or black

    # shade the inspector band first, so the points are drawn on top of it -
    if band !== nothing
        t_low, t_high = band;
        plot!(figure, Shape([t_low, t_high, t_high, t_low], [-0.6, -0.6, 1.6, 1.6]),
            c = "#7F7FBF", fillalpha = 0.25, lw = 0, label = "Inspector band");
    end

    # the row of each banknote (1 forged, 0 genuine), spread by a fixed offset in [-0.3, 0.3) -
    row = [y[i] == 1 ? 1.0 : 0.0 for i ∈ eachindex(y)];
    offset = [0.6*(mod(i*0.6180339887498949, 1.0) - 0.5) for i ∈ eachindex(y)]; # golden-ratio steps spread evenly
    predicted = [p ≥ 0.5 ? 1 : -1 for p ∈ P]; # forged when the probability is at least 1/2

    # draw the correctly labeled banknotes in their class color -
    for (label, name) ∈ ((1, "Forged"), (-1, "Genuine"))
        rows = findall((y .== label) .& (predicted .== y)); # this class, labeled correctly
        scatter!(figure, P[rows], row[rows] .+ offset[rows], c = _LABEL_COLORS[label], msw = 0,
            ms = 4, label = name);
    end

    # draw the mislabeled banknotes in gray -
    rows = findall(predicted .!= y); # the banknotes whose label is wrong
    scatter!(figure, P[rows], row[rows] .+ offset[rows], c = "#8C8C8C", msw = 0, ms = 5,
        label = "Missed");

    # draw the threshold 1/2 -
    vline!(figure, [0.5], c = line_color, ls = :dash, lw = 1.5, label = "Threshold 1/2");

    # return -
    return figure;
end

end # module L9dVisualize
