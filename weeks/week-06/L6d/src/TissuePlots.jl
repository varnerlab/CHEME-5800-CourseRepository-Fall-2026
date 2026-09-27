module L6dTissuePlots

import Plots # concentration heatmaps
import ..L6dOxygen: tissue_field # rebuild the full grid, including prescribed edges

export plot_tissue

# Explicit themes match the course's light and dark plotting convention -
# Each NamedTuple holds Plots keyword settings for one appearance. The :auto
# option leaves these settings to the global theme chosen in the notebook.
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
    plot_tissue(model, theta; title = "Oxygen in the tissue", theme = :auto)

Plot dimensionless oxygen concentration, including the prescribed edges, on
the square -1 ≤ ξ, η ≤ 1, with fixed color limits (0,1) for comparing scenarios.

# Arguments
- `model`: NamedTuple from `build_tissue_system`; supplies `n`, `boundary`, and
  the dimensionless `coordinates` along both axes.
- `theta`: vector of `model.n^2` real, dimensionless interior concentrations in
  the ordering `p = i + (j-1)*n`. May be an intermediate iterate or a final solution.
- `title = "Oxygen in the tissue"`: plot title.
- `theme = :auto`: inherit the current Plots theme. `:light` (alias `:default`)
  and `:dark` select this figure's appearance without changing the global theme.

# Returns
A `Plots.Plot` heatmap including all four boundaries. Its horizontal coordinate
is ξ and its vertical coordinate is η; the field is transposed to match the
heatmap's row convention. Inputs are unchanged. Intermediate iterates show
numerical progress toward the steady solution; correction counts are solver steps.

# Errors
Throw `ArgumentError` for an unrecognized theme, nonfinite concentrations, or
concentrations outside [0,1] by more than `1e-8`, including boundary values.
Throw `DimensionMismatch` if `theta` does not have `model.n^2` entries.

# Example
```julia
model = build_tissue_system(15, 2.0);
theta = model.A \\ model.b;
plot_tissue(model, theta; title = "Steady oxygen field", theme = :dark)
```
"""
function plot_tissue(model, theta; title = "Oxygen in the tissue", theme = :auto)
    # Resolve the requested appearance -
    if theme === :default
        theme = :light; # accept the name used by theme(:default) in the notebook
    end
    if theme ∉ (:auto, :light, :dark)
        throw(ArgumentError("theme must be :auto, :light, :default, or :dark"))
    end
    if theme === :auto
        canvas = NamedTuple(); # no local overrides: inherit the current Plots settings
    else
        canvas = _FIGURE_THEMES[theme];
    end
    # Compact alternatives to the three conditional blocks:
    # theme === :default && (theme = :light)
    # theme ∈ (:auto, :light, :dark) || throw(ArgumentError("theme must be :auto, :light, :default, or :dark"))
    # canvas = theme === :auto ? NamedTuple() : _FIGURE_THEMES[theme];

    # Rebuild the grid and check the shared concentration scale -
    field = tissue_field(model, theta);
    if !all(isfinite, field) # all(...) checks every concentration, including the edges
        throw(ArgumentError("concentrations must be finite"))
    end
    if minimum(field) < -1e-8 || maximum(field) > 1.0 + 1e-8
        throw(ArgumentError("this comparison plot uses concentration limits (0,1)"))
    end
    # Compact alternatives:
    # all(isfinite, field) || throw(ArgumentError("concentrations must be finite"))
    # minimum(field) >= -1e-8 && maximum(field) <= 1.0 + 1e-8 ||
    #     throw(ArgumentError("this comparison plot uses concentration limits (0,1)"))

    # Orient the field for plotting: heatmap rows run along the vertical axis -
    heatmap_values = transpose(field); # field[i,j] uses ξ first; heatmap expects η first
    return Plots.heatmap(model.coordinates, model.coordinates, heatmap_values;
        xlabel = "ξ = x/L", ylabel = "η = y/L", title = title,
        colorbar_title = "θ", color = :viridis, clims = (0.0, 1.0), # same scale across scenarios
        aspect_ratio = :equal, xlims = (-1.0, 1.0), ylims = (-1.0, 1.0), # square tissue
        xticks = [-1.0, 0.0, 1.0], yticks = [-1.0, 0.0, 1.0],
        grid = false, titlefontsize = 11, size = (520, 440), margin = 4 * Plots.mm,
        canvas...) # ... passes the NamedTuple entries as plotting keywords
end

end
