# TODO

- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
    - definitely add zed config
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
    profiles automatically, arch-only for now. css, sideberry still TODO.
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
- `battbench` (`private_dot_local/bin/executable_battbench`, arch-only, added 2026-10-31):
  A/B power configs by avg watts + joules per fixed task, not wall-clock. Usage:
  `battbench <label> [idle_min]`, unplugged, same brightness/apps each run, order A-B-A.
  Needs edits before it's trustworthy on the ThinkPad:
    - temp: reads AMD `Tctl` via `sensors`; Intel shows `Package id 0` (match both)
    - boost: `cpufreq/boost` is AMD/acpi-cpufreq; `intel_pstate` uses
      `/sys/devices/system/cpu/intel_pstate/no_turbo` (inverted: 1 = off)
    - also log EPP (`cpufreq/energy_performance_preference`) and
      `/sys/firmware/acpi/platform_profile`, they matter under load on modern drivers
    - battery: confirm `BAT0` has `energy_*` + `power_now` (some report `charge_*`/`current_*`)
    - first run = stock profile baseline, before installing TLP or auto-cpufreq
  Findings on the old IdeaPad (Ryzen 3250U, acpi-cpufreq): `powersave` pinned 1.4 GHz and
  doubled task time; `schedutil` fixed it. TLP vs auto-cpufreq was a wash (within noise).
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
