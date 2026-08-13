# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io). Source repo lives at
`~/.local/share/chezmoi` on every machine — that's chezmoi's own built-in default path,
not a custom choice, so it's the same on Windows and Linux without any config.

This repo is local-only for now (no remote set). A remote will be added directly by the
repo owner (not via the `gh` CLI default account on this machine).

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
| Claude Code settings | `dot_claude/settings.json.tmpl` | Templated — the PowerShell notification/herdr hooks only render on Windows (`{{ if eq .chezmoi.os "windows" }}`), since those `.ps1` scripts don't exist on Linux. `CLAUDE.md` is deliberately **not** tracked here — it can contain client/work-sensitive content. |
| Claude Code terse output style | `dot_claude/output-styles/terse.md` | `outputStyle: Terse` in settings.json above makes this the global default for every session. Has an explicit exception for drafting messages meant for someone else (emails, ClickUp updates, LinkedIn posts, client-facing docs) — those use normal writing-voice guidance instead, and for code comments specifically it now applies the same fragment/abbreviation rules as prose (previously exempted all code content wholesale). |
| Neovim config | `dot_config/nvim/` | `init.lua`, `after/`, `readme.md`. Previously its own repo (`gursuj/nvim-temp`, created only as a temporary sync mechanism) — folded in here instead, so that repo can be retired. Targets `~/.config/nvim` on both OSes — see below. |
| PowerShell profile | `readonly_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Windows-only content (PowerShell doesn't run on the VPS) — tracked as-is, no templating needed. `readonly_` prefix just reflects the live folder's read-only attribute, not a chezmoi behaviour choice. |
| Yazi config | `dot_config/yazi/` | `yazi.toml`, `keymap.toml`, `package.toml`. Targets `~/.config/yazi` on both OSes — see below. The `ya pkg`-installed `plugins/` dir is deliberately **not** tracked (reproducible from `package.toml`, same reasoning as not tracking nvim's data dir). |
| fd ignore patterns | `dot_config/fd/ignore` | Targets `~/.config/fd/ignore` on both OSes — see below. |
| OpenCode config | `dot_config/opencode/opencode.jsonc` | The `mcp.mindwtr` entry (pointed at a Windows-only `D:\git-clone\Mindwtr\...` path) was removed rather than templated — Mindwtr moved to REST-API-only, so a local MCP server entry was stale, not just non-portable. |
| Herdr config | `.chezmoitemplates/herdr-config.toml.tmpl` | Shared content, included by two thin per-OS stub files (`AppData/Roaming/herdr/config.toml.tmpl` for Windows, `dot_config/herdr/config.toml.tmpl` for Linux/Mac — confirmed from herdr's own docs) — see below. `default_shell` is left unset entirely now (see below); the `prefix+n` custom keybinding, which shells out to a Windows-only PowerShell script depending on the `cc` function in the tracked PowerShell profile, is still gated to Windows only. |
| Kanata config | `dot_config/kanata/kanata.kbd` | Targets `~/.config/kanata/kanata.kbd`, plain file (no templating needed — cross-platform as-is). Caps Lock is a layer key: tap = Esc, hold = arrow-key layer on WASD, replacing the PowerToys Keyboard Manager remap for this (PowerToys KM's chorded-hold-modifier remaps were intermittently dropping the intercept on a cheap membrane keyboard — confirmed not a rollover/ghosting issue via NKRO tester first). Runs via an elevated Task Scheduler entry (`AtLogOn`, 15s delay — Kanata is known to fail silently if started too early at boot) rather than the Startup folder, since Startup can't grant admin rights. |
| Agent skills (9 of them) | `dot_agents/skills/<name>/` | See below. |

### Agent skills tracked

Skills live in `~/.agents/skills/<name>/`, and each agent (Claude Code, opencode, etc.)
gets a Windows junction pointing at that folder — see the "Agent skills" section of the
old `dotfiles.md` note for the junction-creation command. Tracking the real folder here
means editing on any device and running `chezmoi update` on the others picks up the change.

- `agent-browser` — originally installed via `npx skills add vercel-labs/agent-browser --skill agent-browser`. Re-run that command on a fresh machine if you ever want the CLI's own update flow instead of relying on this repo's copy.
- `herdr` — not confidently installed via the skills CLI (may have just been cloned by hand); treat this repo's copy as the actual source of truth, not the CLI's lock file.
- `dotfiles` — **being phased out.** This skill's job (tracking scattered config locations in `dotfiles.md`) is superseded by this very README now that a real repo exists. Kept for now so "edit my dotfiles" still triggers something useful in Claude Code; retarget or retire once `dotfiles.md` is fully migrated.
- `handoff-generic` — deliberately renamed from the upstream skill name `handoff` (source: `mattpocock/skills`) because it collided with a different `handoff` skill installed via a Claude Code plugin. If `npx skills update` output ever looks confused about this skill, that's why — the plugin conflict is Claude-Code-specific, so re-evaluate if the plugin isn't installed on a given machine.
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

## Nvim cross-platform path (resolved 2026-08-10)

Windows Neovim looks for its config at `~/AppData/Local/nvim` by default; Linux looks at
`~/.config/nvim`. Rather than track two target paths for identical content, set
`XDG_CONFIG_HOME` as a Windows user env var (`setx XDG_CONFIG_HOME "%USERPROFILE%\.config"`,
or via `[Environment]::SetEnvironmentVariable`) and moved the live config from
`AppData\Local\nvim` to `.config\nvim` — Neovim checks XDG vars first regardless of
platform, so one target path now works on both OSes.

Deliberately **not** touched: `XDG_DATA_HOME`/`XDG_STATE_HOME`. Leaving those unset means
Neovim's data dir (plugins, undo, lazy state) keeps resolving to the correct per-OS default
on its own (`AppData\Local\nvim-data` on Windows, `~/.local/share/nvim` on Linux) — no data
migration needed, and no risk to existing undo history or installed plugins.

New terminals (and Neovim itself) need to be restarted to pick up the env var — same
"existing terminals won't see it" caveat as other PATH/env changes in `dotfiles.md`.

## Yazi and fd cross-platform paths (resolved 2026-08-10)

Same shape of problem as nvim, different fix per tool since neither honours
`XDG_CONFIG_HOME` on Windows the way Neovim does:

- **Yazi** has its own dedicated override, `YAZI_CONFIG_HOME` — set that (Windows user env
  var) to `~/.config/yazi` and moved the live config there. One target path on both OSes.
  `.chezmoiscripts/run_onchange_after_10-yazi-pkg-install.sh.tmpl` runs `ya pkg install`
  whenever `package.toml`'s content changes (including the first apply on a new machine),
  so declared plugins (currently `Ape/smart-enter`) actually get fetched instead of just
  sitting declared-but-uninstalled. Needs `.chezmoi.toml.tmpl`'s `[interpreters.sh]`
  mapping to run at all on Windows — chezmoi doesn't auto-detect shebangs there.
- **fd** has no override env var at all for its ignore-file lookup. Instead of duplicating
  the ignore file per-OS target, moved it to `~/.config/fd/ignore` and updated the
  PowerShell profile's `$env:FZF_DEFAULT_COMMAND` to pass `--ignore-file` explicitly,
  pointing fd at that one canonical path rather than relying on its OS-specific default.
  The equivalent Linux shell rc (bashrc/zshrc, not yet tracked here) needs the same
  `--ignore-file` flag added when it's set up — the ignore file itself is already in place
  and ready for that.

## Herdr: same content, two target paths (resolved 2026-08-10)

**Correction (2026-08-11):** originally assumed (from herdr's docs) that the config path
differs per OS — `~/.config/herdr/config.toml` on Linux/Mac, `%APPDATA%\herdr\config.toml`
on Windows — and tracked two separate stub files with a `.chezmoiignore` conditional to
pick the right one. That was wrong: herdr's own `--help` output on this machine states its
actual config path as `C:\Users\User\.config\herdr\config.toml`, confirmed by which file
was actually being written to during a live session (the `.config` copy's `session.json`
kept updating; the `AppData\Roaming` copy had gone stale). So `.config/herdr` is correct on
**both** OSes here — no per-OS split needed. Consolidated to a single
`dot_config/herdr/config.toml.tmpl` stub (still just `{{ template "herdr-config.toml.tmpl" . }}`,
content lives in the shared `.chezmoitemplates/herdr-config.toml.tmpl` partial), removed the
`AppData/Roaming/herdr/config.toml.tmpl` stub, and `.chezmoiignore` now unconditionally
ignores `AppData/Roaming/herdr/config.toml` rather than branching on OS.

An older, now-untracked copy of herdr's config/session files may still exist at
`AppData\Roaming\herdr\` on this machine from before this was sorted out — safe to archive
or delete once you've confirmed `.config\herdr` has everything you need (check
`session.json` there for your current workspace layout first).

`default_shell` is hardcoded to pwsh 7 on Windows, left unset (falls back to `$SHELL`) on
Linux/Mac — gated by a `{{ if eq .chezmoi.os "windows" }}` block inside the shared template.

**Correction (2026-08-11):** a prior version of this note claimed herdr's docs say "$SHELL,
then `/bin/sh` on Unix and PowerShell on Windows," and that setting `$SHELL` as a Windows
user env var would make herdr resolve pwsh 7 the same way it does on Unix. That turned out
to be wrong — checked herdr's actual config reference (`herdr.dev/docs/config-reference/`)
and it only documents "`$SHELL`, then `/bin/sh`," with no Windows-specific fallback at all.
Confirmed empirically too: `$SHELL` was set as a persistent user env var, the machine was
fully rebooted, and herdr still fell back to Windows PowerShell 5, not pwsh 7. Herdr's
Windows support is still marked beta on its own site — likely `$SHELL` just isn't read
there yet. Hardcoding `default_shell` per-OS in config is the only thing that's actually
been shown to work, so that's what's tracked now, not an env var.

`$SHELL` is still worth having set as a Windows user env var for other tools that do honour
it correctly (nvim, etc. — see below) — just don't assume herdr is one of them.

## Not tracked at all (still Windows-only, out of scope for this pass)

7-Zip PATH entry, Cygwin — this-machine-specific tooling / a one-line PATH fix, not really
"config" to sync — see `dotfiles.md` in the Obsidian vault for the full historical list
until it's fully folded into this repo.

## VPS setup (run these yourself — no SSH automation)

1. Install chezmoi: `sh -c "$(curl -fsLS get.chezmoi.io)"`
2. Once a remote is set on this repo: `chezmoi init <remote-url>` then `chezmoi diff` to
   review before `chezmoi apply`.

## TODOs
- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
- on vps, make hermes use webclaw instead of firecralwl(?) though check comparisons first
- include browser config, extensions configs too?
- vet nvim plugins for security, if really necessary
    - need to slowly build nvim config. just ask AI to help
- firefox profile configs for performance, css, sideberry?
- replace bash w/ zsh on vps.
    - compare if anything useful from bashrc should be inherited
    - will prob need separate zsh configs for laptop and vps?
- find some way to automate npx skills installation. check notes above regarding this
- fd ignorefile isn't being used in linux currently. should fix
