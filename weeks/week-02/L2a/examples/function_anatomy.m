% Runnable Octave companion for L2a's function anatomy comparison.

function function_anatomy()
    % FUNCTION_ANATOMY Run one conversion example and print the result.

    % Choose a sample temperature with a known Celsius equivalent.
    temperature_f = 68.0;

    % Call the conversion function and store its return value.
    temperature_c = fahrenheit_to_celsius(temperature_f);

    % Display the input and output values with their units.
    fprintf("%.1f F = %.1f C\n", temperature_f, temperature_c);
end
