# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io). Source repo lives at
`~/.local/share/chezmoi` on every machine — that's chezmoi's own built-in default path,
not a custom choice, so it's the same on Windows and Linux without any config.

This repo is local-only for now (no remote set). A remote will be added directly by the
repo owner (not via the `gh` CLI default account on this machine).

## Currently tracked

| What | Source path | Notes |
| --- | --- | --- |
| Custom scripts | `scripts/` | `~/scripts` |
| Claude Code settings | `dot_claude/settings.json.tmpl` | Templated — the PowerShell notification/herdr hooks only render on Windows (`{{ if eq .chezmoi.os "windows" }}`), since those `.ps1` scripts don't exist on Linux. `CLAUDE.md` is deliberately **not** tracked here — it can contain client/work-sensitive content. |
| Neovim config | `dot_config/nvim/` | `init.lua`, `after/`, `readme.md`. Previously its own repo (`gursuj/nvim-temp`, created only as a temporary sync mechanism) — folded in here instead, so that repo can be retired. Targets `~/.config/nvim` on both OSes — see below. |
| PowerShell profile | `readonly_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | Windows-only content (PowerShell doesn't run on the VPS) — tracked as-is, no templating needed. `readonly_` prefix just reflects the live folder's read-only attribute, not a chezmoi behaviour choice. |
| Yazi config | `dot_config/yazi/` | `yazi.toml`, `keymap.toml`, `package.toml`. Targets `~/.config/yazi` on both OSes — see below. The `ya pkg`-installed `plugins/` dir is deliberately **not** tracked (reproducible from `package.toml`, same reasoning as not tracking nvim's data dir). |
| fd ignore patterns | `dot_config/fd/ignore` | Targets `~/.config/fd/ignore` on both OSes — see below. |
| OpenCode config | `dot_config/opencode/opencode.jsonc` | The `mcp.mindwtr` entry (pointed at a Windows-only `D:\git-clone\Mindwtr\...` path) was removed rather than templated — Mindwtr moved to REST-API-only, so a local MCP server entry was stale, not just non-portable. |
| Herdr config | `AppData/Roaming/herdr/config.toml.tmpl` | Templated — `default_shell` and the `prefix+n` custom keybinding (which shells out to a Windows-only PowerShell script depending on the `cc` function in the tracked PowerShell profile) are both Windows-only, omitted entirely on Linux rather than guessed at. Everything else (keys, theme, ui, experimental) is portable as-is. **Open question:** still targets the literal Windows path (`AppData/Roaming/herdr`) — herdr's Linux config location isn't confirmed, so this isn't unified into one cross-platform path yet the way nvim/yazi/fd are. |
| Agent skills (8 of them) | `dot_agents/skills/<name>/` | See below. |

### Agent skills tracked

Skills live in `~/.agents/skills/<name>/`, and each agent (Claude Code, opencode, etc.)
gets a Windows junction pointing at that folder — see the "Agent skills" section of the
old `dotfiles.md` note for the junction-creation command. Tracking the real folder here
means editing on any device and running `chezmoi update` on the others picks up the change.

- `agent-browser` — originally installed via `npx skills add vercel-labs/agent-browser --skill agent-browser`. Re-run that command on a fresh machine if you ever want the CLI's own update flow instead of relying on this repo's copy.
- `herdr` — not confidently installed via the skills CLI (may have just been cloned by hand); treat this repo's copy as the actual source of truth, not the CLI's lock file.
- `dotfiles` — **being phased out.** This skill's job (tracking scattered config locations in `dotfiles.md`) is superseded by this very README now that a real repo exists. Kept for now so "edit my dotfiles" still triggers something useful in Claude Code; retarget or retire once `dotfiles.md` is fully migrated.
- `handoff-generic` — deliberately renamed from the upstream skill name `handoff` (source: `mattpocock/skills`) because it collided with a different `handoff` skill installed via a Claude Code plugin. If `npx skills update` output ever looks confused about this skill, that's why — the plugin conflict is Claude-Code-specific, so re-evaluate if the plugin isn't installed on a given machine.
- `issue-reporter`, `mindwtr`, `wp-plugin-update-check` — custom-authored skills, no upstream CLI source; this repo is simply their home.
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
