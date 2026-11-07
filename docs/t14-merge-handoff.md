# Handoff — finishing the t14 migration, then merging it back to `main`

## What this branch is

`t14` is a **migration branch, not a fork**. The IdeaPad (old `machine_kind = "arch"`) is being
retired in a few days; when it is gone, this branch merges back into `main` and `t14` becomes
the only Linux-laptop machine kind. Two consequences for anyone working here:

1. **Bias: replicate the IdeaPad's behaviour, don't redesign it.** Where the old config did
   something, this branch should do the same thing on Omarchy — same binds, same monitor
   arrangement, same tools, same defaults. The exceptions are deliberate and documented in
   `learnings.md`: omarchy owns the theming layer and its own entry points (`hyprland.lua`,
   `shell.json`, packaged plugin internals), so we merge *into* its user-owned files instead of
   replacing them.
2. **Don't accumulate t14-only cruft.** Every delta should either be wanted on the merged
   `main` or be guarded by `machine_kind`. Temporary scaffolding (one-off clones, test presets,
   the leftover `superwhisper-panel`) should be cleaned up or listed below before the merge.

## Where it stands (2026-11-07)

Working and verified on the machine: hypr user modules (`bindings`/`looknfeel`/`autostart`/
`monitors`), external monitor above the laptop with 40 px reserved, `CTRL`+brightness on the
BenQ over DDC/CI, kanata (Caps layer) running as a user service, ghostty merged config,
herdr merged config (prefix `ctrl+x`), starship with user@host only over ssh/mosh, opencode on
a single `opencode.jsonc` + merged `cli.json`, mimeapps for installed handlers only, swayimg
default image viewer, sane-break autostart + dconf settings, bar battery %, lock clone with
clock/date/battery, workspaces widget (occupied-only, icons, theme colour), monitor clone with
the 1.5 preset, zed on the Omazed theme.

## Done since this handoff was written (2026-11-07)

- **`chezmoi init` + `apply` have run on this box.** `~/.config/chezmoi/chezmoi.toml` now
  exists (`machine_kind = "t14"`, age identity wired up), 118 targets were created, 6 modified,
  9 scripts ran. Post-apply: `hyprctl configerrors` empty, `omarchy-shell shell ping` ok, kanata
  active, `herdr config check` ok, `zsh -lc` works with antidote installed, `ch` present,
  `~/.local`/`~/.local/share` are 700 as their `private_` names intend.
- **`apply` needed one fix to the config template first**: the `[diff]` sh-wrapper (there for
  git-bash's `diff.exe` and the `NUL:` sentinel) was also being used on Linux, where it broke
  every apply with `diff: …/agent-browser/null: No such file or directory` and exit status 2
  before writing anything. It is now Windows-only; Linux uses chezmoi's own diff.
- **Idle timings ported from the IdeaPad's `hypridle.conf`**: screensaver 300 s and lock 600 s
  replacing Omarchy's 150/300 defaults, and `swayidle` (repo package,
  `swayidle.service` → `~/.local/bin/omarchy-idle`) carries the steps Omarchy's idle service
  does not have. Full ladder, all from the IdeaPad: 150 s keyboard backlight off, 300 s panel
  dimmed to 1 % (its "set 10"), 630 s display off, 1200 s suspend. The Omarchy **screensaver is
  disabled** on this box (`omarchy-toggle-enabled screensaver-off`), which is why the dim step is
  in `swayidle` and not left to `idle.screensaver` — that key is a no-op now, and without the dim
  the panel jumped straight from full brightness to DPMS-off. Re-enabling the screensaver would
  put the art back at the same 300 s point. Device names differ from the IdeaPad:
  `tpacpi::kbd_backlight` and `amdgpu_bl1`. Pane cycling moved off `prefix+tab`/`prefix+shift+tab`
  in herdr, which now own tab navigation (see the herdr commit).
- **`shell.json` is patched by a script, not tracked**: `run_onchange_after_45-omarchy-desktop.sh`
  sets the idle values and the plugin/bar registration (sujal.lock enabled, omarchy.lock
  disabled, sujal.workspaces and sujal.monitor in the bar) idempotently with jq, then asks the
  shell to reload. A deliberate bar edit therefore survives until the script's own content
  changes.
- **Package-picker placement is fixed and verified** — `ebbef01` puts the pickers on the
  scratchpad, shows/focuses it while they are up, and closes it again when the last one exits.
  Verified through the menu itself (Install → Package → Return), plus AUR and Remove, two
  pickers closing one at a time, and the wrapper install flows staying put. Details and the
  re-verification recipe: `docs/pkg-install-terminal-scratchpad.md`.
