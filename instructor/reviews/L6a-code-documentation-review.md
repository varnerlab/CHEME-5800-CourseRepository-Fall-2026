# L6a code documentation and stoichiometry review

Completed September 25, 2026, following the instructor's request to include all
notebook code cells and supporting L6a code resources.

## Scope and changes

- Inspected all ten code cells in the urea example. The lecture and advanced
  derivation contain no executable code cells. Added compact comments about
  copied bounds, exchange labels, the shared objective array, and export units.
  No notebook functions require new docstrings. Markdown, outputs, execution
  counts, metadata, and executable cell logic were preserved.
- Reviewed `Include.jl` and all six files in `src/`. Expanded the model, factory,
  solver, parser, stoichiometric-builder, and bounds contracts: dimensions,
  ordering, units, mutation, return values, input assumptions, and errors.
- Corrected the retained linear-algebra helper documentation, including the
  unnormalized RREF nullspace candidate, full-rank SVD fallback, thin-SVD scope,
  QR convergence limits, and power-iteration stopping/return behavior. These
  helpers are not called by the current urea notebook; their algorithms were
  not refactored or certified for general inputs.
- Documented the figure builder's four Python helpers and their theme/palette,
  tool, output, and error assumptions. Its README already describes rebuilding.
  Reviewed slide build instructions, Makefile, and style comments; no changes
  to slide production or generated artwork were needed.
- Fixed net stoichiometric accumulation: repeated terms on one side are added,
  and reactant/product contributions for the same species are summed. Explicit
  coefficient terms now trim surrounding species whitespace consistently.
- Updated the L6a validation to read the reviewed thermodynamic/turnover CSVs
  and use the notebook's mmol/gDW/h basis instead of legacy parameter literals.
  Added ten regression checks in `l6a_stoichiometry.jl`.

## Verification

- L6a-scoped Week 6 validation: **21/21 checks passed**, including ten net-
  stoichiometry checks, four urea checks, and seven course-package solver checks.
- All **ten notebook code cells** executed sequentially in a fresh Julia 1.12.7
  process, with **7/7 embedded checks passing**. Maximum urea export remained
  **118.08 mmol/gDW/h**; uptake-positive exchanges and the `-b4` objective are unchanged.
- Compared the original and corrected builders on the current network: the
  matrix, species order, reaction order, and equation dictionary are identical.
- Parsed-expression comparison confirmed that the other six Julia files
  (setup plus five source files) changed only in comments/docstrings.
- Notebook schema and HTML export passed; revised comments appear in the
  rendered code. Saved outputs and all Markdown remain unchanged.
- Python syntax validation and scoped whitespace checks passed. No figure
  rebuild was needed for docstring-only changes.

Current urea notebook SHA-256: `90ee20b644124198d3d3ada58e34347628ce4743e0d7f5d86c2d8ce4fd640184`

This supplements the approved notebook review; it does not reopen its narrative
or certify unused numerical helpers as general-purpose solvers.
