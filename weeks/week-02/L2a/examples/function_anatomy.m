% Runnable Octave companion for L2a's function anatomy comparison.

function function_anatomy()
    % FUNCTION_ANATOMY Run one conversion example and print the result.

    % Use an exact reference case so the result is easy to verify: 68 F = 20 C.
    temperature_f = 68.0;

    % Reuse the conversion interface instead of duplicating its formula here.
    temperature_c = fahrenheit_to_celsius(temperature_f);

    % Keep one decimal place and label both physical units in the output.
    fprintf("%.1f F = %.1f C\n", temperature_f, temperature_c);
end
