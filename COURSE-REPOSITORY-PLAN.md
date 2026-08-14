# CHEME 4800/5800 Course Repository Redesign Plan — Fall 2026

**Status:** Working repository specification; implementation and release workflow are not yet validated  
**Repository:** `CHEME-5800-CourseRepository-Fall-2026`  
**Primary objective:** Maintain one instructor repository while giving students simple, immutable weekly downloads that require no Git synchronization.

## Companion instructional design

This repository plan is implemented in service of the approved [Fall 2026 topic boundary](COURSE-TOPIC-BOUNDARY-FALL-2026.md) and the concrete [Fall 2026 content selections](COURSE-CONTENT-SELECTIONS-FALL-2026.md).

The approved topic boundary resolves the content-level decisions that were previously implicit here:

- CHEME 4800 and CHEME 5800 share each weekly release and its examples, but 5800 has explicitly labeled advanced implementation/testing notebooks rather than identical assessment artifacts.
- The semester preserves varied historical examples while selectively compressing algorithm surveys and avoiding unnecessary CHEME 5820 overlap.
- The rebalanced sequence restores early practical data work and adds a full REST/MCP communications unit.
- The Week 13 REST/MCP unit was used as a technical risk prototype because it exercises the largest net-new content and the cross-language packaging path. The chronological student-facing build through Week 16 is now complete.

## 1. Decisions already made

