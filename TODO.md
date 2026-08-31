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
