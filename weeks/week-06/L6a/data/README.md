# L6a urea-cycle network

`Network.net` is a compact model of the urea cycle used in the L6a flux balance
example, adapted from the CHEME 5430/5450 Spring 2026 lecture materials
([varnerlab/Lecture-5430-FluxBalanceAnalysis](https://github.com/varnerlab/Lecture-5430-FluxBalanceAnalysis)).

Each record is `name,reactants,products,is_reversible`. Species on each side are
joined by `+`, with an optional coefficient written as `2*species`; `[]` denotes the
surroundings. Lines beginning with `//` are comments.

- `v1`–`v5`: the enzyme-catalyzed reactions, labeled with their EC numbers
  (6.3.4.5, 4.3.2.1, 3.5.3.1, 2.1.3.3, 1.14.13.39).
- `b1`–`b14`: exchange reactions of the form `[] → species`; a positive flux brings
  the species into the system and a negative flux exports it.

The reversibility flags are a first guess. The example replaces them with estimates
from reaction free energies (eQuilibrator) and sets maximum rates from BRENDA
turnover numbers. The schematic in `../figs/Fig-Urea-cycle-Schematic.png` comes from
the same source.
