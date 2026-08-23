#!/usr/bin/env python3
"""Build a deterministic, student-facing weekly course bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import zipfile


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
ROOT_FILES = ("Include.jl", "Project.toml", "Manifest.toml", "LICENSE")
PACKAGE_PATHS = ("code/Project.toml", "code/src")
SKIP_NAMES = {".DS_Store", ".AppleDouble", "__pycache__", ".ipynb_checkpoints"}
AUTHOR_PATH_MARKERS = (b"/Users/", b"\\Users\\", b"Desktop/julia_work", b"jl_notebook_cell_")
VERSION = re.compile(r"^(\d+)\.(\d+)$")
TAG = re.compile(r"^week-(\d{2})\.(\d+)$")
ZIP_TIME = (1980, 1, 1, 0, 0, 0)


class BuildError(RuntimeError):
    """A release manifest or bundle violated a release invariant."""


def manifest_path(value: str, label: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise BuildError(f"{label} must be a relative path inside the week: {value!r}")
    return path


def is_excluded(source: Path, exclusions: set[Path]) -> bool:
    resolved = source.resolve()
    return any(resolved == item or item in resolved.parents for item in exclusions)


def copy_student_path(source: Path, destination: Path, exclusions: set[Path]) -> None:
    if is_excluded(source, exclusions):
        return
    if source.is_symlink():
        raise BuildError(f"symbolic links are not allowed in student bundles: {source}")
    if source.name in SKIP_NAMES or source.name.endswith("-checkpoint.ipynb"):
        return
    if re.search(r"(?:^|[-_])solution(?:\.|[-_])", source.name, re.IGNORECASE):
        raise BuildError(f"solution file is not listed as instructor-only: {source}")
    if source.is_dir():
        destination.mkdir(parents=True, exist_ok=True)
        for child in sorted(source.iterdir(), key=lambda item: item.name):
            copy_student_path(child, destination / child.name, exclusions)
        return
    if not source.is_file():
        raise BuildError(f"student path is not a regular file: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bundle_files(bundle: Path) -> list[Path]:
    return sorted(path for path in bundle.rglob("*") if path.is_file())


def write_bundle_readme(bundle: Path, week: int, tag: str, title: str) -> None:
    guide = f"weeks/week-{week:02d}/README.md"
    content = f"""# CHEME 4800/5800 Fall 2026: Week {week:02d}

{title}

This is the student bundle for release `{tag}`. Start from this directory, which
contains the pinned Julia environment used by every included notebook.

