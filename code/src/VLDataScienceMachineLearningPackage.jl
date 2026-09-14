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
include("Types.jl");
include("Factory.jl");
include("Files.jl");
include("Compute.jl");
include("TextRepresentation.jl");
include("GraphRepresentation.jl");
include("ShortestPathAlgorithms.jl");
include("FlowValidation.jl");
include("LinearPrograms.jl");
include("StacksQueues.jl");
include("Recursion.jl");
include("Graphs.jl");
include("Solvers.jl");
include("Eigen.jl");
include("Binary.jl");
include("MDP.jl");
include("Bandit.jl");
include("Online.jl");
include("QLearning.jl");
include("Hopfield.jl");
include("Indifference.jl");
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
