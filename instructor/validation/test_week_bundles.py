"""Check that weekly bundles include lab solutions and retain exclusions."""
import importlib.util
from pathlib import Path
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
                selected = [(week / p).resolve() for p in manifest["student_paths"]]
                self.assertTrue(any(p == reference or p in reference.parents for p in selected))
                self.assertTrue(reference.with_name("Compute.jl").is_file())


if __name__ == "__main__":
    unittest.main()
