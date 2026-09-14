import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from bazelutil.query import main as main_module
from bazelutil.query.main import main, query_command, write_if_changed


class Args:
    def __init__(self, manifest):
        self.manifest = manifest


class QueryCommandTest(unittest.TestCase):
    def test_asks_for_one_union_with_only_the_tags_attribute(self):
        command = query_command(
            [
                {"kind": ".*_test", "tag": "unit", "exclude": [], "out": "a.bzl"},
                {"kind": "cjs_root", "tag": None, "exclude": [], "out": "b.bzl"},
            ]
        )
        self.assertEqual(command[:2], ["bazel", "query"])
        self.assertEqual(
            command[2],
            "(attr('tags', '[\\[ ]unit[,\\]]', kind('.*_test', //...))) "
            "+ (kind('cjs_root', //...))",
        )
        self.assertIn("--output=streamed_jsonproto", command)
        self.assertIn("--proto:output_rule_attrs=tags", command)


class WriteIfChangedTest(unittest.TestCase):
    def test_writes_new_content(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "out.bzl"
            write_if_changed(path, "a\n")
            self.assertEqual(path.read_text(), "a\n")

    def test_leaves_an_unchanged_file_alone(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "out.bzl"
            path.write_text("a\n")
            before = path.stat().st_mtime_ns
            write_if_changed(path, "a\n")
            self.assertEqual(path.stat().st_mtime_ns, before)

    def test_leaves_no_temporary_file_behind(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "out.bzl"
            write_if_changed(path, "a\n")
            self.assertEqual([p.name for p in Path(directory).iterdir()], ["out.bzl"])


class FailedQueryTest(unittest.TestCase):
    """The shell version piped a failing query into a read loop, which wrote an
    empty list over a good one."""

    def run_main(self, returncode, stdout, directory):
        manifest = Path(directory) / "manifest.json"
        manifest.write_text(
            json.dumps([{"kind": "cjs_root", "tag": None, "exclude": [], "out": "out.bzl"}])
        )
        completed = subprocess.CompletedProcess([], returncode, stdout=stdout)
        with patch.dict("os.environ", {"BUILD_WORKSPACE_DIRECTORY": directory}):
            with patch.object(main_module.subprocess, "run", return_value=completed):
                main(Args(str(manifest)))

    def test_failed_query_exits_and_writes_nothing(self):
        with TemporaryDirectory() as directory:
            out = Path(directory) / "out.bzl"
            out.write_text('TARGETS = [\n    "//a:b",\n]\n')
            with self.assertRaises(SystemExit) as caught:
                self.run_main(1, "", directory)
            self.assertEqual(caught.exception.code, 1)
            self.assertEqual(out.read_text(), 'TARGETS = [\n    "//a:b",\n]\n')

    def test_successful_query_writes_the_list(self):
        with TemporaryDirectory() as directory:
            line = json.dumps(
                {
                    "type": "RULE",
                    "rule": {"name": "//a:b", "ruleClass": "cjs_root", "attribute": []},
                }
            )
            self.run_main(0, line + "\n", directory)
            self.assertEqual(
                (Path(directory) / "out.bzl").read_text(),
                'TARGETS = [\n    "//a:b",\n]\n',
            )

    def test_a_dead_exclusion_exits_without_writing(self):
        with TemporaryDirectory() as directory:
            manifest = Path(directory) / "manifest.json"
            manifest.write_text(
                json.dumps(
                    [
                        {
                            "kind": "cjs_root",
                            "tag": None,
                            "exclude": ["//gone:gone"],
                            "out": "out.bzl",
                        }
                    ]
                )
            )
            completed = subprocess.CompletedProcess([], 0, stdout="")
            with patch.dict("os.environ", {"BUILD_WORKSPACE_DIRECTORY": directory}):
                with patch.object(
                    main_module.subprocess, "run", return_value=completed
                ):
                    with self.assertRaises(SystemExit) as caught:
                        main(Args(str(manifest)))
            self.assertIn("//gone:gone", str(caught.exception.code))
            self.assertFalse((Path(directory) / "out.bzl").exists())


if __name__ == "__main__":
    unittest.main()
