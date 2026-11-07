# Handoff — Omarchy package-installer terminal still opens on the current workspace

Status: **open, deliberately not fixed yet.** Whoever picks this up starts from here; nothing
below needs re-discovery.

## The ask

Omarchy's menu has two package pickers ("Install package" from pacman/omarchy repos, and the
AUR one). They spawn a **floating terminal**. The goal: those windows must always land on the
**scratchpad** special workspace instead of appearing on the workspace that is currently
focused.

## Where things live

| Path | What it is |
|---|---|
| `/usr/share/omarchy/bin/omarchy-pkg-install` | the picker itself (`fzf` TUI, `omarchy:requires-sudo=true`) |
| `/usr/share/omarchy/bin/omarchy-pkg-aur-install` | the AUR picker (same shape) |
| `/usr/share/omarchy/bin/omarchy-launch-floating-terminal-with-presentation` | the wrapper the menu uses: `exec setsid uwsm-app -- xdg-terminal-exec --app-id=org.omarchy.terminal --title=Omarchy -e bash -c "omarchy-show-logo; <cmd>; omarchy-show-done"` |
| `~/.config/hypr/looknfeel.lua` | **chezmoi-tracked** user file; the rule currently lives at the bottom under "window rules" |
| `~/.config/hypr/hyprland.lua` | Omarchy's entry point — never edit, never track (it requires the five user modules) |

This machine: ThinkPad T14, Omarchy 4.5, Hyprland **0.56.2** (Lua config, `hyprctl keyword`
does not work — use `hyprctl eval` / `hl.*`). chezmoi work is on branch `t14` of
`~/.local/share/chezmoi`.

## What is already in place

Rule at the bottom of `~/.config/hypr/looknfeel.lua`:

```lua
o.window({
  class = "^(org\\.omarchy\\.terminal)$",
  title = "^(Omarchy|omarchy-pkg-(aur-)?install|omarchy-pkg-remove)$",
}, {
  float = true,
  center = true,
  size = { 1000, 620 },
  workspace = "special:scratchpad silent",
})
```

(`o.window` is Omarchy's helper — it passes through to `hl.window_rule`; `workspace = "... silent"`
is the same form Omarchy uses itself, e.g. `apps/system.lua` sends the screensaver to
`special:screensaver silent`.)

Evidence gathered so far:

- Spawning a window with the **same class/title by hand** works:
  `hyprctl dispatch 'hl.dsp.exec_cmd("ghostty --class=org.omarchy.terminal --title=Omarchy -e sleep 20")'`
  → `hyprctl clients -j` shows it on `special:scratchpad`, floating. ✔
- Spawning it through the real menu action still lands on the focused workspace. ✘
- The window's `title` is "Omarchy" at map time (the wrapper sets it) and only *later* becomes
  the command name (`omarchy-pkg-install`) — that was one already-fixed bug (the rule used to
  match only the post-rename title).
- `hyprctl configerrors` is empty, so this is a matching/timing problem, not a syntax problem.

## Leading hypotheses (in order)

1. **The app-id arrives late.** The previous machine's Hyprland config had a note that Ghostty
   sets its class/app-id *after* the surface is mapped, so a `class`-based rule misses it and
   the window is placed before the class is known. `initial_class` / `initial_title` matching
   (or `match:initial_class`) is the classic workaround, if this Hyprland build supports it.
2. **`xdg-terminal-exec` + `uwsm-app` indirection.** The wrapper does not exec Ghostty directly;
   `uwsm-app` may spawn the terminal through a session bus activation, which changes ordering
   (and possibly the transient class the compositor sees first).
3. **`workspace ... silent` on a rule may be ignored when the window is floated and centered**
   by the same rule, or when the client is already placed by the `auto-up`/`center` path.
4. The `title` **changes again** after the rule has run (bash sets it from the running command),
   and something re-maps the window on a workspace change.

## Suggested investigation

```bash
# 1. See the real client's fields, immediately and again a second later
hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-pkg-install")'   # or trigger it from the menu
hyprctl clients -j | jq '.[] | {class, initialClass, title, initialTitle, workspace: .workspace.name, floating}'
sleep 1
hyprctl clients -j | jq '.[] | select(.class|test("omarchy")) | {class, initialClass, title, initialTitle, workspace: .workspace.name}'

# 2. Which fields differ between the menu-spawned window and the manual test window?
#    (take the same snapshot for `ghostty --class=org.omarchy.terminal --title=Omarchy`)

# 3. Does a class-only rule work? Comment out the `title` matcher and retest.
#    Then try matching initial_class instead of class.

# 4. Does the workspace assignment work on its own (drop float/center/size) for a
#    menu-spawned window? Is it the workspace key or the combination that fails?

# 5. Fallback worth trying if rules cannot win the race: an event hook in a user file, e.g.
#    hl.on("window.open", ...) that checks the class and moves the window itself.
#    (qconsole.lua has an example of hl.on("workspace.created", ...) with hl.exec_cmd workspace opts.)
```

Useful references: `/usr/share/omarchy/default/agents/skills/omarchy/*.md` documents the Lua
API; `/usr/share/omarchy/default/hypr/apps/*.lua` has rule examples; `hl.window_rule` /
`hl.workspace_rule` are used in `default/hypr/windows.lua` and `qconsole.lua`.

## Constraints

- **Do not edit `/usr/share/omarchy/**`** — package-owned, wiped by updates.
- Keep edits in the user modules (`bindings.lua`, `looknfeel.lua`, `monitors.lua`,
  `autostart.lua`); `hyprland.lua` is off limits and ignored by chezmoi.
- The change is chezmoi-tracked on branch `t14`: edit the live file, verify, copy to
  `dot_config/hypr/`, commit.
- Don't break other Omarchy floating terminals (plugin installer, btop, the qconsole agent).
  If the fix ends up class-wide, confirm those still open where they should.
- Verify with `hyprctl configerrors` (must stay empty) and by actually opening the menu entry —
  a hand-spawned window proving the rule is *not* sufficient evidence here, that already passed.

## Definition of done

Opening either package picker from the Omarchy menu leaves the focused workspace untouched and
the window appears on the scratchpad when it is toggled (`SUPER+S`). Window stays floating and
centred, `hyprctl configerrors` empty, other Omarchy floating terminals unaffected.
