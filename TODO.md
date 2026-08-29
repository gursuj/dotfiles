# TODO

- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
    - definitely add zed config
- on vps, make hermes use webclaw instead of firecralwl(?) though check comparisons first
- include browser config, extensions configs too?
- vet nvim plugins for security, if really necessary
    - need to slowly build nvim config. just ask AI to help
- ~~firefox profile configs for performance~~ done 2026-08-29: `dot_config/firefox-tweaks/user.js`
    + `run_onchange_after_60-browser-user-js-sync.py.tmpl` symlinks it into Firefox/Waterfox
    profiles automatically, arch-only for now. css, sideberry still TODO.
- switch wpc (windows) to Waterfox too, and extend the firefox-tweaks auto-apply script to
    cover it -- currently gated to arch only in the sync script. Windows quirks to handle:
    - profile dirs live under `%APPDATA%\Mozilla\Firefox\` / `%APPDATA%\Waterfox\` instead of
      `~/.mozilla/firefox` / `~/.waterfox`, but same `profiles.ini` format, so detection logic
      carries over
    - `.chezmoi.toml.tmpl` only maps a `sh` interpreter for windows (git-bash) -- the sync
      script is Python (`.py.tmpl`), needs a `[interpreters.py]` entry added or a rewrite in sh
    - `os.symlink` on Windows needs admin/Developer Mode -- may need a copy fallback instead of
      a symlink when that's unavailable
    - untested: no Windows box available when this was built, so treat first run there as a
      dry run before trusting it
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
