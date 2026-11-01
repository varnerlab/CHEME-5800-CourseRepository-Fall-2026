# =============================================================================
# CHEME 5800 | L11c example helpers: reward shaping, random rollout, and drawing
# =============================================================================
# This file holds the functions the L11c example calls:
#
#   rbf(...)            spreads the charging station's reward over the grid
#   myrollout(...)      computes the discounted return of one random walk
#   follow_policy(...)  walks a policy from a start square
#   square(...)         makes the outline of one grid square, for drawing
#   arrow_shape(...)    makes a small arrow that points one way, for drawing
#   draw_path(...)      draws the grid world, the policy, and the roomba's path
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

export rbf, myrollout, follow_policy, square, arrow_shape, draw_path

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
    square(x::Int, y::Int; width::Float64 = 1.0) -> Shape

Make the outline of a square centered at `(x, y)`, so we can draw it with `plot!(...)`.

Each square of the grid is one unit wide. A `width` of one gives a square that fills its
grid square; a smaller `width` gives a smaller square inside it. The corners are half a
`width` from the center, and they are listed in order around the square: bottom left,
bottom right, top right, and top left.

### Arguments
- `x::Int`: the `x` coordinate of the center of the square.
- `y::Int`: the `y` coordinate of the center of the square.
- `width::Float64 = 1.0`: the width of the square, as a fraction of one grid square.

### Returns
- `Shape`: a `Plots` shape that `plot!(...)` draws as a filled square.
"""
function square(x::Int, y::Int; width::Float64 = 1.0)::Shape

    # the corners are half a width from the center -
    h = width/2;

    # the x and y coordinates of the four corners -
    corner_x = [x - h, x + h, x + h, x - h];
    corner_y = [y - h, y - h, y + h, y + h];

    # return -
    return Shape(corner_x, corner_y);
end

"""
    arrow_shape(x::Int, y::Int, Δ::Tuple{Int,Int}; arrow_length::Float64 = 0.5) -> Shape

Make a small arrow centered at `(x, y)` that points in the direction `Δ`, so we can draw it
with `plot!(...)`.

The arrow is one closed outline with seven corners: a thin shaft and a triangular head. Its
size is given in grid squares, so the arrow stays the same size relative to its square for
any grid size. The direction `Δ` is one of the moves of the grid world, e.g., up = `(0,1)`.

### Arguments
- `x::Int`: the `x` coordinate of the center of the arrow.
- `y::Int`: the `y` coordinate of the center of the arrow.
- `Δ::Tuple{Int,Int}`: the direction the arrow points, one square left, right, down, or up.
- `arrow_length::Float64 = 0.5`: the length of the arrow, tail to tip, in grid squares.

### Returns
- `Shape`: a `Plots` shape that `plot!(...)` draws as a filled arrow.
"""
function arrow_shape(x::Int, y::Int, Δ::Tuple{Int,Int}; arrow_length::Float64 = 0.5)::Shape

    # the sizes of the parts of the arrow, as fractions of its length -
    shaft_half_width = 0.06*arrow_length; # half the width of the shaft
    head_length = 0.45*arrow_length; # how far the head reaches back from the tip
    head_half_width = 0.3*arrow_length; # half the width of the head at its base

    # the direction the arrow points (dx, dy), and the direction across it (nx, ny) -
    dx = Δ[1];
    dy = Δ[2];
    nx = -dy; # turning (dx, dy) a quarter turn gives the direction across the arrow
    ny = dx;

    # three points along the arrow: the tail, the tip, and the neck where the head starts -
    tail_x = x - 0.5*arrow_length*dx;
    tail_y = y - 0.5*arrow_length*dy;
    tip_x = x + 0.5*arrow_length*dx;
    tip_y = y + 0.5*arrow_length*dy;
    neck_x = tip_x - head_length*dx;
    neck_y = tip_y - head_length*dy;

    # the seven corners of the outline, in order around the arrow -
    corner_x = [
        tail_x + shaft_half_width*nx, # tail, one side
        neck_x + shaft_half_width*nx, # neck, same side
        neck_x + head_half_width*nx,  # head, same side
        tip_x,                        # tip
        neck_x - head_half_width*nx,  # head, other side
        neck_x - shaft_half_width*nx, # neck, other side
        tail_x - shaft_half_width*nx, # tail, other side
    ];
    corner_y = [
        tail_y + shaft_half_width*ny,
        neck_y + shaft_half_width*ny,
        neck_y + head_half_width*ny,
        tip_y,
        neck_y - head_half_width*ny,
        neck_y - shaft_half_width*ny,
        tail_y - shaft_half_width*ny,
    ];

    # return -
    return Shape(corner_x, corner_y);
end

"""
    draw_path(path::Array{Tuple{Int,Int},1}, policy::Array{Int64,1},
        world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
        absorbing_state_set::Set{Tuple{Int,Int}};
        charging_reward::Float64, lava_reward::Float64,
        number_of_rows::Int64, number_of_cols::Int64)

Draw the grid world, the policy in every square, and the roomba's path.

Each square of the grid is drawn as a unit square, so the figure keeps its proportions for
any grid size. The charging station is a green square, and each lava pit is a red square, each drawn a
little smaller than its grid square.
A small gray arrow in every other square points in the direction the policy moves from that
square; `arrow_shape(...)` makes each one. The roomba's path is a thick blue line from the
start square, marked with a blue dot, to where the walk ended.

