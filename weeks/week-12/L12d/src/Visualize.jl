# =============================================================================
# CHEME 5800 | L12d lab: the figures
# =============================================================================
# The figure of a grid policy on the (B, Z) grid.
#
#   draw_grid_policy(...)   draws a grid policy, with the treatment of one patient on top
#   cell(...)               the outline of the square cell around one grid point
# =============================================================================

# --- PUBLIC METHODS BELOW HERE --------------------------------------------------------------------------------------- #
"""
    draw_grid_policy(model::MyPatientModel, policy::MyGridPolicyModel, run::NamedTuple;
        label::String = "treatment", last_cycle::Int64 = 40,
        Blims::Tuple{Float64,Float64} = (0.0, 1.0), Zlims::Tuple{Float64,Float64} = (0.0, 1.0))

Draw a grid policy on the `(B, Z)` grid, with the treatment of one patient on top.

Each grid point is drawn as a square cell, one grid step wide. Every patient state inside a cell
rounds to the grid point at its center, so the policy gives every state in the cell the same dose.

The figure is drawn in layers, from the bottom up:
1. the cells. A cell where the grid says the patient is cured is green, and a cell where the grid
   says the patient has died is red. Every other cell is blue, and a darker blue is a larger dose.
2. two dashed lines: the cure level `Bcure` and the lethal level `Zlethal` of the patient model.
3. the treatment: a line through the patient states, with a dot at the state after each cycle.
4. a larger dot at the starting state.

### Arguments
- `model::MyPatientModel`: the patient model; we use its doses, its cure level, and its lethal level.
- `policy::MyGridPolicyModel`: the grid policy, as returned by `solvegrid(...)`.
- `run::NamedTuple`: one treatment, as returned by `simulate(...)`; we use its `B` and `Z` fields.
- `label::String = "treatment"`: the legend text of the treatment.
- `last_cycle::Int64 = 40`: the last cycle of the treatment that we draw.
- `Blims::Tuple{Float64,Float64} = (0.0, 1.0)`: the range of tumor burdens to show.
- `Zlims::Tuple{Float64,Float64} = (0.0, 1.0)`: the range of toxicities to show.

### Returns
- A `Plots` figure. Display it by making it the last expression of a notebook cell.
"""
function draw_grid_policy(model::MyPatientModel, policy::MyGridPolicyModel, run::NamedTuple;
    label::String = "treatment", last_cycle::Int64 = 40,
    Blims::Tuple{Float64,Float64} = (0.0, 1.0), Zlims::Tuple{Float64,Float64} = (0.0, 1.0))

    # initialize -
    nlevels = policy.nlevels; # the number of grid levels on each axis
    step = policy.step; # the grid spacing
    number_of_actions = length(model.doses);
    dose_colors = ["#deebf7", "#9ecae1", "#4292c6", "#08519c"]; # one blue per dose, light to dark
    cure_color = "#a6dba0"; # light green
    dead_color = "#f4a582"; # light red
    path_color = :black;

    # an empty canvas: the legend is a list to the right of the grid -
    p = plot(framestyle = :box, aspect_ratio = :equal, size = (800, 620),
        legend = :outerright, legendfontsize = 10, foreground_color_legend = nothing,
        xlims = (Blims[1] - step/2, Blims[2] + step/2), ylims = (Zlims[1] - step/2, Zlims[2] + step/2),
        xlabel = "Tumor burden B", ylabel = "Toxicity Z", grid = false,
        background_color = :transparent, background_color_inside = :transparent);

    # sort the cells into groups: one group per dose, one for a cure, and one for a toxic death -
    dose_cells = Array{Array{Shape,1},1}();
    for a ∈ 1:number_of_actions
        push!(dose_cells, Array{Shape,1}());
    end
    cure_cells = Array{Shape,1}();
    dead_cells = Array{Shape,1}();
    for iB ∈ 1:nlevels
        for iZ ∈ 1:nlevels
            B = (iB - 1)*step; # the tumor burden of this grid point
            Z = (iZ - 1)*step; # the toxicity of this grid point

            # the grid decides the outcome at the grid point, for every state in the cell -
            if (isdead(model, B, Z) == true)
                push!(dead_cells, cell(B, Z, step));
            elseif (iscured(model, B, Z) == true)
                push!(cure_cells, cell(B, Z, step));
            else
                a = policy.π[iB, iZ]; # the action the policy gives at this grid point
                push!(dose_cells[a], cell(B, Z, step));
            end
        end
    end

    # draw each group of cells at once; a thin white border separates the cells -
    for a ∈ 1:number_of_actions
        if (length(dose_cells[a]) > 0)
            plot!(p, dose_cells[a], c = dose_colors[a], lc = :white, lw = 0.5, label = "");
        end
    end
    if (length(cure_cells) > 0)
        plot!(p, cure_cells, c = cure_color, lc = :white, lw = 0.5, label = "");
    end
    if (length(dead_cells) > 0)
        plot!(p, dead_cells, c = dead_color, lc = :white, lw = 0.5, label = "");
    end

    # the cure level and the lethal level of the patient model -
    plot!(p, [model.Bcure, model.Bcure], [Zlims[1] - step/2, Zlims[2] + step/2], c = :gray20, lw = 2, ls = :dash, label = "");
    plot!(p, [Blims[1] - step/2, Blims[2] + step/2], [model.Zlethal, model.Zlethal], c = :gray20, lw = 2, ls = :dash, label = "");

    # the patient states of the treatment, up to the last cycle we draw -
    n = min(run.cycles, last_cycle); # the last cycle we draw
    path_B = run.B[1:(n + 1)]; # entry 1 is the starting state, and entry t + 1 is the state after cycle t
    path_Z = run.Z[1:(n + 1)];

    # the treatment: a white line under a black line, so the path stands out from the cells -
    plot!(p, path_B, path_Z, c = :white, lw = 3.5, label = "");
    plot!(p, path_B, path_Z, c = path_color, lw = 1.5, label = "");
    scatter!(p, path_B, path_Z, ms = 3, mc = path_color, msc = :white, label = "");

    # mark the starting state with a larger dot -
    scatter!(p, [path_B[1]], [path_Z[1]], ms = 7, mc = path_color, msc = :white, label = "");

    # the legend: one entry per kind of mark. Each entry is an empty series (its point is NaN,
    # "not a number", so nothing is drawn on the grid); it only sets the symbol and the text -
    for a ∈ 1:number_of_actions
        scatter!(p, [NaN], [NaN], marker = :square, ms = 7, mc = dose_colors[a], msc = :gray50,
            label = "dose $(round(model.doses[a], digits = 2))");
    end
    scatter!(p, [NaN], [NaN], marker = :square, ms = 7, mc = cure_color, msc = :gray50, label = "cured on the grid");
    scatter!(p, [NaN], [NaN], marker = :square, ms = 7, mc = dead_color, msc = :gray50, label = "dead on the grid");
    plot!(p, [NaN], [NaN], c = :gray20, lw = 2, ls = :dash, label = "cure and lethal levels");
    plot!(p, [NaN], [NaN], c = path_color, lw = 1.5, marker = :circle, ms = 3, label = label);
    scatter!(p, [NaN], [NaN], ms = 7, mc = path_color, msc = :white, label = "start");

    # return the figure -
    return p;
