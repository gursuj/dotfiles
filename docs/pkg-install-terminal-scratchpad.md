# Package-installer terminal on the scratchpad

Status: **fixed and verified on the T14** (2026-11-07, Omarchy 4.5, Hyprland 0.56.2). The rule
and the close hook live in `~/.config/hypr/looknfeel.lua`, mirrored byte-for-byte into
`dot_config/hypr/looknfeel.lua` on branch `t14`.

Behaviour: triggering a picker from the menu **shows and focuses** the scratchpad with the picker
on it; when the last picker closes, the scratchpad is closed again and the user is back on the
workspace they were on. Anything else parked on the scratchpad stays parked.

## The ask

Omarchy's menu has three package pickers ("Install → Package" from the pacman/omarchy repos,
"Install → AUR", and "Remove → Package"). They spawn a **floating terminal**; the windows must
land on the **scratchpad** instead of on the focused workspace, without disturbing the other
floating terminals Omarchy launches.

## What was actually wrong

The previous rule did match on the title the window has at map time — on the wrong surface:

| Launcher | Menu rows | Title at map | Class |
|---|---|---|---|
| `xdg-terminal-exec --app-id=org.omarchy.terminal <cmd>` (no `--title`) | `install.package`, `install.aur`, `remove.package` | the terminal's own title — `Ghostty`, renamed to `omarchy-pkg-install` a moment later | `org.omarchy.terminal` |
| `omarchy-launch-floating-terminal-with-presentation '<cmd>'` → `… --title=Omarchy` | every *install* flow (`omarchy-install-browser …`, `setup.plugin.add`, …) | `Omarchy` | `org.omarchy.terminal` |

Two consequences:

1. **The pickers never matched.** Their map-time title is `Ghostty`; the rule alternated on
   `^(Omarchy|omarchy-pkg-(aur-)?install|omarchy-pkg-remove)$`. Hyprland evaluates window rules
   at map only, so the later rename to `omarchy-pkg-install` re-triggers nothing — confirmed: the
   window sat on the focused workspace with its final title already applied.
2. **The hand-spawn that "proved" the rule worked was a different launcher.** A manual
   `ghostty --class=org.omarchy.terminal --title=Omarchy …` mimics the *wrapper* path, which the
   pickers do not use. That is why the rule looked correct while the menu still misbehaved.

A third, quieter finding: `float`/`center`/`size = {1000, 620}` in the old rule were **inert**.
`/usr/share/omarchy/default/hypr/apps/system.lua` tags `org.omarchy.terminal` as a
`floating-window` (float, centre, **875×600**), and that packaged tag rule wins over the user
size — measured at 875×600 on both paths, with and without the user rule matching.

## The fix

```lua
o.window({
  class = "^(org\\.omarchy\\.terminal)$",
  title = "negative:^(Omarchy)$",
}, {
  workspace = "special:scratchpad",          -- no `silent`: the scratchpad opens and focuses
})

hl.on("window.close", function(window)        -- …and closes again with the last picker
  if not window or window.class ~= "org.omarchy.terminal" then return end
  if not (window.workspace and window.workspace.name == "special:scratchpad") then return end
  local closed = tostring(window.address)

  hl.timer(function()
    for _, other in ipairs(hl.get_workspace_windows("special:scratchpad") or {}) do
      if other.class == "org.omarchy.terminal" and tostring(other.address) ~= closed then
        return
      end
    end
    local focused = hl.get_active_window()
    if focused and focused.workspace and focused.workspace.name == "special:scratchpad" then
      hl.dispatch(hl.dsp.workspace.toggle_special("scratchpad"))
    end
  end, { type = "oneshot", timeout = 60 })
end)
```

- **Class is a safe key.** Only these three menu rows and the presentation wrapper ever use
  `org.omarchy.terminal` (`grep -R` over `/usr/share/omarchy`: `apps/system.lua`,
  `apps/terminals.lua`, `omarchy-menu.jsonc`). btop is `org.omarchy.btop`, TUIs are `TUI.float`,
  the console agent is `org.omarchy.agent`.
- **Title is negated, not enumerated.** The wrapper always sets `--title=Omarchy`; everything
  else with this class is a picker. `negative:` is Hyprland's own regex negation and is already
  used by Omarchy (`default/hypr/workspace-modes.lua:232`), so the rule stays terminal-agnostic —
  no literal `"Ghostty"` that dies when the default terminal changes.
