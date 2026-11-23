# Fix: notebook crash when `using` must compile a package

Found 2026-11-23 in the L14a gene circuits example. The fix is one edit to the
root `Include.jl`, released as `week-14.3`.

## Symptom

Running the include cell of `CHEME-5800-L14a-Example-GeneCircuits-Fall-2026.ipynb`
in a VS Code notebook stopped with:

```
LoadError: MethodError: no method matching pipe_writer(::VSCodeServer.IJuliaCore.IJuliaStdio{...})
The applicable method may be too new: running in world age 38707, while current world is 39152.
in expression starting at .../weeks/week-14/L14a/Include.jl:63
```

Line 63 is `import SteadyStateDiffEq`.

## Cause

- `SteadyStateDiffEq` and its dependency `DiffEqCallbacks` are new in week 14.
  They had not been downloaded or compiled yet.
- So `import SteadyStateDiffEq` started a compile inside the notebook.
- Julia 1.12 loads packages in the "world age" fixed when Julia started.
  The VS Code notebook output stream is defined later, so code in that world
  cannot print to it.
- The compile crashed when it printed its summary.
- The stack trace confirms this: the print comes from `precompilepkgs`, called by
  `require`.

This is a bug in the VS Code Julia extension (1.250.2) with Julia 1.12.
It is not a bug in the course code.

It can hit any student whose packages are not compiled yet. This includes the
course package in every newly extracted bundle folder.

## Fix

In the root `Include.jl`, add `Pkg.instantiate()` after the project activation
and before `using VLDataScienceMachineLearningPackage`.

`Pkg.instantiate()` installs anything missing and then compiles the whole course
environment through Pkg. Pkg runs in the current world, so it can print to the
notebook. The `using` and `import` lines that follow then find compiled caches
and print nothing.

Every weekly `Include.jl` loads the root file in a fresh kernel, so this one
edit covers every week.

Replace lines 17–24 of `Include.jl`:

```julia
# Switch projects only when the course environment is not already active -
let active_project = Base.active_project()
    if isnothing(active_project) || normpath(active_project) != normpath(CHEME5800_PROJECT)
        Pkg.activate(CHEME5800_ROOT)
    end
end

using VLDataScienceMachineLearningPackage # exported course models and algorithms, including L4c shortest paths
```

with:

```julia
# Switch projects only when the course environment is not already active -
let active_project = Base.active_project()
    if isnothing(active_project) || normpath(active_project) != normpath(CHEME5800_PROJECT)
        Pkg.activate(CHEME5800_ROOT)
    end
end

# Install and compile the course packages here, before any `using` line.
# In a VS Code notebook on Julia 1.12, a compile started by `using` crashes when
# it prints its progress. A compile run by Pkg does not. When nothing is missing,
# this check takes about 1.5 s.
Pkg.instantiate()

using VLDataScienceMachineLearningPackage # exported course models and algorithms, including L4c shortest paths
```

## Check on the development machine

1. Make the edit above.
2. From the repository root, run each check:

   ```bash
   julia --project=. -e 'include("weeks/week-14/L14a/Include.jl"); println("INCLUDE-OK")'
   julia --startup-file=no --project=. instructor/validation/week-14/runtests.jl
   python3 instructor/validation/notebook_style_check.py --strict weeks/week-14/L14a/*.ipynb
   ```

3. Optional: open the L14a gene circuits example in VS Code.
   Restart the kernel and run the include cell.

## Release

1. In `weeks/week-14/release.toml`, change `version = "1.2"` to `version = "1.3"`.
2. Commit `Include.jl`, `release.toml`, and this file to `main`, then push.
3. Tag and push:

   ```bash
   git tag -a week-14.3 -m "Week 14: Linear state space models and practicum launch"
   git push origin week-14.3
   ```

4. The release Action builds a draft and runs every `Include.jl` in the bundle.
   Publish the draft when it passes.

## Student announcement

> If the L14a setup cell gives a `MethodError` about `pipe_writer`, download the
> week-14.3 bundle. Or, from a terminal in your week-14 bundle folder, run
> `julia --project=. -e 'using Pkg; Pkg.instantiate()'`.
> Then restart the notebook kernel and run the setup cell again.

## What was tested

- The crash: the same world age, 38707, appeared in a stand-in for the notebook
  output stream (a pipe type defined after Julia starts).
  - `using` alone gave the `MethodError`.
  - `Pkg.precompile()` and then `using` ran with no error.
  - `Pkg.instantiate()` and then `using` ran with no error. This is the fix.
- On the course environment, a `Pkg.instantiate()` with nothing to do takes
  1.4 s.
- Not tested: the fix inside a real VS Code notebook. Step 3 of the check above
  covers that.
