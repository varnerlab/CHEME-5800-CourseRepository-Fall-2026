# Function anatomy examples

These files implement the same temperature-conversion function in Julia, Python,
C, and Octave. Run the commands below from the `L2a` directory.

## Commenting pattern

Each implementation follows the same commenting pattern:

1. Describe the function's purpose.
2. Document each input and return value.
3. Explain the calculation and the main steps that call the function.

Comments should explain intent or reasoning rather than repeat the code.

## Command line

### Julia

```bash
julia examples/function_anatomy.jl
```

### Python

```bash
python3 examples/function_anatomy.py
```

### Octave

```bash
octave --quiet --no-history --path examples --eval "function_anatomy()"
```

### C

C source must be compiled before it can be run:

```bash
cc examples/function_anatomy.c -o /tmp/function_anatomy
/tmp/function_anatomy
```

Each command prints:

```text
68.0 F = 20.0 C
```

## REPL

### Julia REPL

Start Julia with `julia`, then load the file and call the function:

```julia
julia> include("examples/function_anatomy.jl")

julia> fahrenheit_to_celsius(68.0)
20.0
```

### Python REPL

Start Python with `python3`, then import and call the function:

```python
>>> from examples.function_anatomy import fahrenheit_to_celsius
>>> fahrenheit_to_celsius(68.0)
20.0
```

### Octave REPL

Start Octave with `octave --quiet --no-history`, then add the examples directory
to the load path and call the function:

```octave
octave> addpath("examples")
octave> fahrenheit_to_celsius(68.0)
ans = 20
```

C does not have a standard REPL; compile and run the program from the command
line as shown above.
