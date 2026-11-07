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

- **Package-picker placement is fixed and verified** — `ebbef01` puts the pickers on the
  scratchpad, shows/focuses it while they are up, and closes it again when the last one exits.
  Verified through the menu itself (Install → Package → Return), plus AUR and Remove, two
  pickers closing one at a time, and the wrapper install flows staying put. Details and the
  re-verification recipe: `docs/pkg-install-terminal-scratchpad.md`.
- **The modified-file list is down from 11 to 8, and none of it is content drift:**
  - `~/.config/hypr/looknfeel.lua` — repo and live byte-identical.
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

1. **`chezmoi init`, then a staged `apply`.** It has never run here: `~/.config/chezmoi/`
   holds only `key.txt`, so there is no `chezmoi.toml` and no cached `machine_kind`. Verified
   pending (2026-11-07, throwaway config, `machine_kind = t14`): **113 creates, 8 modifications,
   8 script runs**. The age key is present and `0600`, so `cliamp`/`tidemail`/`.ssh` decrypt.
   The 8 modifications and why none of them loses live work:
   - `.bashrc`, `.claude/settings.json` — tracked versions are **supersets** of live (see item
     2). Applying *adds* the wp-cli source line / the full Claude Code config.
   - `.config/opencode/cli.json` — source is `private_cli.json` (600), live is 644; apply
     tightens the mode, content identical.
   - `.local`, `.local/share` — source is `private_dot_local` (700), live is 755; apply
     tightens the directory mode. Nothing inside is affected.
   - `.config/omarchy/plugins/sujal.workspaces` — plain dir in source (755), live clone is 700;
     apply widens it. Cosmetic.
2. **`.claude/settings.json` is a superset, not a conflict.** Live is 196 bytes: just the
   `SessionStart` hook running `herdr-agent-state.sh session`. The tracked file carries that
   same hook block plus `model`, `permissions`, `statusLine`, `enabledPlugins`,
   `extraKnownMarketplaces`, `theme`, `tui`, `outputStyle`, `skillOverrides` and friends. No
   key exists only in live, so applying loses nothing.
3. **`shell.json` is still untracked**, so the three plugin clones (`sujal.lock`,
   `sujal.workspaces`, `sujal.monitor`) land as files but never get registered — a fresh
   machine shows nothing. Decide whether to track `shell.json` (conflicts on Omarchy updates)
   or add an idempotent `run_onchange` script that patches the bar layout. See `TODO.md`.
4. **First-apply side effects to expect:** `30-antidote-install.sh` installs antidote (network)
   — that is what finally makes `~/.zshrc` usable; `35-cch-install.sh` rebuilds `ch`
   (already installed on this box, harmless); `10-yazi-pkg-install.sh` self-skips; skill
   symlinks + browser `user.js` sync run (`python-lz4` is installed); `~/.local` and
   `~/.local/share` get chmod'ed 700 by their `private_` names.
5. **Merge mechanics:** rebase/squash `t14` onto `main`, keep `machine_kind = "t14"` as the
   laptop value (do not resurrect `"arch"`), keep the `wpc`/`vps` branches, and drop `main`'s
   hypr monolith (`dot_config/hypr/hyprland.lua`, `hypridle/hyprlock/hyprpaper.conf`,
   `new-example-hyprland.conf`) since the user-module layout supersedes it. Keep the
   `arch-aliasrc` filename: its contents are pacman/Wayland aliases, still accurate.
6. **Post-merge cleanup:** remove the leftover `~/.config/omarchy/plugins/superwhisper-panel`
   (its app is uninstalled), decide whether `sujal.monitor` (1.5 preset) is worth keeping over
   stock 1.6, and confirm no test-only binds/scaffolding survived.
7. **Docs:** README's tracked-files table now covers the hypr user modules, the `sujal.*` plugin
   clones, zed and `docs/` (done 2026-11-07). Left for the merge itself: refresh the `Branches`
   section once `t14` is `main`, and drop the migration framing from it.

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
