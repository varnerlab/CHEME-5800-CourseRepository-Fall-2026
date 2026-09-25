"""
Abstract base type for all BiGG database API endpoint models.
Subtypes represent specific API endpoints and carry any required parameters.
"""
abstract type AbstractBiggEndpointModel end

"""
    MyBiggModelsEndpointModel <: AbstractBiggEndpointModel

Endpoint model for the BiGG `/api/v2/models` listing endpoint.
No parameters are required; instantiate with `MyBiggModelsEndpointModel()`.
"""
struct MyBiggModelsEndpointModel <: AbstractBiggEndpointModel

    # methods -
    MyBiggModelsEndpointModel() = new();
end

"""
    MyBiggModelsDownloadModelEndpointModel <: AbstractBiggEndpointModel

Endpoint model for downloading a specific BiGG model via `/api/v2/models/<bigg_id>/download`.

### Fields
- `bigg_id::String`: the BiGG model identifier (e.g., `"iJO1366"`).
"""
mutable struct MyBiggModelsDownloadModelEndpointModel <: AbstractBiggEndpointModel

    # data -
    bigg_id::String

    # methods -
    MyBiggModelsDownloadModelEndpointModel() = new();
end

