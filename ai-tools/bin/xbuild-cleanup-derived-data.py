"""Private helper for xbuild; its caller holds the build lock for this process."""

import os
import plistlib
import shutil
import stat
import sys
import time
from contextlib import contextmanager
from xml.parsers.expat import ExpatError


MIN_AGE_NS = 7 * 24 * 60 * 60 * 1_000_000_000
SHARED_CACHES = {
    "ModuleCache", "CompilationCache", "SDKStatCaches", "SymbolCache", "Index",
}
REMOVAL_BLOCKED_FLAGS = (
    "UF_IMMUTABLE", "SF_IMMUTABLE", "UF_APPEND", "SF_APPEND",
    "UF_NOUNLINK", "SF_NOUNLINK",
)


class Preserve(Exception):
    """The available evidence is insufficient to delete this entry."""


class UniqueKeys(dict):
    def __setitem__(self, key, value):
        if key in self:
            raise Preserve("duplicate plist key")
        super().__setitem__(key, value)


def absolute_parts(path):
    if (
        not isinstance(path, str)
        or not path.startswith("/")
        or path.startswith("//")
        or os.path.normpath(path) != path
        or any(ord(char) < 32 or ord(char) == 127 for char in path)
    ):
        raise Preserve("expected a normalized absolute path without control characters")
    return path.split("/")[1:] if path != "/" else []


@contextmanager
def directory(name, parent_fd=None):
    fd = os.open(
        name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent_fd
    )
    try:
        yield fd
    finally:
        os.close(fd)


@contextmanager
def absolute_directory(path):
    # Opening each component separately rejects symlinks in ancestors too.
    parts = absolute_parts(path)
    fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
    try:
        for part in parts:
            next_fd = os.open(
                part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd
            )
            os.close(fd)
            fd = next_fd
        yield fd
    finally:
        os.close(fd)


def signature(info):
    return (
        info.st_dev, info.st_ino, info.st_mode, info.st_nlink, info.st_size,
        info.st_mtime_ns, info.st_ctime_ns,
    )


def is_same_or_ancestor(directory_fd, path):
    """Compare directory identity along a protected path, not its spelling."""
    parts = absolute_parts(path)
    fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
    try:
        if os.path.samestat(os.fstat(directory_fd), os.fstat(fd)):
            return True
        for part in parts:
            next_fd = os.open(
                part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd
            )
            os.close(fd)
            fd = next_fd
            if os.path.samestat(os.fstat(directory_fd), os.fstat(fd)):
                return True
        return False
    finally:
        os.close(fd)


def validate_root(root):
    if len(absolute_parts(root)) < 2:
        raise Preserve("refusing a filesystem root or top-level directory")
    home = os.environ.get("HOME")
    absolute_parts(home)
    with absolute_directory(root) as root_fd:
        for protected in (home, os.getcwd()):
            protected = os.path.realpath(protected, strict=True)
            if is_same_or_ancestor(root_fd, protected):
                raise Preserve("refusing home, the current directory, or their ancestors")


def directory_removal_preflight(fd, info=None):
    info = os.fstat(fd) if info is None else info
    if not stat.S_ISDIR(info.st_mode):
        raise Preserve("expected a directory during removal preflight")

    flags = getattr(info, "st_flags", 0)
    if any(flags & getattr(stat, name, 0) for name in REMOVAL_BLOCKED_FLAGS):
        raise Preserve("directory has immutable, append-only, or no-unlink flags")

    uid = os.geteuid()
    groups = set(os.getgroups()) | {os.getegid()}
    if uid == info.st_uid:
        permission_bits = stat.S_IWUSR | stat.S_IXUSR
    elif info.st_gid in groups:
        permission_bits = stat.S_IWGRP | stat.S_IXGRP
    else:
        permission_bits = stat.S_IWOTH | stat.S_IXOTH
    if info.st_mode & permission_bits != permission_bits:
        raise Preserve("directory mode does not permit removal")
    try:
        accessible = os.access(
            ".", os.W_OK | os.X_OK, dir_fd=fd, effective_ids=True
        )
    except (NotImplementedError, OSError, TypeError) as error:
        raise Preserve("directory removal permissions are uncertain") from error
    if not accessible:
        raise Preserve("directory ACL or effective permissions deny removal")


