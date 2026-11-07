# =============================================================================
# CHEME 5800 | Types.jl: the data types of the course package
# =============================================================================
# This file defines every data type in the course package. A type is a named
# container that keeps related values together. For example, one
# MyMDPProblemModel object holds the states, the actions, the transition
# probabilities, the rewards, and the discount factor of a Markov decision
# process. Most notebooks create these objects with the build(...) function in
# Factory.jl. They then pass the object to a function such as solve(...),
# learn(...), or findshortestpath(...).
#
# How to read the definitions in this file
# -----------------------------------------------------------------------------
#   mutable struct Name ... end   a container whose fields we can change after we create it
#   struct Name ... end           a container whose fields are fixed once we create it
#   field::Type                   the field holds a value of that type
#   Array{Float64,1}              a vector of floating-point numbers (same as Vector{Float64})
#   Array{Float64,2}              a matrix of floating-point numbers
#   Array{Float64,3}              a three-index array, e.g., T[s, s′, a]
#   Array{<:Number,2}             a matrix whose entries are some kind of number (Float32, Int32, ...)
#   Int                           the same as Int64 on a 64-bit computer
#   Dict{K,V}                     a dictionary that maps each key of type K to a value of type V
#   Set{Int64}                    a collection of integers with no repeats and no order
#   Tuple{Int,Int}                a pair of integers, e.g., (2, 3)
#   Union{Nothing, T}             the field holds either the value nothing or a value of type T
#   Function                      the field holds a function that we can call
#   Name() = new()                an empty constructor: Name() creates the object with every field
#                                 left unset, and build(Name, (...)) then fills in the fields
#
# Abstract types and the <: symbol
# -----------------------------------------------------------------------------
# An abstract type is a family name. It has no fields, and we never create an
# object of an abstract type. We write Child <: Parent to say that the type
# Child belongs to the family Parent, e.g., DijkstraAlgorithm <: AbstractGraphSearchAlgorithm.
#
# Families let one function name work for several related types. When we call
# a function, Julia looks at the types of the arguments and runs the method
# written for those types; this is called multiple dispatch. For example,
# findshortestpath(...) accepts any member of AbstractGraphSearchAlgorithm.
# It runs Dijkstra's method when we pass DijkstraAlgorithm(), and the
# Bellman-Ford method when we pass BellmanFordAlgorithm().
#
# Types in this file, by course topic (the family of each type is in brackets)
# -----------------------------------------------------------------------------
# Text (no course notebook uses these):
#   MySarcasmRecordModel                one headline of the sarcasm headline dataset [AbstractTextRecordModel]
#   MySarcasmRecordCorpusModel          a collection of sarcasm records and a token dictionary [AbstractTextDocumentCorpusModel]
# Linear programming (week 5, L5c):
#   MyLinearProgrammingProblemModel     the data of a linear program: A, b, c, and the bounds [AbstractLinearProgrammingProblemType]
# Classification (week 9):
#   MyPerceptronClassificationModel     the perceptron parameters and mistake threshold (L9a, L9b, L9d) [AbstractClassificationAlgorithm]
#   MyLogisticRegressionClassificationModel  logistic regression settings (no course notebook uses it) [AbstractClassificationAlgorithm]
# Graphs (weeks 4 and 5):
#   MyGraphNodeModel                    one node of a graph [AbstractGraphNodeModel]
#   MyGraphEdgeModel                    one edge of a graph, read from an edge file [AbstractGraphEdgeModel]
#   MyConstrainedGraphEdgeModel         one edge with a cost and lower and upper flow bounds [no family]
#   MySimpleDirectedGraphModel          a directed graph: nodes, edge weights, and children (L4b, L4d) [AbstractGraphModel]
#   MySimpleUndirectedGraphModel        the same fields as the directed graph (no course notebook uses it) [AbstractGraphModel]
#   MyDirectedBipartiteGraphModel       a flow network: a source, a sink, and edge capacities (L5a, L5b) [AbstractGraphModel]
# Algorithm tags (no fields; each one selects a method):
#   DijkstraAlgorithm, BellmanFordAlgorithm              shortest paths with findshortestpath(...) (L4d)
#   FordFulkersonAlgorithm, EdmondsKarpAlgorithm         maximum flow with maximumflow(...) (L5a, L5b)
#   DepthFirstSearchAlgorithm, BreadthFirstSearchAlgorithm   graph traversal with walk(...)
#   JacobiMethod, GaussSeidelMethod, SuccessiveOverRelaxationMethod   iterative linear solvers with solve(...) (L6c, L6d)
# Markov decision processes (weeks 11 and 12):
#   MyMDPProblemModel                   states, actions, transitions T, rewards R, and discount factor γ [AbstractProcessModel]
#   MyRectangularGridWorldModel         a grid of squares: state numbers, moves, and rewards [AbstractWorldModel]
#   MyValueIterationModel               the number of value-iteration sweeps [no family]
#   MyValueFunctionPolicy               the result of value iteration: the problem and the value of each state [no family]
# Bandits (week 10):
#   MyExploreFirstAlgorithmModel        explore-first, K arms (L10d) [AbstractBanditAlgorithmModel]
#   MyUCB1AlgorithmModel                UCB1, K arms (L10c, L10d) [AbstractBanditAlgorithmModel]
#   MyEpsilonGreedyAlgorithmModel       epsilon-greedy, K arms (L10d) [AbstractBanditAlgorithmModel]
#   MyBinaryVectorArmsEpsilonGreedyAlgorithmModel  epsilon-greedy over yes/no choices of K goods (no course notebook uses it)
#   MyConsumerChoiceBanditContextModel  the shopping data for that bandit (no course notebook uses it) [AbstractBanditProblemContextModel]
# Online learning (weeks 10 and 12):
#   MyBinaryWeightedMajorityAlgorithmModel  the weighted majority algorithm (L10b) [AbstractOnlineLearningModel]
#   MyTwoPersonZeroSumGameModel         a two-player game played with multiplicative weights (no course notebook uses it)
#   MyQLearningAgentModel               a Q-learning agent: states, actions, α, γ, and the Q table (L12a, L12b)
# Hopfield networks (no course notebook uses these):
#   MyClassicalHopfieldNetworkModel     a classical Hopfield network [AbstractlHopfieldNetworkModel]
#   MyModernHopfieldNetworkModel        a modern Hopfield network [AbstractlHopfieldNetworkModel]
# Utility functions (no course notebook uses this):
#   VLLinearUtilityFunction             a linear utility function U(x) = α₁⋅x₁ + α₂⋅x₂ + ... [AbstractUtilityFunctionType]
#
# Three more types live in the file of the functions that use them: WeightedEdge in
# ShortestPathAlgorithms.jl (L4c), and MyStack and MyQueue in StacksQueues.jl (L3b).
# =============================================================================

# -- ABSTRACT TYPES (FAMILIES) BELOW HERE --------------------------------------------------------- #

"""
    abstract type AbstractTextRecordModel end

The family of types that hold one record (one entry) of a text dataset.

The only member is [`MySarcasmRecordModel`](@ref). The `build(...)` method for text records in
Factory.jl accepts any member of this family. No course notebook uses this family.
"""
abstract type AbstractTextRecordModel end

"""
    abstract type AbstractTextDocumentCorpusModel end

The family of types that hold a whole text collection (a corpus): many records and a shared
token dictionary.

The only member is [`MySarcasmRecordCorpusModel`](@ref). No course notebook uses this family.
"""
abstract type AbstractTextDocumentCorpusModel end

"""
    abstract type AbstractPriceTreeModel end

A family name for tree models of prices.

No type in this package belongs to this family, and no function in this package uses it.
"""
abstract type AbstractPriceTreeModel end

"""
    abstract type AbstractGraphModel end

The family of graph types: containers that hold the nodes and edges of a graph.

The members are [`MySimpleDirectedGraphModel`](@ref), [`MySimpleUndirectedGraphModel`](@ref), and
[`MyDirectedBipartiteGraphModel`](@ref). The graph functions `children(...)`, `weight(...)`,
`walk(...)`, `findshortestpath(...)`, and `maximumflow(...)` in Graphs.jl accept any member of
this family. So does `build(graphtype, edges)` in Factory.jl. Weeks 4 and 5 use these types.
"""
abstract type AbstractGraphModel end

