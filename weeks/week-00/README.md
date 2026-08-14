# Week 0 — Course setup and system check

Week 0 is the asynchronous onboarding unit for CHEME 4800/5800. Complete the
required system check before the first scheduled class meeting. It separates
installation work from Week 1 instruction and remains useful as a diagnostic
baseline throughout the semester.

## Onboarding objectives

By the end of Week 0, students should be able to:

1. verify that Julia 1.12 is available from a terminal;
2. instantiate the single pinned course environment;
3. open a course notebook with a Julia 1.12 kernel;
4. load both installed packages and meeting-local source code; and
5. run computation, plotting, and tests from beginning to end.

## Onboarding sequence

| Unit | Status | Purpose | Notebook |
|---|---|---|---|
| W0a | **Required before L1a** | Installation verification and end-to-end smoke test | [Course setup and system check](W0a/CHEME-5800-W0a-Onboarding-SystemCheck-Fall-2026.ipynb) |
| W0b | Optional bridge | Preview a function contract and tested engineering calculation | [First tested calculation](W0b/CHEME-5800-W0b-Optional-FirstTestedCalculation-Fall-2026.ipynb) |

W0b is not part of system setup. It previews material taught systematically in
Week 2 and may remain incomplete without affecting readiness for L1a.

## Required setup

1. Install Julia 1.12 and confirm that the terminal reports the expected release:

   ```bash
   julia --version
   ```

2. Download and extract the course bundle, then open a terminal in its top-level
   directory. Students do not need Git for the course release workflow.

3. Instantiate the pinned environment and verify the vendored course package:

   ```bash
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
   ```

4. Open the W0a notebook in the supported notebook front end and select its Julia
   1.12 kernel. Run every cell in order. When the terminal histogram is visible,
   change `do_you_see_the_histogram` from `false` to `true` and rerun the final
   system-check tests.

A completely green W0a test cell is the definition of setup completion.

## Troubleshooting

| Symptom | Check |
|---|---|
| `julia` is not found | Restart the terminal after installation and verify that the Julia executable is on the command path. |
| Julia reports the wrong version | Select the Julia 1.12 installation before instantiating the course environment. |
| `Pkg.instantiate()` fails | Confirm that the terminal is at the extracted bundle root containing `Project.toml` and `Manifest.toml`, then retry with a working network connection. |
| The notebook has no Julia kernel | Restart the notebook front end after Julia installation and select the kernel named `Julia 1.12`. |
| The first notebook cell cannot find `Include.jl` | Open the notebook from inside the extracted course bundle without moving it away from its `W0a` folder. |
| The first cell stops with `Setup resolved the wrong Include.jl` | The notebook front end started in a directory other than the notebook's own folder, so the first cell loaded the bundle root setup file instead. Point the front end at the `W0a` or `W0b` folder holding the notebook, then restart the kernel and run from the top. |
| Only the histogram-flag test fails | Confirm that the histogram rendered, set the flag to `true`, and rerun the test cell. |

Do not diagnose W0b until W0a is completely green. If W0a worked previously,
rerunning it is the fastest way to distinguish an environment failure from a bug
in later course work.

## Instructor validation

From the authoring-repository root:

```bash
julia --startup-file=no --project=. instructor/validation/week-00/runtests.jl
```

The optional W0b function ships as a student stub. Its reference solution remains
instructor-only and is used by the validation suite.
