#!/usr/bin/env python3
"""
onedrive_sync.py — Deletion-aware multi-destination sync.

Each sync *pair* has one source folder and one or more destinations. A pair can be:

* two-way merge (default): newer copy wins; new files on either side are copied
  across; deletions are propagated after interactive confirmation; if the surviving
  copy changed since the last snapshot, the deletion is skipped and the modified file
  is re-copied back ("modify wins").
* one-way (source is authoritative): source -> destination only. Updated files
  overwrite the destination; files deleted from the source are removed from the
  destination (after confirmation). The destination is never pulled back into the
  source, and destination-only files that never came from the source are left alone.

Deletion detection relies on a per-(pair, destination) *state manifest* — a snapshot of
what existed after the previous sync — stored in:
    ~/Documents/Scripts/.onedrive-sync-state/
Logs are written to:
    ~/Documents/Scripts/logs/

Usage:
    ./onedrive_sync.py              # sync (prompts before any delete)
    ./onedrive_sync.py --dry-run    # show planned actions only; no changes, no prompts
    ./onedrive_sync.py --only NAME  # sync just the pair(s) whose name contains NAME
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from collections import defaultdict, deque
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
HOME = Path.home()
DOCUMENTS = HOME / "Documents"
ONEDRIVE = HOME / "Library" / "CloudStorage" / "OneDrive-DFJStudio"

STATE_DIR = DOCUMENTS / "Scripts" / ".onedrive-sync-state"
LOG_DIR = DOCUMENTS / "Scripts" / "logs"

# Timestamp tolerance (seconds). OneDrive / FAT-derived stores round mtimes, so treat
# files whose mtimes are within this window as "the same time".
MTIME_TOL = 2.0

# rclone exits 3 for "directory not found", which is a legitimately empty
# destination rather than a failure to list it.
RCLONE_DIR_NOT_FOUND = 3

# Paths that failed to copy/delete this run (reported at the end).
FAILURES: list[str] = []
PLACEHOLDERS_SKIPPED: list[str] = []


# ---------------------------------------------------------------------------
# Config model
# ---------------------------------------------------------------------------
class Dest:
    """A sync destination.

    kind == "local"  -> a filesystem path (target is a Path).
    kind == "rclone" -> an rclone remote (remote name + base folder), e.g. gdrive + Books.
    """

    def __init__(self, target, label: str, kind: str = "local", base: str | None = None):
        self.kind = kind
        self.label = label
        if kind == "local":
            self.path = Path(target)
        else:
            self.remote = str(target)          # e.g. "gdrive"
            self.base = (base or "").strip("/")  # e.g. "Books"


class Pair:
    """One source folder synced to one or more destinations."""

    def __init__(self, name: str, source: Path, dests: list[Dest],
                 mode: str = "twoway", include: list[str] | None = None,
                 exclude: list[str] | None = None):
        assert mode in ("twoway", "oneway")
        self.name = name
        self.source = Path(source)
        self.dests = dests
        self.mode = mode
        self.include = include  # e.g. ["*.md"]; None means "all files"
        self.exclude = exclude  # e.g. ["Older music libraries"]; path-prefix/glob excludes


def _onedrive_doc(name: str, dst_rel: str | None = None,
                  exclude: list[str] | None = None) -> Pair:
    """A two-way pair: ~/Documents/<name>  <->  OneDrive/<dst_rel or Documents/name>.

    OneDrive is reached via the rclone `onedrive` remote (not the local CloudStorage
    folder), so the sync is portable to any machine with rclone configured and avoids
    Files-On-Demand hydration timeouts.
    """
    rel = dst_rel if dst_rel is not None else f"Documents/{name}"
    return Pair(name, DOCUMENTS / name,
                [Dest("onedrive", "OneDrive", kind="rclone", base=rel)],
                mode="twoway", exclude=exclude)


# --- The sync pairs --------------------------------------------------------
# NOTE: Google Drive / Dropbox destinations for Books are added once rclone remotes
# are configured (see config-rclone / wire-rclone steps).
PAIRS: list[Pair] = [
    _onedrive_doc("3D Printer"),
    _onedrive_doc("Archive", exclude=["Older music libraries"]),
    _onedrive_doc("Art", exclude=["2021 ML"]),
    _onedrive_doc("Backgrounds"),
    # Books syncs two-way to OneDrive AND Google Drive (Dropbox can be added later).
    Pair("Books", DOCUMENTS / "Books",
         [Dest("onedrive", "OneDrive", kind="rclone", base="Books"),
          Dest("gdrive", "GoogleDrive", kind="rclone", base="Books")],
         mode="twoway"),
    _onedrive_doc("Comics"),
    # Conferences intentionally skipped: its files are cloud (OneDrive) placeholders
    # that stall on read/hydration. Re-enable by uncommenting if they're materialized.
    # _onedrive_doc("Conferences"),
    _onedrive_doc("Health"),
    _onedrive_doc("Images"),
    _onedrive_doc("Libro"),
    _onedrive_doc("Music"),
    _onedrive_doc("NUMUS"),
    _onedrive_doc("obsidian"),
    _onedrive_doc("Push Notification Certs"),
    _onedrive_doc("Rhizome"),
    _onedrive_doc("Synth Stuff"),
    _onedrive_doc("Taxes"),
    _onedrive_doc("Therapy"),
    _onedrive_doc("Travel"),
    _onedrive_doc("Web Receipts"),
]

# File/dir names to ignore entirely (macOS / cloud / Office cruft).
EXCLUDE_NAMES = {
    ".DS_Store",
    ".localized",
    ".Spotlight-V100",
    ".Trashes",
    ".fseventsd",
    ".TemporaryItems",
    ".DocumentRevisions-V100",
}


def is_excluded(rel: str) -> bool:
    """True if any path component (or the file name) should be ignored."""
    for part in Path(rel).parts:
        if part in EXCLUDE_NAMES:
            return True
        if part.startswith("~$"):        # Office lock files
            return True
        if part.startswith("Icon\r"):    # macOS custom-icon resource file
            return True
        if part.endswith(".tmp"):
            return True
    return False


def matches_include(rel: str, include: list[str] | None) -> bool:
    """True if the file should be synced given the pair's include filters."""
    if not include:
        return True
    name = Path(rel).name
    return any(fnmatch.fnmatch(name, pat) for pat in include)