"""
    abstract type AbstractGraphNodeModel end

The family of graph node types. The only member is [`MyGraphNodeModel`](@ref).
"""
abstract type AbstractGraphNodeModel end

"""
    abstract type AbstractGraphEdgeModel end

The family of graph edge types.

The only member is [`MyGraphEdgeModel`](@ref). The edge type for flow networks,
[`MyConstrainedGraphEdgeModel`](@ref), does not declare this family.
"""
abstract type AbstractGraphEdgeModel end

"""
    abstract type AbstractGraphSearchAlgorithm end

The family of shortest-path algorithm tags.

The members are [`DijkstraAlgorithm`](@ref) and [`BellmanFordAlgorithm`](@ref). We pass a member
as the `algorithm` keyword of [`findshortestpath`](@ref) to choose the method it runs (week 4, L4d).
"""
abstract type AbstractGraphSearchAlgorithm end

"""
    abstract type AbstractGraphFlowAlgorithm end

The family of maximum-flow algorithm tags.

The members are [`FordFulkersonAlgorithm`](@ref) and [`EdmondsKarpAlgorithm`](@ref). We pass a
member as the `algorithm` keyword of [`maximumflow`](@ref) to choose the method it runs
(week 5, L5a and L5b).
"""
abstract type AbstractGraphFlowAlgorithm end

"""
    abstract type AbstractGraphTraversalAlgorithm end

The family of graph traversal algorithm tags.

The members are [`DepthFirstSearchAlgorithm`](@ref) and [`BreadthFirstSearchAlgorithm`](@ref). We
pass a member as the `algorithm` keyword of [`walk`](@ref) to choose the order in which it
visits the nodes.
"""
abstract type AbstractGraphTraversalAlgorithm end

"""
    abstract type AbstractLinearSolverAlgorithm end

The family of iterative linear solver tags, for systems of equations `A⋅x = b`.

The members are [`JacobiMethod`](@ref), [`GaussSeidelMethod`](@ref), and
[`SuccessiveOverRelaxationMethod`](@ref). We pass a member as the `algorithm` keyword of
`solve(A, b, xₒ; algorithm = ...)` in Solvers.jl to choose the method it runs (week 6, L6c and L6d).
"""
abstract type AbstractLinearSolverAlgorithm end

"""
    abstract type AbstractClassificationAlgorithm end

The family of binary classifiers: models that sort each example into one of two classes,
labeled `-1` and `+1`.

The members are [`MyPerceptronClassificationModel`](@ref) and
[`MyLogisticRegressionClassificationModel`](@ref). The functions [`learn`](@ref) and
[`classify`](@ref) in Binary.jl accept any member of this family and run the method written for
that member (week 9).
"""
abstract type AbstractClassificationAlgorithm end

"""
    abstract type AbstractLinearProgrammingProblemType end

The family of linear programming problem types.

The only member is [`MyLinearProgrammingProblemModel`](@ref). The `build(...)` method for linear
programs in Factory.jl accepts any member of this family (week 5, L5c).
"""
abstract type AbstractLinearProgrammingProblemType end

"""
    abstract type AbstractProcessModel end

The family of decision process models. The only member is [`MyMDPProblemModel`](@ref)
(weeks 11 and 12).
"""
abstract type AbstractProcessModel end

"""
    abstract type AbstractWorldModel end

The family of world models: the environment that an agent moves through.

The only member is [`MyRectangularGridWorldModel`](@ref) (weeks 11 and 12).
"""
abstract type AbstractWorldModel end

"""
    abstract type AbstractBanditAlgorithmModel end

The family of multi-armed bandit algorithms (week 10).

A bandit problem has `K` arms (choices). Each pull of an arm returns a random reward, and the
algorithm must learn which arm pays best while it plays. The members are
[`MyExploreFirstAlgorithmModel`](@ref), [`MyEpsilonGreedyAlgorithmModel`](@ref),
[`MyUCB1AlgorithmModel`](@ref), and [`MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`](@ref).
The function `solve(model; T, world)` in Bandit.jl runs the first three members. The binary-vector
member also needs a context: `solve(model, context; T, world)`.
"""
abstract type AbstractBanditAlgorithmModel end

"""
    abstract type AbstractOnlineLearningModel end

The family of online learning models: models that learn one round at a time as data arrive.

The members are [`MyBinaryWeightedMajorityAlgorithmModel`](@ref) (week 10, L10b),
[`MyTwoPersonZeroSumGameModel`](@ref), and [`MyQLearningAgentModel`](@ref) (week 12).
"""
abstract type AbstractOnlineLearningModel end

"""
    abstract type AbstractBanditProblemContextModel end

The family of context models for bandit problems: extra data that the reward of an arm depends on.

The only member is [`MyConsumerChoiceBanditContextModel`](@ref). No course notebook uses this family.
"""
abstract type AbstractBanditProblemContextModel end

"""
    abstract type AbstractlHopfieldNetworkModel end

The family of Hopfield network models. The members are [`MyClassicalHopfieldNetworkModel`](@ref)
and [`MyModernHopfieldNetworkModel`](@ref).

The name has an extra `l` after `Abstract`; we must type it exactly as spelled. No course notebook
uses this family.
"""
abstract type AbstractlHopfieldNetworkModel end

# -- ABSTRACT TYPES (FAMILIES) ABOVE HERE --------------------------------------------------------- #

"""
    mutable struct MyLinearProgrammingProblemModel <: AbstractLinearProgrammingProblemType

The data of a linear program, used in the fruit-buying example of week 5 (L5c).

The function `solve(problem)` in Solvers.jl finds the vector `x` that maximizes `cᵀx` subject to
`A⋅x ≤ b` and `lb ≤ x ≤ ub`. The vector `x` holds the `n` decision variables, e.g., how much of
each fruit to buy. Each of the `m` rows of `A⋅x ≤ b` is one constraint, e.g., the budget. The
keyword `constraints = :geq` or `constraints = :eq` of `solve` changes `≤` to `≥` or to `=`.

### Fields
- `A::Array{Float64,2}`: the constraint matrix, `m × n`: one row per constraint and one column per
  decision variable.
- `b::Array{Float64,1}`: the right-hand side vector, length `m`: one entry per constraint.
- `c::Union{Array{Float64,2}, Array{Float64,1}}`: the objective coefficients, one per decision
  variable. `Union{...}` means the field accepts either type: a vector of length `n` or an
  `n × 1` matrix.
- `lb::Array{Float64,1}`: the lower bound of each decision variable, length `n`.
- `ub::Array{Float64,1}`: the upper bound of each decision variable, length `n`.

### How to create one
Call `build(MyLinearProgrammingProblemModel, (A = ..., b = ..., c = ..., lb = ..., ub = ...))`,
defined in Factory.jl. The `NamedTuple` (the list of `name = value` pairs in parentheses) must
have all five keys. Then pass the model to `solve(problem)`.

### Example
```julia
problem = build(MyLinearProgrammingProblemModel, (
    A = [2.0 3.0],    # one constraint and two decision variables: a 1 × 2 matrix
    b = [12.0],       # the right-hand side of the one constraint
    c = [1.0, 1.5],   # the objective coefficients, one per decision variable
    lb = [0.0, 0.0],  # the lower bound of each decision variable
    ub = [4.0, 4.0]   # the upper bound of each decision variable
));
```
"""
mutable struct MyLinearProgrammingProblemModel <: AbstractLinearProgrammingProblemType

    # data -
    A::Array{Float64,2}     # constraint matrix, m × n: one row per constraint, one column per variable
    b::Array{Float64,1}     # right-hand side vector, length m
    c::Union{Array{Float64,2}, Array{Float64,1}}     # objective coefficients, length n (a vector or an n × 1 matrix)
    lb::Array{Float64,1}    # lower bound of each variable, length n
    ub::Array{Float64,1}    # upper bound of each variable, length n

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyLinearProgrammingProblemModel() = new();
end



