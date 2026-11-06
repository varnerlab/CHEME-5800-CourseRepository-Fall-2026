# =============================================================================
# CHEME 5800 | L12a example code: the lava grid world, and drawing a policy
# =============================================================================
# This file holds the functions the example uses to build the world and to look at
# a policy:
#
#   build_mdp(...)      builds the rewards and the transition probabilities of the grid world
#   lavaworld(...)      simulates one move: the next state and the reward
#   count_optimal_moves(...)  counts the states where a policy chooses an optimal action
#   follow_policy(...)  walks a policy from a start square
#   square(...)         makes the outline of one grid square, for drawing
#   arrow_shape(...)    makes a small arrow that points one way, for drawing
#   draw_path(...)      draws the grid world, the policy, and the robot's path
#
# None of them reads a notebook variable; everything they need is passed in as
# an argument. Include.jl loads this file only once, so restart the kernel if
# you edit it.
# =============================================================================
module L12aGridWorld

using VLDataScienceMachineLearningPackage: MyRectangularGridWorldModel, MyMDPProblemModel, build # the grid world and MDP types, and build
using Random # AbstractRNG, the type of a random number generator
using Plots # the figure drawn by draw_path

export build_mdp, lavaworld, count_optimal_moves, follow_policy, square, arrow_shape, draw_path

"""
    build_mdp(world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
        absorbing_state_set::Set{Tuple{Int,Int}}; γ::Float64, step_reward::Float64 = -1.0,
        off_grid_reward::Float64 = -50000.0) -> MyMDPProblemModel

Build the Markov decision process of the grid world: the reward matrix `R`, the transition
array `T`, and the discount factor `γ`, packaged as a `MyMDPProblemModel`. These are the same
rules we used for value iteration.

Every move is certain. A move onto a square of the grid lands there and collects that square's
reward: the charging station or lava pit reward from `rewards`, or `step_reward` for an ordinary
square. A move that would leave the grid keeps the robot where it is and costs
`off_grid_reward`. In an absorbing state, every action keeps the robot where it is and earns
nothing, because the episode has ended.

### Arguments
- `world::MyRectangularGridWorldModel`: the grid world; we use its `coordinates`, `states`, and
  `moves` dictionaries.
- `rewards::Dict{Tuple{Int,Int},Float64}`: the reward of the charging station and each lava pit.
- `absorbing_state_set::Set{Tuple{Int,Int}}`: the `(x, y)` squares that end an episode.
- `γ::Float64`: the discount factor, `0 ≤ γ < 1`.
- `step_reward::Float64 = -1.0`: the reward of an ordinary move.
- `off_grid_reward::Float64 = -50000.0`: the reward of a move off the grid.

### Returns
- `MyMDPProblemModel`: the MDP, with states `1, 2, …, |𝒮|`, actions `1, 2, 3, 4`, the transition
  array `T` of size `|𝒮| × |𝒮| × |𝒜|`, the reward matrix `R` of size `|𝒮| × |𝒜|`, and `γ`.
"""
function build_mdp(world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
    absorbing_state_set::Set{Tuple{Int,Int}}; γ::Float64, step_reward::Float64 = -1.0,
    off_grid_reward::Float64 = -50000.0)::MyMDPProblemModel

    # initialize -
    number_of_states = length(world.coordinates); # one state per square
    number_of_actions = length(world.moves); # left, right, down, up
    R = zeros(number_of_states, number_of_actions);
    T = zeros(number_of_states, number_of_states, number_of_actions);

    # main loop: where each state-action pair lands, and what it earns -
    for s ∈ 1:number_of_states
        current_position = world.coordinates[s]; # the (x,y) square of state s
        for a ∈ 1:number_of_actions
            Δ = world.moves[a]; # the move for action a, e.g., up = (0,1)
            new_position = (current_position[1] + Δ[1], current_position[2] + Δ[2]); # where action a takes us

            if (in(current_position, absorbing_state_set) == true)
                T[s, s, a] = 1.0; # the episode has ended: we stay put
                R[s, a] = 0.0; # and earn nothing more
            elseif (haskey(world.states, new_position) == true)
                T[s, world.states[new_position], a] = 1.0; # a legal move lands on the new square
                if (haskey(rewards, new_position) == true)
                    R[s, a] = rewards[new_position]; # the charging station or a lava pit
                else
                    R[s, a] = step_reward; # an ordinary move
                end
            else
                T[s, s, a] = 1.0; # off the grid: we stay put
                R[s, a] = off_grid_reward; # so costly that the robot learns never to do it
            end
        end
    end

    # package the MDP -
    𝒮 = range(1, stop = number_of_states, step = 1) |> collect; # states
    𝒜 = range(1, stop = number_of_actions, step = 1) |> collect; # actions
    return build(MyMDPProblemModel, (𝒮 = 𝒮, 𝒜 = 𝒜, T = T, R = R, γ = γ));
end