def verify_root(root, root_fd):
    with absolute_directory(root) as current_fd:
        if not os.path.samestat(os.fstat(root_fd), os.fstat(current_fd)):
            raise Preserve("DerivedData root changed")


def missing_workspace(path, root, device):
    parts = absolute_parts(path)
    # Xcode also records the implicit workspace inside an .xcodeproj. Keep the
    # entry whenever that project exists, even if its implicit workspace does not.
    if (
        len(parts) >= 2
        and parts[-1] == "project.xcworkspace"
        and parts[-2].endswith(".xcodeproj")
    ):
        parts.pop()
    if not parts or not parts[-1].endswith((".xcworkspace", ".xcodeproj")):
        raise Preserve("unrecognized WorkspacePath")
    if parts[-1] in (".xcworkspace", ".xcodeproj"):
        raise Preserve("unrecognized WorkspacePath")
    if any(part.endswith((".xcworkspace", ".xcodeproj")) for part in parts[:-1]):
        raise Preserve("unrecognized nested WorkspacePath")
    target = "/" + "/".join(parts)
    if os.path.commonpath((root, target)) in (root, target):
        raise Preserve("WorkspacePath overlaps the DerivedData root")
    if parts[0] in ("Volumes", "Network", "net"):
        raise Preserve("workspace may be on an offline or network volume")

    # Require the immediate parent to be accessible, not just some ancestor.
    # A missing checkout/mount/parent is ambiguous, not proof of an orphan.
    parent = os.path.dirname(target)
    with absolute_directory(parent) as parent_fd:
        if os.fstat(parent_fd).st_dev != device:
            raise Preserve("workspace parent is on a different filesystem")
        try:
            os.stat(parts[-1], dir_fd=parent_fd, follow_symlinks=False)
        except FileNotFoundError:
            with absolute_directory(parent) as current_fd:
                if not os.path.samestat(os.fstat(parent_fd), os.fstat(current_fd)):
                    raise Preserve("workspace parent changed")
            return
        # Includes existing files, symlinks, and dangling symlinks.
        raise Preserve("workspace or project still exists")


def read_workspace(entry_fd):
    fd = os.open(
        "info.plist", os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=entry_fd
    )
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
            raise Preserve("info.plist is not a single-link regular file")
        if info.st_size > 1024 * 1024:
            raise Preserve("unexpectedly large info.plist")
        with os.fdopen(fd, "rb", closefd=False) as stream:
            try:
                data = plistlib.loads(
                    stream.read(1024 * 1024 + 1), dict_type=UniqueKeys
                )
            except (AttributeError, IndexError) as error:
                raise Preserve("malformed info.plist") from error
        if signature(os.fstat(fd)) != signature(info):
            raise Preserve("info.plist changed while reading")
    finally:
        os.close(fd)
    if not isinstance(data, dict) or not isinstance(data.get("WorkspacePath"), str):
        raise Preserve("info.plist has no string WorkspacePath")
    return data["WorkspacePath"], signature(info)


def tree_snapshot(entry_fd, device):
    """Record every mtime, including directories/metadata, without following links."""
    snapshot = []

    def visit(fd, relative):
        before = os.fstat(fd)
        if before.st_dev != device:
            raise Preserve("entry crosses a filesystem boundary")
        directory_removal_preflight(fd, before)
        snapshot.append((relative, signature(before)))
        for name in sorted(os.listdir(fd)):
            info = os.stat(name, dir_fd=fd, follow_symlinks=False)
            if info.st_dev != device:
                raise Preserve("entry crosses a filesystem boundary")
            flags = getattr(info, "st_flags", 0)
            if any(flags & getattr(stat, flag, 0) for flag in REMOVAL_BLOCKED_FLAGS):
                raise Preserve("entry contains immutable, append-only, or no-unlink flags")
            child = relative + "/" + name
            if stat.S_ISDIR(info.st_mode):
                with directory(name, fd) as child_fd:
                    if not os.path.samestat(info, os.fstat(child_fd)):
                        raise Preserve("directory changed while scanning")
                    visit(child_fd, child)
            elif stat.S_ISREG(info.st_mode) and info.st_nlink == 1:
                snapshot.append((child, signature(info)))
            else:
                raise Preserve("entry contains a symlink, hard link, or special file")
        if signature(os.fstat(fd)) != signature(before):
            raise Preserve("directory changed while scanning")

    visit(entry_fd, ".")
    return tuple(snapshot)