"""
    mutable struct MyPerceptronClassificationModel <: AbstractClassificationAlgorithm

The parameters and the stopping rule of a perceptron, the linear classifier of week 9
(L9a, L9b, and L9d).

A perceptron predicts the label `ŷ = sign(xᵀβ)` of a feature vector `x`, where each label is
`-1` or `+1`. The function `learn(X, y, model)` in Binary.jl passes through the training data
again and again. Each time it finds a misclassified example (`y⋅xᵀβ ≤ 0`), it updates the
parameters by `β ← β + y⋅x`. It stops after a pass with at most `mistakes` misclassified
examples, or after `maxiter` passes. Then `classify(X, model)` returns the labels `sign.(X*β)`.

### Fields
- `β::Vector{Float64}`: the parameters, one per column of the feature matrix `X`. When `X` has a
  column of ones, the matching entry of `β` is the bias. `learn` replaces this field with the
  learned parameters.
- `mistakes::Int64`: the mistake threshold `M`. `learn` stops after a pass through the training
  data with at most `M` misclassified examples. `M = 0` asks for a pass with no mistakes.

### How to create one
Call `build(MyPerceptronClassificationModel, (parameters = ..., mistakes = ...))`, defined in
Factory.jl. The key for `β` is `parameters`.

### Example
```julia
model = build(MyPerceptronClassificationModel, (
    parameters = zeros(3), # two feature weights and the bias, all starting at zero
    mistakes = 0           # stop after a pass through the data with no mistakes
));
```
"""
mutable struct MyPerceptronClassificationModel <: AbstractClassificationAlgorithm

    # data -
    β::Vector{Float64}; # parameters, one per column of the feature matrix (the bias included)
    mistakes::Int64; # mistake threshold: learn(...) stops after a pass with at most this many mistakes

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyPerceptronClassificationModel() = new();
end

"""
    mutable struct MyLogisticRegressionClassificationModel <: AbstractClassificationAlgorithm

The settings of a logistic regression classifier that `learn(X, y, model)` in Binary.jl trains
by gradient descent. No course notebook uses this type.

Each label is `-1` or `+1`. In each pass, `learn` adds up the gradient of the loss `L` over all
training examples. It estimates each partial derivative by a forward difference with step `h`:
`(L(x, y, T, λ, β + h⋅eⱼ) − L(x, y, T, λ, β))/h`, where `eⱼ` is the `j`-th unit vector. It then
updates `β ← β − α⋅∇L`. It stops when the norm of the summed gradient is at most `ϵ`, or after
`maxiter` passes. Then `classify(X, model)` returns an `N × 2` matrix: column 1 holds the
probability `1/(1 + exp(−2⋅xᵀβ))` that the label is `+1`, and column 2 the probability that it is `-1`.

### Fields
- `β::Vector{Float64}`: the parameters, one per column of the feature matrix. `learn` replaces this
  field with the learned parameters.
- `α::Float64`: the learning rate: the step size of each gradient-descent update.
- `ϵ::Float64`: the stopping tolerance on the norm of the gradient.
- `L::Function`: the loss of one example, called as `L(x, y, T, λ, β)`, where `x` is one feature
  vector and `y` is its label.
- `T::Float64`: a parameter that `learn` passes to `L`; the original comment calls it the inverse
  temperature of the logistic function. `classify` does not use it.
- `λ::Float64`: the regularization parameter, which `learn` passes to `L`.
- `h::Float64`: the finite-difference step size used to estimate each partial derivative.

### How to create one
Call `build(MyLogisticRegressionClassificationModel, (parameters = ..., learning_rate = ...,
loss_function = ..., ϵ = ..., T = ..., λ = ..., h = ...))`, defined in Factory.jl. All seven keys
are required. Three keys differ from the field names: `parameters` fills `β`, `learning_rate`
fills `α`, and `loss_function` fills `L`.
"""
mutable struct MyLogisticRegressionClassificationModel <: AbstractClassificationAlgorithm

    # data -
    β::Vector{Float64}; # parameters, one per column of the feature matrix
    α::Float64; # learning rate: the step size of each gradient-descent update
    ϵ::Float64; # stopping tolerance on the norm of the gradient
    L::Function; # loss of one example, called as L(x, y, T, λ, β)
    T::Float64; # parameter passed to L (inverse temperature of the logistic function)
    λ::Float64; # regularization parameter, passed to L
    h::Float64; # finite-difference step size for the gradient estimate

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyLogisticRegressionClassificationModel() = new();
end

"""
    mutable struct MySarcasmRecordModel <: AbstractTextRecordModel

One record of the sarcasm headline dataset: a news headline, its article entry, and whether the
headline is sarcastic. No course notebook uses this type.

### Fields
- `issarcastic::Bool`: `true` when the headline is sarcastic, `false` otherwise.
- `headline::String`: the headline text. `build` removes punctuation and every character with a
  code above 255, and leaves one space between words.
- `article::String`: the article entry stored with the headline. `build` copies it unchanged.

### How to create one
Call `build(MySarcasmRecordModel, (headline = ..., article = ..., issarcastic = ...))`, defined
in Factory.jl.

### Example
```julia
record = build(MySarcasmRecordModel, (headline = "Area man wins, again!",
    article = "https://example.com/story", issarcastic = true));
record.headline # "Area man wins again": the punctuation is gone
```
"""
mutable struct MySarcasmRecordModel <: AbstractTextRecordModel

    # data -
    issarcastic::Bool # true when the headline is sarcastic
    headline::String # the headline, with the punctuation removed
    article::String # the article entry, copied unchanged

    # empty constructor: new() makes a record with no fields set; build(...) in Factory.jl fills them in -
    MySarcasmRecordModel() = new(); # empty
end


"""
    mutable struct MySarcasmRecordCorpusModel <: AbstractTextDocumentCorpusModel

A collection (corpus) of sarcasm headline records, with a token dictionary for the whole
collection. No course notebook uses this type.

A token is one unit of text, usually a word. The token dictionary gives each token an integer
code, so that a headline can be stored as a vector of integers.

### Fields
- `records::Dict{Int, MySarcasmRecordModel}`: the records, keyed by an integer record number.
- `tokens::Dict{String, Int64}`: the token dictionary: each token maps to its integer code. The
  function `tokenize(...)` in Compute.jl uses a dictionary of this form, and it expects the
  control tokens `<bos>` (beginning of sequence), `<eos>` (end of sequence), `<unk>` (unknown
  word), and `<pad>` (padding).
- `inverse::Dict{Int64, String}`: the reverse lookup: each integer code maps back to its token.

### How to create one
There is no `build(...)` method for this type. Create an empty corpus with
`MySarcasmRecordCorpusModel()`, then set each field.

### Example
```julia
corpus = MySarcasmRecordCorpusModel();
corpus.records = Dict{Int, MySarcasmRecordModel}();
```
"""
mutable struct MySarcasmRecordCorpusModel <: AbstractTextDocumentCorpusModel

    # data -
    records::Dict{Int, MySarcasmRecordModel} # record number => record
    tokens::Dict{String, Int64} # token => integer code
    inverse::Dict{Int64, String} # integer code => token

    # empty constructor: new() makes a corpus with no fields set; we set the fields ourselves -
    MySarcasmRecordCorpusModel() = new(); # empty
end

# -- GRAPHS BELOW HERE ---------------------------------------------------------------------------- #
"""
    mutable struct MyGraphNodeModel <: AbstractGraphNodeModel

One node (vertex) of a graph, used by the graph types of weeks 4 and 5.

A graph stores its nodes in its `nodes` field, a dictionary from node number to node. Functions
such as `findshortestpath(graph, startnode)` and `maximumflow(graph, source, sink)` take a node
object to say where to start, e.g., `graph.nodes[1]`.

### Fields
- `id::Int64`: the node number. `build(graphtype, edges)` numbers the nodes `1, 2, …, n` in
  increasing order of the node ids in the edge file.
- `data::Union{Nothing, Any}`: optional data attached to the node. `build` sets it to `nothing`.
  `Union{Nothing, Any}` accepts any value at all, because every value, `nothing` included, is
  an `Any`.

### How to create one
`build(graphtype, edges)` creates the nodes of a graph for us. To create one by hand, call
`MyGraphNodeModel(id, data)`, e.g., `MyGraphNodeModel(1, nothing)`.
"""
mutable struct MyGraphNodeModel <: AbstractGraphNodeModel

   # data -
   id::Int64 # the node number
   data::Union{Nothing, Any}; # optional data attached to the node; build(...) stores nothing here

   # constructor: MyGraphNodeModel(id, data) stores the two values in that order with new(id, data) -
   MyGraphNodeModel(id::Int64, data::Union{Nothing, Any}) = new(id, data);