- **`.claude/settings.json` is rewritten by Claude Code itself** (it inlines the `hooks` block
  and re-indents). The tracked file is still the superset; `chezmoi status` showing it as
  modified after a Claude Code session is that rewrite, not lost config.
- **`superwhisper-panel` must NOT be removed** (the old item 6 below said to): the app is
  installed (`superwhisper-bin 1.2.0-1`), the plugin ships with it from
  `/opt/superwhisper/assets/omarchy-plugin/`, and it is already live in the bar's tray section.
- **The screen turning off mid-typing was the lid switch, not idle.** logind logged
  `Lid closed. / Suspending…` three times in nine minutes (20:43, 20:49, 20:51 — the last one
  suspended for 9 s), and the kernel logged
  `ACPI: button: [Firmware Bug]: Unexpected lid state reported by firmware`. The ACPI driver
  turns a repeated same-state notification into a *complement* "closed" event, so a spurious
  firmware notification reads as a lid close. Nothing to do with `idle.*` — input was arriving
  the whole time, and the `owed` wallpaper daemon only *reacts* to the resulting
  `dpms-off`/`locked`/`sleep` states.
  - **Was the charger involved?** All three flaps happened with AC plugged in, and the ACPI log
    also carries EC firmware errors (`\_SB.PCI0.LPC0.EC0.HKEY.MSCB`, `AE_NOT_FOUND`, at every
    resume), so an EC/firmware trigger that only fires under charge is plausible — but nothing in
    the log ties a lid notification to a power event, and the EC errors are a known T14/BIOS
    problem on their own. The charger was unplugged at 21:10; **if the flaps stop now, the trigger
    is AC/EC-side; if they continue, it is the switch (or the firmware `_LID` handler) itself.**
    That is the discriminator to watch, so no logind change is committed yet.
  - **The fix depends on that answer.** `HandleLidSwitchExternalPower=ignore` only helps
    while charging; `HandleLidSwitch=ignore` (suspend from the menu instead) is the only setting
    that survives a phantom event on battery. A BIOS update is the other candidate — this
    machine still runs R1BET87W 1.56, and the `HKEY`/`MSCB` errors are exactly the kind of thing
    a later EC firmware fixes.
- **Separate finding, same boot: the fingerprint reader re-enumerates constantly.** `usb 4-3`
  (`06cb:00bd`, Synaptics) resets every few minutes — 30+ times since 18:37, including at
  20:49:30 and 20:51:47, i.e. right after the first two lid flaps, and again at 21:05. That is
  also why the lock screen logged `Verification timed out` at 20:50:24 before the fingerprint
  finally authenticated. Unrelated to the lid suspends, worth its own look if the reader misbehaves
  under `fprintd`.
- **The external BenQ was disconnected at the DRM level during this session**
  (`/sys/class/drm/card1-HDMI-A-1/status` = `disconnected`, so Hyprland has only `eDP-1`). Not a
  config problem — check the cable/monitor power. Consumer of that fact: the live
  `monitors.lua` now carries `scale = 1.25` and `GDK_SCALE = 1` (the display widget's
  `persist_scale` rewrite at 20:22), and that live state was mirrored into the repo rather than
  reverted. Say which pair is wanted long-term (1.5/2 or 1.25/1).
- **The modified-file list is down from 11 to 8, and none of it is content drift:**
  - `~/.config/hypr/looknfeel.lua`, `~/.config/hypr/monitors.lua` — repo and live byte-identical.
  - `~/.config/herdr/config.toml` — live's `onboarding = false` ported into
    `.chezmoitemplates/herdr-config.toml.tmpl` (the shared template, not the rendered file); the
    template's `reload_config`/`rename_workspace` comment written into live. Renders and parses
    as TOML.
  - `~/.config/opencode/tui.jsonc` — the template now renders exactly what opencode writes back
    (object expanded, plugin array inline; the Windows branch carries `vimcode` on one line).
    The old render drifted after every opencode session.
  - `~/.config/omarchy/plugins/sujal.lock/poster.sh` — content was identical; chezmoi normalises
    plain files to 644, so the source is now `executable_poster.sh` and the clone keeps
    upstream's exec bit. (`bash poster.sh` means 644 works too — this is fidelity, not function.)
  - `.bashrc`, `.claude/settings.json` — nothing to do, the tracked files are supersets.
