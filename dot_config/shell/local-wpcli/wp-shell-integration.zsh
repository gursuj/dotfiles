# zsh port of wp-shell-integration.sh — see that file's header for why.
# Source from ~/.zshrc:
#   source ~/.config/shell/local-wpcli/wp-shell-integration.zsh

wp() {
    local real_wp
    real_wp=$(whence -p wp)
    if [ -z "$real_wp" ]; then
        echo "wp: command not found" >&2
        return 127
    fi

    local site_path
    site_path=$(pwd -L)

    # Match .../<site-name>/app/public(/...)  — Local's standard docroot layout
    if [[ "$site_path" =~ '/([^/]+)/app/public(/|$)' ]]; then
        local site_name="${match[1]}"
        local sites_json="$HOME/.config/Local/sites.json"

        if [ -f "$sites_json" ]; then
            local run_id
            run_id=$(python3 -c "
import json
d = json.load(open('$sites_json'))
for k, v in d.items():
    if v.get('name') == '$site_name':
        print(k)
        break
" 2>/dev/null)

            if [ -n "$run_id" ]; then
                local run_dir="$HOME/.config/Local/run/$run_id"
                local php_ini="$run_dir/conf/php/php.ini"

                if [ -f "$php_ini" ]; then
                    local php_fpm_pid
                    php_fpm_pid=$(pgrep -f "php-fpm: master process.*$run_id" | head -1)

                    if [ -n "$php_fpm_pid" ]; then
                        local php_fpm_exe php_version_dir php_bin libs
                        php_fpm_exe=$(readlink -f "/proc/$php_fpm_pid/exe")
                        php_version_dir=$(dirname "$(dirname "$(dirname "$(dirname "$php_fpm_exe")")")")
                        php_bin="$php_version_dir/bin/linux/bin/php"
                        libs="$php_version_dir/bin/linux/shared-libs:$php_version_dir/bin/linux/lib"

                        # Same idea for MySQL: find which mysqld binary this site's DB
                        # actually runs, so `wp db *` (mysqlcheck/mysqldump/mysql via
                        # sh -c) uses matching client tools instead of host PATH
                        # (usually nothing at all).
                        local mysql_bin="" mysql_sock="$run_dir/mysql/mysqld.sock"
                        local mysqld_pid
                        mysqld_pid=$(pgrep -f "mysqld.*$run_id" | head -1)
                        if [ -n "$mysqld_pid" ]; then
                            local mysqld_exe mysql_version_dir
                            mysqld_exe=$(readlink -f "/proc/$mysqld_pid/exe")
                            mysql_version_dir=$(dirname "$(dirname "$(dirname "$(dirname "$mysqld_exe")")")")
                            mysql_bin="$mysql_version_dir/bin/linux/bin"
                        fi

                        # auto_prepend_file unsets LD_LIBRARY_PATH once PHP's own libs
                        # are loaded, so it doesn't leak into child processes wp-cli
                        # shells out to (e.g. `db check` -> mysqlcheck via sh -c),
                        # which breaks under Local's bundled libreadline.
                        # MYSQL_UNIX_PORT points mysql client tools at this site's
                        # socket (DB_HOST is 'localhost', so they'd otherwise fall back
                        # to the compiled-in default /tmp/mysql.sock and fail).
                        local prepend="$HOME/.config/shell/local-wpcli/unset-ld-library-path.php"
                        PATH="$mysql_bin:$PATH" MYSQL_UNIX_PORT="$mysql_sock" LD_LIBRARY_PATH="$libs" "$php_bin" -d auto_prepend_file="$prepend" -c "$php_ini" "$real_wp" "$@"
                        return $?
                    fi
                fi
            fi
        fi
    fi

    # Not inside a recognized Local site, or lookup failed — behave like normal wp-cli.
    "$real_wp" "$@"
}
