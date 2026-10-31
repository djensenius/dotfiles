#!/usr/bin/env python3
"""Temporary-only cleanup fixtures; native lock/forwarding tests require macOS."""

import contextlib
import errno
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import plistlib
import select
import shutil
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest import mock


sys.dont_write_bytecode = True
BIN = Path(__file__).resolve().parents[1] / "bin"
HELPER = BIN / "xbuild-cleanup-derived-data.py"
spec = importlib.util.spec_from_file_location("xbuild_cleanup", HELPER)
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class Fixture(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="xbuild-test-")
        self.addCleanup(temporary.cleanup)
        # macOS's /var and /tmp aliases are symlinks; production rejects linked
        # ancestors, so use the fixture's real absolute location.
        self.base = Path(temporary.name).resolve()
        self.root = self.base / "DerivedData"
        self.workspaces = self.base / "workspaces"
        self.home = self.base / "home"
        for path in (self.root, self.workspaces, self.home):
            path.mkdir()
        self.now = time.time_ns()
        self.old = self.now - cleanup.MIN_AGE_NS - 1_000_000_000
        self.environment = mock.patch.dict(os.environ, {
            "HOME": str(self.home),
            "XBUILD_DERIVED_DATA_ROOT": str(self.root),
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def age(self, entry, mtime=None):
        mtime = self.old if mtime is None else mtime
        for parent, directories, files in os.walk(entry, followlinks=False):
            for name in directories + files:
                os.utime(Path(parent) / name, ns=(mtime, mtime), follow_symlinks=False)
            os.utime(parent, ns=(mtime, mtime), follow_symlinks=False)

    def entry(self, name="App-hash", workspace=None, fmt=plistlib.FMT_XML):
        path = self.root / name
        (path / "Build" / "Products").mkdir(parents=True)
        (path / "Build" / "Products" / "artifact").write_bytes(b"fixture build data")
        metadata = {"WorkspacePath": str(workspace or self.workspaces / "Gone.xcworkspace")}
        (path / "info.plist").write_bytes(plistlib.dumps(metadata, fmt=fmt))
        self.age(path)
        return path

    def run_cleanup(self, delete=False):
        output = io.StringIO()
        errors = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            status = cleanup.cleanup(str(self.root), delete, now_ns=self.now)
        return status, output.getvalue(), errors.getvalue()

    def snapshot(self, root):
        result = {}
        for parent, directories, files in os.walk(root, followlinks=False):
            for path in [Path(parent)] + [Path(parent) / name for name in directories + files]:
                info = path.lstat()
                content = None
                if path.is_symlink():
                    content = os.readlink(path)
                elif path.is_file():
                    content = path.read_bytes()
                result[str(path.relative_to(root))] = (
                    cleanup.signature(info), content,
                )
        return result

    def mutate_after_selection(self, mutation):
        inspect = cleanup.inspect_entry
        calls = 0

        def intercept(*args):
            nonlocal calls
            result = inspect(*args)
            calls += 1
            if calls == 1:
                mutation()
            return result

        return mock.patch.object(cleanup, "inspect_entry", side_effect=intercept)


class CleanupTests(Fixture):
    def test_default_and_explicit_dry_run_are_nonmutating(self):
        self.entry("XML with spaces-hash")
        self.entry("Binary-hash", fmt=plistlib.FMT_BINARY)
        before = self.snapshot(self.root)
        for arguments in ([], ["--dry-run"]):
            with self.subTest(arguments=arguments), contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(cleanup.main(arguments), 0)
                self.assertEqual(output.getvalue().count("WOULD DELETE"), 2)
            self.assertEqual(self.snapshot(self.root), before)

    def test_delete_selects_only_old_xml_binary_and_missing_implicit_projects(self):
        removed = [
            self.entry("XML-hash"),
            self.entry("Binary-hash", fmt=plistlib.FMT_BINARY),
            self.entry("Implicit-hash", self.workspaces / "Gone.xcodeproj" / "project.xcworkspace"),
            self.entry("Project-hash", self.workspaces / "Gone.xcodeproj"),
        ]
        active = self.workspaces / "Active.xcworkspace"
        active.mkdir()
        kept = self.entry("Active-hash", active)
        status, output, errors = self.run_cleanup(delete=True)
        self.assertEqual((status, errors), (0, ""))
        self.assertEqual(output.count("DELETED "), len(removed))
        self.assertTrue(all(not path.exists() for path in removed))
        self.assertTrue(kept.is_dir())
        self.assertTrue(active.is_dir())
        self.assertTrue(self.root.is_dir())

    def test_recursive_newest_mtime_including_metadata_and_future_dates(self):
        for index, relative in enumerate((".", "info.plist", "Build", "Build/Products/artifact")):
            path = self.entry(f"Recent-{index}")
            os.utime(path / relative, ns=(self.now, self.now))
        future = self.entry("Future-hash")
        os.utime(future / "info.plist", ns=(self.now, self.now + cleanup.MIN_AGE_NS))
        status, output, _ = self.run_cleanup(delete=True)
        self.assertEqual(status, 0)
        self.assertEqual(output.count("KEEP "), 5)
        self.assertEqual(len(list(self.root.iterdir())), 5)

    def test_exact_seven_day_boundary_is_inclusive(self):
        eligible = self.entry("Exactly-seven-days")
        recent = self.entry("One-nanosecond-too-recent")
        self.age(eligible, self.now - cleanup.MIN_AGE_NS)
        self.age(recent, self.now - cleanup.MIN_AGE_NS + 1)
        self.assertEqual(self.run_cleanup(delete=True)[0], 0)
        self.assertFalse(eligible.exists())
        self.assertTrue(recent.exists())

    def test_existing_workspaces_projects_and_dangling_links_are_kept(self):
        active = self.workspaces / "Active.xcworkspace"
        active.mkdir()
        project = self.workspaces / "Active.xcodeproj"
        project.mkdir()
        file = self.workspaces / "File.xcworkspace"
        file.touch()
        linked = self.workspaces / "Linked.xcworkspace"
        linked.symlink_to(active)
        dangling = self.workspaces / "Dangling.xcworkspace"
        dangling.symlink_to(self.workspaces / "Absent.xcworkspace")
        parent_link = self.base / "linked-parent"
        parent_link.symlink_to(self.workspaces)
        paths = (
            active, project, file, linked, dangling,
            project / "project.xcworkspace", parent_link / "Gone.xcworkspace",
        )
        for index, path in enumerate(paths):
            self.entry(f"Keep-{index}", path)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), len(paths))
        self.assertEqual(len(list(self.root.iterdir())), len(paths))

    def test_malformed_missing_unrecognized_and_duplicate_metadata_are_kept(self):
        invalid = [
            b"not a plist", b"bplist00broken", plistlib.dumps([]),
            plistlib.dumps({}), plistlib.dumps({"WorkspacePath": 42}),
            plistlib.dumps({"WorkspacePath": "/unrecognized.txt"}),
            plistlib.dumps({"WorkspacePath": "relative.xcworkspace"}),
            plistlib.dumps({"WorkspacePath": "file:///Gone.xcworkspace"}),
            plistlib.dumps({"WorkspacePath": str(self.workspaces) + "/../Gone.xcworkspace"}),
            plistlib.dumps({"WorkspacePath": "//Gone.xcworkspace"}),
            plistlib.dumps({"WorkspacePath": str(self.workspaces) + "/Gone.xcworkspace/"}),
            plistlib.dumps({"WorkspacePath": str(self.workspaces) + "/Bad\nName.xcworkspace"}),
            plistlib.dumps({"WorkspacePath": str(self.workspaces / ".xcworkspace")}),
            plistlib.dumps({"WorkspacePath": str(self.root / "Gone.xcworkspace")}),
            plistlib.dumps({"WorkspacePath": str(self.workspaces / "Gone.xcodeproj/Other.xcworkspace")}),
            b"<plist><dict><key>WorkspacePath</key><string>/Gone.xcworkspace</string>"
            b"<key>WorkspacePath</key><string>/Other.xcworkspace</string></dict></plist>",
            b"x" * (1024 * 1024 + 1),
        ]
        for index, data in enumerate(invalid):
            entry = self.entry(f"Invalid-{index}")
            (entry / "info.plist").write_bytes(data)
            self.age(entry)
        missing = self.entry("No-metadata")
        (missing / "info.plist").unlink()
        self.age(missing)
        (self.root / "Not-a-directory").write_text("keep")
        before = self.snapshot(self.root)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), len(invalid) + 2)
        self.assertEqual(self.snapshot(self.root), before)

    def test_parser_attribute_and_index_errors_preserve_only_bad_entries(self):
        malformed = {
            "Malformed-date": (
                b'<plist version="1.0"><dict><key>WorkspacePath</key>'
                b'<date>not-a-date</date></dict></plist>'
            ),
            "Malformed-key": b'<plist version="1.0"><key>WorkspacePath</key></plist>',
        }
        entries = {}
        for name, data in malformed.items():
            entries[name] = self.entry(name)
            (entries[name] / "info.plist").write_bytes(data)
            self.age(entries[name])
        eligible = self.entry("Z-Eligible-after-malformed")

        status, output, errors = self.run_cleanup(delete=True)

        self.assertEqual((status, errors), (0, ""))
        self.assertEqual(output.count("KEEP "), len(malformed))
        self.assertEqual(output.count("DELETED "), 1)
        for name, data in malformed.items():
            self.assertTrue(entries[name].is_dir())
            self.assertEqual((entries[name] / "info.plist").read_bytes(), data)
        self.assertFalse(eligible.exists())

    def test_shared_caches_are_kept_even_with_misleading_orphan_metadata(self):
        names = sorted(cleanup.SHARED_CACHES) + [
            "ModuleCache.noindex", "SDKStatCaches.noindex", "CompilationCache.noindex",
            "SymbolCache.noindex", "UnknownCache.noindex", "Cache.nosync", ".hidden",
        ]
        for name in names:
            self.entry(name)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), len(names))
        self.assertEqual(len(list(self.root.iterdir())), len(names))

    def test_linked_entries_metadata_nested_links_and_hardlinks_are_kept(self):
        outside = self.entry("Outside")
        outside = outside.rename(self.base / "outside")
        (self.root / "Linked-entry").symlink_to(outside)
        (self.root / "Dangling-entry").symlink_to(self.base / "missing")
        metadata = self.entry("Linked-metadata")
        (metadata / "info.plist").unlink()
        (metadata / "info.plist").symlink_to(outside / "info.plist")
        nested = self.entry("Nested-link")
        (nested / "Build" / "linked").symlink_to(outside)
        hardlink = self.entry("Hardlinked-file")
        os.link(outside / "Build/Products/artifact", hardlink / "hardlink")
        for entry in (metadata, nested, hardlink):
            self.age(entry)
        before = self.snapshot(outside)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), 5)
        self.assertEqual(self.snapshot(outside), before)
        self.assertEqual(len(list(self.root.iterdir())), 5)

    def test_unsafe_missing_and_symlinked_roots_are_refused(self):
        self.entry()
        linked = self.base / "linked-root"
        linked.symlink_to(self.root)
        ancestor = self.base / "linked-ancestor"
        ancestor.symlink_to(self.base)
        file = self.base / "file"
        file.touch()
        roots = (
            "", ".", "/", "/Users", str(self.home), str(self.base), os.getcwd(),
            str(linked), str(ancestor / "DerivedData"), str(self.base / "missing"),
            str(file), str(self.root) + "/../DerivedData", str(self.root) + "/",
        )
        before = self.snapshot(self.root)
        for root in roots:
            with self.subTest(root=root), mock.patch.dict(os.environ, {"XBUILD_DERIVED_DATA_ROOT": root}):
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(cleanup.main(["--delete"]), 1)
        self.assertEqual(self.snapshot(self.root), before)

    def test_missing_checkout_parents_and_offline_volume_paths_are_kept(self):
        paths = [
            self.workspaces / "missing-checkout/Gone.xcworkspace",
            Path("/Volumes/unavailable/Gone.xcworkspace"),
            Path("/Network/unavailable/Gone.xcworkspace"),
            Path("/net/unavailable/Gone.xcworkspace"),
        ]
        for index, path in enumerate(paths):
            self.entry(f"Uncertain-{index}", path)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), len(paths))
        self.assertEqual(len(list(self.root.iterdir())), len(paths))

    def test_home_alias_and_missing_home_refuse_unsafe_roots(self):
        linked_home = self.base / "linked-home"
        linked_home.symlink_to(self.home)
        with mock.patch.dict(os.environ, {
            "HOME": str(linked_home), "XBUILD_DERIVED_DATA_ROOT": str(self.home),
        }), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(cleanup.main(["--delete"]), 1)
        with mock.patch.dict(os.environ), contextlib.redirect_stderr(io.StringIO()):
            del os.environ["HOME"]
            self.assertEqual(cleanup.main(["--delete"]), 1)
            del os.environ["XBUILD_DERIVED_DATA_ROOT"]
            self.assertEqual(cleanup.main(["--delete"]), 1)

    def test_workspace_permission_io_and_not_directory_errors_are_not_absence(self):
        entry = self.entry()
        real_stat = os.stat
        for code in (errno.EACCES, errno.EIO, errno.ENOTDIR, errno.ESTALE):
            def failing_stat(path, *args, **kwargs):
                if path == "Gone.xcworkspace":
                    raise OSError(code, os.strerror(code))
                return real_stat(path, *args, **kwargs)

            with self.subTest(errno=code), mock.patch.object(cleanup.os, "stat", side_effect=failing_stat):
                self.assertIn("KEEP ", self.run_cleanup(delete=True)[1])
            self.assertTrue(entry.exists())

    def test_recursive_permission_errors_preserve_the_entry(self):
        entry = self.entry()
        nested_inode = (entry / "Build").stat().st_ino
        real_listdir = os.listdir

        def failing_listdir(fd):
            if os.fstat(fd).st_ino == nested_inode:
                raise PermissionError(errno.EACCES, "fixture unreadable directory")
            return real_listdir(fd)

        with mock.patch.object(cleanup.os, "listdir", side_effect=failing_listdir):
            self.assertIn("KEEP ", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())

    def test_workspace_and_nested_filesystem_boundaries_are_kept(self):
        entry = self.entry()
        real_fstat = os.fstat
        for path in (self.workspaces, entry / "Build"):
            inode = path.stat().st_ino

            def other_device(fd):
                info = real_fstat(fd)
                if info.st_ino == inode:
                    fields = {key: getattr(info, key) for key in dir(info) if key.startswith("st_")}
                    fields["st_dev"] += 1
                    return SimpleNamespace(**fields)
                return info

            with self.subTest(path=path), mock.patch.object(cleanup.os, "fstat", side_effect=other_device):
                self.assertIn("KEEP ", self.run_cleanup(delete=True)[1])
            self.assertTrue(entry.exists())

    def test_special_files_and_hardlinked_metadata_are_kept(self):
        fifo = self.entry("Fifo-metadata")
        (fifo / "info.plist").unlink()
        os.mkfifo(fifo / "info.plist")
        hardlink = self.entry("Hardlinked-metadata")
        os.link(hardlink / "info.plist", self.base / "metadata")
        nested_fifo = self.entry("Nested-fifo")
        os.mkfifo(nested_fifo / "Build" / "fifo")
        directory = self.entry("Directory-metadata")
        (directory / "info.plist").unlink()
        (directory / "info.plist").mkdir()
        for entry in (fifo, hardlink, nested_fifo, directory):
            self.age(entry)
        self.assertEqual(self.run_cleanup(delete=True)[1].count("KEEP "), 4)
        self.assertEqual(len(list(self.root.iterdir())), 4)

    def test_workspace_restored_during_tree_scan_is_kept(self):
        entry = self.entry()
        snapshot = cleanup.tree_snapshot

        def restore(*args):
            result = snapshot(*args)
            (self.workspaces / "Gone.xcworkspace").mkdir()
            return result

        with mock.patch.object(cleanup, "tree_snapshot", side_effect=restore):
            self.assertIn("workspace or project still exists", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())

    def test_workspace_recreated_before_removal_is_kept(self):
        entry = self.entry()
        with self.mutate_after_selection(lambda: (self.workspaces / "Gone.xcworkspace").mkdir()):
            self.assertIn("revalidation", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())

    def test_recent_nested_write_before_removal_is_kept(self):
        entry = self.entry()

        def modify():
            (entry / "Build/Products/artifact").write_bytes(b"new build data")

        with self.mutate_after_selection(modify):
            self.assertIn("revalidation", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())

    def test_changed_metadata_before_removal_is_kept_even_if_backdated(self):
        entry = self.entry()

        def modify():
            (entry / "info.plist").write_bytes(plistlib.dumps({
                "WorkspacePath": str(self.workspaces / "Other.xcworkspace"),
            }))
            self.age(entry)

        with self.mutate_after_selection(modify):
            self.assertIn("entry changed since selection", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())

    def test_replaced_directory_identity_before_removal_is_kept(self):
        entry = self.entry()

        def replace():
            entry.rename(self.base / "saved")
            self.entry()

        with self.mutate_after_selection(replace):
            self.assertIn("entry changed since selection", self.run_cleanup(delete=True)[1])
        self.assertTrue(entry.exists())
        self.assertTrue((self.base / "saved").exists())

    def test_replaced_root_is_refused_without_touching_either_tree(self):
        self.entry()
        outside = self.base / "outside"
        outside.mkdir()
        sentinel = outside / "keep"
        sentinel.write_text("keep")

        def replace():
            self.root.rename(self.base / "saved-root")
            self.root.symlink_to(outside)

        with self.mutate_after_selection(replace), self.assertRaises((cleanup.Preserve, OSError)):
            self.run_cleanup(delete=True)
        self.assertEqual(sentinel.read_text(), "keep")
        self.assertTrue((self.base / "saved-root/App-hash").exists())

    def test_symlink_replacement_at_removal_never_follows_outside_root(self):
        entry = self.entry()
        outside = self.base / "outside"
        outside.mkdir()
        sentinel = outside / "keep"
        sentinel.write_text("keep")
        rmtree = shutil.rmtree

        def replace_then_remove(*args, **kwargs):
            entry.rename(self.base / "saved")
            entry.symlink_to(outside)
            return rmtree(*args, **kwargs)

        with mock.patch.object(cleanup.shutil, "rmtree", side_effect=replace_then_remove):
            status, _, errors = self.run_cleanup(delete=True)
        self.assertEqual(status, 1)
        self.assertIn("removal failed", errors)
        self.assertEqual(sentinel.read_text(), "keep")
        self.assertTrue((self.base / "saved").exists())

    def test_default_root_and_explicit_python_safety_prerequisite(self):
        default = self.home / "Library/Developer/Xcode/DerivedData"
        default.parent.mkdir(parents=True)
        self.entry()
        self.root.rename(default)
        with mock.patch.dict(os.environ):
            del os.environ["XBUILD_DERIVED_DATA_ROOT"]
            with contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(cleanup.main([]), 0)
            self.assertIn("WOULD DELETE", output.getvalue())
            for patch in (
                mock.patch.object(cleanup.sys, "version_info", (3, 10)),
                mock.patch.object(cleanup.shutil.rmtree, "avoids_symlink_attacks", False),
            ):
                with patch, contextlib.redirect_stderr(io.StringIO()) as error:
                    self.assertEqual(cleanup.main(["--delete"]), 1)
                self.assertIn("requires Python 3.11+", error.getvalue())
            self.assertTrue((default / "App-hash").exists())

    def test_unknown_or_conflicting_arguments_never_start_selection(self):
        with mock.patch.object(cleanup, "cleanup") as selection:
            for arguments in (["--force"], ["--delete", "--dry-run"], ["--delete", "--delete"]):
                with self.subTest(arguments=arguments), contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(cleanup.main(arguments), 2)
            selection.assert_not_called()


