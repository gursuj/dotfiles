# Handoff — Firefox extension shortcuts

Status: **done on the IdeaPad (2026-11-08). One step left on every other machine (t14 first).**

## Result

The shortcuts are tracked in `dot_config/extension-shortcuts/firefox-shortcuts.json` and
carried by `scripts/sync-extension-shortcuts.py` (`apply` / `dump`). 14 bindings across 5
add-ons: Dark Reader, Sidebery, Bitwarden, UltimaDark, Violentmonkey. Deliberately unset keys
(e.g. Dark Reader `toggle` = `""`) are tracked too.

## Findings

- The original plan was wrong. This doc used to say bindings are
  `user_pref("commands.<id>.<cmd>", ...)` lines in `prefs.js`, to be carried via `user.js`.
  A scan found **0** such lines on the IdeaPad, which has 14 bindings set.
- Real store: the profile's `extension-settings.json`, top-level `commands` key. Each command
  has a `precedenceList` of `{id, installDate, value: {shortcut}, enabled}`. `user.js` cannot
  write it, so nothing was added to `firefox-preferences.js.tmpl`.
- Firefox 147+ keeps profiles in `~/.config/mozilla/firefox` (XDG) on a fresh install, but
  the IdeaPad's profile is still at the legacy `~/.mozilla/firefox`. Both machines' paths are
  worth checking, which is why the script reads `profiles.ini` instead of hardcoding a profile.
- Profile dir names are random per machine (`l6zcy5s7.default-release` on the IdeaPad,
  `ay458jc3.default-release` on the t14) and Firefox rewrites `extension-settings.json` on
  exit. That is why this is a manual script and not a chezmoi `modify_` script.
- Containers' `open_container_N` / `reopen_in_container_N` entries have no `shortcut` key, so
  they are not bindings and `dump` skips them.
- `Ctrl+Alt+D` is bound to both Dark Reader `addSite` and UltimaDark `toggle-site`. Kept on
  purpose (user decision 2026-11-08). Do not "fix" it.
- Waterfox is not covered. It has different add-ons and different bindings (Bitwarden is
  `_execute_browser_action` there, `_execute_sidebar_action` in Firefox). Applying this
  file to it would set the wrong commands. See the script docstring for what a Waterfox
  switch needs.
- `apply` skips add-ons missing from the profile's `extensions.json`, so Sync must have
  installed the extensions first.
- Tested: `dump` against the live IdeaPad profile; `apply` against a scratch copy of it
  (in-sync no-op, changed key, new command, uninstalled add-on skipped, re-apply no-op).
  **Not yet run** against a live profile, on Windows, or on the t14.

## Instructions for the t14 agent

1. `git pull` in `~/.local/share/chezmoi`, then `chezmoi apply`. This deploys the script
   (`~/scripts/`) and `~/.config/extension-shortcuts/firefox-shortcuts.json`.
2. Confirm the add-ons are installed in Firefox (Sync). The ids are in the json.
3. **Close Firefox fully.** `pgrep -x firefox` should print nothing. The script refuses to
   run otherwise.
4. Run `~/scripts/sync-extension-shortcuts.py apply`. It prints each shortcut it set, any
   add-on it skipped, and a `.bak-<pid>` backup path.
5. Start Firefox. Check `about:addons` → gear → **Manage Extension Shortcuts** shows the
   keys from the json.
6. If something looks wrong, close Firefox and restore the `.bak-<pid>` file over
   `extension-settings.json` in the profile dir.
7. Do not run `dump` on the t14 unless you changed a shortcut there on purpose. It
   overwrites the tracked json with that machine's state.

## Adding or changing a shortcut later

1. Set it in `about:addons` → Manage Extension Shortcuts.
2. Close Firefox (it writes `extension-settings.json` on exit).
3. `scripts/sync-extension-shortcuts.py dump`
4. `chezmoi re-add ~/.config/extension-shortcuts/firefox-shortcuts.json`
5. Review `git diff`, commit.

## Open items

- Verify `apply` on the t14's live profile and report back here or in `learnings.md`.
- The Windows path (`%APPDATA%\Mozilla\Firefox`) is copied from `sync-search-engines.py` and
  untested.
