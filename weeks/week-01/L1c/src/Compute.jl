module L1cCalculation

export ideal_gas_pressure

const DEFAULT_GAS_CONSTANT = 8.31446261815324 # Pa*m^3/(mol*K)

"""Compute ideal-gas pressure in Pa from amount, absolute temperature, and volume."""
function ideal_gas_pressure(
    amount_mol::Real,
    temperature_K::Real,
    volume_m3::Real;
    gas_constant::Real = DEFAULT_GAS_CONSTANT,
)::Float64
    inputs = (
        amount_mol = amount_mol,
        temperature_K = temperature_K,
        volume_m3 = volume_m3,
        gas_constant = gas_constant,
    )
    for (name, value) in pairs(inputs)
        isfinite(value) || throw(ArgumentError("$(name) must be finite"))
        value > 0 || throw(ArgumentError("$(name) must be positive"))
    end
    return Float64(amount_mol * gas_constant * temperature_K / volume_m3)
end

end

