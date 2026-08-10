"""
    abstract type AbstractTextRecordModel end

Abstract supertype for a single record in a text corpus (e.g. one sarcasm headline, one SMS message).
"""
abstract type AbstractTextRecordModel end

"""
    abstract type AbstractTextDocumentCorpusModel end

Abstract supertype for a collection of [`AbstractTextRecordModel`](@ref) records plus a shared token dictionary.
"""
abstract type AbstractTextDocumentCorpusModel end

"""
    abstract type AbstractPriceTreeModel end

Abstract supertype for tree-structured price/asset models (e.g. recombining commodity price trees).
"""
abstract type AbstractPriceTreeModel end

"""
    abstract type AbstractGraphModel end

Abstract supertype for graph container types (directed, undirected, bipartite, ...).
"""
abstract type AbstractGraphModel end

"""
    abstract type AbstractGraphNodeModel end

Abstract supertype for graph node models.
"""
abstract type AbstractGraphNodeModel end

"""
    abstract type AbstractGraphEdgeModel end

Abstract supertype for graph edge models.
"""
abstract type AbstractGraphEdgeModel end

"""
    abstract type AbstractGraphSearchAlgorithm end

Abstract supertype (tag) for shortest-path search algorithms, e.g. [`DijkstraAlgorithm`](@ref) and
[`BellmanFordAlgorithm`](@ref), used to dispatch [`findshortestpath`](@ref).
"""
abstract type AbstractGraphSearchAlgorithm end

"""
    abstract type AbstractGraphFlowAlgorithm end

Abstract supertype (tag) for maximum-flow algorithms, e.g. [`FordFulkersonAlgorithm`](@ref) and
[`EdmondsKarpAlgorithm`](@ref), used to dispatch [`maximumflow`](@ref).
"""
abstract type AbstractGraphFlowAlgorithm end

"""
    abstract type AbstractGraphTraversalAlgorithm end

Abstract supertype (tag) for graph traversal algorithms, e.g. [`DepthFirstSearchAlgorithm`](@ref) and
[`BreadthFirstSearchAlgorithm`](@ref), used to dispatch [`walk`](@ref).
"""
abstract type AbstractGraphTraversalAlgorithm end

"""
    abstract type AbstractLinearSolverAlgorithm end

Abstract supertype (tag) for iterative linear-system solver algorithms, e.g. [`JacobiMethod`](@ref),
[`GaussSeidelMethod`](@ref), and [`SuccessiveOverRelaxationMethod`](@ref), used to dispatch `solve`.
"""
abstract type AbstractLinearSolverAlgorithm end

"""
    abstract type AbstractClassificationAlgorithm end

Abstract supertype for binary classification models (perceptron, logistic regression, ...) used to dispatch
[`learn`](@ref) and [`classify`](@ref).
"""
abstract type AbstractClassificationAlgorithm end

"""
    abstract type AbstractLinearProgrammingProblemType end

Abstract supertype for linear programming problem models.
"""
abstract type AbstractLinearProgrammingProblemType end

"""
    abstract type AbstractProcessModel end

Abstract supertype for stochastic process models, e.g. [`MyMDPProblemModel`](@ref).
"""
abstract type AbstractProcessModel end

"""
    abstract type AbstractWorldModel end

Abstract supertype for environment/world models that an agent interacts with, e.g.
[`MyRectangularGridWorldModel`](@ref).
"""
abstract type AbstractWorldModel end

"""
    abstract type AbstractBanditAlgorithmModel end

Abstract supertype for multi-armed bandit algorithm models (explore-first, epsilon-greedy, UCB1, ...).
"""
abstract type AbstractBanditAlgorithmModel end

"""
    abstract type AbstractOnlineLearningModel end

Abstract supertype for online learning models (weighted majority, two-person zero-sum game, Q-learning agent, ...).
"""
abstract type AbstractOnlineLearningModel end

"""
    abstract type AbstractBanditProblemContextModel end

Abstract supertype for contextual bandit problem context models.
"""
abstract type AbstractBanditProblemContextModel end

