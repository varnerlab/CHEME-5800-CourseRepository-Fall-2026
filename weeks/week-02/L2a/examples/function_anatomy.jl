"""
    fahrenheit_to_celsius(temperature_f::Real) -> Float64

Convert a temperature from degrees Fahrenheit to degrees Celsius.

# Arguments
- `temperature_f::Real`: Temperature in degrees Fahrenheit.

# Returns
- `Float64`: The corresponding temperature in degrees Celsius.
"""
function fahrenheit_to_celsius(temperature_f::Real)::Float64
    # Shift the Fahrenheit scale so that 32 °F maps to 0 °C, then rescale
    # each Fahrenheit degree by the ratio 5/9.
    temperature_c = (temperature_f - 32.0) * (5.0 / 9.0)
    return temperature_c
end

"""
    main() -> Nothing

Run one temperature-conversion example and print the result.
"""
function main()::Nothing
    # Use an exact reference case so the result is easy to verify: 68 °F = 20 °C.
    temperature_f = 68.0

    # Reuse the conversion interface instead of duplicating its formula in main.
    temperature_c = fahrenheit_to_celsius(temperature_f)

    # Label both physical units in the displayed result.
    println("$(temperature_f) F = $(temperature_c) C")
    return nothing
end

# Run the example only when this file is the command-line entry point. Calling
# include(...) from a Julia session defines the functions without printing output.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
