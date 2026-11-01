# =============================================================================
# CHEME 5800 | L11c example helpers: reward shaping, random rollout, and drawing
# =============================================================================
# This file holds the functions the L11c example calls:
#
#   rbf(...)            spreads the charging station's reward over the grid
#   myrollout(...)      computes the discounted return of one random walk
#   follow_policy(...)  walks a policy from a start square
#   square(...)         makes the outline of one grid square, for drawing
#   draw_path(...)      draws the grid world and the roomba's path
#
# None of these functions reads a notebook variable; everything they need is
# passed in as an argument. Include.jl loads this file only once, so restart
# the kernel if you edit it.
# =============================================================================
module L11cRollout

# the world and MDP model types, and the random policy and random step functions -
using VLDataScienceMachineLearningPackage: MyMDPProblemModel, MyRectangularGridWorldModel
using VLDataScienceMachineLearningPackage: myrandpolicy, myrandstep
using Plots # the figure drawn by draw_path

export rbf, myrollout, follow_policy, square, draw_path

"""
    rbf(x::Tuple{Int,Int}, y::Tuple{Int,Int}; σ::Float64 = 1.0) -> Float64

Compute the radial basis function weight of square `x` relative to square `y`.

The weight is `exp(-δ/(2σ²))`, where `δ` is the straight-line distance between the two
squares. The weight equals one at `y` and falls toward zero as `x` moves away from `y`.
The width `σ` sets how quickly the weight falls.

### Arguments
- `x::Tuple{Int,Int}`: the `(x, y)` coordinates of the square we want the weight of.
- `y::Tuple{Int,Int}`: the `(x, y)` coordinates of the center square, e.g., the charging station.
- `σ::Float64 = 1.0`: the width of the kernel.

### Returns
- `Float64`: the weight, a number between zero and one.
"""
function rbf(x::Tuple{Int,Int}, y::Tuple{Int,Int}; σ::Float64 = 1.0)::Float64

    # compute the straight-line (Euclidean) distance between the two squares -
    δ = sqrt((x[1] - y[1])^2 + (x[2] - y[2])^2);

    # compute the weight -
    w = exp(-δ/(2*σ^2));

    # return -
    return w;
end

"""
    myrollout(problem::MyMDPProblemModel, world::MyRectangularGridWorldModel, s::Int64,
        depth::Int64, absorbing_state_set::Set{Tuple{Int,Int}}) -> Float64

Compute the discounted return of one random rollout that starts in state `s`.

At each step, the rollout picks a random action that keeps the roomba on the grid using
the `myrandpolicy(...)` function, takes that action using the `myrandstep(...)` function,
and adds the discounted reward `γᵗ r` to the return. The rollout stops after `depth` steps,
or when the roomba enters an absorbing square (the charging station or a lava pit). The
reward for entering that square is collected. A rollout that starts in an absorbing square
returns zero. This is Algorithm 9.1 of the Decisions Book, with the stopping rule from the
lecture.

The random actions come from Julia's global random number generator, so call
`Random.seed!(...)` before a set of rollouts to make the results reproducible.

### Arguments
- `problem::MyMDPProblemModel`: the MDP; we use its reward matrix `R` and discount factor `γ`.
- `world::MyRectangularGridWorldModel`: the grid world; we use its squares and moves.
- `s::Int64`: the state where the rollout starts.
- `depth::Int64`: the maximum number of steps in the rollout, `d ≥ 1`.
- `absorbing_state_set::Set{Tuple{Int,Int}}`: the `(x, y)` squares that end an episode.

### Returns
- `Float64`: the discounted return `G` of the rollout.
"""
function myrollout(problem::MyMDPProblemModel, world::MyRectangularGridWorldModel, s::Int64,
    depth::Int64, absorbing_state_set::Set{Tuple{Int,Int}})::Float64

    # initialize -
    G = 0.0; # the discounted return, we add to this at each step
    γ = problem.γ; # the discount factor
    t = 0; # the number of steps we have taken
    is_ok_to_stop = false; # we set this to true when the rollout should end

    # a rollout that starts in an absorbing square has nothing left to collect -
    current_position = world.coordinates[s]; # the (x,y) coordinates of the start state
    if (in(current_position, absorbing_state_set) == true)
        is_ok_to_stop = true;
    end

    # main loop: take one random step each pass through the loop -
    while (is_ok_to_stop == false)

        # choose a random action, and take it -
        a = myrandpolicy(problem, world, s); # a random action that keeps us on the grid
        result = myrandstep(problem, world, s, a); # returns the tuple (next state, reward)
        next_state = result[1]; # the state we land in
        r = result[2]; # the reward for taking action a in state s

        # add the discounted reward to the return, and count the step -
        G = G + r*(γ^t);
        t = t + 1;

        # should we stop? Either we used up the depth, or we entered an absorbing square -
        next_position = world.coordinates[next_state]; # the (x,y) coordinates of the next state
        if (t ≥ depth)
            is_ok_to_stop = true;
        elseif (in(next_position, absorbing_state_set) == true)
            is_ok_to_stop = true; # charging station or lava: the episode ends
        end

        # move to the next state -
        s = next_state;
    end

    # return -
    return G;
