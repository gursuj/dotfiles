# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io). Source repo lives at
`~/.local/share/chezmoi` on every machine — that's chezmoi's own built-in default path,
not a custom choice, so it's the same on Windows and Linux without any config.

Remote: `git@github.com:gursuj/dotfiles.git`.

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
  this path as the exception, not the habit.

Other useful commands: `chezmoi diff` (preview before apply — note it can show CRLF/LF
noise as spurious diff lines on Windows-tracked files, not real content changes; check
before assuming something changed), `chezmoi status` (quick out-of-sync check), `chezmoi
merge` / `merge-all` (three-way merge when both source and live have drifted — safer than
`re-add` for that case).

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
| Agent pointer files | `AGENTS.md`, `CLAUDE.md`, `learnings.md`, `TODO.md` | Repo root, not chezmoi-templated. `AGENTS.md` (opencode's native file, also honoured by Claude Code in setups that support it) and `CLAUDE.md` (thin pointer, see below) both point at `learnings.md` — the dated log of resolved issues/corrections — so any agent working in this repo picks it up regardless of which one it reads by default. `TODO.md` holds open items, kept out of this README. |
| Claude Code settings | `dot_claude/settings.json.tmpl` | Templated — the PowerShell notification/herdr hooks only render on Windows (`{{ if eq .chezmoi.os "windows" }}`), since those `.ps1` scripts don't exist on Linux. The real personal `CLAUDE.md` (full org/user instructions) is deliberately **not** tracked here — it can carry client/work-sensitive content. The tracked root `CLAUDE.md` is just a thin pointer to `AGENTS.md`, not the real one. |
| Claude Code terse output style | `dot_claude/output-styles/terse.md` | `outputStyle: Terse` in settings.json above makes this the global default for every session. Has an explicit exception for drafting messages meant for someone else (emails, ClickUp updates, LinkedIn posts, client-facing docs) — those use normal writing-voice guidance instead, and for code comments specifically it now applies the same fragment/abbreviation rules as prose (previously exempted all code content wholesale). |
| Claude Code keybindings | `dot_claude/keybindings.json` | Custom vim-style h/j/k/l rebinds across Tabs/Confirmation/Footer/Attachments/DiffDialog/ModelPicker contexts. Plain file, no secrets. |
| WP-CLI / Local by Flywheel notes | `dot_claude/wordpress-preferences.md` | Contains local dev site paths and a per-site env-activation example (Local run-ID paths) — no credentials or secrets. Site name redacted to a placeholder before making this repo public. |
| Neovim config | `dot_config/nvim/` | `init.lua`, `after/`, `readme.md`. Previously its own repo (`gursuj/nvim-temp`, created only as a temporary sync mechanism) — folded in here instead, so that repo can be retired. Targets `~/.config/nvim` on both OSes — see `learnings.md`. |
| PowerShell profile | `readonly_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Windows-only content (PowerShell doesn't run on the VPS) — tracked as-is, no templating needed. `readonly_` prefix just reflects the live folder's read-only attribute, not a chezmoi behaviour choice. |
| Yazi config | `dot_config/yazi/` | `yazi.toml`, `keymap.toml`, `desired-plugins.txt`. Targets `~/.config/yazi` both OSes — see `learnings.md`. `plugins/` dir and `package.toml` not tracked (see `learnings.md`); `desired-plugins.txt` is the real plugin declaration, generated by `scripts/sync-yazi-plugins.sh`. |
| fd ignore patterns | `dot_config/fd/ignore` | Targets `~/.config/fd/ignore` on both OSes — see `learnings.md`. |
| OpenCode config | `dot_config/opencode/opencode.jsonc` | The `mcp.mindwtr` entry (pointed at a Windows-only `D:\git-clone\Mindwtr\...` path) was removed rather than templated — Mindwtr moved to REST-API-only, so a local MCP server entry was stale, not just non-portable. |
| OpenCode TUI plugin config | `dot_config/opencode/tui.jsonc` | Just `{ "plugin": ["./herdr-tui-session.js"] }` — small, stable wiring, not itself herdr-managed generated code (see `learnings.md`), so tracked like `settings.json` is for Claude Code. |
| Herdr config | `.chezmoitemplates/herdr-config.toml.tmpl` | Shared content, included by two thin per-OS stub files (`AppData/Roaming/herdr/config.toml.tmpl` for Windows, `dot_config/herdr/config.toml.tmpl` for Linux/Mac — confirmed from herdr's own docs) — see `learnings.md`. `default_shell` is left unset entirely now (see `learnings.md`); the `prefix+n` custom keybinding, which shells out to a Windows-only PowerShell script depending on the `cc` function in the tracked PowerShell profile, is still gated to Windows only. |
| Herdr plugins | `dot_config/herdr/desired-plugins.txt` | One `owner/repo` per line, same shape as yazi's file above. `run_onchange_after_20-herdr-plugin-install.sh.tmpl` runs `herdr plugin install` for anything not already present — see `learnings.md`. |
| Kanata config | `dot_config/kanata/kanata.kbd` | Targets `~/.config/kanata/kanata.kbd`, plain file. Caps = layer key: tap Esc, hold = arrow layer on WASD. Replaces PowerToys KM, which was intermittently dropping the intercept on a cheap membrane keyboard (confirmed not rollover/ghosting first, via NKRO tester). Runs via elevated Task Scheduler (`AtLogOn`, 15s delay — Kanata fails silently if started too early) since Startup folder can't grant admin rights. |
| Agent skills (9 of them) | `dot_agents/skills/<name>/` | See below. |
| WTQ (quake-terminal launcher) config | `AppData/Roaming/wtq/wtq.jsonc` | Windows-only tool, plain file, no templating needed. `wtq.schema.json` in the same live folder is shipped by the app itself for schema validation, not user-authored — not tracked. |
| Windows Terminal settings | `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Profiles, keybindings, color schemes, the `_quake` globalSummon action WTQ hotkeys into. The `8wekyb3d8bbwe` publisher-hash segment is Microsoft's own fixed ID for this package, not machine-specific — same path on any Windows install of the Store version. `state.json` in the same folder (window position, last-active tab) is runtime state, not tracked. |
| SaneBreak config | `AppData/Roaming/SaneBreak.ini` | Break-reminder timing settings (interval, flash/confirm durations, bell sounds, postpone ratios). There's also a byte-identical copy at `AppData/Roaming/SaneBreak/SaneBreak.ini` plus a `sane-break.db` (break history) in that same subfolder — only the top-level `.ini` is tracked; the nested copy and the db are the app's own runtime data. |

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
  content in place, but does **not** create the per-agent link. On Windows that's a
  junction (`New-Item -ItemType Junction ...`, see old `dotfiles.md`); on Linux it's a
  plain `ln -s ~/.agents/skills/<name> ~/.claude/skills/<name>` — no privilege issue there
  at all, junctions were only ever a Windows problem. This isn't automated yet — do it by
  hand per skill after the first `chezmoi apply` on a new machine, or automate later with
  a chezmoi `run_once_` script once there's a second real device to test it against.
- For skills **not** tracked here (`find-skills`, `skill-creator`, `frontend-design`,
  `wp-plugin-development`, `wp-rest-api`, `wp-wpcli-and-ops`): just run
  `npx skills add <source> --skill <name>` again — the CLI handles both download and
  agent-linking itself, using real symlinks on Linux (no junction problem to work around).

### Deliberately NOT tracked here (npx-managed, no need to duplicate)

`find-skills`, `skill-creator`, `frontend-design`, `wp-plugin-development`, `wp-rest-api`,
`wp-wpcli-and-ops` — all installed via `npx skills add ...` and not edited by hand, so the
CLI's own install/update flow is enough. No point duplicating them here.

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