1. Lecture and lab materials will live in one course repository and be organized together by week.
2. Students will normally download a weekly release asset instead of cloning or pulling the repository.
3. The course will use the local-code model. Course materials will use a pinned local snapshot of [`VLDataScienceMachineLearningPackage.jl`](https://github.com/varnerlab/VLDataScienceMachineLearningPackage.jl), rather than installing the package from a remote URL during class.
4. The repository will have one student-facing Julia environment at its root: one `Project.toml` and one committed `Manifest.toml`.
5. Individual lecture and lab directories will not contain their own Julia environments.
6. Problem sets are out of scope for this repository. Each problem set lives in a separate repository, and its problem and solution are released at the same time through a separately managed workflow.
7. Published weekly releases are immutable. Corrections produce a new patch release; an existing asset is never silently replaced.

## 2. Student experience to design around

The normal weekly workflow should be:

1. Open the course release page or the week link in the LMS.
2. Download the clearly named asset, for example `CHEME-4800-5800-Fall-2026-Week-07.zip`.
3. Unzip it into the student's course-work directory.
4. Open that folder in VS Code or Jupyter.
5. Start Julia with the environment supplied in the bundle.
6. Work on lecture examples and the lab locally.
Students should not need to clone, pull, merge, stash, resolve notebook conflicts, initialize submodules, or manage multiple Julia environments.

## 3. Proposed authoring-repository layout

```text
CHEME-5800-CourseRepository-Fall-2026/
├── Project.toml
├── Manifest.toml
├── Include.jl
├── README.md
├── LICENSE
├── .gitignore
├── code/
│   ├── Project.toml
│   ├── UPSTREAM.toml
│   └── src/
│       ├── VLDataScienceMachineLearningPackage.jl
│       └── ...
├── weeks/
│   ├── week-00/
│   │   ├── README.md
│   │   ├── release.toml
│   │   ├── W0a/
│   │   └── W0b/
│   ├── week-01/
│   │   ├── README.md
│   │   ├── release.toml
│   │   ├── L1a/
│   │   │   ├── Include.jl
│   │   │   ├── CHEME-5800-L1a-Lecture-Topic-Fall-2026.ipynb
│   │   │   ├── CHEME-5800-L1a-Example-Application-Fall-2026.ipynb
│   │   │   ├── data/
│   │   │   └── src/
│   │   └── L1b/
│   ├── week-02/
│   └── ...
├── instructor/
│   ├── notes/
│   └── release-checklists/
├── scripts/
│   ├── sync-local-package.sh
│   ├── build-week.sh
│   ├── validate-week.jl
│   └── validate-environment.jl
└── .github/
    └── workflows/
        ├── validate.yml
        └── release-week.yml
```

### Visibility rule

Weekly course-content archives contain the week's class-meeting folders, approved
data, and supporting code. They do not contain problem sets or problem-set
solutions because those artifacts live in separate repositories and are released
together. Instructor notes, notebook checkpoints, and other authoring-only files
remain excluded from weekly archives.

## 4. Julia environment and local package design

### 4.1 One environment

- Place the only course-environment `Project.toml` and `Manifest.toml` at repository root. The vendored package retains its own `code/Project.toml` as package metadata, not as a student environment.
- Merge the dependencies required by the local package, lectures, labs, and instructional validation tests into the root `Project.toml`.
- Commit `Manifest.toml` because the course is an application with a reproducible environment, not a reusable package release.
- Track the latest stable Julia release; record the exact version used to validate each published course release.
- Remove all class-meeting-level `Project.toml` and `Manifest.toml` files during migration.
- Standardize notebook startup so every notebook activates the bundle/repository root, not the current notebook directory.
- Provide one environment smoke test that imports all required dependencies and loads the local module.

### 4.2 Vendor the package; do not use a student-facing submodule

The preferred model is a pinned source snapshot under `code/`, matching the CHEME 5660 local-code model, with its upstream identity recorded in `code/UPSTREAM.toml`. Do not require students to initialize a Git submodule. A synchronization script should:

1. Fetch a specified upstream tag or commit.
2. Copy the approved source files into `code/src`.
3. Copy only approved data resources according to the data policy below.
4. Record the upstream repository, commit SHA, package version, and synchronization date in `UPSTREAM.toml`.
5. Refuse to continue if the local snapshot contains unexpected files or if validation fails.

Retain `code/Project.toml` so Julia can identify the local package and record `path = "code"` in the root manifest. Do not retain a second package manifest, `.git` directory, documentation build output, or development-only configuration. Dependencies used directly by course notebooks belong in the root `Project.toml`; package implementation dependencies remain declared in `code/Project.toml` and resolve through the root manifest.

The root `Include.jl` owns environment activation and local-package loading. Each
class-meeting folder carries a local `Include.jl`, following the CHEME 5660 Fall
2026 convention. The local file delegates environment setup to the root, contains
all `using` statements required by that meeting's notebooks, and includes the
meeting's source. Notebooks and authoring tests do not repeat package-loading
statements. A local file must not create another Julia environment.

### 4.3 Data policy must be explicit

The current upstream package checkout is approximately 460 MB. Its `src/data` directory is approximately 341 MB and contains about 45,000 files; the Julia source files themselves are comparatively small. Therefore, blindly copying the entire upstream repository into every weekly archive would undermine the weekly-release model.

Create a data inventory with, for every dataset:

- canonical name and source;
- license and attribution requirements;
- size and file count;
- checksum/version;
- weeks that use it;
- whether it belongs in Git, a setup bundle, a weekly bundle, or external object storage;
- whether a reduced teaching subset can replace the full dataset.

Use these packaging rules:

- Small, broadly reused data may go in `data/common`.
- Small week-specific data goes only in the applicable weekly bundle.
- Large collections such as image corpora should be supplied once in a versioned setup/data bundle or as a separately downloadable dataset asset.
- Weekly archives should contain a data manifest and fail validation if a referenced dataset is missing.
- Generated model states, rendered HTML, notebook checkpoints, and duplicate assets should not be source data.

Decision to make after measuring the actual course dependency graph: either make every weekly bundle fully standalone, or use one semester setup/data bundle plus small weekly overlays. Prefer standalone bundles when they remain reasonably sized; use the setup bundle only for genuinely large shared data.

## 5. Weekly content model

Each `weeks/week-NN` directory should contain the complete student-facing instructional unit:

- a short `README.md` stating objectives, preparation, class-meeting sequence, and required data;
- one folder per scheduled class meeting, named by its course identifier (`L3b`, `L3c`, and so on);
- notebooks whose filenames state their actual role: `Lecture`, `Lab`, `Example`, `Advanced`, `Derivation`, or `Algorithm`;
- a local `Include.jl` plus only the `data/`, `figs/`, and `src/` subdirectories actually required by that meeting;
- a machine-readable `release.toml` listing included paths, required datasets, entry notebooks, validation commands, and release version.

`week-00` is the one structural exception: it is an asynchronous onboarding unit,
so its `W0a` and `W0b` identifiers denote a required system check and an optional
bridge rather than scheduled class meetings. It otherwise follows the same release,
environment, and validation rules as instructional weeks.

Do not expose authoring vocabulary such as `fixtures` or `extensions`, or create
generic `lectures` and `lab` subdirectories inside a week. An intentionally
invalid file is a clearly named data example. A deeper notebook uses an accurate
role such as `Advanced`, `Derivation`, or `Algorithm` and lives with the meeting
it supports. The course identifiers remain visible because they
match the schedule, recordings, and the established 5660/5820 repository pattern;
the remainder of each filename states its purpose and topic.

CHEME 4800 and CHEME 5800 share one weekly archive and common instructional path.
Encode any additional CHEME 5800-specific notebook in release metadata rather
than duplicating the week tree or creating an `extensions` hierarchy.

### 5.1 Notebook presentation standard

Use the CHEME 5820 Spring 2026 notebooks as a presentation reference, not as a
mandatory notebook decomposition:

- a descriptive title and opening paragraph;
- a blockquoted `Learning Objectives` panel followed by a horizontal rule;
- conceptual development, executable code, and examples combined or separated
  according to what best serves the class meeting;
- `Setup, Data, and Prerequisites`, numbered tasks, explanatory transitions around
  code, and interpreted outputs when the notebook is computational;
- `Lecture`, `Lab`, `Example`, `Advanced`, `Derivation`, or `Algorithm` labels only
  when that role is accurate;
- a closing `Summary` with a blockquoted `Key Takeaways` panel and horizontal rule.

Execution tests remain necessary but do not substitute for instructional writing,
mathematical development, task structure, or output interpretation.

### 5.2 Labs require student work

**Every lab must ship something incomplete that students finish during the meeting.**
A notebook that only reads and runs pre-written code is not a lab. This is a deliberate
change for Fall 2026: several 2025 labs were read-and-run, and that is what we are
correcting.

Each lab is a single 50-minute meeting shared with discussion and setup, so scope the
work to one function or one clearly bounded piece of one. Students receive the
scaffolding — types, signature, docstring, helper functions, and the test set that acts
as the specification — and write the body. A lab that requires building a program from
nothing is mis-sized.

The convention, carried over from the 2025 labs and standardized here:

- A lab's `src/` folder holds `Compute.jl` (student-facing stub) and
  `Compute-solution.jl` (reference solution) side by side, using the **same module
  name** so the two are drop-in interchangeable.
- The stub keeps the module, signature, and docstring; replaces the body with
  `# TODO:` comments describing what to write; and ends with
  `throw(ErrorException("Oooops! The \`name(...)\` function is not implemented yet - we'd better fix that."))`.
- The week's `release.toml` lists the solution under `instructor_only_paths` so it is
  not bundled for students.
- The week's `runtests.jl` validates against the solution, and separately asserts that
  the student file still contains its `TODO` markers and none of the solution's
  distinctive expressions. That guard catches a solution leaking into the student tree.
- The lab notebook must contain a section naming the file, listing what each `TODO`
  expects, and pointing at the test cell as the definition of done. A stub alone is not
  discoverable.

Where the work is a judgement rather than a function — confirming a plot rendered, for
instance — a `TODO`-marked flag in a notebook code cell that the test set asserts is an
acceptable substitute (see `L1b`).

This rule is enforced mechanically by rule `F16` of the `notebook-style` audit skill.

### 5.3 Historical-content-first rule

Before authoring a notebook, inspect the corresponding CHEME 5800 Fall 2025
lecture and lab repositories and other approved course instances. Adapt the
highest-quality existing explanation, example, code, and figure assets when they
fit the Fall 2026 topic boundary. Write new material only for a genuine gap or a
substantive correction. Record what was retained, corrected, omitted, or newly
authored in the week's README.

## 6. Release system

### 6.1 Build behavior

`scripts/build-week.sh NN` should create a clean archive in a temporary build directory containing only:

- root `Project.toml` and `Manifest.toml`;
- a bundle-specific `README.md`;
- the vendored local source needed by the week;
- approved common and week-specific data;
- the selected `weeks/week-NN/LNx` class-meeting folders;
- notebooks labeled `Advanced`, `Derivation`, or `Algorithm` when selected for the release;
- license and attribution files;
- optional validation scripts.

The archive should expand into one top-level directory such as:

```text
CHEME-4800-5800-Fall-2026-Week-07/
```

The build must exclude at least:

- `.git`, `.github`, `.vscode`, and `.DS_Store`;
- `.ipynb_checkpoints` and temporary notebook files;
- problem-set repositories, instructor notes, and authoring-only validation material;
- generated HTML and duplicate figures unless deliberately required;
- unused datasets and model checkpoints;
- development-only package files.

### 6.2 Release naming and immutability

- Git tag: `week-07.0`
- Release title: `CHEME 4800/5800 - Week 07`
- Asset: `CHEME-4800-5800-Fall-2026-Week-07.0.zip`
- Correction: tag `week-07.1` with a new asset and release note explaining the change.

Do not use `gh release upload --clobber`. A released tag and its student asset are immutable.

Release notes must tell students to download the specifically named asset under **Assets**, not GitHub's automatically generated “Source code” ZIP or tarball.

### 6.3 Automation

The validation workflow should run on every pull request and main-branch change. The release workflow should run only for a versioned week tag or a manually approved dispatch. It should:

1. Validate root environment consistency.
2. Check the week manifest and prohibited-file rules.
3. Build the archive from a clean checkout.
4. Unzip the archive into a fresh directory.
5. Instantiate/precompile the Julia environment.
6. Load the vendored module.
7. run notebook/static smoke tests and the week's validation test.
8. Generate checksums and a file inventory.
9. Create a draft release and attach the asset.
10. Publish only after an instructor reviews the draft artifact.

## 7. Migration from the 2025 repositories

1. Inventory the 2025 lecture and lab trees by week and map each item into the new weekly structure.
2. Identify shared versus week-specific data and record every notebook's actual file dependencies.
3. Remove generated and accidental files before importing:
   - `.DS_Store`;
   - `.ipynb_checkpoints`;
   - redundant rendered HTML trees;
   - obsolete Keynote/source assets not used during class;
   - duplicate rendered notebook variants and outputs;
   - generated model-state files that can be reproduced.
4. Strip large cell outputs from student notebooks where the output is not instructionally necessary.
5. Consolidate all Julia dependencies into the root environment.
6. Replace per-directory bootstrap and include files with the shared course bootstrap.
7. Update paths so notebooks work from the extracted weekly bundle, not only from the authoring repository.
8. Exclude problem-set materials, which are managed in separate repositories, from this migration and its release paths.
9. Validate each migrated week independently in a clean directory.
10. Preserve the 2025 repositories as read-only historical archives; do not merge their Git histories into the new repository unless there is a specific archival need.

## 8. Problem-set repository boundary

Problem-set operations are deliberately handled outside this repository:

1. each problem set uses a separate repository;
2. the problem and solution are released at the same time;
3. weekly course-content archives do not package either artifact;
4. this repository does not define problem-set collection, grading, or feedback workflows; and
5. weekly documentation may link to a problem-set repository after that separate workflow is finalized.

This boundary keeps lecture/lab release engineering independent from problem-set
repository operations. Decisions about those repositories belong in their own
documentation, not in this course-content plan.

## 9. Validation and acceptance criteria

The redesign is ready for students when all of the following are true:

- A student can start from a clean machine, follow one setup document, and run a week bundle without Git.
- Every notebook activates the same root environment and loads the local module.
- No weekly directory contains another `Project.toml` or `Manifest.toml`; `code/Project.toml` is package metadata rather than a second course environment.
- A clean `Pkg.instantiate()` succeeds on supported macOS, Windows, and Linux configurations.
- Each release archive is reproducible from its tag and has a published checksum.
- Release validation detects missing data, problem-set artifacts, and prohibited authoring files.
- A correction creates a new versioned release and leaves the previous release intact.
- Release metadata distinguishes the CHEME 4800 common path from the CHEME 5800 extension without duplicating the weekly archive.
- A TA who did not build the system can execute the documented setup, validation, and release procedures.

## 10. Implementation phases

### Phase 0 — Confirm policy and constraints

- Decide repository visibility during the semester.
- Decide whether unreleased weeks may be visible.
- Define supported Julia and operating-system versions.
- Decide whether weekly bundles are standalone or depend on one setup/data bundle.

### Phase 1 — Establish the repository foundation

- Create the proposed directory structure.
- Add the root environment and commit the manifest.
- Add the local package synchronization/provenance mechanism.
- Add the shared bootstrap and environment smoke test.
- Strengthen `.gitignore` for notebooks, macOS files, generated models, archives, and build artifacts.

### Phase 2 — Build the Week 13 vertical prototype

- Use the selected REST/MCP unit to exercise the cross-language environment, recorded response examples, tests, and release packaging.
- Migrate that week as a complete unit containing lectures, a lab, local source use, data, and a CHEME 5800 extension.
- Build and unzip its release artifact.
- Test it on clean macOS and Windows environments.
- Revise the structure before bulk migration.

### Phase 3 — Migrate and normalize the semester

- Import remaining lecture and lab weeks.
- Consolidate dependencies and paths.
- Inventory and place data.
- Separate student-facing instructional content from instructor authoring materials.
- Create week manifests and README files.

### Phase 4 — Automate validation and releases

- Implement clean-build packaging.
- Add CI validation and prohibited-file scanning.
- Add tag-triggered draft releases.
- Add checksums, inventories, and release notes.
- Test a patch-release correction without replacing the original.

### Phase 5 — Confirm the problem-set boundary

- Document the external problem-set repository link convention when that workflow is ready.
- Verify that weekly build scripts reject embedded problem-set and solution artifacts.
- Keep problem-set operations out of the course-content release automation.

### Phase 6 — Student and staff usability test

- Ask one TA and one person unfamiliar with the repository to perform setup, weekly download, lab work, validation, and correction workflows from the written instructions.
- Fix every point where either tester requires undocumented instructor help.

## 11. Immediate next actions

1. Retrofit Weeks 1 and 2 to the validated Week 3 class-meeting layout and CHEME 5820 notebook presentation standard.
2. Run the cross-course cleanup and release-quality pass across the completed Weeks 1–16 instructional build.
3. Implement clean weekly ZIP packaging, checksum generation, inventory checks, and rejection of problem-set artifacts.
4. Test extracted weekly releases on supported clean macOS and Windows environments.
5. Confirm whether the authoring repository will be public or private during Fall 2026.
6. Document the external problem-set repository link convention when that separate workflow is ready.
7. Conduct the TA and unfamiliar-user setup and usability test, then repair every undocumented dependency.

## 12. Reuse for CHEME 5820 Spring 2027

Build the repository scripts and conventions so they are course-parameterized rather than hard-coded to 5800. At minimum, course number, semester, archive prefix, module path, week count, and release title should come from a small configuration file. After the 5800 vertical prototype is stable, extract the generic synchronization, validation, and release components for reuse in the 5820 repository. Do not create a shared framework prematurely; first prove the workflow with one real 5800 week.