def matches_exclude(rel: str, exclude: list[str] | None) -> bool:
    """True if the relative path should be skipped given the pair's exclude patterns.

    A pattern matches when the path equals it, sits underneath it (directory prefix),
    or matches it as an fnmatch glob (globs are matched against the whole rel path).
    """
    if not exclude:
        return False
    for pat in exclude:
        p = pat.rstrip("/")
        if rel == p or rel.startswith(p + "/") or fnmatch.fnmatch(rel, pat):
            return True
    return False


# ---------------------------------------------------------------------------
# File metadata
# ---------------------------------------------------------------------------
# macOS flag marking a "dataless" cloud placeholder (OneDrive Files-On-Demand,
# iCloud, etc.): the file's content is NOT on local disk. Reading such a file's
# CONTENT triggers hydration (download); on a full disk that read hangs forever.
# Reading st_flags/st_size/st_mtime is pure metadata and never hydrates.
SF_DATALESS = 0x40000000


class Meta:
    __slots__ = ("size", "mtime", "birthtime", "dataless")

    def __init__(self, size: int, mtime: float, birthtime: float,
                 dataless: bool = False):
        self.size = size
        self.mtime = mtime
        self.birthtime = birthtime
        self.dataless = dataless

    @classmethod
    def from_path(cls, p: Path) -> "Meta":
        st = p.stat()
        birth = getattr(st, "st_birthtime", st.st_mtime)
        dataless = bool(getattr(st, "st_flags", 0) & SF_DATALESS)
        return cls(st.st_size, st.st_mtime, birth, dataless)

    def to_dict(self) -> dict:
        return {"size": self.size, "mtime": self.mtime, "birthtime": self.birthtime}

    @classmethod
    def from_dict(cls, d: dict) -> "Meta":
        return cls(d["size"], d["mtime"], d.get("birthtime", d["mtime"]))

    def same_as(self, other: "Meta") -> bool:
        return self.size == other.size and abs(self.mtime - other.mtime) <= MTIME_TOL


def fmt_ts(ts: float) -> str:
    return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")