end

"""
    mutable struct MyGraphEdgeModel <: AbstractGraphEdgeModel

One edge of a graph, as read from an edge file (week 4, L4b and L4d).

The function `MyGraphEdgeModels(path, parser)` in Files.jl reads an edge file and returns a
`Dict{Int64, MyGraphEdgeModel}`, one entry per data line. Then
`build(MySimpleDirectedGraphModel, edges)` turns that dictionary into a graph.

### Fields
- `id::Int64`: the edge number. `MyGraphEdgeModels` numbers the edges `0, 1, 2, …` in file order.
- `source::Int64`: the id of the node where the edge starts.
- `target::Int64`: the id of the node where the edge ends.
- `weight::Union{Nothing, Any}`: the value attached to the edge, usually a number such as a cost
  or a distance. To build a graph from the edge, the weight must be a number, because the graph
  stores it in a dictionary of numbers.

### How to create one
Call `build(MyGraphEdgeModel, (id = ..., source = ..., target = ..., weight = ...))`, defined in
Factory.jl. All four keys are required.

### Example
```julia
edge = build(MyGraphEdgeModel, (id = 1, source = 1, target = 2, weight = 5.0));
```
"""
mutable struct MyGraphEdgeModel <: AbstractGraphEdgeModel

    # data -
    id::Int64 # the edge number
    source::Int64 # the node where the edge starts
    target::Int64 # the node where the edge ends
    weight::Union{Nothing, Any}; # the value attached to the edge, usually a number

    # empty constructor: new() makes an edge with no fields set; build(...) in Factory.jl fills them in -
    MyGraphEdgeModel() = new();
end

"""
    mutable struct MyConstrainedGraphEdgeModel

One edge of a flow network: an edge with a cost and with lower and upper bounds on the flow it
carries (week 5, L5a and L5b).

The function `MyConstrainedGraphEdgeModels(path, parser)` in Files.jl reads a file of these
edges and returns a `Dict{Int64, MyConstrainedGraphEdgeModel}`. Then
`build(MyDirectedBipartiteGraphModel, (s = ..., t = ..., edges = ...))` turns that dictionary
into a flow network. This type declares no family, unlike [`MyGraphEdgeModel`](@ref).

### Fields
- `id::Int64`: the edge number. `MyConstrainedGraphEdgeModels` numbers the edges `0, 1, 2, …` in
  file order.
- `source::Int64`: the id of the node where the edge starts.
- `target::Int64`: the id of the node where the edge ends.
- `weight::Union{Nothing, Number}`: the cost or weight of the edge, or `nothing`.
- `lower::Union{Nothing, Number}`: the lower bound on the flow through the edge.
  `maximumflow(...)` ignores it and uses zero.
- `upper::Union{Nothing, Number}`: the upper bound on the flow through the edge: its capacity.

### How to create one
Call `build(MyConstrainedGraphEdgeModel, (id = ..., source = ..., target = ..., weight = ...,
lower = ..., upper = ...))`, defined in Factory.jl. All six keys are required.

### Example
```julia
edge = build(MyConstrainedGraphEdgeModel, (id = 1, source = 1, target = 2,
    weight = 0.0, lower = 0.0, upper = 10.0));
```
"""
mutable struct MyConstrainedGraphEdgeModel

    # data -
    id::Int64 # the edge number
    source::Int64 # the node where the edge starts
    target::Int64 # the node where the edge ends
    weight::Union{Nothing, Number}; # the cost or weight of the edge, or nothing
    lower::Union{Nothing, Number} # lower bound on the flow
    upper::Union{Nothing, Number} # upper bound on the flow: the capacity

    # empty constructor: new() makes an edge with no fields set; build(...) in Factory.jl fills them in -
    MyConstrainedGraphEdgeModel() = new();
end


"""
    mutable struct MySimpleDirectedGraphModel <: AbstractGraphModel

A directed graph: a set of nodes joined by one-way edges. Week 4 builds one from an edge file
and searches it (L4b and L4d).

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}`: node number → node. `build` numbers the
  nodes `1, 2, …, n`.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}`: edge `(source, target)` → the weight of
  that edge. `weight(graph, source, target)` reads this dictionary.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}`: node number → the set of its children, the
  nodes that one outgoing edge reaches. `children(graph, node)` reads this dictionary.
- `edgesinverse::Dict{Int, Tuple{Int, Int}}`: edge number → `(source, target)`. `build` numbers
  the edges `1, 2, …` in order of the source node, then the target node.

`Union{Nothing, ...}` means a field may hold `nothing`; `build` always fills the fields.

### How to create one
Read the edges with `MyGraphEdgeModels(path, parser)` from Files.jl, then call
`build(MySimpleDirectedGraphModel, edges)`, defined in Factory.jl. When the node ids in the edge
file are `1, 2, …, n`, `build` keeps those numbers.

### Example
```julia
edges = Dict{Int64, MyGraphEdgeModel}();
edges[1] = build(MyGraphEdgeModel, (id = 1, source = 1, target = 2, weight = 5.0));
edges[2] = build(MyGraphEdgeModel, (id = 2, source = 2, target = 3, weight = 1.0));
graph = build(MySimpleDirectedGraphModel, edges);
children(graph, graph.nodes[1]) # Set([2]): node 1 has one child, node 2
```
"""
mutable struct MySimpleDirectedGraphModel <: AbstractGraphModel

   # data -
   nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}} # node number => node
   edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}} # (source, target) => edge weight
   children::Union{Nothing, Dict{Int64, Set{Int64}}} # node number => the set of its children
   edgesinverse::Dict{Int, Tuple{Int, Int}} # edge number => (source, target)

   # empty constructor: new() makes a graph with no fields set; build(...) in Factory.jl fills them in -
   MySimpleDirectedGraphModel() = new();
end

"""
    mutable struct MySimpleUndirectedGraphModel <: AbstractGraphModel

A graph type with the same fields as [`MySimpleDirectedGraphModel`](@ref), meant for graphs whose
edges run both ways. No course notebook uses this type.

`build(MySimpleUndirectedGraphModel, edges)` fills it exactly as it fills the directed graph. It
stores each edge only in the direction listed in the edge file, and it does not add the reverse
edge. To make an edge two-way, list it in both directions.

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}`: node number → node.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}`: edge `(source, target)` → the weight of
  that edge.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}`: node number → the set of nodes that one
  listed edge from it reaches.
- `edgesinverse::Dict{Int, Tuple{Int, Int}}`: edge number → `(source, target)`.

### How to create one
Call `build(MySimpleUndirectedGraphModel, edges)`, defined in Factory.jl, where `edges` is the
`Dict{Int64, MyGraphEdgeModel}` returned by `MyGraphEdgeModels(path, parser)`.
"""
mutable struct MySimpleUndirectedGraphModel <: AbstractGraphModel

    # data -
    nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}} # node number => node
    edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}} # (source, target) => edge weight
    children::Union{Nothing, Dict{Int64, Set{Int64}}} # node number => the set of its children
    edgesinverse::Dict{Int, Tuple{Int, Int}} # edge number => (source, target)

    # empty constructor: new() makes a graph with no fields set; build(...) in Factory.jl fills them in -
    MySimpleUndirectedGraphModel() = new();
end

