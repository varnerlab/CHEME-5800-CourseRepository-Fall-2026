# L6a advanced flux balance derivation comparison

Reviewed September 24, 2026. Updated the
[advanced derivation notebook](../../weeks/week-06/L6a/CHEME-5800-L6a-Advanced-Derivation-FluxBalanceAnalysis-Fall-2026.ipynb)
against the local chapter's `sections/derivation.tex` and
`sections/linearprogram.tex` in
`/Users/jdv27/Desktop/papers/MRW-BTC4-Chapter-Varner/chapter`.

The chapter's derivation is correct under its stated batch/fed-batch assumptions
with no biomass flow. The original notebook reaches the conventional constraint,
but mixes normalization bases and presents sufficient assumptions for one special
case as general requirements. Its intermediate balance needs the qualifications
below. The revision follows the chapter's product-rule derivation while retaining
the notebook's conceptual lecture format.

| Issue | Original notebook | Corrected interpretation |
| --- | --- | --- |
| Physical volume versus biomass | Calls both physical volume and cell mass an abstract volume; writes `V = B V̄`. | Physical volume has units L; total biomass `ℬ = B V̄` has units gDW. Use lowercase `cᵢ` per volume and uppercase `Cᵢ` per biomass. |
| Reaction-rate units | Gives a volumetric reaction rate as concentration/volume/time. | Volumetric rates have units mmol/L/h; biomass-specific rates have units mmol/gDW/h. |
| Stream direction | Changes from `νₛ` to an undefined `dₛ`. | Define and consistently use `dₛ = +1` for inlets and `−1` for outlets. |
| Growth rate | Identifies `μ` with the relative change in biomass concentration after fixing volume. | Without biomass flow, `μ = ℬ̇/ℬ = Ḃ/B + V̄̇/V̄`. Fixed volume is a special case. |
| Steady state | Groups constant volume, steady intracellular concentrations, and no transport together. | Balanced growth fixes intracellular amounts per biomass, while their total amounts increase. It gives `S v̂ = μ x` before neglecting pool dilution. |
| Small dilution | Labels the dimensional quantity `μ Cᵢ` as much less than one. | Compare it with a production or consumption rate in the same units, using `abs(μ Cᵢ)/qᵢ ≪ 1`. |
| Open-system transport | First removes transport, then restores exchange through hypothetical reactions. | Retain molecular transport in the stoichiometric flux sum, distinguish it from reactor streams, and count every transfer once. |
| Cell-free systems | Mentions a different volume basis without developing the consequence. | Derive the physical-volume balance. No growth dilution does not imply zero accumulation. |

The dynamic intracellular balance is `S v̂ = dx/dt + μ x`. The conventional
zero-balance constraint additionally assumes stationary specific pools and
neglects their explicit dilution demands. It still includes precursor demands
through a biomass pseudo-reaction. The revision states the units for the usual
biomass-reaction normalization and warns against counting the same growth demand
both there and as explicit pool dilution.

The chapter's growth-rate identity must not be extended to cultures with biomass
inflow or washout without including those flows in both the biomass and metabolite
amount balances. The revised notebook makes that scope explicit. Molecular
transport includes passive as well as active transport; absence of a bulk stream
through a membrane does not remove either process. The chapter was not edited.

## Reference correction

The original Bordbar link uses PMID 24987116, which identifies
[Minimal metabolic pathway structure is consistent with associated biomolecular interactions](https://pubmed.ncbi.nlm.nih.gov/24987116/).
The intended general review is
[Bordbar, Monk, King, and Palsson (2014), Constraint-based models predict metabolic and associated cellular functions](https://doi.org/10.1038/nrg3643).
The notebook now links to that review.

The existing local file `L6a/docs/Bordbar-CurrOpinBiotechnol-28-2014.pdf` actually
contains Spirito et al., *Chain elongation in anaerobic reactor microbiomes to
recover resources from waste*. The revised notebook does not cite that file;
replacing the shared literature file is outside this notebook edit.

The dilution discussion was also checked against
[Benyamini et al. (2010), Flux balance analysis accounting for metabolite dilution](https://doi.org/10.1186/gb-2010-11-4-r43),
and the conventional formulation and biomass reaction against the local
[Orth, Thiele, and Palsson primer](../../weeks/week-06/L6a/docs/Orth-NatBiotechnol-28-2010.pdf).

## Verification

- Notebook JSON and notebook schema validated; original metadata and cell IDs
  preserved, with one new Markdown cell for the biomass derivation.
- Symbolic checks passed for the product rule, the fed-batch growth identity,
  physical-volume dilution, and cancellation of matched cell washout terms.
- Checked units, flux signs, equation lead-ins and punctuation, local links,
  three objectives, three conceptual takeaways, and major-section separators.
- Exported to HTML and inspected heading, blockquote, list, and equation markup.
- Typeset the complete narrative and all 15 displayed equations to a temporary
  PDF and visually inspected the rendered pages. A live notebook-browser preview
  was unavailable; native VS Code/MathJax display was not visually checked.
- No executable cells or Julia implementation were changed. Course solver tests
  were not needed for this mathematical narrative revision.
