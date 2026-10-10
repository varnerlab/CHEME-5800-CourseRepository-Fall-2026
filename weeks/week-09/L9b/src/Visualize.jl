# =============================================================================
# CHEME 5800 | L9b supplied figures
# =============================================================================
# plot_dataset(...) draws a labeled dataset, and plot_misses(...) draws the test
# points a classifier got wrong, with its learned decision boundary. You do not
# need to edit this file; your work is in Compute.jl. Include.jl loads this file
# once, so after an edit here, restart the kernel.
#
# Names that start with an underscore (_empty_figure, ...) are internal helpers
# for the two figures; they are not exported.
#
# Plots shorthand used below: c is the color, ms the marker size, msw the width
# of the marker outline (0 for none), and lw the line width.
# =============================================================================
module L9bVisualize

import Plots: plot, plot!, scatter!, mm # figures, and millimeters for the margins
import Colors: red, green, blue # the red, green, and blue parts of a color, each 0 to 1

export plot_dataset, plot_misses

# Label colors, as in the L9a lecture figure: orange for label 1, teal for label -1 -
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
    _empty_figure(title::String, theme::Symbol; legend_columns::Int = -1) -> Plots.Plot

Return an empty square figure that covers the unit disk, with labeled axes and the
legend below the axes, on the canvas chosen by `theme`. The features are in arbitrary
units (AU). The legend has `legend_columns` columns; `-1` puts every entry in one row.
"""
function _empty_figure(title::String, theme::Symbol; legend_columns::Int = -1)
    return plot(; _figure_theme_attributes(theme)..., title = title, framestyle = :box,
        aspect_ratio = :equal, xlims = (-1.1, 1.1), ylims = (-1.1, 1.1), # the disk, with a margin
        xlabel = "Feature 1 (AU)", ylabel = "Feature 2 (AU)", legend = :outerbottom,
        legend_columns = legend_columns, fg_legend = :transparent, bg_legend = :transparent,
        left_margin = 6mm, bottom_margin = 2mm)
end

"""
    plot_dataset(D::Array{Float64,2}; title::String = "", theme::Symbol = :auto) -> Plots.Plot

Draw each row of `D` as a point at its two features, colored by its label: orange for
label `1` and teal for label `-1`. The axes cover the disk of radius one around the
origin, in arbitrary units (AU).

### Arguments
- `D::Array{Float64,2}`: the dataset, one row per point: the two features in the
  first two columns and the label (`1` or `-1`) in the third.
- `title::String = ""`: the figure title.
- `theme::Symbol = :auto`: `:auto` follows the current Plots theme. `:light` or `:dark`
  draws this figure on that background without changing the global theme; `:default`
  is another name for `:light`.

### Returns
- The figure, a `Plots.Plot`.

### Example
```julia
plot_dataset(datasets["XOR"], title = "XOR")
```
"""
function plot_dataset(D::Array{Float64,2}; title::String = "", theme::Symbol = :auto)

    # initialize -
    figure = _empty_figure(title, theme);

    # draw the points with each label, in that label's color -
    for label ∈ (1, -1)
        rows = findall(D[:,3] .== label); # the row numbers of the points with this label
        scatter!(figure, D[rows,1], D[rows,2], c = _LABEL_COLORS[label], msw = 0, ms = 3,
            label = "Label: $(label)");
    end

    # return -
    return figure;
end

"""
    plot_misses(D::Array{Float64,2}, predicted::Array{<:Number,1}, θ::Array{Float64,1};
        title::String = "", theme::Symbol = :auto) -> Plots.Plot

Draw each row of `D` as a point at its two features. A point whose label the classifier
predicted correctly keeps its label color (orange for `1`, teal for `-1`); a point it
missed is gray. The function also draws the learned decision boundary, the line where
`θ[1]*x₁ + θ[2]*x₂ + θ[3] = 0`. If both feature weights are zero, there is no such
line, and none is drawn.

A predicted label counts as correct only when it equals the actual label, so a
predicted `0`, the sign of a zero score, counts as a miss.

### Arguments
- `D::Array{Float64,2}`: the dataset, one row per point: the two features in the
  first two columns and the actual label (`1` or `-1`) in the third.
- `predicted::Array{<:Number,1}`: the predicted label of each row of `D`.
- `θ::Array{Float64,1}`: the classifier parameters: the two feature weights,
  followed by the bias.
- `title::String = ""`: the figure title.
- `theme::Symbol = :auto`: `:auto` follows the current Plots theme. `:light` or `:dark`
  draws this figure on that background without changing the global theme; `:default`
  is another name for `:light`.

### Returns
- The figure, a `Plots.Plot`.

### Example
```julia
θ = perceptron_models["XOR"].β; # the learned parameters
plot_misses(test["XOR"], ŷ_perceptron["XOR"], θ, title = "Perceptron: XOR")
```
"""
function plot_misses(D::Array{Float64,2}, predicted::Array{<:Number,1}, θ::Array{Float64,1};
    title::String = "", theme::Symbol = :auto)

    # initialize -
    figure = _empty_figure(title, theme, legend_columns = 2); # four legend entries, in two rows

    # pick a boundary color that stands out from the canvas: a dark canvas has a low
    # total of its red, green, and blue parts (at most 3, for white) -
    background = figure[:background_color]; # the canvas color, set by the theme
    dark_background = (red(background) + green(background) + blue(background)) < 1.5;
    boundary_color = dark_background ? "#F2F2F2" : "#000000"; # near-white or black

    # draw the correctly classified points in their label color -
    for label ∈ (1, -1)
        rows = findall((D[:,3] .== label) .& (predicted .== D[:,3])); # this label, predicted correctly
        scatter!(figure, D[rows,1], D[rows,2], c = _LABEL_COLORS[label], msw = 0, ms = 3,
            label = "Label: $(label)");
    end

    # draw the missed points in gray -
    rows = findall(predicted .!= D[:,3]); # the points whose prediction is wrong
    scatter!(figure, D[rows,1], D[rows,2], c = "#8C8C8C", msw = 0, ms = 3, label = "Missed");

    # with both feature weights zero, there is no boundary line to draw -
    if (θ[1] == 0.0 && θ[2] == 0.0)
        return figure;
    end

    # draw the learned boundary, θ[1]*x₁ + θ[2]*x₂ + θ[3] = 0. We solve the equation
    # for the coordinate whose weight has the larger absolute value and divide by that
    # weight, so a nearly vertical or nearly horizontal line still draws correctly -
    s = range(-1.1, 1.1, length = 200) |> collect; # 200 values across the plotting window
    if abs(θ[2]) ≥ abs(θ[1]) # x₁ = s and x₂ = -(θ[1]*s + θ[3])/θ[2]
        plot!(figure, s, -(θ[1] .* s .+ θ[3]) ./ θ[2], lw = 2, c = boundary_color,
            label = "Learned boundary");
    else # x₂ = s and x₁ = -(θ[2]*s + θ[3])/θ[1]
        plot!(figure, -(θ[2] .* s .+ θ[3]) ./ θ[1], s, lw = 2, c = boundary_color,
            label = "Learned boundary");
    end

    # return -
    return figure;
end

end # module L9bVisualize