"""
    abstract type AbstractlHopfieldNetworkModel end

Abstract supertype for Hopfield network models (classical and modern).
"""
abstract type AbstractlHopfieldNetworkModel end

"""
    mutable struct MyLinearProgrammingProblemModel <: AbstractLinearProgrammingProblemType

A mutable struct that represents a linear programming problem model.

### Fields
- `A::Array{Float64,2}`: constraint matrix
- `b::Array{Float64,1}`: right-hand side vector
- `c::Union{Array{Float64,2}, Array{Float64,1}}`: objective function coefficient matrix (vector)
- `lb::Array{Float64,1}`: lower bound vector
- `ub::Array{Float64,1}`: upper bound vector

"""
mutable struct MyLinearProgrammingProblemModel <: AbstractLinearProgrammingProblemType

    # data -
    A::Array{Float64,2}     # constraint matrix
    b::Array{Float64,1}     # right-hand side vector
    c::Union{Array{Float64,2}, Array{Float64,1}}     # objective function coefficient matrix (vector)
    lb::Array{Float64,1}    # lower bound vector
    ub::Array{Float64,1}    # upper bound vector

    # constructor
    MyLinearProgrammingProblemModel() = new();
end



"""
    mutable struct MyPerceptronClassificationModel <: AbstractClassificationAlgorithm
A mutable struct that represents a perceptron classification model.

### Fields
    - `β::Vector{Float64}`: coefficients
    - `mistakes::Int64`: number of mistakes that are are willing to make
"""
mutable struct MyPerceptronClassificationModel <: AbstractClassificationAlgorithm

    # data -
    β::Vector{Float64}; # coefficients
    mistakes::Int64; # number of mistakes that are are willing to make

    # empty constructor -
    MyPerceptronClassificationModel() = new();
end

"""
    mutable struct MyLogisticRegressionClassificationModel <: AbstractClassificationAlgorithm

A mutable struct that represents a logistic regression classification model.

### Fields
    - `β::Vector{Float64}`: coefficients
    - `α::Float64`: learning rate
    - `ϵ::Float64`: convergence criterion
    - `L::Function`: loss function
    - `T::Float64`: inverse temperature parameter for the logistic function
    - `λ::Float64`: regularization parameter
    - `h::Float64`: finite difference step size
"""
mutable struct MyLogisticRegressionClassificationModel <: AbstractClassificationAlgorithm

    # data -
    β::Vector{Float64}; # coefficients
    α::Float64; # learning rate
    ϵ::Float64; # convergence criterion
    L::Function; # loss function
    T::Float64; # inverse temperature parameter for the logistic function
    λ::Float64; # regularization parameter
    h::Float64; # finite difference step size

    # empty constructor -
    MyLogisticRegressionClassificationModel() = new();
end

"""
    MySarcasmRecordModel <: AbstractTextRecordModel

Model for a record in the Sarcasm dataset.

### Fields
- `data::Array{String, Any}` - The data found in the record in the order they were found
"""
mutable struct MySarcasmRecordModel <: AbstractTextRecordModel

    # data -
    issarcastic::Bool
    headline::String
    article::String

    # constructor -
    MySarcasmRecordModel() = new(); # empty
end


"""
    MySarcasmRecordCorpusModel <: AbstractTextDocumentCorpusModel

Model for a collection of records in the Sarcasm dataset.

### Fields
- `records::Dict{Int, MySarcasmRecordModel}` - The records in the document (collection of records)
- `tokens::Dict{String, Int64}` - A dictionary of tokens in alphabetical order (key: token, value: position) for the entire document
"""
mutable struct MySarcasmRecordCorpusModel <: AbstractTextDocumentCorpusModel

    # data -
    records::Dict{Int, MySarcasmRecordModel}
    tokens::Dict{String, Int64}
    inverse::Dict{Int64, String}

    # constructor -
    MySarcasmRecordCorpusModel() = new(); # empty
end

