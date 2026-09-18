# Week 5 lab solution files and release packaging

Updated September 18, 2026, following the instructor's request to include
`Compute-solution.jl` in the weekly GitHub Action release bundle.

- L5b now uses `src/Compute.jl` for the student implementation of
  `validate_sensitivity_flow(...)` and `src/Compute-solution.jl` for the reference.
- L5d uses the same pair for the student implementation of `flow_formulation(...)`.
- Both reference files are byte-for-byte copies of the previously tested complete
  implementations. The module names, public functions, and solved behavior are unchanged.
- Notebook code cells, saved outputs, execution counts, and metadata are preserved.
  Four Markdown cells now identify the student task or updated source path. The
  changed sections were rendered and inspected; the reviewed Summary sections remain intact.
- All 46 Julia checks pass, including ten checks of the student scaffolds and the
  default setup path. All five packaging tests pass, all local references resolve,
  and the seven notebooks have no findings in the strict style check.

Weekly manifests no longer exclude lab reference solutions. The builder includes
them alongside the student files and still excludes instructor material and
machine-specific paths. Packaging is performed by the existing tag-triggered
[GitHub Action](../../.github/workflows/release-week.yml).