def inspect_entry(root_fd, name, root, cutoff):
    if (
        name.startswith(".")
        or name in SHARED_CACHES
        or name.endswith((".noindex", ".nosync"))
    ):
        raise Preserve("shared cache or unrecognized entry")
    directory_removal_preflight(root_fd)
    with directory(name, root_fd) as entry_fd:
        workspace, metadata = read_workspace(entry_fd)
        device = os.fstat(root_fd).st_dev
        missing_workspace(workspace, root, device)
        tree = tree_snapshot(entry_fd, device)
        if signature(os.stat("info.plist", dir_fd=entry_fd, follow_symlinks=False)) != metadata:
            raise Preserve("info.plist changed while scanning")
        newest = max(item[1][5] for item in tree)
        if newest > cutoff:
            raise Preserve("modified within seven days (or has a future mtime)")
        if signature(os.stat(name, dir_fd=root_fd, follow_symlinks=False)) != tree[0][1]:
            raise Preserve("entry changed while scanning")
        # A large tree scan can take time; recheck the workspace afterwards too.
        missing_workspace(workspace, root, device)
        return workspace, tree


ENTRY_ERRORS = (Preserve, OSError, ValueError, TypeError, ExpatError, RecursionError)


def cleanup(root, delete=False, now_ns=None):
    validate_root(root)
    cutoff = (time.time_ns() if now_ns is None else now_ns) - MIN_AGE_NS
    failures = 0
    with absolute_directory(root) as root_fd:
        for name in sorted(os.listdir(root_fd)):
            path = os.path.join(root, name)
            try:
                selected = inspect_entry(root_fd, name, root, cutoff)
            except ENTRY_ERRORS as error:
                print(f"KEEP {path!r}: {error}")
                continue
            if not delete:
                print(f"WOULD DELETE {path!r}: missing {selected[0]!r}, unchanged for >=7 days")
                continue

            verify_root(root, root_fd)
            try:
                # Re-read identity, metadata, workspace state and the entire
                # tree immediately before removal, not merely the parent mtime.
                if inspect_entry(root_fd, name, root, cutoff) != selected:
                    raise Preserve("entry changed since selection")
            except ENTRY_ERRORS as error:
                print(f"KEEP {path!r}: revalidation: {error}")
                continue
            verify_root(root, root_fd)
            try:
                # Python's fd-based rmtree checks lstat/open identities and does
                # not follow replacement symlinks, including nested ones.
                shutil.rmtree(name, dir_fd=root_fd)
                print(f"DELETED {path!r}")
            except OSError as error:
                failures += 1
                print(f"ERROR {path!r}: removal failed (may be partial): {error}", file=sys.stderr)
    return 1 if failures else 0


def main(argv):
    if argv not in ([], ["--dry-run"], ["--delete"]):
        print("usage: xbuild cleanup-derived-data [--dry-run|--delete]", file=sys.stderr)
        return 2
    if sys.version_info < (3, 11) or not getattr(shutil.rmtree, "avoids_symlink_attacks", False):
        print("xbuild: cleanup requires Python 3.11+ with symlink-safe rmtree", file=sys.stderr)
        return 1
    root = os.environ.get(
        "XBUILD_DERIVED_DATA_ROOT",
        os.path.join(os.environ.get("HOME", ""), "Library/Developer/Xcode/DerivedData"),
    )
    try:
        return cleanup(root, delete=argv == ["--delete"])
    except ENTRY_ERRORS as error:
        print(f"xbuild: cleanup refused: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
