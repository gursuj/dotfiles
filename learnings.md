# Learnings

Dated log of resolved issues, corrections, and decisions made while building out this
dotfiles repo. Kept separate from `README.md` so the README stays a clean current-state
reference and this file stays the historical "why" record. Referenced from `AGENTS.md` and
`README.md` so any agent working in this repo picks it up.

## Laptop power tuning: governor mattered, TLP vs auto-cpufreq didn't (2026-10-29)

Machine: Lenovo IdeaPad 81W0, Ryzen 3 3250U (2C/4T), `acpi-cpufreq` driver (no `amd_pstate`
on Zen+), kernel 7.2.11. Bench: `battbench <label> 5` (`~/.local/bin/battbench`, arch-only,
tracked here): 90 s warmup, 5 min idle, then 4 jobs x 12 GB sha256. Brightness fixed at
20982/65535, AC unplugged, same open apps, one run per config (run-to-run noise not measured).

| config | idle | task | task power | clock under load | temp under load | energy/task |
|---|---|---|---|---|---|---|
| auto-cpufreq default (`powersave`, boost 0) | 4.81 W (~4.7 h) | 52.7 s | 6.92 W | 1381 MHz | 43 C | 365 J |
| auto-cpufreq, `schedutil` on battery | 4.88 W (~4.6 h) | 26.7 s | 10.82 W | 2784 MHz | 62 C | 289 J |
| TLP, `schedutil` on battery, boost on | 4.84 W (~4.6 h) | 26.8 s | 10.51 W | 2714 MHz | 63 C | 282 J |

- **Cause of the browser choke:** on `acpi-cpufreq`, the `powersave` governor just pins the
  clock low (~1.4 GHz even at full load). auto-cpufreq's default battery profile uses it.
  Switching to `schedutil` halved task time and cut energy per task by ~21%, idle unchanged.
- **TLP vs auto-cpufreq:** same task time, idle within 0.04 W, energy 2.4% apart. Not
  distinguishable from this data, and no measurable gain from TLP's device tuning (idle is
  mostly the screen, ~4.8 W). Under load it's all governor + boost, whichever tool sets it.
- Runtime estimates use `energy_full` (22.4 Wh), the pack is at 63% of design (35.3 Wh).
  `cycle_count` reads 4274, which is bogus firmware data, trust capacity instead.
- Charge limit: IdeaPad only has `conservation_mode` (on/off, ~55-60% cap) via
  `/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode`. No percentage threshold
  file. TLP's `recalibrate` is ThinkPad-only. Skipped both.
- TLP defaults on this machine: doesn't disable bluetooth or wifi; wifi power save and USB
  autosuspend on (btusb not excluded), audio/PCIe runtime PM on.
  `DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth"` would turn bluetooth off when unused.
- `/etc/auto-cpufreq.conf` and `/etc/tlp.d/10-bench.conf` are outside `$HOME`, not tracked.
  auto-cpufreq conf used: `[battery] governor = schedutil, turbo = auto` and
  `[charger] governor = performance, turbo = auto`. The TLP bench conf mirrored it
  (`CPU_SCALING_GOVERNOR_ON_BAT=schedutil`, `_ON_AC=performance`, `CPU_BOOST_ON_*=1`).
- **Reverting to auto-cpufreq** (TLP was left running after the bench):
  1. `sudo systemctl disable --now tlp`
  2. `sudo systemctl unmask systemd-rfkill.service systemd-rfkill.socket`
  3. `sudo rm /etc/tlp.d/10-bench.conf` (or `sudo pacman -Rns tlp` to drop it entirely)
  4. `sudo systemctl enable --now auto-cpufreq`
  5. Check on battery: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` says
     `schedutil`, and `systemctl is-active tlp auto-cpufreq` says `inactive` then `active`.
  Never run both, they fight over the governor.
- **For the ThinkPad:** battbench needs edits first: temp reads AMD `Tctl` (Intel is
  `Package id 0`); boost path differs on `intel_pstate` (`no_turbo`, inverted); also log
  `energy_performance_preference` and `/sys/firmware/acpi/platform_profile`; confirm `BAT0`
  has `energy_*` + `power_now`. First run there = stock profile, before installing TLP or
  auto-cpufreq. Tracked as a Mindwtr task, not here.

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

`run_after_20-herdr-plugin-install.sh.tmpl` reads
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

**To pick up new commits on `gursuj/herdr-auto-namer`** (or any github plugin): nothing.
The script is `run_after_` (every apply, not onchange) and ends with `herdr plugin update -y`
(herdr PR #4245, merged 2026-10-05). Update skips linked and unchanged plugins, so the dev
machine's local link is safe. Failure is non-fatal. Needs a herdr build with `plugin update`.

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

## Firefox/Waterfox Windows support added; `extensions.activeThemeID` removed (2026-08-31)

`run_onchange_after_60-browser-user-js-sync.py.tmpl` now runs on Windows too (was
arch-only): `%APPDATA%\Mozilla\Firefox\` / `%APPDATA%\Waterfox\` profile dirs, a
`[interpreters.py]` entry in `.chezmoi.toml.tmpl`, and a copy fallback when `os.symlink`
fails without admin/Developer Mode. Confirmed working on this machine — Waterfox landed
as a copy (Dev Mode not enabled here by choice), same script handles re-copying on future
hash changes automatically. `scripts/sync-search-engines.py` got matching Windows
path/process detection (`tasklist` instead of `pgrep`), but stays manual-only by design —
never auto-run by chezmoi apply, since the browser rewrites that file on exit and would
clobber a merge mid-session.

Also removed `user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org")`
from `firefox-preferences.js.tmpl` — confirmed on a real profile it doesn't switch the
theme; browser chrome stayed on the OS "System" setting. Built-in Firefox themes are
toggled through the Addon Manager's own state (`extensions.json` / `addonStartup.json.lz4`),
not read from `user.js` at startup the way a normal pref is, so writing it there was a
silent no-op. If dark mode is wanted again, it needs picking manually in `about:addons` →
Themes — there's no user.js pref that reliably forces it.

