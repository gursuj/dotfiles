# Handoff: local-wpcli (wp-cli fix for Local by Flywheel on Linux)

## Origin

Came out of reproducing WP core trac ticket [#53529](https://core.trac.wordpress.org/ticket/53529)
in `~/programming/git-cloned/wordpress-develop`. Needed a local WP install to
test against, set one up in Local (site: `wp-core-dev`), and immediately hit
`wp` (WP-CLI) failing with `Error: Error establishing a database connection.`
against that site — even though the site itself worked fine in the browser.

## Root cause

Local (on Linux, using its native "Lightning" services rather than Docker)
runs **each site's own bundled PHP-FPM and MySQL instance**, each on a
per-site Unix socket under `~/.config/Local/run/<run-id>/`. The host's `wp`
binary (installed via `pacman -S wp-cli`, package `wp-cli`, binary at
`/usr/bin/wp`) runs against the **host's** PHP and `php.ini`, which has no
idea that per-site socket exists. `wp-config.php`'s `DB_HOST` can't be edited
to fix this — the DB is genuinely only reachable through Local's own bundled
PHP binary for that site (its `php.ini` sets `mysqli.default_socket` etc. to
the right path).

There is only **one** `wp` binary involved throughout all of this — the
pacman one. Nothing here replaces it; everything just changes *which PHP
interpreter* executes it. Don't uninstall the pacman `wp-cli` package.

## What got built

All in `~/.config/shell/local-wpcli/`:

| File | Purpose |
|---|---|
| `wpl` | Standalone script: `wpl <site-name> <wp-cli-args...>`. Works from anywhere, explicit site name. Symlinked to `~/.local/bin/wpl`. |
| `wp-shell-integration.sh` | Bash function that shadows `wp`, auto-detecting the Local site from `$PWD` (`.../<site-name>/app/public`). Sourced from `~/.bashrc`. |
| `wp-shell-integration.zsh` | Same, zsh syntax (mainly: `type -P` → `whence -p`, `BASH_REMATCH` → `$match`). Sourced from `~/.zshrc`. |
| `README.md` | User-facing usage docs. |

All three resolve a site name → run-id via `~/.config/Local/sites.json` →
that site's `php.ini` under `~/.config/Local/run/<run-id>/conf/php/` → which
PHP version that site's live `php-fpm` process is actually running (checked
via `/proc/<pid>/exe`, since Local lets each site pick its own PHP version)
→ execs `/usr/bin/wp` through that PHP binary with `LD_LIBRARY_PATH` pointed
at that PHP version's bundled shared libs (needed, or you get
`error while loading shared libraries: libtidy.so...`).

## Wiring (already done)

`~/.bashrc`:
```bash
[ -f ~/.config/shell/local-wpcli/wp-shell-integration.sh ] && source ~/.config/shell/local-wpcli/wp-shell-integration.sh
```

`~/.zshrc`:
```bash
[ -f "$HOME/.config/shell/local-wpcli/wp-shell-integration.zsh" ] && source "$HOME/.config/shell/local-wpcli/wp-shell-integration.zsh"
```

Both fall straight through to the real `/usr/bin/wp` (untouched, on host
PHP) when `$PWD` isn't inside a recognized Local site path, or if any lookup
step fails — so normal `wp` usage elsewhere is unaffected.

## Why both bash AND zsh

Daily shell is zsh. But Local's "Open Site Shell" feature hardcodes
launching **bash** on Linux (`gnome-terminal -e "/bin/bash $@"` — see
below), regardless of login shell. So the bash version fixes `wp` inside
that feature specifically; the zsh version fixes it for normal
manually-`cd`'d-into-a-site terminal use.

## Related, separate issue: "Open Site Shell" not opening at all

Independent, older, already-documented problem: Local hardcodes launching
`gnome-terminal` on Linux, which doesn't exist on non-GNOME setups (Hyprland
here). Already worked around before this session started, via a shim script
at `~/.config/shell/gnome-terminal` (that dir is on `$PATH` ahead of
anywhere `gnome-terminal` would otherwise be found):

```bash
#!/bin/bash
exec /usr/bin/ghostty -e "/bin/bash $@"
```

