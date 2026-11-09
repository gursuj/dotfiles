# Auto backup Everdo db daily

Tracked in chezmoi. `chezmoi apply` deploys everything below except step 2.

Files:
- `~/.config/everdo/everdo-auto-backup`: script (sqlite `.backup`, skips if db unchanged, keeps last 10)
- `~/.config/systemd/user/everdo-auto-backup.service`: oneshot, runs the script (`%h` = home, no hardcoded path)
- `~/.config/systemd/user/everdo-auto-backup.timer`: daily 06:00, `Persistent=true` catches up after a missed run

Backups land in `~/.config/everdo/backups/` as `db_backup_<date>_<time>.sqlite`.

## Setup on a new machine

1. `chezmoi apply`
2. Enable the timer (not the service):
```sh
systemctl --user daemon-reload
systemctl --user enable --now everdo-auto-backup.timer
```

## Check

```sh
systemctl --user list-timers everdo-auto-backup.timer
systemctl --user start everdo-auto-backup.service   # run now
journalctl --user -u everdo-auto-backup.service
ls ~/.config/everdo/backups
```
