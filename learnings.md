# Learnings

Dated log of resolved issues, corrections, and decisions made while building out this
dotfiles repo. Kept separate from `README.md` so the README stays a clean current-state
reference and this file stays the historical "why" record. Referenced from `AGENTS.md` and
`README.md` so any agent working in this repo picks it up.

## Syncthing config: deliberately not tracked (2026-08-17)

`.config/syncthing/` (`config.xml`, `cert.pem`, `key.pem`, `https-cert.pem`, `https-key.pem`,
`csrftokens.txt`, `index-v0.14.0.db/`) is not tracked here and should never be added. It
contains TLS private keys, session tokens, and a local leveldb index — secrets and per-device
state, not shareable config. Syncthing regenerates all of this itself on first run per device;
there's nothing worth templating.

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

- **Yazi** has its own override, `YAZI_CONFIG_HOME` — set to `~/.config/yazi` (Windows user
  env var), one target path both OSes. `.chezmoiscripts/run_onchange_after_10-yazi-pkg-install.sh.tmpl`
  reads `dot_config/yazi/desired-plugins.txt` (one `owner/repo` per line), runs `ya pkg add`
  for any not already in local `package.toml`, then `ya pkg install` to catch anything not
  yet fetched. Trigger hash is over `desired-plugins.txt`'s content, so it only reruns when
  that file changes. Needs `.chezmoi.toml.tmpl`'s `[interpreters.sh]` mapping to run on
  Windows at all — chezmoi doesn't auto-detect shebangs there.
  **To add a plugin:** `ya pkg add owner/repo` locally, then `scripts/sync-yazi-plugins.sh`
  — mirrors `package.toml`'s `use = "..."` lines into `desired-plugins.txt`, no hand-typing.
  Review the diff, commit. Still one manual step per machine — no live sync between
  devices, only committed source, so something has to carry "installed here" to "installed
  everywhere."
  **`package.toml` not chezmoi-managed** (`.chezmoiignore`, 2026-08-13) — `ya` rewrites its
  `hash` field per machine on every run, which fought chezmoi's own "changed since I last
  wrote it" check (hit repeatedly on the VPS). Also can't serve as the sync source anyway:
  it only reflects one machine's local installs. `ya` owns it fully, like `plugins/`. If
  `ya` ever aborts with "you have modified the contents of `<plugin>`" — its own safety
  check, unrelated to chezmoi: delete `~/.config/yazi/plugins/<plugin>` and rerun.
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
it correctly (nvim, etc.) — just don't assume herdr is one of them.

## Herdr plugins: same pattern as yazi (2026-08-13)

`herdr-auto-namer` was forked to `gursuj/herdr-auto-namer` on GitHub (own copy, actively
developed at `D:\code\gursuj\herdr-auto-namer` on this machine) instead of running the
upstream `kakigakki/herdr-auto-namer`. herdr has its own plugin manager
(`herdr plugin install owner/repo`, `herdr plugin link <path>`, `herdr plugin list`) — same
shape as yazi's `ya pkg add`, so it gets the same treatment: chezmoi doesn't track the
plugin's code (that lives in its own GitHub repo, `herdr plugin install` fetches it), only a
`desired-plugins.txt` declaration, same format as yazi's.

`run_onchange_after_20-herdr-plugin-install.sh.tmpl` reads
`dot_config/herdr/desired-plugins.txt` and runs `herdr plugin install owner/repo -y` for
each line. Plugin ids (from the plugin's own `herdr-plugin.toml`, e.g. `auto-namer`) don't
necessarily match the repo name, so there's no reliable way to pre-check `herdr plugin
list` by name before installing — instead the script just attempts the install and treats
`"already linked"` / `"already installed"` in the error text as an idempotent no-op rather
than a failure. That's what makes it safe on **this** dev machine too: `auto-namer` is
`herdr plugin link`-ed straight to its `D:\code\gursuj\herdr-auto-namer` clone for active
development, so the install attempt fails with "already linked" and the script swallows
that rather than aborting — it won't clobber the local link with a fetched copy. Other
machines have no local link, so the same command actually installs from GitHub there.

**To add another plugin:** `herdr plugin install owner/repo` locally, then
`scripts/sync-herdr-plugins.sh` — mirrors every `source.kind == "github"` entry from
`herdr plugin list --json` into `desired-plugins.txt` (skips `local`-linked entries on
purpose, e.g. this machine's own dev link). Review the diff, commit.

Guard rail: the sync script refuses to write an empty file over a populated one. That
matters here specifically because *this* dev machine has `auto-namer` linked, not
installed — if it found zero github-sourced plugins and wrote anyway, it'd erase the
declaration every other machine relies on. Run the sync script from a machine where the
plugin is actually github-installed.

**To pick up new commits on `gursuj/herdr-auto-namer`** on a machine that installed it via
GitHub (not linked locally): `herdr plugin uninstall auto-namer` then re-run
`chezmoi apply` (or `herdr plugin install gursuj/herdr-auto-namer -y` directly) — the
onchange script only installs what's missing, it doesn't update what's already there.

## ccc (Claude Code sandbox launcher): one var, per-shell scripts (2026-08-23)

Ported pwsh's `ccc` (run Claude Code in `$PWD` or a scratch sandbox, `-y`/`-n` skip
prompt) to zsh as a function in `dot_zshrc.tmpl`. Converted the pwsh profile to
`.tmpl` too.

Can't share one literal script across pwsh/zsh — different languages, no function
import across shells (pwsh can only shell out to bash as a subprocess, e.g.
`Invoke-CygwinBash` — doesn't share pwsh's own source with it). What's shared:
the sandbox path, via a new `sandbox_dir` chezmoi data var in `.chezmoi.toml.tmpl`
(same per-OS pattern as `machine_kind`). Both scripts read `{{ .sandbox_dir }}`;
only the path is defined once, logic stays duplicated per shell.

New `[data]` vars need `chezmoi init` (regenerates `~/.config/chezmoi/chezmoi.toml`,
safe, doesn't re-prompt cached `promptChoiceOnce` answers) before `chezmoi apply`
picks them up.

## Herdr's own agent integrations: not tracked (2026-08-18)

`herdr integration install claude` and `herdr integration install opencode` each generate
files stamped `# installed by herdr / managed by herdr; reinstalling or updating the
integration overwrites this file` — same "tool owns this, chezmoi shouldn't duplicate it"
category as the yazi/herdr plugin pattern, just for herdr's own agent-state reporting
instead of a third-party plugin:

- `C:\Users\User\.claude\hooks\herdr-agent-state.ps1` (Claude Code)
- `C:\Users\User\.config\opencode\plugins\herdr-agent-state.js` and
  `C:\Users\User\.config\opencode\herdr-tui-session.js` (OpenCode)

On a fresh machine, re-run `herdr integration install claude` / `herdr integration install
opencode` instead of restoring these from a backup — that also re-wires whatever hook/plugin
registration the target tool's own config needs (already tracked: the Claude Code
`SessionStart` hook entry in `dot_claude/settings.json.tmpl`, and OpenCode's `tui.jsonc`).
