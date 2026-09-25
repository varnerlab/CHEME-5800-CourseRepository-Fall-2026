# L6a urea-cycle example review — September 24, 2026

**Status:** Reviewed and approved by the instructor on September 24, 2026. Approval covers the current saved notebook, including all three tasks, worked interpretation, numerical checks, and revised Summary. The polish round is closed.

Target: [Urea-cycle example](../../weeks/week-06/L6a/CHEME-5800-L6a-Example-UreaCycle-FluxBalance-Fall-2026.ipynb).

Reference: the instructor's `MRW-BTC4-Chapter-Varner` checkout,
`chapter/sections/example_urea.tex`, `code/fba/urea_cycle.jl`, its tests, and
`code/data/urea_{thermodynamics,turnover_numbers,fba_solution}.csv`.
The chapter was read but not edited. The target's pre-existing change was Julia
language metadata (1.12.5 → 1.12.7); this was preserved. Other modified course
notebooks and figures were left alone.

## Initial assessment

Overall: **6.0/10**, an editorial judgment before corrections.

| Dimension | Initial score | Evidence |
| --- | ---: | --- |
| Technical correctness | 5 | Inconsistent abundance units, obsolete parameter records, incorrect explanation of objective sign, wrong solver dictionary key, misleading bottleneck claim, and tests that passed blank responses. |
| Organization | 6 | Useful build–bound–solve sequence, but the example retained CHEME 5450 PS2 framing, completion flags, blank discussion answers, and tests after Summary. |
| Narrative | 6 | Explains why bounds matter, but overstates HL-60 specificity and physiological interpretation of a thermodynamic threshold. |
| Presentation | 7 | Readable diagram and objectives, but missing major-section separators, long text-table output, and a schematic branch arrow inconsistent with the final direction assignment. |
| Cognitive density and pacing | 6 | Repeated assignment instructions and TODOs obscure a code-forward worked example; results need developed interpretation. |

## Applied technical corrections

- Preserved the network's uptake-positive exchange convention. Its `b4` coefficient
  remains -1 because the local solver **maximizes** `c'v`. The chapter instead
  negates the exchange columns and uses a +1 coefficient. Blindly copying the
  chapter's objective sign would reverse the notebook's intended optimization.
- Replaced inconsistent hard-coded Gibbs energies with the chapter's recorded
  standard transformed estimates: -4.3, 11.6, -33.9, -30.3, and -1254.4 kJ/mol.
  Explained the recorded transformed-state conditions and heuristic direction rule.
- Copied the two provenance CSVs into the notebook's data directory and loaded
  parameters by reaction name. The copied tables retain their original access
  dates; these were not new live database queries.
- Adopted the chapter's nominal turnover numbers, including 1.08 s⁻¹ for the
  nitric oxide synthase branch, and reference abundance 0.01 mmol/gDW. Added the
  factor of 3600 so capacities and reported fluxes use mmol/gDW/h consistently.
- Corrected EC 1.15.13.39 to 1.14.13.39 in the network comment. The original figure
  already uses the latter identifier.
- Clarified cross-organism inputs, the v2 species-attribution conflict, illustrative
  abundance, finite exchange bounds, and the distinction between an active bound
  and a bound that limits the objective.
- Corrected `solution["objective"]` to `solution["objective_value"]` in the prose,
  removed swallowed solver errors, and cleared old objective coefficients on rerun.
- Replaced completion-flag tests with seven solution checks and placed the test
  cell before Summary. Removed the four self-reported completion flags. The
  approved worked interpretation also replaces the blank discussion answers.
- Added a caption explaining that the old schematic shows nominal exchange
  directions and a reversible branch arrow, while the numerical model restricts
  that branch to the forward direction. The image itself was not revised.
- Refreshed executed outputs and reloaded the saved notebook in JupyterLab.

## Validation

Executed every code cell in a fresh Julia 1.12.7 Jupyter kernel using the course
setup. Notebook JSON/schema validation and targeted `git diff --check` passed.
The seven embedded solution checks passed. A separate Julia script passed thirteen
checks against the chapter and deliberately perturbed models:

- Species/reaction order, internal stoichiometry, opposite exchange columns,
  lower/upper bounds, and opposite objective coefficients agree.
- All nineteen nominal fluxes match the chapter's recorded solution after the
  exchange-sign conversion. Urea export is 118.08 mmol/gDW/h, while the signed
  notebook exchange flux is -118.08. The four cycle reactions each carry 118.08;
  the nitric oxide synthase branch is zero.