end

"""
    follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
        world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
        absorbing_state_set::Set{Tuple{Int,Int}};
        charging_reward::Float64) -> Tuple{Array{Tuple{Int,Int},1}, String}

Walk a policy from a starting square, and report the squares visited and how the walk ended.

Starting at `start`, the function looks up the action the policy chooses in the current
square and moves the roomba one square. It repeats this until the roomba enters an absorbing
square, tries to leave the grid, or returns to a square it already visited. A return to a
visited square means the policy would walk in a loop forever.

### Arguments
- `policy::Array{Int64,1}`: the action to take in each state, i.e., `policy[s]` is the action in state `s`.
- `start::Tuple{Int,Int}`: the `(x, y)` coordinates of the square where the walk starts.
- `world::MyRectangularGridWorldModel`: the grid world; we use its `states` dictionary, which maps
  a square to its state, and its `moves` dictionary, which maps an action to a change in position.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the reward of each square; we use it to tell the
  charging station from a lava pit when the walk ends.
- `absorbing_state_set::Set{Tuple{Int,Int}}`: the `(x, y)` squares that end an episode.
- `charging_reward::Float64`: the reward value of the charging station.

### Returns
- `Tuple{Array{Tuple{Int,Int},1}, String}`: the squares visited in order, starting with
  `start`, and a phrase describing how the walk ended. The number of moves is one less than
  the number of squares in the path.
"""
function follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
    world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
    absorbing_state_set::Set{Tuple{Int,Int}};
    charging_reward::Float64)::Tuple{Array{Tuple{Int,Int},1}, String}

    # initialize -
    path = Array{Tuple{Int,Int},1}(); # the squares the roomba visits, in order
    push!(path, start);
    position = start; # where the roomba is now
    outcome = ""; # a phrase describing how the walk ended
    is_ok_to_stop = false; # we set this to true when the walk should end

    # a roomba that starts in an absorbing square never moves -
    if (in(start, absorbing_state_set) == true)
        if (rewards[start] == charging_reward)
            outcome = "is already at the charging station";
        else
            outcome = "is already in a lava pit";
        end
        is_ok_to_stop = true;
    end

    # main loop: make one move each pass through the loop -
    while (is_ok_to_stop == false)

        # look up the action the policy chooses here, and where it takes us -
        s = world.states[position]; # the state of the current square
        a = policy[s]; # the action the policy chooses in state s
        Δ = world.moves[a]; # the change in position for action a, e.g., up = (0,1)
        new_position = (position[1] + Δ[1], position[2] + Δ[2]); # the new (x,y) coordinates

        # check the move: off the grid, or back to a square we already visited? -
        if (haskey(world.states, new_position) == false)
            outcome = "tried to leave the grid"; # there is no state at the new position
            is_ok_to_stop = true;
        elseif (in(new_position, path) == true)
            outcome = "walks in a loop"; # the policy would cycle forever
            is_ok_to_stop = true;
        else

            # the move is ok: take it -
            push!(path, new_position);
            position = new_position;

            # did we enter an absorbing square? -
            if (in(position, absorbing_state_set) == true)
                if (rewards[position] == charging_reward)
                    outcome = "reached the charging station";
                else
                    outcome = "fell into a lava pit";
                end
                is_ok_to_stop = true;
            end
        end
    end

    # return -
    return (path, outcome);