# -- GRAPHS BELOW HERE ---------------------------------------------------------------------------- #
"""
    mutable struct MyGraphNodeModel

A lightweight mutable node model used in simple graph representations.

### Fields
- `id::Int64` - Unique integer identifier for the node.
"""
mutable struct MyGraphNodeModel <: AbstractGraphNodeModel

   # data -
   id::Int64
   data::Union{Nothing, Any}; # this is a little fancy??

   # constructor -
   MyGraphNodeModel(id::Int64, data::Union{Nothing, Any}) = new(id, data);
end

"""
    mutable struct MyGraphEdgeModel

A mutable edge model representing a directed or undirected connection between nodes.
The model stores a numeric id, endpoint indices, and an optional numeric weight.

### Fields
- `id::Int64` - Unique integer identifier for the edge.
- `source::Int64` - Identifier of the source node (or one endpoint).
- `target::Int64` - Identifier of the target node (or the other endpoint).
- `weight::Union{Nothing, Any}` - Optional edge weight; nothing indicates an unweighted edge.
"""
mutable struct MyGraphEdgeModel <: AbstractGraphEdgeModel

    # data -
    id::Int64
    source::Int64
    target::Int64
    weight::Union{Nothing, Any}; # this is a little fancy??

    # constructor -
    MyGraphEdgeModel() = new();
end

"""
    mutable struct MyConstrainedGraphEdgeModel

Mutable model for a graph edge with capacity constraints.

### Fields
- `id::Int64` - Unique identifier for the edge.
- `source::Int64` - Identifier for the source node.
- `target::Int64` - Identifier for the target node.
- `lower::Union{Nothing, Number}` - Lower capacity constraint for the edge.
- `upper::Union{Nothing, Number}` - Upper capacity constraint for the edge.

"""
mutable struct MyConstrainedGraphEdgeModel

    # data -
    id::Int64
    source::Int64
    target::Int64
    weight::Union{Nothing, Number}; # this is a little fancy??
    lower::Union{Nothing, Number}
    upper::Union{Nothing, Number}

    # constructor -
    MyConstrainedGraphEdgeModel() = new();
end


"""
    mutable struct MySimpleDirectedGraphModel

A minimal mutable directed graph container that keeps node and edge registries
and a children adjacency map for fast traversal of outgoing neighbors.

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}` - Optional mapping from node id to MyGraphNodeModel. Use nothing when uninitialized.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Int64}}` - Optional mapping from (source, target) tuple to edge id. Use nothing when uninitialized.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}` - Optional adjacency map from a node id to the set of its child (outgoing) node ids.
"""
mutable struct MySimpleDirectedGraphModel <: AbstractGraphModel

   # data -
   nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}
   edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}
   children::Union{Nothing, Dict{Int64, Set{Int64}}}
   edgesinverse::Dict{Int, Tuple{Int, Int}} # map between edge id and source and target

   # constructor -
   MySimpleDirectedGraphModel() = new();
end

"""
    mutable struct MySimpleUndirectedGraphModel

A minimal mutable undirected graph container that keeps node and edge registries and a children adjacency map for fast traversal of outgoing neighbors.

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}` - Optional mapping from node id to MyGraphNodeModel. Use nothing when uninitialized.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Int64}}` - Optional mapping from (source, target) tuple to edge id. Use nothing when uninitialized.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}` - Optional adjacency map from a node id to the set of its child (outgoing) node ids.
"""
mutable struct MySimpleUndirectedGraphModel <: AbstractGraphModel

    # data -
    nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}
    edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}
    children::Union{Nothing, Dict{Int64, Set{Int64}}}
    edgesinverse::Dict{Int, Tuple{Int, Int}} # map between edge id and source and target

    # constructor -
    MySimpleUndirectedGraphModel() = new();
end