def fmt_size(n: int) -> str:
    f = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if f < 1024 or unit == "TB":
            return f"{int(f)}B" if unit == "B" else f"{f:.1f}{unit}"
        f /= 1024
    return f"{n}B"


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
class Logger:
    """Echoes to stdout, and to a file when one is given.

    `path` is None for dry runs, which must not create or truncate anything.
    """

    def __init__(self, path: Path | None):
        self.fh = path.open("w", encoding="utf-8") if path is not None else None

    def __call__(self, msg: str = "") -> None:
        print(msg)
        if self.fh is not None:
            self.fh.write(msg + "\n")
            self.fh.flush()

    def close(self):
        if self.fh is not None:
            self.fh.close()
            self.fh = None


# ---------------------------------------------------------------------------
# Scanning
# ---------------------------------------------------------------------------
class ScanIncomplete(RuntimeError):
    """A side could not be fully inventoried.

    A partial listing is indistinguishable from a deletion: any file that is in
    the manifest but missing from the scan looks deleted, so propagating it
    would remove the intact copy on the other side. Callers must abort the pair
    and preserve its manifest instead.
    """


def scan(root: Path, include: list[str] | None = None,
         exclude: list[str] | None = None) -> dict[str, Meta]:
    """{relative_path: Meta} for every non-excluded regular file under root.

    Raises ScanIncomplete if any directory or file could not be read.
    """
    out: dict[str, Meta] = {}
    if not root.exists():
        return out

    def _walk_error(err: OSError) -> None:
        raise ScanIncomplete(f"cannot read {getattr(err, 'filename', root)}: {err}")

    for dirpath, dirnames, filenames in os.walk(root, onerror=_walk_error):
        rel_dir = "" if Path(dirpath) == root else str(Path(dirpath).relative_to(root))
        # Prune ignored/excluded directories so we don't descend into them at all.
        dirnames[:] = [
            d for d in dirnames
            if d not in EXCLUDE_NAMES and not d.startswith("~$")
            and not matches_exclude((f"{rel_dir}/{d}" if rel_dir else d), exclude)
        ]
        for name in filenames:
            full = Path(dirpath) / name
            rel = str(full.relative_to(root))
            if (is_excluded(rel) or matches_exclude(rel, exclude)
                    or not matches_include(rel, include)):
                continue
            try:
                if full.is_symlink() or not full.is_file():
                    continue
                out[rel] = Meta.from_path(full)
            except OSError as e:
                raise ScanIncomplete(f"cannot read {full}: {e}") from e
    return out


# ---------------------------------------------------------------------------
# Manifest persistence (keyed per pair+destination)
# ---------------------------------------------------------------------------
def manifest_path(key: str) -> Path:
    safe = key.replace(os.sep, "__").replace(" ", "_").replace(":", "-")
    return STATE_DIR / f"{safe}.json"


def load_manifest(key: str) -> dict[str, Meta]:
    p = manifest_path(key)
    if not p.exists():
        return {}
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
        return {k: Meta.from_dict(v) for k, v in data.items()}
    except (json.JSONDecodeError, KeyError, OSError):
        return {}


def save_manifest(key: str, files: dict[str, Meta]) -> None:
    p = manifest_path(key)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({k: v.to_dict() for k, v in files.items()}, indent=0),
                 encoding="utf-8")


# ---------------------------------------------------------------------------
# Deletion confirmation
# ---------------------------------------------------------------------------
class Confirmer:
    def __init__(self, log: Logger):
        self.log = log
        self.yes_all = False
        self.quit = False

    def confirm_delete(self, path: Path, meta: Meta) -> bool:
        if self.quit:
            return False
        if self.yes_all:
            return True
        self.log("")
        self.log(f"  DELETE candidate: {path}")
        self.log(f"      size     : {fmt_size(meta.size)} ({meta.size} bytes)")
        self.log(f"      modified : {fmt_ts(meta.mtime)}")
        self.log(f"      created  : {fmt_ts(meta.birthtime)}")
        while True:
            try:
                ans = input("      Delete this file? [y]es / [n]o / [a]ll / [q]uit: ").strip().lower()
            except EOFError:
                return False
            if ans in ("y", "yes"):
                return True
            if ans in ("n", "no", ""):
                return False
            if ans in ("a", "all"):
                self.yes_all = True
                return True
            if ans in ("q", "quit"):
                self.quit = True
                return False


