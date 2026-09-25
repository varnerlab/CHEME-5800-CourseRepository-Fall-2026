# L6a stoichiometric-matrix SVD example review

**Status:** Reviewed and approved by the instructor on September 24, 2026. Approval covers the current saved notebook, including all three tasks, the cumulative grayscale reconstruction, the conservation and flux-feasibility discussion, and the Summary. The polish round is closed.

**Notebook:** [L7b Example: Stoichiometric Structure and Singular Value Decomposition](../../weeks/week-07/L7b/CHEME-5800-L7b-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb)

**Final editorial score:** 9/10, compared with 6/10 before the polish round. Scores are editorial judgments, not measured learning outcomes.

| Dimension | Initial | Final |
|---|---:|---:|
| Technical correctness and agreement with code | 5 | 9 |
| Organization and sequencing | 6.5 | 9 |
| Narrative and interpretation | 5.5 | 9 |
| Presentation | 6 | 9 |
| Density and pacing | 6 | 8.5 |

The notebook now defines full-SVD dimensions, orthonormality, and numerical rank; uses squared singular values to measure cumulative reconstruction; and computes the selected reconstruction without storing every rank-one matrix. Full grayscale images compare the cumulative reconstruction with the original matrix using an explicit near-zero band.

Both nullspaces are extracted from the full singular-vector bases. Conservation relations are tied to the modeled dynamics. A trial flux demonstrates that stoichiometric balance alone does not imply feasibility under reaction bounds. Short derivations replace broken companion links, and three tasks align with three objectives and three takeaways.

Validation completed during the polish round and final review:

- All 19 saved notebook code cells executed in order in the repository Julia environment using the supplied cached platelet model.
- Verified matrix dimensions 738 × 1008, numerical rank 719, left nullity 19, right nullity 289, and 271 reaction-bound violations for the selected balanced trial vector.
- Checked full-SVD reconstruction, nullspace orthonormality and residuals, the truncation-error identity, and grayscale image dimensions and zero encoding.
- Rendered and inspected approved sections and the completed notebook structure. Checked the cumulative plot in light and dark themes; grayscale coefficient meanings remain the same in either theme.
- Notebook schema, local links, objective/task/takeaway counts, section separators, sequential saved execution counts, and absence of saved error outputs passed. Saved sections match their approved previews.

No required corrections remain from this round. The fresh-download branch was not exercised; validation used the supplied cache. Task 2 remains mathematically substantial, and classroom pacing is untested. This review does not change the Week 6 release status.

Reviewed notebook SHA-256: `27445b0583b5625b02308453837400d781f63f782770635e04aa662897db8329`

Relocated to L7b on September 25, 2026, replacing the S&P 500 example. The review and checksum above describe the approved pre-move snapshot; the migration changes only the cache-path constant in the notebook.


Migration validation:

- All 19 notebook code cells executed from L7b with the supplied cache, including in an isolated Week 7 bundle containing no Week 6 files.
- Week 7 validation passed all 24 checks; the isolated L7b run passed all 12 checks. L6a's remaining validation passed all 11 checks after the BiGG helpers and cache were moved.
- The 10 weekly-bundle inclusion tests passed. The prototype release statuses and current meeting scopes were retained; no release was published.
- The cache is byte-identical to the original. Notebook prose, outputs, execution counts, and metadata are preserved; only `_PATH_TO_DATA` became `CHEME5800_L7B_DATA` in the cache-loading cell.
- The BiGG helpers now live in L7b's local module. The network helper uses the declared Downloads standard library instead of an unimported HTTP module. Its URL construction and JSON parsing were checked; the live download branch was not exercised.
- Updated week indexes, release manifests, lecture links, the planning queue, and the existing L6a slide hyperlinks. The deck rebuilt successfully, and its SVD links point to L7b.

Relocated notebook SHA-256: `d87b8c22e63dcb53c8c64795a6262b3d180bab574d2fb573ab45902c793a0c57`
