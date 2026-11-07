# =============================================================================
# CHEME 5800 | VLDataScienceMachineLearningPackage.jl: the module file
# =============================================================================
# This is the top file of the course package. Each notebook loads the package
# with `using VLDataScienceMachineLearningPackage`, and Julia then runs this file.
# The file does four things, in order:
#
#   1. It sets the paths to the package source folder and its data folder.
#   2. It loads the external Julia packages that the course code uses (`using`).
#   3. It reads in the course code, one file per topic (`include`).
#   4. It lists the names that a notebook can use directly (`export`).
#
# A name that is not exported can still be reached with the package name in
# front of it, e.g., VLDataScienceMachineLearningPackage._build(...).
# =============================================================================
module VLDataScienceMachineLearningPackage # everything up to the matching `end` belongs to this package

# ----------------------------------------------------------------------------------------------- #
# Paths (single definition for the merged package; see Decision 5 of the merge plan) -
# We define the two paths once here, and the files below use them to find the data files.
# pathof(@__MODULE__) is the full path of this file; dirname(...) keeps only its folder -
const _PATH_TO_SRC = dirname(pathof(@__MODULE__)); # the folder that holds this file (code/src)
const _PATH_TO_DATA = joinpath(_PATH_TO_SRC, "data"); # the data folder inside it (code/src/data)

# load external packages -
# `using PackageName` loads a package and makes its exported names available in this file -
using CSV # reads comma-separated (.csv) files; the dataset loaders in Files.jl use CSV.read(...)
using DataFrames # the DataFrame table type that the dataset loaders return
using FileIO # the general load(...) function for data files and image files (Files.jl)
using JLD2 # reads .jld2 files, a Julia data format (the stock-market dataset in Files.jl)
using JSON # reads .json files (the English word list in Files.jl)
using DataStructures # Queue and PriorityQueue for graph searches (Graphs.jl), CircularBuffer (Hopfield.jl)
using Distributions # the Categorical distribution, for random draws with given probabilities
using LinearAlgebra # norm, dot, diag, Diagonal, and qr for vector and matrix work
using Statistics # mean, for the average reward in regret(...) (Bandit.jl)
using JuMP # the optimization modeling language: Model, @variable, @objective, optimize! (Solvers.jl)
using GLPK # the GLPK linear-programming solver that JuMP calls
using ColorVectorSpace # arithmetic on colors; also the outer-product operator ⊗ (Hopfield build in Factory.jl)
using Colors # color types such as Gray, the pixel type of the handwritten-digit images
using Images # image-processing tools for arrays of pixels
using ImageIO # lets FileIO's load(...) read image files
using NNlib # the softmax function (the modern Hopfield network in Hopfield.jl)
using Distances # distance functions between vectors: hamming(...), which counts the entries that differ, in Hopfield.jl
using Optim # NelderMead, Fminbox, and optimize, for the minimization in indifference(...) (Indifference.jl)

# load my codes - order matters: types before factories before compute/solve routines -
# Types.jl must come first: the other files use its type names in their function signatures,
# and Julia must know a type before a signature can name it. Each file below then adds the
# functions of one course topic -
include("Types.jl"); # all abstract types (families) and data types of the package
include("Factory.jl"); # the build(...) methods that create and fill those types
include("Files.jl"); # dataset loaders (My...Dataset) and the edge-file readers MyGraphEdgeModels and MyConstrainedGraphEdgeModels
include("Compute.jl"); # tokenize, log_growth_matrix (L10b), and the Markov word generator functions (L11b)
include("TextRepresentation.jl"); # codepoint_hex: Unicode code points of characters (week 2, L2c)
include("GraphRepresentation.jl"); # edge lists, adjacency lists, and adjacency matrices (week 4, L4a)
include("ShortestPathAlgorithms.jl"); # WeightedEdge, dijkstra, and bellman_ford (week 4, L4c)
include("FlowValidation.jl"); # build a flow network from an edge file and check a flow (week 5, L5a)
include("LinearPrograms.jl"); # the fruit-allocation linear program (week 5, L5c)
include("FluxBalance.jl"); # flux balance analysis (week 6, L6b)
include("StacksQueues.jl"); # MyStack, MyQueue, and isbalanced (week 3, L3b)
include("Recursion.jl"); # iterative and recursive Fibonacci functions (weeks 2 and 3)
include("Graphs.jl"); # children, weight, walk, findshortestpath, and maximumflow (weeks 4 and 5)
include("Solvers.jl"); # solve(...) for iterative linear solvers (week 6) and for linear programs (week 5)
include("Eigen.jl"); # qriteration: eigenvalues and eigenvectors by QR iteration
include("Binary.jl"); # learn, classify, and confusion for binary classifiers (week 9)
include("MDP.jl"); # Markov decision process functions and value iteration (weeks 11 and 12)
include("Bandit.jl"); # solve(...) for multi-armed bandits and regret (week 10)
include("Online.jl"); # play(...) for the weighted majority algorithm (week 10, L10b) and zero-sum games
include("QLearning.jl"); # solve(...) for the Q-learning agent (week 12)
include("Hopfield.jl"); # recover(...) for Hopfield networks
include("Indifference.jl"); # evaluate and indifference for linear utility functions
# ----------------------------------------------------------------------------------------------- #