# ---------------------------------------------------------------------------
# File operations
# ---------------------------------------------------------------------------
def copy_file(src: Path, dst: Path, log: Logger, dry: bool) -> bool:
    """Local-to-local copy (used by github_md_collect and the local fast path)."""
    log(f"  COPY  {src}  ->  {dst}")
    if dry:
        return True
    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copy2(src, dst)
        return True
    except OSError as e:
        log(f"    !! copy failed: {e}")
        return False


def delete_file(path: Path, log: Logger, dry: bool) -> None:
    """Local delete (used by github_md_collect)."""
    log(f"  REMOVE {path}")
    if dry:
        return
    try:
        path.unlink()
    except OSError as e:
        log(f"    !! failed to remove: {e}")


# ---------------------------------------------------------------------------
# Endpoints: a uniform interface over local filesystem and rclone remotes
# ---------------------------------------------------------------------------
def _parse_modtime(s: str) -> float:
    """Parse an rclone RFC3339 ModTime into an epoch float."""
    s = s.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    if "." in s:  # trim fractional seconds to microseconds for fromisoformat
        head, frac = s.split(".", 1)
        m = re.match(r"(\d+)(.*)", frac)
        s = f"{head}.{m.group(1)[:6]}{m.group(2)}"
    try:
        return datetime.fromisoformat(s).timestamp()
    except ValueError:
        return 0.0


class LocalEndpoint:
    kind = "local"

    def __init__(self, root: Path):
        self.root = Path(root)

    def scan(self, include, exclude=None):
        return scan(self.root, include, exclude)

    def exists(self) -> bool:
        return self.root.exists()

    def display(self) -> str:
        return str(self.root)

    def local_path(self, rel: str) -> Path:
        return self.root / rel

    def arg(self, rel: str) -> str:
        return str(self.root / rel)

    def root_arg(self) -> str:
        return str(self.root)


class RcloneEndpoint:
    kind = "rclone"

    def __init__(self, remote: str, base: str):
        self.remote = remote
        self.base = base.strip("/")

    def target(self) -> str:
        return f"{self.remote}:{self.base}"

    def scan(self, include, exclude=None):
        out: dict[str, Meta] = {}
        p = subprocess.run(["rclone", "lsjson", "-R", self.target()],
                           capture_output=True, text=True, check=False)
        if p.returncode == RCLONE_DIR_NOT_FOUND:
            return out  # base folder does not exist yet -> genuinely empty
        if p.returncode != 0:
            # A transient failure (network, auth, rate limit) must never be read
            # as "the remote is empty" — that would propose deleting every file.
            raise ScanIncomplete(
                f"rclone lsjson {self.target()} failed (exit {p.returncode}): "
                f"{p.stderr.strip()}")
        try:
            data = json.loads(p.stdout or "[]")
        except json.JSONDecodeError as e:
            raise ScanIncomplete(
                f"rclone lsjson {self.target()} returned invalid JSON: {e}") from e
        for e in data:
            if e.get("IsDir"):
                continue
            rel = e["Path"]
            if (is_excluded(rel) or matches_exclude(rel, exclude)
                    or not matches_include(rel, include)):
                continue
            mt = _parse_modtime(e.get("ModTime", ""))
            out[rel] = Meta(int(e.get("Size", 0)), mt, mt)
        return out

    def exists(self) -> bool:
        return True

    def display(self) -> str:
        return self.target()

    def arg(self, rel: str) -> str:
        return f"{self.target()}/{rel}"

    def root_arg(self) -> str:
        return self.target()


def make_endpoint(dest: Dest):
    if dest.kind == "local":
        return LocalEndpoint(dest.path)
    return RcloneEndpoint(dest.remote, dest.base)


COPY_RETRIES = 3
COPY_RETRY_WAIT = 5.0  # seconds; OneDrive on-demand files may need time to hydrate


