# TODO

- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
    - definitely add zed config
- omarchy `shell.json` / `shell.toml` (bar layout, idle timings) — version-control candidate,
  deliberately not tracked yet. Caveat: omarchy rewrites `~/.config/omarchy/shell.json` itself
  when the bar is changed from its own UI/menu, so tracking it means a drift diff after every
  such change — treat it as "re-add after a deliberate change", not as a file that stays in sync.
  Same applies to `~/.config/omarchy/extensions/omarchy-menu.jsonc`.
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
