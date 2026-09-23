# L6b E. coli core model

`e_coli_core.json` is the *Escherichia coli* core metabolic model from
[BiGG Models](http://bigg.ucsd.edu/models/e_coli_core), downloaded on 2026-09-23 from
`https://bigg.ucsd.edu/static/models/e_coli_core.json`. It has 95 reactions and
72 metabolites covering glycolysis, the pentose phosphate pathway, the TCA cycle,
oxidative phosphorylation, fermentation, and a biomass reaction
(`BIOMASS_Ecoli_core_w_GAM`).

- Orth JD, Fleming RMT, Palsson BØ. Reconstruction and use of microbial metabolic
  networks: the core *Escherichia coli* metabolic model as an educational guide.
  *EcoSal Plus* 4(1) (2010). doi:10.1128/ecosalplus.10.2.1
- King ZA, Lu J, Dräger A, et al. BiGG Models: a platform for integrating,
  standardizing and sharing genome-scale models. *Nucleic Acids Research* 44
  (2016) D515–D522. doi:10.1093/nar/gkv1049

Units: fluxes in mmol/gDW/h; the biomass flux is the growth rate in 1/h. BiGG writes
exchange reactions as `A → ∅`, so uptake is a negative flux. The file's default
bounds allow glucose uptake up to 10 mmol/gDW/h, leave oxygen uptake effectively
unlimited (1000), and require the non-growth ATP maintenance reaction `ATPM` to
run at 8.39 mmol/gDW/h or more.

SHA-256: `7bedec10576cfe935b19218dc881f3fb14f890a1871448fc19a9b4ee15b448d8`
