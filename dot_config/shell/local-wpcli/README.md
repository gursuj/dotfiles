# local-wpcli

A `wp-cli` wrapper for [Local by Flywheel](https://localwp.com/) sites on Linux.

## The problem

On Linux, `wp` (WP-CLI) installed via the system package manager runs against
your **host** PHP, using your host `php.ini`. Local's sites don't run on your
host PHP — each site gets its own bundled PHP-FPM and its own bundled MySQL
instance, each listening on a per-site Unix socket under
`~/.config/Local/run/<run-id>/`.

Your host `php.ini` has no idea that socket exists, so any `wp` command run
against a Local site's `wp-config.php` fails with:

```
Error: Error establishing a database connection.
```

This is not fixable by editing `wp-config.php`'s `DB_HOST` — the DB is only
reachable through Local's own PHP binary (whose bundled `php.ini` sets
`mysqli.default_socket` etc. to the right per-site path).

## The fix

Run WP-CLI through Local's *own* PHP binary and php.ini for that specific
site, instead of your host PHP. That's all `wpl` does:

1. Look up the site's run-id from `~/.config/Local/sites.json` (matched by
   site name).
2. Find that site's `php.ini` under `~/.config/Local/run/<run-id>/conf/php/`.
3. Find which PHP version that site's `php-fpm` is actually running (Local
   lets each site pick its own PHP version), and locate that version's
   bundled binary + shared libs under
   `~/.config/Local/lightning-services/php-<version>/`.
4. `cd` into the site's docroot (`<site path>/app/public`) and exec `wp`
   through that PHP binary, with `LD_LIBRARY_PATH` pointed at the bundled
   shared libs (needed or you'll hit `error while loading shared libraries:
   libtidy.so...` — those libs aren't on your system's normal library path).

## Requirements

- The target Local site must be **started** (its php-fpm process running) —
  the run-id directories only exist while a site is running.
- `python3` (used to parse `sites.json`).

## Usage

### Option 1: `wpl` — explicit site name, works anywhere

```bash
wpl <site-name> <wp-cli-args...>

# examples
wpl wp-core-dev user list
wpl wp-core-dev theme activate twentytwentyone
wpl my-client-site option get siteurl
```

`<site-name>` is the name Local shows in its site list (same as the
`*.local` domain minus `.local`).

### Option 2: transparent `wp` — auto-detects the site from your cwd

Once wired in (see Install), plain `wp` works normally as long as you're
`cd`'d into a Local site's docroot (`.../<site-name>/app/public`) — no need
to remember `wpl` or the site name. Outside a Local site path, or if lookup
fails for any reason, it falls straight through to the real `wp` untouched.

This also fixes `wp` inside Local's **"Open Site Shell"** on Linux, which on
its own only solves half the problem (see below) — even once that shell
opens, running `wp` inside it hits the same DB-socket error unless this is
wired in too.

## Install

`wpl` — symlinked into `~/.local/bin/wpl` (already on `$PATH`):

```bash
ln -sf ~/.config/shell/local-wpcli/wpl ~/.local/bin/wpl
```

Transparent `wp` — sourced from your shell rc file(s). Local's "Open Site
Shell" always launches **bash** regardless of your login shell, so if you
want it fixed there too, this needs to be in `.bashrc` even if you use zsh
day-to-day:

```bash
# ~/.bashrc (fixes `wp` inside Local's "Open Site Shell")
[ -f ~/.config/shell/local-wpcli/wp-shell-integration.sh ] && source ~/.config/shell/local-wpcli/wp-shell-integration.sh

# ~/.zshrc (fixes `wp` in normal interactive use, if you cd into a Local site manually)
[ -f ~/.config/shell/local-wpcli/wp-shell-integration.zsh ] && source ~/.config/shell/local-wpcli/wp-shell-integration.zsh
```

### Aside: "Open Site Shell" not opening at all

If clicking "Open Site Shell" does nothing, that's a separate, older,
well-documented issue — Local hardcodes launching `gnome-terminal` on Linux,
which doesn't exist on non-GNOME setups. Fix: put a script named
`gnome-terminal` earlier in your `$PATH` that execs your actual terminal
instead, e.g.:

```bash
#!/bin/bash
exec /usr/bin/ghostty -e "/bin/bash $@"
```

(swap `ghostty` for `konsole`, `alacritty`, etc.) See
https://stackoverflow.com/q/67719856 for the original report.

## Known limitation (db commands)

`wp db *` commands (`check`, `export`, `import`, etc.) shell out to
`mysqlcheck`/`mysqldump`/`mysql`. This wrapper finds Local's bundled copies
matching the site's running MySQL version, and points them at the site's
actual socket. Same requirement as above: the site must be running.

## Known limitation

If you renamed a site inside Local (name in `sites.json` no longer matches
the folder under `~/Local Sites/`), lookup by name may resolve to the wrong
or a stale path. Rare in practice — Local keeps these in sync.
