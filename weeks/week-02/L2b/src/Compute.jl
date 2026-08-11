module L2bDebugging

export residence_time_minutes

function _require_finite_positive(name::AbstractString, value::Real)::Float64
    isfinite(value) || throw(ArgumentError("$(name) must be finite"))
    value > 0 || throw(ArgumentError("$(name) must be positive"))
    return Float64(value)
end

"""Return residence time in min for volume in L and volumetric flow in mL/min."""
function residence_time_minutes(volume_L::Real, flow_mL_min::Real)::Float64
    volume = _require_finite_positive("volume_L", volume_L)
    flow = _require_finite_positive("flow_mL_min", flow_mL_min)
    return 1000.0 * volume / flow
end

end

