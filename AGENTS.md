# Agent notes for this repo

This is a chezmoi source repo — see `README.md` for the workflow (edit-source-first,
`chezmoi apply`, never hand-edit rendered `.tmpl` targets).

Before making changes here, also read `learnings.md` — a dated log of resolved issues,
corrections, and decisions (nvim/yazi/fd cross-platform paths, herdr config resolution,
plugin-manager patterns, what's deliberately not tracked and why). It exists so past
mistakes aren't repeated and past reasoning isn't silently overwritten.

Note: this file, `CLAUDE.md`, `learnings.md`, `TODO.md`, and `README.md` all live at the
repo root with no `dot_` prefix — chezmoi's naming convention would otherwise try to
`apply` them straight into `$HOME` (e.g. `~/AGENTS.md`). They're repo-only docs, not
dotfiles to deploy, so all five are listed in `.chezmoiignore`. Add any future root-level
doc file there too, or it'll get applied somewhere it shouldn't.
