---
name: wrapup
description: End-of-session wrap: update docs, flag loose ends, offer a handoff.
---

# Wrap up

Use at the end of a session or task, or when the user says wrap / wrap up / done / that's it.

Report only what is true from this session: what changed, what is left, what needs them. No
summary of the conversation, no praise, no "great progress".

## 1. Snapshot the change

```bash
git status --short
git log --oneline -10        # or <session-start>..HEAD if a ref is known
git diff --stat
```

Add files edited outside git this session (live configs under `~/.config`, skills, system units).

## 2. Update what the session made wrong

Docs and comments that now lie get fixed in the same commit: README tables, TODO entries, dated
learnings notes, handoff docs, the comment above the thing you changed. Nothing else — no prose
polish, no new sections nobody asked for.

If the project defines a check (template render, `hyprctl configerrors`, `herdr config check`,
`<tool> validate-config`), run it and report the output, not the claim.

## 3. Flag loose ends

One line each, saying what unblocks it:

- uncommitted or unpushed work — name the branch
- a decision still waiting on the user
- something only they can do (sudo, GUI, hardware, a login)
- an approach that did not work, so it is not retried

## 4. Offer a handoff — do not write one unasked

If the loose ends will outlive this chat, offer `docs/<topic>-handoff.md` in the repo's existing
shape: the ask in one sentence, a table of files/commands involved, what is already in place, what
was tried and what that rules out, ranked hypotheses, the exact next commands, constraints, and a
definition of done. Ask before writing it.

## 5. Next steps

Optional, and only when the order matters: at most three bullets, each tied to something above.
Otherwise state what is blocked on what and stop.

## Do not

- commit, push, apply, deploy or install unless asked in this turn
- claim it works without the command output that shows it
- repeat the conversation back, or list files you did not touch
- invoke `/clear` (Claude Code) — tell the user to type it
