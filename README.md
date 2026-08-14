# CHEME 4800/5800 - Fall 2026

This repository is the authoring source for **Principles of Computational Thinking for Engineers** in Fall 2026. It will combine lectures and labs into curated weekly releases that students can download and run without using Git.

The selective rebalance preserves varied examples while using a consistent computational workflow: represent a problem, compute a result, test it, and interpret what it means.

## Start with Week 0

The course uses one Julia 1.12 environment at the repository or extracted-bundle
root. The manifest pins `VLDataScienceMachineLearningPackage` to the vendored
source under `code/`; no remote course package is installed during class.

Complete the [Week 0 setup and system check](weeks/week-00/README.md) before the
first scheduled meeting. The short commands below are the environment core of that
guided onboarding sequence:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
```

Week 0 verifies the notebook kernel, plotting, local source loading, and tests.
Weekly notebooks then load their local `Include.jl`, which delegates to the shared root
bootstrap and activates this environment. There are no lecture- or lab-specific
Julia environments.

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
