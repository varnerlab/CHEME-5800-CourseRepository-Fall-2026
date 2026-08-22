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

Four pieces: Julia, VS Code and two extensions, the course environment, and the W0a
notebook. Budget about half an hour the first time, most of it spent waiting on
downloads.

### 1. Install Julia 1.12

Use [`juliaup`](https://github.com/JuliaLang/juliaup), the official Julia installer
and version manager. It is the supported path on both platforms.

**Windows** (PowerShell or Command Prompt):

```powershell
winget install -e --id Julia.Juliaup
```

**macOS** (Terminal; the installer picks the right build for Apple Silicon or Intel):

```bash
curl -fsSL https://install.julialang.org | sh
```

Close and reopen the terminal so it picks up the new path, then select the course
release and confirm it:

```bash
juliaup add 1.12
juliaup default 1.12
julia --version
```

The last command must report a `1.12` release. Direct installers are available from
[julialang.org/downloads](https://julialang.org/downloads/) if `juliaup` will not run
on your machine, but then keeping Julia 1.12 on your path is your responsibility.

### 2. Install VS Code and its two extensions

Download VS Code from
[code.visualstudio.com/download](https://code.visualstudio.com/download); the page
offers the Windows and macOS builds. Then install both extensions, either from the
Extensions view (`Ctrl+Shift+X`, or `Cmd+Shift+X` on macOS) or from a terminal:

```bash
code --install-extension julialang.language-julia
code --install-extension ms-toolsai.jupyter
```

| Extension | Identifier | Why the course needs it |
|---|---|---|
| [Julia](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia) | `julialang.language-julia` | Julia language support and the integrated REPL |
| [Jupyter](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) | `ms-toolsai.jupyter` | Opens `.ipynb` files and connects them to the Julia kernel |

### 3. Instantiate the course environment

Download and extract the course bundle, then open a terminal in its top-level
directory, the one holding `Project.toml`. Students do not need Git for the course
release workflow. Problem sets are released as separate repositories and do need a
GitHub account and GitHub Desktop, but nothing in Week 0 or in the weekly lectures
and labs requires them.

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
```

The first command takes several minutes on a new machine: it downloads every package
the course uses and precompiles them. It also builds `IJulia`, which is what
registers the `Julia 1.12` notebook kernel, so there is no separate kernel
installation step.

### 4. Run the W0a notebook

Open the extracted bundle folder in VS Code (`File > Open Folder`), then open
[the W0a notebook](W0a/CHEME-5800-W0a-Onboarding-SystemCheck-Fall-2026.ipynb). Choose
the kernel named `Julia 1.12` from the kernel picker in the upper right, then run
every cell in order. When the terminal histogram is visible, change
`do_you_see_the_histogram` from `false` to `true` and rerun the final system-check
tests.

A completely green W0a test cell is the definition of setup completion.

### If you would rather use Jupyter Lab

VS Code is the supported front end and the one office hours assumes. If you prefer
the browser, `IJulia` will start a server for you from the bundle root:

```bash
julia --project=. -e 'using IJulia; jupyterlab(dir=pwd())'
```

The first run offers to install a private Jupyter through `Conda.jl` if you do not
already have one. The course material behaves identically either way; only the
troubleshooting table below assumes VS Code.

## Troubleshooting

| Symptom | Check |
|---|---|
| `julia` is not found | Close and reopen the terminal so it picks up the new path. On Windows, confirm the Microsoft Store installation finished; on macOS, confirm that `~/.juliaup/bin` is on your path. |
| Julia reports the wrong version | Run `juliaup default 1.12`, then reopen the terminal and check `julia --version` again. |
| `Pkg.instantiate()` fails | Confirm that the terminal is at the extracted bundle root containing `Project.toml` and `Manifest.toml`, then retry with a working network connection. |
| The kernel picker offers no `Julia 1.12` entry | Step 3 registers that kernel by building `IJulia`. Re-run it, or run `julia --project=. -e 'using Pkg; Pkg.build("IJulia")'`, then restart VS Code. |
| The notebook opens but has no run buttons | The Jupyter extension (`ms-toolsai.jupyter`) is not installed. Install it, then reopen the file. |
| The first notebook cell cannot find `Include.jl` | Open the notebook from inside the extracted course bundle without moving it away from its `W0a` folder. |
| The first cell stops with `Setup resolved the wrong Include.jl` | VS Code started in a directory other than the notebook's own folder, so the first cell loaded the bundle root setup file instead. Open the folder holding the notebook (`W0a` or `W0b`), then restart the kernel and run from the top. |
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
