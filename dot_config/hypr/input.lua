-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.
--
-- Ported from the IdeaPad (branch main) on 2026-11-07: the t14 had inverted
-- scrolling because Omarchy ships touchpad.natural_scroll = false and this file
-- carried no overrides. Its commented examples live in
-- /usr/share/omarchy/default/hypr/input.lua if they are wanted back.
hl.config({
  input = {
    sensitivity = -0.04,
    scroll_button_lock = true,
    repeat_delay = 280,
    touchpad = {
      natural_scroll = true, -- content follows the fingers
      scroll_factor = 0.22,  -- Omarchy's 0.4 is nearly twice as fast
    },
  },
})

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "omarchy:shift_caps_compose,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
-- o.window("foot", { scroll_touchpad = 2.0 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Touchpad gestures already live in ~/.config/hypr/bindings.lua (the
-- "touchpad gestures" block): 3-finger swipe changes workspace, up is
-- fullscreen, down floats. Do not register them here — a second registration is
-- reported as "Gesture will be overshadowed by a previous gesture" and only
-- adds configerrors noise.

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
