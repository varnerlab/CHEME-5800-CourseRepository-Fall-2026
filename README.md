# CHEME 4800/5800 - Fall 2026

This repository is the authoring source for **Principles of Computational Thinking for Engineers** in Fall 2026. It will combine lectures and labs into curated weekly releases that students can download and run without using Git.

The selective rebalance preserves varied examples while using a consistent computational workflow: represent a problem, compute a result, test it, and interpret what it means.

## Requirements

| Tool | Version | Needed for |
|---|---|---|
| [Julia](https://julialang.org) | 1.12 | Every week of the course |
| [VS Code](https://code.visualstudio.com) | current | The supported editor and notebook front end |
| VS Code Julia extension | current | Julia language support and the integrated REPL |
| VS Code Jupyter extension | current | Opening `.ipynb` files and connecting them to the Julia kernel |
| [GitHub Desktop](https://desktop.github.com) + a GitHub account | current | Problem sets, which live in their own repositories |
| [Python](https://www.python.org) | 3.11 or newer | Weeks 2 and 3 (standard library only) and the Week 13 MCP unit |

Lectures and labs are distributed as weekly `.zip` bundles that you download and
extract, so you do not need Git to run any of the weekly material. **Problem sets are
different**: each one lives in its own repository, so you do need a GitHub account and
GitHub Desktop before the first problem set is released.

You do not need to install Jupyter or `IJulia` separately; step 4 below handles both.

## Installation

### 1. Install Julia 1.12

Use [`juliaup`](https://github.com/JuliaLang/juliaup), the official Julia installer
and version manager.

**Windows** (PowerShell):

```powershell
winget install -e --id Julia.Juliaup
```

**macOS** (Terminal; the installer selects the right build for Apple Silicon or Intel):

```bash
curl -fsSL https://install.julialang.org | sh
```

Close and reopen the terminal so it picks up the new path, then select the course
release:

```bash
juliaup add 1.12
juliaup default 1.12
julia --version
```

The last command must report a `1.12` release. If `juliaup` will not run on your
machine, direct installers are at
[julialang.org/downloads](https://julialang.org/downloads/); you are then
responsible for keeping Julia 1.12 on your path.

### 2. Install VS Code

Download it from
[code.visualstudio.com/download](https://code.visualstudio.com/download), which
offers both the Windows and macOS builds.

**On macOS**, also register the `code` command: open the Command Palette
(`Cmd+Shift+P`), type `Shell Command`, and run
**Shell Command: Install 'code' command in PATH**. Windows installers add `code`
automatically.

### 3. Install the two VS Code extensions

From a terminal:

```bash
code --install-extension julialang.language-julia
code --install-extension ms-toolsai.jupyter
```

Or from the Extensions view (`Ctrl+Shift+X`, `Cmd+Shift+X` on macOS), searching for
the identifiers below.

| Extension | Identifier |
|---|---|
| [Julia](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia) | `julialang.language-julia` |
| [Jupyter](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) | `ms-toolsai.jupyter` |

### 4. Instantiate the course environment

The course uses one Julia 1.12 environment at the repository or extracted-bundle
root. The manifest pins `VLDataScienceMachineLearningPackage` to the vendored source
under `code/`; no remote course package is installed during class.

Download and extract a weekly bundle, then open a terminal in its top-level
directory, the one holding `Project.toml`:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
```

The first command takes several minutes on a new machine: it downloads every package
the course uses and precompiles them. It also builds `IJulia`, which is what
registers the `Julia 1.12` notebook kernel, so there is no separate Jupyter or kernel
installation step.

### 5. Install GitHub Desktop (before the first problem set)

Lectures and labs need none of this, so you can leave it until the first problem set
is announced. Problem sets are released as separate repositories, and
[GitHub Desktop](https://desktop.github.com) is the supported way to get them without
using Git from a terminal.

1. Create a [GitHub account](https://github.com/signup) if you do not have one.
2. Install [GitHub Desktop](https://desktop.github.com) and sign in.
3. Set VS Code as its editor: **File > Options > Integrations** on Windows, or
   **GitHub Desktop > Settings > Integrations** on macOS, then choose
   **Visual Studio Code** as the external editor.

To pick up a problem set, use **File > Clone repository** with the URL from the
assignment, then open the cloned folder in VS Code.

### 6. Install Python (only before Weeks 2, 3, and 13)

Weeks 2 and 3 run a short Julia/Python comparison that uses only the Python standard
library, so any Python 3.11 or newer will do: the
[python.org installer](https://www.python.org/downloads/), Anaconda, or the one your
operating system supplies. Week 13 creates its own local virtual environment from the
repository root:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r weeks/week-13/python/requirements.txt
```

Those requirements include `ipykernel`, so VS Code can select the repository-local
`.venv` interpreter for the Week 13 notebooks.

## Smoke test

Confirm the three commands resolve:

```bash
julia --version     # must report 1.12
code --version
python3 --version   # only needed before Weeks 2, 3, and 13
```

Then run the real check. [Week 0](weeks/week-00/README.md) is the asynchronous
onboarding unit, and completing it is the definition of a working installation:
open the extracted bundle folder in VS Code (`File > Open Folder`), open
[the W0a notebook](weeks/week-00/W0a/CHEME-5800-W0a-Onboarding-SystemCheck-Fall-2026.ipynb),
choose the `Julia 1.12` kernel from the picker in the upper right, and run every cell
in order. It exercises the environment, an installed package, meeting-local source,
plotting, and tests. A completely green test cell means you are ready for the first
class meeting.

Weekly notebooks then load their local `Include.jl`, which delegates to the shared
root bootstrap and activates this environment. There are no lecture- or lab-specific
Julia environments.

## Common issues

| Symptom | Fix |
|---|---|
| `julia` is not found | Close and reopen the terminal so it picks up the new path. On macOS, confirm `~/.juliaup/bin` is on your path; see the appendix below. |
| Julia reports the wrong version | Run `juliaup default 1.12`, reopen the terminal, and check `julia --version` again. |
| `code` is not found (macOS) | Run **Shell Command: Install 'code' command in PATH** from the VS Code Command Palette. |
| `Pkg.instantiate()` fails | Confirm the terminal is at the extracted bundle root containing `Project.toml` and `Manifest.toml`, then retry on a working network connection. |
| The kernel picker offers no `Julia 1.12` entry | Step 4 registers that kernel by building `IJulia`. Re-run it, or run `julia --project=. -e 'using Pkg; Pkg.build("IJulia")'`, then restart VS Code. |
| A notebook opens with no run buttons | The Jupyter extension (`ms-toolsai.jupyter`) is not installed. |
| A notebook's first cell cannot find `Include.jl` | Open the notebook from inside the extracted bundle, without moving it out of its meeting folder. |

The [Week 0 README](weeks/week-00/README.md#troubleshooting) carries the longer
troubleshooting table, including the failure modes specific to the W0a system check.

## Appendix: putting Julia on the path by hand

`juliaup` normally edits your shell profile for you. If `julia` is still not found
after reopening the terminal, add its directory yourself.

**macOS** (`~/.zshrc` for the default shell):

```bash
export PATH="$HOME/.juliaup/bin:$PATH"
```

Reload with `source ~/.zshrc`, or open a new terminal.

**Windows**: `juliaup` installs to `%USERPROFILE%\.julia\juliaup\bin`. Add it under
Settings > System > About > Advanced system settings > Environment Variables > Path,
then open a new PowerShell window.

## Design documents

- [Fall 2026 topic boundary](COURSE-TOPIC-BOUNDARY-FALL-2026.md): approved selective rebalance, CHEME 5820 prerequisite boundary, topic disposition, and communications/MCP unit.
- [Fall 2026 content selections](COURSE-CONTENT-SELECTIONS-FALL-2026.md): concrete Week 9 classification, Week 13 REST/MCP, Week 15 dynamics, and deeper-dive scope choices.
- [Week 0 onboarding and Weeks 1–16 build queue](COURSE-BUILD-QUEUE-WEEKS-01-16.md): chronological authoring order, completion status, and cleanup handoff.
- [Course repository plan](COURSE-REPOSITORY-PLAN.md): environment, packaging, releases, validation, repository boundaries, and implementation phases.

## Current status

The rebalanced session schedule is the working Fall 2026 schedule. Week 0 owns
asynchronous system setup, and the initial chronological build through instructional
Weeks 1–16 is complete. Every instructional week uses
the approved structural pattern: one top-level weekly package, class-meeting
folders (`L1a`, `L1b`, and so on), and a local `Include.jl` in each Julia meeting.
Notebook roles follow the material rather than a mandatory Lecture/Example split.
Week 15 is a full instructional dynamics block rather than two practicum work
sessions. The next phase is the cross-course cleanup and release-quality review.

Problem sets, the practicum, and their simultaneously released solutions are
managed in separate repositories and are outside this course-content repository.