"""
    mutable struct MyDirectedBipartiteGraphModel <: AbstractGraphModel

A flow network: a directed graph with a source node, a sink node, and a capacity on each edge
(week 5). `build_flow_graph(...)` in FlowValidation.jl builds one for L5a, and the L5b lab builds
one for a worker–task assignment network. Then `maximumflow(graph, source, sink)` computes the
largest flow that the network can carry from the source to the sink.

The name says bipartite, but `build` accepts any directed edge list. (In a bipartite graph, the
nodes split into two groups, such as workers and tasks, and every edge joins the two groups.)

### Fields
- `nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}}`: node number → node. `build` numbers the
  nodes `1, 2, …, n`.
- `edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}}`: edge `(source, target)` → the cost or
  weight of that edge.
- `children::Union{Nothing, Dict{Int64, Set{Int64}}}`: node number → the set of its children, the
  nodes that one outgoing edge reaches.
- `edgesinverse::Dict{Int, Tuple{Int, Int}}`: edge number → `(source, target)`.
- `left::Set{Int64}`: one node group of a bipartite graph. `build` does not set this field, so
  reading it gives an error.
- `right::Set{Int64}`: the other node group. `build` does not set this field either.
- `source::Int64`: the id of the source node, where the flow starts (the `s` key of `build`).
- `sink::Int64`: the id of the sink node, where the flow ends (the `t` key of `build`).
- `capacity::Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}`: edge `(source, target)` →
  `(lower, upper)` bounds on its flow. `build` keeps the node ids from the edge file here, so
  those ids should be `1, 2, …, n`. `maximumflow` uses only the upper bound.

### How to create one
Read the edges with `MyConstrainedGraphEdgeModels(path, parser)` from Files.jl, then call
`build(MyDirectedBipartiteGraphModel, (s = ..., t = ..., edges = ...))`, defined in Factory.jl.

### Example
```julia
edges = Dict{Int64, MyConstrainedGraphEdgeModel}();
edges[1] = build(MyConstrainedGraphEdgeModel, (id = 1, source = 1, target = 2,
    weight = 0.0, lower = 0.0, upper = 4.0));
edges[2] = build(MyConstrainedGraphEdgeModel, (id = 2, source = 2, target = 3,
    weight = 0.0, lower = 0.0, upper = 3.0));
network = build(MyDirectedBipartiteGraphModel, (s = 1, t = 3, edges = edges));
network.capacity[(1, 2)] # (0.0, 4.0): the lower and upper bounds of edge 1 → 2
```
"""
mutable struct MyDirectedBipartiteGraphModel <: AbstractGraphModel

    # data -
    nodes::Union{Nothing, Dict{Int64, MyGraphNodeModel}} # node number => node
    edges::Union{Nothing, Dict{Tuple{Int, Int}, Number}} # (source, target) => edge cost or weight
    children::Union{Nothing, Dict{Int64, Set{Int64}}} # node number => the set of its children
    edgesinverse::Dict{Int, Tuple{Int, Int}} # edge number => (source, target)
    left::Set{Int64} # one node group of a bipartite graph (build does not set it)
    right::Set{Int64} # the other node group (build does not set it)
    source::Int64 # id of the source node
    sink::Int64 # id of the sink node
    capacity::Dict{Tuple{Int64, Int64}, Tuple{Number, Number}} # (source, target) => (lower, upper) flow bounds

    # empty constructor: new() makes a graph with no fields set; build(...) in Factory.jl fills them in -
    MyDirectedBipartiteGraphModel() = new();
end

# Algorithm tag types. A tag type has no fields. We create one with empty parentheses, e.g.,
# DijkstraAlgorithm(), and pass it to a function to choose which method that function runs -

"""
    struct DijkstraAlgorithm <: AbstractGraphSearchAlgorithm

A tag that selects Dijkstra's shortest-path method in [`findshortestpath`](@ref) (week 4, L4d).

A tag type has no fields; its only job is to choose the method. Dijkstra's method needs every
edge weight to be zero or positive, and `findshortestpath` stops with an `ArgumentError` when a
weight is negative.

### How to use one
Create the tag with `DijkstraAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`findshortestpath(graph, startnode, algorithm = DijkstraAlgorithm())`.
"""
struct DijkstraAlgorithm <: AbstractGraphSearchAlgorithm end

"""
    struct BellmanFordAlgorithm <: AbstractGraphSearchAlgorithm

A tag that selects the Bellman-Ford shortest-path method in [`findshortestpath`](@ref)
(week 4, L4d). It is the default of `findshortestpath`.

A tag type has no fields; its only job is to choose the method. The Bellman-Ford method accepts
negative edge weights. `findshortestpath` stops with an `ArgumentError` when it finds a cycle of
negative total weight that the start node can reach.

### How to use one
Create the tag with `BellmanFordAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`findshortestpath(graph, startnode, algorithm = BellmanFordAlgorithm())`.
"""
struct BellmanFordAlgorithm <: AbstractGraphSearchAlgorithm end

"""
    struct FordFulkersonAlgorithm <: AbstractGraphFlowAlgorithm

A tag that selects the Ford-Fulkerson maximum-flow method in [`maximumflow`](@ref)
(week 5, L5a). It is the default of `maximumflow`.

A tag type has no fields; its only job is to choose the method. This method finds each
augmenting path (a path from the source to the sink with spare capacity) by depth-first search.

### How to use one
Create the tag with `FordFulkersonAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`maximumflow(graph, source, sink, algorithm = FordFulkersonAlgorithm())`.
"""
struct FordFulkersonAlgorithm <: AbstractGraphFlowAlgorithm end

"""
    struct EdmondsKarpAlgorithm <: AbstractGraphFlowAlgorithm

A tag that selects the Edmonds-Karp maximum-flow method in [`maximumflow`](@ref)
(week 5, L5a and L5b).

A tag type has no fields; its only job is to choose the method. This method finds each
augmenting path (a path from the source to the sink with spare capacity) by breadth-first
search, so it always uses a path with the fewest edges.

### How to use one
Create the tag with `EdmondsKarpAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`maximumflow(graph, source, sink, algorithm = EdmondsKarpAlgorithm())`.
"""
struct EdmondsKarpAlgorithm <: AbstractGraphFlowAlgorithm end

"""
    struct DepthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm

A tag that makes [`walk`](@ref) visit the nodes of a graph in depth-first order: it follows one
path as deep as it can before it backs up. No course notebook uses `walk`.

### How to use one
Create the tag with `DepthFirstSearchAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`walk(graph, startnode, algorithm = DepthFirstSearchAlgorithm())`.
"""
struct DepthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm end

"""
    struct BreadthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm

A tag that makes [`walk`](@ref) visit the nodes of a graph in breadth-first order: all nodes one
edge away, then all nodes two edges away, and so on. It is the default of `walk`. No course
notebook uses `walk`.

### How to use one
Create the tag with `BreadthFirstSearchAlgorithm()` and pass it as the `algorithm` keyword, e.g.,
`walk(graph, startnode, algorithm = BreadthFirstSearchAlgorithm())`.
"""
struct BreadthFirstSearchAlgorithm <: AbstractGraphTraversalAlgorithm end

"""
    struct JacobiMethod <: AbstractLinearSolverAlgorithm

A tag that selects the Jacobi method in `solve(A, b, xₒ; algorithm = ...)` from Solvers.jl
(week 6, L6c and L6d). It is the default of that `solve`.

A tag type has no fields; its only job is to choose the method. The Jacobi method improves a
guess `x` of the solution of `A⋅x = b` by `x ← x + D⁻¹⋅(b − A⋅x)`, where `D` is the diagonal
of `A`.

### How to use one
Create the tag with `JacobiMethod()` and pass it as the `algorithm` keyword, e.g.,
`solve(A, b, xₒ, algorithm = JacobiMethod())`.
"""
struct JacobiMethod <: AbstractLinearSolverAlgorithm end

"""
    struct GaussSeidelMethod <: AbstractLinearSolverAlgorithm

A tag that selects the Gauss-Seidel method in `solve(A, b, xₒ; algorithm = ...)` from Solvers.jl
(week 6, L6c and L6d).

A tag type has no fields; its only job is to choose the method.

### How to use one
Create the tag with `GaussSeidelMethod()` and pass it as the `algorithm` keyword, e.g.,
`solve(A, b, xₒ, algorithm = GaussSeidelMethod())`.
"""
struct GaussSeidelMethod <: AbstractLinearSolverAlgorithm end

"""
    struct SuccessiveOverRelaxationMethod <: AbstractLinearSolverAlgorithm

A tag that selects the successive over-relaxation (SOR) method in
`solve(A, b, xₒ; algorithm = ...)` from Solvers.jl (week 6, L6c and L6d).

A tag type has no fields; its only job is to choose the method. The relaxation factor is the
`ω` keyword of `solve`.

### How to use one
Create the tag with `SuccessiveOverRelaxationMethod()` and pass it as the `algorithm` keyword,
e.g., `solve(A, b, xₒ, algorithm = SuccessiveOverRelaxationMethod(), ω = 1.2)`.
"""
struct SuccessiveOverRelaxationMethod <: AbstractLinearSolverAlgorithm end

# -- GRAPHS ABOVE HERE ---------------------------------------------------------------------------- #

# -- MDP AND RL BELOW HERE ------------------------------------------------------------------------ #


