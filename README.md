# CHEME 4800/5800: Principles of Computational Thinking for Engineers (Fall 2026)

This course develops practical computational habits for engineers: represent a
problem, compute a result, test the implementation, and interpret what the result
means. Using Julia and a small amount of Python, we apply that workflow to data
representations, graph algorithms, optimization, data-driven modeling, sequential
decision-making, scientific communication, and dynamical systems.

## Getting the course material

There are two ways to use the course materials:

1. **Download the weekly bundle (recommended; no Git required).** When a week is
   published, download its `.zip` file from the
   [Releases page](https://github.com/varnerlab/CHEME-5800-CourseRepository-Fall-2026/releases),
   extract it, and open the extracted folder in VS Code. Published bundles are
   versioned snapshots; corrections are issued as new releases rather than silently
   replacing files.
2. **Clone the repository (for Git users).** The complete authoring repository is
   available at
   [varnerlab/CHEME-5800-CourseRepository-Fall-2026](https://github.com/varnerlab/CHEME-5800-CourseRepository-Fall-2026).
   Current instructional materials are organized under [`weeks/`](weeks/).

Problem sets and the practicum are distributed through separate repositories; see
[Assignments and practicum](#assignments-and-practicum) below.

## One-time setup

The supported environment is Julia 1.12 in VS Code with the Julia and Jupyter
extensions. The complete installation guide, system check, and troubleshooting
table are in the [Week 0 onboarding guide](weeks/week-00/README.md).

In brief:

1. Install Julia 1.12 with
   [`juliaup`](https://github.com/JuliaLang/juliaup).
2. Install [VS Code](https://code.visualstudio.com/download), then install the
   `julialang.language-julia` and `ms-toolsai.jupyter` extensions.
3. From the repository root or an extracted bundle root—the directory containing
   `Project.toml`—instantiate the course environment and run the package smoke test:

   ```bash
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
   ```

4. Open and complete the
   [Week 0 system-check notebook](weeks/week-00/W0a/CHEME-5800-W0a-Onboarding-SystemCheck-Fall-2026.ipynb).
   A green final test means the installation is ready for class.

Python 3.11 or newer is used only in Weeks 2, 3, and 13. A GitHub account and
[GitHub Desktop](https://desktop.github.com) are needed for problem sets, but not
for downloaded weekly lecture and lab bundles. The Week 0 guide explains both.

## Weekly materials

Each weekly guide gives the learning objectives, class-meeting sequence, required
data, and validation instructions for that unit. The links below point to the
current source materials; use the [Releases page](https://github.com/varnerlab/CHEME-5800-CourseRepository-Fall-2026/releases)
for published student bundles.

| Week | Topic | Materials |
|---:|---|---|
| 0 | Course setup and system check | [Week 0](weeks/week-00/) |
| 1 | Primitive types, data representations, and floating point | [Week 1](weeks/week-01/) |
| 2 | Functions, errors, collections, and defensive programs | [Week 2](weeks/week-02/) |
| 3 | Data provenance, recursion, and testable algorithms | [Week 3](weeks/week-03/) |
| 4 | Graph representations, traversal, and shortest paths | [Week 4](weeks/week-04/) |
| 5 | Maximum flow and linear programming | [Week 5](weeks/week-05/) |
| 6 | Duality, flux balance, and iterative linear solvers | [Week 6](weeks/week-06/) |
| 7 | SVD, data reduction, and ordinary least squares | [Week 7](weeks/week-07/) |
| 8 | Regularization, cross-validation, and model checking | [Week 8](weeks/week-08/) |
| 9 | Binary classification and numerical optimization | [Week 9](weeks/week-09/) |
| 10 | Online learning and multi-armed bandits | [Week 10](weeks/week-10/) |
| 11 | Markov models, Markov decision processes, and value iteration | [Week 11](weeks/week-11/) |
| 12 | Tabular Q-learning and sequential-decision integration | [Week 12](weeks/week-12/) |
| 13 | REST clients and Model Context Protocol servers | [Week 13](weeks/week-13/) |
| 14 | Integration clinic and practicum launch | [Week 14](weeks/week-14/) |
| 15 | Dynamics as algorithms and the CHEME 5820 bridge | [Week 15](weeks/week-15/) |
| 16 | Course synthesis and transition to CHEME 5820 | [Week 16](weeks/week-16/) |

## Course environment and library

The course uses one Julia 1.12 environment at the repository or extracted-bundle
root. `Project.toml` and `Manifest.toml` pin the dependencies, including the
semester snapshot of `VLDataScienceMachineLearningPackage` vendored under
[`code/`](code/). No remote course package or Julia registry is needed during
class.

Every notebook loads its meeting-local `Include.jl`, which activates the supplied
root environment and imports the code needed for that meeting. After the one-time
setup, notebooks can be run directly. The
[course library documentation](https://varnerlab.github.io/CHEME-5800-CourseRepository-Fall-2026/)
describes the reusable types and computational routines.

## Assignments and practicum

Problem sets, the practicum, and their solutions are managed in separate
repositories rather than this course-content repository. Assignment links and
release instructions will be distributed through the course communication
channels. GitHub Desktop is the supported way to obtain those repositories without
using Git from a terminal.

Course materials are provided under the [MIT License](LICENSE).