"""
    mutable struct MyDirectedBipartiteGraphModel <: AbstractGraphModel

This type models a directed bipartite graph with source and sink nodes, along with maximum capacity constraints on the edges.
This type is constructed using a build method.

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}` - Optional mapping from node id to MyGraphNodeModel. Use nothing when uninitialized.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Int64}}` - Optional mapping from (source, target) tuple to edge id. Use nothing when uninitialized.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}` - Optional adjacency map from a node id to the set of its child (outgoing) node ids.
- `edgesinverse::Dict{Int, Tuple{Int, Int}}` - Map between edge id and (source, target) tuple.
- `left::Set{Int64}` - Set of left (source) node ids.
- `right::Set{Int64}` - Set of right (sink) node ids.
- `source::Int64` - Source node id.
- `sink::Int64` - Sink node id.
- `capacity::Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}` - Capacity constraints on the edges.
"""
mutable struct MyDirectedBipartiteGraphModel <: AbstractGraphModel

    # data -
    nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}
    edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}
    children::Union{Nothing, Dict{Int64, Set{Int64}}}
    edgesinverse::Dict{Int, Tuple{Int, Int}} # map between edge id and source and target
    left::Set{Int64}
    right::Set{Int64}
    source::Int64
    sink::Int64
    capacity::Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}

    # constructor -
    MyDirectedBipartiteGraphModel() = new();
end

# Let's create some tag types
struct DijkstraAlgorithm <: AbstractGraphSearchAlgorithm end
struct BellmanFordAlgorithm <: AbstractGraphSearchAlgorithm end
struct FordFulkersonAlgorithm <: AbstractGraphFlowAlgorithm end
struct EdmondsKarpAlgorithm <: AbstractGraphFlowAlgorithm end
struct DepthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm end
struct BreadthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm end
struct JacobiMethod <: AbstractLinearSolverAlgorithm end
struct GaussSeidelMethod <: AbstractLinearSolverAlgorithm end
struct SuccessiveOverRelaxationMethod <: AbstractLinearSolverAlgorithm end

# -- GRAPHS ABOVE HERE ---------------------------------------------------------------------------- #

# -- MDP AND RL BELOW HERE ------------------------------------------------------------------------ #


"""
    mutable struct MyMDPProblemModel <: AbstractProcessModel

A mutable struct that defines a Markov Decision Process (MDP) model.
The MDP model is defined by the tuple `(𝒮, 𝒜, T, R, γ)`.
The state space `𝒮` is an array of integers, the action space `𝒜` is an array of integers,
the transition matrix `T` is a function or a 3D array, the reward matrix `R` is a function or a 2D array,
and the discount factor `γ` is a float.

### Fields
- `𝒮::Array{Int64,1}`: state space
- `𝒜::Array{Int64,1}`: action space
- `T::Union{Function, Array{Float64,3}}`: transition matrix of function
- `R::Union{Function, Array{Float64,2}}`: reward matrix or function
- `γ::Float64`: discount factor
"""
mutable struct MyMDPProblemModel <: AbstractProcessModel

    # data -
    𝒮::Array{Int64,1}
    𝒜::Array{Int64,1}
    T::Union{Function, Array{Float64,3}}
    R::Union{Function, Array{Float64,2}}
    γ::Float64

    # constructor -
    MyMDPProblemModel() = new()
end

"""
    mutable struct MyRectangularGridWorldModel <: AbstractWorldModel

A mutable struct that defines a rectangular grid world model.

### Fields
- `number_of_rows::Int`: number of rows in the grid
- `number_of_cols::Int`: number of columns in the grid
- `coordinates::Dict{Int,Tuple{Int,Int}}`: dictionary of state to coordinate mapping
- `states::Dict{Tuple{Int,Int},Int}`: dictionary of coordinate to state mapping
- `moves::Dict{Int,Tuple{Int,Int}}`: dictionary of state to move mapping
- `rewards::Dict{Int,Float64}`: dictionary of state to reward mapping
"""
mutable struct MyRectangularGridWorldModel <: AbstractWorldModel

    # data -
    number_of_rows::Int
    number_of_cols::Int
    coordinates::Dict{Int,Tuple{Int,Int}}
    states::Dict{Tuple{Int,Int},Int}
    moves::Dict{Int,Tuple{Int,Int}}
    rewards::Dict{Int,Float64}

    # constructor -
    MyRectangularGridWorldModel() = new();
end

"""
    struct MyValueIterationModel <: AbstractProcessModel

A struct that defines a value iteration model.
The value iteration model is defined by the maximum number of iterations `k_max`.
"""
struct MyValueIterationModel

    # data -
    k_max::Int64; # max number of iterations