"""
    mutable struct MyMDPProblemModel <: AbstractProcessModel

A Markov decision process (MDP), the model of weeks 11 and 12 (L11c, L11d, L12a, and L12b).

In an MDP, an agent in state `s` takes action `a`, earns the reward `R(s,a)`, and moves to the
next state `s′` with probability `T(s′|s,a)`. The MDP is the tuple `(𝒮, 𝒜, T, R, γ)`.

### Fields
- `𝒮::Array{Int64,1}`: the states, numbered `1, 2, …, |𝒮|`.
- `𝒜::Array{Int64,1}`: the actions, numbered `1, 2, …, |𝒜|`.
- `T::Union{Function, Array{Float64,3}}`: the transition probabilities. As an array, `T[s, s′, a]`
  is the probability that action `a` in state `s` moves us to state `s′`. The array is
  `|𝒮| × |𝒮| × |𝒜|`, and for each `s` and `a` the entries over `s′` add up to 1. The field also
  accepts a function, but `lookahead`, `Q`, `backup`, and `solve` in MDP.jl index `T` with
  brackets, so they need the array.
- `R::Union{Function, Array{Float64,2}}`: the rewards. As an array, `R[s, a]` is the reward for
  taking action `a` in state `s`; the array is `|𝒮| × |𝒜|`. The functions in MDP.jl need the array.
- `γ::Float64`: the discount factor, between 0 and 1. A reward `k` steps in the future counts
  `γᵏ` times as much as a reward now.

### How to create one
Call `build(MyMDPProblemModel, (𝒮 = ..., 𝒜 = ..., T = ..., R = ..., γ = ...))`, defined in
Factory.jl. If a key is missing, `build` stores a placeholder (an array of arbitrary numbers, or
`γ = 0.1`) instead of stopping with an error, so pass all five keys.

### Example
```julia
T = zeros(2, 2, 1);  # T[s, s′, a]: two states and one action
T[1, 2, 1] = 1.0;    # from state 1, the action moves us to state 2
T[2, 2, 1] = 1.0;    # from state 2, the action keeps us in state 2
R = zeros(2, 1);     # R[s, a]: one row per state, one column per action
R[2, 1] = 1.0;       # we earn 1 in state 2
m = build(MyMDPProblemModel, (𝒮 = [1, 2], 𝒜 = [1], T = T, R = R, γ = 0.9));
```
"""
mutable struct MyMDPProblemModel <: AbstractProcessModel

    # data -
    𝒮::Array{Int64,1} # the states 1, 2, ..., |𝒮|
    𝒜::Array{Int64,1} # the actions 1, 2, ..., |𝒜|
    T::Union{Function, Array{Float64,3}} # T[s, s′, a]: probability of moving from s to s′ under action a
    R::Union{Function, Array{Float64,2}} # R[s, a]: reward for taking action a in state s
    γ::Float64 # discount factor, between 0 and 1

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyMDPProblemModel() = new()
end

"""
    mutable struct MyRectangularGridWorldModel <: AbstractWorldModel

A rectangular grid world: a grid of squares that an agent moves through one square at a time
(weeks 11 and 12, L11c, L11d, and L12a). The grid numbers each square as one state of an MDP and
holds the reward of each square.

### Fields
- `number_of_rows::Int`: the number of rows in the grid.
- `number_of_cols::Int`: the number of columns in the grid.
- `coordinates::Dict{Int,Tuple{Int,Int}}`: state number → square `(row, column)`.
- `states::Dict{Tuple{Int,Int},Int}`: square `(row, column)` → state number. `build` numbers the
  squares row by row: `(1,1)` is state 1, `(1,2)` is state 2, and so on. So square `(i, j)` is
  state `(i − 1)⋅number_of_cols + j`.
- `moves::Dict{Int,Tuple{Int,Int}}`: action → change in the square `(i, j)`: action 1 adds
  `(-1, 0)`, 2 adds `(1, 0)`, 3 adds `(0, -1)`, and 4 adds `(0, 1)`. The course notebooks read a
  square `(i, j)` as the point `(x, y)`, so the four actions move left, right, down, and up.
- `rewards::Dict{Int,Float64}`: state number → the reward of that square.

### How to create one
Call `build(MyRectangularGridWorldModel, (nrows = ..., ncols = ..., rewards = ...))`, defined in
Factory.jl. The `rewards` key is a `Dict{Tuple{Int,Int},Float64}` keyed by square `(row, column)`.
Squares that are not in it get the optional key `defaultreward`, which is `-1.0` when we leave it out.

### Example
```julia
world = build(MyRectangularGridWorldModel, (nrows = 2, ncols = 3, rewards = Dict((2, 3) => 10.0)));
world.states[(2, 3)] # 6: the last square of the second row
world.rewards[1]     # -1.0: the default reward
```
"""
mutable struct MyRectangularGridWorldModel <: AbstractWorldModel

    # data -
    number_of_rows::Int # rows in the grid
    number_of_cols::Int # columns in the grid
    coordinates::Dict{Int,Tuple{Int,Int}} # state number => (row, column)
    states::Dict{Tuple{Int,Int},Int} # (row, column) => state number
    moves::Dict{Int,Tuple{Int,Int}} # action => (row change, column change)
    rewards::Dict{Int,Float64} # state number => reward

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyRectangularGridWorldModel() = new();
end

"""
    struct MyValueIterationModel

The setting of value iteration, the method that solves an MDP (week 11, L11d; week 12, L12a).

The call `solve(MyValueIterationModel(k_max), problem)` in MDP.jl starts from `U(s) = 0` for
every state. It then applies the Bellman backup `U(s) ← maxₐ [R(s,a) + γ⋅Σ T(s,s′,a)⋅U(s′)]` to
every state, `k_max` times, where the sum runs over every next state `s′`. It returns a
[`MyValueFunctionPolicy`](@ref). This type is a `struct`, so its field is fixed once we create
it, and it declares no family.

### Fields
- `k_max::Int64`: the number of sweeps. `solve` always runs exactly `k_max` sweeps.

### How to create one
Call `MyValueIterationModel(k_max)`, e.g., `MyValueIterationModel(1000)`. A struct with no
constructor of its own gets one from Julia that takes the field values in order.
"""
struct MyValueIterationModel

    # data -
    k_max::Int64; # number of value-iteration sweeps
end

"""
    struct MyValueFunctionPolicy

The result of value iteration: the MDP and the value `U(s)` of each state (week 11, L11d).

`solve(MyValueIterationModel(k_max), problem)` in MDP.jl returns one. The object can be called
like a function: if `π` is a `MyValueFunctionPolicy`, then `π(s)` returns the greedy action in
state `s`. The greedy action is the one with the largest `R(s,a) + γ⋅Σ T(s,s′,a)⋅U(s′)`.

### Fields
- `problem::MyMDPProblemModel`: the MDP that was solved.
- `U::Array{Float64,1}`: the value of each state: `U[s]` is the value of state `s`, length `|𝒮|`.
  `Q(problem, U)` turns it into the table of action values.

### How to create one
Call `solve(MyValueIterationModel(k_max), problem)`, e.g.,
`solution = solve(MyValueIterationModel(1000), m)`, where `m` is a [`MyMDPProblemModel`](@ref).
"""
struct MyValueFunctionPolicy
    problem::MyMDPProblemModel # the MDP that was solved
    U::Array{Float64,1} # U[s]: the value of state s
end

"""
    mutable struct MyExploreFirstAlgorithmModel <: AbstractBanditAlgorithmModel

The explore-first algorithm for a `K`-armed bandit (week 10, L10d).

`solve(model; T, world)` in Bandit.jl first pulls each arm the same number of times,
`Nₐ = clamp(round((T/K)^(2/3)⋅cbrt(log T)), 1, floor(T/K))`. It then pulls the arm with the
best average reward for the remaining rounds. Here `T` is the number of rounds, and
`world(a)` returns the reward of one pull of arm `a`.

### Fields
- `K::Int64`: the number of arms, at least 1.

### How to create one
Call `build(MyExploreFirstAlgorithmModel, (K = 3,))`, defined in Factory.jl. The comma after the
3 makes `(K = 3,)` a `NamedTuple` with one entry; without the comma, Julia reads `(K = 3)` as an
assignment.
"""
mutable struct MyExploreFirstAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyExploreFirstAlgorithmModel() = new();
end

