# =============================================================================
# CHEME 5800 | L12d lab: the figure
# =============================================================================
#   plot_left(...)   the percent of agents that choose "left" in each episode
#
# Include.jl loads this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12dVisualize

using Plots # figures

export plot_left

"""
    plot_left(left_one::Array{Float64,1}, left_two::Array{Float64,1}; label_one::String,
        label_two::String, ϵ::Float64 = 0.1, title::String = "") -> Plots.Plot

Plot, for each episode, the percent of the agents that chose "left" in state A, for two
methods. A dashed line marks `100⋅ϵ/2` percent: the agents choose "left" this often even when
they rate "right" higher, because an exploring step picks "left" half the time.

### Arguments
- `left_one::Array{Float64,1}`, `left_two::Array{Float64,1}`: the fraction of the agents that chose
  "left" in each episode, for the first and the second method.
- `label_one::String`, `label_two::String`: the legend labels of the two methods.
- `ϵ::Float64 = 0.1`: the exploration probability of the agents.
- `title::String = ""`: the title of the figure.
"""
function plot_left(left_one::Array{Float64,1}, left_two::Array{Float64,1}; label_one::String,
    label_two::String, ϵ::Float64 = 0.1, title::String = "")

    # the two methods, episode by episode, in percent -
    episodes = 1:length(left_one);
    p = plot(episodes, 100 .* left_one, lw = 2, label = label_one, xlabel = "episode",
        ylabel = "percent of agents choosing left", ylims = (0, 100), title = title,
        size = (720, 380), margin = 5Plots.mm);
    plot!(p, episodes, 100 .* left_two, lw = 2, label = label_two);

    # the floor set by exploration -
    hline!(p, [100*ϵ/2], color = :gray, ls = :dash, label = "exploration only (ϵ/2)");

    # return -
    return p;
end

end # module L12dVisualize