- **No `silent`.** `silent` means "park it, leave the view alone", which is exactly the
  complaint that made this a bug report: the picker ran somewhere invisible. Dropping it opens
  and focuses the scratchpad on the picker's monitor.
- **No float/center/size.** Omarchy's tag rule already floats, centres and sizes this class;
  repeating a size here is silently overridden (see above).
- **The close hook is what makes showing the scratchpad survivable.** Hyprland closes a special
  workspace by itself only when it is *empty*; this desk keeps a terminal parked on the
  scratchpad, so without the hook cancelling a picker left the user staring at the scratchpad.
  The hook fires only for a window the rule parked there (the wrapper's install flows share the
  class and are excluded by the workspace check), waits one loop so a second picker opening
  straight after does not lose the view, and only closes the scratchpad when it is what the
  user is looking at. `toggle_special` returns to the regular workspace that was underneath.

Known edge: if the scratchpad was *already* open when the picker was triggered (i.e. the user
was working in it), it is closed once the picker exits rather than left open. Acceptable — the
parked windows are still there behind `SUPER+S` — but that is the one case where the hook takes
something away rather than restoring it.


## Where things live

| Path | What it is |
|---|---|
| `/usr/share/omarchy/bin/omarchy-pkg-install` | the picker itself (`fzf` TUI, `omarchy:requires-sudo=true`) |
| `/usr/share/omarchy/bin/omarchy-pkg-aur-install` | the AUR picker (same shape) |
| `/usr/share/omarchy/bin/omarchy-pkg-remove` | the removal picker (same shape) |
| `/usr/share/omarchy/bin/omarchy-launch-floating-terminal-with-presentation` | the wrapper used by the *install* flows: `exec setsid uwsm-app -- xdg-terminal-exec --app-id=org.omarchy.terminal --title=Omarchy -e bash -c …` |
| `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` | the three picker rows (lines 269, 290, 365) and every wrapper-launched install row |
| `/usr/share/omarchy/default/hypr/apps/system.lua` | floats/centres/sizes `org.omarchy.terminal` via the `floating-window` tag |
| `~/.config/hypr/looknfeel.lua` | **chezmoi-tracked** user file; the rule sits under "window rules" |
| `~/.config/hypr/hyprland.lua` | Omarchy's entry point — never edit, never track |

On this build `hyprctl keyword` does not work (non-legacy parser): use `hyprctl eval` for
object-shaped settings and `hyprctl dispatch 'hl.dsp.exec_cmd("…")'` to launch GUI apps.

## Evidence (2026-11-07)

Windows were polled at 100 ms with
`hyprctl clients -j | jq '.[] | select(.class=="org.omarchy.terminal")'`:

| Spawned | `workspace.name` | `floating` | focused ws | scratchpad view |
|---|---|---|---|---|
| `xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-install` | `special:scratchpad` on the first frame (title still `Ghostty`) | true, 875×600 | unchanged (`13`) | opened, picker focused |
| `… omarchy-pkg-aur-install` | `special:scratchpad` | true, 875×600 | unchanged | opened, picker focused |
| `… omarchy-pkg-remove` | `special:scratchpad` | true, 875×600 | unchanged | opened, picker focused |
| `omarchy-launch-floating-terminal-with-presentation 'sleep 10'` | `13`, as before | true, 875×600 | unchanged | untouched |
| `xdg-terminal-exec --app-id=org.omarchy.btop -e sleep 6` | `13` | true | unchanged | untouched |
| `ghostty -e sleep 6` (`com.mitchellh.ghostty`) | `13` | false | unchanged | untouched |

Focus and return, measured with `hyprctl monitors -j` (`specialWorkspace.name`),
`hyprctl activeworkspace` and `hyprctl activewindow`:

| Scenario | on open | on close |
|---|---|---|
| scratchpad hidden, a terminal parked on it (this desk's real state) | `special=special:scratchpad`, `activewindow = org.omarchy.terminal` | `special=` (hidden), back on `13`, focus on the window that had it, parked terminal still on the scratchpad |
| scratchpad hidden and empty | shown, picker focused | hidden by Hyprland itself; the hook no-ops because focus is no longer on the scratchpad |
| two pickers, closed one at a time | shown, second picker focused | first close: stays open with the other picker; last close: hidden, back on `13` |
| wrapper install flow (`sleep 8`) | stays on `13`, focused there | back on `13`; the hook does not fire (window is not on the scratchpad) |

The menu path was also exercised for real, not just by running the action string:
`omarchy menu summon install` → Return on the highlighted "Package" row (sent with
`wtype -k Return`) opened `omarchy-pkg-install` on `special:scratchpad` with the scratchpad
shown, while the workspace underneath kept its two windows; cancelling it (`wtype -k Escape`)
closed the scratchpad and returned focus to the Hermes window. The menu runs a row with
`Util.execDetached(command)` (`shell/plugins/menu/Menu.qml`), i.e. the same shell command a
dispatch runs, so the CLI tests and the menu test agree by construction.

`hyprctl configerrors` is empty after `hyprctl reload`.


## Re-check / when this breaks again

- **If the pickers ever move to the presentation wrapper**, their map-time title becomes
  `Omarchy` and this rule stops matching (they go back to the focused workspace). Fix it then by
  giving them a distinct `--app-id` through a menu-extension override
  (`~/.config/omarchy/extensions/omarchy-menu.jsonc` reuses the row id and overrides `action`)
  and matching that class, rather than by widening the negative title.
- **Re-verify through the menu, not by hand**: a hand-spawned `--title=Omarchy` window tests the
  wrapper path and passes even when the pickers are broken.
- **The close hook depends on behaviour no API reports directly.** There is no Lua query for
  "is this special workspace shown" (`window.monitor.specialWorkspace` is nil in this build, and
  `hl.on("workspace.special_active")` does not fire for a rule-driven switch), so the hook infers
  it from "the focused window sits on `special:scratchpad`". If a Hyprland update changes focus
  handling for special workspaces, the symptom is the picker closing without the scratchpad
  closing — visible, not silent.
- Omarchy rewrites nothing here — it is a user file — but `omarchy refresh` of
  `~/.config/hypr/looknfeel.lua` would drop the rule and the hook; the chezmoi source is the copy
  of record.

## Constraints that still hold

- Never edit `/usr/share/omarchy/**` — package-owned, wiped by updates.
- Keep edits in the user modules (`bindings.lua`, `looknfeel.lua`, `monitors.lua`,
  `autostart.lua`); `hyprland.lua` is off limits and ignored by chezmoi.
- Edit the live file, verify, then mirror into `dot_config/hypr/` and `diff -q` the pair.

## Re-verification recipe

```bash
# 0. point hyprctl at the live session (a compositor restart leaves a stale signature)
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -d /run/user/$UID/hypr/* | tail -1 | xargs basename)

# 1. spawn exactly what the menu row runs, then read the client back
hyprctl dispatch 'hl.dsp.exec_cmd("xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-install")'
sleep 1
hyprctl clients -j | jq '.[] | select(.class=="org.omarchy.terminal") | {title, workspace: .workspace.name, floating, size}'
#    …and check it is actually on screen and has the keyboard
hyprctl monitors -j | jq -r '.[] | "\(.name) special=\(.specialWorkspace.name)"'
hyprctl activewindow -j | jq -r '.class'

# 2. the wrapper path must NOT be parked
hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-floating-terminal-with-presentation '"'"'sleep 10'"'"'")'
sleep 1
hyprctl clients -j | jq '.[] | select(.title=="Omarchy") | {workspace: .workspace.name}'

# 3. the close hook: cancel the picker and confirm the scratchpad closes with it
wtype -k Escape; sleep 2
hyprctl monitors -j | jq -r '.[] | "\(.name) special=\(.specialWorkspace.name)"'   # empty on the picker's monitor
hyprctl activeworkspace -j | jq -r .name                                           # back on the regular workspace

# 4. cleanup: kill by address (never `pkill -f omarchy-pkg-install` — the pattern matches the
#    agent's own bash -c and kills the call)
hyprctl dispatch "hl.dsp.window.kill({ window = 'address:0x…' })"
```

Useful references: `/usr/share/omarchy/default/agents/skills/omarchy/*.md` documents the Lua
API; `/usr/share/omarchy/default/hypr/apps/*.lua` has rule examples; `hl.window_rule` /
`hl.workspace_rule` are used in `default/hypr/windows.lua` and `qconsole.lua`.