end

"""
    struct MyValueFunctionPolicy

A struct that defines a value function policy.

### Fields
- `problem::MyMDPProblemModel`: MDP problem model
- `U::Array{Float64,1}`: value function vector. This holds the Utility of each state.
"""
struct MyValueFunctionPolicy
    problem::MyMDPProblemModel
    U::Array{Float64,1}
end

"""
    mutable struct MyExploreFirstAlgorithmModel <: AbstractBanditAlgorithmModel

A mutable struct that represents an explore-first bandit algorithm model.
"""
mutable struct MyExploreFirstAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # constructor -
    MyExploreFirstAlgorithmModel() = new();
end

"""
    mutable struct MyUCB1AlgorithmModel <: AbstractBanditAlgorithmModel

A mutable struct that represents a UCB1 bandit algorithm model.
"""
mutable struct MyUCB1AlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # constructor -
    MyUCB1AlgorithmModel() = new();
end

"""
    mutable struct MyEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

A mutable struct that represents an epsilon-greedy bandit algorithm model.
"""
mutable struct MyEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # constructor -
    MyEpsilonGreedyAlgorithmModel() = new();
end

"""
    mutable struct MyBinaryVectorArmsEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

A mutable struct that represents a binary vector arms epsilon-greedy bandit algorithm model.

### Fields
- `K::Int64`: number of arms
"""
mutable struct MyBinaryVectorArmsEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # constructor -
    MyBinaryVectorArmsEpsilonGreedyAlgorithmModel() = new();
end


"""
    mutable struct MyConsumerChoiceBanditContextModel <: AbstractBanditProblemContextModel

This struct defines a consumer choice bandit context model for bandit problems with context.

### Fields
- `data::Dict{String, Any}`: A dictionary containing the context data for each item.
- `items::Array{String,1}`: An array of item names (things we are purchasing).
- `bounds::Array{Float64,2}`: A 2D array defining the bounds on the items that we can purchase.
- `B::Float64`: The budget available to spend on the collection of items.
- `nₒ::Array{Float64,1}`: An initial guess for the solution (quantities of each item).
- `μₒ::Array{Float64,1}`: An initial estimate for the utility of each arm (collection of items).
"""
mutable struct MyConsumerChoiceBanditContextModel <: AbstractBanditProblemContextModel

    # data -
    data::Dict{String, Any} # data dictionary for each item, or more generally the context
    items::Array{String,1} # items for each asset
    bounds::Array{Float64,2} # bounds on the assets that we can purchase
    B::Float64 # budget that we have to spend on the collection of assets
    nₒ::Array{Float64,1} # initial guess for the solution
    μₒ::Array{Float64,1} # initial for the utility of each arm
    γ::Array{Float64,1} # parameters for the utility function (preferences)

    # constructor -
    MyConsumerChoiceBanditContextModel() = new();
end
# -- MDP AND RL ABOVE HERE ------------------------------------------------------------------------ #

# -- WMA and MWA BELOW HERE ----------------------------------------------------------------------- #

"""
    MyBinaryWeightedMajorityAlgorithmModel

A mutable type for the Binary Weighted Majority Algorithm model.
This model is used to simulate the Binary Weighted Majority Algorithm. The model has the following fields:

- `ϵ::Float64`: learning rate
- `n::Int64`: number of experts
- `T::Int64`: number of rounds
- `weights::Array{Float64,2}`: weights of the experts
- `expert::Function`: expert function
- `adversary::Function`: adversary function
"""
mutable struct MyBinaryWeightedMajorityAlgorithmModel <: AbstractOnlineLearningModel

    # parameters
    ϵ::Float64 # learning rate
    n::Int64 # number of experts
    T::Int64 # number of rounds
    weights::Array{Float64,2} # weights of the experts
    expert::Function # expert function
    adversary::Function # adversary function

    # default constructor -
    MyBinaryWeightedMajorityAlgorithmModel() = new();
end

