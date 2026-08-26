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
    # Choose a sample temperature with a known Celsius equivalent.
    temperature_f = 68.0

    # Call the conversion function and store its return value.
    temperature_c = fahrenheit_to_celsius(temperature_f)

    # Display the input and output values with their units.
    println("$(temperature_f) F = $(temperature_c) C")
    return nothing
end

# Run main only when this file is executed from the command line. Loading the
# file with include(...) in the Julia REPL defines the functions without running it.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
