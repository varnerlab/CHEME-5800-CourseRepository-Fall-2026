# =============================================================================
# CHEME 5800 | L12d supplied figure: one fed-batch run over time
# =============================================================================
# This file holds the function the lab uses to draw a batch:
#
#   plot_batch(...)   draws the cell density, lactate, volume, and feed of one batch
#
# It is complete; there is nothing to edit in this lab. It reads no notebook
# variable; everything it needs is passed in as an argument. Include.jl loads
# this file only once, so restart the kernel if you edit it.
# =============================================================================
module L12dVisualize

using ..L12dBioreactor: MyFedBatchBioreactorModel # the bioreactor type
using Plots # the figure

export plot_batch

"""
    plot_batch(model::MyFedBatchBioreactorModel, batch::NamedTuple; title::String = "")

Draw one batch over time: the cell density `X`, the lactate `L`, and the volume `V` at the start
of each cycle, the feed rate chosen in each cycle as a dashed step line, and two dotted lines
for the crash level of the lactate and the harvest level of the volume.

### Arguments
- `model::MyFedBatchBioreactorModel`: the environment; we use its `Lcrash` and `Vmax` fields.
- `batch::NamedTuple`: one batch, as returned by `simulate(...)`.
- `title::String = ""`: the title of the figure.

### Returns
- A `Plots` figure. Display it by making it the last expression of a notebook cell.
"""
function plot_batch(model::MyFedBatchBioreactorModel, batch::NamedTuple; title::String = "")

    # the cycle numbers 0, 1, 2, ... -
    cycles = range(0, stop = length(batch.X) - 1, step = 1) |> collect;

    # the culture state, one line per variable -
    p = plot(cycles, batch.X, lw = 2, marker = :circle, ms = 3, label = "cell density X",
        xlabel = "feed cycle", ylabel = "scaled value or feed rate", title = title,
        legend = :outerright, size = (760, 420), margin = 5Plots.mm);
    plot!(p, cycles, batch.L, lw = 2, marker = :square, ms = 3, label = "lactate L");
    plot!(p, cycles, batch.V, lw = 2, marker = :diamond, ms = 3, label = "volume V");

    # the feed rate chosen in each cycle -
    plot!(p, cycles, batch.feed, seriestype = :steppost, lw = 2, ls = :dash, c = :purple, label = "feed f");

    # the crash and harvest levels -
    hline!(p, [model.Lcrash], color = :red, ls = :dot, lw = 2, label = "crash level");
    hline!(p, [model.Vmax], color = :green, ls = :dot, lw = 2, label = "harvest level");

    # return the figure -
    return p;
end

end # module L12dVisualize
