#!/usr/bin/env python3
"""Merge Firefox extension keyboard shortcuts between a profile and chezmoi's
tracked copy at ~/.config/extension-shortcuts/firefox-shortcuts.json.

Shortcuts set in about:addons -> Manage Extension Shortcuts live in the
profile's extension-settings.json under "commands" (not prefs.js, so user.js
can't set them). Firefox Sync syncs extensions, not their bindings.

  apply   merge tracked shortcuts into the live profile. Firefox must be
          closed first -- it rewrites this file on exit and would clobber
          the merge. Add-ons not installed in the profile are skipped.
  dump    pull the profile's shortcuts into the tracked json, for
          review/commit from the source repo (chezmoi apply won't do this
          direction automatically). Run after changing a shortcut in the GUI.

Firefox only. Waterfox has different add-ons and different bindings (e.g.
Bitwarden's Ctrl+Alt+B is _execute_browser_action there, _execute_sidebar_action
in Firefox), so applying this file to it would set the wrong commands. If you
switch: add a "waterfox" entry to BROWSERS (see sync-search-engines.py for the
paths), give it its own tracked json, and make TRACKED_JSON per-browser.

Active profile dir is auto-detected from profiles.ini. Stdlib only. Never
auto-run by chezmoi -- re-run this yourself after `chezmoi apply` on a new
device.
"""
import json
import os
import subprocess
import sys
import time
from configparser import ConfigParser
from pathlib import Path

if sys.platform == "win32":
    BROWSERS = {
        "firefox": {"dir": Path(os.environ["APPDATA"]) / "Mozilla" / "Firefox", "proc": "firefox.exe"},
    }
else:
    BROWSERS = {
        "firefox": {"dir": Path.home() / ".mozilla/firefox", "proc": "firefox"},
    }

BROWSER = "firefox"
TRACKED_JSON = Path.home() / ".config/extension-shortcuts/firefox-shortcuts.json"


def active_profile_dir():
    info = BROWSERS[BROWSER]
    ini_path = info["dir"] / "profiles.ini"
    if not ini_path.exists():
        sys.exit(f"error: no profiles.ini at {ini_path} -- is {BROWSER} installed?")

    cfg = ConfigParser()
    cfg.read(ini_path)

    # a Locked install section's Default wins over any [ProfileN] Default=1
    for section in cfg.sections():
        if section.startswith("Install") and cfg.getboolean(section, "Locked", fallback=False):
            return info["dir"] / cfg.get(section, "Default")

    for section in cfg.sections():
        if section.startswith("Profile") and cfg.getboolean(section, "Default", fallback=False):
            return info["dir"] / cfg.get(section, "Path")

    sys.exit(f"error: couldn't find a default profile in {ini_path}")


def is_running():
    proc = BROWSERS[BROWSER]["proc"]
    if sys.platform == "win32":
        out = subprocess.run(
            ["tasklist", "/FI", f"IMAGENAME eq {proc}"], capture_output=True, text=True
        ).stdout
        return proc.lower() in out.lower()
    return subprocess.run(["pgrep", "-x", proc], stdout=subprocess.DEVNULL).returncode == 0


def installed_addons(profile):
    """{addon id: display name} from extensions.json."""
    path = profile / "extensions.json"
    if not path.exists():
        return {}
    addons = json.loads(path.read_text()).get("addons", [])
    return {a["id"]: (a.get("defaultLocale") or {}).get("name", "") for a in addons}


def cmd_apply():
    if not TRACKED_JSON.exists():
        sys.exit(f"error: no tracked shortcuts at {TRACKED_JSON} -- run `chezmoi apply` first")
    tracked = json.loads(TRACKED_JSON.read_text())

    if is_running():
        sys.exit(f"error: {BROWSER} still running -- close it first (it'll clobber this on exit)")

    profile = active_profile_dir()
    settings_path = profile / "extension-settings.json"
    if not settings_path.exists():
        sys.exit(f"error: no extension-settings.json at {settings_path} -- start {BROWSER} once first")

    data = json.loads(settings_path.read_text())
    commands = data.setdefault("commands", {})
    installed = installed_addons(profile)

    changed, skipped = [], []
    for addon_id, entry in tracked.items():
        label = entry.get("name") or addon_id
        if addon_id not in installed:
            skipped.append(label)
            continue
        for command, key in entry["commands"].items():
            plist = commands.setdefault(command, {"precedenceList": []})["precedenceList"]
            existing = next((e for e in plist if e["id"] == addon_id), None)
            if existing is None:
                plist.insert(0, {
                    "id": addon_id,
                    "installDate": int(time.time() * 1000),
                    "value": {"shortcut": key},
                    "enabled": True,
                })
            elif existing.get("value", {}).get("shortcut") == key:
                continue
            else:
                # keep this profile's installDate/enabled, only set the key
                existing.setdefault("value", {})["shortcut"] = key
            changed.append(f"{label}: {command} = {key or '(unset)'}")

    if skipped:
        print(f"skipped (not installed): {', '.join(skipped)}", file=sys.stderr)
    if not changed:
        print(f"{BROWSER}: already in sync, nothing to do")
        return

    backup = settings_path.with_suffix(settings_path.suffix + f".bak-{os.getpid()}")
    settings_path.rename(backup)
    settings_path.write_text(json.dumps(data))
    print(f"{BROWSER}: set {len(changed)} shortcut(s)")
    for line in changed:
        print(f"  {line}")
    print(f"{BROWSER}: backup at {backup}")


def cmd_dump():
    profile = active_profile_dir()
    settings_path = profile / "extension-settings.json"
    if not settings_path.exists():
        sys.exit(f"error: no extension-settings.json at {settings_path}")

    names = installed_addons(profile)
    out = {}
    for command, setting in json.loads(settings_path.read_text()).get("commands", {}).items():
        for e in setting.get("precedenceList", []):
            value = e.get("value", {})
            # open_container_N etc. have only a description, no shortcut -- not a binding
            if "shortcut" not in value:
                continue
            addon = out.setdefault(e["id"], {"name": names.get(e["id"], ""), "commands": {}})
            addon["commands"][command] = value["shortcut"]

    for addon in out.values():
        addon["commands"] = dict(sorted(addon["commands"].items()))

    TRACKED_JSON.parent.mkdir(parents=True, exist_ok=True)
    TRACKED_JSON.write_text(json.dumps(out, indent=2, sort_keys=True) + "\n")
    total = sum(len(a["commands"]) for a in out.values())
    print(f"wrote {total} shortcut(s) across {len(out)} add-on(s) from {BROWSER} to {TRACKED_JSON}")

    source_repo = subprocess.run(
        ["chezmoi", "source-path"], capture_output=True, text=True
    ).stdout.strip() or str(Path.home() / ".local/share/chezmoi")
    print(f"\nnext: chezmoi re-add {TRACKED_JSON}")
    print(f"review with: git -C {source_repo} diff -- dot_config/extension-shortcuts/firefox-shortcuts.json")
    print("then commit from the source repo")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("apply", "dump"):
        sys.exit(__doc__)
    cmd_apply() if sys.argv[1] == "apply" else cmd_dump()


if __name__ == "__main__":
    main()
