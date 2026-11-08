#!/usr/bin/env python3
"""Export the active Firefox/Waterfox profile's extension list into the repo.

Firefox Sync carries the extensions themselves (and any `storage.sync` data), but
not their *settings* -- those live in the profile's storage/default/ IndexedDB,
which is per-profile and not portable. So the repo keeps a list of what should be
installed, and the per-extension export files (uBlock backup, Dark Reader export,
Tridactyl's :mktridactylrc, Sideberry's settings JSON) cover the settings.

Writes the chezmoi source copy, never the deployed one -- same rule as
sync-search-engines.py: only `chezmoi apply` writes deployed paths.

Usage: export-firefox-extensions.py [firefox|waterfox]   (default: firefox)
"""

import json
import subprocess
from configparser import ConfigParser
import sys
from pathlib import Path

CONFIG_HOME = Path(__import__("os").environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")

BROWSERS = {
    "firefox": [CONFIG_HOME / "mozilla" / "firefox", Path.home() / ".mozilla/firefox"],
    "waterfox": [CONFIG_HOME / "waterfox", Path.home() / ".waterfox"],
}

# Bundled/system add-ons that every install has; not worth tracking.
BUILTIN = {
    "formautofill@mozilla.org",
    "ipp-activator@mozilla.com",
    "newtab@mozilla.org",
    "pictureinpicture@mozilla.org",
    "addons-search-detection@mozilla.com",
    "webcompat@mozilla.org",
}


def source_path() -> Path:
    repo = subprocess.run(["chezmoi", "source-path"], capture_output=True, text=True).stdout.strip() \
        or str(Path.home() / ".local/share/chezmoi")
    return Path(repo) / "dot_config/firefox-tweaks/extensions.txt"


def active_profile(browser: str) -> Path:
    """The profile Firefox would use: a locked Install section wins, then
    [ProfileN] Default=1, then whichever profile directory actually has an
    extensions.json (the two can disagree -- a leftover "default" profile on this
    box shadows the real default-release one)."""
    for candidate in BROWSERS[browser]:
        ini = candidate / "profiles.ini"
        if not ini.exists():
            continue

        cfg = ConfigParser()
        cfg.read(ini)

        for section in cfg.sections():
            if section.startswith("Install") and cfg.getboolean(section, "Locked", fallback=False):
                resolved = candidate / cfg.get(section, "Default", fallback="")
                if (resolved / "extensions.json").exists():
                    return resolved

        for section in cfg.sections():
            if section.startswith("Profile") and cfg.getboolean(section, "Default", fallback=False):
                resolved = candidate / cfg.get(section, "Path", fallback="")
                if (resolved / "extensions.json").exists():
                    return resolved

        profiles = sorted(
            (d for d in candidate.iterdir() if (d / "extensions.json").exists()),
            key=lambda d: (d / "extensions.json").stat().st_mtime,
            reverse=True,
        )
        if profiles:
            return profiles[0]

    sys.exit(f"error: no {browser} profile with an extensions.json")



def main() -> None:
    browser = sys.argv[1] if len(sys.argv) > 1 else "firefox"
    if browser not in BROWSERS:
        sys.exit(f"usage: {sys.argv[0]} [{'|'.join(BROWSERS)}]")

    profile = active_profile(browser)
    addons = json.loads((profile / "extensions.json").read_text()).get("addons", [])

    rows = []
    for addon in addons:
        if addon.get("type") != "extension" or addon.get("id") in BUILTIN:
            continue
        name = addon.get("defaultLocale", {}).get("name") or addon.get("id")
        state = "disabled" if addon.get("userDisabled") else "enabled"
        rows.append((name, addon.get("id"), addon.get("version", "?"), state))

    rows.sort()
    out = [
        "# Firefox extensions, exported from " + str(profile),
        "# Regenerate: ~/scripts/export-firefox-extensions.py firefox",
        "# Settings are not portable -- see README (Firefox section) for the export",
        "# files and sync options. This list is a record, not an installer.",
        "",
    ]
    out += ["\t".join(row) for row in rows]

    target = source_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(out) + "\n")
    print(f"wrote {len(rows)} extension(s) to {target}")


if __name__ == "__main__":
    main()
