# =============================================================================
# CHEME 5800 | L11d supplied helpers: walking and drawing a policy
# =============================================================================
# follow_policy(...) applies a policy one move at a time and reports where the
# robot ended up. draw_path(...) draws the grid, the hazards, and that path.
# Both are complete; your work for this meeting is in Compute.jl. Include.jl
# loads this file only once, so restart the kernel if you do edit it.
#
# Neither function reads a notebook variable. Everything they need, the world,
# the rewards, and the grid size, is passed in, so they behave the same no
# matter what the notebook has defined.
# =============================================================================
module L11dUtility

using VLDataScienceMachineLearningPackage: MyRectangularGridWorldModel # the grid world type
using Plots # the figure drawn by draw_path

export follow_policy, draw_path

"""
    follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
        world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
        absorbing_state_set::Set{Tuple{Int,Int}};
        charging_reward::Float64) -> Tuple{Array{Tuple{Int,Int},1}, String}

Walk a policy from a starting square and report the squares visited and how the walk ended.

Starting at `start`, the function repeatedly looks up the action the policy chooses in the
current square and moves there. It stops when the robot enters an absorbing state, tries to
leave the grid, or revisits a square, which means the policy would cycle forever.

### Arguments
- `policy::Array{Int64,1}`: the action to take in each state, as `policy[state]`.
- `start::Tuple{Int,Int}`: the `(x, y)` square to start from.
- `world::MyRectangularGridWorldModel`: supplies `states`, the square-to-state map, and
  `moves`, the position change of each action.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the non-default rewards, used only to tell a
  charging station from a lava pit when the walk ends.
- `absorbing_state_set::Set{Tuple{Int,Int}}`: the squares that end an episode.
- `charging_reward::Float64`: the reward marking the charging station.

### Returns
- `Tuple{Array{Tuple{Int,Int},1}, String}`: the squares visited in order, starting with
  `start`, and a phrase describing the outcome. The number of moves is one less than the
  length of the path.
"""
function follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
    world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
    absorbing_state_set::Set{Tuple{Int,Int}};
    charging_reward::Float64)::Tuple{Array{Tuple{Int,Int},1}, String}

    # initialize -
    path = [start]; # the squares the robot visits, in order
    position = start; # where the robot is now

    # a robot that starts in an absorbing state never moves -
    if (start ∈ absorbing_state_set)
        return (path, rewards[start] == charging_reward ? "is already at the charging station" :
            "is already in a lava pit");
    end

    # main loop: one move each pass, until the robot stops -
    while true
        a = policy[world.states[position]]; # the action the policy chooses in this square
        new_position = position .+ world.moves[a]; # the .+ adds the move to the (x,y) pair

        if (haskey(world.states, new_position) == false)
            return (path, "tried to leave the grid"); # no state there, so the move is off the grid
        elseif (new_position ∈ path)
            return (path, "walks in a loop"); # back to a square it already visited
        end

        push!(path, new_position);
        position = new_position;

        if (position ∈ absorbing_state_set) # the episode ends here
            return (path, rewards[position] == charging_reward ? "reached the charging station" :
                "fell into a lava pit");
        end
    end
end

"""
    draw_path(path::Array{Tuple{Int,Int},1}, world::MyRectangularGridWorldModel,
        states::Array{Int64,1}, rewards::Dict{Tuple{Int,Int},Float64};
        charging_reward::Float64, lava_reward::Float64,
        number_of_rows::Int64, number_of_cols::Int64)

Draw the grid world and a path across it.

Every square is a small open marker, the charging station is a green marker, each lava pit
is a red marker, and the path is drawn as blue arrows, one per move.

### Arguments
- `path::Array{Tuple{Int,Int},1}`: the squares to draw, in order, as `follow_policy` returns.
- `world::MyRectangularGridWorldModel`: supplies `coordinates`, the state-to-square map.
- `states::Array{Int64,1}`: the states to draw, usually every state in the world.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the non-default rewards, used to find the
  charging station and the lava pits.
- `charging_reward`, `lava_reward::Float64`: the reward values marking those squares.
- `number_of_rows`, `number_of_cols::Int64`: the grid size, which sets the axis limits.

### Returns
- A `Plots` figure. Display it by making it the last expression of a cell.
"""
function draw_path(path::Array{Tuple{Int,Int},1}, world::MyRectangularGridWorldModel,
    states::Array{Int64,1}, rewards::Dict{Tuple{Int,Int},Float64};
    charging_reward::Float64, lava_reward::Float64,
    number_of_rows::Int64, number_of_cols::Int64)

    # an empty square canvas, one unit of margin on each side -
    p = plot(framestyle = :box, aspect_ratio = :equal, legend = :outerright,
        xlims = (0, number_of_rows + 1), ylims = (0, number_of_cols + 1),
        xlabel = "x", ylabel = "y",
        background_color = :transparent, background_color_inside = :transparent);

    # draw the squares of the grid world -
    # first.(...) and last.(...) pull the x and y of every (x,y) pair.
    squares = [world.coordinates[s] for s ∈ states]; # (x,y) of every square
    scatter!(p, first.(squares), last.(squares), ms = 2, mc = :white, msc = :gray, label = "");

    # mark the hazards and the goal -
    lava = [c for (c, r) ∈ rewards if r == lava_reward]; # (x,y) of the lava pits
    scatter!(p, first.(lava), last.(lava), ms = 6, mc = :red, label = "lava pit");
    station = [c for (c, r) ∈ rewards if r == charging_reward]; # (x,y) of the charging station
    scatter!(p, first.(station), last.(station), ms = 6, mc = :green, label = "charging station");

    # draw the path, one arrow for each move -
    # only the first arrow carries a label, so the legend shows a single entry.
    for i ∈ 1:(length(path) - 1)
        plot!(p, [path[i][1], path[i+1][1]], [path[i][2], path[i+1][2]],
            arrow = true, lw = 2, c = :dodgerblue, label = (i == 1 ? "path" : ""));
    end

    return p
end

end # module L11dUtility
