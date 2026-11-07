# =============================================================================
# CHEME 5800 | Factory.jl: the build(...) methods that make the course models
# =============================================================================
# This file holds the factory methods of the course package. A factory method
# makes a model for us. We call build(ModelType, data), and the method creates
# an empty instance of ModelType, copies our data into its fields, fills in any
# derived fields, and returns the finished model.
#
# The model types, and the meaning of each field, are defined in Types.jl.
# Julia chooses which build method to run from the type we pass as the first
# argument. This choice by argument type is called multiple dispatch.
#
# The data argument is usually a NamedTuple: a fixed list of named values,
# written like (nrows = 20, ncols = 20, rewards = rewards). We read one value
# with data.nrows or with data[:nrows]; the two forms mean the same thing.
# A NamedTuple with one entry needs a trailing comma, as in (K = 3,).
# Without the comma, Julia reads (K = 3) as the assignment K = 3.
# If data lacks a key that a method reads, Julia stops with an error that
# names the missing field.
#
# Where the course calls these methods:
#   week 4 (L4b, L4d)        directed graphs, built from edge models read from a file
#   week 5 (L5a, L5b, L5c)   flow networks with capacities, and the linear program
#   week 9 (L9a, L9b, L9d)   the perceptron classifier
#   week 10 (L10b, L10c, L10d)  the weighted majority algorithm and the bandit algorithms
#   week 11 (L11c, L11d)     Markov decision processes and grid worlds
#   week 12 (L12a, L12b)     Markov decision processes, grid worlds, and Q-learning agents
# The text record, logistic regression, zero-sum game, contextual bandit,
# Hopfield, and utility function methods have no caller in the current notebooks.
#
# The methods in this file (a leading underscore marks a private helper):
#   _build(MySarcasmRecordModel, data)            cleans a headline and stores one sarcasm record
#   build(T <: AbstractTextRecordModel, data)     builds a text record by calling _build
#   build(T <: AbstractLinearProgrammingProblemType, data)  stores a linear program: A, b, c, lb, ub
#   build(MyPerceptronClassificationModel, data)  stores the starting coefficients and the mistake limit
#   build(MyLogisticRegressionClassificationModel, data)  stores the coefficients and the training settings
#   build(T <: AbstractGraphModel, edgemodels)    builds a graph: renumbers the nodes, stores edges and children
#   build(MyGraphEdgeModel, data)                 stores one weighted edge
#   build(MyConstrainedGraphEdgeModel, data)      stores one edge with a weight and flow bounds
#   build(MyDirectedBipartiteGraphModel, data)    builds a flow network: a graph plus capacities, source, and sink
#   build(MyMDPProblemModel, data)                stores a Markov decision process (𝒮, 𝒜, T, R, γ)
#   build(MyRectangularGridWorldModel, data)      numbers the squares of a grid, and sets their rewards and the moves
#   build(MyEpsilonGreedyAlgorithmModel, data)    stores the number of arms K
#   build(MyExploreFirstAlgorithmModel, data)     stores the number of arms K
#   build(MyUCB1AlgorithmModel, data)             stores the number of arms K
#   build(MyBinaryWeightedMajorityAlgorithmModel, data)  stores the experts and the adversary, and a weight table of ones
#   build(MyTwoPersonZeroSumGameModel, data)      stores the payoff matrix, and a weight table with random first row
#   build(MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, data)  stores the number of goods K
#   build(MyConsumerChoiceBanditContextModel, data)  stores the context of a consumer-choice bandit
#   build(MyQLearningAgentModel, data)            copies every field of a Q-learning agent from data
#   build(MyClassicalHopfieldNetworkModel, data)  computes the Hebbian weights and the energy of each memory
#   build(MyModernHopfieldNetworkModel, data)     stores the memories and the inverse temperature β
#   _build(T <: AbstractUtilityFunctionType, data)  copies every field of a utility function from data
#   build(VLLinearUtilityFunction, data)          builds a linear utility function by calling _build
#
# Syntax that appears in almost every method:
#   build(modeltype::Type{MyUCB1AlgorithmModel}, data::NamedTuple)
#       The first argument is a type, not a value. We call build(MyUCB1AlgorithmModel, (K = 3,)).
#   build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractGraphModel
#       One method serves a family of types. T stands for any subtype of AbstractGraphModel.
#   model = modeltype();
#       Calling the type with no arguments runs its empty constructor, new(). The fields are
#       not set yet (Julia calls them undefined), and the method then fills them in one by one.
#
# The fieldnames loop. Two methods fill a model with a loop instead of one line per
# field: the Q-learning agent build and the utility function _build. The loop is
#
#   for key ∈ fieldnames(modeltype)      # key takes each field name in turn, e.g. :states, then :actions
#       value = data[key]                # the value stored under that name in the NamedTuple
#       setproperty!(model, key, value)  # the same as model.states = value, when key is :states
#   end
#
# fieldnames(modeltype) returns the names of the fields of the type, in the order that
# Types.jl declares them. Each name is a Symbol: a name written with a leading colon,
# such as :α or :states. haskey(data, key) asks whether the NamedTuple has an entry with
# that name. The loop lets one method fill every field without naming the fields one by
# one. The two methods differ only when data lacks a field name: the Q-learning build
# stops with an ArgumentError, and the utility _build stores the value nothing.
# =============================================================================

