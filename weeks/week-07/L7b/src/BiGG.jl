module L7bBiGG

import Downloads # retrieve a model when its local cache is absent
import JSON # parse BiGG model records
import DataFrames: DataFrame # tabular response helper
import VLDataScienceMachineLearningPackage: build # extend the course factory interface

export MyBiggModelsEndpointModel, MyBiggModelsDownloadModelEndpointModel

include("Types.jl")
include("Factory.jl")
include("Handler.jl")
include("Network.jl")

end