def copy(src_ep, dst_ep, rel: str, log: Logger, dry: bool) -> bool:
    """Copy rel from src_ep to dst_ep. Resilient: retries, never raises.

    Returns True on success. On persistent failure it logs, records the failure, and
    returns False so the caller can continue; the file will simply be retried on a
    later run (it won't be recorded in the manifest, so it is never mistaken for a
    deletion).
    """
    log(f"  COPY  {src_ep.display()}/{rel}  ->  {dst_ep.display()}/{rel}")
    if dry:
        return True

    last_err = ""
    for attempt in range(1, COPY_RETRIES + 1):
        try:
            if src_ep.kind == "local" and dst_ep.kind == "local":
                d = dst_ep.local_path(rel)
                d.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_ep.local_path(rel), d)
                return True
            r = subprocess.run(["rclone", "copyto", src_ep.arg(rel), dst_ep.arg(rel)],
                               capture_output=True, text=True)
            if r.returncode == 0:
                return True
            last_err = r.stderr.strip()
        except OSError as e:
            last_err = str(e)
        if attempt < COPY_RETRIES:
            log(f"    .. attempt {attempt} failed ({last_err}); retrying in {COPY_RETRY_WAIT:.0f}s")
            time.sleep(COPY_RETRY_WAIT)

    log(f"    !! FAILED after {COPY_RETRIES} attempts: {last_err}")
    FAILURES.append(f"{src_ep.display()}/{rel}")
    return False


def delete_ep(ep, rel: str, log: Logger, dry: bool) -> None:
    log(f"  REMOVE {ep.display()}/{rel}")
    if dry:
        return
    if ep.kind == "local":
        try:
            ep.local_path(rel).unlink()
        except OSError as e:
            log(f"    !! failed to remove: {e}")
            FAILURES.append(f"{ep.display()}/{rel} (delete failed)")
        return
    r = subprocess.run(["rclone", "deletefile", ep.arg(rel)],
                       capture_output=True, text=True, check=False)
    if r.returncode != 0:
        log(f"    !! rclone delete failed: {r.stderr.strip()}")
        FAILURES.append(f"{ep.display()}/{rel} (delete failed)")


# ---------------------------------------------------------------------------
# Batched rclone copy: transfer many files in ONE rclone invocation (parallel),
# far faster than one `rclone copyto` per file (which re-auths every time).
# ---------------------------------------------------------------------------
def rclone_copy_batch(src_ep, dst_ep, rels, log: Logger, dry: bool) -> None:
    log(f"  COPY (batch x{len(rels)})  {src_ep.display()}  ->  {dst_ep.display()}")
    for rel in rels:
        log(f"      + {rel}")
    if dry:
        return
    tf = tempfile.NamedTemporaryFile("w", delete=False, suffix=".lst", encoding="utf-8")
    try:
        tf.write("\n".join(rels))
        tf.close()
        cmd = ["rclone", "copy", src_ep.root_arg(), dst_ep.root_arg(),
               "--files-from-raw", tf.name,
               "--transfers", "8", "--checkers", "8", "--retries", "3",
               "--stats", "5s", "--stats-one-line", "--stats-log-level", "NOTICE"]
        # Stream rclone's periodic one-line stats (transferred, %, speed, ETA) to the
        # log/terminal live instead of capturing them silently.
        proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL,
                                stderr=subprocess.PIPE, text=True, bufsize=1)
        tail = deque(maxlen=20)
        for line in proc.stderr:
            line = line.rstrip("\n")
            if not line:
                continue
            tail.append(line)
            log(f"      · {line}")
        proc.wait()
        if proc.returncode != 0:
            log(f"    !! rclone batch had errors: {' | '.join(tail)[:500]}")
            FAILURES.append(f"{dst_ep.display()} (batch of {len(rels)} files)")
    finally:
        try:
            os.unlink(tf.name)
        except OSError:
            pass


# ---------------------------------------------------------------------------
# A Plan collects sync decisions so copies can be batched and deletions confirmed.
# ---------------------------------------------------------------------------
class Plan:
    def __init__(self):
        self.copies: list[tuple] = []   # (src_ep, dst_ep, rel)
        self.deletes: list[tuple] = []  # (ep, rel, meta, reason)

    def add_copy(self, src_ep, dst_ep, rel):
        self.copies.append((src_ep, dst_ep, rel))

    def add_delete(self, ep, rel, meta, reason):
        self.deletes.append((ep, rel, meta, reason))