## `~/.local/share` on Windows holds real, unmanaged app dirs -- don't assume chezmoi made them (2026-09-22)

While chasing a stray `.local/share/com.pais.handy` dir that chezmoi kept recreating on
Windows (see the Handy config entry above and the `.chezmoiignore` block-placement fix),
also checked the rest of `~/.local/share` on this machine in case anything else needed the
same ignore treatment. Found `chezmoi/`, `claude/`, `opencode/`, `opentui/` alongside it --
none of these are chezmoi-managed (`chezmoi managed` doesn't list any file under them).
They're each tool's own data dir, created by the tool itself (chezmoi's own cache/lock
state, Claude Code's session data, OpenCode's data dir, OpenTUI's data dir), following the
XDG `~/.local/share` convention even on Windows where `AppData` is the native spot. Nothing
to ignore or fix here -- only add a `.chezmoiignore` entry under `.local/share` for a path
if chezmoi itself is shown to be the one (re)creating it (check with `chezmoi managed`
first), not just because the path lives there.

Also checked `layout.css.prefers-color-scheme.content-override` (was tracked, value `0`)
while debugging this — confirmed it's a *different* bug, not unrelated as first assumed:
this pref pins Firefox's "Website Appearance" setting (`about:preferences` → Language and
Appearance), which controls what web content sees for `prefers-color-scheme`, not the
browser's own chrome theme. Value mapping is 0=Dark, 1=Light, 2=System, 3=Browser/Auto —
initially misread `0` as Light, it's actually Dark. Since user.js re-pins it on every
restart, any UI change back to Light/Auto silently reverted to Dark on next launch.
Removed the pref entirely so the setting behaves like a normal toggle and persists
whatever's picked in the UI, instead of being locked.

## cch (`ch`) install on Arch: sudo step, run by hand (2026-09-28)

`run_onchange_after_35-cch-install.sh.tmpl` clones/builds `gursuj/cch` into
`~/.cache/cch-src` but can't finish `npm install -g` itself on Arch — npm's global prefix
is `/usr`, root-owned. Script prints the command; ran manually once:

```
sudo npm install -g --prefix "/usr" "/home/sujal/.cache/cch-src"
```

## OpenCode v2 vim plugin: wrong config file, not a host bug (2026-10-05)

Two v2-port forks of `leohenon/opencode-vim-plugin` (cameronr's, xFabriicio's) both crashed
with `context.storage`/`context.ui.slot` undefined, even on the fork pinning the correct
package scope (`@opencode/plugin`, not the abandoned `@opencode-ai/plugin@0.0.0-beta-*`).
Not a package-version issue.

Real cause: both forks export a root `"."` alongside `"./tui"` in `package.json`. A root
export routes OpenCode to **server-side** activation (eager, at boot, no TUI client
attached yet), and that `Context` lacks `storage`/`ui` regardless of type declarations.
Confirmed via `oribarilan/vimcode`'s own docs: "do not add a root export, which redirects v2
plugin installation to the server target."

Also: v2 TUI plugins register in `cli.json` (schema `opencode.ai/v2/cli.json`), not
`opencode.jsonc`'s `plugin` array (server/generic plugins — dcp lives there) and not
`tui.jsonc` (that key is a red herring). Found this from herdr's own TUI entry living in
`cli.json`.

Switched to `oribarilan/vimcode` (`vimcode@git+https://github.com/oribarilan/vimcode.git#v0.19.1`
in `cli.json`'s `plugins`) — maintained, tested, works. Leader key: `cli.json`'s
`keybinds.leader` and the plugin's `experimentalV2Leader` option must match, or leader
shortcuts/printable input get swallowed.

## herdr pane-mover: installed from a fork, same plugin id (2026-10-12)

`prefix+m` runs `osamahbeig.pane-mover.open` on every machine. The plugin is installed
from `gursuj/herdr-pane-mover` (in `desired-plugins.txt`), a fork that only adds
`"windows"` to `platforms` in `herdr-plugin.toml`. The upstream PR is
`osamahbeig/herdr-pane-mover#1`.

herdr takes the plugin id from the manifest, not the GitHub slug, so the fork still
installs as `osamahbeig.pane-mover` and the bind needs no change. The catch: the fork and
upstream share that id, so they can't be installed together.

When the upstream PR merges, on each machine:
1. Change the slug in `desired-plugins.txt` to `osamahbeig/herdr-pane-mover`.
2. Run `herdr plugin uninstall osamahbeig.pane-mover` once.
3. The next `chezmoi apply` reinstalls it from upstream.

If upstream declines the PR, the fork stays. Pull upstream changes into the fork's `main`
and re-check that the `platforms` line survived.

## kanata-start on Windows: background start and elevation (2026-10-12)

`kanata-start` in the PowerShell profile stops any running kanata and starts a fresh one
with a hidden window. Three things to remember:

- A plain `& "...kanata_windows_gui_winIOv2_x64.exe" --cfg ...` does not background it in
  PowerShell. kanata's log output stays attached to the terminal and makes it unusable. The
  function uses `Start-Process -WindowStyle Hidden` with stdout and stderr redirected to
  `%TEMP%\kanata.out.log` and `%TEMP%\kanata.err.log`.
- The normal instance runs elevated from the Task Scheduler logon task. A non-elevated shell
  can't stop it, so the function prints a message and does not start a second copy. Run it
  from an elevated pwsh to restart.
- A restart from a normal shell leaves kanata non-elevated until the next logon. It may then
  not remap keys inside admin windows. Log off and on, or restart it from an elevated shell,
  to get the elevated instance back.

Tested: the function parses and loads, and an earlier version's "already running" guard
worked. The stop-and-restart path was run by hand, not by the agent.

## VPS is Ubuntu 24.04.5 LTS: apt nvim is 0.9.5, init.lua degrades instead (2026-10-24)

The `vps` machine kind runs Ubuntu 24.04.5 LTS (noble). Its apt `neovim` is 0.9.5 and
that's the newest apt offers there. Two things in `dot_config/nvim/init.lua` broke on it:
`vim.keycode()` (needs 0.10) failed on first open, and `vim.o.winborder` needs 0.11. The
plugin stack (nvim-treesitter `main`, current nvim-lspconfig) needs 0.11 or newer too, so
making the whole config 0.9-compatible isn't realistic.

Decision: no nvim install script (an earlier tarball-installer draft was dropped). Instead
`init.lua` uses a plain `' '` leader, guards `winborder`, and returns before the PLUGINS
section when `vim.fn.has('nvim-0.11') == 0`. On the VPS you get the editor settings only,
no plugins, no error. On arch (0.12.x) nothing changes.

If the VPS ever needs the full config: `sudo add-apt-repository ppa:neovim-ppa/unstable`
or `sudo snap install nvim --classic`, by hand. Check the version it gives is 0.11 or newer.

Same class of issue: Debian/Ubuntu fzf is 0.44, which has no `fzf --zsh` (added in 0.48).
`dot_zshrc.tmpl` falls back to `/usr/share/doc/fzf/examples/key-bindings.zsh`.

## pwsh unix commands broke after a per-user Git reinstall (2026-10-26)

A `winget upgrade` failed halfway on this machine (no admin: Git's installer hit `Error 5:
Access is denied` on `C:\Program Files\Git`, and the GitHub CLI MSI hit 1625, "forbidden by
system policy"). winget had already removed the old Git, so `git` disappeared. Reinstalling
per-user with `winget install Git.Git --scope user` put Git in
`%LOCALAPPDATA%\Programs\Git`.

That broke `clear` (and `ls`, `cat`, `cp`, `mv`, `rm`, `sort`, `tee`, `diff`, `echo`,
`sleep`, `ps`, `kill`). The profile deliberately removes pwsh's aliases for these so the
real unix binaries in Git's `usr\bin` win, but it hardcoded `C:\Program Files\Git\usr\bin`.
With Git elsewhere the aliases were gone and nothing replaced them, so `clear` reported "not
recognized".

Fix: the profile now derives `usr\bin` from wherever `git.exe` resolves (two levels up, then
`usr\bin`), and falls back to the old path if git isn't on PATH. Any Git location now works,
including a non-admin install. Existing terminals need a restart to pick it up.