This is the documented fix from
[stackoverflow.com/q/67719856](https://stackoverflow.com/q/67719856) (2021),
just swapping `konsole` for `ghostty`. Confirmed this shim is correct and
matches the accepted answer's pattern — it was **not** the thing broken;
what still looked "broken" after using it was actually the DB-socket issue
above (the shell opened fine, `wp` inside it still failed) — now fixed by
`wp-shell-integration.sh`.

## Prior art check (already done, don't duplicate)

Before building this, checked whether it's worth publishing standalone.
Conclusion: no — already covered by
[github.com/asharirfan/local-wpcli](https://github.com/asharirfan/local-wpcli)
(npm package, same core approach, built specifically for Local's Linux
"Lightning" services, actively maintained), plus Local's own community forum
threads documenting the root cause and workarounds (hardcoding a socket path
into `DB_HOST`, or "Open Site Shell" itself). Nothing here needed to be
reported upstream as new.

## Verification

```bash
# Confirm only one wp binary exists, owned by pacman
pacman -Qo /usr/bin/wp

# Confirm the function activates inside a Local site, and which PHP it uses
zsh -i -c "cd '/home/sujal/Local Sites/wp-core-dev/app/public' && set -x && wp option get siteurl" 2>&1 | grep lightning-services

# Confirm clean fallback outside a Local site
zsh -i -c "cd /tmp && wp --version"
```

Both bash and zsh versions tested working (site-detection path + fallback
path) as of 2026-09-18, against `wp-core-dev`.

## Follow-up fix: `wp db *` commands (2026-09-18)

`wp plugin list` etc worked from the start, but `wp db check` (and
`db export`/`db import`/anything shelling out to `mysqlcheck`/`mysqldump`/
`mysql`) still failed. Two separate bugs, both now fixed in `wpl`,
`wp-shell-integration.sh`, and `wp-shell-integration.zsh`:

1. **`LD_LIBRARY_PATH` leak breaks `sh`.** wp-cli's db commands shell out via
   `/bin/sh -c`. The `LD_LIBRARY_PATH` we set (needed only so the exec'd PHP
   binary finds Local's bundled shared libs) is inherited by that child `sh`,
   whose dynamic linker then picks up Local's bundled `libreadline.so.8`
   instead of the host's — an incompatible ABI, missing symbols the host
   `sh` needs (`symbol lookup error: sh: undefined symbol:
   rl_trim_arg_from_keyseq`). Fixed via a new file,
   `unset-ld-library-path.php`, loaded as `auto_prepend_file`: it calls
   `putenv('LD_LIBRARY_PATH')` once PHP's own libs are already resolved
   (safe — the dynamic linker doesn't need the var again after that), so it
   no longer propagates to child processes.

2. **No `mysql`/`mysqlcheck`/`mysqldump` on host at all**, and even pointed
   at Local's bundled copies (matched to the site's running `mysqld` version
   the same way PHP version is matched — via `/proc/<pid>/exe`), they failed
   to connect: `wp-config.php` has `DB_HOST => 'localhost'`, which makes
   mysql client tools use a Unix socket — but with no socket path given they
   fall back to the compiled-in default `/tmp/mysql.sock`, not Local's
   per-site socket. Fixed by adding that site's mysql `bin/linux/bin` to
   `PATH`, and setting `MYSQL_UNIX_PORT` to the site's actual socket
   (`$RUN_DIR/mysql/mysqld.sock`).

Verified working: `db check`, `db size`, `db tables`, `db export`, plus
regression-checked `plugin list`, `user list`, `theme list`, `cron event
list`, `transient list`, `search-replace --dry-run`, `core check-update`,
and the outside-a-site fallback path.

## Known limitations

- Target site must be **running** (its php-fpm process up) — the run-id
  directories only exist while Local has the site started.
- If a site was renamed in Local (name in `sites.json` no longer matches its
  folder under `~/Local Sites/`), name-based lookup may resolve stale. Rare
  in practice.
- Detection is purely path-based (`.../<name>/app/public`) — a site whose
  folder structure deviates from Local's default layout won't be picked up.