def execute_plan(plan: Plan, log: Logger, confirmer: Confirmer, dry: bool) -> None:
    # Copies: local<->local done inline (resilient); anything touching rclone is batched
    # per (source, destination) endpoint pair.
    batches: dict = defaultdict(list)
    for src_ep, dst_ep, rel in plan.copies:
        if src_ep.kind == "local" and dst_ep.kind == "local":
            copy(src_ep, dst_ep, rel, log, dry)
        else:
            batches[(id(src_ep), id(dst_ep))].append((src_ep, dst_ep, rel))
    for group in batches.values():
        src_ep, dst_ep = group[0][0], group[0][1]
        rclone_copy_batch(src_ep, dst_ep, [g[2] for g in group], log, dry)

    # Deletions: per file, with interactive confirmation.
    for ep, rel, meta, reason in plan.deletes:
        if confirmer.quit:
            break
        _maybe_delete(ep, rel, meta, log, confirmer, dry, reason)


# ---------------------------------------------------------------------------
# Sync one (pair, destination) — works for local or rclone destinations
# ---------------------------------------------------------------------------
def sync_dest(pair: Pair, dest: Dest, log: Logger, confirmer: Confirmer, dry: bool) -> None:
    a_ep = LocalEndpoint(pair.source)     # source (always local)
    b_ep = make_endpoint(dest)            # destination (local or rclone)
    key = f"{pair.name}::{dest.label}"

    log("")
    log(f"[{pair.mode}] {pair.name}  ->  {dest.label} ({b_ep.display()})")
    if pair.include:
        log(f"    include filter: {', '.join(pair.include)}")
    if pair.exclude:
        log(f"    exclude filter: {', '.join(pair.exclude)}")

    if not a_ep.exists() and not b_ep.exists():
        log("  (neither side exists — skipping)")
        return

    try:
        a = a_ep.scan(pair.include, pair.exclude)
        b = b_ep.scan(pair.include, pair.exclude)
    except ScanIncomplete as e:
        log(f"  !! incomplete inventory: {e}")
        log("  (skipping this pair; manifest preserved so nothing is "
            "mistaken for a deletion)")
        FAILURES.append(f"{pair.name} -> {dest.label} (incomplete inventory)")
        return
    m = load_manifest(key)

    plan = Plan()
    for rel in sorted(set(a) | set(b) | set(m)):
        a_meta, b_meta, m_meta = a.get(rel), b.get(rel), m.get(rel)
        if pair.mode == "oneway":
            _sync_rel_oneway(rel, a_meta, b_meta, m_meta, a_ep, b_ep, plan, log)
        else:
            _sync_rel_twoway(rel, a_meta, b_meta, m_meta, a_ep, b_ep, plan, log)

    execute_plan(plan, log, confirmer, dry)

    if not dry:
        try:
            _rebuild_manifest(key, pair, a_ep, b_ep)
        except ScanIncomplete as e:
            # Keeping the previous manifest is the safe choice: a manifest built
            # from a partial scan would make the missing files look deleted on
            # the next run.
            log(f"  !! manifest not updated: {e}")
            FAILURES.append(f"{pair.name} -> {dest.label} (manifest not updated)")


def _sync_rel_twoway(rel, a_meta, b_meta, m_meta, a_ep, b_ep, plan, log):
    # Local side is a dataless cloud placeholder: its content lives in the cloud,
    # not on disk. Never read it (that would hydrate/hang, esp. on a full disk).
    # It is already "present", so it is neither uploaded nor treated as a deletion.
    if a_meta and a_meta.dataless:
        PLACEHOLDERS_SKIPPED.append(rel)
        return

    # present on both sides -> newer wins
    if a_meta and b_meta:
        if a_meta.same_as(b_meta):
            return
        if a_meta.mtime > b_meta.mtime + MTIME_TOL:
            plan.add_copy(a_ep, b_ep, rel)
        elif b_meta.mtime > a_meta.mtime + MTIME_TOL:
            plan.add_copy(b_ep, a_ep, rel)
        else:
            log(f"  CONFLICT (same time, differing content): {rel} — leaving both untouched")
        return

    # present only on source side
    if a_meta and not b_meta:
        if m_meta is None:
            plan.add_copy(a_ep, b_ep, rel)
        elif a_meta.same_as(m_meta):
            plan.add_delete(a_ep, rel, a_meta, "deleted on destination")
        else:
            log(f"  MODIFIED since last sync; re-copying to destination: {rel}")
            plan.add_copy(a_ep, b_ep, rel)
        return

    # present only on destination side
    if b_meta and not a_meta:
        if m_meta is None:
            plan.add_copy(b_ep, a_ep, rel)
        elif b_meta.same_as(m_meta):
            plan.add_delete(b_ep, rel, b_meta, "deleted on source")
        else:
            log(f"  MODIFIED since last sync; re-copying to source: {rel}")
            plan.add_copy(b_ep, a_ep, rel)
        return
    # else: only in manifest -> gone from both; manifest rebuild handles it.


