# TODO

- **t14 lid switch suspends the machine mid-work (open, 2026-11-07).** logind logs `Lid closed.`
  → `Suspending…` on phantom lid events; the kernel says `ACPI: button: [Firmware Bug]:
  Unexpected lid state reported by firmware` (a repeated same-state `_LID` notification is turned
  into a complement "closed" event). Full diagnosis in `learnings.md` and
  `docs/t14-merge-handoff.md`. All three flaps seen so far happened with the charger connected,
  and the ACPI log carries EC firmware errors (`HKEY.MSCB`, `AE_NOT_FOUND`) — unplugged as of
  21:10 as a discriminator: flaps stop ⇒ AC/EC-side, continue ⇒ switch or firmware.
  **Fix, once that is known:** `/etc/systemd/logind.conf.d/` drop-in with
  `HandleLidSwitchExternalPower=ignore` (only while charging) or `HandleLidSwitch=ignore` (no lid
  suspends; suspend from the menu); a BIOS update past R1BET87W 1.56 is the other candidate.
  Cannot be deployed from this repo — it lives outside `$HOME`.
- **swayidle cannot read logind's inhibitor list (open, 2026-11-07).** Startup always logs
  `Failed to parse get BlockInhibited property: Invalid argument` (swayidle 1.9 against current
  systemd). Consequence: an app that holds an idle inhibitor (video player, presentation mode)
  still hits the 630 s display-off and 1200 s suspend. Options: drop the suspend step and rely on
  the menu, patch/watch for a swayidle update, or replace the daemon with something that parses
  the current systemd property (`PrepareForSleep` inhibitors are visible via
  `systemd-inhibit --list`). Re-check after the next `omarchy update`.
- **t14 external display**: the BenQ was disconnected at the DRM level
  (`card1-HDMI-A-1: disconnected`) and the cable is out for now. When it goes back, decide the
  pair in `monitors.lua`: live/repo currently carry external `1.25` + `GDK_SCALE 1` (written by
  the display widget), the IdeaPad-era value was `1.5` + `2`.
- **Synaptics fingerprint reader re-enumerates constantly** (`06cb:00bd` on `usb 4-3`, 30+ resets
  in two hours on 2026-11-07). Also makes lock-screen fingerprint auth flaky (`Verification timed
  out` before it succeeds). Not investigated yet.
- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
    - definitely add zed config
- omarchy `shell.json` (bar layout, idle timings) — **decided 2026-11-07: not tracked; patched by
  script.** Omarchy rewrites the file itself whenever the bar is edited from its own UI/menu, so a
  tracked copy drifts after every such change. `run_onchange_after_45-omarchy-desktop.sh.tmpl`
  instead sets only the keys this repo owns (idle values, plugin enable/disable, bar layout
  entries) with jq, idempotently, and reloads the shell. Same reasoning applies to
  `~/.config/omarchy/extensions/omarchy-menu.jsonc` if it ever needs local rows.
- omarchy bar: **custom resource-monitoring plugin** (CPU / temperature / RAM / disk, the waybar
  modules that have no first-party equivalent). Bar widgets are QML plugins under
  `~/.config/omarchy/plugins/`; wanted: same minimal, clickable UI as the shipped widgets —
  icon in the bar, popup on click. Also the only route to "only show occupied workspaces" is
  cloning `omarchy.workspaces` and trimming `workspaceIds()` (it always seeds the monitor's
  first five slots); not done yet.
