---
name: dotfiles
description: "Use when the user wants to view, edit, or add to their dotfiles/config tracking — e.g. 'edit my dotfiles', 'where's my nvim config', 'add X to dotfiles', 'what configs do I have tracked', or any request to find or modify a personal config file location."
---

# Dotfiles

User maintains a running note of scattered Windows config file locations, meant to
eventually be consolidated into a proper cross-platform dotfiles repo.

**Reference file:** `C:\Users\User\Documents\obsidian\dotfiles.md`

This is the single source of truth — it lives directly in the Obsidian vault (no symlink
involved; an earlier symlink setup was abandoned because Windows blocks non-admin symlink
creation unless Developer Mode is on). Always read and edit this file directly at that path.

## When to use this skill

- User wants to edit a dotfile/config but doesn't remember the path → check this file first.
- User just set up or reconfigured a tool with a config file → add an entry here.
- User asks "what do I have tracked" or similar → read and summarize this file.

## Workflow

1. Read `C:\Users\User\Documents\obsidian\dotfiles.md` before hunting for config paths elsewhere.
2. If the tool/config isn't listed yet, search for it (common Windows locations: `%APPDATA%`,
   `%LOCALAPPDATA%`, `~\.config\`, `~\Documents\`) and add an entry once found, following the
   existing table format (one `##` heading per tool, `| File | Path |` table).
3. When adding an entry, verify the path actually exists before writing it down.
4. If a config directory turns out to be its own git repo (like the nvim config), note the
   remote URL alongside the path — useful context for the eventual consolidation.

## Phase-out in progress

As of 2026-08-10, the chezmoi repo described below exists (`~/.local/share/chezmoi`,
local-only for now, remote to be added by User) and is the real dotfiles consolidation.
This skill and `dotfiles.md` are being phased out in favour of the chezmoi repo's own
README, which is now the source of truth for what's tracked and why. Until every entry in
`dotfiles.md` has a home in the chezmoi repo (or an explicit "stays machine-local, not
tracked" note), keep using this skill and file as before — just check the chezmoi repo
README first if the question is "is X already tracked in the real repo."

For any config already tracked in chezmoi, use the edit-source-first workflow: edit the source `.tmpl`/file under `~/.local/share/chezmoi` and run `chezmoi apply` — don't hand-edit the live target path, it gets overwritten on next apply. Don't reach for `chezmoi re-add` as a shortcut instead — it doesn't work on templated files and can clobber template logic. See the chezmoi repo README's "Using chezmoi" section for the full workflow writeup.

## Future direction (historical — chezmoi is now set up, see above)

User wants to eventually move these into one real dotfiles git repo that works on both
Windows and Linux. Raw symlinks (e.g. GNU Stow) are a weak fit here — Windows symlink creation
needs admin/Developer Mode, which is exactly the friction this note exists to avoid. Chezmoi
is a better candidate: it copies/templates files into place instead of symlinking, and
supports per-OS templating for paths that differ between Windows and Linux.