def _sync_rel_oneway(rel, a_meta, b_meta, m_meta, a_ep, b_ep, plan, log):
    """Source (a) is authoritative; destination (b) is never pulled back."""
    # Dataless local placeholder: content is in the cloud, never read it.
    if a_meta and a_meta.dataless:
        PLACEHOLDERS_SKIPPED.append(rel)
        return
    if a_meta and b_meta:
        if not a_meta.same_as(b_meta):
            plan.add_copy(a_ep, b_ep, rel)  # source overwrites destination
        return
    if a_meta and not b_meta:
        plan.add_copy(a_ep, b_ep, rel)      # new / restored on source
        return
    if b_meta and not a_meta:
        if m_meta is None:
            log(f"  DEST-ONLY (never came from source; leaving alone): {rel}")
        elif b_meta.same_as(m_meta):
            plan.add_delete(b_ep, rel, b_meta, "deleted from source")
        else:
            log(f"  DEST changed but source deleted it; not removing: {rel}")
        return


def _maybe_delete(ep, rel, meta, log, confirmer, dry, reason):
    disp = f"{ep.display()}/{rel}"
    if dry:
        log(f"  WOULD PROMPT to delete ({reason}): {disp}")
    elif confirmer.confirm_delete(disp, meta):
        delete_ep(ep, rel, log, dry)


def _rebuild_manifest(key, pair, a_ep, b_ep):
    a2 = a_ep.scan(pair.include, pair.exclude)
    if pair.mode == "oneway":
        merged = dict(a2)  # source is the source of truth
    else:
        # Two-way: record only files that are actually present on BOTH sides now.
        # A failed copy leaves a file on one side only -> excluded here -> it is
        # retried next run rather than being mistaken for a deletion.
        b2 = b_ep.scan(pair.include, pair.exclude)
        merged = {rel: a2[rel] for rel in set(a2) & set(b2)}
    save_manifest(key, merged)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(description="Deletion-aware multi-destination sync.")
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="Show planned actions; change nothing and do not prompt.")
    parser.add_argument("--only", metavar="NAME", default=None,
                        help="Only sync pairs whose name contains NAME (case-insensitive).")
    args = parser.parse_args()

    # A dry run must be side-effect free, so it neither creates the state/log
    # directories nor opens a log file.
    log_file = None
    if not args.dry_run:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        log_file = LOG_DIR / f"onedrive-sync-{datetime.now():%Y%m%d-%H%M%S}.log"
    log = Logger(log_file)

    log("=" * 62)
    log(f"Multi-destination sync  {datetime.now():%Y-%m-%d %H:%M:%S}")
    if args.dry_run:
        log("*** DRY RUN — no changes, no prompts ***")
    log(f"State dir : {STATE_DIR}")
    if log_file is not None:
        log(f"Log file  : {log_file}")
    log("=" * 62)

    pairs = PAIRS
    if args.only:
        needle = args.only.lower()
        pairs = [p for p in PAIRS if needle in p.name.lower()]
        log(f"Filtered to {len(pairs)} pair(s) matching '{args.only}'.")

    confirmer = Confirmer(log)
    for pair in pairs:
        if confirmer.quit:
            log("\nAborted by user.")
            break
        for dest in pair.dests:
            if confirmer.quit:
                break
            sync_dest(pair, dest, log, confirmer, args.dry_run)

    log("")
    log("=" * 62)
    if PLACEHOLDERS_SKIPPED:
        log(f"{len(PLACEHOLDERS_SKIPPED)} cloud-placeholder file(s) skipped "
            f"(content only in the cloud; already backed up, nothing to read/upload).")
    if FAILURES:
        log(f"{len(FAILURES)} operation(s) FAILED (will retry next run):")
        for p in FAILURES[:20]:
            log(f"  - {p}")
        if len(FAILURES) > 20:
            log(f"  ... and {len(FAILURES) - 20} more (see log).")
    log(f"Sync complete  {datetime.now():%Y-%m-%d %H:%M:%S}")
    log("=" * 62)
    log.close()
    # Non-zero on any failure so schedulers can detect an incomplete sync.
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
