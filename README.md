# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io). Source repo lives at
`~/.local/share/chezmoi` on every machine — that's chezmoi's own built-in default path,
not a custom choice, so it's the same on Windows and Linux without any config.

Remote: `git@github.com:gursuj/dotfiles.git`.

## Branches

`main` is the IdeaPad-era config. **`t14` is a migration branch for the ThinkPad T14 running
Omarchy, and it is meant to merge back into `main`** once the IdeaPad is retired (a few days
after 2026-11-07) — it is not a permanent fork. On `t14`, `machine_kind` for the laptop is
`t14` (`"arch"` is retired), and the intent is to reproduce the old machine's behaviour on top
of Omarchy's own config layer rather than redesign it.

Two working notes from that effort live in `docs/`:

- `docs/t14-merge-handoff.md` — state of the migration, what is left before `chezmoi apply`,
  and the merge checklist for folding `t14` back into `main`.
- `docs/pkg-install-terminal-scratchpad.md` — the package-picker window placement work: why a
  hand-spawned window is not evidence, what the menu actually runs, and the rule + close hook
  that puts the picker on the scratchpad and returns you to your workspace afterwards.

## Dependencies

Everything here is stdlib shell/Python, except:

- **python3**, for the two browser-sync scripts (`run_onchange_after_60-browser-user-js-sync.py.tmpl`,
  `scripts/sync-search-engines.py`). Needed on every machine including Windows -- not
  bundled with chezmoi itself, so a fresh Windows box needs it installed and on PATH
  before its first `chezmoi apply` (the sync script silently no-ops if `python` isn't
  found, since chezmoi's `[interpreters.py]` mapping just fails to launch it).
- **`pip install lz4`**, only for `scripts/sync-search-engines.py` (Firefox/Waterfox's
  `search.json.mozlz4` is lz4-compressed, no stdlib decompressor for that format). The
  script exits with this exact instruction if the module's missing, so you'll know
  immediately if it wasn't run.

### New-device manual steps

Not everything here is `chezmoi apply`-and-done:

- **Custom search engines** (`dot_config/search-engines/custom-engines.json`) never
  auto-apply -- `scripts/sync-search-engines.py apply both` needs running by hand after
  `chezmoi apply`, with both browsers closed first (they rewrite this file on exit and
  would clobber the merge). This is deliberate, not a gap -- see the script's own
  docstring.
- **Firefox/Waterfox `user.js`** auto-syncs via a symlink on Linux, and now on Windows
  too, but the Windows path is untested on a real machine -- check the
  `run_onchange_after_60-browser-user-js-sync.py.tmpl` output on first `chezmoi apply` on
  a new Windows box rather than assuming it linked (or copied) correctly.

`AGENTS.md` at repo root points agents (opencode natively, Claude Code where it honours
`AGENTS.md`) at `learnings.md` — the dated log of resolved issues and corrections for
this repo. Keeps that history out of this README so the README stays current-state only.

## Using chezmoi (workflow)

Two ways to make a change; pick edit-source-first as the default.

- **Edit-source-first (default).** `chezmoi edit <target>` opens the source file directly
  (handles templates and encryption transparently), then `chezmoi apply` (or
  `chezmoi edit --apply` to do both at once). This is the safe default, especially for
  templated files like `dot_claude/settings.json.tmpl` — see below for why.
- **Edit-live-then-sync-back.** Edit the live file directly, then `chezmoi re-add` (or
  `chezmoi add <file>` for a single one) to pull the change back into source. Faster for a
  quick one-off tweak, but **`re-add` does not work on templated files** — it operates on
  plain source files only, so running it against a `.tmpl` will either skip it or clobber
  the template logic (`{{- if ... }}` blocks etc.) with flattened, rendered output. Given
  several files here are templated (`settings.json.tmpl`, the herdr config template), treat
  this path as the exception, not the habit. For an age-encrypted file (e.g. cliamp's
  `config.toml`), plain `chezmoi add` without `chezmoi init` having loaded the `[age]` block
  will offer to *remove* the encrypted attribute instead of re-encrypting — always run
  `chezmoi add --encrypt <file>` for these, and make sure `chezmoi init` has been run on the
  machine first so the age identity/recipient are actually configured.

Other useful commands: `chezmoi diff` (preview before apply — note it can show CRLF/LF
noise as spurious diff lines on Windows-tracked files, not real content changes; check
before assuming something changed), `chezmoi status` (quick out-of-sync check), `chezmoi
merge` / `merge-all` (three-way merge when both source and live have drifted — safer than
`re-add` for that case).

`cz` is a shorthand alias for `chezmoi` (e.g. `cz status` / `cz diff` / `cz apply`) — `alias
cz=chezmoi` in `dot_config/shell/aliasrc` (all Linux machine kinds), `function cz` in the PowerShell
profile on Windows.

`chezmoi status` can flag a *directory* as modified (`MM`) while `chezmoi diff` on that same
path shows nothing — that's not the CRLF/LF noise above, it's directory metadata (perms/mtime)
drift, which `status` picks up but `diff` doesn't render since it only diffs file content.
Confirm with `chezmoi diff -- <dir>`: empty output means it's metadata-only and safe to
`chezmoi apply --force <dir>` past the "changed since chezmoi last wrote it" prompt that
plain `apply` hits for these (no TTY-safe way to answer that prompt otherwise).

`chezmoi apply` can hang on an interactive prompt (e.g. asking to confirm an overwrite)
instead of erroring out — if an agent session appears stuck on `apply`, just kill it rather
than waiting it out. Always run `chezmoi diff` and have the user manually review the diff
before running `apply`, rather than applying directly.

If a tracked file keeps showing a large diff on every check even though nothing meaningful
changed, check for a line-ending mismatch before assuming real drift: some external tool
that writes the live file may hardcode a line ending regardless of OS (e.g. Claude Code
always saves `settings.json` with LF, even on Windows — confirmed 2026-08-11, source template
had CRLF from whenever it was first created/edited, causing a whole-file diff on every
`chezmoi status`). Fix by converting the *source* file's line endings to match what the
external tool actually writes, not the other way round — track in whatever format the thing
saving the live file uses, don't fight it.

Note: this workflow duplication (manually running `chezmoi edit`/`apply`/`diff` each time)
is exactly the kind of repeatable, rule-based task that might be better served by a proper
Claude Code skill instead of relying on CLAUDE.md prose reminders — worth revisiting once
this repo's usage patterns settle.

## Currently tracked

| What | Source path | Notes |
| --- | --- | --- |
| Custom scripts | `scripts/` | `~/scripts` |
| Firefox/Waterfox `user.js` | `dot_config/firefox-tweaks/user.js` (built from `.chezmoitemplates/firefox-performance.js.tmpl` + `firefox-preferences.js.tmpl`) | Auto-symlinked (copy fallback on Windows) into each browser's active profile by `run_onchange_after_60-browser-user-js-sync.py.tmpl` on every `chezmoi apply`. Skipped on the VPS (no browser there). See Dependencies above for the python3 requirement. |
| Custom search engines | `dot_config/search-engines/custom-engines.json` | Firefox Sync doesn't carry custom search engines (they live in `search.json.mozlz4`, not `places.sqlite`). Merged into a live profile manually via `scripts/sync-search-engines.py apply both` -- never auto-applied by chezmoi, see Dependencies above. |
| Agent pointer files | `AGENTS.md`, `CLAUDE.md`, `learnings.md`, `TODO.md` | Repo root, not chezmoi-templated. `AGENTS.md` (opencode's native file, also honoured by Claude Code in setups that support it) and `CLAUDE.md` (thin pointer, see below) both point at `learnings.md` — the dated log of resolved issues/corrections — so any agent working in this repo picks it up regardless of which one it reads by default. `TODO.md` holds open items, kept out of this README. |
| Claude Code settings | `dot_claude/settings.json.tmpl` | Templated — the PowerShell notification/herdr hooks only render on Windows (`{{ if eq .chezmoi.os "windows" }}`), since those `.ps1` scripts don't exist on Linux. The real personal `CLAUDE.md` (full org/user instructions) is deliberately **not** tracked here — it can carry client/work-sensitive content. The tracked root `CLAUDE.md` is just a thin pointer to `AGENTS.md`, not the real one. |
| Claude Code terse output style | `dot_claude/output-styles/terse.md` | `outputStyle: Terse` in settings.json above makes this the global default for every session. Has an explicit exception for drafting messages meant for someone else (emails, ClickUp updates, LinkedIn posts, client-facing docs) — those use normal writing-voice guidance instead, and for code comments specifically it now applies the same fragment/abbreviation rules as prose (previously exempted all code content wholesale). |
| Claude Code keybindings | `dot_claude/keybindings.json` | Custom vim-style h/j/k/l rebinds across Tabs/Confirmation/Footer/Attachments/DiffDialog/ModelPicker contexts. Plain file, no secrets. |
| WP-CLI / Local by Flywheel notes | `dot_claude/wordpress-preferences.md` | Contains local dev site paths and a per-site env-activation example (Local run-ID paths) — no credentials or secrets. Site name redacted to a placeholder before making this repo public. |
| WP-CLI / Local by Flywheel shell fix (the `.zshrc`/`.bashrc` sourcing lines) | `dot_zshrc.tmpl`, `dot_bashrc` | Sources `~/.config/shell/local-wpcli/wp-shell-integration.{zsh,sh}` (tracked at `dot_config/shell/local-wpcli/`, moved in from `~/programming/` 2026-10-11; `~/.local/bin/wpl` is a chezmoi-managed symlink to it via `private_dot_local/bin/symlink_wpl.tmpl`; see its own `HANDOFF.md`). In `dot_zshrc.tmpl` the line is placed *before* the `CLAUDECODE` skip-block, deliberately — Claude Code's own shells run `wp` in these site dirs too and need the fix, unlike the interactive-only keybind/completion/plugin setup that block skips. `dot_bashrc` is new and, for now, t14-only (`.chezmoiignore`) — this is the wp-cli fix only, not a general bashrc consolidation; see `TODO.md`'s bash-on-vps note. |
| Neovim config | `dot_config/nvim/` | `init.lua`, `after/`, `readme.md`. Previously its own repo (`gursuj/nvim-temp`, created only as a temporary sync mechanism) — folded in here instead, so that repo can be retired. Targets `~/.config/nvim` on both OSes — see `learnings.md`. |
| PowerShell profile | `readonly_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Windows-only content (PowerShell doesn't run on the VPS) — tracked as-is, no templating needed. `readonly_` prefix just reflects the live folder's read-only attribute, not a chezmoi behaviour choice. |
| Yazi config | `dot_config/yazi/` | `yazi.toml`, `keymap.toml`, `desired-plugins.txt`. Targets `~/.config/yazi` both OSes — see `learnings.md`. `plugins/` dir and `package.toml` not tracked (see `learnings.md`); `desired-plugins.txt` is the real plugin declaration, generated by `scripts/sync-yazi-plugins.sh`. |
| fd ignore patterns | `dot_config/fd/ignore` | Targets `~/.config/fd/ignore` on both OSes — see `learnings.md`. |
| Ghostty config | `dot_config/ghostty/config.tmpl` | Omarchy's shipped defaults (font, padding, cursor, shell-integration, CSI-u Enter keys, split-resize binds, `async-backend = epoll`) plus the IdeaPad's three extras (`copy-on-select`, `ctrl+enter=unbind`, `middle-click-action = clipboard-paste`). The single omarchy-specific line — the `config-file = ?…/omarchy/current/theme/ghostty.conf` theme include — is gated on `{{ if lookPath "omarchy" }}`, so the file renders clean on a non-omarchy machine. `omarchy-refresh-config ghostty/config` would overwrite it. |
| OpenCode config | `dot_config/opencode/opencode.jsonc` | The `mcp.mindwtr` entry (pointed at a Windows-only `D:\git-clone\Mindwtr\...` path) was removed rather than templated — Mindwtr moved to REST-API-only, so a local MCP server entry was stale, not just non-portable. |
| OpenCode TUI plugin config | `dot_config/opencode/tui.jsonc.tmpl` | `{ "plugin": ["./herdr-tui-session.js"] }`, plus `vimcode` pinned to `v0.19.1` on Windows only (opencode v1 reads it here; v2 on arch uses `cli.json`) — small, stable wiring, not itself herdr-managed generated code (see `learnings.md`), so tracked like `settings.json` is for Claude Code. |
| OpenCode v2 CLI config | `dot_config/opencode/cli.json` | Keybinds (leader = space), diffs/session/animation prefs, and the v2 `plugins` array (herdr's TUI plugin, `vimcode` pinned to `v0.19.1`). Different file from `opencode.jsonc`/`tui.jsonc` above — see `learnings.md` for why v2 TUI plugins belong here specifically. |
| Herdr config | `.chezmoitemplates/herdr-config.toml.tmpl` | Shared content, included by two thin per-OS stub files (`AppData/Roaming/herdr/config.toml.tmpl` for Windows, `dot_config/herdr/config.toml.tmpl` for Linux/Mac — confirmed from herdr's own docs) — see `learnings.md`. `default_shell` is left unset entirely now (see `learnings.md`); the `prefix+n` custom keybinding, which shells out to a Windows-only PowerShell script depending on the `cc` function in the tracked PowerShell profile, is still gated to Windows only. |
| Herdr plugins | `dot_config/herdr/desired-plugins.txt` | One `owner/repo` per line, same shape as yazi's file above. `run_after_20-herdr-plugin-install.sh.tmpl` runs `herdr plugin install` for anything missing, then `herdr plugin update`, every apply — see `learnings.md`. |
| `ch` (cch, Claude Code History) | `cl`/`cps`/`cs` aliases in both `dot_zshrc.tmpl` and the PowerShell profile | Installed from our fork (`gursuj/cch`), not upstream `halooojustin/cch` — same package name/binary, so it's a drop-in. `run_onchange_after_35-cch-install.sh.tmpl` does `git clone` + local `npm install -g` rather than npm's own git-protocol installer, since that's blocked in some sandboxed environments (`EALLOWGIT`). Uses the system npm prefix (root-owned on Arch), so the script can't finish the global install unattended — it builds the package into a cache dir and prints a `sudo npm install -g` command for you to run by hand. Also needs a terminal multiplexer (zellij or tmux) on PATH for session resume — neither installed by this repo, bring your own. |
| Kanata config | `dot_config/kanata/kanata.kbd.tmpl` | Targets `~/.config/kanata/kanata.kbd` on both Windows and the t14 ThinkPad (`{{ if eq .chezmoi.os "windows" }}` gates the few things that differ, e.g. dropping `1` from defsrc to dodge a Windows-only WTQ hotkey race). Caps = layer key: tap Esc, hold = Fn layer (number row → F-keys, WASD → arrows). Caps+Grv force-releases stuck modifiers — manual workaround for a kanata bug (jtroo/kanata #423, #1553) where a modifier release can get lost on a keyboard-grab race. Replaces PowerToys KM, which was intermittently dropping the intercept on a cheap membrane keyboard (confirmed not rollover/ghosting first, via NKRO tester). Excluded entirely on the VPS via `.chezmoiignore` (no physical keyboard to remap there). On the t14 it autostarts via `dot_config/systemd/user/kanata.service` (also excluded on the VPS); on Windows it runs via elevated Task Scheduler (`AtLogOn`, 15s delay — Kanata fails silently if started too early) since Startup folder can't grant admin rights. `kanata-start` (PowerShell profile) restarts it by hand, see `learnings.md` for its elevation caveat. |
| Omarchy Hyprland user modules | `dot_config/hypr/{bindings,looknfeel,monitors,autostart}.lua`, `dot_config/hypr/hyprsunset.conf` | Omarchy loads these five from its packaged `hyprland.lua`, which is deliberately **never** tracked — replacing it drops every Omarchy default. `looknfeel.lua` carries the t14 look (no gaps, 1 px border), `binds.workspace_back_and_forth`, `misc.middle_click_paste = false` (compositor-level paste targets the *focused* window, which breaks middle-click in a scratchpad terminal), the screenshot dir, and the package-picker scratchpad rule + close hook — see `docs/pkg-install-terminal-scratchpad.md`. `bindings.lua` ports the IdeaPad binds with `o.bind`/`o.rebind` only: binding an already-bound key leaves both actions live, and the number row is bound by *keycode* (`SUPER + code:10..19`), so a keysym rebind shadows it instead of replacing it. `hyprsunset.conf` is read by the daemon rather than `hyprctl` — apply it with `omarchy restart hyprsunset`. |
| Omarchy shell plugin clones | `dot_config/omarchy/plugins/sujal.{lock,workspaces,monitor}/` | Cloned from the packaged plugins (`omarchy plugin clone`) and then edited: clock/date/battery on the lock screen, occupied-only workspaces with icons and the theme's active colour, and a 1.5 scale preset in the display panel. **Tracking the files does not register them** — the enable list and the bar layout live in `~/.config/omarchy/shell.json`, which is not tracked; `run_onchange_after_45-omarchy-desktop.sh.tmpl` patches it (see the idle row below). `poster.sh` is tracked as `executable_poster.sh` because chezmoi normalises plain files to 644 and the clone should stay executable like upstream's copy. The clones import Omarchy-internal QML modules (`qs.Commons`, `qs.Ui`, `Style`, `Commons.Color.*`), which are not a stable API — an Omarchy update can break a clone while the packaged original keeps working. |
| Zed config | `dot_config/zed/private_settings.json.tmpl`, `dot_config/zed/keymap.json` | `theme` must name the generated `Omazed` theme for both light and dark: `omazed` regenerates `themes/omazed.json` from the active Omarchy theme, but only switches Zed to it when `settings.json` already names it. The theme block is gated on `{{ if lookPath "omazed" }}` with Zed's stock pair as the else-branch, so the file still renders on a box without the package. `keymap.json` is the dock toggles (ctrl-escape / ctrl-b). |
| Omarchy idle timings + display/suspend | `.chezmoiscripts/run_onchange_after_45-omarchy-desktop.sh.tmpl`, `private_dot_local/bin/executable_omarchy-idle`, `dot_config/systemd/user/swayidle.service` | `~/.config/omarchy/shell.json` is deliberately **not** tracked — the shell rewrites it on every bar edit — so a run_onchange script patches only the keys this repo owns, idempotently with jq, and asks the shell to reload: `idle.screensaver` 300 s (the IdeaPad's hypridle "dim at 5 min"), `idle.lock` 600 s (its lock at 10 min), plus the plugin/bar registration for the clones. Omarchy's idle service has no display-off or suspend step, so those hypridle timers live in `swayidle` (repo package): 150 s → keyboard backlight off, 300 s → panel dimmed to 1 % (the screensaver is disabled on this box, so `idle.screensaver` no longer does that job), 630 s → DPMS off, 1200 s → `systemctl suspend`, sharing ext-idle-notify with the shell. Requires `sudo pacman -S swayidle` on a fresh box; the script enables the service once the binary is present. |
| Working docs | `docs/` | Repo-only, never deployed — `docs` is listed in `.chezmoiignore`, like the root docs above (a root-level file or folder missing from that list gets applied into `$HOME`, which is how `docs/` would have landed at `~/docs`). `docs/t14-merge-handoff.md` is the migration state and merge checklist; `docs/pkg-install-terminal-scratchpad.md` is the resolved package-picker write-up. |
| Agent skills (9 of them) | `dot_agents/skills/<name>/` | See below. |
| WTQ (quake-terminal launcher) config | `AppData/Roaming/wtq/wtq.jsonc` | Windows-only tool, plain file, no templating needed. `wtq.schema.json` in the same live folder is shipped by the app itself for schema validation, not user-authored — not tracked. |
| Windows Terminal settings | `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Profiles, keybindings, color schemes, the `_quake` globalSummon action WTQ hotkeys into. The `8wekyb3d8bbwe` publisher-hash segment is Microsoft's own fixed ID for this package, not machine-specific — same path on any Windows install of the Store version. `state.json` in the same folder (window position, last-active tab) is runtime state, not tracked. |
| SaneBreak config | `AppData/Roaming/SaneBreak.ini` | Break-reminder timing settings (interval, flash/confirm durations, bell sounds, postpone ratios). There's also a byte-identical copy at `AppData/Roaming/SaneBreak/SaneBreak.ini` plus a `sane-break.db` (break history) in that same subfolder — only the top-level `.ini` is tracked; the nested copy and the db are the app's own runtime data. |
| WinSCP "Compare Files" extension | `AppData/Roaming/WinSCP/Extensions/CompareFiles.WinSCPextension.ps1` | wpc-only (`.chezmoiignore`). Copy of WinSCP's built-in extension, patched so the WinMerge entry also checks `%LOCALAPPDATA%\Programs\WinMerge` (WinMerge is a per-user install here; stock script only checks Program Files). Gotcha: the Ctrl+Alt+Shift+C shortcut is bound to the *built-in* (`commonext\CompareFiles`), so the install-dir copy needs the same one-line patch too (a WinSCP update overwrites it). Nothing else under `%APPDATA%\WinSCP` exists. Saved sessions/passwords live in the registry (`HKCU:\Software\Martin Prikryl\WinSCP 2`), never tracked. |

### Agent skills tracked

Skills live in `~/.agents/skills/<name>/`, and each agent (Claude Code, opencode, etc.)
gets a Windows junction pointing at that folder — see the "Agent skills" section of the
old `dotfiles.md` note for the junction-creation command. Tracking the real folder here
means editing on any device and running `chezmoi update` on the others picks up the change.

- `agent-browser` — originally installed via `npx skills add vercel-labs/agent-browser --skill agent-browser`. Re-run that command on a fresh machine if you ever want the CLI's own update flow instead of relying on this repo's copy.
- `herdr` — as of 2026-08-18, confirmed CLI-tracked from herdr's own repo (`herdrdev/herdr`, `skills/herdr/SKILL.md`) per `.skill-lock.json` — no longer the "maybe hand-cloned" uncertainty noted here previously. Adopted that official version wholesale (much more complete: workspace/tab/pane and wait commands, Windows-specific troubleshooting) over the old hand-maintained copy. Re-run `npx skills add herdrdev/herdr --skill herdr` on a fresh machine if you want the CLI's own update flow instead of relying on this repo's copy.
- `dotfiles` — **being phased out.** This skill's job (tracking scattered config locations in `dotfiles.md`) is superseded by this very README now that a real repo exists. Kept for now so "edit my dotfiles" still triggers something useful in Claude Code; retarget or retire once `dotfiles.md` is fully migrated.
- `handoff-generic` — deliberately renamed from the upstream skill name `handoff` (source: `mattpocock/skills`) because it collided with a different `handoff` skill installed via a Claude Code plugin. If `npx skills update` output ever looks confused about this skill, that's why — the plugin conflict is Claude-Code-specific, so re-evaluate if the plugin isn't installed on a given machine.
  **TODO (2026-08-18):** the colliding skill was WPC OS's own `_plugin/skills/handoff` — PR open to rename it to `wpc-handoff` (`sujal/rename-handoff-skill`). Once that PR merges and is pulled locally, the collision is gone — remove this `handoff-generic` fork and go back to plain `npx skills add`/`update` for the upstream `handoff` skill under its real name.
- `issue-reporter`, `mindwtr`, `wp-plugin-update-check`, `wp-plugin-search` — custom-authored skills, no upstream CLI source; this repo is simply their home. `wp-plugin-search` was renamed from `wp-search-plugins` 2026-08-10 (folder, junction, and frontmatter `name` all updated together).
- `webclaw` — installed via `npx skills add https://github.com/0xmassi/webclaw-skill --skill webclaw`.

### npx skills CLI on a fresh device: what actually needs doing

The `skills` CLI (`npx skills add ...`) is itself the thing that created `~/.agents/skills/`
and the junctions from each agent's own skills dir (Claude Code, etc.) into it — the
`lastSelectedAgents` list in `~/.agents/.skill-lock.json` confirms this. That lock file
is **not** tracked here (it's local install-state, not something to sync), so on a new
device:

- For skills tracked in this repo (the list above): `chezmoi apply` puts the real file
  content in place, and on Linux `.chezmoiscripts/run_onchange_after_40-skill-symlinks.sh.tmpl`
  now creates the per-agent link automatically (`ln -s ~/.agents/skills/<name>
  ~/.claude/skills/<name>`, idempotent, reruns whenever a skill is added/removed thanks to
  a content hash of `dot_agents/skills` embedded in the script). opencode needs no link at
  all — it reads `~/.agents/skills/<name>/SKILL.md` natively as a global fallback location.
  hermes is still a manual TODO in that script, pending its install-method rework. On
  Windows this is still manual: a junction (`New-Item -ItemType Junction ...`, see old
  `dotfiles.md`) — out of scope for that script since Windows is a single known device.
- Skills **not** tracked here no longer apply — the CLI-only ones (`find-skills`,
  `skill-creator`, `frontend-design`, `wp-plugin-development`, `wp-rest-api`,
  `wp-wpcli-and-ops`) were removed from the repo and the machines; see the section below.

### Not tracked here

If you `npx skills add` something new later that you don't want tracked here,
that's fine — it'll sit in `~/.agents/skills` untouched by chezmoi; just remember dangling
symlinks won't self-clean if you later remove it by hand instead of via the CLI.

Dated write-ups of how each of these was resolved (nvim, yazi/fd, herdr paths, herdr
plugins, herdr agent integrations, syncthing exclusion) now live in `learnings.md`, kept
separate so this README stays a current-state reference rather than a change log.

## Plugin-manager tools: apply this pattern going forward

Yazi and herdr both now get the same two-piece treatment for their plugins: a
`desired-plugins.txt` (or equivalent) that chezmoi tracks and an onchange script that
installs anything missing on `chezmoi apply`, plus a `scripts/sync-*.sh` helper that
regenerates the desired file from whatever the tool's own plugin manager reports installed
locally. Chezmoi never tracks the plugin code itself — that stays owned by the tool's own
package manager (`ya`, `herdr plugin`, whatever) and its own GitHub source.

Any other tool here that grows a similar plugin/extension ecosystem with its own
manager (nvim's lazy.nvim, opencode plugins, etc.) should get the same treatment where
feasible, rather than a one-off or a fully manual note: tracked desired-list + onchange
install script + sync helper. Worth checking for this whenever a new plugin-capable tool
gets added to this repo.

## Not tracked at all (still Windows-only, out of scope for this pass)

7-Zip PATH entry, Cygwin — this-machine-specific tooling / a one-line PATH fix, not really
"config" to sync — see `dotfiles.md` in the Obsidian vault for the full historical list
until it's fully folded into this repo.

## VPS setup (run these yourself — no SSH automation)

1. Install chezmoi: `sh -c "$(curl -fsLS get.chezmoi.io)"`
2. `chezmoi init git@github.com:gursuj/dotfiles.git` then `chezmoi diff` to review before
   `chezmoi apply`.

See `TODO.md` for open items.
