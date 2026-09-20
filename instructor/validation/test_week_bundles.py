"""Check that weekly bundles include lab solutions, retain exclusions, and respect the release scope."""
import importlib.util
from pathlib import Path, PurePosixPath
import re
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("build_week", ROOT / "scripts/build_week.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class WeeklyBundleTests(unittest.TestCase):
    def test_student_and_reference_files_are_both_preserved(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            student = b'# TODO: implement the lab function\n'
            solution = b'return 42\n'
            (source / "Compute.jl").write_bytes(student)
            (source / "Compute-solution.jl").write_bytes(solution)
            bundle = root / "bundle"
            builder.copy_student_path(source, bundle / "weeks/week-05/L5b/src", set())
            builder.validate_bundle(bundle)
            self.assertEqual((bundle / "weeks/week-05/L5b/src/Compute.jl").read_bytes(), student)
            self.assertEqual((bundle / "weeks/week-05/L5b/src/Compute-solution.jl").read_bytes(), solution)

    def test_explicit_instructor_exclusions_still_apply(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            private = source / "instructor"
            private.mkdir()
            (private / "notes.md").write_text("Instructor notes")
            (source / "Compute-solution.jl").write_text("return 42\n")
            bundle = root / "bundle"
            builder.copy_student_path(source, bundle, {private.resolve()})
            builder.validate_bundle(bundle)
            self.assertFalse((bundle / "instructor").exists())
            self.assertTrue((bundle / "Compute-solution.jl").is_file())

    def test_instructor_directory_is_rejected_if_copied(self):
        with tempfile.TemporaryDirectory() as temporary:
            bundle = Path(temporary)
            (bundle / "instructor").mkdir()
            with self.assertRaisesRegex(builder.BuildError, "prohibited path"):
                builder.validate_bundle(bundle)

    def test_author_machine_paths_in_solutions_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            bundle = Path(temporary)
            (bundle / "Compute-solution.jl").write_text('include("/Users/instructor/local.jl")\n')
            with self.assertRaisesRegex(builder.BuildError, "author-machine path"):
                builder.validate_bundle(bundle)

    def test_every_reference_solution_is_selected_by_its_manifest(self):
        references = sorted((ROOT / "weeks").glob("week-*/*/src/Compute-solution.jl"))
        self.assertTrue(references)
        for reference in references:
            with self.subTest(reference=reference.relative_to(ROOT)):
                week = reference.parents[2]
                manifest = tomllib.loads((week / "release.toml").read_text())
                exclusions = {(week / p).resolve() for p in manifest.get("instructor_only_paths", [])}
                self.assertFalse(builder.is_excluded(reference, exclusions))
                if manifest.get("cadence") == "meeting":
                    # A partial release may not have reached this meeting yet; it is
                    # selected once the patch number does, provided it is a meeting folder.
                    meeting = reference.relative_to(week).parts[0]
                    self.assertIn(meeting, builder.meeting_folders(week))
                else:
                    selected = [(week / p).resolve() for p in manifest["student_paths"]]
                    self.assertTrue(any(p == reference or p in reference.parents for p in selected))
                self.assertTrue(reference.with_name("Compute.jl").is_file())


def _week_with_meetings(root: Path, *meetings: str) -> Path:
    week = root / "week-06"
    for name in meetings + ("src",):
        (week / name).mkdir(parents=True)
    (week / "README.md").write_text("# Week 6\n")
    return week


class ReleaseScopeTests(unittest.TestCase):
    def test_patch_number_names_the_last_meeting_included(self):
        with tempfile.TemporaryDirectory() as temporary:
            week = _week_with_meetings(Path(temporary), "L6a", "L6b", "L6c", "L6d")
            manifest = {"cadence": "meeting"}
            first = builder.release_scope(manifest, week, 6, 0)
            self.assertEqual(first["included"], ["L6a"])
            self.assertFalse(first["complete"])
            self.assertEqual(first["title"], "CHEME 4800/5800 - Week 06 (L6a)")
            second = builder.release_scope(manifest, week, 6, 1)
            self.assertEqual(second["included"], ["L6a", "L6b"])
            self.assertEqual(second["label"], "L6a\u2013L6b")
            last = builder.release_scope(manifest, week, 6, 3)
            self.assertTrue(last["complete"])
            self.assertEqual(last["title"], "CHEME 4800/5800 - Week 06")
            fix = builder.release_scope(manifest, week, 6, 5)
            self.assertEqual(fix["included"], ["L6a", "L6b", "L6c", "L6d"])
            self.assertTrue(fix["complete"])

    def test_legacy_manifests_release_the_whole_week(self):
        with tempfile.TemporaryDirectory() as temporary:
            week = _week_with_meetings(Path(temporary), "L5a", "L5b", "L5c", "L5d")
            scope = builder.release_scope({}, week, 5, 0)
            self.assertEqual(scope["included"], ["L5a", "L5b", "L5c", "L5d"])
            self.assertTrue(scope["complete"])
            self.assertEqual(scope["title"], "CHEME 4800/5800 - Week 05")
            with self.assertRaisesRegex(builder.BuildError, "cadence"):
                builder.release_scope({"cadence": "daily"}, week, 5, 0)

    def test_student_paths_must_match_the_tag(self):
        with tempfile.TemporaryDirectory() as temporary:
            week = _week_with_meetings(Path(temporary), "L6a", "L6b", "L6c", "L6d")
            scope = builder.release_scope({"cadence": "meeting"}, week, 6, 1)
            builder.validate_scope(["README.md", "L6a", "L6b", "src"], scope)
            with self.assertRaisesRegex(builder.BuildError, "student_paths"):
                builder.validate_scope(["README.md", "L6a", "L6b", "L6c", "L6d", "src"], scope)
            with self.assertRaisesRegex(builder.BuildError, "student_paths"):
                builder.validate_scope(["README.md", "L6a"], scope)
            legacy = builder.release_scope({}, week, 6, 0)
            builder.validate_scope(["README.md", "L6a"], legacy)

    def test_manifest_entries_outside_the_release_are_ignored(self):
        with tempfile.TemporaryDirectory() as temporary:
            week = _week_with_meetings(Path(temporary), "L6a", "L6b", "L6c", "L6d")
            scope = builder.release_scope({"cadence": "meeting"}, week, 6, 0)
            self.assertTrue(builder.in_scope(PurePosixPath("L6a/notebook.ipynb"), scope))
            self.assertFalse(builder.in_scope(PurePosixPath("L6c/data/x.csv"), scope))
            self.assertTrue(builder.in_scope(PurePosixPath("src/Week06Core.jl"), scope))

    def test_repository_manifests_are_consistent_with_their_version(self):
        for manifest_file in sorted((ROOT / "weeks").glob("week-*/release.toml")):
            with self.subTest(manifest=manifest_file.relative_to(ROOT)):
                manifest = tomllib.loads(manifest_file.read_text())
                week = manifest_file.parent
                version = str(manifest.get("version", "")).removesuffix("-prototype")
                match = re.fullmatch(r"(\d+)\.(\d+)", version)
                self.assertIsNotNone(match, f"unparseable version {version!r}")
                scope = builder.release_scope(manifest, week, int(manifest["week"]), int(match.group(2)))
                builder.validate_scope(manifest["student_paths"], scope)


if __name__ == "__main__":
    unittest.main()