# Exports. `export name` lets a notebook write `name` instead of
# `VLDataScienceMachineLearningPackage.name`. The groups below follow the course topics -

# export data loading functions -
# Datasets: each function reads a data file and returns it ready to use -
export MyStringDecodeChallengeDataset; # the String Decode Challenge puzzle data: two test sets and a production set
export MyCommonSurnameDataset; # common surnames by country, as a DataFrame
export MyCommonForenameDataset; # common first names by country, as a DataFrame
export MyTrainingMarketDataSet; # the variables stored in the stock-price JLD2 file, as a Dict (the source of the L10b data; the file is not in this repository)
export MyKaggleHousingPricesDataset; # house sale prices, as a DataFrame (weeks 7 and 8, L7d and L8d)
export MyBanknoteAuthenticationDataset; # genuine and forged banknote measurements, as a DataFrame (week 9)
export MyEnglishLanguageVocabularyModel; # English words grouped by first letter (week 11, L11b)
export MyMNISTHandwrittenDigitImageDataset; # images of handwritten digits 0 to 9

# types -
# Abstract types -
# Families of types (see the header of Types.jl): a function written for a family accepts every member -
export AbstractTextRecordModel; # text: one record
export AbstractTextDocumentCorpusModel; # text: a collection of records
export AbstractPriceTreeModel; # price trees (no type belongs to this family yet)
export AbstractGraphModel; # graphs (weeks 4 and 5)
export AbstractGraphNodeModel; # graph nodes
export AbstractGraphEdgeModel; # graph edges
export AbstractGraphSearchAlgorithm; # shortest-path algorithm tags (week 4)
export AbstractGraphFlowAlgorithm; # maximum-flow algorithm tags (week 5)
export AbstractGraphTraversalAlgorithm; # traversal algorithm tags
export AbstractLinearSolverAlgorithm; # iterative linear solver tags (week 6)
export AbstractClassificationAlgorithm; # binary classifiers (week 9)
export AbstractLinearProgrammingProblemType; # linear programs (week 5)
export AbstractProcessModel; # Markov decision processes (weeks 11 and 12)
export AbstractWorldModel; # grid worlds (weeks 11 and 12)
export AbstractBanditAlgorithmModel; # multi-armed bandit algorithms (week 10)
export AbstractOnlineLearningModel; # online learning models (weeks 10 and 12)
export AbstractBanditProblemContextModel; # context data for bandit problems
export AbstractlHopfieldNetworkModel; # Hopfield networks (the name has an extra "l")
export AbstractUtilityFunctionType; # utility functions

# Concrete types -
# Linear programming (week 5, L5c) -
export MyLinearProgrammingProblemModel;
# Classification (week 9) -
export MyPerceptronClassificationModel, MyLogisticRegressionClassificationModel;
# Text records (no course notebook uses these) -
export MySarcasmRecordModel;
export MySarcasmRecordCorpusModel;
# Two dataset functions again; they are already exported above, and a second export does no harm -
export MyEnglishLanguageVocabularyModel;
export MyMNISTHandwrittenDigitImageDataset;

# Graphs (weeks 4 and 5): node, edge, and graph types, plus the edge-file readers MyGraphEdgeModels and MyConstrainedGraphEdgeModels (functions in Files.jl) -
export MyGraphNodeModel, MyGraphEdgeModel, MyGraphEdgeModels, MySimpleDirectedGraphModel, MySimpleUndirectedGraphModel, MyDirectedBipartiteGraphModel, MyConstrainedGraphEdgeModel, MyConstrainedGraphEdgeModels;
export DepthFirstSearchAlgorithm, BreadthFirstSearchAlgorithm; # traversal tags for walk(...)
export DijkstraAlgorithm, BellmanFordAlgorithm, FordFulkersonAlgorithm, EdmondsKarpAlgorithm # shortest-path tags (week 4) and maximum-flow tags (week 5)
# Iterative linear solvers (week 6) -
export JacobiMethod, GaussSeidelMethod, SuccessiveOverRelaxationMethod;
# Markov decision processes (weeks 11 and 12) -
export MyValueIterationModel, MyValueFunctionPolicy;
export MyRectangularGridWorldModel, MyMDPProblemModel;
# Multi-armed bandits (week 10) -
export MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel;
# Online learning: the weighted majority algorithm (week 10, L10b) and zero-sum games -
export MyBinaryWeightedMajorityAlgorithmModel, MyTwoPersonZeroSumGameModel;
# A bandit over yes/no shopping choices and its context data (no course notebook uses these) -
export MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, MyConsumerChoiceBanditContextModel;
# Q-learning (week 12) -
export MyQLearningAgentModel;
# Utility functions (no course notebook uses this) -
export VLLinearUtilityFunction;

