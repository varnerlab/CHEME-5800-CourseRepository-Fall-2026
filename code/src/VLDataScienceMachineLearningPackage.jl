module VLDataScienceMachineLearningPackage

# ----------------------------------------------------------------------------------------------- #
# Paths (single definition for the merged package; see Decision 5 of the merge plan) -
const _PATH_TO_SRC = dirname(pathof(@__MODULE__));
const _PATH_TO_DATA = joinpath(_PATH_TO_SRC, "data");

# load external packages -
using CSV
using DataFrames
using FileIO
using JLD2
using JSON
using DataStructures
using Distributions
using LinearAlgebra
using Statistics
using JuMP
using GLPK
using ColorVectorSpace
using Colors
using Images
using ImageIO
using NNlib
using Distances
using Optim

# load my codes - order matters: types before factories before compute/solve routines -
include(joinpath(_PATH_TO_SRC, "Types.jl"));
include(joinpath(_PATH_TO_SRC, "Factory.jl"));
include(joinpath(_PATH_TO_SRC, "Files.jl"));
include(joinpath(_PATH_TO_SRC, "Compute.jl"));
include(joinpath(_PATH_TO_SRC, "TextRepresentation.jl"));
include(joinpath(_PATH_TO_SRC, "GraphRepresentation.jl"));
include(joinpath(_PATH_TO_SRC, "ShortestPathAlgorithms.jl"));
include(joinpath(_PATH_TO_SRC, "FlowValidation.jl"));
include(joinpath(_PATH_TO_SRC, "LinearPrograms.jl"));
include(joinpath(_PATH_TO_SRC, "StacksQueues.jl"));
include(joinpath(_PATH_TO_SRC, "Recursion.jl"));
include(joinpath(_PATH_TO_SRC, "Graphs.jl"));
include(joinpath(_PATH_TO_SRC, "Solvers.jl"));
include(joinpath(_PATH_TO_SRC, "Eigen.jl"));
include(joinpath(_PATH_TO_SRC, "Binary.jl"));
include(joinpath(_PATH_TO_SRC, "MDP.jl"));
include(joinpath(_PATH_TO_SRC, "Bandit.jl"));
include(joinpath(_PATH_TO_SRC, "Online.jl"));
include(joinpath(_PATH_TO_SRC, "QLearning.jl"));
include(joinpath(_PATH_TO_SRC, "Hopfield.jl"));
include(joinpath(_PATH_TO_SRC, "Indifference.jl"));
# ----------------------------------------------------------------------------------------------- #

# export data loading functions -
export MyStringDecodeChallengeDataset;
export MyCommonSurnameDataset;
export MyCommonForenameDataset;
export MyTrainingMarketDataSet;
export MyKaggleHousingPricesDataset;
export MyBanknoteAuthenticationDataset;
export MyEnglishLanguageVocabularyModel;
export MyMNISTHandwrittenDigitImageDataset;

# types -
# Abstract types -
export AbstractTextRecordModel;
export AbstractTextDocumentCorpusModel;
export AbstractPriceTreeModel;
export AbstractGraphModel;
export AbstractGraphNodeModel;
export AbstractGraphEdgeModel;
export AbstractGraphSearchAlgorithm;
export AbstractGraphFlowAlgorithm;
export AbstractGraphTraversalAlgorithm;
export AbstractLinearSolverAlgorithm;
export AbstractClassificationAlgorithm;
export AbstractLinearProgrammingProblemType;
export AbstractProcessModel;
export AbstractWorldModel;
export AbstractBanditAlgorithmModel;
export AbstractOnlineLearningModel;
export AbstractBanditProblemContextModel;
export AbstractlHopfieldNetworkModel;
export AbstractUtilityFunctionType;

# Concrete types -
export MyLinearProgrammingProblemModel;
export MyPerceptronClassificationModel, MyLogisticRegressionClassificationModel;
export MySarcasmRecordModel;
export MySarcasmRecordCorpusModel;
export MyEnglishLanguageVocabularyModel;
export MyMNISTHandwrittenDigitImageDataset;

export MyGraphNodeModel, MyGraphEdgeModel, MyGraphEdgeModels, MySimpleDirectedGraphModel, MySimpleUndirectedGraphModel, MyDirectedBipartiteGraphModel, MyConstrainedGraphEdgeModel, MyConstrainedGraphEdgeModels;
export DepthFirstSearchAlgorithm, BreadthFirstSearchAlgorithm;
export DijkstraAlgorithm, BellmanFordAlgorithm, FordFulkersonAlgorithm, EdmondsKarpAlgorithm
export JacobiMethod, GaussSeidelMethod, SuccessiveOverRelaxationMethod;
export MyValueIterationModel, MyValueFunctionPolicy;
export MyRectangularGridWorldModel, MyMDPProblemModel;
export MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel;
export MyBinaryWeightedMajorityAlgorithmModel, MyTwoPersonZeroSumGameModel;
export MyBinaryVectorArmsEpsilonGreedyAlgorithmModel, MyConsumerChoiceBanditContextModel;
export MyQLearningAgentModel;
export VLLinearUtilityFunction;

# Hopfield Network types -
export MyClassicalHopfieldNetworkModel;
export MyModernHopfieldNetworkModel;

# methods -
export tokenize;
export build;
export children;
export weight;
export walk;
export findshortestpath;
export maximumflow;
export solve;
export qriteration;
export log_growth_matrix;
export learn;
export classify;
export confusion;
export vocabulary_transition_matrix;
export sample_words;

# L2c lecture material -
export codepoint_hex;

# L4a lecture material -
export adjacency_list, adjacency_matrix, directed_density, read_weighted_edges, representation_report, vertex_ids;

# L4c lecture material -
export WeightedEdge, bellman_ford, dijkstra, path_cost, reconstruct_path, weighted_edges;

# L5a lecture material -
export build_flow_graph, parse_constrained_edge, validate_flow;

# L5c lecture material -
export solve_fruit_problem;

# week-03 stack, queue and recursion material -
export MyStack, MyQueue, isbalanced;

export fibonacci, fibonacci!, memoization_fibonacci!;
export iterative_fibonacci_report, recursive_fibonacci_report;

# MDP and RL methods -
export lookahead;
export backup;
export Q;
export policy;
export myrandpolicy;
export myrandstep;
export iterative_policy_evaluation;
export greedy;

# bandit methods -
export regret;

# Hopfield methods -
export recover;

# WMA and MWA methods -
export play;

# utility/choice methods -
export evaluate;
export indifference;

end # module VLDataScienceMachineLearningPackage
