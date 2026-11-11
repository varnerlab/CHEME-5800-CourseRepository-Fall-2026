# =============================================================================
# CHEME 5800 | L12d lab: the lab module
# =============================================================================
# One module holds the lab's code. It reads four files, in this order:
#
#   Types.jl     every type of the lab
#   Factory.jl   the build(...) methods
#   Helper.jl    small helper functions
#   Compute.jl   the patient, the network, value iteration, and DQN
#
# Include.jl loads this module only once, so restart the kernel if you edit it.
# =============================================================================
module L12dLab

import VLDataScienceMachineLearningPackage: build # we add build methods for the lab's types
using Random # Xoshiro, a seeded random number generator

# the lab's code -
include("Types.jl")
include("Factory.jl")
include("Helper.jl")
include("Compute.jl")

# the types -
export MyPatientModel, MyGridPolicyModel, MyLinearQNetworkModel, MyTransitionModel, MyReplayBufferModel

# the functions -
export isdead, iscured, isterminal, treat, features, qvalues, greedyaction
export solvegrid, gridaction, remember!, mydqn, simulate

end # module L12dLab
