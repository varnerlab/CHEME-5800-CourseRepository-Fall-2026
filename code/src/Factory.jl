function _build(recordtype::Type{MySarcasmRecordModel}, data::NamedTuple)::MySarcasmRecordModel

    # get data from the NamedTuple -
    headlinerecord = data.headline;
    article = data.article;
    issarcastic = data.issarcastic;

    # clean the data - do NOT include puncuation in the headline -
    puncuation_skip_set = Set{Char}();
    push!(puncuation_skip_set, ',');
    push!(puncuation_skip_set, '.');
    push!(puncuation_skip_set, '!');
    push!(puncuation_skip_set, '?');
    push!(puncuation_skip_set, ';');
    push!(puncuation_skip_set, ':');
    push!(puncuation_skip_set, ')');
    push!(puncuation_skip_set, '(');
    push!(puncuation_skip_set, '\"');
    push!(puncuation_skip_set, '/');
    push!(puncuation_skip_set, '\\');
    push!(puncuation_skip_set, '-');
    push!(puncuation_skip_set, '_');
    push!(puncuation_skip_set, '`');
    push!(puncuation_skip_set, ''');
    push!(puncuation_skip_set, '*');
    push!(puncuation_skip_set, '+');
    push!(puncuation_skip_set, '=');
    push!(puncuation_skip_set, '@');
    push!(puncuation_skip_set, '%');
    push!(puncuation_skip_set, '|');
    push!(puncuation_skip_set, '{');
    push!(puncuation_skip_set, '}');
    push!(puncuation_skip_set, '[');
    push!(puncuation_skip_set, ']');
    push!(puncuation_skip_set, '<');
    push!(puncuation_skip_set, '>');
    push!(puncuation_skip_set, '~');
    push!(puncuation_skip_set, '^');
    push!(puncuation_skip_set, '&');
    push!(puncuation_skip_set, '$');
    push!(puncuation_skip_set, '¿');
    push!(puncuation_skip_set, '¡');
    push!(puncuation_skip_set, '£');
    push!(puncuation_skip_set, '€');
    push!(puncuation_skip_set, '¥');
    push!(puncuation_skip_set, '₹');
    push!(puncuation_skip_set, '©');
    push!(puncuation_skip_set, '®');
    push!(puncuation_skip_set, '™');
    push!(puncuation_skip_set, '¯');
    push!(puncuation_skip_set, ' ');

    # ok, so field is a string, and we are checking if it contains any of the puncuation characters
    chararray =  headlinerecord |> collect;

    # let's use the filter function to remove any puncuation characters from the field -
    headlinerecord = filter(c -> (c |> Int ) ≤ 255 && !(c ∈ puncuation_skip_set),
            chararray) |> String |> string-> strip(string, ' ') |> String;

    # checks?
    # if we split the headline, we should have a list of words, with no field being empty
    fields = split(headlinerecord, ' ') .|> String
    fields = filter(x -> x != "", fields)
    headlinerecord = join(fields, ' ')

    # create the an empty instance of the modeltype, and then add data to it
    record = recordtype();
    record.headline = headlinerecord;
    record.article = article;
    record.issarcastic = issarcastic;

    # return the populated model -
    return record;
end


function build(record::Type{T}, data::NamedTuple)::T where T <: AbstractTextRecordModel
    return _build(record, data);
end

"""
    function build(modeltype::Type{T},
        data::NamedTuple)::T where T <: AbstractLinearProgrammingProblemType

The function builds a linear programming problem model from the data provided.

### Arguments
- `modeltype::Type{T}`: the type of the model to build where `T` is a subtype of `AbstractLinearProgrammingProblemType`.
- `data::NamedTuple`: the data to use to build the model.

The `data::NamedTuple` must have the following fields:
- `A::Array{Float64,2}`: the constraint matrix.
- `b::Array{Float64,1}`: the right-hand side vector.
- `c::Array{Float64,1}`: the cost vector.
- `lb::Array{Float64,1}`: the lower bounds vector.
- `ub::Array{Float64,1}`: the upper bounds vector.

### Returns
- a linear programming problem model of type `T` where `T` is a subtype of `AbstractLinearProgrammingProblemType`.
"""
function build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractLinearProgrammingProblemType

    # initialize -
    model = modeltype(); # build an empty model

    # set the data -
    model.A = data.A;
    model.b = data.b;
    model.c = data.c;
    model.lb = data.lb;
    model.ub = data.ub;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyPerceptronClassificationModel},
        data::NamedTuple) -> MyPerceptronClassificationModel

The function builds a perceptron classification model from the data provided.

### Arguments
- `modeltype::Type{MyPerceptronClassificationModel}`: the type of the model to build.
- `data::NamedTuple`: the data to use to build the model.

The `data::NamedTuple` must have the following fields:
- `parameters::Vector{Float64}`: the coefficients of the model.
- `mistakes::Int64`: the number of mistakes that are are willing to make.

### Returns
- a perceptron classification model.
"""
function build(modeltype::Type{MyPerceptronClassificationModel},
    data::NamedTuple)::MyPerceptronClassificationModel

    # build an empty model -
    model = modeltype();
    β = data.parameters;
    m = data.mistakes;

    # set the data -
    model.β = β;
    model.mistakes = m;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyLogisticRegressionClassificationModel},
        data::NamedTuple) -> MyLogisticRegressionClassificationModel

The function builds a logistic regression classification model from the data provided.

### Arguments
- `modeltype::Type{MyLogisticRegressionClassificationModel}`: the type of the model to build.
- `data::NamedTuple`: the data to use to build the model.

The `data::NamedTuple` must have the following fields:
- `parameters::Vector{Float64}`: the coefficients of the model.

### Returns
- a logistic regression classification model.
"""
function build(modeltype::Type{MyLogisticRegressionClassificationModel},
    data::NamedTuple)::MyLogisticRegressionClassificationModel

    # build an empty model -
    model = modeltype();
    β = data.parameters;
    α = data.learning_rate
    L = data.loss_function
    ϵ = data.ϵ
    T = data.T; # inverse temperature parameter
    λ = data.λ; # regularization parameter
    h = data.h; # finite difference step size

    # set the data -
    model.β = β;
    model.α = α;
    model.L = L;
    model.ϵ = ϵ;
    model.T = T;
    model.λ = λ;
    model.h = h;

    # return -
    return model;
end

"""
    function build(model::Type{T}, edgemodels::Dict{Int64, MyGraphEdgeModel}) where T <: AbstractGraphModel

This function builds a graph model from a dictionary of edge models.

### Arguments
- `model::Type{T}`: The type of graph model to build, where `T` is a subtype of `AbstractGraphModel`.
- `edgemodels::Dict{Int64, MyGraphEdgeModel}`: A dictionary of edge models to use for building the graph.

### Returns
- `T`: The constructed graph model, where `T` is a subtype of `AbstractGraphModel`.
"""
function build(model::Type{T}, edgemodels::Dict{Int64, MyGraphEdgeModel}) where T <: AbstractGraphModel

    # build and empty graph model -
    graphmodel = model();
    nodes = Dict{Int64, MyGraphNodeModel}();
    edges = Dict{Tuple{Int64, Int64}, Number}();
    children = Dict{Int64, Set{Int64}}();
    edgesinverse = Dict{Int, Tuple{Int, Int}}();

    # let's build a list of nodes ids -
    tmp_node_ids = Set{Int64}();
    for (_,v) ∈ edgemodels
        push!(tmp_node_ids, v.source);
        push!(tmp_node_ids, v.target);
    end
    list_of_node_ids = tmp_node_ids |> collect |> sort;

    # remap the node ids to a contiguous ordering -
    nodeidmap = Dict{Int64, Int64}();
    nodecounter = 1;
    for id ∈ list_of_node_ids
        nodeidmap[id] = nodecounter;
        nodecounter += 1;
    end

    # build the nodes models -
    [nodes[nodeidmap[id]] = MyGraphNodeModel(nodeidmap[id], nothing) for id ∈ list_of_node_ids];

    # build the edges -
    for (_, v) ∈ edgemodels
        source_index = nodeidmap[v.source];
        target_index = nodeidmap[v.target];
        edges[(source_index, target_index)] = v.weight;
    end

    # build the inverse edge dictionary edgeid -> (source, target)
    n = length(nodes);
    edgecounter = 1;
    for source ∈ 1:n
        for target ∈ 1:n
            if haskey(edges, (source, target)) == true
                edgesinverse[edgecounter] = (source, target);
                edgecounter += 1;
            end
        end
    end

    # compute the children -
    for id ∈ list_of_node_ids
        newid = nodeidmap[id];
        node = nodes[newid];
        children[newid] = _children(edges, node.id);
    end


    # add stuff to model -
    graphmodel.nodes = nodes;
    graphmodel.edges = edges;
    graphmodel.edgesinverse = edgesinverse;
    graphmodel.children = children;

    # return -
    return graphmodel;
end

function build(edgemodel::Type{MyGraphEdgeModel}, data::NamedTuple)::MyGraphEdgeModel

    # initialize -
    model = edgemodel(); # build an empty edge model

    # get data from the tuple -
    id = data.id;
    source = data.source;
    target = data.target;
    weight = data.weight;

    # populate -
    model.id = id;
    model.source = source;
    model.target = target;
    model.weight = weight;

    # return -
    return model
end

function build(edgemodel::Type{MyConstrainedGraphEdgeModel}, data::NamedTuple)::MyConstrainedGraphEdgeModel

    # initialize -
    model = edgemodel(); # build an empty edge model

    # get data from the tuple -
    id = data.id;
    source = data.source;
    target = data.target;
    lower = data.lower;
    upper = data.upper;
    weight = data.weight;

    # populate -
    model.id = id;
    model.source = source;
    model.target = target;
    model.lower = lower;
    model.upper = upper;
    model.weight = weight;

    # return -
    return model
end

"""
    function build(modeltype::Type{MyDirectedBipartiteGraphModel}, data::NamedTuple) -> MyDirectedBipartiteGraphModel

This function builds a mutable `MyDirectedBipartiteGraphModel` instance given the data in the `data::NamedTuple` argument.

### Arguments
- `modeltype::Type{MyDirectedBipartiteGraphModel}` - The type of the model to build.
- `data::NamedTuple` - The data to populate the model with.

The `data::NamedTuple` argument must contain the following fields:
- `s::Int64` - The source node index.
- `t::Int64` - The target node index.
- `edges::Dict{Int, MyConstrainedGraphEdgeModel}` - The edges dictionary containing the constrained graph edges models.

"""
function build(modeltype::Type{MyDirectedBipartiteGraphModel}, data::NamedTuple)::MyDirectedBipartiteGraphModel

    # initialize -
    model = modeltype(); # build an empty model
    nodes = Dict{Int64, MyGraphNodeModel}();
    edges = Dict{Tuple{Int64, Int64}, Number}();
    children = Dict{Int64, Set{Int64}}();
    edgesinverse = Dict{Int, Tuple{Int, Int}}();
    capacity = Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}();

    # get stuff from the NamedTuple -
    sid = data.s; # source node index
    tid = data.t; # target node index
    edgemodels = data.edges; # edges dictionary

    # let's build a list of nodes ids -
    tmp_node_ids = Set{Int64}();
    for (_,v) ∈ edgemodels
        push!(tmp_node_ids, v.source);
        push!(tmp_node_ids, v.target);
    end
    list_of_node_ids = tmp_node_ids |> collect |> sort;

    # remap the node ids to a contiguous ordering -
    nodeidmap = Dict{Int64, Int64}();
    nodecounter = 1;
    for id ∈ list_of_node_ids
        nodeidmap[id] = nodecounter;
        nodecounter += 1;
    end

    # build the nodes models -
    [nodes[nodeidmap[id]] = MyGraphNodeModel(nodeidmap[id], nothing) for id ∈ list_of_node_ids];

    # build the edges -
    for (_, v) ∈ edgemodels
        source_index = nodeidmap[v.source];
        target_index = nodeidmap[v.target];
        edges[(source_index, target_index)] = v.weight;
    end

    # build the inverse edge dictionary edgeid -> (source, target)
    n = length(nodes);
    edgecounter = 1;
    for source ∈ 1:n
        for target ∈ 1:n
            if haskey(edges, (source, target)) == true
                edgesinverse[edgecounter] = (source, target);
                edgecounter += 1;
            end
        end
    end

    # compute the children -
    for id ∈ list_of_node_ids
        newid = nodeidmap[id];
        node = nodes[newid];
        children[newid] = _children(edges, node.id);
    end

    # let's build the capacity dictionary -
    for (_, edge) ∈ edgemodels
        s = edge.source;
        t = edge.target;
        capacity[(s, t)] = (edge.lower, edge.upper);
    end

    # populate the model -
    model.nodes = nodes;
    model.edges = edges;
    model.edgesinverse = edgesinverse;
    model.children = children;
    model.capacity = capacity;
    model.source = sid;
    model.sink = tid;

    # return -
    return model
end

"""
    build(model::Type{MyMDPProblemModel}, data::NamedTuple) -> MyMDPProblemModel

Builds a `MyMDPProblemModel` from a `NamedTuple`.

### Arguments
- `model::Type{MyMDPProblemModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `𝒮::Array{Int64,1}`: state space
- `𝒜::Array{Int64,1}`: action space
- `T::Union{Function, Array{Float64,3}}`: transition matrix of function
- `R::Union{Function, Array{Float64,2}}`: reward matrix or function
- `γ::Float64`: discount factor

### Returns
- `MyMDPProblemModel`: the built MDP problem model
"""
function build(model::Type{MyMDPProblemModel}, data::NamedTuple)::MyMDPProblemModel

    # build an empty model -
    m = model();

    # get data from the named tuple -
    haskey(data, :𝒮) == false ? m.𝒮 = Array{Int64,1}(undef,1) : m.𝒮 = data[:𝒮];
    haskey(data, :𝒜) == false ? m.𝒜 = Array{Int64,1}(undef,1) : m.𝒜 = data[:𝒜];
    haskey(data, :T) == false ? m.T = Array{Float64,3}(undef,1,1,1) : m.T = data[:T];
    haskey(data, :R) == false ? m.R = Array{Float64,2}(undef,1,1) : m.R = data[:R];
    haskey(data, :γ) == false ? m.γ = 0.1 : m.γ = data[:γ];

    # return -
    return m;
end

"""
    build(modeltype::Type{MyRectangularGridWorldModel}, data::NamedTuple) -> MyRectangularGridWorldModel

Builds a `MyRectangularGridWorldModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyRectangularGridWorldModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `nrows::Int`: number of rows in the grid
- `ncols::Int`: number of columns in the grid
- `rewards::Dict{Tuple{Int,Int},Float64}`: dictionary of state to reward mapping
- `defaultreward::Float64`: default reward value (optional)

### Returns
- `MyRectangularGridWorldModel`: a populated rectangular grid world model
"""
function build(modeltype::Type{MyRectangularGridWorldModel}, data::NamedTuple)::MyRectangularGridWorldModel

    # initialize and empty model -
    model = modeltype()

    # get the data -
    nrows = data[:nrows]
    ncols = data[:ncols]
    rewards = data[:rewards]
    defaultreward = haskey(data, :defaultreward) == false ? -1.0 : data[:defaultreward]

    # setup storage
    rewards_dict = Dict{Int,Float64}()
    coordinates = Dict{Int,Tuple{Int,Int}}()
    states = Dict{Tuple{Int,Int},Int}()
    moves = Dict{Int,Tuple{Int,Int}}()

    # build all the stuff
    position_index = 1;
    for i ∈ 1:nrows
        for j ∈ 1:ncols

            # capture this corrdinate
            coordinate = (i,j);

            # set -
            coordinates[position_index] = coordinate;
            states[coordinate] = position_index;

            if (haskey(rewards,coordinate) == true)
                rewards_dict[position_index] = rewards[coordinate];
            else
                rewards_dict[position_index] = defaultreward;
            end

            # update position_index -
            position_index += 1;
        end
    end

    # setup the moves dictionary -
    moves[1] = (-1,0)   # a = 1 up
    moves[2] = (1,0)    # a = 2 down
    moves[3] = (0,-1)   # a = 3 left
    moves[4] = (0,1)    # a = 4 right

    # add items to the model -
    model.rewards = rewards_dict
    model.coordinates = coordinates
    model.states = states;
    model.moves = moves;
    model.number_of_rows = nrows
    model.number_of_cols = ncols

    # return -
    return model
end

"""
    build(modeltype::Type{MyEpsilonGreedyAlgorithmModel}, data::NamedTuple) -> MyEpsilonGreedyAlgorithmModel

Builds a `MyEpsilonGreedyAlgorithmModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyEpsilonGreedyAlgorithmModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `K::Int64`: number of arms
"""
function build(modeltype::Type{MyEpsilonGreedyAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build empty model -
    model = modeltype();
    model.K = K;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyExploreFirstAlgorithmModel}, data::NamedTuple) -> MyExploreFirstAlgorithmModel

Builds a `MyExploreFirstAlgorithmModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyExploreFirstAlgorithmModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `K::Int64`: number of arms
"""
function build(modeltype::Type{MyExploreFirstAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build empty model -
    model = modeltype();
    model.K = K;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyUCB1AlgorithmModel}, data::NamedTuple) -> MyUCB1AlgorithmModel

Builds a `MyUCB1AlgorithmModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyUCB1AlgorithmModel}`: the model type to
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `K::Int64`: number of arms
"""
function build(modeltype::Type{MyUCB1AlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build empty model -
    model = modeltype();
    model.K = K;

    # return -
    return model;
end


"""
    build(modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel},
        data::NamedTuple) -> MyBinaryWeightedMajorityAlgorithmModel

Build a Binary Weighted Majority Algorithm model. This function initializes the model with the given parameters
in the `data` NamedTuple. The model is returned to the caller.

### Arguments
- `modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel}`: the type of the model to build
- `data::NamedTuple`: the parameters to initialize the model

The named tuple `data` must have the following fields:
- `ϵ::Float64`: learning rate
- `n::Int64`: number of experts
- `T::Int64`: number of rounds
- `expert::Function`: expert function
- `adversary::Function`: adversary function
"""
function build(modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel},
    data::NamedTuple)::MyBinaryWeightedMajorityAlgorithmModel

    # Initialize -
    model = modeltype(); # build an empty model
    ϵ = data.ϵ; # learning rate
    n = data.n; # number of experts
    T = data.T; # number of rounds
    expert = data.expert; # expert function
    adversary = data.adversary; # adversary function

    # set the parameters -
    model.ϵ = ϵ;
    model.n = n;
    model.T = T;
    model.expert = expert;
    model.adversary = adversary;
    model.weights = ones(Float64, T+1, n) # initialize the weights array with ones

    # return the model -
    return model;
end

"""
    function build(modeltype::Type{MyTwoPersonZeroSumGameModel},
        data::NamedTuple)::MyTwoPersonZeroSumGameModel

This method builds and returns an instance of the `MyTwoPersonZeroSumGameModel` type.

### Arguments
- `modeltype::Type{MyTwoPersonZeroSumGameModel}`: The model type to build.
- `data::NamedTuple`: A named tuple containing the model parameters:
    - `ϵ::Float64`: The learning rate.
    - `n::Int`: The number of experts (actions).
    - `T::Int`: The number of rounds.
    - `payoffmatrix::Array{Float64,2}`: The payoff matrix.

### Returns
- `model::MyTwoPersonZeroSumGameModel`: An instance of the `MyTwoPersonZeroSumGameModel` type with the specified parameters.
"""
function build(modeltype::Type{MyTwoPersonZeroSumGameModel},
    data::NamedTuple)::MyTwoPersonZeroSumGameModel

    # initialize -
    model = modeltype(); # build an empty model
    ϵ = data.ϵ; # learning rate
    n = data.n; # number of experts (actions)
    T = data.T; # number of rounds
    payoffmatrix = data.payoffmatrix; # payoff matrix

    # set the parameters -
    model.ϵ = ϵ;
    model.n = n;
    model.T = T;
    model.payoffmatrix = payoffmatrix;
    model.weights = zeros(Float64, T+1, n) # initialize the weights array with ones

    # generate a random initial weight vector -
    model.weights[1, :] = rand(n);

    # return the model -
    return model;
end

"""
    build(modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}, data::NamedTuple) -> MyBinaryVectorArmsEpsilonGreedyAlgorithmModel

Builds a `MyBinaryVectorArmsEpsilonGreedyAlgorithmModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `K::Int64`: number of arms

### Returns
- `MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`: a populated binary vector arms epsilon greedy algorithm model
"""
function build(modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build empty model -
    model = modeltype();
    model.K = K;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyConsumerChoiceBanditContextModel}, data::NamedTuple) -> MyConsumerChoiceBanditContextModel

Builds a `MyConsumerChoiceBanditContextModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyConsumerChoiceBanditContextModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model
The `data` `NamedTuple` must contain the following keys:
- `data::Dict{String, Any}`: data dictionary for each item, or more generally the context
- `items::Array{String,1}`: items for each asset
- `bounds::Array{Float64,2}`: bounds on the assets that we can purchase
- `B::Float64`: budget that we have to spend on the collection of assets
- `nₒ::Array{Float64,1}`: initial guess for the solution
- `μₒ::Array{Float64,1}`: initial for the utility of each arm
- `γ::Array{Float64,1}`: parameters for the utility function (preferences)

### Returns
- `MyConsumerChoiceBanditContextModel`: a populated consumer choice bandit context model
"""
function build(modeltype::Type{MyConsumerChoiceBanditContextModel},
    data::NamedTuple)::MyConsumerChoiceBanditContextModel

    # get stuff from the NamedTuple -
    contextdata = data.data; # data dictionary for each item, or more generally the context
    items = data.items; # items for each asset
    bounds = data.bounds; # bounds on the assets that we can purchase
    B = data.B; # budget that we have to spend on the collection of assets
    nₒ = data.nₒ; # initial guess for the solution
    μₒ = data.μₒ; # initial for the utility of each arm
    γ = data.γ; # parameters for the utility function (preferences)

    # build empty model -
    model = modeltype();
    model.data = contextdata;
    model.items = items;
    model.bounds = bounds;
    model.B = B;
    model.nₒ = nₒ;
    model.μₒ = μₒ;
    model.γ = γ;

    # return -
    return model;
end

"""
    function build(type::Type{MyQLearningModel},data::NamedTuple) -> MyQLearningModel

Builds a `MyQLearningAgentModel` from data in a `NamedTuple`.

### Arguments
- `modeltype::Type{MyQLearningAgentModel}`: the model type to build
- `data::NamedTuple`: the data to use to build the model

The `data` `NamedTuple` must contain the following keys:
- `states::Array{Int64,1}`: the state space
- `actions::Array{Int64,1}`: the action space
- `α::Float64`: the learning rate
- `γ::Float64`: the discount factor

### Returns
- `MyQLearningAgentModel`: a populated Q-learning agent model

"""
function build(modeltype::Type{MyQLearningAgentModel}, data::NamedTuple)::MyQLearningAgentModel

    # initialize -
    model = MyQLearningAgentModel();

    # if we have options, add them to the contract model -
    if (isempty(data) == false)

        for key ∈ fieldnames(modeltype)

            # convert the field_name_symbol to a string -
            field_name_string = string(key)

            # check the for the key -
            if (haskey(data, key) == false)
                throw(ArgumentError("NamedTuple is missing: $(field_name_string)"))
            end

            # get the value -
            value = data[key]

            # set -
            setproperty!(model, key, value)
        end
    end

    # return -
    return model
end

# -- HOPFIELD METHODS BELOW HERE ---------------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyClassicalHopfieldNetworkModel}, data::NamedTuple) -> MyClassicalHopfieldNetworkModel

Factory method for building a Hopfield network model.

### Arguments
- `modeltype::Type{MyClassicalHopfieldNetworkModel}`: the type of the model to be built.
- `data::NamedTuple`: a named tuple containing the data for the model.

The named tuple should contain the following fields:
- `memories`: a matrix of memories (each column is a memory).

### Returns
- `model::MyClassicalHopfieldNetworkModel`: the built Hopfield network model with the following fields populated:
    - `W`: the weight matrix.
    - `b`: the bias vector.
    - `memories`: the stored memories (columns).
    - `energy`: a dictionary of energies for each memory.
"""
function build(modeltype::Type{MyClassicalHopfieldNetworkModel}, data::NamedTuple)::MyClassicalHopfieldNetworkModel

    # initialize -
    model = modeltype();
    linearimagecollection = data.memories;
    number_of_rows, number_of_cols = size(linearimagecollection);
    W = zeros(Float32, number_of_rows, number_of_rows);
    b = zeros(Float32, number_of_rows); # zero bias for classical Hopfield

    # compute the W -
    for j ∈ 1:number_of_cols
        Y = ⊗(linearimagecollection[:,j], linearimagecollection[:,j]); # compute the outer product -
        W += Y; # update the W -
    end

    # no self-coupling and Hebbian scaling -
    for i ∈ 1:number_of_rows
        W[i,i] = 0.0f0; # no self-coupling in a classical Hopfield network
    end
    WN = (1/number_of_rows)*W; # We are going to scale the weights by the number if features (number of rows) to ensure that the energy landscape is well-behaved, and to prevent numerical issues during the energy computation.

    # compute the energy dictionary -
    energy = Dict{Int64, Float32}();
    for i ∈ 1:number_of_cols
        energy[i] = _energy(linearimagecollection[:,i], WN, b);
    end

    # add data to the model -
    model.W = WN;
    model.b = b;
    model.memories = copy(linearimagecollection);
    model.energy = energy;

    # return -
    return model;
end

"""
    build(modeltype::Type{MyModernHopfieldNetworkModel}, data::NamedTuple) -> MyModernHopfieldNetworkModel

Factory method for assembling a modern Hopfield network model from raw memories and an inverse-temperature parameter.

### Arguments
- `modeltype::Type{MyModernHopfieldNetworkModel}`: concrete model type to instantiate.
- `data::NamedTuple`: expects `memories` (matrix with memories on columns) and `β` (inverse-temperature scalar).

### Returns
- `model::MyModernHopfieldNetworkModel`: model populated with `X` (memory matrix) and `β`.
"""
function build(modeltype::Type{MyModernHopfieldNetworkModel}, data::NamedTuple)::MyModernHopfieldNetworkModel

    # initialize -
    model = modeltype();
    linearimagecollection = data.memories;
    normalized_linear_image_collection = data.normalized_memories;
    β = data.β; # beta parameter

    # add stuff the model -
    model.β = β;
    model.X = linearimagecollection;
    model.X̂ = normalized_linear_image_collection;

    # return -
    return model;
end
# --- HOPFIELD METHODS ABOVE HERE --------------------------------------------------------------------------------------- #

# -- UTILITY FUNCTION METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    _build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractUtilityFunctionType

Generic reflection-based factory: builds an empty instance of `modeltype` and sets each of its fields from the
matching key in `data` (missing keys are set to `nothing`).
"""
function _build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractUtilityFunctionType

    # build an empty model
    model = modeltype();

    # if we have options, add them to the contract model -
    if (isempty(data) == false)
        for key ∈ fieldnames(modeltype)

            # check the for the key - if we have it, then grab this value
            value = nothing
            if (haskey(data, key) == true)
                # get the value -
                value = data[key]
            end

            # set -
            setproperty!(model, key, value)
        end
    end

    # return -
    return model
end

"""
    build(model::Type{VLLinearUtilityFunction}, data::NamedTuple)::VLLinearUtilityFunction

Factory method for building a [`VLLinearUtilityFunction`](@ref) instance from a `NamedTuple`.

### Arguments
- `model::Type{VLLinearUtilityFunction}`: the type of the model to build.
- `data::NamedTuple`: must contain the key `α::Array{Float64,1}` (the linear utility weights/parameters).

### Returns
- `VLLinearUtilityFunction`: the populated model.
"""
build(model::Type{VLLinearUtilityFunction}, data::NamedTuple)::VLLinearUtilityFunction = _build(model, data)
# -- UTILITY FUNCTION METHODS ABOVE HERE -------------------------------------------------------------------------------- #
