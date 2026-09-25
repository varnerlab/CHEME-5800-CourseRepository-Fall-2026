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

## Recorded thermodynamic and kinetic inputs

`urea_thermodynamics.csv` and `urea_turnover_numbers.csv` were copied on
2026-09-24 from `MRW-BTC4-Chapter-Varner/code/data/` (the instructor's chapter
checkout). The tables preserve the chapter's 2026-07-22 access dates, reaction
queries, transformed-state conditions, source publications, and parameter-selection
notes. These are recorded inputs, not fresh database queries.

The thermodynamic values are standard transformed reaction Gibbs energies;
the -10 kJ/mol reversibility cutoff is a teaching heuristic, not an intracellular
thermodynamic calculation. The kinetic records span organisms and assays. In
particular, the v2 record has a species-attribution conflict, and v1 uses a
literature-based default. The common enzyme abundance is illustrative, not a
measured HL-60 abundance.

The notebook uses `eₒ = 0.01 mmol/gDW` and multiplies turnover numbers in s⁻¹ by
3600 to report capacities and fluxes in mmol/gDW/h. The chapter uses
secretion-positive exchanges, whereas this network retains uptake-positive
exchanges. Thus the same nominal solution has urea exchange flux -118.08 here
and +118.08 in the chapter; the urea export rate is +118.08 in both.
