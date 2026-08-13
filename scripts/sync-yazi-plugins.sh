#!/bin/sh
# Pulls plugin names out of local package.toml into chezmoi's
# desired-plugins.txt. Run after `ya pkg add <plugin>`, commit the result,
# other machines pick it up on next `chezmoi apply`.
#
# Manual step chezmoi can't remove -- no live sync between devices, only
# committed source. package.toml itself stays untracked (hash churns per
# machine); this just mirrors its `use = "..."` lines. See README.

set -eu

config_home="${YAZI_CONFIG_HOME:-$HOME/.config/yazi}"
pkg_toml="$config_home/package.toml"
source_repo="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
dest="$source_repo/dot_config/yazi/desired-plugins.txt"

if [ ! -f "$pkg_toml" ]; then
  echo "no package.toml at $pkg_toml -- nothing to sync" >&2
  exit 1
fi

grep '^use = "' "$pkg_toml" | sed 's/^use = "\(.*\)"$/\1/' > "$dest"

count=$(wc -l < "$dest" | tr -d ' ')
echo "wrote $count plugin(s) to $dest"
echo
git -C "$source_repo" diff -- dot_config/yazi/desired-plugins.txt
echo
echo "review the diff above, then commit from $source_repo"
