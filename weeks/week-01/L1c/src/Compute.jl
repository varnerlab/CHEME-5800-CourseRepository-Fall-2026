module L1cCalculation

export ideal_gas_pressure

const DEFAULT_GAS_CONSTANT = 8.31446261815324 # Pa*m^3/(mol*K), exact by definition

"""
    ideal_gas_pressure(amount_mol, temperature_K, volume_m3; gas_constant) -> Float64

Compute ideal-gas pressure in Pa from amount in mol, absolute temperature in K, and
volume in m^3, using P = nRT/V.

The contract: `amount_mol`, `temperature_K`, `volume_m3` and `gas_constant` must each
be finite and strictly positive. Any argument that is not raises an `ArgumentError`
naming that argument.
"""
function ideal_gas_pressure(
    amount_mol::Real,
    temperature_K::Real,
    volume_m3::Real;
    gas_constant::Real = DEFAULT_GAS_CONSTANT,
)::Float64

    # TODO 1: validate the inputs.
    #   For each of amount_mol, temperature_K, volume_m3 and gas_constant, throw an
    #   ArgumentError naming that argument if the value is not finite, or if it is
    #   not strictly positive. See `isfinite` and `throw`.
    #   Hint: a NamedTuple plus `pairs(...)` lets you loop over names and values
    #   together, so you write the check once rather than four times.

    # TODO 2: return the pressure.
    #   P = nRT/V, converted to Float64.

    throw(ErrorException("Oooops! The `ideal_gas_pressure(...)` function is not " *
                         "implemented yet - we'd better fix that."))
end

end