### Arguments
- `path::Array{Tuple{Int,Int},1}`: the squares the roomba visits, in order, as returned by
  `follow_policy(...)`.
- `policy::Array{Int64,1}`: the action to take in each state, i.e., `policy[s]` is the action in state `s`.
- `world::MyRectangularGridWorldModel`: the grid world; we use its `coordinates` dictionary,
  which maps a state to its square, and its `moves` dictionary, which maps an action to a
  change in position.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the reward of each square; we use it to find the
  charging station and the lava pits.
- `absorbing_state_set::Set{Tuple{Int,Int}}`: the `(x, y)` squares that end an episode; we draw
  no policy arrow in these squares.
- `charging_reward::Float64`: the reward value of the charging station.
- `lava_reward::Float64`: the reward value of a lava pit.
- `number_of_rows::Int64`: the number of rows in the grid, which sets the `x` axis limits.
- `number_of_cols::Int64`: the number of columns in the grid, which sets the `y` axis limits.

### Returns
- A `Plots` figure. Display it by making it the last expression of a notebook cell.
"""
function draw_path(path::Array{Tuple{Int,Int},1}, policy::Array{Int64,1},
    world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
    absorbing_state_set::Set{Tuple{Int,Int}};
    charging_reward::Float64, lava_reward::Float64,
    number_of_rows::Int64, number_of_cols::Int64)

    # the axis ticks: every square on a small grid, otherwise every fifth square -
    n = max(number_of_rows, number_of_cols); # the longer side of the grid
    if (n ≤ 10)
        ticks = 1:n;
    else
        ticks = [1; 5:5:n]; # 1, 5, 10, 15, ...
    end

    # an empty canvas: one unit per square, with the legend as a list to the right of the grid -
    p = plot(framestyle = :box, aspect_ratio = :equal, size = (800, 620),
        legend = :outerright, legendfontsize = 10, foreground_color_legend = nothing,
        xlims = (0.5, number_of_rows + 0.5), ylims = (0.5, number_of_cols + 0.5),
        xticks = ticks, yticks = ticks, xlabel = "x", ylabel = "y", grid = false,
        background_color = :transparent, background_color_inside = :transparent);

    # draw the borders between the squares, faint so the arrows and the path stand out -
    for x ∈ 0:number_of_rows
        plot!(p, [x + 0.5, x + 0.5], [0.5, number_of_cols + 0.5], c = :gray, lw = 0.5, alpha = 0.35, label = "");
    end
    for y ∈ 0:number_of_cols
        plot!(p, [0.5, number_of_rows + 0.5], [y + 0.5, y + 0.5], c = :gray, lw = 0.5, alpha = 0.35, label = "");
    end

    # fill the lava pits and the charging station, each with a square 0.6 grid squares wide -
    # label = "" keeps these out of the legend; we add the legend entries at the end.
    marker_width = 0.6;
    for (coordinate, reward) ∈ rewards
        x = coordinate[1];
        y = coordinate[2];
        if (reward == lava_reward)
            plot!(p, square(x, y, width = marker_width), c = :red, lc = :red, label = "");
        elseif (reward == charging_reward)
            plot!(p, square(x, y, width = marker_width), c = :green3, lc = :green3, label = "");
        end
    end

    # build one policy arrow for every square that is not absorbing -
    # each arrow is 0.5 grid squares long, so neighboring arrows do not touch.
    arrows = Array{Shape,1}();
    for (s, coordinate) ∈ world.coordinates
        if (in(coordinate, absorbing_state_set) == false)
            Δ = world.moves[policy[s]]; # the move the policy chooses in this square, e.g., up = (0,1)
            push!(arrows, arrow_shape(coordinate[1], coordinate[2], Δ, arrow_length = 0.5));
        end
    end

    # draw all the policy arrows at once -
    plot!(p, arrows, c = :gray55, lc = :gray55, lw = 0, label = "");

    # draw the path through the centers of the squares the roomba visits -
    path_x = Array{Int,1}();
    path_y = Array{Int,1}();
    for i ∈ 1:length(path)
        push!(path_x, path[i][1]);
        push!(path_y, path[i][2]);
    end
    plot!(p, path_x, path_y, c = :dodgerblue, lw = 3, label = "");

    # mark the start square with a dot -
    scatter!(p, [path_x[1]], [path_y[1]], ms = 7, mc = :dodgerblue, msc = :white, label = "");

    # the legend: one entry per kind of mark, in this order. Each entry is an empty series
    # (its point is NaN, "not a number", so nothing is drawn on the grid); it only sets the
    # symbol and the text that appear in the legend -
    scatter!(p, [NaN], [NaN], marker = :square, ms = 7, mc = :green3, msc = :green3, label = "charging station");
    scatter!(p, [NaN], [NaN], marker = :square, ms = 7, mc = :red, msc = :red, label = "lava pit");
    scatter!(p, [NaN], [NaN], marker = :rtriangle, ms = 6, mc = :gray55, msc = :gray55, label = "policy");
    plot!(p, [NaN], [NaN], c = :dodgerblue, lw = 3, label = "path");
    scatter!(p, [NaN], [NaN], ms = 7, mc = :dodgerblue, msc = :white, label = "start");

    # return the figure -
    return p;
end

end # module L11cRollout