# -- TEXT RECORD METHODS BELOW HERE ------------------------------------------------------------------------------------- #
"""
    _build(recordtype::Type{MySarcasmRecordModel}, data::NamedTuple) -> MySarcasmRecordModel

Clean a news headline, and store it with its article link and its label in a `MySarcasmRecordModel`.
This is the private helper behind `build(MySarcasmRecordModel, data)`.

The method cleans the headline in four steps:
1. It removes every character whose code point (its number in Unicode) is above 255. This keeps the
   Latin-1 letters, such as `é`, and removes symbols such as `—`, `€`, and `™`.
2. It removes the punctuation and symbol characters in the skip set below, such as `,`, `!`, `'`,
   `(`, and `£`. The set also holds the non-breaking space (Unicode U+00A0), but not the ordinary
   space. Two words joined by a non-breaking space become one word.
3. It removes ordinary spaces at both ends of the headline.
4. It splits the headline at each ordinary space, drops the empty pieces, and joins the words again
   with one space between them. This step turns a run of spaces into one space.

For example, the headline `"Hello,  world! It's £5"` becomes `"Hello world Its 5"`.

### Arguments
- `recordtype::Type{MySarcasmRecordModel}`: the record type to build.
- `data::NamedTuple`: the raw record. It must have the keys:
  - `headline::String`: the headline text, before cleaning.
  - `article::String`: the link to the article. The method stores it as given.
  - `issarcastic::Bool`: `true` if the headline is sarcastic. The method stores it as given.

### Returns
- `MySarcasmRecordModel`: the record, with the fields `headline` (the cleaned headline), `article`,
  and `issarcastic`.

### Throws
- an error, if `data` lacks one of the three keys.
"""
function _build(recordtype::Type{MySarcasmRecordModel}, data::NamedTuple)::MySarcasmRecordModel

    # get the raw values from the NamedTuple -
    headlinerecord = data.headline; # the headline text, before cleaning
    article = data.article; # the link to the article
    issarcastic = data.issarcastic; # true if the headline is sarcastic

    # build the set of characters to remove from the headline: punctuation and symbols.
    # A Set answers the question "is this character in the set?" quickly. Each push! adds one character -
    puncuation_skip_set = Set{Char}();
    push!(puncuation_skip_set, ',');
    push!(puncuation_skip_set, '.');
    push!(puncuation_skip_set, '!');
    push!(puncuation_skip_set, '?');
    push!(puncuation_skip_set, ';');
    push!(puncuation_skip_set, ':');
    push!(puncuation_skip_set, ')');
    push!(puncuation_skip_set, '(');
    push!(puncuation_skip_set, '\"'); # the double quote character
    push!(puncuation_skip_set, '/');
    push!(puncuation_skip_set, '\\'); # the backslash character; we write it twice because one backslash starts an escape
    push!(puncuation_skip_set, '-');
    push!(puncuation_skip_set, '_');
    push!(puncuation_skip_set, '`'); # the backtick character
    push!(puncuation_skip_set, '''); # the apostrophe (single quote) character
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
    push!(puncuation_skip_set, '$'); # the dollar sign
    push!(puncuation_skip_set, '¿');
    push!(puncuation_skip_set, '¡');
    push!(puncuation_skip_set, '£');
    push!(puncuation_skip_set, '€');
    push!(puncuation_skip_set, '¥');
    push!(puncuation_skip_set, '₹');
    push!(puncuation_skip_set, '©');
    push!(puncuation_skip_set, '®');
    push!(puncuation_skip_set, '™');
    push!(puncuation_skip_set, '¯'); # the macron, a raised bar
    push!(puncuation_skip_set, ' '); # the non-breaking space (Unicode U+00A0), not the ordinary space

    # split the headline into a vector of characters, so we can test each character on its own.
    # The pipe |> passes the value on its left to the function on its right: this line is collect(headlinerecord) -
    chararray =  headlinerecord |> collect;

    # use the filter function to keep a character c only when both tests pass: its code point
    # Int(c) is at most 255, and c is not in the skip set. The expression c -> ... is an anonymous
    # (unnamed) function; filter calls it on each character and keeps the character when it returns true.
    # The pipes then turn the kept characters back into a String, strip ordinary spaces from both
    # ends, and convert the result to a String. Inside the last anonymous function, the name string is
    # a variable that holds the text -
    headlinerecord = filter(c -> (c |> Int ) ≤ 255 && !(c ∈ puncuation_skip_set), # (c |> Int) is Int(c), the code point of c
            chararray) |> String |> string-> strip(string, ' ') |> String;

    # turn every run of spaces into one space: split the headline at each space, drop the empty
    # pieces that a run of spaces leaves behind, and join the words with one space between them -
    fields = split(headlinerecord, ' ') .|> String # the dot in .|> applies String to each piece in turn
    fields = filter(x -> x != "", fields) # keep the pieces that are not the empty string ""
    headlinerecord = join(fields, ' ') # glue the words back together, one space between them

    # create an empty record, and then fill in its fields -
    record = recordtype(); # the empty constructor; the fields are not set yet
    record.headline = headlinerecord;
    record.article = article;
    record.issarcastic = issarcastic;

    # return the populated record -
    return record;
end

"""
    build(record::Type{T}, data::NamedTuple) -> T where T <: AbstractTextRecordModel

Build one record of a text dataset from its raw fields. The method passes the work to the private
helper `_build`, which has one method for each record type. The package has one record type,
`MySarcasmRecordModel`. Its helper cleans the headline: it removes characters with a code point
above 255, removes punctuation and symbols, and collapses runs of spaces (see `_build` above).

### Arguments
- `record::Type{T}`: the record type to build. `T` is any subtype of `AbstractTextRecordModel`.
- `data::NamedTuple`: the raw fields of the record. For `MySarcasmRecordModel` the keys are:
  - `headline::String`: the headline text, before cleaning.
  - `article::String`: the link to the article.
  - `issarcastic::Bool`: `true` if the headline is sarcastic.

### Returns
- `T`: the record. A `MySarcasmRecordModel` holds the cleaned `headline`, and the `article` and
  `issarcastic` values as given.

### Throws
- a `MethodError`, if `T` is a record type that has no `_build` method.
- an error, if `data` lacks one of the keys that `_build` reads.

### Example
```julia
record = build(MySarcasmRecordModel, (headline = "Man, 42, still waiting!",
    article = "https://example.com/a", issarcastic = true));
record.headline   # "Man 42 still waiting"
```
"""
function build(record::Type{T}, data::NamedTuple)::T where T <: AbstractTextRecordModel
    return _build(record, data); # Julia picks the _build method that matches the record type
end
# -- TEXT RECORD METHODS ABOVE HERE ------------------------------------------------------------------------------------- #

# -- LINEAR PROGRAMMING AND CLASSIFICATION METHODS BELOW HERE ----------------------------------------------------------- #
"""
    build(modeltype::Type{T}, data::NamedTuple) -> T where T <: AbstractLinearProgrammingProblemType

Build a linear programming problem model, such as `MyLinearProgrammingProblemModel`, from its data.
The model describes the problem

    maximize cᵀx  subject to  A⋅x ≤ b  and  lb ≤ x ≤ ub,

where `x` is the vector of unknowns. The `solve(...)` method in Solvers.jl reads the model and solves
the problem. Its `constraints` keyword can change `A⋅x ≤ b` to `A⋅x ≥ b` or to `A⋅x = b`. This
method copies the five arrays into the model. It fills in no defaults and computes nothing.

### Arguments
- `modeltype::Type{T}`: the model type to build. `T` is any subtype of `AbstractLinearProgrammingProblemType`.
- `data::NamedTuple`: the problem data. It must have the keys:
  - `A::Array{Float64,2}`: the constraint matrix, one row per constraint and one column per unknown.
    A single constraint still needs a matrix with one row, such as `[2.0 3.0]`.
  - `b::Array{Float64,1}`: the right-hand side vector, one entry per constraint.
  - `c::Array{Float64,1}`: the objective coefficients, one entry per unknown.
  - `lb::Array{Float64,1}`: the lower bound of each unknown.
  - `ub::Array{Float64,1}`: the upper bound of each unknown.

### Returns
- `T`: the model, with the fields `A`, `b`, `c`, `lb`, and `ub` copied from `data`.

### Throws
- an error, if `data` lacks one of the five keys.

### Example
```julia
problem = build(MyLinearProgrammingProblemModel, (A = [2.0 3.0], b = [12.0], c = [1.0, 1.0],
    lb = [0.0, 0.0], ub = [4.0, 4.0]));
```
"""
function build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractLinearProgrammingProblemType

    # initialize -
    model = modeltype(); # build an empty model; the fields are not set yet

    # copy the problem data into the model -
    model.A = data.A; # the constraint matrix
    model.b = data.b; # the right-hand side vector
    model.c = data.c; # the objective coefficients
    model.lb = data.lb; # the lower bounds on the unknowns
    model.ub = data.ub; # the upper bounds on the unknowns

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyPerceptronClassificationModel}, data::NamedTuple) -> MyPerceptronClassificationModel

Build a perceptron classification model from its starting coefficients and its stopping rule.
The `learn(...)` method in Binary.jl trains the model. It passes through the training examples and
updates the coefficient vector `β` after each misclassified example. It stops after a full pass
through the examples with at most `mistakes` misclassified examples, or at its iteration limit.
This method stores the two values. It fills in no defaults.

### Arguments
- `modeltype::Type{MyPerceptronClassificationModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the keys:
  - `parameters::Vector{Float64}`: the starting coefficient vector `β`, one entry per column of the
    feature matrix. The course starts from a vector of zeros.
  - `mistakes::Int64`: the number of misclassified training examples we accept in one full pass.
    With `mistakes = 0`, training stops only after a pass with no mistakes, or at the iteration limit.

### Returns
- `MyPerceptronClassificationModel`: the model, with the fields `β` (from the key `parameters`) and `mistakes`.

### Throws
- an error, if `data` lacks one of the two keys.

### Example
```julia
model = build(MyPerceptronClassificationModel, (parameters = zeros(3), mistakes = 0));
```
"""
function build(modeltype::Type{MyPerceptronClassificationModel},
    data::NamedTuple)::MyPerceptronClassificationModel

    # build an empty model, and get the values from the NamedTuple -
    model = modeltype(); # the empty constructor; the fields are not set yet
    β = data.parameters; # the starting coefficient vector
    m = data.mistakes; # the number of mistakes we accept in one pass

    # store the values in the model -
    model.β = β;
    model.mistakes = m;

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyLogisticRegressionClassificationModel}, data::NamedTuple) -> MyLogisticRegressionClassificationModel

Build a logistic regression classification model from its starting coefficients and the settings of
its training loop. The `learn(...)` method in Binary.jl trains the model by gradient descent. Each
step moves the coefficients against the gradient of the total loss, `β ← β − α⋅∇L`, where the total
loss `L` is the sum of the loss of each training example. The method estimates each entry of the
gradient with a forward finite difference of step `h`. It stops when the length of the gradient,
`‖∇L‖`, is at most `ϵ`, or at its iteration limit. This method stores the values. It fills in no
defaults.

Three keys have different names from the fields they fill: `parameters` fills `β`, `learning_rate`
fills `α`, and `loss_function` fills `L`.

### Arguments
- `modeltype::Type{MyLogisticRegressionClassificationModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the keys:
  - `parameters::Vector{Float64}`: the starting coefficient vector `β`, one entry per column of the
    feature matrix.
  - `learning_rate::Float64`: the step size `α` of gradient descent.
  - `loss_function::Function`: the loss of one training example. `learn(...)` calls it as
    `loss_function(x, y, T, λ, β)`, where `x` is the feature vector of the example and `y` is its
    label, `−1` or `1`.
  - `ϵ::Float64`: the stopping tolerance on the length of the gradient.
  - `T::Float64`: the inverse temperature of the logistic function. `learn(...)` passes it to the loss function.
  - `λ::Float64`: the regularization parameter. `learn(...)` passes it to the loss function.
  - `h::Float64`: the step size of the finite-difference gradient.

### Returns
- `MyLogisticRegressionClassificationModel`: the model, with the fields `β`, `α`, `L`, `ϵ`, `T`, `λ`, and `h`.

### Throws
- an error, if `data` lacks one of the seven keys.
"""
function build(modeltype::Type{MyLogisticRegressionClassificationModel},
    data::NamedTuple)::MyLogisticRegressionClassificationModel

    # build an empty model, and get the values from the NamedTuple -
    model = modeltype(); # the empty constructor; the fields are not set yet
    β = data.parameters; # the starting coefficient vector
    α = data.learning_rate # the learning rate (step size of gradient descent)
    L = data.loss_function # the loss function of one training example
    ϵ = data.ϵ # the stopping tolerance on the length of the gradient
    T = data.T; # inverse temperature parameter
    λ = data.λ; # regularization parameter
    h = data.h; # finite difference step size

    # store the values in the model -
    model.β = β;
    model.α = α;
    model.L = L;
    model.ϵ = ϵ;
    model.T = T;
    model.λ = λ;
    model.h = h;

    # return the populated model -
    return model;
end
# -- LINEAR PROGRAMMING AND CLASSIFICATION METHODS ABOVE HERE ----------------------------------------------------------- #

# -- GRAPH METHODS BELOW HERE ------------------------------------------------------------------------------------------- #
"""
    build(model::Type{T}, edgemodels::Dict{Int64, MyGraphEdgeModel}) -> T where T <: AbstractGraphModel

Build a graph, such as a `MySimpleDirectedGraphModel`, from a dictionary of edge models. The course
reads the edge models from a file with `MyGraphEdgeModels(...)` in Files.jl, and passes them here.
Unlike the other methods in this file, the second argument is a dictionary, not a NamedTuple.

The method works in five steps:
1. It collects the id of every node that appears as the source or the target of an edge, and sorts
   the ids in increasing order.
2. It renumbers the nodes `1, 2, …, n` in that order. For example, the nodes `10, 20, 30` become
   `1, 2, 3`. Every field of the graph uses the new numbers.
3. It stores the weight of each edge under the key `(source, target)`. Each edge is stored in one
   direction only, from its source to its target. If two edge models join the same pair of nodes,
   the dictionary keeps only one of their weights.
4. It numbers the edges `1, 2, …, m` in order of source, then target, and stores the map from an
   edge number to its `(source, target)` pair. These numbers can differ from the `id` field of the
   edge models.
5. It stores the children of each node: the set of nodes that the edges leaving the node point to.

### Arguments
- `model::Type{T}`: the graph type to build. `T` is any subtype of `AbstractGraphModel`.
- `edgemodels::Dict{Int64, MyGraphEdgeModel}`: the edges, keyed by edge id. Each edge model gives a
  `source` node id, a `target` node id, and a numeric `weight`.

### Returns
- `T`: the graph, with the fields
  - `nodes::Dict{Int64, MyGraphNodeModel}`: node number => node model. Each node carries no data (`nothing`).
  - `edges::Dict{Tuple{Int64, Int64}, Number}`: `(source, target)` => edge weight.
  - `edgesinverse::Dict{Int, Tuple{Int, Int}}`: edge number => `(source, target)`.
  - `children::Dict{Int64, Set{Int64}}`: node number => the set of its children. A node with no
    outgoing edge has an empty set.

### Throws
- a `MethodError`, if an edge has the weight `nothing`, because the `edges` dictionary holds only numbers.

### Example
```julia
edges = Dict{Int64, MyGraphEdgeModel}();
edges[1] = build(MyGraphEdgeModel, (id = 1, source = 10, target = 20, weight = 2.0));
edges[2] = build(MyGraphEdgeModel, (id = 2, source = 20, target = 30, weight = 1.5));
graph = build(MySimpleDirectedGraphModel, edges);
graph.edges[(1, 2)]   # 2.0, the edge from node 10 (now node 1) to node 20 (now node 2)
graph.children[2]     # Set([3])
```
"""
function build(model::Type{T}, edgemodels::Dict{Int64, MyGraphEdgeModel}) where T <: AbstractGraphModel

    # build an empty graph model, and the empty dictionaries we fill below -
    graphmodel = model(); # the empty constructor; the fields are not set yet
    nodes = Dict{Int64, MyGraphNodeModel}(); # node number => node model
    edges = Dict{Tuple{Int64, Int64}, Number}(); # (source, target) => edge weight
    children = Dict{Int64, Set{Int64}}(); # node number => the set of its children
    edgesinverse = Dict{Int, Tuple{Int, Int}}(); # edge number => (source, target)

    # collect the id of every node that appears at either end of an edge. A Set keeps each id only once -
    tmp_node_ids = Set{Int64}();
    for (_,v) ∈ edgemodels # each entry is a pair key => value; (_, v) unpacks it, and _ means we ignore the key
        push!(tmp_node_ids, v.source);
        push!(tmp_node_ids, v.target);
    end
    list_of_node_ids = tmp_node_ids |> collect |> sort; # |> passes the value along: collect turns the Set into a Vector, and sort orders it

    # renumber the nodes 1, 2, ..., n in sorted order: nodeidmap[original id] = new number -
    nodeidmap = Dict{Int64, Int64}();
    nodecounter = 1;
    for id ∈ list_of_node_ids
        nodeidmap[id] = nodecounter;
        nodecounter += 1; # short for nodecounter = nodecounter + 1
    end

    # build one node model for each node. This comprehension [... for id ∈ ...] runs the assignment once
    # for each id. We want only the side effect, the filled nodes dictionary; Julia throws away the array
    # that the brackets build. MyGraphNodeModel(number, nothing) is a node that carries no extra data -
    [nodes[nodeidmap[id]] = MyGraphNodeModel(nodeidmap[id], nothing) for id ∈ list_of_node_ids];

    # store the weight of each edge under its (source, target) key, using the new node numbers -
    for (_, v) ∈ edgemodels
        source_index = nodeidmap[v.source]; # the new number of the source node
        target_index = nodeidmap[v.target]; # the new number of the target node
        edges[(source_index, target_index)] = v.weight;
    end

    # number the edges 1, 2, ..., m. We scan every (source, target) pair in order, and give the next
    # edge number to each pair that is an edge: edgesinverse[edge number] = (source, target) -
    n = length(nodes); # the number of nodes
    edgecounter = 1;
    for source ∈ 1:n
        for target ∈ 1:n
            if haskey(edges, (source, target)) == true # is there an edge from source to target?
                edgesinverse[edgecounter] = (source, target);
                edgecounter += 1;
            end
        end
    end

    # find the children of each node: the targets of the edges that leave the node.
    # _children(...) is a private helper in Graphs.jl -
    for id ∈ list_of_node_ids
        newid = nodeidmap[id]; # the new number of this node
        node = nodes[newid];
        children[newid] = _children(edges, node.id);
    end


    # store the dictionaries in the graph model -
    graphmodel.nodes = nodes;
    graphmodel.edges = edges;
    graphmodel.edgesinverse = edgesinverse;
    graphmodel.children = children;

    # return the populated graph -
    return graphmodel;
end

"""
    build(edgemodel::Type{MyGraphEdgeModel}, data::NamedTuple) -> MyGraphEdgeModel

Build one edge of a graph. `MyGraphEdgeModels(...)` in Files.jl calls this method once for each
line of an edge file, and the graph `build(...)` method above turns the collection of edges into a
graph. This method copies the four values into the model. It fills in no defaults.

### Arguments
- `edgemodel::Type{MyGraphEdgeModel}`: the edge type to build.
- `data::NamedTuple`: the edge data. It must have the keys:
  - `id::Int64`: the edge id.
  - `source::Int64`: the id of the node where the edge starts.
  - `target::Int64`: the id of the node the edge points to.
  - `weight`: the weight of the edge, such as a distance or a cost. The edge model accepts any value,
    including `nothing` for an unweighted edge. The graph `build(...)` method needs a number.

### Returns
- `MyGraphEdgeModel`: the edge, with the fields `id`, `source`, `target`, and `weight`.

### Throws
- an error, if `data` lacks one of the four keys.

### Example
```julia
edge = build(MyGraphEdgeModel, (id = 1, source = 1, target = 2, weight = 3.0));
```
"""
function build(edgemodel::Type{MyGraphEdgeModel}, data::NamedTuple)::MyGraphEdgeModel

    # initialize -
    model = edgemodel(); # build an empty edge model; the fields are not set yet

    # get the values from the NamedTuple -
    id = data.id; # the edge id
    source = data.source; # the node where the edge starts
    target = data.target; # the node the edge points to
    weight = data.weight; # the weight of the edge

    # store the values in the model -
    model.id = id;
    model.source = source;
    model.target = target;
    model.weight = weight;

    # return the populated edge -
    return model
end

"""
    build(edgemodel::Type{MyConstrainedGraphEdgeModel}, data::NamedTuple) -> MyConstrainedGraphEdgeModel

Build one edge of a flow network: an edge with a weight and with lower and upper bounds on the
flow it carries. `MyConstrainedGraphEdgeModels(...)` in Files.jl calls this method once for each
line of an edge file. In the week 5 flow networks, each line gives the source, the target, the cost
per unit of flow (stored as the weight), and the two bounds. This method copies the six values into
the model. It fills in no defaults.

### Arguments
- `edgemodel::Type{MyConstrainedGraphEdgeModel}`: the edge type to build.
- `data::NamedTuple`: the edge data. It must have the keys:
  - `id::Int64`: the edge id.
  - `source::Int64`: the id of the node where the edge starts.
  - `target::Int64`: the id of the node the edge points to.
  - `weight::Union{Nothing, Number}`: the weight of the edge, such as the cost per unit of flow.
  - `lower::Union{Nothing, Number}`: the smallest flow the edge may carry (its lower capacity).
  - `upper::Union{Nothing, Number}`: the largest flow the edge may carry (its upper capacity).

### Returns
- `MyConstrainedGraphEdgeModel`: the edge, with the fields `id`, `source`, `target`, `lower`,
  `upper`, and `weight`.

### Throws
- an error, if `data` lacks one of the six keys.

### Example
```julia
edge = build(MyConstrainedGraphEdgeModel, (id = 1, source = 1, target = 2, weight = 0.0,
    lower = 0.0, upper = 4.0));
```
"""
function build(edgemodel::Type{MyConstrainedGraphEdgeModel}, data::NamedTuple)::MyConstrainedGraphEdgeModel

    # initialize -
    model = edgemodel(); # build an empty edge model; the fields are not set yet

    # get the values from the NamedTuple -
    id = data.id; # the edge id
    source = data.source; # the node where the edge starts
    target = data.target; # the node the edge points to
    lower = data.lower; # the smallest flow the edge may carry
    upper = data.upper; # the largest flow the edge may carry
    weight = data.weight; # the weight of the edge, e.g., the cost per unit of flow

    # store the values in the model -
    model.id = id;
    model.source = source;
    model.target = target;
    model.lower = lower;
    model.upper = upper;
    model.weight = weight;

    # return the populated edge -
    return model
end

"""
    build(modeltype::Type{MyDirectedBipartiteGraphModel}, data::NamedTuple) -> MyDirectedBipartiteGraphModel

Build a flow network: a directed graph with a source node, where flow enters, a sink node, where
flow leaves, and capacity bounds on every edge. The `maximumflow(...)` method in Graphs.jl and
`validate_flow(...)` in FlowValidation.jl read this model. `build_flow_graph(...)` in
FlowValidation.jl calls this method.

The method builds the graph part in the same five steps as the graph `build(...)` method above:
it renumbers the nodes `1, 2, …, n` in sorted order of their ids, stores each edge weight under
`(source, target)`, numbers the edges, and finds the children of each node. Then it adds:
- the capacity of each edge, the pair `(lower, upper)`, stored under `(source, target)`;
- the source and sink node ids, stored as given.

The capacity dictionary and the source and sink use the original node ids from the edge models.
The `nodes`, `edges`, `edgesinverse`, and `children` fields use the new numbers. The two agree
when the node ids are already `1, 2, …, n`, as in the week 5 edge files. `maximumflow(...)` reads
the capacity keys as row and column numbers of an `n × n` matrix, so it needs ids `1, 2, …, n`.

The method does not set the fields `left` and `right`. Reading either field stops with an
`UndefRefError`.

### Arguments
- `modeltype::Type{MyDirectedBipartiteGraphModel}`: the model type to build.
- `data::NamedTuple`: the network data. It must have the keys:
  - `s::Int64`: the id of the source node.
  - `t::Int64`: the id of the sink node.
  - `edges::Dict{Int, MyConstrainedGraphEdgeModel}`: the edges, keyed by edge id. The course reads
    them from a file with `MyConstrainedGraphEdgeModels(...)`.

### Returns
- `MyDirectedBipartiteGraphModel`: the network, with the fields
  - `nodes::Dict{Int64, MyGraphNodeModel}`: node number => node model.
  - `edges::Dict{Tuple{Int64, Int64}, Number}`: `(source, target)` => edge weight.
  - `edgesinverse::Dict{Int, Tuple{Int, Int}}`: edge number => `(source, target)`.
  - `children::Dict{Int64, Set{Int64}}`: node number => the set of its children.
  - `capacity::Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}`: `(source, target)` => `(lower, upper)`.
  - `source::Int64` and `sink::Int64`: the source and sink node ids.

### Throws
- a `MethodError`, if an edge has `nothing` as its weight, its lower bound, or its upper bound,
  because the `edges` and `capacity` dictionaries hold only numbers.
- an error, if `data` lacks one of the three keys.

### Example
```julia
edges = Dict{Int, MyConstrainedGraphEdgeModel}();
edges[1] = build(MyConstrainedGraphEdgeModel, (id = 1, source = 1, target = 2, weight = 0.0, lower = 0.0, upper = 5.0));
edges[2] = build(MyConstrainedGraphEdgeModel, (id = 2, source = 2, target = 3, weight = 0.0, lower = 0.0, upper = 3.0));
network = build(MyDirectedBipartiteGraphModel, (s = 1, t = 3, edges = edges));
network.capacity[(2, 3)]   # (0.0, 3.0)
```
"""
function build(modeltype::Type{MyDirectedBipartiteGraphModel}, data::NamedTuple)::MyDirectedBipartiteGraphModel

    # initialize: an empty model, and the empty dictionaries we fill below -
    model = modeltype(); # build an empty model; the fields are not set yet
    nodes = Dict{Int64, MyGraphNodeModel}(); # node number => node model
    edges = Dict{Tuple{Int64, Int64}, Number}(); # (source, target) => edge weight
    children = Dict{Int64, Set{Int64}}(); # node number => the set of its children
    edgesinverse = Dict{Int, Tuple{Int, Int}}(); # edge number => (source, target)
    capacity = Dict{Tuple{Int64, Int64}, Tuple{Number, Number}}(); # (source, target) => (lower, upper)

    # get the values from the NamedTuple -
    sid = data.s; # source node index
    tid = data.t; # target node index
    edgemodels = data.edges; # edges dictionary

    # collect the id of every node that appears at either end of an edge. A Set keeps each id only once -
    tmp_node_ids = Set{Int64}();
    for (_,v) ∈ edgemodels # each entry is a pair key => value; (_, v) unpacks it, and _ means we ignore the key
        push!(tmp_node_ids, v.source);
        push!(tmp_node_ids, v.target);
    end
    list_of_node_ids = tmp_node_ids |> collect |> sort; # |> passes the value along: collect turns the Set into a Vector, and sort orders it

    # renumber the nodes 1, 2, ..., n in sorted order: nodeidmap[original id] = new number -
    nodeidmap = Dict{Int64, Int64}();
    nodecounter = 1;
    for id ∈ list_of_node_ids
        nodeidmap[id] = nodecounter;
        nodecounter += 1; # short for nodecounter = nodecounter + 1
    end

    # build one node model for each node. The comprehension runs the assignment once for each id;
    # Julia throws away the array that the brackets build (see the graph build method above) -
    [nodes[nodeidmap[id]] = MyGraphNodeModel(nodeidmap[id], nothing) for id ∈ list_of_node_ids];

    # store the weight of each edge under its (source, target) key, using the new node numbers -
    for (_, v) ∈ edgemodels
        source_index = nodeidmap[v.source]; # the new number of the source node
        target_index = nodeidmap[v.target]; # the new number of the target node
        edges[(source_index, target_index)] = v.weight;
    end

    # number the edges 1, 2, ..., m. We scan every (source, target) pair in order, and give the next
    # edge number to each pair that is an edge: edgesinverse[edge number] = (source, target) -
    n = length(nodes); # the number of nodes
    edgecounter = 1;
    for source ∈ 1:n
        for target ∈ 1:n
            if haskey(edges, (source, target)) == true # is there an edge from source to target?
                edgesinverse[edgecounter] = (source, target);
                edgecounter += 1;
            end
        end
    end

    # find the children of each node: the targets of the edges that leave the node.
    # _children(...) is a private helper in Graphs.jl -
    for id ∈ list_of_node_ids
        newid = nodeidmap[id]; # the new number of this node
        node = nodes[newid];
        children[newid] = _children(edges, node.id);
    end

    # build the capacity dictionary: (lower, upper) bounds of each edge. This loop keys the
    # dictionary by the ORIGINAL node ids of the edge model, not by the new node numbers -
    for (_, edge) ∈ edgemodels
        s = edge.source; # the original id of the source node
        t = edge.target; # the original id of the target node
        capacity[(s, t)] = (edge.lower, edge.upper);
    end

    # store everything in the model. The fields left and right stay unset -
    model.nodes = nodes;
    model.edges = edges;
    model.edgesinverse = edgesinverse;
    model.children = children;
    model.capacity = capacity;
    model.source = sid; # the source node id, as given
    model.sink = tid; # the sink node id, as given

    # return the populated network -
    return model
end
# -- GRAPH METHODS ABOVE HERE ------------------------------------------------------------------------------------------- #

# -- MDP AND GRID WORLD METHODS BELOW HERE ------------------------------------------------------------------------------ #
"""
    build(model::Type{MyMDPProblemModel}, data::NamedTuple) -> MyMDPProblemModel

Build a Markov decision process (MDP) model from its five parts `(𝒮, 𝒜, T, R, γ)`. An MDP
describes an agent that is in a state `s`, takes an action `a`, collects the reward `R(s, a)`, and
moves to the next state `s′` with probability `T(s′ | s, a)`. The discount factor `γ` is the
weight of a reward one step in the future, relative to the same reward now.

Every key is optional. A missing key gets a placeholder:
- `𝒮` and `𝒜`: a vector with one entry whose value is not set;
- `T`: a `1×1×1` array whose value is not set;
- `R`: a `1×1` array whose value is not set;
- `γ`: the value `0.1`.
A value that is not set holds whatever bits were in memory, so it means nothing. We pass every key
when we build a model that we plan to solve.

### Arguments
- `model::Type{MyMDPProblemModel}`: the model type to build.
- `data::NamedTuple`: the parts of the MDP. The keys are:
  - `𝒮::Array{Int64,1}`: the states, numbered `1, 2, …, |𝒮|`.
  - `𝒜::Array{Int64,1}`: the actions, numbered `1, 2, …, |𝒜|`.
  - `T::Array{Float64,3}`: the transition probabilities. The entry `T[s, s′, a]` is the probability
    of moving from state `s` to state `s′` when we take action `a`. The field also accepts a function,
    but the package's MDP methods read `T` as an array.
  - `R::Array{Float64,2}`: the rewards. The entry `R[s, a]` is the reward for taking action `a` in
    state `s`. The field also accepts a function, but the package's MDP methods read `R` as an array.
  - `γ::Float64`: the discount factor, between 0 and 1.

### Returns
- `MyMDPProblemModel`: the model, with the fields `𝒮`, `𝒜`, `T`, `R`, and `γ`.

### Example
```julia
m = build(MyMDPProblemModel, (𝒮 = [1, 2], 𝒜 = [1, 2], T = ones(2, 2, 2) / 2, R = zeros(2, 2), γ = 0.9));
```
"""
function build(model::Type{MyMDPProblemModel}, data::NamedTuple)::MyMDPProblemModel

    # build an empty model -
    m = model(); # the empty constructor; the fields are not set yet

    # copy each part of the MDP from the NamedTuple. Each line uses the form cond ? a : b, which means
    # "if cond is true, do a; otherwise do b". Here: if data has no such key, store a placeholder;
    # otherwise, store the value from data. data[:𝒮] is the same as data.𝒮, and :𝒮 is the key name
    # written as a Symbol. Array{Int64,1}(undef,1) is a vector with one entry whose value is not set -
    haskey(data, :𝒮) == false ? m.𝒮 = Array{Int64,1}(undef,1) : m.𝒮 = data[:𝒮]; # the states
    haskey(data, :𝒜) == false ? m.𝒜 = Array{Int64,1}(undef,1) : m.𝒜 = data[:𝒜]; # the actions
    haskey(data, :T) == false ? m.T = Array{Float64,3}(undef,1,1,1) : m.T = data[:T]; # the transition probabilities T[s, s′, a]
    haskey(data, :R) == false ? m.R = Array{Float64,2}(undef,1,1) : m.R = data[:R]; # the rewards R[s, a]
    haskey(data, :γ) == false ? m.γ = 0.1 : m.γ = data[:γ]; # the discount factor; 0.1 when data has none

    # return the populated model -
    return m;
end

"""
    build(modeltype::Type{MyRectangularGridWorldModel}, data::NamedTuple) -> MyRectangularGridWorldModel

Build a rectangular grid world: a grid of `nrows × ncols` squares that an agent moves across, one
square per step. Each square `(i, j)` is a state, where `i` runs from 1 to `nrows` and `j` runs from
1 to `ncols`. The method fills in four dictionaries:
- `states`: square `(i, j)` => state number. The method numbers the squares row by row, so the
  square `(i, j)` gets the state number `s = (i − 1)⋅ncols + j`.
- `coordinates`: state number => square `(i, j)`, the inverse of `states`.
- `rewards`: state number => reward. A square listed in the `rewards` key gets its listed reward;
  every other square gets `defaultreward`.
- `moves`: action => change in `(i, j)`. Action 1 is `(−1, 0)`, action 2 is `(1, 0)`, action 3 is
  `(0, −1)`, and action 4 is `(0, 1)`. The course notebooks read a square `(i, j)` as the point
  `(x, y)`, so the four actions move left, right, down, and up.

### Arguments
- `modeltype::Type{MyRectangularGridWorldModel}`: the model type to build.
- `data::NamedTuple`: the grid data. It must have the keys:
  - `nrows::Int`: the number of rows, the largest value of the first coordinate `i`.
  - `ncols::Int`: the number of columns, the largest value of the second coordinate `j`.
  - `rewards::Dict{Tuple{Int,Int},Float64}`: square `(i, j)` => reward, for the squares whose reward
    differs from the default, such as a goal or a hazard.
  It may also have the key:
  - `defaultreward::Float64`: the reward of every square that is not in `rewards`. The default is `-1.0`.

### Returns
- `MyRectangularGridWorldModel`: the grid world, with the fields `states`, `coordinates`, `rewards`,
  `moves`, `number_of_rows` (equal to `nrows`), and `number_of_cols` (equal to `ncols`).

### Throws
- an error, if `data` lacks `nrows`, `ncols`, or `rewards`.

### Example
```julia
world = build(MyRectangularGridWorldModel, (nrows = 3, ncols = 3, rewards = Dict((3, 3) => 10.0)));
world.states[(3, 3)]   # 9, the state number of the square (3, 3)
world.rewards[9]       # 10.0
world.rewards[1]       # -1.0, the default reward
```
"""
function build(modeltype::Type{MyRectangularGridWorldModel}, data::NamedTuple)::MyRectangularGridWorldModel

    # initialize an empty model -
    model = modeltype() # the empty constructor; the fields are not set yet

    # get the values from the NamedTuple -
    nrows = data[:nrows] # the number of rows; data[:nrows] is the same as data.nrows
    ncols = data[:ncols] # the number of columns
    rewards = data[:rewards] # square (i, j) => reward, for the special squares
    defaultreward = haskey(data, :defaultreward) == false ? -1.0 : data[:defaultreward] # if data has no defaultreward, use -1.0; otherwise use data's value

    # set up the empty dictionaries we fill below -
    rewards_dict = Dict{Int,Float64}() # state number => reward
    coordinates = Dict{Int,Tuple{Int,Int}}() # state number => square (i, j)
    states = Dict{Tuple{Int,Int},Int}() # square (i, j) => state number
    moves = Dict{Int,Tuple{Int,Int}}() # action => change in (i, j)

    # visit the squares row by row, give each square the next state number, and set its reward -
    position_index = 1; # the state number of the next square
    for i ∈ 1:nrows
        for j ∈ 1:ncols

            # the square we are visiting -
            coordinate = (i,j);

            # record the square in both directions: state number => square, and square => state number -
            coordinates[position_index] = coordinate;
            states[coordinate] = position_index;

            # set the reward: the listed reward if the square has one, otherwise the default reward -
            if (haskey(rewards,coordinate) == true)
                rewards_dict[position_index] = rewards[coordinate];
            else
                rewards_dict[position_index] = defaultreward;
            end

            # move on to the next state number -
            position_index += 1;
        end
    end

    # set up the moves dictionary: the change in (i, j) for each action. The course notebooks read (i, j) as (x, y) -
    moves[1] = (-1,0)   # a = 1: i decreases by 1 (left)
    moves[2] = (1,0)    # a = 2: i increases by 1 (right)
    moves[3] = (0,-1)   # a = 3: j decreases by 1 (down)
    moves[4] = (0,1)    # a = 4: j increases by 1 (up)

    # store everything in the model -
    model.rewards = rewards_dict
    model.coordinates = coordinates
    model.states = states;
    model.moves = moves;
    model.number_of_rows = nrows
    model.number_of_cols = ncols

    # return the populated grid world -
    return model
end
# -- MDP AND GRID WORLD METHODS ABOVE HERE ------------------------------------------------------------------------------ #

# -- BANDIT METHODS BELOW HERE ------------------------------------------------------------------------------------------ #
"""
    build(modeltype::Type{MyEpsilonGreedyAlgorithmModel}, data::NamedTuple) -> MyEpsilonGreedyAlgorithmModel

Build an epsilon-greedy bandit algorithm model. A multi-armed bandit is a repeated choice among `K`
options, called arms. Each pull of an arm pays a random reward from that arm's own distribution,
which we do not know. The epsilon-greedy algorithm pulls each arm once. Then, in each round `t`, it
pulls a random arm with probability `ϵₜ`, which shrinks as `t` grows, and otherwise pulls the arm
with the best average reward so far. The `solve(...)` method in Bandit.jl runs the algorithm. We pass the number of rounds
and the reward function to `solve(...)`. The model stores only `K`.

### Arguments
- `modeltype::Type{MyEpsilonGreedyAlgorithmModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the key:
  - `K::Int64`: the number of arms.

### Returns
- `MyEpsilonGreedyAlgorithmModel`: the model, with the field `K`.

### Throws
- an error, if `data` lacks the key `K`.

### Example
```julia
model = build(MyEpsilonGreedyAlgorithmModel, (K = 3,));   # the comma makes (K = 3,) a NamedTuple
```
"""
function build(modeltype::Type{MyEpsilonGreedyAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build an empty model, and store K -
    model = modeltype(); # the empty constructor; the field K is not set yet
    model.K = K;

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyExploreFirstAlgorithmModel}, data::NamedTuple) -> MyExploreFirstAlgorithmModel

Build an explore-first bandit algorithm model. A multi-armed bandit is a repeated choice among `K`
options, called arms. Each pull of an arm pays a random reward from that arm's own distribution,
which we do not know. The explore-first algorithm pulls every arm the same fixed number of times,
and then pulls the arm with the best average reward for all the remaining rounds. The `solve(...)`
method in Bandit.jl runs the algorithm. We pass the number of rounds and the reward function to
`solve(...)`. The model stores only `K`.

### Arguments
- `modeltype::Type{MyExploreFirstAlgorithmModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the key:
  - `K::Int64`: the number of arms.

### Returns
- `MyExploreFirstAlgorithmModel`: the model, with the field `K`.

### Throws
- an error, if `data` lacks the key `K`.

### Example
```julia
model = build(MyExploreFirstAlgorithmModel, (K = 3,));   # the comma makes (K = 3,) a NamedTuple
```
"""
function build(modeltype::Type{MyExploreFirstAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build an empty model, and store K -
    model = modeltype(); # the empty constructor; the field K is not set yet
    model.K = K;

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyUCB1AlgorithmModel}, data::NamedTuple) -> MyUCB1AlgorithmModel

Build a UCB1 bandit algorithm model. A multi-armed bandit is a repeated choice among `K` options,
called arms. Each pull of an arm pays a random reward from that arm's own distribution, which we do
not know. The UCB1 (upper confidence bound) algorithm pulls each arm once, and then, in each round
`t`, pulls the arm with the largest score `μᵢ + √(2⋅ln t / Nᵢ)`, where `μᵢ` is the average reward
of arm `i` so far and `Nᵢ` is the number of times we have pulled it. The `solve(...)` method in
Bandit.jl runs the algorithm. We pass the number of rounds and the reward function to `solve(...)`.
The model stores only `K`.

### Arguments
- `modeltype::Type{MyUCB1AlgorithmModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the key:
  - `K::Int64`: the number of arms.

### Returns
- `MyUCB1AlgorithmModel`: the model, with the field `K`.

### Throws
- an error, if `data` lacks the key `K`.

### Example
```julia
model = build(MyUCB1AlgorithmModel, (K = 3,));   # the comma makes (K = 3,) a NamedTuple
```
"""
function build(modeltype::Type{MyUCB1AlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # number of arms

    # build an empty model, and store K -
    model = modeltype(); # the empty constructor; the field K is not set yet
    model.K = K;

    # return the populated model -
    return model;
end
# -- BANDIT METHODS ABOVE HERE ------------------------------------------------------------------------------------------ #

# -- ONLINE LEARNING METHODS BELOW HERE --------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel}, data::NamedTuple) -> MyBinaryWeightedMajorityAlgorithmModel

Build a binary weighted majority algorithm model. In each round, `n` experts each predict an
outcome, `−1` or `1`. The algorithm predicts the outcome that has the larger total weight of experts
behind it. After the adversary reveals the actual outcome, each expert that predicted wrong loses
the fraction `ϵ` of its weight: `w ← w⋅(1 − ϵ)`. The `play(...)` method in Online.jl runs the rounds.

The method stores the five values from `data` and fills in one derived field:
- `weights = ones(T + 1, n)`: the weight table. Row `t` holds the weights of the `n` experts at the
  start of round `t`. Row 1 is all ones, so every expert starts with weight 1. `play(...)` writes
  rows 2 to `T + 1` into this same table.

### Arguments
- `modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the keys:
  - `ϵ::Float64`: the learning rate, between 0 and 1: the fraction of its weight an expert loses after
    a wrong prediction.
  - `n::Int64`: the number of experts.
  - `T::Int64`: the number of rounds.
  - `expert::Function`: the experts. `play(...)` calls it as `expert(i, t, data)`, and it returns the
    prediction of expert `i` in round `t`, `−1` or `1`. The argument `data` is the data matrix passed to `play(...)`.
  - `adversary::Function`: the adversary. `play(...)` calls it as `adversary(t, data)`, and it returns
    the actual outcome of round `t`, `−1` or `1`.

### Returns
- `MyBinaryWeightedMajorityAlgorithmModel`: the model, with the fields `ϵ`, `n`, `T`, `expert`,
  `adversary`, and `weights` (a `(T + 1) × n` matrix of ones).

### Throws
- an error, if `data` lacks one of the five keys.
"""
function build(modeltype::Type{MyBinaryWeightedMajorityAlgorithmModel},
    data::NamedTuple)::MyBinaryWeightedMajorityAlgorithmModel

    # build an empty model, and get the values from the NamedTuple -
    model = modeltype(); # build an empty model; the fields are not set yet
    ϵ = data.ϵ; # learning rate
    n = data.n; # number of experts
    T = data.T; # number of rounds
    expert = data.expert; # expert function
    adversary = data.adversary; # adversary function

    # store the values in the model, and build the weight table -
    model.ϵ = ϵ;
    model.n = n;
    model.T = T;
    model.expert = expert;
    model.adversary = adversary;
    model.weights = ones(Float64, T+1, n) # the weight table: T+1 rows (one per round, plus the start) and n columns (one per expert), all ones

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyTwoPersonZeroSumGameModel}, data::NamedTuple) -> MyTwoPersonZeroSumGameModel

Build a two-person zero-sum game model. Two players each choose an action in every round. The
payoff matrix `M` gives the row player's payoff `M[i, j]` when the row player chooses action `i`
and the column player chooses action `j`. The column player loses what the row player wins, which
is why the game is called zero-sum. The `play(...)` method in Online.jl runs the game with the
multiplicative weights algorithm. Each of the row player's `n` actions is an expert with a weight.
After each round, the weight of action `i` is multiplied by `exp(−ϵ⋅ℓᵢ)`, where `ℓᵢ` is the loss of
action `i` in that round.

The method stores the four values from `data` and fills in one derived field:
- `weights`: the weight table, a `(T + 1) × n` matrix. Row `t` holds the weights of the `n` actions at
  the start of round `t`. Row 1 holds random numbers between 0 and 1, drawn with `rand(n)` from
  Julia's global random number generator; the other rows start at zero. `play(...)` writes rows 2 to
  `T + 1`. Two builds give different starting weights unless we call `Random.seed!(...)` with the
  same seed before each one.

### Arguments
- `modeltype::Type{MyTwoPersonZeroSumGameModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the keys:
  - `ϵ::Float64`: the learning rate of the multiplicative weights update.
  - `n::Int`: the number of actions of the row player (the experts).
  - `T::Int`: the number of rounds.
  - `payoffmatrix::Array{Float64,2}`: the payoff matrix `M`, one row per row-player action and one
    column per column-player action.

### Returns
- `MyTwoPersonZeroSumGameModel`: the model, with the fields `ϵ`, `n`, `T`, `payoffmatrix`, and `weights`.

### Throws
- an error, if `data` lacks one of the four keys.

### Example
```julia
model = build(MyTwoPersonZeroSumGameModel, (ϵ = 0.1, n = 2, T = 100, payoffmatrix = [1.0 -1.0; -1.0 1.0]));
size(model.weights)   # (101, 2)
```
"""
function build(modeltype::Type{MyTwoPersonZeroSumGameModel},
    data::NamedTuple)::MyTwoPersonZeroSumGameModel

    # build an empty model, and get the values from the NamedTuple -
    model = modeltype(); # build an empty model; the fields are not set yet
    ϵ = data.ϵ; # learning rate
    n = data.n; # number of experts (actions)
    T = data.T; # number of rounds
    payoffmatrix = data.payoffmatrix; # payoff matrix

    # store the values in the model, and build the weight table -
    model.ϵ = ϵ;
    model.n = n;
    model.T = T;
    model.payoffmatrix = payoffmatrix;
    model.weights = zeros(Float64, T+1, n) # the weight table: T+1 rows (one per round, plus the start) and n columns (one per action), all zeros

    # fill the first row with random starting weights. rand(n) draws n numbers between 0 and 1 from the global random number generator -
    model.weights[1, :] = rand(n); # [1, :] means row 1, every column

    # return the populated model -
    return model;
end
# -- ONLINE LEARNING METHODS ABOVE HERE --------------------------------------------------------------------------------- #

# -- CONTEXTUAL BANDIT METHODS BELOW HERE ------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}, data::NamedTuple) -> MyBinaryVectorArmsEpsilonGreedyAlgorithmModel

Build an epsilon-greedy bandit model whose arms are binary vectors. We choose which of `K` goods to
buy. An arm is a vector of `K` entries, each `0` (do not buy the good) or `1` (buy it), so there are
`2ᴷ` arms. The contextual `solve(model, context; ...)` method in Bandit.jl runs the algorithm with a
`MyConsumerChoiceBanditContextModel`. The model stores only `K`.

### Arguments
- `modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the key:
  - `K::Int64`: the number of goods. `solve(...)` builds `2ᴷ` arms from it, one per bundle of goods.

### Returns
- `MyBinaryVectorArmsEpsilonGreedyAlgorithmModel`: the model, with the field `K`.

### Throws
- an error, if `data` lacks the key `K`.

### Example
```julia
model = build(MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, (K = 3,));   # 3 goods, so 2^3 = 8 arms
```
"""
function build(modeltype::Type{MyBinaryVectorArmsEpsilonGreedyAlgorithmModel}, data::NamedTuple)

    # initialize -
    K = data.K; # the number of goods; there are 2^K arms

    # build an empty model, and store K -
    model = modeltype(); # the empty constructor; the field K is not set yet
    model.K = K;

    # return the populated model -
    return model;
end

"""
    build(modeltype::Type{MyConsumerChoiceBanditContextModel}, data::NamedTuple) -> MyConsumerChoiceBanditContextModel

Build the context of a consumer-choice bandit problem: the data about the goods, the budget, and the
starting estimates that the contextual `solve(...)` method in Bandit.jl and our `world` function use.
An arm is a binary vector that says which of the `K` goods to buy (see the method above). Of these
values, `solve(...)` itself reads only `μₒ`. It passes the whole context to the `world` function,
which reads the others. The method copies the seven values into the model. It fills in no defaults.

### Arguments
- `modeltype::Type{MyConsumerChoiceBanditContextModel}`: the model type to build.
- `data::NamedTuple`: the context data. It must have the keys:
  - `data::Dict{String, Any}`: the data about the goods, or more generally the context, in a
    dictionary that the `world` function reads.
  - `items::Array{String,1}`: the names of the goods.
  - `bounds::Array{Float64,2}`: the bounds on how much of each good we can buy.
  - `B::Float64`: the budget we can spend on the whole purchase.
  - `nₒ::Array{Float64,1}`: an initial guess for the quantity of each good.
  - `μₒ::Array{Float64,1}`: the initial average reward of each arm, one entry per arm (`2ᴷ` entries).
  - `γ::Array{Float64,1}`: the preference parameters of the utility function.

### Returns
- `MyConsumerChoiceBanditContextModel`: the context, with the fields `data`, `items`, `bounds`, `B`,
  `nₒ`, `μₒ`, and `γ`, copied from `data`.

### Throws
- an error, if `data` lacks one of the seven keys.
"""
function build(modeltype::Type{MyConsumerChoiceBanditContextModel},
    data::NamedTuple)::MyConsumerChoiceBanditContextModel

    # get the values from the NamedTuple -
    contextdata = data.data; # data dictionary for each item, or more generally the context
    items = data.items; # items for each asset
    bounds = data.bounds; # bounds on the assets that we can purchase
    B = data.B; # budget that we have to spend on the collection of assets
    nₒ = data.nₒ; # initial guess for the solution
    μₒ = data.μₒ; # initial for the utility of each arm
    γ = data.γ; # parameters for the utility function (preferences)

    # build an empty model, and store the values -
    model = modeltype(); # the empty constructor; the fields are not set yet
    model.data = contextdata;
    model.items = items;
    model.bounds = bounds;
    model.B = B;
    model.nₒ = nₒ;
    model.μₒ = μₒ;
    model.γ = γ;

    # return the populated context -
    return model;
end
# -- CONTEXTUAL BANDIT METHODS ABOVE HERE ------------------------------------------------------------------------------- #

# -- Q-LEARNING METHODS BELOW HERE -------------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyQLearningAgentModel}, data::NamedTuple) -> MyQLearningAgentModel

Build a Q-learning agent. The agent keeps a table `Q` of action values: `Q[s, a]` estimates the
total discounted reward of taking action `a` in state `s` and acting well after that. The `solve(...)`
method in QLearning.jl starts from this table and updates it as the agent explores.

The method fills the agent with the fieldnames loop described in the file header. For each field of
`MyQLearningAgentModel`, in the order `states`, `actions`, `γ`, `α`, `Q`, it copies the value with
the same name from `data`. Every field is required, and the method fills in no defaults. Keys in
`data` that are not field names are ignored. An empty NamedTuple, `NamedTuple()`, skips the loop and
returns an agent with no fields set.

### Arguments
- `modeltype::Type{MyQLearningAgentModel}`: the model type to build.
- `data::NamedTuple`: the agent data. It must have the keys:
  - `states::Array{Int64,1}`: the states, numbered `1, 2, …, |𝒮|`.
  - `actions::Array{Int64,1}`: the actions, numbered `1, 2, …, |𝒜|`.
  - `γ::Float64`: the discount factor, between 0 and 1.
  - `α::Float64`: the learning rate, between 0 and 1: the fraction of the way `Q[s, a]` moves toward
    each new target.
  - `Q::Array{Float64,2}`: the starting table of action values, one row per state and one column per
    action, for example `zeros(length(states), length(actions))`.

### Returns
- `MyQLearningAgentModel`: the agent, with the fields `states`, `actions`, `γ`, `α`, and `Q`.

### Throws
- `ArgumentError`, if `data` is not empty and lacks one of the five keys. The message names the
  missing key, for example `NamedTuple is missing: Q`.

### Example
```julia
agent = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 0.1, γ = 0.9,
    Q = zeros(3, 2)));
```
"""
function build(modeltype::Type{MyQLearningAgentModel}, data::NamedTuple)::MyQLearningAgentModel

    # initialize -
    model = MyQLearningAgentModel(); # an empty agent; the fields are not set yet

    # copy each field from the NamedTuple with the fieldnames loop (see the file header).
    # An empty NamedTuple skips the loop -
    if (isempty(data) == false)

        for key ∈ fieldnames(modeltype) # key is each field name in turn: :states, :actions, :γ, :α, :Q

            # convert the field name from a Symbol (:states) to a String ("states") for the error message -
            field_name_string = string(key)

            # stop with an error if data has no entry for this field -
            if (haskey(data, key) == false)
                throw(ArgumentError("NamedTuple is missing: $(field_name_string)"))
            end

            # get the value stored under this name -
            value = data[key]

            # store the value in the field; this is the same as model.states = value when key is :states -
            setproperty!(model, key, value)
        end
    end

    # return the populated agent -
    return model
end
# -- Q-LEARNING METHODS ABOVE HERE -------------------------------------------------------------------------------------- #

# -- HOPFIELD METHODS BELOW HERE ---------------------------------------------------------------------------------------- #
"""
    build(modeltype::Type{MyClassicalHopfieldNetworkModel}, data::NamedTuple) -> MyClassicalHopfieldNetworkModel

Build a classical Hopfield network that stores a set of memories. A memory is a pattern, such as a
black-and-white image, written as a column of `N` entries, each `−1` or `1`. The method computes
three things:
- the weight matrix by the Hebbian rule, `W = (1/N)⋅Σⱼ x⁽ʲ⁾⋅x⁽ʲ⁾ᵀ`, where `x⁽ʲ⁾` is memory `j`,
  `x⁽ʲ⁾⋅x⁽ʲ⁾ᵀ` is its `N × N` outer product, and the sum runs over the memories. The method sets the
  diagonal to zero, `Wᵢᵢ = 0`, so no entry is coupled to itself.
- the bias vector `b`, all zeros.
- the energy of each memory, `E(x) = −½⋅Σᵢ Σₖ Wᵢₖ⋅xᵢ⋅xₖ − bᵀx`, computed by the private helper
  `_energy(...)` in Hopfield.jl. The `recover(...)` method in Hopfield.jl takes an energy value,
  such as one of these, and stops once the energy of its state is at or below that value.

### Arguments
- `modeltype::Type{MyClassicalHopfieldNetworkModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the key:
  - `memories::Array{<:Number,2}`: the memory matrix, `N` rows (one per entry, such as one per pixel)
    and one column per memory, with entries `−1` or `1`.

### Returns
- `MyClassicalHopfieldNetworkModel`: the network, with the fields
  - `W::Array{Float64,2}`: the `N × N` weight matrix. Its numbers are `Float64` because the scale
    factor `1/N` is a `Float64`.
  - `b::Array{Float32,1}`: the bias vector, `N` zeros.
  - `memories`: a copy of the memory matrix, one memory per column.
  - `energy::Dict{Int64, Float32}`: memory number `j` => the energy of memory `j`.

### Throws
- an error, if `data` lacks the key `memories`.

### Example
```julia
X = [1 -1; -1 1; 1 1; -1 -1];   # N = 4 entries, 2 memories (one per column)
model = build(MyClassicalHopfieldNetworkModel, (memories = X,));
size(model.W)   # (4, 4)
```
"""
function build(modeltype::Type{MyClassicalHopfieldNetworkModel}, data::NamedTuple)::MyClassicalHopfieldNetworkModel

    # initialize -
    model = modeltype(); # the empty constructor; the fields are not set yet
    linearimagecollection = data.memories; # the memories, one per column
    number_of_rows, number_of_cols = size(linearimagecollection); # N entries per memory, and the number of memories
    W = zeros(Float32, number_of_rows, number_of_rows); # the N × N weight matrix, all zeros to start
    b = zeros(Float32, number_of_rows); # zero bias for classical Hopfield

    # compute W: add up the outer product x⋅xᵀ of each memory x (the Hebbian rule) -
    for j ∈ 1:number_of_cols
        Y = ⊗(linearimagecollection[:,j], linearimagecollection[:,j]); # compute the outer product of column j with itself; ⊗ comes from the ColorVectorSpace package, and [:,j] means every row of column j
        W += Y; # short for W = W + Y
    end

    # no self-coupling and Hebbian scaling -
    for i ∈ 1:number_of_rows
        W[i,i] = 0.0f0; # no self-coupling in a classical Hopfield network; 0.0f0 is zero as a Float32
    end
    WN = (1/number_of_rows)*W; # scale the weights by 1/N, where N is the number of features (rows), to keep the energy landscape well-behaved and avoid numerical issues when we compute the energy

    # compute the energy of each memory: energy[j] is the energy of column j -
    energy = Dict{Int64, Float32}();
    for i ∈ 1:number_of_cols
        energy[i] = _energy(linearimagecollection[:,i], WN, b);
    end

    # store everything in the model -
    model.W = WN;
    model.b = b;
    model.memories = copy(linearimagecollection); # a copy, so a later change to our matrix does not change the model
    model.energy = energy;

    # return the populated network -
    return model;
end

"""
    build(modeltype::Type{MyModernHopfieldNetworkModel}, data::NamedTuple) -> MyModernHopfieldNetworkModel

Build a modern Hopfield network from its memories and its inverse temperature `β`. The `recover(...)`
method in Hopfield.jl uses the normalized memory matrix `X̂` and `β`. Each step computes the
probability vector `p = softmax(β⋅X̂ᵀ⋅s)`, one entry per memory, and moves the state to `s = X̂⋅p`.
A larger `β` puts more of the weight of `p` on the memory whose column has the largest dot product
with the state `s`. The method copies the three values into
the model. It fills in no defaults and does not compute or check the normalization.

### Arguments
- `modeltype::Type{MyModernHopfieldNetworkModel}`: the model type to build.
- `data::NamedTuple`: the model data. It must have the keys:
  - `memories::Array{<:Number,2}`: the memory matrix, one memory per column.
  - `normalized_memories::Array{<:Number,2}`: the memory matrix after we normalize it, the same size
    as `memories`. `recover(...)` uses this matrix.
  - `β::Number`: the inverse temperature, a positive number.

### Returns
- `MyModernHopfieldNetworkModel`: the network, with the fields `X` (from `memories`), `X̂` (from
  `normalized_memories`), and `β`.

### Throws
- an error, if `data` lacks one of the three keys.
"""
function build(modeltype::Type{MyModernHopfieldNetworkModel}, data::NamedTuple)::MyModernHopfieldNetworkModel

    # initialize -
    model = modeltype(); # the empty constructor; the fields are not set yet
    linearimagecollection = data.memories; # the memories, one per column
    normalized_linear_image_collection = data.normalized_memories; # the normalized memories, one per column
    β = data.β; # beta parameter (the inverse temperature)

    # store the values in the model -
    model.β = β;
    model.X = linearimagecollection;
    model.X̂ = normalized_linear_image_collection;

    # return the populated network -
    return model;
end
# --- HOPFIELD METHODS ABOVE HERE --------------------------------------------------------------------------------------- #

# -- UTILITY FUNCTION METHODS BELOW HERE -------------------------------------------------------------------------------- #
"""
    _build(modeltype::Type{T}, data::NamedTuple) -> T where T <: AbstractUtilityFunctionType

Build a utility function model by copying each of its fields from `data`. This is the private helper
behind `build(VLLinearUtilityFunction, data)`.

The method uses the fieldnames loop described in the file header. For each field of `modeltype`, it
looks for the key with the same name in `data`. If the key is there, the method stores its value. If
the key is missing, the method stores `nothing`. Keys in `data` that are not field names are ignored.
An empty NamedTuple, `NamedTuple()`, skips the loop and returns a model with no fields set.

### Arguments
- `modeltype::Type{T}`: the model type to build. `T` is any subtype of `AbstractUtilityFunctionType`.
- `data::NamedTuple`: the values of the fields, keyed by field name.

### Returns
- `T`: the model. Each field holds the value from `data`, or `nothing` if `data` lacks that key. With an empty `NamedTuple()`, the fields are left unset.
"""
function _build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractUtilityFunctionType

    # build an empty model -
    model = modeltype(); # the empty constructor; the fields are not set yet

    # copy each field from the NamedTuple with the fieldnames loop (see the file header).
    # An empty NamedTuple skips the loop -
    if (isempty(data) == false)
        for key ∈ fieldnames(modeltype) # key is each field name in turn, e.g. :α

            # look for the key. If data has it, use its value; otherwise, keep the value nothing -
            value = nothing
            if (haskey(data, key) == true)
                # get the value -
                value = data[key]
            end

            # store the value in the field; this is the same as model.α = value when key is :α -
            setproperty!(model, key, value)
        end
    end

    # return the populated model -
    return model
end

"""
    build(model::Type{VLLinearUtilityFunction}, data::NamedTuple) -> VLLinearUtilityFunction

Build a linear utility function, `U(x) = Σᵢ αᵢ⋅xᵢ`, where `xᵢ` is the amount of good `i` and the
weight `αᵢ` is how much one unit of good `i` is worth to us. The `evaluate(...)` and
`indifference(...)` methods in Indifference.jl read the weights. The method passes the work to the
private helper `_build(...)` above. If `data` is not empty and lacks the key `α`, the field `α` is set to `nothing`.

### Arguments
- `model::Type{VLLinearUtilityFunction}`: the model type to build.
- `data::NamedTuple`: the model data, with the key:
  - `α::Array{Float64,1}`: the utility weights, one per good.

### Returns
- `VLLinearUtilityFunction`: the utility function, with the field `α`.

### Example
```julia
U = build(VLLinearUtilityFunction, (α = [0.6, 0.4],));   # the comma makes a one-entry NamedTuple
```
"""
build(model::Type{VLLinearUtilityFunction}, data::NamedTuple)::VLLinearUtilityFunction = _build(model, data) # the short form f(x) = ... defines a one-line function
# -- UTILITY FUNCTION METHODS ABOVE HERE -------------------------------------------------------------------------------- #