# Hopfield Network types -
# Hopfield networks (no course notebook uses these) -
export MyClassicalHopfieldNetworkModel;
export MyModernHopfieldNetworkModel;

# methods -
# Functions used across several topics -
export tokenize; # text: turn a string into a vector of integer token codes (Compute.jl)
export build; # every topic: create and fill a model, build(Type, (...)) (Factory.jl)
# Graphs (weeks 4 and 5, Graphs.jl) -
export children; # the children of a node
export weight; # the weight of an edge
export walk; # visit the nodes in breadth-first or depth-first order
export findshortestpath; # shortest paths from a start node (week 4, L4d)
export maximumflow; # the maximum flow from a source to a sink (week 5)
# Solvers, eigenvalues, and stock growth -
export solve; # one name, many methods: linear programs, iterative linear solvers, bandits, value iteration, and Q-learning
export qriteration; # eigenvalues and eigenvectors by QR iteration (Eigen.jl)
export log_growth_matrix; # log growth rates of stock prices (Compute.jl; week 10, L10b)
# Classification (week 9, Binary.jl) -
export learn; # train a classifier on labeled data
export classify; # predict the labels of new data
export confusion; # the 2 × 2 confusion matrix of actual and predicted labels
# Markov word generator (week 11, L11b, Compute.jl) -
export vocabulary_transition_matrix; # letter-to-letter transition probabilities from a word list
export sample_words; # generate words from those transition probabilities

# L2c lecture material -
# Text representation (week 2, L2c) -
export codepoint_hex;

# L4a lecture material -
# Graph representations (week 4, L4a) -
export adjacency_list, adjacency_matrix, directed_density, read_weighted_edges, representation_report, vertex_ids;

# L4c lecture material -
# Shortest paths on a plain edge list (week 4, L4c) -
export WeightedEdge, bellman_ford, dijkstra, path_cost, reconstruct_path, weighted_edges;

# L5a lecture material -
# Maximum flow: build a flow network and check a flow (week 5, L5a) -
export build_flow_graph, parse_constrained_edge, validate_flow;

# L5c lecture material -
# Linear programming (week 5, L5c) -
export solve_fruit_problem;

# L6a lecture and L6b lab material -
# Flux balance analysis (week 6) -
export solve_flux_balance, check_flux_balance;

# week-03 stack, queue and recursion material -
# Stacks, queues, and balanced delimiters (week 3, L3b) -
export MyStack, MyQueue, isbalanced;

# Fibonacci numbers: iteration, recursion, and memoization (weeks 2 and 3) -
export fibonacci, fibonacci!, memoization_fibonacci!;
export iterative_fibonacci_report, recursive_fibonacci_report; # operation counts, used by the week 3 validation tests

# MDP and RL methods -
# Markov decision processes (weeks 11 and 12, MDP.jl) -
export lookahead; # the value of one action in one state, given the state values U
export backup; # the best lookahead value in one state
export Q; # the table of action values Q(s,a) from the state values U
export policy; # the greedy action in each state, from a Q table
export myrandpolicy; # a random action that keeps the agent on the grid (week 11, L11c)
export myrandstep; # one step: the next state and the reward (week 11, L11c)
export iterative_policy_evaluation; # the state values of a fixed policy
export greedy; # the greedy action and its value in one state

# bandit methods -
# Multi-armed bandits (week 10, Bandit.jl) -
export regret; # the regret of a bandit game, round by round

# Hopfield methods -
# Hopfield networks (Hopfield.jl) -
export recover; # recover a stored memory from a starting state

# WMA and MWA methods -
# Online learning (week 10, Online.jl) -
export play; # play the weighted majority algorithm (L10b) or a zero-sum game

# utility/choice methods -
# Utility functions (Indifference.jl) -
export evaluate; # the utility of a basket of goods
export indifference; # points of equal utility (an indifference curve)

end # module VLDataScienceMachineLearningPackage
