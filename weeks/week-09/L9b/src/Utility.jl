# =============================================================================
# CHEME 5800 | L9b supplied helper: the random cloud of points
# =============================================================================
# generatedatacloud(...) draws the points that the notebook labels three ways.
# You do not need to edit this file; your work is in Compute.jl. Include.jl
# loads this file once, so after an edit here, restart the kernel.
# =============================================================================
module L9bUtility

export generatedatacloud

"""
    generatedatacloud(center::Tuple{Float64,Float64}; number_of_points::Int = 100,
        radius::Float64 = 1.0, label::Int64 = 1) -> Array{Float64,2}

Generate `number_of_points` random points inside a disk of the given `radius` around
`center`, and give every point the same `label`. Each point has a random angle and a
random distance from the center, both drawn uniformly, so the points are denser near
the center than near the edge.

The points come from Julia's global random number generator, so call
`Random.seed!(...)` first to get the same points on every run.

### Arguments
- `center::Tuple{Float64,Float64}`: the center of the disk, `(x, y)`.
- `number_of_points::Int = 100`: the number of points to generate. At least 1.
- `radius::Float64 = 1.0`: the radius of the disk. Positive.
- `label::Int64 = 1`: the label to assign to every point.

### Returns
- An `Array{Float64,2}` with one row per point: the `x` and `y` coordinates of the
  point in the first two columns, and the label in the third.

### Errors
Throws an `ArgumentError` if `number_of_points < 1` or `radius ≤ 0`.

### Example
```julia
Random.seed!(5800); # the same points on every run
cloud = generatedatacloud((0.0, 0.0), number_of_points = 2000, label = 0); # 2000 × 3
```
"""
function generatedatacloud(center::Tuple{Float64,Float64};
    number_of_points::Int = 100, radius::Float64 = 1.0, label::Int64 = 1)::Array{Float64,2}

    # check the arguments -
    if number_of_points < 1
        throw(ArgumentError("number_of_points must be at least 1"))
    end
    if radius ≤ 0
        throw(ArgumentError("radius must be positive"))
    end

    # initialize -
    data = zeros(number_of_points, 3); # one row per point: x, y, label

    # generate the data: draw the angle first, then the distance from the center -
    for i ∈ 1:number_of_points

        α = rand() * 2π; # random angle (radians), uniform on [0, 2π)
        r = rand() * radius; # random distance from the center, uniform on [0, radius)

        # convert the polar coordinates (r, α) to x and y -
        data[i,1] = center[1] + r * cos(α); # x
        data[i,2] = center[2] + r * sin(α); # y
        data[i,3] = label; # label
    end

    # return -
    return data;
end

end # module L9bUtility
