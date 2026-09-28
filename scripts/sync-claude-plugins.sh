#!/bin/sh
# Pulls non-built-in, non-predating plugins out of `claude plugin list --json`
# and `claude plugin marketplace list --json` into chezmoi's
# dot_claude/desired-plugins.txt. Run after `claude plugin marketplace add` +
# `claude plugin install`, commit the result, other machines pick it up on
# next `chezmoi apply`.
#
# claude-plugins-official and wpc-os are both excluded -- figma (official,
# ships with Claude Code, no marketplace add needed) and wp-creative (org
# plugin, installed via the wpc-client-setup skill) predate this pattern and
# are deliberately left out of the merge (see README) -- if you want either
# tracked here too, add its line to desired-plugins.txt by hand once.
#
# Union of existing file + currently-detected plugins, same as herdr's sync
# helper -- removal is manual, see README.

set -eu

if ! command -v claude >/dev/null 2>&1; then
  echo "claude not found on PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found on PATH -- needed to parse claude plugin JSON" >&2
  exit 1
fi

source_repo="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
dest="$source_repo/dot_claude/desired-plugins.txt"

plugins_json="$(claude plugin list --json)"
marketplaces_json="$(claude plugin marketplace list --json)"

detected="$(python3 -c '
import json, sys
plugins = json.loads(sys.argv[1])
marketplaces = {m["name"]: m for m in json.loads(sys.argv[2])}
out = []
for p in plugins:
    if p.get("scope") == "synced":
        continue
    pid = p.get("id", "")
    if "@" not in pid:
        continue
    _, marketplace = pid.split("@", 1)
    if marketplace in ("claude-plugins-official", "wpc-os"):
        continue
    m = marketplaces.get(marketplace)
    if not m or m.get("source") != "github":
        continue
    out.append(m["repo"] + " " + pid)
print("\n".join(sorted(out)))
' "$plugins_json" "$marketplaces_json")"

existing="$(cat "$dest" 2>/dev/null || true)"
merged="$(printf '%s\n%s\n' "$existing" "$detected" | sed '/^$/d' | sort -u)"

printf '%s\n' "$merged" > "$dest"

count=$(wc -l < "$dest" | tr -d ' ')
echo "wrote $count plugin(s) to $dest (merged with existing entries, none removed)"
echo
git -C "$source_repo" diff -- dot_claude/desired-plugins.txt
echo
echo "review the diff above, then commit from $source_repo"
