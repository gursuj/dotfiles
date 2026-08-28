#!/bin/sh
# Pulls GitHub-sourced plugins out of `herdr plugin list --json` into chezmoi's
# desired-plugins.txt. Run after `herdr plugin install owner/repo`, commit the
# result, other machines pick it up on next `chezmoi apply`.
#
# Local (`herdr plugin link`) plugins contribute nothing to this machine's scan
# -- e.g. gursuj/herdr-auto-namer is linked straight to D:\code\gursuj here for
# dev, so `herdr plugin list --json` reports it as source.kind "local", not
# "github". That does NOT mean it should drop out of desired-plugins.txt --
# other machines install it fresh from GitHub and still need that line. So
# this merges (union of existing file + currently-detected github repos)
# instead of overwriting. Bit the dev machine once: this used to fully
# regenerate the file from source.kind=="github" entries only, which silently
# dropped auto-namer's line the moment a second, github-installed plugin
# (drovr) existed alongside it -- the "skip if nothing github-sourced found"
# guard only covered an all-local machine, not this mixed case.
#
# Removal is intentionally manual now: if a plugin's genuinely retired
# everywhere, delete its line from the source file by hand.
#
# Manual step chezmoi can't remove -- no live sync between devices, only
# committed source. See README.

set -eu

if ! command -v herdr >/dev/null 2>&1; then
  echo "herdr not found on PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found on PATH -- needed to parse herdr plugin list --json" >&2
  exit 1
fi

source_repo="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
dest="$source_repo/dot_config/herdr/desired-plugins.txt"

repos="$(herdr plugin list --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
plugins = data["result"]["plugins"]
out = []
for p in plugins:
    source = p.get("source", {})
    if source.get("kind") == "github":
        out.append(source["owner"] + "/" + source["repo"])
print("\n".join(sorted(out)))
')"

existing="$(cat "$dest" 2>/dev/null || true)"
merged="$(printf '%s\n%s\n' "$existing" "$repos" | sed '/^$/d' | sort -u)"

printf '%s\n' "$merged" > "$dest"

count=$(wc -l < "$dest" | tr -d ' ')
echo "wrote $count plugin(s) to $dest (merged with existing entries, none removed)"
echo
git -C "$source_repo" diff -- dot_config/herdr/desired-plugins.txt
echo
echo "review the diff above, then commit from $source_repo"
