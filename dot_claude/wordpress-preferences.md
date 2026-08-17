# WordPress Preferences & Environment

## WP-CLI on Local by Flywheel

Local bundles its own PHP and WP-CLI — not on system PATH by default. Must activate the site shell before any `wp` command.

Site shell scripts: `%USERPROFILE%\AppData\Roaming\Local\ssh-entry\`
Each site has a `.bat` and `.sh` pair. Grep the `.sh` files for the site name to find the right one.

### amp.local (script: MR4vbFkFi.bat)

```powershell
$env:MYSQL_HOME = "C:\Users\User\AppData\Roaming\Local\run\MR4vbFkFi\conf\mysql"
$env:PHPRC = "C:\Users\User\AppData\Roaming\Local\run\MR4vbFkFi\conf\php"
$env:WP_CLI_CONFIG_PATH = "C:\Program Files (x86)\Local\resources\extraResources\bin\wp-cli\config.yaml"
$env:WP_CLI_DISABLE_AUTO_CHECK_UPDATE = "1"
$env:PATH = "C:\Windows\Sysnative;C:\Windows\Sysnative\OpenSSH;C:\Users\User\AppData\Roaming\Local\lightning-services\mysql-8.0.35+4\bin\win64\bin;C:\Users\User\AppData\Roaming\Local\lightning-services\php-8.2.29+0\bin\win64;C:\Program Files (x86)\Local\resources\extraResources\bin\wp-cli\win32;C:\Program Files (x86)\Local\resources\extraResources\bin\composer\win32;C:\Users\User\AppData\Roaming\Local\lightning-services\php-8.2.29+0\bin\win64\ImageMagick;" + $env:PATH
cd "D:\wp-sites\amp\app\public"
```

For a different site, read its `.bat` from the ssh-entry folder to get the correct run ID and service versions.