end

"""
    square(x::Int, y::Int) -> Shape

Make the outline of the grid square centered at `(x, y)`, so we can draw it with `plot!(...)`.

Each square of the grid is one unit wide, so its corners are half a unit from its center.
The corners are listed in order around the square: bottom left, bottom right, top right,
and top left.

### Arguments
- `x::Int`: the `x` coordinate of the center of the square.
- `y::Int`: the `y` coordinate of the center of the square.

### Returns
- `Shape`: a `Plots` shape that `plot!(...)` draws as a filled square.
"""
function square(x::Int, y::Int)::Shape

    # the x and y coordinates of the four corners -
    corner_x = [x - 0.5, x + 0.5, x + 0.5, x - 0.5];
    corner_y = [y - 0.5, y - 0.5, y + 0.5, y + 0.5];

    # return -
    return Shape(corner_x, corner_y);
end

"""
    draw_path(path::Array{Tuple{Int,Int},1}, rewards::Dict{Tuple{Int,Int},Float64};
        charging_reward::Float64, lava_reward::Float64,
        number_of_rows::Int64, number_of_cols::Int64,
        shading::Dict{Tuple{Int,Int},Float64} = Dict{Tuple{Int,Int},Float64}())

Draw the grid world and the roomba's path across it.

Each square of the grid is drawn as a unit square, so the figure keeps its proportions for
any grid size. The charging station is a green square, each lava pit is a red square, the
start square has a blue outline, and the path is drawn in blue. On a small grid (15 squares
or fewer on a side) the path has one arrow per move; on a larger grid, the path is one line
with an arrow at its end, so it stays readable. The axis ticks also thin out as the grid
grows, so the labels do not overlap.

When the `shading` dictionary is not empty, each square is filled with green, from clear
(weight zero) to solid green (weight one). This shows how far the shaped charging reward
reaches.

### Arguments
- `path::Array{Tuple{Int,Int},1}`: the squares the roomba visits, in order, as returned by
  `follow_policy(...)`.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the reward of each square; we use it to find the
  charging station and the lava pits.
- `charging_reward::Float64`: the reward value of the charging station.
- `lava_reward::Float64`: the reward value of a lava pit.
- `number_of_rows::Int64`: the number of rows in the grid, which sets the `x` axis limits.
- `number_of_cols::Int64`: the number of columns in the grid, which sets the `y` axis limits.
- `shading::Dict{Tuple{Int,Int},Float64}`: an optional weight between zero and one for each
  `(x, y)` square. Leave it empty to draw the grid without shading.

### Returns
- A `Plots` figure. Display it by making it the last expression of a notebook cell.
"""
function draw_path(path::Array{Tuple{Int,Int},1}, rewards::Dict{Tuple{Int,Int},Float64};
    charging_reward::Float64, lava_reward::Float64,
    number_of_rows::Int64, number_of_cols::Int64,
    shading::Dict{Tuple{Int,Int},Float64} = Dict{Tuple{Int,Int},Float64}())

    # sizes that depend on the grid -
    n = max(number_of_rows, number_of_cols); # the longer side of the grid
    tick_step = max(1, ceil(Int, n/10)); # the spacing between tick labels: about ten labels per axis
    if (n ≤ 15)
        path_width = 2.5; # a small grid: thick lines
    else
        path_width = 1.5; # a larger grid: thinner lines
    end

    # an empty canvas: one unit per square, with room for the legend on the right -
    p = plot(framestyle = :box, aspect_ratio = :equal, legend = :outerright, size = (720, 560),
        xlims = (0.5, number_of_rows + 0.5), ylims = (0.5, number_of_cols + 0.5),
        xticks = 1:tick_step:number_of_rows, yticks = 1:tick_step:number_of_cols,
        xlabel = "x", ylabel = "y", grid = false,
        background_color = :transparent, background_color_inside = :transparent);

    # shade the squares by weight, if we were given weights -
    if (isempty(shading) == false)

        # build the weight matrix: the row index is y, and the column index is x -
        weights = zeros(number_of_cols, number_of_rows);
        for x ∈ 1:number_of_rows
            for y ∈ 1:number_of_cols
                if (haskey(shading, (x,y)) == true)
                    weights[y,x] = shading[(x,y)];
                end
            end
        end

        # draw the weights. RGBA(red, green, blue, opacity) is a color: the color scale runs
        # from clear green (opacity 0) to solid green (opacity 1), so the unshaded squares show
        # the background of either the light or the dark theme -
        green_scale = cgrad([RGBA(0.0, 0.5, 0.0, 0.0), RGBA(0.0, 0.5, 0.0, 1.0)]);
        heatmap!(p, 1:number_of_rows, 1:number_of_cols, weights, c = green_scale,
            clims = (0, 1), colorbar = false, label = "");
    end

    # draw the borders between the squares, faint so the path stands out -
    for x ∈ 0:number_of_rows
        plot!(p, [x + 0.5, x + 0.5], [0.5, number_of_cols + 0.5], c = :gray, lw = 0.5, alpha = 0.4, label = "");
    end
    for y ∈ 0:number_of_cols
        plot!(p, [0.5, number_of_rows + 0.5], [y + 0.5, y + 0.5], c = :gray, lw = 0.5, alpha = 0.4, label = "");
    end

    # fill the lava pits and the charging station -
    # we only label the first square of each kind, so the legend shows each kind once.
    lava_label = "lava pit";
    station_label = "charging station";
    for (coordinate, reward) ∈ rewards
        x = coordinate[1];
        y = coordinate[2];
        if (reward == lava_reward)
            plot!(p, square(x, y), c = :red, lc = :red, label = lava_label);
            lava_label = ""; # no label for the remaining lava pits
        elseif (reward == charging_reward)
            plot!(p, square(x, y), c = :green3, lc = :green3, label = station_label);
            station_label = ""; # no label for any other charging station
        end
    end

    # outline the start square -
    start = path[1];
    plot!(p, square(start[1], start[2]), fillalpha = 0, lc = :dodgerblue, lw = path_width, label = "start");

    # draw the path -
    if (n ≤ 15)

        # a small grid has room for one arrow per move. We only label the first arrow -
        path_label = "path";
        for i ∈ 1:(length(path) - 1)
            x_values = [path[i][1], path[i+1][1]]; # x coordinates of this move: from, to
            y_values = [path[i][2], path[i+1][2]]; # y coordinates of this move: from, to
            plot!(p, x_values, y_values, arrow = arrow(:closed, :head), lw = path_width,
                c = :dodgerblue, label = path_label);
            path_label = ""; # no label for the remaining arrows
        end
    else

        # a larger grid: draw one line through all the squares, with an arrow at its end -
        x_values = Array{Int,1}();
        y_values = Array{Int,1}();
        for i ∈ 1:length(path)
            push!(x_values, path[i][1]);
            push!(y_values, path[i][2]);
        end
        plot!(p, x_values, y_values, arrow = arrow(:closed, :head), lw = path_width,
            c = :dodgerblue, label = "path");
    end

    # return the figure -
    return p;
end

end # module L11cRollout
