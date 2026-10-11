<?php
// Loaded via auto_prepend_file. PHP's own shared libs are already resolved by
// the dynamic linker before this runs, so unsetting here is safe — it just
// stops LD_LIBRARY_PATH (needed only to exec this PHP binary) from leaking
// into child processes wp-cli shells out to (e.g. `wp db check` -> mysqlcheck
// via `sh -c`), where Local's bundled libreadline.so.8 breaks the host's sh.
putenv('LD_LIBRARY_PATH');
unset($_SERVER['LD_LIBRARY_PATH'], $_ENV['LD_LIBRARY_PATH']);