end
# --- PUBLIC METHODS ABOVE HERE --------------------------------------------------------------------------------------- #

# --- PRIVATE METHODS BELOW HERE -------------------------------------------------------------------------------------- #
"""
    cell(B::Float64, Z::Float64, width::Float64) -> Shape

Make the outline of the square cell centered at the grid point `(B, Z)`, so we can draw it with
`plot!(...)`. The corners are half a `width` from the center, and they are listed in order around
the cell: bottom left, bottom right, top right, and top left.

### Arguments
- `B::Float64`: the tumor burden of the grid point at the center of the cell.
- `Z::Float64`: the toxicity of the grid point at the center of the cell.
- `width::Float64`: the width of the cell. A width of one grid step fills the cell.

### Returns
- `Shape`: a `Plots` shape that `plot!(...)` draws as a filled square.
"""
function cell(B::Float64, Z::Float64, width::Float64)::Shape

    # the corners are half a width from the center -
    h = width/2;

    # the B and Z coordinates of the four corners -
    corner_B = [B - h, B + h, B + h, B - h];
    corner_Z = [Z - h, Z - h, Z + h, Z + h];

    # return -
    return Shape(corner_B, corner_Z);
end
# --- PRIVATE METHODS ABOVE HERE -------------------------------------------------------------------------------------- #