"""
    mutable struct MyTwoPersonZeroSumGameModel <: AbstractOnlineLearningModel

A mutable type for the Two-Person Zero-Sum Game model.
This model is used to simulate the Two-Person Zero-Sum Game using the Multiplicative Weights Algorithm.
The model has the following fields:

- `ϵ::Float64`: learning rate
- `n::Int64`: number of experts (actions)
- `T::Int64`: number of rounds
- `weights::Array{Float64,2}`: weights of the experts
- `payoffmatrix::Array{Float64,2}`: payoff matrix
"""
mutable struct MyTwoPersonZeroSumGameModel <: AbstractOnlineLearningModel

    # parameters
    ϵ::Float64 # learning rate
    n::Int64 # number of experts (actions)
    T::Int64 # number of rounds
    weights::Array{Float64,2} # weights of the experts
    payoffmatrix::Array{Float64,2} # payoff matrix

    # default constructor -
    MyTwoPersonZeroSumGameModel() = new();
end

"""
    mutable struct MyQLearningAgentModel <: AbstractOnlineLearningModel

A mutable type for the Q-Learning Agent model.

### Fields
- `states::Array{Int,1}`: array of states
- `actions::Array{Int,1}`: array of actions
- `γ::Float64`: discount factor
- `α::Float64`: learning rate
- `Q::Array{Float64,2}`: Q-value table
"""
mutable struct MyQLearningAgentModel <: AbstractOnlineLearningModel

    # data -
    states::Array{Int,1}
    actions::Array{Int,1}
    γ::Float64
    α::Float64
    Q::Array{Float64,2}

    # constructor
    MyQLearningAgentModel() = new();
end
# -- WMA and MWA ABOVE HERE ----------------------------------------------------------------------- #

# -- HOPFIELD NETWORKS BELOW HERE ----------------------------------------------------------------- #


"""
    MyClassicalHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

A mutable struct representing a classical Hopfield network model.

### Fields
- `W::Array{<:Number, 2}`: weight matrix.
- `b::Array{<:Number, 1}`: bias vector.
- `memories::Array{<:Number, 2}`: stored memories (one memory per column).
- `energy::Dict{Int64, Float32}`: energy of the states.
"""
mutable struct MyClassicalHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

    # data -
    W::Array{<:Number, 2} # weight matrix
    b::Array{<:Number, 1} # bias vector
    memories::Array{<:Number, 2} # stored memories
    energy::Dict{Int64, Float32} # energy of the states

    # empty constructor -
    MyClassicalHopfieldNetworkModel() = new();
end

"""
    MyModernHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

A mutable struct representing a modern Hopfield network model.

### Fields
- `X::Array{<:Number, 2}`: data matrix with memories stored in the columns.
- `X̂::Array{<:Number, 2}`: normalized data matrix.
- `β::Number`: beta parameter (inverse temperature) controlling sharpness of softmax updates.
"""
mutable struct MyModernHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

    # data -
    X::Array{<:Number, 2} # data matrix
    X̂::Array{<:Number, 2} # normalized data matrix
    β::Number; # beta parameter

    # empty constructor -
    MyModernHopfieldNetworkModel() = new();
end
# -- HOPFIELD NETWORKS ABOVE HERE ----------------------------------------------------------------- #

# -- UTILITY FUNCTIONS BELOW HERE ------------------------------------------------------------------ #
"""
    abstract type AbstractUtilityFunctionType end

Abstract supertype for consumer utility function models, e.g. [`VLLinearUtilityFunction`](@ref).
"""
abstract type AbstractUtilityFunctionType end

"""
    mutable struct VLLinearUtilityFunction <: AbstractUtilityFunctionType

A linear utility function model: ``U(x) = \\sum_i \\alpha_i x_i``.

### Fields
- `α::Union{Nothing, Array{Float64,1}}`: the vector of linear utility weights (preferences), one per good.
"""
mutable struct VLLinearUtilityFunction <: AbstractUtilityFunctionType

    # data -
    α::Union{Nothing, Array{Float64,1}} # parameters -

    # constructor -
    VLLinearUtilityFunction() = new()
end
# -- UTILITY FUNCTIONS ABOVE HERE ------------------------------------------------------------------ #
