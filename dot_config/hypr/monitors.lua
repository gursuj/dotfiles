-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Monitor scale is Hyprland's scale for the output. It sizes everything
-- Wayland-native, accepts fractions (1.6, 1.75), and applies immediately.
-- "auto" lets Hyprland pick per display.
local omarchy_monitor_scale = "auto"
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- GDK scale is GDK_SCALE, the factor GTK draws its own UI at. It's what
-- sizes X11/XWayland windows, which Omarchy leaves unscaled so they stay
-- crisp instead of being stretched by the compositor. GTK only honors whole
-- numbers, so use the nearest integer to the monitor scale, and restart an
-- app for a change to reach it.
local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- External display (BenQ GW2270 over HDMI) sits above the laptop, as on the
-- IdeaPad. auto-up keeps it working when the panel is 1440p or the cable swaps
-- to DP. `reserved.bottom` keeps a strip at the bottom of the external display
-- out of the work area -- 40 px, half of the 80 px the IdeaPad used. The laptop
-- stays at 0x0, so with nothing plugged in it still starts at the top.
--
-- Kept on ONE line on purpose: omarchy-hyprland-monitor-scaling's persist_scale
-- only rewrites single-line rules with a plain scale value, and the display
-- widget's scale chips go through it.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto-up", scale = 1.25, reserved = { bottom = 40 } })