"""
    mutable struct MyUCB1AlgorithmModel <: AbstractBanditAlgorithmModel

The UCB1 (upper confidence bound) algorithm for a `K`-armed bandit (week 10, L10c and L10d).

`solve(model; T, world)` in Bandit.jl pulls every arm once. In each later round `t`, it pulls the
arm with the largest `μ̂ₐ + sqrt(2⋅log(t)/Nₐ)`, where `μ̂ₐ` is the average reward of arm `a` so far
and `Nₐ` is the number of times we pulled it. Here `T` is the number of rounds, and `world(a)`
returns the reward of one pull of arm `a`.

### Fields
- `K::Int64`: the number of arms, at least 1.

### How to create one
Call `build(MyUCB1AlgorithmModel, (K = 3,))`, defined in Factory.jl. The comma after the 3 makes
`(K = 3,)` a `NamedTuple` with one entry.
"""
mutable struct MyUCB1AlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyUCB1AlgorithmModel() = new();
end

"""
    mutable struct MyEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

The epsilon-greedy algorithm for a `K`-armed bandit (week 10, L10d).

`solve(model; T, world)` in Bandit.jl pulls every arm once. In each later round `t`, with
probability `ϵₜ = min(1, cbrt(K⋅log(t)/t))` it pulls a random arm, and otherwise it pulls the arm
with the best average reward so far. Here `T` is the number of rounds, and `world(a)` returns the
reward of one pull of arm `a`.

### Fields
- `K::Int64`: the number of arms, at least 1.

### How to create one
Call `build(MyEpsilonGreedyAlgorithmModel, (K = 3,))`, defined in Factory.jl. The comma after the
3 makes `(K = 3,)` a `NamedTuple` with one entry.
"""
mutable struct MyEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of arms

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyEpsilonGreedyAlgorithmModel() = new();
end

"""
    mutable struct MyBinaryVectorArmsEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

An epsilon-greedy bandit whose arms are yes/no shopping choices over `K` goods. No course
notebook uses this type.

Each arm is a vector of `K` zeros and ones that says which goods to buy, so
`solve(model, context; T, world)` in Bandit.jl considers `2ᴷ` arms. It works with a
[`MyConsumerChoiceBanditContextModel`](@ref) that holds the shopping data.

### Fields
- `K::Int64`: the number of goods (not the number of arms).

### How to create one
Call `build(MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, (K = 3,))`, defined in Factory.jl.
"""
mutable struct MyBinaryVectorArmsEpsilonGreedyAlgorithmModel <: AbstractBanditAlgorithmModel

    # data -
    K::Int64 # number of goods; the number of arms is 2^K

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyBinaryVectorArmsEpsilonGreedyAlgorithmModel() = new();
end


"""
    mutable struct MyConsumerChoiceBanditContextModel <: AbstractBanditProblemContextModel

The shopping data (the context) for the binary-vector bandit,
[`MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`](@ref). No course notebook uses this type.

`solve(model, context; T, world)` in Bandit.jl reads only `μₒ` from the context. It passes the
whole context to our `world` function, which uses the other fields to compute the reward.

### Fields
- `data::Dict{String, Any}`: the context data for each item, keyed by a name.
- `items::Array{String,1}`: the names of the items (goods) we may buy.
- `bounds::Array{Float64,2}`: a matrix of bounds on how much of each item we may buy.
- `B::Float64`: the budget we may spend on the collection of items.
- `nₒ::Array{Float64,1}`: an initial guess of the quantity of each item.
- `μₒ::Array{Float64,1}`: an initial estimate of the average reward of each arm, one entry per
  arm (`2ᴷ` entries for `K` goods).
- `γ::Array{Float64,1}`: the parameters (preferences) of the utility function.

### How to create one
Call `build(MyConsumerChoiceBanditContextModel, (data = ..., items = ..., bounds = ..., B = ...,
nₒ = ..., μₒ = ..., γ = ...))`, defined in Factory.jl. All seven keys are required.
"""
mutable struct MyConsumerChoiceBanditContextModel <: AbstractBanditProblemContextModel

    # data -
    data::Dict{String, Any} # context data for each item
    items::Array{String,1} # names of the items we may buy
    bounds::Array{Float64,2} # bounds on how much of each item we may buy
    B::Float64 # budget for the collection of items
    nₒ::Array{Float64,1} # initial guess of the quantity of each item
    μₒ::Array{Float64,1} # initial estimate of the average reward of each arm
    γ::Array{Float64,1} # parameters (preferences) of the utility function

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyConsumerChoiceBanditContextModel() = new();
end
# -- MDP AND RL ABOVE HERE ------------------------------------------------------------------------ #

# -- WMA and MWA BELOW HERE ----------------------------------------------------------------------- #

"""
    mutable struct MyBinaryWeightedMajorityAlgorithmModel <: AbstractOnlineLearningModel

The binary weighted majority algorithm (WMA), the online learning method of week 10 (L10b).

In each round, `n` experts each predict an outcome of `-1` or `+1`. The algorithm predicts the
side with the larger total expert weight. Then the adversary reveals the actual outcome, and
every expert that was wrong has its weight multiplied by `1 − ϵ`. The function
`play(model, data)` in Online.jl runs the `T` rounds.

### Fields
- `ϵ::Float64`: the learning rate: the fraction of weight a wrong expert loses in one round.
- `n::Int64`: the number of experts.
- `T::Int64`: the number of rounds.
- `weights::Array{Float64,2}`: the expert weights, `(T + 1) × n`: row `t` holds the weights at the
  start of round `t`. `build` sets every entry to 1. `play` fills rows 2 to `T + 1`, and it changes
  this array in place.
- `expert::Function`: the expert function, called as `expert(i, t, data)`. It returns the
  prediction of expert `i` in round `t`, either `-1` or `+1`.
- `adversary::Function`: the adversary function, called as `adversary(t, data)`. It returns the
  actual outcome of round `t`, either `-1` or `+1`.

### How to create one
Call `build(MyBinaryWeightedMajorityAlgorithmModel, (ϵ = ..., n = ..., T = ..., expert = ...,
adversary = ...))`, defined in Factory.jl, where `expert` and `adversary` are functions we have
written. All five keys are required; `build` creates `weights` itself.
"""
mutable struct MyBinaryWeightedMajorityAlgorithmModel <: AbstractOnlineLearningModel

    # parameters
    ϵ::Float64 # learning rate: a wrong expert's weight is multiplied by (1 - ϵ)
    n::Int64 # number of experts
    T::Int64 # number of rounds
    weights::Array{Float64,2} # (T + 1) × n: row t holds the expert weights at the start of round t
    expert::Function # expert(i, t, data): the prediction of expert i in round t
    adversary::Function # adversary(t, data): the actual outcome of round t

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyBinaryWeightedMajorityAlgorithmModel() = new();
end

"""
    mutable struct MyTwoPersonZeroSumGameModel <: AbstractOnlineLearningModel

A two-person zero-sum game that the row player learns with the multiplicative weights algorithm
(MWA). No course notebook uses this type.

In a zero-sum game, whatever one player wins, the other player loses. In each round of
`play(model)` in Online.jl, the row player draws an action with probability `p = w/Σw`, where
`w` is the current weight vector. The column player picks the column `j` that gives the row
player the smallest expected payoff. Then each row action `i` has its weight multiplied by
`exp(ϵ⋅M[i, j])`, so actions that pay well against `j` gain weight.

### Fields
- `ϵ::Float64`: the learning rate of the weight update.
- `n::Int64`: the number of actions of the row player (the experts).
- `T::Int64`: the number of rounds.
- `weights::Array{Float64,2}`: the action weights, `(T + 1) × n`: row `t` holds the weights at the
  start of round `t`. `build` fills row 1 with random numbers between 0 and 1 and the other rows
  with zeros. `play` fills rows 2 to `T + 1`.
- `payoffmatrix::Array{Float64,2}`: the payoff matrix `M`: `M[i, j]` is the payoff to the row
  player when the row player picks `i` and the column player picks `j`. `play` needs an `n × n`
  matrix.

### How to create one
Call `build(MyTwoPersonZeroSumGameModel, (ϵ = ..., n = ..., T = ..., payoffmatrix = ...))`,
defined in Factory.jl.

### Example
```julia
game = build(MyTwoPersonZeroSumGameModel, (ϵ = 0.1, n = 2, T = 100,
    payoffmatrix = [0.0 1.0; 1.0 0.0]));
```
"""
mutable struct MyTwoPersonZeroSumGameModel <: AbstractOnlineLearningModel

    # parameters
    ϵ::Float64 # learning rate of the weight update
    n::Int64 # number of actions of the row player (experts)
    T::Int64 # number of rounds
    weights::Array{Float64,2} # (T + 1) × n: row t holds the action weights at the start of round t
    payoffmatrix::Array{Float64,2} # M[i, j]: payoff to the row player for row action i and column action j

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyTwoPersonZeroSumGameModel() = new();
end

