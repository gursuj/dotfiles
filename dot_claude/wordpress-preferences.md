# WordPress Preferences & Environment

## WP-CLI on Local by Flywheel

Local bundles its own PHP and WP-CLI — not on system PATH by default. Must activate the site shell before any `wp` command.

Site shell scripts: `%USERPROFILE%\AppData\Roaming\Local\ssh-entry\`
Each site has a `.bat` and `.sh` pair. Grep the `.sh` files for the site name to find the right one.

### example-site.local (script: MR4vbFkFi.bat)

```powershell
$env:MYSQL_HOME = "C:\Users\User\AppData\Roaming\Local\run\MR4vbFkFi\conf\mysql"
$env:PHPRC = "C:\Users\User\AppData\Roaming\Local\run\MR4vbFkFi\conf\php"
$env:WP_CLI_CONFIG_PATH = "C:\Program Files (x86)\Local\resources\extraResources\bin\wp-cli\config.yaml"
$env:WP_CLI_DISABLE_AUTO_CHECK_UPDATE = "1"
$env:PATH = "C:\Windows\Sysnative;C:\Windows\Sysnative\OpenSSH;C:\Users\User\AppData\Roaming\Local\lightning-services\mysql-8.0.35+4\bin\win64\bin;C:\Users\User\AppData\Roaming\Local\lightning-services\php-8.2.29+0\bin\win64;C:\Program Files (x86)\Local\resources\extraResources\bin\wp-cli\win32;C:\Program Files (x86)\Local\resources\extraResources\bin\composer\win32;C:\Users\User\AppData\Roaming\Local\lightning-services\php-8.2.29+0\bin\win64\ImageMagick;" + $env:PATH
cd "D:\wp-sites\example-site\app\public"
```

For a different site, read its `.bat` from the ssh-entry folder to get the correct run ID and service versions.

## Accessing *.local sites via CLI (curl, agent-browser, etc.)

Local writes both `::1` (IPv6) and `127.0.0.1` (IPv4) entries to the Windows hosts file for every site, in a `## Local - Start ##` / `## Local - End ##` block. Local's router usually only binds IPv4, so the `::1` entry connects (TCP handshake succeeds) but never responds — this hangs curl/Chrome/agent-browser until timeout instead of failing fast, since it looks like a live connection, not a dead one.

Local rewrites this whole block on every site start/stop, so removing the `::1` lines from the hosts file is a temporary fix at best — they come back on next restart. Don't bother editing the hosts file for this; use one of these instead when a `*.local` site hangs on connect:

- **curl:** force IPv4 resolution, bypassing the `::1` entry: `curl --resolve sitename.local:80:127.0.0.1 http://sitename.local/`
- **curl (simpler):** `curl -4 http://sitename.local/` forces IPv4 globally for the request
- **Host header via IP directly:** `curl -H "Host: sitename.local" http://127.0.0.1/` — skips hostname resolution entirely
- **agent-browser:** same idea — hit `http://127.0.0.1/` with a `--headers '{"Host":"sitename.local"}'` flag, or use curl's `--resolve` trick if the tool being driven shells out to curl

Symptom to recognize: `curl -v` shows `Established connection to X.local (::1 port 80)` followed by a long hang and eventual timeout with 0 bytes received — that's this issue, not a genuinely down site. Confirm Local is actually running before assuming site is broken.
