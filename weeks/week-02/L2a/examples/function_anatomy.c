/* Runnable C companion for L2a's function anatomy comparison. */

#include <stdio.h>

/**
 * Convert a temperature from degrees Fahrenheit to degrees Celsius.
 *
 * @param temperature_f Temperature in degrees Fahrenheit.
 * @return The corresponding temperature in degrees Celsius.
 */
double fahrenheit_to_celsius(double temperature_f)
{
    /* Shift the Fahrenheit scale so that 32 F maps to 0 C, then rescale
       each Fahrenheit degree by the ratio 5/9. */
    const double temperature_c = (temperature_f - 32.0) * (5.0 / 9.0);
    return temperature_c;
}

/**
 * Run one temperature-conversion example and print the result.
 *
 * @return Zero when the program finishes successfully.
 */
int main(void)
{
    /* Use an exact reference case so the result is easy to verify: 68 F = 20 C. */
    const double temperature_f = 68.0;

    /* Reuse the conversion interface instead of duplicating its formula in main. */
    const double temperature_c = fahrenheit_to_celsius(temperature_f);

    /* Keep one decimal place and label both physical units in the output. */
    printf("%.1f F = %.1f C\n", temperature_f, temperature_c);
    return 0;
}