- **`docs/` was missing from `.chezmoiignore`** — the first `apply` would have created `~/docs`,
  the exact trap `AGENTS.md` warns about. Added.

## Still to do (in order)

1. **Remaining drift after the first apply** is small and understood: the always-run scripts
   (`05-herdr-plugin-sync`, `20-herdr-plugin-install`) show `R` on every status, and
   `.claude/settings.json` shows `M` whenever Claude Code has rewritten its own formatting.
   Nothing left needs a decision.
2. **Watch the lid switch, then pick the logind policy.** The flaps stopped being explained the
   moment the charger came out (see above) — let a day of unplugged use answer whether it is
   AC/EC-correlated or the switch. Then either `/etc/systemd/logind.conf.d/30-lid.conf` with
   `[Login]` + `HandleLidSwitchExternalPower=ignore` (only the AC case) or
   `HandleLidSwitch=ignore` (no lid suspends at all; suspend from the menu), and verify with
   `busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
   org.freedesktop.login1.Manager HandleLidSwitchExternalPower`. A BIOS update past R1BET87W
   1.56 is the other candidate — the EC `HKEY`/`MSCB` errors are firmware-side.
3. **Decide the display pair** that should stay in `monitors.lua`, once the cable is back (the
   external is deliberately unplugged for now): external `1.25` with `GDK_SCALE = 1` (what the
   display widget last wrote, now mirrored in the repo) or back to `1.5`/`2`. Tracked in
   `TODO.md`.
4. **`swayidle` cannot read logind's inhibitor list** (`Failed to parse get BlockInhibited
   property: Invalid argument`, swayidle 1.9 vs current systemd), so app-held idle inhibitors do
   not stop the display-off/suspend steps. Tracked in `TODO.md` as an open fix; until then, drop
   the suspend step if it starts interrupting something.
5. **Merge mechanics:** rebase/squash `t14` onto `main`, keep `machine_kind = "t14"` as the
   laptop value (do not resurrect `"arch"`), keep the `wpc`/`vps` branches, and drop `main`'s
   hypr monolith (`dot_config/hypr/hyprland.lua`, `hypridle/hyprlock/hyprpaper.conf`,
   `new-example-hyprland.conf`) since the user-module layout supersedes it. Keep the
   `arch-aliasrc` filename: its contents are pacman/Wayland aliases, still accurate. Note that
   `main`'s `hypridle.conf` is the file whose timings were ported in this branch — keep it in
   the history so the numbers have a provenance, but do not deploy it.
6. **Post-merge cleanup:** `superwhisper-panel` stays (app-owned, live in the bar — see above),
   `sujal.monitor` stays (the 1.5 preset is wanted), and the remaining check is that no test-only
   binds/scaffolding survived.
7. **Docs:** README's tracked-files table now covers the hypr user modules, the `sujal.*` plugin
   clones, zed, `docs/`, and the idle setup (done 2026-11-07). Left for the merge itself: refresh
   the `Branches` section once `t14` is `main`, and drop the migration framing from it.

## Gotchas that will bite (all learned the hard way; details in `learnings.md`)

- `o.bind` on an already-bound key leaves **both** actions live — use `o.rebind` or `hl.unbind`.
- Number-row workspace binds are **keycode** binds (`SUPER + code:10..19`); rebinding them by
  keysym adds a second bind instead of replacing.
- Never track `~/.config/hypr/hyprland.lua`; replacing it kills every Omarchy default.
- `omarchy-refresh-config <path>` overwrites tracked files (`ghostty`, `herdr`, `opencode`) —
  don't run it on chezmoi-owned paths.
- Hyprland's `misc:middle_click_paste` must stay `false`, else middle-click pastes into the
  *focused* window instead of the terminal under the cursor.
- `omarchy-hyprland-monitor-scaling` re-applies a monitor with `position = "auto"`; the clone
  reloads afterwards, and the external's rule must stay on one line so `persist_scale` can edit
  its scale.
- `udev` rules that set `TAG+="uaccess"` must sort **before** `73-seat-late.rules`
  (`70-kanata.rules`), or the ACL never lands.
- The `sujal.*` plugin clones import Omarchy-internal QML modules; an update can break them.

## Definition of done for the merge

`chezmoi apply` on a clean Omarchy install reproduces the setup with no manual steps beyond
`chezmoi init`; `hyprctl configerrors` empty; `omarchy-shell shell ping` ok; herdr reloads with
no diagnostics; kanata active; bar shows only occupied workspaces with icons; external display
lands above with the reserved strip; and `main` fast-forwards without resurrecting the monolith.