"""
    mutable struct MyQLearningAgentModel <: AbstractOnlineLearningModel

A Q-learning agent, the learner of week 12 (L12a and L12b).

The agent keeps a table `Q` of action values. `Q[s,a]` estimates the total discounted reward of
taking action `a` in state `s` and acting well afterward. The function
`solve(agent, problem; worldmodel, absorbing)` in QLearning.jl learns the table from simulated
moves, without reading the rewards or the transition probabilities of the problem.

### Fields
- `states::Array{Int,1}`: the states, numbered `1, 2, …, |𝒮|`.
- `actions::Array{Int,1}`: the actions, numbered `1, 2, …, |𝒜|`.
- `γ::Float64`: the discount factor, between 0 and 1.
- `α::Float64`: the learning rate, between 0 and 1: the fraction of the way each update moves
  `Q[s,a]` toward its target.
- `Q::Array{Float64,2}`: the action-value table, `|𝒮| × |𝒜|`: one row per state and one column per
  action. `solve` starts from a copy of this table and returns the learned table; the agent's own
  table is not changed.

### How to create one
Call `build(MyQLearningAgentModel, (states = ..., actions = ..., α = ..., γ = ..., Q = ...))`,
defined in Factory.jl. All five keys are required; `build` stops with an `ArgumentError` that
names the first missing key. An empty `NamedTuple()` skips this check, and `build` then returns
an agent whose fields are not set.

### Example
```julia
agent = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2],
    α = 0.5, γ = 0.95, Q = zeros(3, 2)));
```
"""
mutable struct MyQLearningAgentModel <: AbstractOnlineLearningModel

    # data -
    states::Array{Int,1} # the states 1, 2, ..., |𝒮|
    actions::Array{Int,1} # the actions 1, 2, ..., |𝒜|
    γ::Float64 # discount factor
    α::Float64 # learning rate
    Q::Array{Float64,2} # action-value table: one row per state, one column per action

    # empty constructor: new() makes an agent with no fields set; build(...) in Factory.jl fills them in -
    MyQLearningAgentModel() = new();
end
# -- WMA and MWA ABOVE HERE ----------------------------------------------------------------------- #

# -- HOPFIELD NETWORKS BELOW HERE ----------------------------------------------------------------- #


"""
    mutable struct MyClassicalHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

A classical Hopfield network: a network that stores a few patterns (memories) and recovers a
stored pattern from a noisy copy. No course notebook uses this type.

Each memory is a vector of `N` entries, each `-1` or `+1`, e.g., the pixels of a black-and-white
image. The function `recover(model, sₒ, trueenergyvalue)` in Hopfield.jl starts from the state
`sₒ`. It repeatedly picks one entry `j` at random and sets it to the sign of `W[j,:]⋅s − b[j]`.

### Fields
- `W::Array{<:Number, 2}`: the weight matrix, `N × N`. `build` sets `W = (1/N)⋅Σₖ mₖ⋅mₖᵀ`, the
  sum over the memories `mₖ`, with zeros on the diagonal. `build` stores `W` as `Float64` values; the bias `b` and the
  energies are `Float32`.
- `b::Array{<:Number, 1}`: the bias vector, length `N`. `build` sets every entry to zero.
- `memories::Array{<:Number, 2}`: the stored memories, `N × K`: one memory per column.
- `energy::Dict{Int64, Float32}`: memory number `k` → the energy
  `E(mₖ) = −(1/2)⋅mₖᵀ⋅W⋅mₖ − bᵀ⋅mₖ` of that memory. A lower energy means a more stable state.

### How to create one
Call `build(MyClassicalHopfieldNetworkModel, (memories = ...,))`, defined in Factory.jl, where the
memories are an `N × K` matrix with one memory per column. `build` computes `W`, `b`, and `energy`.
"""
mutable struct MyClassicalHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

    # data -
    W::Array{<:Number, 2} # weight matrix, N × N
    b::Array{<:Number, 1} # bias vector, length N
    memories::Array{<:Number, 2} # stored memories, N × K: one memory per column
    energy::Dict{Int64, Float32} # memory number => energy of that memory

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyClassicalHopfieldNetworkModel() = new();
end

"""
    mutable struct MyModernHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

A modern Hopfield network: a network that recovers a stored memory with softmax weights. No
course notebook uses this type.

The function `recover(model, sₒ)` in Hopfield.jl repeats two steps from the state `sₒ`. It
computes the weights `p = softmax(β⋅X̂ᵀ⋅s)`, one per memory, and then moves the state to the
weighted average `s ← X̂⋅p`. The softmax turns a vector `z` into positive weights that add up to
1: `softmax(z)ᵢ = exp(zᵢ)/Σⱼ exp(zⱼ)`.

### Fields
- `X::Array{<:Number, 2}`: the memories, `N × K`: one memory per column. `recover` does not read
  this field.
- `X̂::Array{<:Number, 2}`: the normalized memories, the same shape as `X`. `recover` uses these.
- `β::Number`: the inverse temperature. A larger `β` puts more of the weight on the memory most
  similar to the state.

### How to create one
Call `build(MyModernHopfieldNetworkModel, (memories = ..., normalized_memories = ..., β = ...))`,
defined in Factory.jl. All three keys are required; `normalized_memories` fills `X̂`.
"""
mutable struct MyModernHopfieldNetworkModel <: AbstractlHopfieldNetworkModel

    # data -
    X::Array{<:Number, 2} # memories, N × K: one memory per column
    X̂::Array{<:Number, 2} # normalized memories, N × K
    β::Number; # inverse temperature of the softmax

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    MyModernHopfieldNetworkModel() = new();
end
# -- HOPFIELD NETWORKS ABOVE HERE ----------------------------------------------------------------- #

# -- UTILITY FUNCTIONS BELOW HERE ------------------------------------------------------------------ #
"""
    abstract type AbstractUtilityFunctionType end

The family of utility function models: models of the value a consumer places on a basket of
goods.

The only member is [`VLLinearUtilityFunction`](@ref). The helper `_build(...)` in Factory.jl
accepts any member of this family. No course notebook uses this family.
"""
abstract type AbstractUtilityFunctionType end

"""
    mutable struct VLLinearUtilityFunction <: AbstractUtilityFunctionType

A linear utility function `U(x) = α₁⋅x₁ + α₂⋅x₂ + … + αₙ⋅xₙ`: the value a consumer places on the
amounts `x₁, …, xₙ` of `n` goods. No course notebook uses this type.

The function `evaluate(model, x)` in Indifference.jl computes `U(x)`. The function
`indifference(model; utility, bounds)` traces the points `x` that all have the same utility.

### Fields
- `α::Union{Nothing, Array{Float64,1}}`: the weights (preferences), one per good. The field holds
  `nothing` when `data` has other keys but no `α` key. With an empty `NamedTuple()`, `build`
  leaves the field unset.

### How to create one
Call `build(VLLinearUtilityFunction, (α = ...,))`, defined in Factory.jl.

### Example
```julia
u = build(VLLinearUtilityFunction, (α = [0.5, 0.5],));
evaluate(u, [2.0, 4.0]) # 0.5⋅2 + 0.5⋅4 = 3.0
```
"""
mutable struct VLLinearUtilityFunction <: AbstractUtilityFunctionType

    # data -
    α::Union{Nothing, Array{Float64,1}} # the weights (preferences), one per good

    # empty constructor: new() makes a model with no fields set; build(...) in Factory.jl fills them in -
    VLLinearUtilityFunction() = new()
end
# -- UTILITY FUNCTIONS ABOVE HERE ------------------------------------------------------------------ #
