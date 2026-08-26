function temperature_c = fahrenheit_to_celsius(temperature_f)
    % FAHRENHEIT_TO_CELSIUS Convert Fahrenheit to Celsius.
    %
    % Input:
    %   temperature_f - Temperature in degrees Fahrenheit.
    %
    % Output:
    %   temperature_c - The corresponding temperature in degrees Celsius.

    % Shift the Fahrenheit scale so that 32 F maps to 0 C, then rescale
    % each Fahrenheit degree by the ratio 5/9.
    temperature_c = (temperature_f - 32.0) * (5.0 / 9.0);
end