@unittest.skipUnless(sys.platform == "darwin", "native lockf descriptor tests require macOS")
class NativeWrapperTests(Fixture):
    def setUp(self):
        super().setUp()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        for name, target in (
            ("python3", sys.executable), ("bash", "/bin/bash"), ("lockf", "/usr/bin/lockf"),
        ):
            (self.bin / name).symlink_to(target)
        self.build_log = self.base / "build.json"
        self.sim_log = self.base / "sim.json"
        (self.bin / "xcodebuild").write_text(f"""#!{sys.executable}
import json, os, pathlib, sys, time
pathlib.Path(os.environ["BUILD_LOG"]).write_text(json.dumps(sys.argv[1:]))
if os.environ.get("EXPECT_DELETED") and os.path.lexists(os.environ["EXPECT_DELETED"]):
    sys.exit(93)
if os.environ.get("BUILD_READY"):
    pathlib.Path(os.environ["BUILD_READY"]).touch()
    deadline = time.monotonic() + 10
    while not pathlib.Path(os.environ["BUILD_RELEASE"]).exists():
        if time.monotonic() > deadline:
            sys.exit(94)
        time.sleep(0.01)
sys.exit(int(os.environ.get("BUILD_EXIT", "0")))
""")
        (self.bin / "xcrun").write_text(f"""#!{sys.executable}
import json, os, pathlib, sys
pathlib.Path(os.environ["SIM_LOG"]).write_text(json.dumps(sys.argv[1:]))
sys.exit(99)
""")
        for name in ("xcodebuild", "xcrun"):
            (self.bin / name).chmod(0o755)
        locks = self.base / "locks"
        locks.mkdir()
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin",
            "USER": "task31-fixture", "TMPDIR": str(locks),
            "XBUILD_DERIVED_DATA_ROOT": str(self.root),
            "BUILD_LOG": str(self.build_log), "SIM_LOG": str(self.sim_log),
            "PYTHONDONTWRITEBYTECODE": "1",
        }
        installed = self.base / "installed bin"
        installed.mkdir()
        self.wrapper = installed / "xbuild"
        (self.base / "tracked-link").symlink_to(BIN / "xbuild")
        self.wrapper.symlink_to("../tracked-link")

    def run_wrapper(self, *arguments, env=None):
        return subprocess.run(
            [str(self.wrapper), *arguments], cwd=self.base, env=env or self.env,
            text=True, capture_output=True, timeout=15,
        )

    def start_wrapper(self, arguments, env=None):
        process = subprocess.Popen(
            [str(self.wrapper), *arguments], cwd=self.base, env=env or self.env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

        def finish():
            # Release only this fixture's gates, and reap every child even when
            # an assertion fails. Never interact with other builds or locks.
            (self.base / "release").touch()
            try:
                process.communicate(timeout=15)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.communicate(timeout=5)

        self.addCleanup(finish)
        return process

    def wait_for(self, path, process):
        deadline = time.monotonic() + 5
        while not path.exists():
            if process.poll() is not None:
                output, error = process.communicate()
                self.fail(f"fixture exited before gate ({process.returncode}): {output}{error}")
            if time.monotonic() > deadline:
                self.fail(f"fixture did not reach gate: {path}")
            time.sleep(0.01)

    def assert_waiting(self, process):
        ready, _, _ = select.select([process.stderr], [], [], 5)
        self.assertTrue(ready, "contender did not report native lock contention")
        self.assertIn("waiting for the lock", process.stderr.readline())
        self.assertIsNone(process.poll())

    def test_installed_symlink_default_dry_run_and_explicit_delete(self):
        entry = self.entry()
        for flags in ([], ["--dry-run"]):
            result = self.run_wrapper("cleanup-derived-data", *flags)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("WOULD DELETE", result.stdout)
            self.assertTrue(entry.exists())
        result = self.run_wrapper("cleanup-derived-data", "--delete")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DELETED", result.stdout)
        self.assertFalse(entry.exists())
        self.assertFalse(self.build_log.exists())
        self.assertFalse(self.sim_log.exists())

    def test_invalid_flags_and_missing_python_do_not_build_or_clean_simulators(self):
        entry = self.entry()
        for flags in (["--force"], ["--delete", "--dry-run"], ["--delete", "test"]):
            result = self.run_wrapper("cleanup-derived-data", *flags)
            self.assertEqual(result.returncode, 2, result.stderr)
        (self.bin / "python3").unlink()
        result = self.run_wrapper("cleanup-derived-data", "--delete", env={
            **self.env, "PATH": str(self.bin),
        })
        self.assertEqual(result.returncode, 1)
        self.assertIn("requires Python 3.11+", result.stderr)
        self.assertTrue(entry.exists())
        self.assertFalse(self.build_log.exists())
        self.assertFalse(self.sim_log.exists())

    def test_build_forwarding_defaults_exit_status_and_no_automatic_cleanup(self):
        entry = self.entry()
        arguments = ["test", "-workspace", "App with spaces.xcworkspace", "-scheme", "App"]
        result = self.run_wrapper(*arguments, env={**self.env, "BUILD_EXIT": "37"})
        self.assertEqual(result.returncode, 37, result.stderr)
        key = self.base.name + "-" + hashlib.sha1(str(self.base).encode()).hexdigest()[:8]
        self.assertEqual(json.loads(self.build_log.read_text()), arguments + [
            "-derivedDataPath", str(self.root / key), "-parallel-testing-worker-count", "2",
        ])
        self.assertEqual(json.loads(self.sim_log.read_text()), ["simctl", "shutdown", "all"])
        self.assertTrue(entry.exists())

    def test_explicit_build_overrides_worker_environment_and_keep_simulators(self):
        arguments = [
            "test-without-building", "-derivedDataPath", str(self.base / "explicit data"),
            "-parallel-testing-worker-count", "5",
        ]
        env = {**self.env, "XBUILD_TEST_WORKERS": "7", "XBUILD_KEEP_SIMS": "1"}
        self.assertEqual(self.run_wrapper(*arguments, env=env).returncode, 0)
        self.assertEqual(json.loads(self.build_log.read_text()), arguments)
        self.assertFalse(self.sim_log.exists())
        env.pop("XBUILD_DERIVED_DATA_ROOT")
        self.assertEqual(self.run_wrapper("test-without-building", env=env).returncode, 0)
        self.assertEqual(json.loads(self.build_log.read_text()), [
            "test-without-building", "-parallel-testing-worker-count", "7",
        ])
        # Ordinary builds still have no Python prerequisite.
        (self.bin / "python3").unlink()
        env["PATH"] = str(self.bin)
        self.assertEqual(self.run_wrapper("build", env=env).returncode, 0)
        self.assertEqual(json.loads(self.build_log.read_text()), ["build"])
        self.assertFalse(self.sim_log.exists())

    def test_native_build_lock_delays_cleanup_selection(self):
        entry = self.entry()
        ready = self.base / "ready"
        release = self.base / "release"
        builder = self.start_wrapper(["build"], env={
            **self.env, "BUILD_READY": str(ready), "BUILD_RELEASE": str(release),
        })
        self.wait_for(ready, builder)
        cleaner = self.start_wrapper(["cleanup-derived-data", "--delete"])
        self.assert_waiting(cleaner)
        self.assertTrue(entry.exists())
        # A workspace restored while cleanup waits must be seen by selection.
        (self.workspaces / "Gone.xcworkspace").mkdir()
        release.touch()
        self.assertEqual(builder.communicate(timeout=10)[1], "")
        self.assertEqual(builder.returncode, 0)
        output, error = cleaner.communicate(timeout=10)
        self.assertEqual(cleaner.returncode, 0, error)
        self.assertIn("workspace or project still exists", output)
        self.assertTrue(entry.exists())
        self.assertFalse(self.sim_log.exists())

    def test_native_cleanup_lock_blocks_build_through_deletion(self):
        entry = self.entry()
        ready = self.base / "ready"
        release = self.base / "release"
        # Gate the real helper immediately before its real fd-safe removal.
        # Only the helper is instrumented; both processes use /usr/bin/lockf.
        tracked = self.base / "tracked"
        tracked.mkdir()
        shutil.copy2(BIN / "xbuild", tracked / "xbuild")
        (tracked / HELPER.name).write_text(f"""
import functools, importlib.util, pathlib, sys, time
spec = importlib.util.spec_from_file_location("cleanup", {str(HELPER)!r})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
remove = module.shutil.rmtree
@functools.wraps(remove)
def gated_remove(*args, **kwargs):
    pathlib.Path({str(ready)!r}).touch()
    deadline = time.monotonic() + 10
    while not pathlib.Path({str(release)!r}).exists():
        if time.monotonic() > deadline:
            raise RuntimeError("fixture release timed out")
        time.sleep(0.01)
    return remove(*args, **kwargs)
module.shutil.rmtree = gated_remove
sys.exit(module.main(sys.argv[1:]))
""")
        self.wrapper.unlink()
        self.wrapper.symlink_to(tracked / "xbuild")
        cleaner = self.start_wrapper(["cleanup-derived-data", "--delete"])
        self.wait_for(ready, cleaner)
        builder = self.start_wrapper(["build"], env={
            **self.env, "EXPECT_DELETED": str(entry),
        })
        self.assert_waiting(builder)
        self.assertFalse(self.build_log.exists())
        self.assertTrue(entry.exists())
        release.touch()
        output, error = cleaner.communicate(timeout=10)
        self.assertEqual(cleaner.returncode, 0, error)
        self.assertIn("DELETED", output)
        _, error = builder.communicate(timeout=10)
        self.assertEqual(builder.returncode, 0, error)
        self.assertFalse(entry.exists())
        self.assertFalse(self.sim_log.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
