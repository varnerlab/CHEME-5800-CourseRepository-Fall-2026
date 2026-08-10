# CHEME 4800/5800 Course Repository Redesign Plan — Fall 2026

**Status:** Working repository specification; implementation and release workflow are not yet validated  
**Repository:** `CHEME-5800-CourseRepository-Fall-2026`  
**Primary objective:** Maintain one instructor repository while giving students simple, immutable weekly downloads that require no Git synchronization.

## Companion instructional design

This repository plan is implemented in service of the approved [Fall 2026 topic boundary](COURSE-TOPIC-BOUNDARY-FALL-2026.md) and the concrete [Fall 2026 content selections](COURSE-CONTENT-SELECTIONS-FALL-2026.md).

The approved topic boundary resolves the content-level decisions that were previously implicit here:

- CHEME 4800 and CHEME 5800 share each weekly release and its examples, but 5800 has explicit implementation/testing extensions rather than identical assessment artifacts.
- The semester preserves varied historical examples while selectively compressing algorithm surveys and avoiding unnecessary CHEME 5820 overlap.
- The rebalanced sequence restores early practical data work and adds a full REST/MCP communications unit.
- The Week 13 REST/MCP unit is the selected first vertical prototype because it exercises the largest net-new content and the cross-language packaging path.

## 1. Decisions already made

