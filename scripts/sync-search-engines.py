#!/usr/bin/env python3
"""Merge custom search engines between Firefox/Waterfox profiles and
chezmoi's tracked copy at ~/.config/search-engines/custom-engines.json.

Custom engines live in a profile's search.json.mozlz4 (mozlz4-compressed
JSON), not in places.sqlite -- that's only true pre-Firefox-51. Firefox
Sync doesn't carry this file, so Waterfox (a separate Firefox-based
install) needs it merged in by hand.

  apply [firefox|waterfox|both]   merge tracked custom-engines.json into
                                  the live profile(s). Browser must be
                                  closed first -- it rewrites this file
                                  on exit and would clobber the merge.
  dump  <firefox|waterfox>        pull this profile's custom engines out
                                  into the tracked json, for review/commit
                                  from the source repo (chezmoi apply
                                  won't do this direction automatically).

Active profile dir is auto-detected from profiles.ini -- not hardcoded
per machine, since profiles.ini already has the answer.

Requires python3 + `pip install lz4` on every machine this runs on, Windows
included -- see README "Dependencies". Never auto-run by chezmoi (see the
module docstring above) -- always a manual step, so re-run this yourself
after `chezmoi apply` on a new device.
"""
import json
import os
import struct
import subprocess
import sys
from configparser import ConfigParser
from pathlib import Path

try:
    import lz4.block
except ImportError:
    # lz4 is Arch's python-lz4, installed for the *system* python. A mise/venv
    # python3 earlier on PATH (this box has one) cannot see it, so re-exec into
    # the distribution python once before giving up.
    if sys.platform != "win32" and sys.executable != "/usr/bin/python3" and Path("/usr/bin/python3").exists():
        os.execv("/usr/bin/python3", ["/usr/bin/python3", *sys.argv])
    sys.exit("error: python3 lz4 module required -- pip install lz4")

if sys.platform == "win32":
    _APPDATA = Path(os.environ["APPDATA"])
    BROWSERS = {
        "firefox": {"dirs": [_APPDATA / "Mozilla" / "Firefox"], "proc": "firefox.exe"},
        "waterfox": {"dirs": [_APPDATA / "Waterfox"], "proc": "waterfox.exe"},
    }
else:
    # Firefox 147 moved its profile root to XDG (bug 259356): ~/.config/mozilla/firefox.
    # Older installs still use ~/.mozilla/firefox, so candidates are tried in order.
    _CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    BROWSERS = {
        "firefox": {
            "dirs": [_CONFIG_HOME / "mozilla" / "firefox", Path.home() / ".mozilla/firefox"],
            "proc": "firefox",
        },
        "waterfox": {
            "dirs": [_CONFIG_HOME / "waterfox", Path.home() / ".waterfox"],
            "proc": "waterfox-bin",
        },
    }

TRACKED_JSON = Path.home() / ".config/search-engines/custom-engines.json"

# built-in-style entries have _loadPath == None -- not portable, and not
# "custom" in any useful sense, so never touched by dump/apply.
def is_custom(engine):
    return engine.get("_loadPath") is not None


def active_profile_dir(browser):
    info = BROWSERS[browser]
    install_dir = None
    for candidate in info["dirs"]:
        if (candidate / "profiles.ini").exists():
            install_dir = candidate
            break
    if install_dir is None:
        tried = ", ".join(str(d) for d in info["dirs"])
        sys.exit(f"error: no profiles.ini for {browser} (tried {tried}) -- is it installed?")
    ini_path = install_dir / "profiles.ini"

    cfg = ConfigParser()
    cfg.read(ini_path)

    # a Locked install section's Default wins over any [ProfileN] Default=1
    for section in cfg.sections():
        if section.startswith("Install") and cfg.getboolean(section, "Locked", fallback=False):
            rel = cfg.get(section, "Default")
            return install_dir / rel

    for section in cfg.sections():
        if section.startswith("Profile") and cfg.getboolean(section, "Default", fallback=False):
            rel = cfg.get(section, "Path")
            return install_dir / rel

    sys.exit(f"error: couldn't find a default profile in {ini_path}")


def is_running(browser):
    proc = BROWSERS[browser]["proc"]
    if sys.platform == "win32":
        out = subprocess.run(
            ["tasklist", "/FI", f"IMAGENAME eq {proc}"], capture_output=True, text=True
        ).stdout
        return proc.lower() in out.lower()
    return subprocess.run(["pgrep", "-x", proc], stdout=subprocess.DEVNULL).returncode == 0


def load_mozlz4(path):
    data = path.read_bytes()
    if data[:8] != b"mozLz40\0":
        sys.exit(f"error: {path} isn't mozlz4-compressed (bad magic)")
    return json.loads(lz4.block.decompress(data[8:]))