- Doubling the v2 capacity gives urea export 236.16 mmol/gDW/h.
- Fixing oxygen uptake to 4 mmol/gDW/h gives branch flux 1 and urea export 116.08.
- Requiring urea export 500 mmol/gDW/h with nominal capacities fails the solver
  feasibility assertion rather than yielding a usable solution.

Artifacts (ignored build directory):
[execution log](../../build/notebook-previews/L6a-urea-execution.log),
[comparison script](../../build/notebook-previews/validate_urea.jl),
[comparison log](../../build/notebook-previews/L6a-urea-regression.log), and
[pre-review notebook](../../build/notebook-previews/L6a-urea-before-review.ipynb).
The comparison script reads the original chapter checkout and is a local review
artifact, not a student dependency.

Inspected the initial notebook, corrected capacity equation/units in JupyterLab,
the existing network image, and the opening-proposal HTML rendered in Chrome.
The original figure was not changed, so no new theme-specific figure was produced.

## Interactive polish status

The opening proposal was shortened after instructor feedback and **approved and applied**:
[PNG](../../build/notebook-previews/L6a-urea-opening-proposal.png),
[Markdown](../../build/notebook-previews/L6a-urea-opening-proposal.md), and
[HTML](../../build/notebook-previews/L6a-urea-opening-proposal.html).
The approved post-objectives paragraph is one sentence. The following sections
have now been approved and applied: setup; Task 1; Task 2 directions, capacities,
bounds, and objective; Task 3 solve step, HTML flux table, and worked interpretation.
The two interpretation subsections replace the old Discussion heading, three
questions, and blank answers. Their numerical examples were verified in the
initial perturbation checks. The HTML flux table was executed in a draft and
verified to contain all nineteen reactions. Existing calculations and outputs
were preserved during the prose changes.

The numerical checks and revised Summary were approved and applied. The first
two takeaways were reordered at the instructor's request. The revised concluding
sentence was accepted as adequate to close the round, rather than as an exemplar
of the preferred voice. No editorial proposals remain pending.

## Final assessment

Overall: **9.0/10**, compared with **6.0/10** initially. These are editorial
judgments, not measured learning outcomes.

| Dimension | Initial | Final | Evidence |
| --- | ---: | ---: | --- |
| Technical correctness | 5 | 9.5 | Units, objective sign, solver return key, recorded parameters, and bottleneck reasoning now agree with the implementation and verified scenarios. Biological predictions remain conditional on illustrative inputs. |
| Organization | 6 | 9.5 | Exactly three tasks develop construction, bounds, and solution; worked interpretation and numerical checks replace legacy assignment scaffolding. |
| Narrative | 6 | 8.5 | Internal balances explain the limiting capacity and oxygen tradeoff. The closing sentence is serviceable but was not strongly endorsed by the instructor. |
| Presentation | 7 | 9.0 | Compact parameter tables, a readable nineteen-reaction HTML output, rendered equations, and consistent headings improve the notebook. The original schematic still needs its caption to explain the branch-arrow discrepancy. |
| Cognitive density and pacing | 6 | 8.5 | The opening was shortened, repeated instructions removed, and interpretation divided into two focused subsections. Parameter provenance and the oxygen example remain relatively dense. |

The final saved notebook executed successfully in a fresh Julia kernel. All seven
embedded checks passed, reproducing urea export of 118.08 mmol/gDW/h. The thirteen
chapter-comparison and perturbation checks had already passed; the closing edits
did not change the numerical model. Final schema validation, three-objective /
three-task / three-takeaway counts, major-section separators, local links,
absence of obsolete question scaffolding, and agreement with the approved Summary
preview passed. Targeted `git diff --check` passed. The saved notebook was reloaded
and visually inspected in Chrome JupyterLab; section previews had been rendered
and inspected throughout the review.

Final execution log: [fresh-kernel run](../../build/notebook-previews/L6a-urea-final-execution.log).
The chapter, unrelated notebooks, and original schematic were not edited.

Reviewed notebook SHA-256: `3a7728c5333084431495ae136fe826ba601f1305024dd5d5f1c6f26fc9257aa3`

## September 25 code-documentation follow-up

Completed the authorized [L6a code documentation and stoichiometry pass](L6a-code-documentation-review.md).
Notebook edits are comments only; all ten cells reran with seven embedded checks
passing and unchanged urea export of 118.08 mmol/gDW/h. The supporting builder now
sums repeated and opposing species coefficients correctly; the current network
matrix and labels are unchanged. The September 24 narrative approval remains closed.

Current notebook SHA-256 after comment updates: `90ee20b644124198d3d3ada58e34347628ce4743e0d7f5d86c2d8ce4fd640184`
