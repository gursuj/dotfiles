#!/bin/sh
# Extracts installed yazi plugin names from the local package.toml and writes
# them into the chezmoi source's desired-plugins.txt -- run this after
# `ya pkg add <plugin>` so other machines pick it up on their next
# `chezmoi apply`, once you've committed the result.
#
# This is the one manual step chezmoi can't remove: propagation across
# machines only happens through committed source, not live device-to-device
# sync, so *something* has to turn "what I just installed here" into "what
# every machine should have." This script does that mechanically -- you
# never type a plugin name by hand, you just run this after `ya pkg add`.
#
# package.toml itself stays untracked by chezmoi (its `hash` field churns
# per machine on every `ya pkg add`/`install` run); this only lifts the
# stable `use = "..."` declarations out of it. See README's yazi section.

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
