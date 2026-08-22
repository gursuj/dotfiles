# TODO

- add configs from arch laptop, and maybe old: https://github.com/gursuj/dotfiles-old-arch
    - definitely add zed config
- on vps, make hermes use webclaw instead of firecralwl(?) though check comparisons first
- include browser config, extensions configs too?
- vet nvim plugins for security, if really necessary
    - need to slowly build nvim config. just ask AI to help
- firefox profile configs for performance, css, sideberry?
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