- lock screen: cloned to `~/.config/omarchy/plugins/sujal.lock` (own id, `omarchy.lock`
  disabled) with clock/date/battery added to `LockView.qml`; battery % in the bar via
  `omarchy.power`'s `showPercentage` in `shell.json`. The clone is a plain copy — `omarchy
  plugin update` never touches it, so upstream lock changes must be ported by hand. Not
  tracked in chezmoi yet; worth adding if it settles. **Cloned plugins depend on omarchy's
  internal QML modules (`qs.Commons`, `qs.Ui`, `Style`, `Commons.Color.*`), which are not a
  stable API** — after a big omarchy update, re-check `omarchy-shell lock status` and the
  journal for "failed for sujal.lock".
- on vps, make hermes use webclaw instead of firecralwl(?) though check comparisons first
- include browser config, extensions configs too?
    - tridactyl (replaces vimium): basic rc tracked in `dot_config/tridactyl/tridactylrc`
      (2026-10-24, arch only). Migrate/add later:
        - vimium custom key mappings -> `bind` lines
        - search engines -> `set searchurls.*`; source from `dot_config/search-engines/custom-engines.json`
          so aliases aren't maintained twice (maybe generate from it)
        - decide `set newtab about:blank` (tridactyl overrides new tab page by default?)
        - optional `guiset` UI hiding (needs native messenger, writes userChrome.css)
        - windows: rc now deploys to `~/.config/tridactyl/` there too (no longer ignored).
          Verify tridactyl finds it (docs: also checks `~/_tridactylrc`), install native messenger
        - ~~verify tridactyl reads firefox search keywords~~ checked 2026-10-24: it doesn't
          (`open` only matches `searchurls` keys, else `searchengine`). Must define `searchurls`.
    - extension settings backups in `~/backups/firefox/` (untracked, outside repo): Dark Reader,
      LeechBlock, uBlock static filters, Redirector, UltimaDark, Vimium (see its `readme.txt`).
      Today restored by hand via each extension's import UI. Future: track them in the repo and
      either (a) auto-apply on `chezmoi apply` (extension storage lives in profile
      `browser-extension-data/` / `storage/default/moz-extension+++*/`, fragile, uuid per profile),
      or (b) find alternatives with file-based config like tridactyl (e.g. uBlock via filter-list
      URL / managed storage policy, Dark Reader and others via enterprise `policies.json` managed
      storage where the extension supports it). Check which of them support managed storage first.
- vet nvim plugins for security, if really necessary
    - need to slowly build nvim config. just ask AI to help
- ~~firefox profile configs for performance~~ done 2026-08-29: `dot_config/firefox-tweaks/user.js`
    + `run_onchange_after_60-browser-user-js-sync.py.tmpl` symlinks it into Firefox/Waterfox
    profiles automatically, t14-only for now. css, sideberry still TODO.
- ~~switch wpc (windows) to Waterfox too, extend firefox-tweaks auto-apply script to cover
    it~~ done 2026-08-31: `run_onchange_after_60-browser-user-js-sync.py.tmpl` now handles
    Windows -- `%APPDATA%\Mozilla\Firefox\` / `%APPDATA%\Waterfox\` profile dirs, a
    `[interpreters.py]` entry in `.chezmoi.toml.tmpl`, and a copy fallback when
    `os.symlink` fails (no admin/Developer Mode). **Untested on a real Windows box** --
    treat the first run there as a dry run, check the printed output before trusting it.
    `scripts/sync-search-engines.py` also got Windows paths + `tasklist`-based process
    detection, but stays manual-only by design (see its own docstring) -- run it yourself
    after `chezmoi apply` on a new device, don't expect chezmoi to do it. css, sideberry
    still TODO.
- replace bash w/ zsh on vps.
    - compare if anything useful from bashrc should be inherited
    - will prob need separate zsh configs for laptop and vps?
- ~~find some way to automate npx skills installation~~ done 2026-08-22: per-agent
    symlinking into `~/.agents/skills` now automated via
    `run_onchange_after_40-skill-symlinks.sh.tmpl` (opencode needs none, reads that dir
    natively; hermes symlink still TODO in that script pending its install-method rework).
    The other half (auto-running `npx skills add` for CLI-only skills) is moot -- those
    skills were removed from the repo/machines.
- fd ignorefile isn't being used in linux currently. should fix
- ~~herdr pane-mover on windows~~ done 2026-10-07: "windows" added to its
    `platforms` in a local clone, linked, bind set. Since 2026-10-15 it's installed from
    the `gursuj/herdr-pane-mover` fork (desired-plugins.txt) and the local clone is
    deleted. Switch the slug back to `osamahbeig/herdr-pane-mover` once the
    upstream platforms PR/issue is merged.
- ~~merge `dot_claude/writing-preferences.md` (personal, drafted 2026-09-22 from a trac
    comment edit) with WPC's writing-voice prefs (wpc-os repo) into one doc. Then make
    sure it's actually referenced by agents, not just sitting in the repo~~ done
    2026-09-22: merged into `dot_claude/writing-preferences.md`, wpc-os's `_my-work`
    copy left as a pointer. `CLAUDE.md` (untracked, personal) now references it. For
    opencode: turns out it falls back to `~/.claude/CLAUDE.md` on its own, but doesn't
    follow file references inside it — so added an explicit `instructions` entry in
    `dot_config/opencode/opencode.jsonc` pointing straight at the file.

- **`~/.config/omarchy/shell.json` is not tracked, so plugin clones are half-applied.**
    `sujal.lock`, `sujal.workspaces` and `sujal.monitor` are in the repo under
    `dot_config/omarchy/plugins/`, but a fresh machine also needs their `bar.layout` entry
    and enabled-list registration in `shell.json` — otherwise the files land and nothing
    shows. Deciding whether to track `shell.json` means weighing that against Omarchy
    rewriting it on shell/plugin updates: if it is tracked, expect conflicts after an
    `omarchy` package update and re-apply the intended deltas (bar layout positions,
    `showPercentage`, enabled plugins) rather than taking either side wholesale.
