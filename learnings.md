# Learnings

Dated log of resolved issues, corrections, and decisions made while building out this
dotfiles repo. Kept separate from `README.md` so the README stays a clean current-state
reference and this file stays the historical "why" record. Referenced from `AGENTS.md` and
`README.md` so any agent working in this repo picks it up.

## Extension shortcuts are not in `prefs.js` (2026-11-08)

Two extraction attempts on the IdeaPad came up empty because they looked for `commands.*` in
`prefs.js` (`user_pref("commands.<id>.<command>", "Ctrl+Alt+D")`). That is the shape older Firefox
used; current Firefox stores them in the profile's **`extension-settings.json`**, under
`commands.<command name>.precedenceList[]` as `{id, installDate, value: {shortcut}, enabled}`.
Consequences: `user.js` cannot carry shortcuts (it only sets prefs), Firefox Sync does not sync
them, and the only route is a file-level merge — `scripts/sync-extension-shortcuts.py`, tracked at
`dot_config/extension-shortcuts/firefox-shortcuts.json`, applied with Firefox closed (it rewrites
the file on exit).

## Check the branch before touching chezmoi (2026-11-08)

`main` and `t14` disagree about `machine_kind`: main (IdeaPad) asks for `"arch"` in every
`.chezmoiignore`/template gate, t14 asks for `"t14"`. Working on the wrong branch makes a whole
category of paths look unmanaged (`firefox-tweaks`, `search-engines`, `tridactyl`, `kanata` all
reported managed=0 under main's gates) and produces diffs that "prove" a regression which does not
exist on the branch that matters. `git branch --show-current` before diagnosing, and be suspicious
when a `git log` shows commits you expected on the other branch — that is how the slip was caught.
A branch switch also leaves `~/.config/chezmoi/chezmoi.toml` generated from the *other* branch's
template, which makes chezmoi warn "config file template has changed"; `chezmoi init
--promptDefaults` rewrites it byte-identically when the first prompt choice is the right one.

## A duplicated table key silently dropped a setting (2026-11-07)

`hl.config({ ... })` takes a Lua table literal, so two `binds = {...}` keys in the same literal
mean the second replaces the first — no error, `configerrors` stays empty. That is how
`binds.workspace_back_and_forth = true` disappeared: it went in with `middle_click_paste` etc., and
a later patch appended a second `binds = { allow_pin_fullscreen = true }` at the end of the same
call. The symptom was the user-visible one ("pressing SUPER+3 while on 3 no longer jumps to the
last workspace"), and `hyprctl getoption binds:workspace_back_and_forth` reporting `false` is what
exposed it — always read the option back after touching `hl.config`, because a lost key looks
exactly like a lost feature. `getoption` cannot set it back; the fix is merging the tables.

## Window-rule `move` and `size` disagree about which comes first (2026-11-07)

A rule that sets both is evaluated with the window's *pre-rule* geometry for `move`: with
`size = { 600, 338 }` and `move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" }`, a
window that mapped at 800x600 landed at x = monitor_w - 800 - 40, not in the corner. Percentages
and the `monitor_w` expressions parse fine, so nothing reports an error. For anything that must
sit flush in a corner at a size it did not choose, arrange it on `window.open` instead
(`float` → `resize` → `move` with `relative = false`, coordinates computed from
`monitor.width / monitor.scale`); Omarchy's own PiP rule (top-right at 600x338) has the same
offset, which is why overriding only its `size` left the window badly placed.

## Trackpad scroll: the notchiness was `emulate_discrete_scroll`, not speed (2026-11-07)

Hyprland reports `input:emulate_discrete_scroll` as 1 by default: pixel-precise touchpad deltas
are folded into whole wheel notches, so two-finger scrolling steps rather than glides. There is no
"smoothed scroll" option in Hyprland — the only knobs are `input:touchpad:scroll_factor` (speed),
`input:scroll_factor` (all devices) and `emulate_discrete_scroll` (0 = pass the smooth deltas
through). Firefox smooths on its own (`general.smoothScroll`, `mousewheel.default.delta_multiplier_y`,
`mousewheel.min_line_scroll_amount`), which is why an app with its own scrolling (Hermes desktop,
browsers) felt smoother than a GTK app under the notched events.

## Per-monitor workspaces: SUPER+N goes to the local block, so override the focus (2026-11-07)

Omarchy's `default/hypr/monitor-workspaces.lua` gives every monitor its own block of ten ids
(panel 1-10, the next monitor 11-20) and `SUPER+N` means "slot N of the focused monitor". Pressing
`SUPER+2` over the external screen therefore opens an empty 12 while the browser sits on 2 on the
panel. `bindings.lua` now rebinds the row (`SUPER + code:10..19`, a keysym bind would sit beside
the code bind instead of replacing it) to `o.workspaces.focus_occupied(N)`: prefer a populated
workspace in that slot — the focused monitor's own first, then the lowest id anywhere — and fall
back to Omarchy's `focus(N)`, which reuses or creates the local slot. Focusing a workspace id that
lives on another monitor moves focus there, which is the wanted behaviour; nothing is moved.

Expose such a helper on `o.workspaces` and return a function: `hyprctl dispatch
'o.workspaces.focus_occupied(5)'` then runs exactly what the key runs, which is the only practical
way to test a bind without pressing it (wtype does not reach Hyprland's bind layer).

## Updating: `omarchy update` and the user's `pac-update` do different things (2026-11-07)

`omarchy update` (= the menu's Update → Omarchy row, which runs `omarchy-update`) is a pipeline,
not a pacman wrapper: update lock, sudo keepalive, stay-awake, log to `/tmp/omarchy-update.log`,
free-space check, package-cache prune, keyring refresh, then
`pacman -Syu --noconfirm --overwrite '/usr/share/omarchy/*'` inside a `systemd-run --scope` (so a
systemd reexec cannot kill the transaction mid-upgrade; a conflict re-runs it interactively), then
orphan prune, log analysis, restart of stale services, `omarchy-update-mise`, AUR via
`yay -Sua --noconfirm --cleanafter --ignore gcc14,gcc14-libs`, a boot/loader check, and a reboot
prompt when the kernel or systemd moved.

The zsh `pac-update` function (`dot_config/shell/arch-aliasrc`) is now the wrapper that combines
the two: reflector first (`pac-mirror-update`), then `omarchy update`, then the cleanup Omarchy
skips — `yay -Sc`, `yay -Yc`, and removal of leftover `/var/cache/pacman/pkg/download-*` dirs.
Its failure summary prints from `/tmp/omarchy-update.log` when Omarchy's pipeline was the thing
that failed (and from its own `tee` logs on a box without Omarchy, which still takes the old
interactive `sudo pacman -Syu` + `yay -Syu` path). It returns non-zero when the update failed,
even though the cleanup still ran.

Neither tool subsumes the other: Omarchy has no mirror refresh and no firmware step (firmware is
its own menu entry, `omarchy-update-firmware`), while `omarchy update` adds the lock, free-space
check, keyring step, boot verification and reboot handling that a hand-rolled `pacman -Syu` has
none of. Hence: `pac-update` = reflector + `omarchy update` + cleanup.

## `dump` wrote the deployed copy, and a live dump wiped 31 search engines (2026-11-07)

`scripts/sync-search-engines.py dump <browser>` used to write the *deployed* file
(`~/.config/search-engines/custom-engines.json`) while the repo copy stayed untouched. Two
consequences, both observed: the dump is silently reverted by the next `chezmoi apply` (and makes
chezmoi ask "has changed since chezmoi last wrote it?"), and a profile that reports **0** custom
engines — a fresh profile, or one that never had them — replaces the tracked list with `[]`. That
is how 31 engines went; the file had to be re-applied from source.

Now `dump` writes the chezmoi source path (`chezmoi source-path`), and refuses to write an empty
list over a non-empty one unless `--force` is passed. General rule for this repo: a tool that
*edits* tracked content writes the source path and prints the `git diff` to review; only `apply`
touches deployed paths, and `chezmoi apply --force -- <file>` is the way to overwrite something
that was edited outside chezmoi (a bare apply tries to prompt and dies with `could not open a new
TTY`).

## Firefox moved its profile root to XDG, so profile scripts did nothing (2026-11-07)

Firefox 147+ keeps profiles under `~/.config/mozilla/firefox` (bug 259356, following the XDG
base-dir spec), not `~/.mozilla/firefox`. Both `run_onchange_after_60-browser-user-js-sync.py`
and `scripts/sync-search-engines.py` hardcoded the legacy path, found no `profiles.ini`, and
skipped with a message that reads like benign "not installed". The tracked `user.js` had therefore
never been linked into a profile on this box. Both now try candidates in order
(`$XDG_CONFIG_HOME/mozilla/firefox`, then `~/.mozilla/firefox`; `$XDG_CONFIG_HOME/waterfox`, then
`~/.waterfox`) — when a browser "isn't found" by a chezmoi script, check the profile root before
believing the message.

Related: `sync-search-engines.py` imports `lz4`, which on Arch comes from `python-lz4` installed
for `/usr/bin/python3`. This box has a Hermes venv's `python3` first on PATH, which cannot see
distribution site-packages, so the script exits at import. It now re-execs `/usr/bin/python3`
once when `lz4` is missing and the distribution python exists.

## Window rules cannot match a special workspace; arrange on the event instead (2026-11-07)

`special:scratchpad` cannot be used as a window-rule match on Hyprland 0.56.2: neither
`workspace = "special:scratchpad"` nor the documented `name:` selector form matched (proved with
a probe rule setting `pin`, which never applied, while a class rule in the same config did). The
wiki lists `workspace` as a match property, so this fails *silently* — the rule is accepted and
`configerrors` stays empty.

What works is the pattern Omarchy's own `default/hypr/workspace-modes.lua` uses: react to
`window.open` / `window.move_to_workspace`, then dispatch
`hl.dsp.window.float({ action = "on", window = w })`,
`hl.dsp.window.resize({ x = ..., y = ..., relative = false, window = w })` and
`hl.dsp.window.center({ window = w })` — sizes computed from `monitor.width / monitor.scale`
minus `monitor.reserved`. Skip windows that already float, so the package pickers keep their
packaged 875×600.

Seeding a terminal into an empty scratchpad: `hl.on("workspace.created", ...)` with
`workspace.is_empty`, then `hl.exec_cmd("xdg-terminal-exec", { workspace = "special:scratchpad" })`.
`on_created_empty` on a workspace rule looks tidier in the stub, but the event + pinned exec is the
shape that is proven here (same as `qconsole.lua`), and `misc.initial_workspace_tracking = 0` is
what makes the explicit `workspace` option necessary rather than optional.

## Register touchpad gestures once, in bindings.lua (2026-11-07)

This repo already ported the IdeaPad's three-finger gestures into `bindings.lua`, so adding the
same `hl.gesture` calls to `input.lua` produced
`Gesture will be overshadowed by a previous gesture` from `hyprctl configerrors` — the first
registration wins and the duplicate is dead code plus permanent noise. Before porting a setting
from `main`, grep the repo's own modules: the packaged Omarchy defaults are not the only thing
that can already implement it.

## Removing a tracked skill leaves three stale things behind (2026-11-07)

Deleting `dot_agents/skills/<name>` and applying removes nothing from the live machine: chezmoi
does not prune targets it no longer manages (this build has no `chezmoi prune`), and the
skill-symlink script only creates links. After dropping the `wrap` skill the leftovers were
`~/.agents/skills/wrap/` (a plain directory with its `SKILL.md`), plus `~/.claude/skills/wrap` and
`~/.hermes/skills/wrap` symlinks pointing into it — the latter two still resolve, so any agent
would keep listing a skill that is no longer tracked. Remove all three by hand, then check
`~/.agents/skills/` and both agent dirs rather than trusting `chezmoi status`.

## Adding a skill: the CLI, the repo copy, and the links (2026-11-07)

`npx skills add <repo> --skill <name>` is still the way to *fetch* a skill, but three things bite:

- **Agent names are not what you would guess.** `claude` and `opencode,claude-code` are rejected;
  the flags are `-a claude-code -a opencode -a hermes-agent` — repeated, one per `-a`, not a
  comma-separated list. `npx skills add <repo> --help` prints nothing useful for this (it dumps the
  top-level help); the valid list only appears in the error when a name is wrong.
- **The upstream can vanish.** `camacho/ai-skills` (source of `wrap`) is private/deleted: `gh repo
  view camacho/ai-skills` cannot resolve it, `gh api users/camacho/repos` does not list it, and
  `npx skills add` fails with `Authentication failed for https://github.com/camacho/ai-skills.git`.
  skills.sh still renders the page, and its Next.js RSC payload carries the whole `SKILL.md` body
  (`previewHtml`/`restHtml` in the flight data: `<h1>Wrap</h1>` through the last table), so the
  skill was reconstructed from there and tracked — `npx skills add`/`update` cannot manage it
  afterwards, and the repo copy is the source of truth. Do this only for a skill already in use:
  the copy stops receiving upstream fixes.
- **hermes needs its own link.** opencode reads `~/.agents/skills` natively, Claude Code needs
  `~/.claude/skills/<name>`, and hermes only reads `~/.hermes/skills` — the symlink script now
  covers all three, and it links every tracked skill, not just the new one.

Also: `chezmoi apply` aborts on `.claude/settings.json` ("has changed since chezmoi last wrote it?
… could not open a new TTY"), so adding a skill silently deploys nothing unless the apply is
`--force` — the status line is what catches it (`R` on the skill-symlinks script after an apply
that should have run it).

## First `chezmoi init` + `apply` on the t14: two blockers, both in this repo (2026-11-07)

`init` and `apply` had never run on this box. Both needed a fix before anything deployed:

- **`promptChoiceOnce` needs a TTY and `--promptDefaults` does not bypass it.** `chezmoi init`
  died with `could not open a new TTY: /dev/tty`. Under a PTY it exited 0 but answered nothing,
  leaving `machine_kind = ""` in the generated config. The answer *is* cached in
  `~/.config/chezmoi/chezmoi.toml` under `[data]`, so writing the right value there makes every
  later `init` non-interactive — verify with `chezmoi data | jq .machine_kind` before applying,
  because an empty kind silently flips every `{{ if ne .machine_kind … }}` gate.
- **A Windows-only `[diff]` wrapper broke `apply` on Linux.** The template routed diffs through
  `sh -c` to translate the `NUL:` sentinel for git-bash's `diff.exe`; on Linux that wrapper is
  unnecessary *and* fatal — for a target that does not exist yet chezmoi diffs against a scratch
  path ending in `/null`, so the wrapper handed `diff` a missing file and `apply` aborted with
  `chezmoi: .agents/skills/agent-browser: exit status 2` **before writing anything**. Gate the
  wrapper on `eq .chezmoi.os "windows"`; everywhere else leave `[diff]` with just `exclude`.
  (Nothing had been applied, so `chezmoi status` was the check that caught it.)
- With those fixed, the apply created 118 targets and ran 9 scripts cleanly. Post-apply checks
  worth repeating: `hyprctl configerrors`, `omarchy-shell shell ping`, `herdr config check`,
  `systemctl --user is-active kanata`, `zsh -lc 'echo ok'`, and `stat -c %a ~/.local` (700, from
  its `private_` name).

## Claude Code rewrites its own `settings.json`; `chezmoi status` will say so (2026-11-07)

Ten minutes after apply, `.claude/settings.json` was `M` again: Claude Code had re-saved it with
the `hooks` block inlined onto one line and a tab indent on one plugin key. The content is
semantically identical (no key lost), so this is not drift to chase — the same class as the
line-ending churn already documented in the README. Leave the tracked file formatted for
readability and treat a lone `M` there as expected.

## Background daemons that share the idle clock, and the one they cannot see (2026-11-07)

Omarchy's shell idle service only knows `idle.screensaver` and `idle.lock`; the IdeaPad's
`hypridle.conf` also had keyboard-backlight, dim, display-off and suspend steps. Those now live in
`swayidle` (repo package), started as `swayidle.service` → `~/.local/bin/omarchy-idle`, and both
daemons listen to ext-idle-notify-v1 so they share one idle clock: 150 s kbd backlight off, 300 s
panel dimmed to 1 %, 630 s DPMS off, 1200 s suspend.

- **Disabled screensaver turns `idle.screensaver` into a no-op — port the dim step instead of
  leaning on it.** This box runs `omarchy-toggle-enabled screensaver-off`, so the value in
  `shell.json` no longer dims or covers anything; the dim at 300 s has to come from the idle
  helper or the panel jumps from full brightness to display-off. (`omarchy-launch-screensaver`
  itself checks that same toggle and exits early.)
- **Backlight device names are per-machine.** The IdeaPad's `brightnessctl -sd rgb:kbd_backlight`
  does not exist here: the LED is `tpacpi::kbd_backlight` and the panel is `amdgpu_bl1` (max
  65535, so `set 10` from the old config would be black — `set 1%` is the lowest visible step).
  `brightnessctl -s` / `-r` save and restore either one.
- **swayidle 1.9 + current systemd: `Failed to parse get BlockInhibited property: Invalid
  argument`** at start. It means swayidle cannot read logind's inhibitor list, so an application
  that holds an idle inhibitor (video player, presentation mode) will still hit the display-off
  and suspend timeouts. Tracked in `TODO.md` as something to fix; until then, drop the suspend
  step if it starts interrupting.
- **A freed default key must be released explicitly.** herdr's defaults bind `prefix+tab` /
  `prefix+shift+tab` to pane cycling; adding those keys to `next_tab`/`previous_tab` (which take
  *arrays*, so multiple binds per action work) is not enough — the default still claims them.
  `cycle_pane_next = "prefix+o"` and `cycle_pane_previous = ""` frees them, and
  `herdr server reload-config` answering `status: applied, diagnostics: []` is the proof: a key
  claimed twice shows up there as `kept X, disabled Y`.

## A phantom "Lid closed" suspends the machine, and the kernel says why (2026-11-07)

Screen went black mid-typing; it was not the idle timers.

- logind logged `Lid closed.` → `Suspending…` three times in nine minutes, one of them a real
  9-second suspend; the kernel logged `ACPI: button: [Firmware Bug]: Unexpected lid state
  reported by firmware`. In `drivers/acpi/button.c` a *repeated same-state* `_LID` notification
  is turned into a **complement** switch event ("closed" if it was open) so buggy firmware events
  stay visible to userspace — which is exactly a phantom lid close.
- Diagnose in that order: `journalctl -b | grep -iE "Lid (closed|opened)"` for logind's view,
  `journalctl -k -b | grep "Unexpected lid state"` for the firmware complaint, and
  `/proc/acpi/button/lid/LID/state` for the live value. Post-hoc greps of "dpms" alone mislead —
  the wallpaper engine (`owed`) only logs that it *reacted* to `dpms-off`/`locked`/`sleep`.
- Mitigation is a logind policy, not a Hyprland one: `HandleLidSwitch=ignore` (never suspend on
  lid) or `HandleLidSwitchExternalPower=ignore` (only while charging). Both need a drop-in under
  `/etc/systemd/logind.conf.d/`; a `private_`-style chezmoi target cannot deploy outside `$HOME`.
- Same boot, unrelated: the Synaptics fingerprint reader (`06cb:00bd`) re-enumerated 30+ times in
  two hours (`usb 4-3: reset full-speed USB device`), which is also why a lock-screen fingerprint
  attempt logged `Verification timed out` before succeeding.

## Pre-apply reconciliation on `t14`: chezmoi normalises modes by filename, and `docs/` needed an ignore line (2026-11-07)

Working through `docs/t14-merge-handoff.md` before the first `apply`: the modified-file list went
from 11 to 8, and every remaining entry is a superset or a mode normalisation rather than
content drift.

- **Audit without touching `~/.config/chezmoi/`.** A throwaway config (`sourceDir` + `[data]
  machine_kind = "t14"`) makes `chezmoi status/diff/managed` work while the real config is still
  un-initialised, and `--exclude=encrypted` keeps it working before the age identity is
  configured. Remember `chezmoi diff` needs **absolute** target paths (`diff -- ~/.config/x`);
  a relative `.config/x` answers "not managed".
- **This chezmoi build ignores the source file's mode and derives it from the name.** A plain
  `dot_x/poster.sh` added as 755 is applied as 644 (reproduced in a two-file scratch repo), so a
  pinned-down script in the source needs the `executable_` prefix (`executable_poster.sh`) to
  stay executable. Same mechanism the other way: `private_*` forces 600/700 — which is why
  `~/.local` and `~/.local/share` are "modified" on a box where Omarchy created them 755, and why
  `dot_config/opencode/private_cli.json` shows a mode-only diff.
- **A root-level folder that is missing from `.chezmoiignore` gets deployed.** `docs/` was
  tracked but not ignored, so the first `apply` would have created `~/docs` — the exact trap
  `AGENTS.md` describes for root docs. It is now listed next to `README.md`/`AGENTS.md`.
- **Track the format the app writes, not the format you wrote.** `tui.jsonc` drifted after every
  opencode session because opencode rewrites it with the plugin array inline; the template now
  renders that shape (and keeps the Windows-only `vimcode` entry on a one-line branch). Both
  branches were rendered and `jq`-validated, and the Linux render is byte-identical to live.
- **Template whitespace is part of the diff.** `{{- … -}}` on the comment/if actions is needed or
  the render starts with a blank line; check with `cat -A` and `chezmoi diff` on the single file
  rather than trusting the template to look right.
- Live-vs-source reconciliation for a **templated** file goes into the shared template
  (`.chezmoitemplates/herdr-config.toml.tmpl`), never `chezmoi re-add` — re-add flattens a
  `.tmpl` and would drop the conditional blocks.

## Window rules match the title a window has *at map time* — and the menu may not use the launcher you think (2026-11-07)

The Omarchy package pickers (Install → Package, Install → AUR, Remove → Package) opened on the
focused workspace instead of the scratchpad although a rule for them existed and a hand-spawned
window obeyed it.

- **Two launchers, one class.** `install.package` / `install.aur` / `remove.package` run
  `xdg-terminal-exec --app-id=org.omarchy.terminal <cmd>` **directly** (no `--title`), so the
  window maps with the terminal's own title (`Ghostty`) and only later renames itself to
  `omarchy-pkg-install`. Every *other* row (plugin add, `omarchy-install-browser …`) goes through
  `omarchy-launch-floating-terminal-with-presentation`, which passes `--title=Omarchy` at map
  time. Read the menu jsonc rows before assuming which wrapper is in play.
- **Hyprland applies rules at map only.** A rule keyed on the post-rename command name never
  fires; the rename does not re-evaluate rules. Key on the map-time pair (`title` /
  `initialTitle`, `class` / `initialClass`).
- **The passing hand-spawn was a false positive.** `ghostty --class=org.omarchy.terminal
  --title=Omarchy -e sleep 20` reproduces the *wrapper* path. Re-test with the literal menu
  action string, not a lookalike.
- Fix: `class = "^(org\\.omarchy\\.terminal)$", title = "negative:^(Omarchy)$"` →
  `workspace = "special:scratchpad"` (no `silent`, so the picker is actually on screen), plus a
  `hl.on("window.close")` hook that closes the scratchpad once the last picker leaves it.
  Negative title keeps the rule terminal-agnostic and leaves the wrapper install flows where
  they were; `negative:` is Hyprland's own regex negation (Omarchy uses it too,
  `workspace-modes.lua`).
- **A parked-but-silent window is an invisible bug, and Hyprland only auto-closes a special
  workspace when it is *empty*.** With a terminal permanently parked on the scratchpad, dropping
  `silent` leaves the user staring at the scratchpad after the picker exits; the close hook
  (`toggle_special` back off, guarded to "no picker left on it" and "the focused window is on
  it") is what makes showing it on open safe.
- **There is no Lua query for "is this special workspace shown"** in 0.56: `monitor.specialWorkspace`
  is nil in the binding and `hl.on("workspace.special_active")` does not fire for a rule-driven
  switch. Infer it from the focused window's workspace, and check `hyprctl monitors -j`
  (`specialWorkspace.name`) from the shell. `hl.get_active_workspace()` reports the *regular*
  workspace underneath, not the special one. `hl` window objects are **userdata**, so `pairs()`
  on them errors — read fields (`class`, `title`, `address`, `workspace.name`), don't iterate.
- **A user rule's `size` loses to a packaged tag rule.** `apps/system.lua` tags
  `org.omarchy.terminal` as `floating-window` and sets 875×600, which beat the rule's
  `size = {1000, 620}` — the size had never applied. Don't re-specify geometry packaging
  already sets.
- Don't clean up test windows with `pkill -f omarchy-pkg-install`: the pattern matches the
  agent's own `bash -c` and kills the running call. Read addresses from `hyprctl clients -j` and
  `hl.dsp.window.kill({ window = 'address:0x…' })`.

## Omarchy already ships a polkit agent — never install hyprpolkitagent (2026-11-07)

Tried `pacman -S hyprpolkitagent` + `systemctl --user enable --now hyprpolkitagent` on the
t14. It crash-looped five times in four seconds, systemd gave up (`start-limit-hit`), and
each attempt fired a "Process crashed" notification.

- Cause: the Omarchy shell already registers an agent. `plugins/polkit/PolkitAgent.qml`
  registers Quickshell's `PolkitAgent` at `/org/omarchy/PolkitAgent`, and polkit allows **one
  agent per session subject**, so hyprpolkitagent's `RegisterAuthenticationAgent` was refused:
  "An authentication agent already exists for the given subject".
- The five SIGSEGVs are a *separate* second failure, not the refusal. `main()` returns 1,
  then the global `g_pAgent` destructor (`~CPolkitListener`) builds an `sdbus::Variant` to
  unregister, and sdbus-c++ 2.3.1's lazy "pseudo connection" reset deletes an object its
  `atexit` handler already freed — a double free in `libsdbus-c++.so.2`. Don't chase the core
  dump as the bug: the refusal is the bug, the segfault is teardown.
- Not Omarchy's to fix: crash is in hyprpolkitagent 0.2.0 + sdbus-c++ 2.3.1, both upstream and
  both current in Arch `extra`. Nothing in this repo is implicated — it deploys no polkit
  config, and installs aren't tracked as packages.
- Remedy: `systemctl --user disable --now hyprpolkitagent` then `pacman -Rns hyprpolkitagent`.
  The unit file disappears with the package; a stale `failed` entry can linger until
  `systemctl --user reset-failed hyprpolkitagent`.
- Race to avoid, and how it actually shows up: if another agent *wins* the slot first, the
  shell's registration is refused and Omarchy does not retry (`keepLoaded`), leaving the
  session with no agent until `omarchy restart shell` (upstream omarchy#9558). Seen live on
  2026-11-08: the shell exited with status 255 at 20:15 (`omarchy-launch-shell` relaunches
  after one second on any non-zero status, without checking that the old instance's D-Bus
  names are free), and its replacement was refused **both** the polkit agent and the
  `org.freedesktop.Notifications` name. Neither registration is retried. The session then
  had no agent for 30 min; LocalWP's `/etc/hosts` write failed with `No polkit
  authentication agent found` (exit 127, `@vscode/sudo-prompt` → `pkexec`) and site
  creation aborted. `omarchy restart shell` re-registered it immediately. Confirm with
  `journalctl --user -g 'omarchy polkit agent'` → `omarchy polkit agent registered`.

## Machine kind renamed `arch` -> `t14` for the ThinkPad migration (2026-11-06)

Moving off the IdeaPad (Arch) onto a ThinkPad T14 running Omarchy. The old `arch` value
named a *machine*, not a distro — Omarchy is Arch-based, so pacman/Wayland conditionals
still hold — so it's renamed rather than duplicated.

- Done on branch `t14` (not merged): `.chezmoi.toml.tmpl` prompt list
  (`t14|vps|wpc`), all `.machine_kind "arch"` conditionals in `.chezmoiignore`,
  `dot_zshrc.tmpl`, `dot_zprofile.tmpl`, `.chezmoitemplates/firefox-preferences.js.tmpl`,
  plus comments/prose in `README.md`, `TODO.md`, `dot_config/shell/arch-aliasrc`.
- `arch-aliasrc`'s **filename** was not renamed — it holds pacman/Wayland aliases, which
  are still Arch-specific even though they're now sourced on `machine_kind == t14`.
- Gotcha: `promptChoiceOnce` caches the answer in the machine's own
  `~/.config/chezmoi/chezmoi.toml`. A box that already answered `arch` will keep rendering
  `arch` (and silently take the vps/not-arch branches) until that `[data] machine_kind`
  entry is edited or the file is deleted. Fresh `chezmoi init` on the t14 sees `t14` in the
  list.
- `main` still says `arch`. Don't apply this repo on the t14 from `main`, and don't apply
  `t14` on the old IdeaPad — the ignores flip either way.

### First decisions on the t14 (same day)

- **zsh is the login shell again** (`/usr/bin/zsh`), so the zsh layer applies after all.
  Arch's `/etc/zsh/zprofile` does `emulate sh -c 'source /etc/profile'`, and
  `/etc/profile.d/omarchy.sh` sources omarchy's `env-bootstrap` — so login shells already
  get `OMARCHY_PATH` + the mise wrapper PATH. `dot_zprofile.tmpl` sources the same file
  again behind a `-r` guard for non-login shells; harmless on the VPS.
- **`.bashrc` now mirrors omarchy's default instead of replacing it.** The old 15-line
  version would have deleted `OMARCHY_PATH` and the mise-wrapper PATH for every
  `bash -i` / script shell. It only ever sources `$OMARCHY_PATH/default/bash/{env-bootstrap,rc}`,
  so omarchy's own aliases keep flowing through updates; the wp-cli fix is the one addition.
  Omarchy does *not* rewrite `~/.bashrc` after install — the only writer is an
  Apple-Silicon-only migration that explicitly skips a dotfiles-managed file.
- **nvim: LazyVim wins for now.** `.config/nvim` is ignored for `machine_kind == t14`; the
  tracked hand-built config would have replaced omarchy's themed LazyVim setup wholesale.
- Merge policy for everything else: omarchy's file stays the base, its theming stays
  authoritative (no hardcoded colours/themes carried), and only chosen old settings are
  ported into omarchy's *user-owned* files.

### Hypr on the t14: track the user files, never the entry point

**Why this branch's hypr config looks nothing like `main`'s, in one paragraph (read this
first in a fresh session):** the IdeaPad ran one hand-written 836-line
`~/.config/hypr/hyprland.conf`-as-Lua monolith that owned every bind, monitor, looknfeel
value and autostart entry. Omarchy replaces that whole layer: `/usr/share/omarchy/config/hypr/`
ships an entry point (`hyprland.lua` → `dofile bootstrap` → `require default.hypr.omarchy`)
that loads defaults, toggles, bar bindings and workspace modes, then requires five
*user-owned* modules (`hypr.monitors`, `input`, `bindings`, `looknfeel`, `autostart`). So on
this branch the monolith was deleted (`git rm`; it still exists on `main` and in history) and
the five user modules were re-created from Omarchy's copies with the personal deltas layered
on top. Concretely: binds are `o.rebind`/`o.bind` over Omarchy's set instead of a full keymap,
colours/gaps come from Omarchy's theme, idle/lock/paper moved to `shell.json` (hypridle,
hyprlock and hyprpaper are not installed here), and `hyprland.lua` itself is ignored by
chezmoi because replacing it kills every default at once. Expect *fewer* lines, not a port.


- Tracked: `dot_config/hypr/{bindings,looknfeel,autostart,monitors}.lua` +
  `hyprsunset.conf`. Ignored: `.config/hypr/hyprland.lua` — it is omarchy's entry point
  (`dofile bootstrap` → `require default.hypr.omarchy` → `require hypr.*`), so replacing it
  kills every default, toggle and bar binding at once.
- The IdeaPad's monolith (`hyprland.lua`, `hypridle/hyprlock/hyprpaper.conf`,
  `new-example-hyprland.conf`, `old-hyprland.conf`) was deleted on this branch; `main` and
  git history still have it. hypridle/hyprlock/hyprpaper aren't installed on the t14 at all —
  omarchy does idle/lock through `~/.config/omarchy/shell.json`.
- **`o.bind` on a key omarchy already binds leaves BOTH actions on that key.** Hyprland then
  has two binds on one combo (the earlier verification caught `SHIFT+C` = Calendar *and*
  Close). Use `o.rebind` (it unbinds first), or `hl.unbind` + `o.bind`. Verify by grouping
  `hyprctl -j binds` output by (modmask, key) and printing any group with >1 entry — that is
  the only way to see it; `hyprctl configerrors` stays empty.
- `o.rebind`/`o.bind` with a command string is wrapped in `exec_cmd`, and `{ tui = ... }` /
  `{ omarchy = ... }` tables are translated by `helpers.lua` — so omarchy's own idioms work
  in `bindings.lua` too.
- Resolved mapping (IdeaPad → t14): `Q` terminal (close stays on `W`, plus `SHIFT+C`);
  `SHIFT+F` maximize; `E` file manager; `SHIFT+M` exit (uwsm ends the session to SDDM, not a
  tty); `H/J/K/L` focus with split/layout moved to `SHIFT+V` / `ALT+V`; `TAB` last window
  (workspace paging on `CTRL+TAB`); `A`/`D` + `SHIFT` workspace/window to monitor, which
  costs omarchy's "select all"; PiP on `ALT+P`; screenshots stay omarchy's `PRINT`.
- **The desk keyboard has no arrow keys** — that is why monitor movement migrated from arrows
  to `A`/`D`, and it must stay that way when editing binds.
- `hyprctl dispatch exec <cmd>` is broken on Hyprland 0.56's Lua config (`')' expected near
  <cmd>`, same family as the old `dpms` lesson below) — launch things with
  `hyprctl dispatch 'hl.dsp.exec_cmd("…")'`. `hyprctl reload` alone does not re-run
  `autostart.lua`, so a newly added `o.launch_on_start` needs one manual launch to take effect
  in the current session.

### Omarchy surfaces that are *not* config-compatible with the waybar/hypridle setup

- **No hypridle/hyprlock/hyprpaper on the t14.** Idle and lock are Omarchy's own (quickshell):
  timings in `~/.config/omarchy/shell.json` → `idle` (screensaver 150, lock 300). The lock
  screen is wallpaper + password card only — `LockView.qml` has no clock, battery or charge
  indicator, and there is no `shell.json` key for adding them. Getting time/battery there means
  either cloning the lock plugin (`omarchy plugin clone`) and adding QML, or installing
  `hyprlock` and pointing idle at it (loses Omarchy's fingerprint/PAM integration styling).
- **`omarchy.workspaces` always renders the monitor's first five slots** plus any workspace
  beyond them that exists (`Workspaces.qml`, `workspaceIds()`), so "only occupied" needs a
  cloned widget with that function trimmed — it is not a `shell.json` option. The *click on the
  focused workspace* there cycles that workspace's layout by design.
- Per-monitor workspace blocks come from `~/.local/state/omarchy/monitor-workspaces`, and
  `hl.get_last_workspace()` is what "go back to the previous workspace" uses (bound on the
  digits in `bindings.lua`).
- **Theme changes never touch `~/.config`.** `omarchy-theme-set` stages theme output under
  `~/.local/state/omarchy/current/theme/` (including the themed `hyprland.lua` and
  `shell.toml`) and leaves `~/.config/omarchy/{shell.json,shell.toml}` and every tracked hypr
  file alone — verified by mtimes after a theme switch.
- `omarchy toggle nightlight` pokes `hyprctl hyprsunset temperature` directly, so a manual
  toggle lasts until the next timed profile boundary (17:30 / 07:00 in `hyprsunset.conf`),
  which re-applies itself.
- Web apps launched by `omarchy-launch-webapp` **require a Chromium-family browser** (it falls
  back to `chromium.desktop` when the default browser is Firefox), so the Google/Discord/
  WhatsApp launchers all run in Chromium, not Firefox.
- **`misc:middle_click_paste` defaults to `true`, and it synthesises the paste into the
  *focused* window.** On a special/scratchpad workspace the terminal overlays the current
  workspace without taking focus, so middle-clicking it pasted into the window behind it
  (a chat window, say) instead of the terminal. Set `misc.middle_click_paste = false` in
  `looknfeel.lua` so the click reaches the client and Ghostty's own `middle-click-action`
  decides — that is what the IdeaPad config did too.
- **Ghostty's only omarchy-specific config line is the theme include**
  (`config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"`); everything else in
  `/usr/share/omarchy/config/ghostty/config` is plain Ghostty settings. The tracked
  `dot_config/ghostty/config.tmpl` keeps those defaults plus our additions and gates the theme
  line on `{{ if lookPath "omarchy" }}` (there is no file-exists test in chezmoi templates;
  the `omarchy` binary is the reliable proxy), so it renders correctly on a non-omarchy box.
  `omarchy-refresh-config ghostty/config` would clobber the tracked file.

### Number-row binds are keycode-based — never rebind them by keysym

- Omarchy binds the workspace row as `o.bind("SUPER + code:" .. (workspace + 9), …)`, i.e.
  **keycode** `code:10`…`code:19`, not keysym `1`…`0`. `o.rebind("SUPER + 1", …)` therefore does
  not replace that bind (`hl.unbind` can't match a code bind by a keysym string) — it adds a
  second bind on the same physical key. Symptom: `SUPER+1..3` stopped switching workspaces
  entirely, while `hyprctl -j binds` looked fine except for two entries per key (one with
  `key: "1"`, one with `key: ""`).
- Fix that shipped: leave the digits to Omarchy and set Hyprland's own
  `hl.config({ binds = { workspace_back_and_forth = true } })` in `looknfeel.lua` — pressing the
  already-active workspace jumps to the last focused one, no Lua callback involved. A
  hand-written callback reading `hl.get_active_workspace()` / `hl.get_last_workspace()` was
  tried first and never switched anything, so prefer the native option.
- When auditing binds, match on `description`, not on `key`: keycode-bound entries report
  `key: ""` and `keycode: 0` in `hyprctl -j binds` JSON, which makes them look absent.

### Cloning omarchy's lock screen: works, with two traps

`omarchy plugin clone omarchy.lock` produces `~/.config/omarchy/plugins/sujal.lock`, rewrites
the id (`manifest.json` gets `omarchy.clonedFrom`), registers it in `shell.json`'s `plugins`
array and disables `omarchy.lock` — the clone is a plain copy, so omarchy updates never touch
it (and `omarchy plugin update` only handles git-managed plugins, so upstream lock changes must
be ported by hand).

- **A QML error in the clone takes the whole lock service down**, not just the widget: the
  service fails to load and `omarchy-shell lock status` answers `Target not found` — i.e. the
  machine is briefly *unlockable and unlock-less*. Verify right after editing:
  `omarchy-shell lock status` must return the JSON blob, and `journalctl --user | grep -i
  "failed for sujal.lock"` must be empty.
- **`Component.onCompleted` twice is fatal.** `LockView.qml` already sets it; adding a second
  one fails the whole file with `Property value set multiple times`. Use a
  `Timer { triggeredOnStart: true }` for an initial refresh instead.
- `keepLoaded` services (lock/polkit/idle) survive plugin hot-reload, so a rescan keeps the
  *old* instance and its `ShellIpc target: "lock"` handler — the clone then logs "Handler was
  registered but will not be used because another handler already exists". `omarchy-restart-shell`
  is required before the clone actually takes over.
- The clone keeps the same `ShellIpc target: "lock"`, so `omarchy-shell lock status|isLocked|lock`
  and `omarchy-system-lock` keep working unchanged.
- **Clones import omarchy's internal QML modules (`qs.Commons`, `qs.Ui`, `Style`,
  `Commons.Color.*`, `Commons.I18n`), which are not a stable API.** A future omarchy release can
  rename or drop those tokens and break a clone while the packaged original keeps working — so
  after any sizable omarchy update, check `omarchy-shell lock status` still returns JSON and
  `journalctl --user | grep -i "failed for <id>"` is empty. Same applies to a cloned
  `omarchy.workspaces` (it reads `Hyprland.*` and `Util.*` from the same modules).
- **A QML edit does nothing until the shell reloads the file, and bar-widget clones make that
  easy to miss.** A removed scale preset stayed on screen after the file was already correct
  because the running shell still held the old QML — the edit only became visible after a
  restart. `omarchy-restart-shell` is the intended command but is unreliable here (it prints
  "Omarchy shell did not become ready after restart" and leaves nothing running). Recovery:
  `pgrep -x quickshell`, then
  `hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")'` — a compositor-side exec inherits
  Hyprland's environment (`HYPRLAND_INSTANCE_SIGNATURE`, `WAYLAND_DISPLAY`), which a bare
  `quickshell -n -p /usr/share/omarchy/shell` from an agent shell does not; that one logs
  `Unable to connect to hyprland event socket` and paints a dead bar. Confirm with
  `omarchy-shell shell ping` → `ok`.
- **Verify widget changes against the rendered surface, not the source.** `grim -o eDP-1`, crop
  the region, look at it. To open a bar panel without a mouse:
  `omarchy-shell shell toggle <plugin-id> '{}'` (e.g. `sujal.monitor`).

## Monitor not waking after suspend: hypridle used pre-Lua `dpms` syntax (2026-10-31)

Symptom: external HDMI monitor often stayed dark after suspend/wake, and Hyprland shuffled
windows up and down while re-laying out outputs. Predates the TLP experiment.

- **Cause:** Hyprland 0.56 reads `hyprland.lua`, and `hyprctl dispatch dpms on|off` no longer
  parses (`error: [string "return hl.dispatch(dpms on)"]:1: ')' expected near 'on'`).
  `hypridle.conf`'s `after_sleep_cmd` and the dpms listener failed every time since the Lua
  migration (21 Oct): 85 failures in the journal (64 `on`, 21 `off`), so the wake never ran.
  The BenQ also re-enumerated as a new output after resume (output id 276 to 277, ~10-15 s),
  which is what triggered the window jumping.
- **Fix:** `hypridle.conf` now calls `hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'`
  (and `"off"`). Plain `on` with no `monitor` wakes every output (tested by forcing `eDP-1`
  off first). Also set `misc.key_press_enables_dpms` and `misc.mouse_move_enables_dpms` to
  `true` in `hyprland.lua` (both default `false`): after a *manual* dpms off nothing woke the
  laptop panel, only HDMI. Side effect: a manual `hyprctl dispatch ... "off"` from a terminal
  wakes again on the Enter key release, so use `sleep 2; hyprctl dispatch ...` to test.
- Suspend wake confirmed working after the change.
- `old-hyprland.conf` stays in the repo but is in `.chezmoiignore` and no longer deployed.
- Separate, unresolved: `amdgpu 0000:03:00.0: failed to load ucode RLC_RESTORE_LIST_*` and
  `psp gfx command LOAD_IP_FW failed` (0xFFFF300F / 0xFFFF000F) logged on every resume. GPU
  still resumes and renders, so left alone for now. Web search (2026-10-31) found no report
  with this exact string, only other PSP resume failures on Raven/Picasso parts (e.g.
  freedesktop drm/amd issue 919, Ryzen 7 3700U display hang on resume) -- none conclusive.
  Don't assume it's harmless or known-benign; if resume ever hangs, start here.
  A second search (kernel source / amd-gfx terms) also found no exact match; nearest are an
  Omarchy report of PSP resume failing on a Picasso laptop (omacom/omarchy #16617) and a 2017
  amd-gfx patch adding a PSP ring-stop on suspend for Raven. Neither mentions the RLC restore
  list. Own log (resume at 19:05:30): `PSP is resuming...`, then the three `failed to load
  ucode` lines, then the optional RAS/RAP/securedisplay "not available" lines (normal), then all
  rings come up and the display works. No `PSP resume failed` line, so the kernel carries on and
  the restore-list load looks non-fatal on this chip (inferred from the log, not confirmed in
  source). Firmware current: linux-firmware 20260916, picasso_rlc*.bin present. Kernel 7.2.11.

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

## Syncthing config: deliberately not tracked (2026-08-17, path updated 2026-11-07)

Syncthing's config directory (`config.xml`, `cert.pem`, `key.pem`, `https-cert.pem`,
`https-key.pem`, `csrftokens.txt`, the index DB) is not tracked here and should never be added. It
contains TLS private keys, session tokens, and a local database — secrets and per-device state,
not shareable config. Syncthing regenerates all of this itself on first run per device; there's
nothing worth templating. **Syncthing 2.x moved it**: it is now `~/.local/state/syncthing/`, not
`~/.config/syncthing/` (the old path is what the 2026-08-17 note described; the box here runs
2.1.7 and wrote nothing to `~/.config`).

- **Startup is the packaged user unit, not a hand-run binary.**
  `systemctl --user enable --now syncthing` (unit at `/usr/lib/systemd/user/syncthing.service`,
  `ExecStart=… serve --no-browser --no-restart`, `WantedBy=default.target`). It generates the
  config on first start and serves the setup GUI on <http://127.0.0.1:8384>. Running `syncthing`
  in a terminal first is optional and only makes you stop that instance again — one process per
  config dir — so set the device up in the GUI instead.

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

## Charge threshold is systemd's, and Omarchy only warns at 10% (2026-11-08)

`BAT0/charge_control_end_threshold` reads 80 (start 75) on the t14 -- not set by Omarchy and
not a BIOS setting. systemd ships `/usr/lib/udev/hwdb.d/60-upower-battery.hwdb` with a
blanket rule `battery:*:*:dmi:* CHARGE_LIMIT=75,80`, applied by `60-upower-battery.rules` to
every laptop battery. To change it, add `/etc/udev/hwdb.d/61-battery-local.hwdb` with the
same match and your own CHARGE_LIMIT, then `sudo systemd-hwdb update` and trigger the battery
(`udevadm trigger -v -p /sys/class/power_supply/BAT0`). The EC holds it: at 80% it stops
charging, and start=75 means it resumes once the pack falls back to 75.

Omarchy 4.5 has one battery notification: `omarchy-battery-low` at 10%, from the shell's
`plugins/services/battery/Service.qml` (`batteryThreshold = 10`, once per discharge, then
`~/.config/omarchy/hooks/battery-low.d/`). Nothing fires at the charge limit -- the power
panel only *shows* "holding at 80%". `omarchy-battery-notify` (in this repo, deployed to
`~/.local/bin`) adds a 20% warning plus the limit-reached toast: it polls sysfs every 30s and
keeps two flags in `~/.local/state/battery-notify.state` so each fires once per plug-in or
discharge cycle.

Toasts are drawn by the shell's notification service, so the systemd --user unit is
`After=graphical-session.target`; a udev `RUN+=` as root would never reach the desktop session.

## SUPER+Tab is last workspace, not last window (2026-11-15)

`SUPER + TAB` was `focus({ last = true })` (last window). Now `focus({ workspace =
"previous_per_monitor" })`, the action Omarchy gave `SUPER + CTRL + TAB` "Former workspace"
(which this repo already rebinds to next workspace). Behaves like pressing the current
workspace's number under `binds.workspace_back_and_forth`. Last-window focus has no bind now.