1. Lecture and lab materials will live in one course repository and be organized together by week.
2. Students will normally download a weekly release asset instead of cloning or pulling the repository.
3. The course will use the local-code model. Course materials will use a pinned local snapshot of [`VLDataScienceMachineLearningPackage.jl`](https://github.com/varnerlab/VLDataScienceMachineLearningPackage.jl), rather than installing the package from a remote URL during class.
4. The repository will have one student-facing Julia environment at its root: one `Project.toml` and one committed `Manifest.toml`.
5. Individual lecture and lab directories will not contain their own Julia environments.
6. GitHub Classroom will not be part of the Fall 2026 operating model. GitHub has announced that Classroom will be decommissioned on August 28, 2026, so assignment distribution, collection, testing, feedback, and grading need a replacement.
7. Published weekly releases are immutable. Corrections produce a new patch release; an existing asset is never silently replaced.

## 2. Student experience to design around

The normal weekly workflow should be:

1. Open the course release page or the week link in the LMS.
2. Download the clearly named asset, for example `CHEME-4800-5800-Fall-2026-Week-07.zip`.
3. Unzip it into the student's course-work directory.
4. Open that folder in VS Code or Jupyter.
5. Start Julia with the environment supplied in the bundle.
6. Work on lecture examples and the lab locally.
7. Submit the designated assignment artifact through the selected assignment system.

Students should not need to clone, pull, merge, stash, resolve notebook conflicts, initialize submodules, or manage multiple Julia environments.

## 3. Proposed authoring-repository layout

```text
CHEME-5800-CourseRepository-Fall-2026/
├── Project.toml
├── Manifest.toml
├── README.md
├── LICENSE
├── .gitignore
├── local/
│   └── VLDataScienceMachineLearningPackage/
│       ├── UPSTREAM.toml
│       └── src/
│           ├── VLDataScienceMachineLearningPackage.jl
│           ├── Include.jl
│           └── ...
├── data/
│   ├── README.md
│   ├── common/
│   └── week-specific/
├── weeks/
│   ├── week-01/
│   │   ├── README.md
│   │   ├── lectures/
│   │   ├── lab/
│   │   ├── extensions/
│   │   │   └── cheme-5800/
│   │   └── release.toml
│   ├── week-02/
│   └── ...
├── assignments/
│   ├── templates/
│   ├── tests/
│   ├── rubrics/
│   └── solutions/
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

Student release archives must never contain `assignments/solutions`, instructor notes, hidden tests, unreleased assessments, notebook checkpoints, or other instructor-only material. If the repository is public during the semester, future solutions and assessments cannot be stored anywhere in it, because excluding them from release archives does not prevent students from browsing the repository.

## 4. Julia environment and local package design

### 4.1 One environment

- Place the only course `Project.toml` and `Manifest.toml` at repository root.
- Merge the dependencies required by the local package, lectures, labs, and assignment tests into the root `Project.toml`.
- Commit `Manifest.toml` because the course is an application with a reproducible environment, not a reusable package release.
- Pin and document the supported Julia version.
- Remove all lecture-level and lab-level `Project.toml` and `Manifest.toml` files during migration.
- Standardize notebook startup so every notebook activates the bundle/repository root, not the current notebook directory.
- Provide one environment smoke test that imports all required dependencies and loads the local module.

### 4.2 Vendor the package; do not use a student-facing submodule

The preferred model is a pinned source snapshot under `local/`, with its upstream identity recorded in `UPSTREAM.toml`. Do not require students to initialize a Git submodule. A synchronization script should:

1. Fetch a specified upstream tag or commit.
2. Copy the approved source files into `local/VLDataScienceMachineLearningPackage/src`.
3. Copy only approved data resources according to the data policy below.
4. Record the upstream repository, commit SHA, package version, and synchronization date in `UPSTREAM.toml`.
5. Refuse to continue if the local snapshot contains unexpected files or if validation fails.

The vendored package's own `Project.toml`, `Manifest.toml`, `.git` directory, documentation build output, and development configuration should not be copied into the course tree. Its dependencies belong in the single root `Project.toml`.

Notebooks should load the vendored module through one shared bootstrap file. Avoid custom `Include.jl` copies in every lecture and lab directory.

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

- a short `README.md` stating objectives, preparation, lecture sequence, lab instructions, required data, and submission link;
- all lecture notebooks and supporting assets for that week;
- the lab starter notebook and supporting assets;
- a clearly labeled `extensions/cheme-5800` path when the week has a graduate implementation/testing requirement;
- a machine-readable `release.toml` listing included paths, required datasets, entry notebooks, assignment identifier, and release version.

Adopt consistent names that do not require students to decode internal lecture codes. Internal identifiers such as `L7a` may remain in metadata, but student-facing files and links should make week and purpose obvious.

CHEME 4800 and CHEME 5800 share one weekly archive and common instructional path. Encode the CHEME 5800 extension entry point and grading track in release metadata rather than duplicating the entire week tree.

## 6. Release system

### 6.1 Build behavior

`scripts/build-week.sh NN` should create a clean archive in a temporary build directory containing only:

- root `Project.toml` and `Manifest.toml`;
- a bundle-specific `README.md`;
- the vendored local source needed by the week;
- approved common and week-specific data;
- `weeks/week-NN/lectures` and `weeks/week-NN/lab`;
- the week's `extensions/cheme-5800` path, when present;
- license and attribution files;
- optional validation scripts.

The archive should expand into one top-level directory such as:

```text
CHEME-4800-5800-Fall-2026-Week-07/
```

The build must exclude at least:

- `.git`, `.github`, `.vscode`, and `.DS_Store`;
- `.ipynb_checkpoints` and temporary notebook files;
- solutions, hidden tests, rubrics, and instructor notes;
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
   - duplicate student/solution notebook outputs;
   - generated model-state files that can be reproduced.
4. Strip large cell outputs from student notebooks where the output is not instructionally necessary.
5. Consolidate all Julia dependencies into the root environment.
6. Replace per-directory bootstrap and include files with the shared course bootstrap.
7. Update paths so notebooks work from the extracted weekly bundle, not only from the authoring repository.
8. Move all solutions and hidden grading material outside student-visible release paths.
9. Validate each migrated week independently in a clean directory.
10. Preserve the 2025 repositories as read-only historical archives; do not merge their Git histories into the new repository unless there is a specific archival need.

## 8. Assignment system after GitHub Classroom

The replacement must separately solve six functions that Classroom previously bundled together:

1. distribute starter files;
2. associate submissions with the roster;
3. record deadlines and extensions;
4. collect submissions reliably;
5. run automated checks where appropriate;
6. return grades and feedback.

### Recommended default for Fall 2026

Use the institutional LMS as the system of record for roster, due dates, extensions, submission receipts, grades, and feedback. Distribute each starter assignment inside the corresponding weekly release. Have students upload one deliberately constrained artifact—preferably a single notebook when possible, otherwise a ZIP with a required structure.

Build a local/instructor-side grading harness that:

- downloads or ingests the LMS submissions;
- validates filenames and archive structure;
- preserves the original submission unchanged;
- runs tests in an isolated working copy with time and resource limits;
- produces a machine-readable result plus an instructor-readable report;
- never executes untrusted student code with instructor credentials or secrets;
- supports manual rubric items and documented overrides.

This model is consistent with the no-Git student workflow and has the lowest dependency on another vendor transition.

### Alternatives to evaluate in a short pilot

- **Classroom 50:** GitHub identifies this as a partner replacement using GitHub repositories and Actions. Evaluate only if per-student repositories and Git-based feedback remain pedagogically valuable; it may recreate the Git friction the weekly-download model is intended to remove.
- **Codio:** Evaluate if existing Codio activities, roster integration, and autograding materially reduce staff work. Measure exportability and avoid locking the authoritative course content inside Codio.
- **Manually scripted GitHub organization:** Template repositories plus GitHub API/CLI automation can reproduce much of Classroom, but this creates a custom service that the course staff must own. Use only if repository-based submissions are a firm requirement.
- **Gradescope or another Cornell-supported submission service:** Evaluate notebook/ZIP handling, autograder support, LMS grade synchronization, group work, late-day handling, and accessibility through institutional support.

### Assignment-system pilot and decision gate

Before committing, test two representative assignments:

- one individual notebook with deterministic tests;
- one larger assignment with supporting files, manual rubric components, and a late/extension case.

Score each candidate on student setup burden, instructor setup burden, TA grading workflow, Julia support, security isolation, roster/LMS integration, handling of extensions and groups, feedback quality, exportability, cost, and risk of service change. Select and document the Fall 2026 system before assignment templates are finalized.

## 9. Validation and acceptance criteria

The redesign is ready for students when all of the following are true:

- A student can start from a clean machine, follow one setup document, and run a week bundle without Git.
- Every notebook activates the same root environment and loads the local module.
- No weekly directory contains another `Project.toml` or `Manifest.toml`.
- A clean `Pkg.instantiate()` succeeds on supported macOS, Windows, and Linux configurations.
- Each release archive is reproducible from its tag and has a published checksum.
- Release validation detects missing data and prohibited instructor files.
- A solution or hidden test cannot be found in the public repository or any student archive.
- A correction creates a new versioned release and leaves the previous release intact.
- The assignment pipeline has been tested end to end with a mock roster, ordinary submission, late submission, extension, malformed submission, and code that times out.
- The release and grading harness distinguish the CHEME 4800 common path from the CHEME 5800 extension without duplicating the weekly archive.
- A TA who did not build the system can execute the documented release and grading procedures.

## 10. Implementation phases

### Phase 0 — Confirm policy and constraints

- Decide repository visibility during the semester.
- Decide whether unreleased weeks may be visible.
- Identify Cornell-supported LMS/submission and sandboxing options.
- Define supported Julia and operating-system versions.
- Decide whether weekly bundles are standalone or depend on one setup/data bundle.

### Phase 1 — Establish the repository foundation

- Create the proposed directory structure.
- Add the root environment and commit the manifest.
- Add the local package synchronization/provenance mechanism.
- Add the shared bootstrap and environment smoke test.
- Strengthen `.gitignore` for notebooks, macOS files, generated models, archives, and build artifacts.

### Phase 2 — Build the Week 13 vertical prototype

- Use the selected REST/MCP unit to exercise the cross-language environment, recorded fixtures, tests, student/instructor separation, and release packaging.
- Migrate that week as a complete unit containing lectures, a lab, local source use, data, an assignment, and a CHEME 5800 extension.
- Build and unzip its release artifact.
- Test it on clean macOS and Windows environments.
- Run a mock submission through the proposed grading workflow.
- Revise the structure before bulk migration.

### Phase 3 — Migrate and normalize the semester

- Import remaining lecture and lab weeks.
- Consolidate dependencies and paths.
- Inventory and place data.
- Separate student, solution, and instructor materials.
- Create week manifests and README files.

### Phase 4 — Automate validation and releases

- Implement clean-build packaging.
- Add CI validation and prohibited-file scanning.
- Add tag-triggered draft releases.
- Add checksums, inventories, and release notes.
- Test a patch-release correction without replacing the original.

### Phase 5 — Finalize assignment operations

- Select the submission platform after the pilot.
- Finalize starter templates, rubrics, tests, and secure grading harness.
- Document roster setup, extensions, late submissions, regrades, group work, and grade export.
- Export/archive any historical GitHub Classroom data needed before shutdown.

### Phase 6 — Student and staff usability test

- Ask one TA and one person unfamiliar with the repository to perform setup, weekly download, lab work, submission, grading, and correction workflows from the written instructions.
- Fix every point where either tester requires undocumented instructor help.

## 11. Immediate next actions

1. Review and approve the rebalanced session-level schedule derived from `COURSE-TOPIC-BOUNDARY-FALL-2026.md`.
2. Adapt and run-validate the 20-item deeper-dive launch set backed by verified historical sources; unselected ideas remain backlog only.
3. Build the selected Week 13 REST/MCP unit as the first vertical prototype, then test a complete weekly ZIP for both course paths.
4. Filter the 2024/2025 content and data inventory against the selected common-core, launch deeper dives, and CHEME 5820 boundary.
5. Confirm whether the authoring repository will be public or private during Fall 2026.
6. Generate the root environment against the current Julia release and document the update/committed-manifest policy without pinning the course to an older Julia version.
7. Decide how the merged local module under `code/` will be loaded and record its provenance.
8. Pilot the LMS-first submission workflow and at least one alternative before choosing the assignment platform.
9. Export any GitHub Classroom roster, assignment, grade, and repository mapping data that must be retained before August 28, 2026.

## 12. Reuse for CHEME 5820 Spring 2027

Build the repository scripts and conventions so they are course-parameterized rather than hard-coded to 5800. At minimum, course number, semester, archive prefix, module path, week count, and release title should come from a small configuration file. After the 5800 vertical prototype is stable, extract the generic synchronization, validation, release, and grading components for reuse in the 5820 repository. Do not create a shared framework prematurely; first prove the workflow with one real 5800 week.