def save_mozlz4(path, obj):
    raw = json.dumps(obj).encode()
    compressed = lz4.block.compress(raw, mode="default", store_size=False)
    payload = b"mozLz40\0" + struct.pack("<I", len(raw)) + compressed
    path.write_bytes(payload)


def cmd_apply(browsers):
    if not TRACKED_JSON.exists():
        sys.exit(f"error: no tracked engines at {TRACKED_JSON} -- run `chezmoi apply` first")
    custom = json.loads(TRACKED_JSON.read_text())

    for browser in browsers:
        if is_running(browser):
            print(f"skip {browser}: still running -- close it first (it'll clobber this on exit)", file=sys.stderr)
            continue

        profile = active_profile_dir(browser)
        search_json = profile / "search.json.mozlz4"
        if not search_json.exists():
            print(f"skip {browser}: no search.json.mozlz4 at {search_json}", file=sys.stderr)
            continue

        backup = search_json.with_suffix(search_json.suffix + f".bak-{os.getpid()}")
        data = load_mozlz4(search_json)
        by_id = {e["id"]: e for e in data["engines"]}

        added, updated = [], []
        for tracked in custom:
            existing = by_id.get(tracked["id"])
            if existing is None:
                data["engines"].append(tracked)
                added.append(tracked["_name"])
                continue
            # upsert: sync name/urls/aliases from tracked, but keep this
            # profile's own order/hasBeenUsed in _metaData rather than
            # resetting them.
            fields_changed = any(
                existing.get(k) != tracked.get(k)
                for k in ("_name", "_urls", "_definedAliases", "_iconMapObj", "_filePath")
            )
            alias_changed = existing.get("_metaData", {}).get("alias") != tracked.get("_metaData", {}).get("alias")
            if not (fields_changed or alias_changed):
                continue
            for k in ("_name", "_urls", "_definedAliases", "_iconMapObj", "_filePath"):
                existing[k] = tracked.get(k)
            if "alias" in tracked.get("_metaData", {}):
                existing.setdefault("_metaData", {})["alias"] = tracked["_metaData"]["alias"]
            else:
                existing.get("_metaData", {}).pop("alias", None)
            updated.append(tracked["_name"])

        if not added and not updated:
            print(f"{browser}: already in sync with {len(custom)} tracked engine(s), nothing to do")
            continue

        search_json.rename(backup)
        save_mozlz4(search_json, data)
        if added:
            print(f"{browser}: added {len(added)} -- {', '.join(added)}")
        if updated:
            print(f"{browser}: updated {len(updated)} -- {', '.join(updated)}")
        print(f"{browser}: backup at {backup}")


def source_json():
    """The chezmoi source copy -- what `dump` has to write.

    TRACKED_JSON is the *deployed* path: chezmoi regenerates it from the repo on
    every apply, so a dump written there is silently reverted (and makes chezmoi
    ask "has changed since chezmoi last wrote it?" on the next apply).
    """
    repo = subprocess.run(
        ["chezmoi", "source-path"], capture_output=True, text=True
    ).stdout.strip() or str(Path.home() / ".local/share/chezmoi")
    return Path(repo) / "dot_config/search-engines/custom-engines.json"


def cmd_dump(browser, force=False):
    profile = active_profile_dir(browser)
    search_json = profile / "search.json.mozlz4"
    if not search_json.exists():
        sys.exit(f"error: no search.json.mozlz4 at {search_json}")

    data = load_mozlz4(search_json)
    custom = [e for e in data["engines"] if is_custom(e)]

    target = source_json()
    existing = []
    if target.exists():
        try:
            existing = json.loads(target.read_text())
        except json.JSONDecodeError:
            existing = []

    # A profile with no custom engines -- a fresh one, or the wrong browser --
    # must not wipe the tracked list. This is how 31 engines disappeared once.
    if not custom and existing and not force:
        sys.exit(
            f"error: {browser} reports 0 custom engines but {target} tracks {len(existing)}\n"
            f"       refusing to overwrite it -- re-run with --force if that is really wanted"
        )

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(custom, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(custom)} custom engine(s) from {browser} to {target}")
    print(f"\nreview with: git -C {target.parents[2]} diff -- dot_config/search-engines/custom-engines.json")
    print("then commit from the source repo, and `chezmoi apply` to deploy it")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)

    action = sys.argv[1]
    if action == "apply":
        target = sys.argv[2] if len(sys.argv) > 2 else "both"
        browsers = list(BROWSERS) if target == "both" else [target]
        for b in browsers:
            if b not in BROWSERS:
                sys.exit(f"error: unknown browser {b!r} -- expected one of {list(BROWSERS)}")
        cmd_apply(browsers)
    elif action == "dump":
        if len(sys.argv) < 3 or sys.argv[2] not in BROWSERS:
            sys.exit(f"usage: {sys.argv[0]} dump <{'|'.join(BROWSERS)}>")
        rest = sys.argv[2:]
        cmd_dump(sys.argv[2], force="--force" in rest)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
