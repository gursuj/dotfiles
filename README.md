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
| Agent skills (7 of them) | `dot_agents/skills/<name>/` | See below. |

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

## Not tracked at all (still Windows-only, per `dotfiles.md`)

PowerShell profile, Yazi, OpenCode config, fzf/fd ignore patterns, Herdr config,
7-Zip PATH entry, Cygwin. These either don't apply on the VPS or weren't in scope for this
pass — see `dotfiles.md` in the Obsidian vault for the full historical list until it's
fully folded into this repo.

## VPS setup (run these yourself — no SSH automation)

1. Install chezmoi: `sh -c "$(curl -fsLS get.chezmoi.io)"`
2. Once a remote is set on this repo: `chezmoi init <remote-url>` then `chezmoi diff` to
   review before `chezmoi apply`.

## TODOs
- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
- on vps, make hermes use webclaw instead of firecralwl(?) though check comparisons first