"""
    lavaworld(problem::MyMDPProblemModel, s::Int64, a::Int64, rng::AbstractRNG) -> Tuple{Int64,Float64}

Simulate one move of the robot: return the next state `s′` and the reward `r` of taking action
`a` in state `s`. This is the only way the Q-learning agent touches the world.

The function draws the next state from the transition probabilities `T(s′|s,a)` of `problem`:
it draws a random number `u` between 0 and 1, then adds up `T(1|s,a), T(2|s,a), …` until the
running sum first exceeds `u`. The reward is `R[s,a]`.

### Arguments
- `problem::MyMDPProblemModel`: the MDP, built by `build_mdp(...)`.
- `s::Int64`: the current state.
- `a::Int64`: the action.
- `rng::AbstractRNG`: the random number generator to draw from.

### Returns
- `Tuple{Int64,Float64}`: the next state `s′` and the reward `r`.
"""
function lavaworld(problem::MyMDPProblemModel, s::Int64, a::Int64, rng::AbstractRNG)::Tuple{Int64,Float64}

    # draw the next state from T(s′|s,a) -
    u = rand(rng); # a random number between 0 and 1
    running_sum = 0.0; # T(1|s,a) + T(2|s,a) + ... so far
    s′ = s;
    for j ∈ problem.𝒮
        running_sum = running_sum + problem.T[s, j, a];
        if (u < running_sum)
            s′ = j; # the first state where the running sum exceeds u
            break;
        end
    end

    # the reward -
    r = problem.R[s, a];

    # return -
    return (s′, r);
end

"""
    count_optimal_moves(Qstar::Array{Float64,2}, policy::Array{Int64,1},
        absorbing::Set{Int64}; tolerance::Float64 = 1e-6) -> Tuple{Int64,Int64}

Count the states, other than the absorbing ones, in which `policy` chooses an optimal action.

When several actions tie for the best value, any of them is optimal. So we count the action
`policy[s]` as optimal when its optimal action value `Qstar[s, policy[s]]` is within
`tolerance` of the best value in the row, `maximum(Qstar[s,:])`.

### Arguments
- `Qstar::Array{Float64,2}`: the optimal action values, one row per state and one column per action.
- `policy::Array{Int64,1}`: the action to take in each state, i.e., `policy[s]` is the action in state `s`.
- `absorbing::Set{Int64}`: the states that end an episode; we skip them.
- `tolerance::Float64 = 1e-6`: how close to the best value counts as a tie.

### Returns
- `Tuple{Int64,Int64}`: the number of states where the action is optimal, and the number of
  states we checked.
"""
function count_optimal_moves(Qstar::Array{Float64,2}, policy::Array{Int64,1},
    absorbing::Set{Int64}; tolerance::Float64 = 1e-6)::Tuple{Int64,Int64}

    # initialize -
    number_optimal = 0; # states where the policy's action is optimal
    number_checked = 0; # states that are not absorbing

    # main loop: check each state that is not absorbing -
    for s ∈ 1:size(Qstar, 1)
        if (in(s, absorbing) == false)
            number_checked = number_checked + 1;
            best = maximum(Qstar[s, :]); # the best value in state s
            if (Qstar[s, policy[s]] ≥ best - tolerance)
                number_optimal = number_optimal + 1;
            end
        end
    end

    # return -
    return (number_optimal, number_checked);
end

"""
    follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
        world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
        absorbing_state_set::Set{Tuple{Int,Int}};
        charging_reward::Float64) -> Tuple{Array{Tuple{Int,Int},1}, String}

Walk a policy from a starting square, and report the squares visited and how the walk ended.

Starting at `start`, the function looks up the action the policy chooses in the current
square and moves the robot one square. It repeats this until the robot enters an absorbing
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
  `start`, and a phrase describing how the walk ended. When the walk ends in a loop, the last
  square is the visited square the robot returned to. The number of moves is one less than
  the number of squares in the path.
"""
function follow_policy(policy::Array{Int64,1}, start::Tuple{Int,Int},
    world::MyRectangularGridWorldModel, rewards::Dict{Tuple{Int,Int},Float64},
    absorbing_state_set::Set{Tuple{Int,Int}};
    charging_reward::Float64)::Tuple{Array{Tuple{Int,Int},1}, String}

    # initialize -
    path = Array{Tuple{Int,Int},1}(); # the squares the robot visits, in order
    push!(path, start);
    position = start; # where the robot is now
    outcome = ""; # a phrase describing how the walk ended
    is_ok_to_stop = false; # we set this to true when the walk should end

    # a robot that starts in an absorbing square never moves -
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
            push!(path, new_position); # the move back to a square we already visited closes the loop
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

Draw the grid world, the policy in every square, and the robot's path.

Each square of the grid is drawn as a unit square, so the figure keeps its proportions for
any grid size. The charging station is a green square, and each lava pit is a red square, each drawn a
little smaller than its grid square.
A small gray arrow in every other square points in the direction the policy moves from that
square; `arrow_shape(...)` makes each one. The robot's path is a thick blue line from the
start square, marked with a blue dot, to where the walk ended.

### Arguments
- `path::Array{Tuple{Int,Int},1}`: the squares the robot visits, in order, as returned by
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

    # draw the path through the centers of the squares the robot visits -
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

end # module L12aGridWorld
