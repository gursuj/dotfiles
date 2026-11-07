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
