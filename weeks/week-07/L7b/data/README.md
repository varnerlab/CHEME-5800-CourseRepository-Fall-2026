# Human platelet metabolic model

`saved-model-iAT_PLT_636.jld2` stores the cached BiGG model used by the
[L7b stoichiometric-matrix SVD example](../CHEME-5800-L7b-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb).
The JLD2 file contains the `model` record with 738 metabolites and 1008 reactions.

Source: the `iAT_PLT_636` model from [BiGG Models](http://bigg.ucsd.edu/),
described by [Thomas et al. (2014)](https://pubmed.ncbi.nlm.nih.gov/24473230/).
The original download date is not recorded. This cache was moved unchanged from
L6a to L7b on September 25, 2026.

SHA-256: `6d826893bcde5ae291dfc037322609b226185e7cfb2703701ab442a2dfc578c0`

The notebook reads this local cache for offline execution. If it is absent, the
BiGG helper downloads the selected model and saves a new cache. Selecting another
model identifier selects another cache filename; that first download requires
network access. Numerical dimensions and diagnostics in the notebook refer to the
supplied platelet model.
