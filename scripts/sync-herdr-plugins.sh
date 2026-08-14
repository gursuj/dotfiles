#!/bin/sh
# Pulls GitHub-sourced plugins out of `herdr plugin list --json` into chezmoi's
# desired-plugins.txt. Run after `herdr plugin install owner/repo`, commit the
# result, other machines pick it up on next `chezmoi apply`.
#
# Local (`herdr plugin link`) plugins are skipped on purpose -- those are
# dev-machine-only paths (e.g. D:\code\gursuj\herdr-auto-namer here), nothing
# to sync. Only source.kind == "github" entries go in the file.
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

# Guard against wiping an already-populated file: this happens on a machine
# where every plugin is `herdr plugin link`-ed (dev machines) rather than
# github-installed -- that machine has nothing to contribute to the sync,
# and running this here would otherwise erase what other machines rely on.
if [ -z "$repos" ] && [ -s "$dest" ]; then
  echo "no github-sourced plugins found (only local links here?) -- leaving $dest untouched" >&2
  echo "$dest" >&2
  exit 1
fi

printf '%s\n' "$repos" > "$dest"

count=$(wc -l < "$dest" | tr -d ' ')
echo "wrote $count plugin(s) to $dest"
echo
git -C "$source_repo" diff -- dot_config/herdr/desired-plugins.txt
echo
echo "review the diff above, then commit from $source_repo"
