-- Change the default Omarchy look'n'feel.

-- t14: no gaps, 1px borders; everything else stays Omarchy's (blur, rounding,
-- border colours). Ported from the IdeaPad, which ran gaps 0 / border 1; colours
-- and blur are deliberately left to Omarchy so theme updates keep working.
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
  },
  -- Pressing the bind for the workspace you are already on jumps to the last
  -- focused one. This is Hyprland's own option (it is what the IdeaPad config
  -- used); the digit binds themselves stay Omarchy's o.workspaces.focus().
  -- Replacing the binds with a Lua callback that read hl.get_active_workspace()
  -- and hl.get_last_workspace() left SUPER+1..0 doing nothing at all, so the
  -- native option is used instead -- see learnings.md.
  binds = {
    workspace_back_and_forth = true,
  },
  -- Hyprland's own middle-click paste (default true) synthesises a paste into
  -- the *focused* window, so middle-clicking a terminal on a special/scratchpad
  -- workspace pasted into whatever window sat behind it. Off => the click
  -- reaches the client and Ghostty's own middle-click-action decides.
  misc = {
    middle_click_paste = false,
  },
})

-- Screenshots: omarchy-capture-screenshot (omasnap) saves into this dir.
-- Replaces the IdeaPad's HYPRSHOT_DIR.
hl.env("OMARCHY_SCREENSHOT_DIR", (os.getenv("HOME") or "") .. "/Pictures/screenshots")

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

----------------------------------------------------------------
-- window rules
----------------------------------------------------------------
-- Omarchy's package pickers (pacman/omarchy repos and the AUR one) open in a
-- floating terminal. Park them on the scratchpad, and *show* the scratchpad
-- while they are up: they are interactive fzf TUIs, so a window parked silently
-- reads as "the menu item did nothing".
--
-- The menu runs these two without the presentation wrapper
-- (`xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-install`, no
-- --title), so the window maps with the terminal's own title -- "Ghostty"
-- here -- and only later renames itself to the command it runs. Matching the
-- command name, or the wrapper's "Omarchy" title, never fires.
--
-- Everything else with this class comes from
-- omarchy-launch-floating-terminal-with-presentation, which always sets
-- --title=Omarchy (plugin install, omarchy-install-*, ...). Those are the
-- flows the user just triggered from the menu, so they must keep landing on
-- the focused workspace: the title matcher is a *negative* one for that
-- reason. It is also terminal-agnostic, unlike listing "Ghostty".
--
-- Float, centre and size are deliberately not repeated here: Omarchy's own
-- apps/system.lua tags org.omarchy.terminal as a floating-window (875x600,
-- centred), and a size in this rule would be ignored anyway -- the packaged
-- tag rule wins.
--
-- No `silent`: the picker is an interactive fzf TUI, so the scratchpad is
-- opened and focused on the same monitor when it maps -- otherwise the window
-- lands hidden and looks like nothing happened. SUPER+S still closes it.
o.window({
  class = "^(org\\.omarchy\\.terminal)$",
  title = "negative:^(Omarchy)$",
}, {
  workspace = "special:scratchpad",
})

-- Coming back out. Showing the scratchpad means it is on screen while the picker
-- runs, and Hyprland only closes a scratchpad by itself when it is empty -- this
-- desk keeps a terminal parked there. So when the last picker on the scratchpad
-- closes and the scratchpad is what the user is looking at, close it again:
-- `toggle_special` returns to the workspace that was active underneath, and
-- whatever is parked stays parked (SUPER+S brings it back).
--
-- Guards: only windows parked on the scratchpad by the rule above qualify (the
-- wrapper's install flows share the class and must not trigger this), and only
-- when no other picker is still open there.
hl.on("window.close", function(window)
  if not window or window.class ~= "org.omarchy.terminal" then return end
  if not (window.workspace and window.workspace.name == "special:scratchpad") then return end
  local closed = tostring(window.address)

  -- a picker that closes right after another one opens would otherwise steal
  -- the view from the picker still on screen, so decide one loop later
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