## Setup

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using VLDataScienceMachineLearningPackage; println("SETUP-OK")'
```

Then open the [Week {week:02d} guide]({guide}) for the class-meeting sequence.
"""
    (bundle / "README.md").write_text(content, encoding="utf-8")


def validate_notebook_paths(bundle: Path, week_root: Path, manifest: dict) -> None:
    for field in ("entry_notebooks", "supporting_notebooks"):
        for raw in manifest.get(field, []):
            relative = manifest_path(raw, field)
            path = week_root / relative
            if not path.is_file():
                raise BuildError(f"{field} entry is missing from the bundle: {relative}")
            try:
                notebook = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, ValueError) as error:
                raise BuildError(f"cannot read notebook {relative}: {error}") from error
            if notebook.get("nbformat") != 4:
                raise BuildError(f"notebook does not use nbformat 4: {relative}")

    for raw in manifest.get("datasets", []):
        relative = manifest_path(raw, "datasets")
        if not (week_root / relative).is_file():
            raise BuildError(f"dataset is missing from the bundle: {relative}")


def validate_bundle(bundle: Path) -> None:
    for path in bundle.rglob("*"):
        if path.name in SKIP_NAMES or path.name in {".git", ".github", ".vscode", "private", "instructor"}:
            raise BuildError(f"prohibited path was copied into the bundle: {path.relative_to(bundle)}")
        if re.search(r"(?:^|[-_])solution(?:\.|[-_])", path.name, re.IGNORECASE):
            raise BuildError(f"solution leaked into the bundle: {path.relative_to(bundle)}")

    for path in bundle_files(bundle):
        data = path.read_bytes()
        for marker in AUTHOR_PATH_MARKERS:
            if marker in data:
                raise BuildError(
                    f"author-machine path leaked into {path.relative_to(bundle)}: "
                    f"found {marker.decode(errors='replace')!r}"
                )


def write_inventory(bundle: Path) -> None:
    lines = ["SHA-256                                                          Bytes  Path"]
    for path in bundle_files(bundle):
        relative = path.relative_to(bundle).as_posix()
        lines.append(f"{sha256(path)}  {path.stat().st_size:>10}  {relative}")
    lines.append("")
    (bundle / "FILE-INVENTORY.txt").write_text("\n".join(lines), encoding="utf-8")


def write_zip(bundle: Path, archive: Path) -> None:
    temporary = archive.with_suffix(archive.suffix + ".tmp")
    if temporary.exists():
        temporary.unlink()
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_STORED) as output:
            for path in bundle_files(bundle):
                archive_name = f"{bundle.name}/{path.relative_to(bundle).as_posix()}"
                info = zipfile.ZipInfo(archive_name, date_time=ZIP_TIME)
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                output.writestr(info, path.read_bytes())
        os.replace(temporary, archive)
    finally:
        if temporary.exists():
            temporary.unlink()


def require_clean_repository() -> None:
    result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=normal"],
        cwd=REPOSITORY_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    if result.stdout.strip():
        raise BuildError("the repository has uncommitted changes; commit them before a release build")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("week", type=int, help="week number, for example 1 or 01")
    parser.add_argument("--output-dir", default="dist", help="artifact directory (default: dist)")
    parser.add_argument("--expected-tag", help="require manifest version to match this release tag")
    parser.add_argument("--allow-dirty", action="store_true", help="allow a local test build from uncommitted files")
    parser.add_argument("--force", action="store_true", help="replace existing local artifacts")
    args = parser.parse_args()

    if args.week < 0 or args.week > 99:
        raise BuildError("week must be between 0 and 99")
    if not args.allow_dirty:
        require_clean_repository()

    week_name = f"week-{args.week:02d}"
    source_week = REPOSITORY_ROOT / "weeks" / week_name
    manifest_file = source_week / "release.toml"
    if not manifest_file.is_file():
        raise BuildError(f"missing release manifest: {manifest_file}")
    manifest = tomllib.loads(manifest_file.read_text(encoding="utf-8"))
    if manifest.get("week") != args.week:
        raise BuildError(f"manifest week does not match requested week {args.week}")
    if manifest.get("status") not in {"ready", "released"}:
        raise BuildError("manifest status must be 'ready' or 'released'")

    version = str(manifest.get("version", ""))
    match = VERSION.fullmatch(version)
    if match is None:
        raise BuildError("manifest version must have the form MAJOR.PATCH, for example 1.0")
    release_patch = int(match.group(2))
    tag = f"week-{args.week:02d}.{release_patch}"
    if args.expected_tag:
        tag_match = TAG.fullmatch(args.expected_tag)
        if tag_match is None or int(tag_match.group(1)) != args.week or int(tag_match.group(2)) != release_patch:
            raise BuildError(f"manifest version {version!r} does not match tag {args.expected_tag!r}")

    title = str(manifest.get("title", "")).strip()
    if not title:
        raise BuildError("manifest title is required")
    student_paths = manifest.get("student_paths")
    if not isinstance(student_paths, list) or not student_paths:
        raise BuildError("manifest student_paths must be a nonempty list")

    exclusions = {
        (source_week / raw).resolve()
        for raw in manifest.get("instructor_only_paths", [])
    }
    output_dir = (REPOSITORY_ROOT / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    bundle_name = f"CHEME-4800-5800-Fall-2026-Week-{args.week:02d}.{release_patch}"
    archive = output_dir / f"{bundle_name}.zip"
    checksum = output_dir / f"{bundle_name}.zip.sha256"
    notes = output_dir / f"RELEASE-NOTES-{tag}.md"
    existing = [path for path in (archive, checksum, notes) if path.exists()]
    if existing and not args.force:
        raise BuildError("artifact already exists; pass --force for a local rebuild: " + ", ".join(map(str, existing)))

    with tempfile.TemporaryDirectory(prefix=f"{week_name}-", dir=output_dir) as temporary:
        bundle = Path(temporary) / bundle_name
        bundle.mkdir()
        for raw in ROOT_FILES + PACKAGE_PATHS:
            source = REPOSITORY_ROOT / raw
            if not source.exists():
                raise BuildError(f"required root path is missing: {raw}")
            copy_student_path(source, bundle / raw, exclusions=set())

        destination_week = bundle / "weeks" / week_name
        for raw in student_paths:
            relative = manifest_path(raw, "student_paths")
            source = source_week / relative
            if not source.exists():
                raise BuildError(f"student path does not exist: {relative}")
            copy_student_path(source, destination_week / relative, exclusions)

        write_bundle_readme(bundle, args.week, tag, title)
        validate_notebook_paths(bundle, destination_week, manifest)
        validate_bundle(bundle)
        write_inventory(bundle)
        write_zip(bundle, archive)

    archive_digest = sha256(archive)
    checksum.write_text(f"{archive_digest}  {archive.name}\n", encoding="utf-8")
    notes.write_text(
        f"""## Week {args.week:02d}: {title}

Download **`{archive.name}`** under **Assets** and extract it. Do not use GitHub's
automatically generated Source code ZIP or tarball; those contain the authoring
repository rather than the student bundle.

The attached `{checksum.name}` file contains the SHA-256 checksum.
""",
        encoding="utf-8",
    )

    print(f"tag={tag}")
    print(f"archive={archive}")
    print(f"checksum={checksum}")
    print(f"notes={notes}")
    print(f"sha256={archive_digest}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (BuildError, OSError, subprocess.CalledProcessError) as error:
        print(f"build-week: {error}", file=sys.stderr)
        sys.exit(1)
